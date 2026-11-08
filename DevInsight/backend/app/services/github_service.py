import logging
import re
from datetime import date, datetime, timedelta, timezone
from typing import Any
from urllib.parse import quote, urlsplit

import httpx

from app.config import get_settings

logger = logging.getLogger(__name__)

GITHUB_API = "https://api.github.com"
MAX_RESPONSE_BYTES = 2_000_000
RECENT_ITEMS_LIMIT = 10
WEEKLY_ACTIVITY_WEEKS = 8
WEEKLY_ACTIVITY_BOUNDARY = "Sunday 00:00 UTC"
MAX_WEEKLY_PAGES = 10
REPOSITORY_PART = re.compile(r"[A-Za-z0-9](?:[A-Za-z0-9._-]{0,98}[A-Za-z0-9])?\Z")
OWNER_PART = re.compile(r"[A-Za-z0-9](?:[A-Za-z0-9-]{0,37}[A-Za-z0-9])?\Z")


class GitHubServiceError(RuntimeError):
    """Base error for safe GitHub API failures."""


class GitHubRepositoryNotFound(GitHubServiceError):
    """The repository does not exist or is not publicly accessible."""


class GitHubPrivateRepository(GitHubServiceError):
    """Private repositories are not supported by this MVP."""


class GitHubRateLimitExceeded(GitHubServiceError):
    """GitHub has temporarily rate limited this server."""


class GitHubUnavailable(GitHubServiceError):
    """GitHub could not provide repository information."""


def parse_repository_url(repository_url: str) -> tuple[str, str]:
    try:
        parsed = urlsplit(repository_url.strip())
    except ValueError as error:
        raise ValueError("Enter a valid public GitHub repository URL.") from error

    try:
        has_port = parsed.port is not None
    except ValueError as error:
        raise ValueError("Enter a valid public GitHub repository URL.") from error
    if (
        parsed.scheme != "https"
        or parsed.hostname != "github.com"
        or parsed.username is not None
        or parsed.password is not None
        or has_port
        or parsed.query
        or parsed.fragment
    ):
        raise ValueError("Enter a valid public GitHub repository URL.")

    parts = parsed.path.strip("/").split("/")
    if len(parts) != 2:
        raise ValueError("Enter a valid public GitHub repository URL.")
    owner, repository = parts
    if repository.endswith(".git"):
        repository = repository[:-4]
    if (
        not OWNER_PART.fullmatch(owner)
        or not REPOSITORY_PART.fullmatch(repository)
        or repository in {".", ".."}
    ):
        raise ValueError("Enter a valid public GitHub repository URL.")
    return owner, repository


class GitHubService:
    def __init__(self, client: httpx.Client | None = None) -> None:
        self._client = client

    def get_repository(self, owner: str, repository: str) -> dict[str, Any]:
        data = self._get(f"/repos/{quote(owner)}/{quote(repository)}")
        if not isinstance(data, dict):
            raise GitHubUnavailable
        if data.get("private") is True:
            raise GitHubPrivateRepository
        if (
            not isinstance(data.get("id"), int)
            or not isinstance(data.get("full_name"), str)
            or not isinstance(data.get("name"), str)
            or not isinstance(data.get("html_url"), str)
            or not isinstance(data.get("owner"), dict)
            or not isinstance(data["owner"].get("login"), str)
        ):
            raise GitHubUnavailable
        return data

    def get_summary(
        self,
        owner: str,
        repository: str,
        repository_data: dict[str, Any],
    ) -> dict[str, Any]:
        encoded_repo = f"{quote(owner)}/{quote(repository)}"
        language_bytes = self._get(f"/repos/{encoded_repo}/languages")
        commits = self._get(
            f"/repos/{encoded_repo}/commits",
            params={"per_page": RECENT_ITEMS_LIMIT},
        )
        issues = self._get(
            f"/repos/{encoded_repo}/issues",
            params={"state": "all", "per_page": RECENT_ITEMS_LIMIT, "sort": "updated"},
        )
        pulls = self._get(
            f"/repos/{encoded_repo}/pulls",
            params={"state": "all", "per_page": RECENT_ITEMS_LIMIT, "sort": "updated"},
        )
        if (
            not isinstance(language_bytes, dict)
            or not isinstance(commits, list)
            or not isinstance(issues, list)
            or not isinstance(pulls, list)
        ):
            raise GitHubUnavailable

        since = (datetime.now(timezone.utc) - timedelta(days=30)).date().isoformat()
        open_pull_requests = self._search_count(
            f"repo:{owner}/{repository} is:pr is:open"
        )
        resolved_issues = self._search_count(
            f"repo:{owner}/{repository} is:issue is:closed closed:>={since}"
        )
        open_issues = self._search_count(f"repo:{owner}/{repository} is:issue is:open")
        total_language_bytes = sum(
            value for value in language_bytes.values() if isinstance(value, int)
        )
        languages = [
            {
                "name": name,
                "bytes": byte_count,
                "percentage": round(byte_count * 100 / total_language_bytes, 1)
                if total_language_bytes
                else 0,
            }
            for name, byte_count in sorted(
                language_bytes.items(),
                key=lambda item: item[1] if isinstance(item[1], int) else 0,
                reverse=True,
            )
            if isinstance(byte_count, int) and byte_count >= 0
        ]

        activity: list[dict[str, Any]] = []
        for commit in commits:
            commit_data = commit.get("commit") or {}
            author = commit_data.get("author") or {}
            message = commit_data.get("message") or ""
            if not isinstance(message, str):
                continue
            activity.append(
                {
                    "type": "commit",
                    "title": message.splitlines()[0][:200],
                    "author": (author.get("name") or "Unknown author"),
                    "date": author.get("date"),
                    "created_at": author.get("date"),
                    "url": commit.get("html_url"),
                    "sha": commit.get("sha"),
                }
            )
        for issue in issues:
            if "pull_request" in issue:
                continue
            activity.append(
                {
                    "type": "issue",
                    "title": issue.get("title") or "Untitled issue",
                    "author": (issue.get("user") or {}).get("login") or "Unknown author",
                    "date": issue.get("updated_at"),
                    "created_at": issue.get("created_at"),
                    "closed_at": issue.get("closed_at"),
                    "url": issue.get("html_url"),
                    "number": issue.get("number"),
                    "state": issue.get("state"),
                    "labels": [
                        label.get("name")
                        for label in issue.get("labels", [])
                        if isinstance(label, dict) and isinstance(label.get("name"), str)
                    ],
                }
            )
        for pull in pulls:
            activity.append(
                {
                    "type": "pull_request",
                    "title": pull.get("title") or "Untitled pull request",
                    "author": (pull.get("user") or {}).get("login") or "Unknown author",
                    "date": pull.get("updated_at"),
                    "created_at": pull.get("created_at"),
                    "closed_at": pull.get("closed_at"),
                    "merged_at": pull.get("merged_at"),
                    "url": pull.get("html_url"),
                    "number": pull.get("number"),
                    "state": "merged" if pull.get("merged_at") else pull.get("state"),
                }
            )
        activity.sort(
            key=lambda item: item.get("date") or "",
            reverse=True,
        )
        oldest_open_pull = self._oldest_open_pull(encoded_repo)
        default_branch = repository_data.get("default_branch")
        weekly_activity = self._weekly_activity(
            encoded_repo,
            default_branch if isinstance(default_branch, str) else None,
            repository_data.get("created_at"),
        )
        signals = self._repository_signals(
            encoded_repo,
            repository_data,
            default_branch if isinstance(default_branch, str) else None,
        )
        latest_commit = signals["latest_commit"]
        pushed_at = repository_data.get("pushed_at")
        latest_commit_at = (
            latest_commit.get("date") if isinstance(latest_commit, dict) else None
        )
        activity_date = pushed_at or latest_commit_at
        recently_active = self._is_recent(activity_date, days=14)
        health = {
            "last_push_at": pushed_at,
            "latest_commit_at": latest_commit_at,
            "recent_activity_status": (
                "recently_active" if recently_active is True
                else "no_recent_push" if recently_active is False
                else "not_measured"
            ),
            "open_issues": open_issues,
            "recently_closed_issues_30d": resolved_issues,
            "open_pull_requests": open_pull_requests,
            "oldest_open_pull_request": oldest_open_pull,
            "ci_state": signals["ci"]["state"],
            "ci_completed_at": signals["ci"]["last_completed_at"],
            "repository_updated_at": repository_data.get("updated_at"),
        }

        return {
            "open_pull_requests": open_pull_requests,
            "resolved_issues_30d": resolved_issues,
            "open_issues": open_issues,
            "languages": languages,
            "recent_commits": [
                item for item in activity if item["type"] == "commit"
            ][:RECENT_ITEMS_LIMIT],
            "recent_activity": activity[:20],
            "recent_data_limit": RECENT_ITEMS_LIMIT,
            "repository_updated_at": repository_data.get("updated_at"),
            "weekly_activity": weekly_activity,
            "repository_health": health,
            "quality_signals": {
                "ci": signals["ci"],
                "readme_present": signals["readme_present"],
                "license_present": signals["license_present"],
                "tests_detected": signals["tests_detected"],
                "default_branch": default_branch,
                "latest_commit": latest_commit,
            },
            "synced_at": datetime.now(timezone.utc).isoformat(),
        }

    def _weekly_activity(
        self,
        encoded_repo: str,
        default_branch: str | None,
        created_at: object,
    ) -> dict[str, Any]:
        today = datetime.now(timezone.utc).date()
        current_week_start = today - timedelta(days=(today.weekday() + 1) % 7)
        first_week_start = current_week_start - timedelta(
            weeks=WEEKLY_ACTIVITY_WEEKS - 1
        )
        week_starts = [
            first_week_start + timedelta(weeks=index)
            for index in range(WEEKLY_ACTIVITY_WEEKS)
        ]
        result: dict[str, Any] = {
            "availability": "unavailable",
            "is_complete": False,
            "weeks": [
                {"week_start": week.isoformat(), "commits": None}
                for week in week_starts
            ],
            "total_commits": None,
            "branch": default_branch,
            "period_start": first_week_start.isoformat(),
            "period_end": today.isoformat(),
            "week_boundary": WEEKLY_ACTIVITY_BOUNDARY,
        }
        try:
            data, response_status = self._get(
                f"/repos/{encoded_repo}/stats/participation",
                include_status=True,
            )
        except (GitHubRepositoryNotFound, GitHubRateLimitExceeded):
            return result
        except GitHubUnavailable:
            return result
        if response_status == 202:
            result["availability"] = "processing"
            return result
        if not isinstance(data, dict):
            return result
        weekly = data.get("all")
        if not isinstance(weekly, list):
            return result

        by_week: dict[date, int] = {}
        for item in weekly:
            if not isinstance(item, dict):
                return result
            timestamp = item.get("week")
            commits = item.get("total")
            if (
                type(timestamp) is not int
                or type(commits) is not int
                or timestamp < 0
                or commits < 0
            ):
                return result
            try:
                week_date = datetime.fromtimestamp(timestamp, timezone.utc).date()
            except (OverflowError, OSError, ValueError):
                return result
            by_week[week_date] = commits

        repository_created = self._parse_date(created_at)
        rows: list[dict[str, Any]] = []
        complete = True
        for week_start in week_starts:
            commits = by_week.get(week_start)
            if commits is None:
                if repository_created is not None and week_start < (
                    repository_created.date()
                    - timedelta(days=(repository_created.weekday() + 1) % 7)
                ):
                    commits = 0
                else:
                    complete = False
            rows.append(
                {"week_start": week_start.isoformat(), "commits": commits}
            )
        result["availability"] = "available" if complete else "incomplete"
        result["is_complete"] = complete
        result["weeks"] = rows
        result["total_commits"] = (
            sum(row["commits"] for row in rows) if complete else None
        )
        return result

    def _repository_signals(
        self,
        encoded_repo: str,
        repository_data: dict[str, Any],
        default_branch: str | None,
    ) -> dict[str, Any]:
        latest_commit: dict[str, Any] | None = None
        commit_sha: str | None = None
        if default_branch:
            try:
                commits = self._get(
                    f"/repos/{encoded_repo}/commits",
                    params={"sha": default_branch, "per_page": 1},
                )
                if isinstance(commits, list) and commits and isinstance(commits[0], dict):
                    commit = commits[0]
                    details = commit.get("commit") or {}
                    committer = details.get("committer") or {}
                    latest_commit = {
                        "sha": commit.get("sha"),
                        "date": committer.get("date"),
                        "url": commit.get("html_url"),
                    }
                    sha_value = commit.get("sha")
                    commit_sha = sha_value if isinstance(sha_value, str) else None
            except (
                GitHubRepositoryNotFound,
                GitHubRateLimitExceeded,
                GitHubUnavailable,
            ):
                pass

        ci = self._ci_signals(encoded_repo, commit_sha)
        readme_present: bool | None
        try:
            readme = self._get(f"/repos/{encoded_repo}/readme")
            readme_present = isinstance(readme, dict)
        except GitHubRepositoryNotFound:
            readme_present = False
        except (GitHubUnavailable, GitHubRateLimitExceeded):
            readme_present = None

        license_data = repository_data.get("license")
        license_present = (
            None
            if "license" not in repository_data
            else isinstance(license_data, dict)
        )
        tests_detected = self._tests_detected(encoded_repo, default_branch)
        return {
            "latest_commit": latest_commit,
            "ci": ci,
            "readme_present": readme_present,
            "license_present": license_present,
            "tests_detected": tests_detected,
        }

    def _ci_signals(
        self,
        encoded_repo: str,
        commit_sha: str | None,
    ) -> dict[str, Any]:
        unavailable = {
            "availability": "not_measured",
            "state": "not_measured",
            "passed": None,
            "failed": None,
            "pending": None,
            "last_completed_at": None,
            "url": None,
        }
        if commit_sha is None:
            return unavailable
        try:
            checks, checks_complete = self._get_check_runs(
                encoded_repo,
                commit_sha,
            )
            status_data = self._get(
                f"/repos/{encoded_repo}/commits/{quote(commit_sha)}/status"
            )
        except (
            GitHubRepositoryNotFound,
            GitHubRateLimitExceeded,
            GitHubUnavailable,
        ):
            return unavailable
        if not isinstance(checks, dict) or not isinstance(status_data, dict):
            return unavailable

        runs = checks.get("check_runs")
        total_checks = checks.get("total_count")
        statuses = status_data.get("statuses")
        if not isinstance(runs, list) or not isinstance(total_checks, int):
            return unavailable
        if not isinstance(statuses, list):
            statuses = []
        count_complete = checks_complete and total_checks <= len(runs)
        passed = failed = pending = 0
        unknown = False
        completed_dates: list[str] = []
        latest_url: str | None = None
        for run in runs:
            if not isinstance(run, dict):
                count_complete = False
                continue
            status_value = run.get("status")
            conclusion = run.get("conclusion")
            if status_value != "completed":
                pending += 1
            elif conclusion in {"success", "neutral", "skipped"}:
                passed += 1
            elif conclusion in {
                "failure",
                "cancelled",
                "timed_out",
                "action_required",
                "stale",
            }:
                failed += 1
            else:
                unknown = True
            completed_at = run.get("completed_at")
            if isinstance(completed_at, str):
                completed_dates.append(completed_at)
            html_url = run.get("html_url")
            if isinstance(html_url, str) and (
                latest_url is None or completed_at is not None
            ):
                latest_url = html_url

        if total_checks == 0 and statuses:
            for status_item in statuses:
                if not isinstance(status_item, dict):
                    continue
                state = status_item.get("state")
                if state == "success":
                    passed += 1
                elif state == "failure" or state == "error":
                    failed += 1
                else:
                    pending += 1
                updated_at = status_item.get("updated_at")
                if isinstance(updated_at, str):
                    completed_dates.append(updated_at)
                target_url = status_item.get("target_url")
                if isinstance(target_url, str):
                    latest_url = target_url
            count_complete = True

        if total_checks == 0 and not statuses:
            return {
                **unavailable,
                "availability": "not_configured",
                "state": "not_configured",
                "passed": 0,
                "failed": 0,
                "pending": 0,
            }
        if not count_complete or unknown:
            state = "not_measured"
        elif failed:
            state = "failure"
        elif pending:
            state = "pending"
        else:
            state = "success"
        return {
            "availability": "available" if count_complete and not unknown else "incomplete",
            "state": state,
            "passed": passed if count_complete else None,
            "failed": failed if count_complete else None,
            "pending": pending if count_complete else None,
            "last_completed_at": max(completed_dates) if completed_dates else None,
            "url": latest_url,
        }

    def _tests_detected(
        self,
        encoded_repo: str,
        default_branch: str | None,
    ) -> bool | None:
        if not default_branch:
            return None
        try:
            tree = self._get(
                f"/repos/{encoded_repo}/git/trees/{quote(default_branch)}",
                params={"recursive": "1"},
            )
        except (
            GitHubRepositoryNotFound,
            GitHubRateLimitExceeded,
            GitHubUnavailable,
        ):
            return None
        if not isinstance(tree, dict):
            return None
        entries = tree.get("tree")
        if not isinstance(entries, list) or tree.get("truncated") is True:
            return None
        test_file = re.compile(
            r"(^|/)(tests?|__tests__)(/|$)|(^|/)(test_[^/]+|[^/]+\.(test|spec)\.[^/]+)$",
            re.IGNORECASE,
        )
        for entry in entries:
            if (
                isinstance(entry, dict)
                and entry.get("type") == "blob"
                and isinstance(entry.get("path"), str)
                and test_file.search(entry["path"])
            ):
                return True
        return False

    def _get_check_runs(
        self,
        encoded_repo: str,
        commit_sha: str,
    ) -> tuple[dict[str, Any], bool]:
        path = f"/repos/{encoded_repo}/commits/{quote(commit_sha)}/check-runs"
        checks = self._get(path, params={"per_page": 100, "page": 1})
        if not isinstance(checks, dict) or not isinstance(checks.get("check_runs"), list):
            raise GitHubUnavailable
        total_count = checks.get("total_count")
        if not isinstance(total_count, int) or total_count < 0:
            raise GitHubUnavailable

        collected = list(checks["check_runs"])
        pages_needed = (total_count + 99) // 100
        if pages_needed > MAX_WEEKLY_PAGES:
            return {**checks, "check_runs": collected}, False
        for page in range(2, pages_needed + 1):
            page_data = self._get(
                path,
                params={"per_page": 100, "page": page},
            )
            if (
                not isinstance(page_data, dict)
                or not isinstance(page_data.get("check_runs"), list)
            ):
                return {**checks, "check_runs": collected}, False
            collected.extend(page_data["check_runs"])
        return {**checks, "check_runs": collected}, len(collected) >= total_count

    def _oldest_open_pull(self, encoded_repo: str) -> dict[str, Any] | None:
        try:
            pulls = self._get(
                f"/repos/{encoded_repo}/pulls",
                params={
                    "state": "open",
                    "sort": "created",
                    "direction": "asc",
                    "per_page": 1,
                },
            )
        except GitHubRepositoryNotFound:
            return {"availability": "available", "pull_request": None}
        except (GitHubUnavailable, GitHubRateLimitExceeded):
            return {"availability": "not_measured", "pull_request": None}
        if not isinstance(pulls, list):
            return {"availability": "not_measured", "pull_request": None}
        if not pulls:
            return {"availability": "available", "pull_request": None}
        if not isinstance(pulls[0], dict):
            return {"availability": "not_measured", "pull_request": None}
        pull = pulls[0]
        created_at = pull.get("created_at")
        age_days = None
        created_date = self._parse_date(created_at)
        if created_date is not None:
            age_days = max(
                0,
                (datetime.now(timezone.utc).date() - created_date.date()).days,
            )
        return {
            "availability": "available",
            "pull_request": {
            "number": pull.get("number"),
            "title": pull.get("title"),
            "created_at": created_at,
            "age_days": age_days,
            "url": pull.get("html_url"),
            },
        }

    @staticmethod
    def _parse_date(value: object) -> datetime | None:
        if not isinstance(value, str):
            return None
        try:
            parsed = datetime.fromisoformat(value.replace("Z", "+00:00"))
        except ValueError:
            return None
        if parsed.tzinfo is None:
            parsed = parsed.replace(tzinfo=timezone.utc)
        return parsed.astimezone(timezone.utc)

    @classmethod
    def _is_recent(cls, value: object, days: int) -> bool | None:
        timestamp = cls._parse_date(value)
        if timestamp is None:
            return None
        age = datetime.now(timezone.utc) - timestamp
        return timedelta(0) <= age <= timedelta(days=days)

    def _search_count(self, query: str) -> int | None:
        result = self._get("/search/issues", params={"q": query, "per_page": 1})
        if not isinstance(result, dict):
            raise GitHubUnavailable
        if result.get("incomplete_results") is True:
            return None
        count = result.get("total_count")
        return count if isinstance(count, int) and count >= 0 else None

    def _get(
        self,
        path: str,
        params: dict[str, object] | None = None,
        *,
        include_status: bool = False,
    ) -> Any:
        settings = get_settings()
        headers = {
            "Accept": "application/vnd.github+json",
            "X-GitHub-Api-Version": "2022-11-28",
            "User-Agent": "DevInsight",
        }
        if settings.github_token:
            headers["Authorization"] = f"Bearer {settings.github_token}"

        try:
            response = (
                self._client.get(
                    f"{GITHUB_API}{path}",
                    params=params,
                    headers=headers,
                    timeout=8.0,
                )
                if self._client is not None
                else httpx.get(
                    f"{GITHUB_API}{path}",
                    params=params,
                    headers=headers,
                    timeout=8.0,
                    follow_redirects=False,
                )
            )
        except httpx.TimeoutException as error:
            raise GitHubUnavailable from error
        except httpx.HTTPError as error:
            raise GitHubUnavailable from error

        if len(response.content) > MAX_RESPONSE_BYTES:
            raise GitHubUnavailable
        if response.status_code == 202 and include_status:
            return [], response.status_code
        if response.status_code == 404:
            raise GitHubRepositoryNotFound
        if response.status_code == 429 or (
            response.status_code == 403
            and (
                response.headers.get("x-ratelimit-remaining") == "0"
                or response.headers.get("retry-after") is not None
                or "rate limit" in response.text.casefold()
            )
        ):
            raise GitHubRateLimitExceeded
        if response.status_code != 202 and (
            response.status_code < 200 or response.status_code >= 300
        ):
            logger.warning("GitHub API request failed with status %s.", response.status_code)
            raise GitHubUnavailable
        try:
            payload = response.json()
        except ValueError as error:
            raise GitHubUnavailable from error
        if not isinstance(payload, (dict, list)):
            raise GitHubUnavailable
        return (payload, response.status_code) if include_status else payload


github_service = GitHubService()
