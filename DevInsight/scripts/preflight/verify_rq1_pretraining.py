#!/usr/bin/env python3
"""Read-only local verification for DevInsight RQ1 pre-training evidence."""

from __future__ import annotations

import csv
import json
import os
import re
import subprocess
import sys
from collections import Counter
from datetime import datetime
from pathlib import Path
from urllib.parse import urlparse


ROOT = Path(__file__).resolve().parents[2]
OUTPUT = ROOT / "data" / "preflight" / "rq1_pretraining_verification.json"
REQUIRED_CSVS = {
    "config/research_repositories.csv": (
        "repo_name",
        "language",
        "default_branch",
        "folder_name",
        "url",
    ),
    "config/repository_setup_manifest.csv": (
        "Repository",
        "Language",
        "DefaultBranch",
        "CommitSHA",
        "RemoteURL",
        "RecordedAtUTC",
    ),
    "data/repository_screening.csv": ("Repository", "Language", "Commits"),
    "data/repository_bug_audit.csv": ("Repository", "Status"),
    "data/bug_issue_samples.csv": (
        "Repository",
        "IssueNumber",
        "URL",
        "CreatedAt",
    ),
    "data/bug_fix_review_auto.csv": (
        "Repository",
        "IssueNumber",
        "IssueURL",
        "FixPRURL",
        "PRMerged",
        "FixCommitSHA",
        "ReviewStatus",
    ),
    "data/repository_suitability_matrix.csv": (
        "Repository",
        "ReviewedIssues",
        "VerifiedFixes",
        "CandidateFixes",
        "BugsWithoutFix",
        "NotABug",
        "Unclear",
    ),
    "data/bug_fix_review.csv": ("Repository", "IssueNumber", "ReviewStatus"),
    "data/repository_bug_audit_pilot.csv": ("Repository", "Status"),
    "data/bug_issue_samples_pilot.csv": ("Repository", "IssueNumber", "URL"),
}
DOCUMENTS = (
    "docs/bug_fix_evidence_review.md",
    "docs/repository_selection_first_half.md",
    "docs/rq1_methodology_first_half.md",
    "docs/rq1_first_half_evaluation_summary.md",
)
SCRIPTS = (
    "scripts/screen_repositories.ps1",
    "scripts/audit_bug_issues.ps1",
    "scripts/retrieve_bug_issue_timelines.ps1",
    "scripts/build_repository_suitability.ps1",
)
SHA_RE = re.compile(r"^[0-9a-fA-F]{40}$")
SOURCE_SUFFIXES = {
    ".py",
    ".pyi",
    ".dart",
    ".java",
    ".kt",
    ".kts",
    ".swift",
    ".m",
    ".mm",
    ".c",
    ".h",
    ".cc",
    ".cpp",
    ".rs",
    ".go",
    ".js",
    ".ts",
}


def git(path: Path, *args: str) -> subprocess.CompletedProcess[str]:
    environment = os.environ.copy()
    environment["GIT_NO_LAZY_FETCH"] = "1"
    return subprocess.run(
        ["git", "-C", str(path), *args],
        capture_output=True,
        text=True,
        encoding="utf-8",
        errors="replace",
        env=environment,
        check=False,
    )


def read_csv(relative_path: str) -> tuple[list[dict[str, str]], list[str]]:
    path = ROOT / relative_path
    with path.open("r", encoding="utf-8-sig", newline="") as stream:
        reader = csv.DictReader(stream)
        return list(reader), list(reader.fieldnames or [])


def parse_date(value: str) -> bool:
    if not value:
        return False
    try:
        datetime.fromisoformat(value.replace("Z", "+00:00"))
        return True
    except ValueError:
        return False


def inspect_csv(relative_path: str, required: tuple[str, ...]) -> dict:
    path = ROOT / relative_path
    result = {
        "path": relative_path,
        "exists": path.is_file(),
        "readable": False,
        "row_count": None,
        "columns": [],
        "missing_required_columns": [],
        "empty_required_values": {},
        "duplicate_rows": 0,
        "repository_ids": [],
        "unknown_repository_ids": [],
        "status_counts": {},
        "errors": [],
    }
    if not path.is_file():
        result["errors"].append("MISSING_FILE")
        return result
    try:
        rows, columns = read_csv(relative_path)
        result["readable"] = True
        result["row_count"] = len(rows)
        result["columns"] = columns
        result["missing_required_columns"] = [
            column for column in required if column not in columns
        ]
        result["empty_required_values"] = {
            column: sum(not (row.get(column) or "").strip() for row in rows)
            for column in required
            if column in columns
        }
        result["duplicate_rows"] = len(rows) - len(
            {tuple(sorted(row.items())) for row in rows}
        )
        if "Repository" in columns:
            result["repository_ids"] = sorted(
                {row["Repository"].strip() for row in rows if row["Repository"]}
            )
        elif "repo_name" in columns:
            result["repository_ids"] = sorted(
                {row["repo_name"].strip() for row in rows if row["repo_name"]}
            )
        if "ReviewStatus" in columns:
            result["status_counts"] = dict(
                Counter(row["ReviewStatus"].strip() for row in rows)
            )
        elif "Status" in columns:
            result["status_counts"] = dict(
                Counter(row["Status"].strip() for row in rows)
            )
    except (OSError, UnicodeError, csv.Error) as error:
        result["errors"].append(f"{type(error).__name__}: {error}")
    return result


def inspect_dataset_relations(datasets: dict[str, list[dict[str, str]]]) -> dict:
    repos = {
        row["repo_name"] for row in datasets["config/research_repositories.csv"]
    }
    sample = datasets["data/bug_issue_samples.csv"]
    reviews = datasets["data/bug_fix_review_auto.csv"]
    manual = datasets["data/bug_fix_review.csv"]
    matrix = datasets["data/repository_suitability_matrix.csv"]
    key = lambda row: (row.get("Repository", ""), row.get("IssueNumber", ""))
    sample_keys = [key(row) for row in sample]
    review_keys = [key(row) for row in reviews]
    manual_keys = [key(row) for row in manual]
    sample_set, review_set, manual_set = (
        set(sample_keys),
        set(review_keys),
        set(manual_keys),
    )
    status_counts = Counter(row["ReviewStatus"].strip() for row in reviews)
    review_counts_by_repo: dict[str, Counter] = {}
    for row in reviews:
        review_counts_by_repo.setdefault(row["Repository"], Counter())[
            row["ReviewStatus"].strip()
        ] += 1
    matrix_mismatches = []
    matrix_fields = {
        "VERIFIED_FIX": "VerifiedFixes",
        "CANDIDATE_FIX": "CandidateFixes",
        "BUG_NO_FIX_LINK": "BugsWithoutFix",
        "NOT_A_BUG": "NotABug",
        "UNCLEAR": "Unclear",
    }
    for row in matrix:
        counts = review_counts_by_repo.get(row["Repository"], Counter())
        mismatches = {
            column: {
                "matrix": int(row[column]),
                "reviews": counts[status],
            }
            for status, column in matrix_fields.items()
            if row.get(column, "").isdigit()
            and int(row[column]) != counts[status]
        }
        if mismatches:
            matrix_mismatches.append(
                {"repository": row["Repository"], "mismatches": mismatches}
            )
    issue_checks = []
    for row in sample:
        issue_url = urlparse(row.get("URL", ""))
        issue_path = issue_url.path.strip("/").split("/")
        issue_checks.append(
            {
                "key": key(row),
                "valid_issue_number": row.get("IssueNumber", "").isdigit()
                and int(row["IssueNumber"]) > 0,
                "valid_github_issue_url": issue_url.scheme == "https"
                and issue_url.netloc == "github.com"
                and len(issue_path) == 4
                and issue_path[2] == "issues",
                "issue_url_matches_key": len(issue_path) == 4
                and issue_path[:2] == row["Repository"].split("/")
                and issue_path[2] == "issues"
                and issue_path[3] == row["IssueNumber"],
                "valid_created_at": parse_date(row.get("CreatedAt", "")),
                "closed_at_empty_or_valid": not row.get("ClosedAt", "").strip()
                or parse_date(row["ClosedAt"]),
            }
        )
    sha_checks = []
    for row in reviews:
        sha = row.get("FixCommitSHA", "").strip()
        issue_url = urlparse(row.get("IssueURL", ""))
        issue_path = issue_url.path.strip("/").split("/")
        pr_url = urlparse(row.get("FixPRURL", ""))
        pr_path = pr_url.path.strip("/").split("/")
        merged = row.get("PRMerged", "").strip().lower()
        sha_checks.append(
            {
                "key": key(row),
                "sha": sha,
                "valid_sha_format": bool(SHA_RE.fullmatch(sha)) if sha else False,
                "sha_present": bool(sha),
                "valid_pr_url": not row.get("FixPRURL", "").strip()
                or (
                    pr_url.scheme == "https"
                    and pr_url.netloc == "github.com"
                    and "/pull/" in pr_url.path
                ),
                "issue_url_matches_key": len(issue_path) == 4
                and issue_path[:2] == row["Repository"].split("/")
                and issue_path[2] == "issues"
                and issue_path[3] == row["IssueNumber"],
                "pr_url_matches_repository": not row.get("FixPRURL", "").strip()
                or (
                    len(pr_path) == 4
                    and pr_path[:2] == row["Repository"].split("/")
                    and pr_path[2] == "pull"
                    and pr_path[3].isdigit()
                ),
                "pr_merged_value": merged,
                "valid_pr_merged_value": merged in {"true", "false"},
                "valid_checked_at": parse_date(row.get("CheckedAtUTC", "")),
                "review_status": row.get("ReviewStatus", ""),
            }
        )
    unknown_by_file = {}
    timestamp_failures = {}
    for relative, rows in datasets.items():
        if not rows:
            continue
        columns = rows[0].keys()
        repository_field = (
            "Repository" if "Repository" in columns else
            "repo_name" if "repo_name" in columns else None
        )
        if repository_field:
            unknown_by_file[relative] = sorted(
                {
                    row[repository_field]
                    for row in rows
                    if row.get(repository_field) and row[repository_field] not in repos
                }
            )
        for field in ("CreatedAt", "ClosedAt", "RecordedAtUTC", "CheckedAtUTC"):
            if field in columns:
                invalid = [
                    index + 2
                    for index, row in enumerate(rows)
                    if row.get(field, "").strip() and not parse_date(row[field])
                ]
                if invalid:
                    timestamp_failures[f"{relative}:{field}"] = invalid
    return {
        "configured_repository_count": len(repos),
        "sample_record_count": len(sample),
        "review_record_count": len(reviews),
        "manual_review_record_count": len(manual),
        "sample_duplicate_keys": len(sample_keys) - len(sample_set),
        "review_duplicate_keys": len(review_keys) - len(review_set),
        "manual_duplicate_keys": len(manual_keys) - len(manual_set),
        "sample_review_key_mismatches": {
            "in_sample_not_in_auto_review": sorted(sample_set - review_set),
            "in_auto_review_not_in_sample": sorted(review_set - sample_set),
            "in_sample_not_in_manual_template": sorted(sample_set - manual_set),
            "in_manual_template_not_in_sample": sorted(manual_set - sample_set),
        },
        "unknown_repository_records": {
            "sample": sorted({row[0] for row in sample_set if row[0] not in repos}),
            "reviews": sorted({row[0] for row in review_set if row[0] not in repos}),
            "by_file": unknown_by_file,
        },
        "invalid_timestamps_by_file_and_field": timestamp_failures,
        "review_status_counts": dict(status_counts),
        "reviewed_issue_count_by_repository": dict(
            Counter(row["Repository"] for row in reviews)
        ),
        "suitability_matrix_status_mismatches": matrix_mismatches,
        "issue_field_failures": [
            item
            for item in issue_checks
            if not all(
                value
                for key_name, value in item.items()
                if key_name != "key"
            )
        ],
        "fix_evidence_field_failures": [
            item
            for item in sha_checks
            if not item["issue_url_matches_key"]
            or not item["valid_checked_at"]
            or (
                item["sha_present"] and not item["valid_sha_format"]
            )
            or (
                item["review_status"] in {"VERIFIED_FIX", "CANDIDATE_FIX"}
                and (
                    not item["valid_pr_url"]
                    or not item["pr_url_matches_repository"]
                    or not item["valid_pr_merged_value"]
                    or not item["sha_present"]
                )
            )
            or (
                item["review_status"] == "VERIFIED_FIX"
                and item["pr_merged_value"] != "true"
            )
            or (
                item["review_status"] == "CANDIDATE_FIX"
                and item["pr_merged_value"] != "false"
            )
        ],
        "fix_records": sha_checks,
    }


def inspect_repository(repo_row: dict[str, str], manifest: dict[str, str]) -> dict:
    path = ROOT / "data" / "repositories" / repo_row["folder_name"]
    record = {
        "repository": repo_row["repo_name"],
        "language": repo_row["language"],
        "local_path": str(path.relative_to(ROOT)),
        "exists": path.is_dir(),
        "git_worktree_valid": False,
        "working_tree_status_exit_code": None,
        "working_tree_dirty_paths": [],
        "origin_url": None,
        "origin_matches_config": None,
        "current_branch": None,
        "head": None,
        "manifest_head": manifest.get("CommitSHA"),
        "head_matches_manifest": None,
        "configured_default_branch": repo_row.get("default_branch"),
        "configured_default_branch_exists": None,
        "remote_default_branch": None,
        "commit_count_all_refs": None,
        "commit_count_head": None,
        "is_shallow": None,
        "partial_clone_filter": None,
        "origin_is_promisor": None,
        "source_file_count_head": None,
        "source_file_extensions": {},
        "tree_object_check_exit_code": None,
        "missing_tree_object_count": None,
        "missing_tree_object_samples": [],
        "source_blob_check_exit_code": None,
        "missing_source_blob_count": None,
        "missing_source_blob_samples": [],
        "object_store": {},
        "status": "REPOSITORY_MISSING",
        "errors": [],
    }
    if not path.is_dir():
        return record
    root = git(path, "rev-parse", "--show-toplevel")
    if root.returncode:
        record["errors"].append(root.stderr.strip())
        return record
    record["git_worktree_valid"] = True
    status = git(path, "status", "--porcelain", "--untracked-files=normal")
    record["working_tree_status_exit_code"] = status.returncode
    record["working_tree_dirty_paths"] = status.stdout.splitlines()
    if status.returncode != 0:
        record["errors"].append(
            "git status failed with lazy fetch disabled: " + status.stderr.strip()
        )
    origin = git(path, "remote", "get-url", "origin")
    if origin.returncode == 0:
        record["origin_url"] = origin.stdout.strip()
        record["origin_matches_config"] = (
            origin.stdout.strip().removesuffix(".git").lower()
            == repo_row["url"].removesuffix(".git").lower()
        )
    branch = git(path, "branch", "--show-current")
    record["current_branch"] = branch.stdout.strip() if branch.returncode == 0 else None
    head = git(path, "rev-parse", "HEAD")
    record["head"] = head.stdout.strip() if head.returncode == 0 else None
    record["head_matches_manifest"] = (
        record["head"] == manifest.get("CommitSHA") if record["head"] else None
    )
    remote_head = git(path, "symbolic-ref", "refs/remotes/origin/HEAD")
    if remote_head.returncode == 0:
        record["remote_default_branch"] = remote_head.stdout.strip().split("/")[-1]
    configured_branch = git(
        path,
        "show-ref",
        "--verify",
        "--quiet",
        f"refs/remotes/origin/{repo_row.get('default_branch', '')}",
    )
    record["configured_default_branch_exists"] = configured_branch.returncode == 0
    count = git(path, "rev-list", "--all", "--count")
    if count.returncode == 0 and count.stdout.strip().isdigit():
        record["commit_count_all_refs"] = int(count.stdout.strip())
    head_count = git(path, "rev-list", "--count", "HEAD")
    if head_count.returncode == 0 and head_count.stdout.strip().isdigit():
        record["commit_count_head"] = int(head_count.stdout.strip())
    shallow = git(path, "rev-parse", "--is-shallow-repository")
    if shallow.returncode == 0:
        record["is_shallow"] = shallow.stdout.strip().lower() == "true"
    partial_filter = git(path, "config", "--get", "extensions.partialClone")
    if partial_filter.returncode != 0:
        partial_filter = git(path, "config", "--get", "remote.origin.partialclonefilter")
    if partial_filter.returncode == 0:
        record["partial_clone_filter"] = partial_filter.stdout.strip()
    promisor = git(path, "config", "--get", "remote.origin.promisor")
    if promisor.returncode == 0:
        record["origin_is_promisor"] = promisor.stdout.strip().lower() == "true"
    commit_trees = git(path, "log", "--all", "--format=%H%x20%T")
    if commit_trees.returncode == 0:
        trees = sorted(
            {
                line.split()[1]
                for line in commit_trees.stdout.splitlines()
                if len(line.split()) == 2
            }
        )
        checked_trees = subprocess.run(
            ["git", "-C", str(path), "cat-file", "--batch-check"],
            input="".join(f"{tree}\n" for tree in trees),
            capture_output=True,
            text=True,
            encoding="utf-8",
            errors="replace",
            env={**os.environ, "GIT_NO_LAZY_FETCH": "1"},
            check=False,
        )
        missing_trees = [
            line for line in checked_trees.stdout.splitlines() if " missing" in line
        ]
        record["tree_object_check_exit_code"] = checked_trees.returncode
        record["missing_tree_object_count"] = len(missing_trees)
        record["missing_tree_object_samples"] = missing_trees[:20]
    else:
        record["tree_object_check_exit_code"] = commit_trees.returncode
        record["missing_tree_object_samples"] = [
            commit_trees.stderr.strip()[:500]
        ]
    tree = git(path, "ls-tree", "-r", "--name-only", "HEAD")
    if tree.returncode == 0:
        files = [line for line in tree.stdout.splitlines() if line]
        source_files = [
            file for file in files if Path(file).suffix.lower() in SOURCE_SUFFIXES
        ]
        target_suffix = ".py" if repo_row["language"] == "Python" else ".dart"
        record["source_file_count_head"] = len(source_files)
        record["target_language_source_file_count_head"] = sum(
            Path(file).suffix.lower() == target_suffix for file in files
        )
        record["source_file_extensions"] = dict(
            Counter(Path(file).suffix.lower() for file in source_files)
        )
        source_tree = git(path, "ls-tree", "-r", "-l", "HEAD")
        blob_ids = set()
        if source_tree.returncode == 0:
            for line in source_tree.stdout.splitlines():
                metadata, separator, file = line.partition("\t")
                fields = metadata.split()
                if (
                    separator
                    and len(fields) >= 3
                    and Path(file).suffix.lower() in SOURCE_SUFFIXES
                ):
                    blob_ids.add(fields[2])
            checked_blobs = subprocess.run(
                ["git", "-C", str(path), "cat-file", "--batch-check"],
                input="".join(f"{blob}\n" for blob in sorted(blob_ids)),
                capture_output=True,
                text=True,
                encoding="utf-8",
                errors="replace",
                env={**os.environ, "GIT_NO_LAZY_FETCH": "1"},
                check=False,
            )
            missing_blobs = [
                line
                for line in checked_blobs.stdout.splitlines()
                if " missing" in line
            ]
            record["source_blob_check_exit_code"] = checked_blobs.returncode
            record["missing_source_blob_count"] = len(missing_blobs)
            record["missing_source_blob_samples"] = missing_blobs[:20]
        else:
            record["source_blob_check_exit_code"] = source_tree.returncode
            record["missing_source_blob_samples"] = [
                source_tree.stderr.strip()[:500]
            ]
    object_count = git(path, "count-objects", "-v")
    if object_count.returncode == 0:
        for line in object_count.stdout.splitlines():
            if ":" in line:
                name, value = line.split(":", 1)
                record["object_store"][name.strip()] = value.strip()
    if not record["git_worktree_valid"]:
        record["status"] = "INVALID_WORKTREE"
    elif record["is_shallow"]:
        record["status"] = "WARNING_SHALLOW_HISTORY"
    elif int(record["object_store"].get("garbage", "0")) > 0:
        record["status"] = "WARNING_GARBAGE_OBJECTS"
    elif (
        record["tree_object_check_exit_code"] != 0
        or record["source_blob_check_exit_code"] != 0
        or record["missing_tree_object_count"] != 0
        or record["missing_source_blob_count"] != 0
    ):
        record["status"] = "WARNING_OBJECT_CHECK"
    else:
        record["status"] = "PASS_LOCAL_INTEGRITY"
    return record


def inspect_commit_diff(
    path: Path, sha: str, parent_count: int
) -> dict[str, object]:
    if parent_count >= 1:
        command = git(path, "diff", "--numstat", f"{sha}^1", sha)
        comparison = "FIRST_PARENT_TO_COMMIT" if parent_count > 1 else "PARENT_TO_COMMIT"
    else:
        command = git(path, "diff-tree", "--root", "--numstat", "-r", sha)
        comparison = "EMPTY_TREE_TO_ROOT_COMMIT"
    if command.returncode != 0:
        return {
            "diff_status": "DIFF_UNAVAILABLE",
            "diff_exit_code": command.returncode,
            "diff_error": (command.stderr or command.stdout).strip(),
            "diff_comparison": comparison,
            "changed_files": None,
            "changed_file_count": None,
            "source_files_changed": None,
            "additions": None,
            "deletions": None,
        }
    additions, deletions, changed = 0, 0, []
    additions_available = deletions_available = True
    for line in command.stdout.splitlines():
        fields = line.split("\t", 2)
        if len(fields) != 3:
            return {
                "diff_status": "DIFF_UNAVAILABLE",
                "diff_exit_code": command.returncode,
                "diff_error": "Unexpected --numstat output shape.",
                "diff_comparison": comparison,
                "changed_files": None,
                "changed_file_count": None,
                "source_files_changed": None,
                "additions": None,
                "deletions": None,
            }
        if fields[0].isdigit():
            additions += int(fields[0])
        else:
            additions_available = False
        if fields[1].isdigit():
            deletions += int(fields[1])
        else:
            deletions_available = False
        changed.append(fields[2])
    source_files = [
        name for name in changed if Path(name).suffix.lower() in SOURCE_SUFFIXES
    ]
    return {
        "diff_status": "DIFF_AVAILABLE",
        "diff_exit_code": command.returncode,
        "diff_error": None,
        "diff_comparison": comparison,
        "changed_files": changed,
        "changed_file_count": len(changed),
        "source_files_changed": source_files,
        "additions": additions if additions_available else None,
        "deletions": deletions if deletions_available else None,
    }


def inspect_local_pr_reference(path: Path, pr_number: str) -> dict:
    if not pr_number:
        return {"status": "NO_PR_LINK", "commits": []}
    matches = git(
        path,
        "log",
        "--all",
        f"--grep=#{pr_number}",
        "--format=%H%x09%s",
        "-n",
        "20",
    )
    if matches.returncode != 0:
        return {
            "status": "SEARCH_UNAVAILABLE",
            "search_error": matches.stderr.strip(),
            "commits": [],
        }
    commits = []
    pr_pattern = re.compile(rf"#{re.escape(pr_number)}(?!\d)")
    for line in matches.stdout.splitlines():
        sha, separator, subject = line.partition("\t")
        if not separator or not pr_pattern.search(subject):
            continue
        metadata = git(path, "show", "-s", "--format=%P", sha)
        if metadata.returncode != 0:
            commits.append(
                {
                    "sha": sha,
                    "subject": subject,
                    "metadata_status": "UNAVAILABLE",
                    "diff_status": "DIFF_NOT_ATTEMPTED",
                    "changed_files": None,
                    "changed_file_count": None,
                    "source_files_changed": None,
                    "additions": None,
                    "deletions": None,
                }
            )
            continue
        parents = metadata.stdout.strip().split()
        role = "MERGE_COMMIT" if len(parents) > 1 else "PR_REFERENCED_SINGLE_PARENT_COMMIT"
        reachable = git(path, "merge-base", "--is-ancestor", sha, "HEAD")
        diff = inspect_commit_diff(path, sha, len(parents))
        commits.append(
            {
                "sha": sha,
                "subject": subject,
                "metadata_status": "AVAILABLE",
                "role": role,
                "parent_count": len(parents),
                "parents": parents,
                "reachable_from_head": (
                    reachable.returncode == 0
                    if reachable.returncode in (0, 1)
                    else None
                ),
                **diff,
            }
        )
    return {
        "status": "LOCAL_PR_REFERENCE_FOUND" if commits else "NO_LOCAL_PR_REFERENCE",
        "commits": commits,
    }


def inspect_fix_commit(fix: dict[str, str], repo_row: dict[str, str]) -> dict:
    path = ROOT / "data" / "repositories" / repo_row["folder_name"]
    sha = fix.get("FixCommitSHA", "").strip()
    pr_match = re.search(r"/pull/(\d+)", fix.get("FixPRURL", ""))
    pr_number = pr_match.group(1) if pr_match else ""
    result = {
        "repository": fix["Repository"],
        "issue_number": fix["IssueNumber"],
        "review_status": fix["ReviewStatus"],
        "fix_pr_url": fix.get("FixPRURL", ""),
        "pr_merged_recorded": fix.get("PRMerged", ""),
        "sha": sha,
        "sha_format_valid": bool(SHA_RE.fullmatch(sha)),
        "recorded_sha_role": None,
        "pr_number": pr_number or None,
        "pr_reference_status": None,
        "pr_reference_commits": [],
        "implementation_trace_status": None,
        "repo_exists": path.is_dir(),
        "commit_found": False,
        "local_object_status": None,
        "object_type": None,
        "reachable_from_head": None,
        "ancestry_status": "NOT_CHECKED",
        "parent_count": None,
        "parents": [],
        "diff_status": "DIFF_NOT_ATTEMPTED",
        "diff_exit_code": None,
        "diff_error": None,
        "diff_comparison": None,
        "changed_files": None,
        "changed_file_count": None,
        "source_files_changed": None,
        "additions": None,
        "deletions": None,
        "commit_timestamp": None,
        "commit_subject": None,
        "classification": None,
        "evidence": [],
    }
    if not path.is_dir():
        result["classification"] = "REPOSITORY_MISSING"
        result["changed_files"] = None
        result["changed_file_count"] = None
        result["source_files_changed"] = None
        result["additions"] = None
        result["deletions"] = None
        result["evidence"].append("Expected local repository directory is absent.")
        return result
    if not result["sha_format_valid"]:
        result["classification"] = "RECORDED_SHA_INVALID"
        result["changed_files"] = None
        result["changed_file_count"] = None
        result["source_files_changed"] = None
        result["additions"] = None
        result["deletions"] = None
        result["evidence"].append("Recorded SHA is empty or not 40 hexadecimal characters.")
        return result
    object_type = git(path, "cat-file", "-t", sha)
    if object_type.returncode:
        result["local_object_status"] = "OBJECT_UNAVAILABLE_LOCALLY"
        result["classification"] = "RECORDED_SHA_UNAVAILABLE_LOCALLY"
        result["changed_files"] = None
        result["changed_file_count"] = None
        result["source_files_changed"] = None
        result["additions"] = None
        result["deletions"] = None
        result["evidence"].append(
            "git cat-file -t <sha> did not resolve locally: "
            + (object_type.stderr or object_type.stdout).strip()
        )
        pr_reference = inspect_local_pr_reference(path, pr_number)
        result["pr_reference_status"] = pr_reference["status"]
        result["pr_reference_commits"] = pr_reference["commits"]
        result["implementation_trace_status"] = (
            "LOCALLY_MAPPED_DIFF_AVAILABLE"
            if any(
                item.get("diff_status") == "DIFF_AVAILABLE"
                and item.get("source_files_changed")
                for item in result["pr_reference_commits"]
            )
            else "LOCALLY_MAPPED_SOURCE_DIFF_UNAVAILABLE"
            if result["pr_reference_commits"]
            else result["pr_reference_status"]
        )
        return result
    result["local_object_status"] = "OBJECT_AVAILABLE"
    result["object_type"] = object_type.stdout.strip()
    result["commit_found"] = result["object_type"] == "commit"
    if not result["commit_found"]:
        result["classification"] = "RECORDED_OBJECT_NOT_COMMIT"
        result["evidence"].append(f"Resolved Git object type is {result['object_type']}, not commit.")
        return result
    metadata = git(path, "show", "-s", "--format=%P%x1f%ct%x1f%s", sha)
    if metadata.returncode != 0:
        result["classification"] = "COMMIT_METADATA_UNAVAILABLE"
        result["diff_status"] = "DIFF_NOT_ATTEMPTED"
        result["changed_files"] = None
        result["changed_file_count"] = None
        result["source_files_changed"] = None
        result["additions"] = None
        result["deletions"] = None
        result["evidence"].append(
            "git show metadata failed: " + metadata.stderr.strip()
        )
        return result
    pieces = metadata.stdout.rstrip("\n").split("\x1f", 2)
    parents = pieces[0].split() if pieces else []
    result["parents"] = parents
    result["parent_count"] = len(parents)
    if len(pieces) > 1 and pieces[1].isdigit():
        result["commit_timestamp"] = int(pieces[1])
    if len(pieces) > 2:
        result["commit_subject"] = pieces[2]
    result["recorded_sha_role"] = (
        "MERGE_COMMIT"
        if result["parent_count"] > 1
        else "SINGLE_PARENT_COMMIT_ROLE_UNCONFIRMED"
    )
    ancestry = git(path, "merge-base", "--is-ancestor", sha, "HEAD")
    if ancestry.returncode == 0:
        result["reachable_from_head"] = True
        result["ancestry_status"] = "REACHABLE_FROM_HEAD"
    elif ancestry.returncode == 1:
        result["reachable_from_head"] = False
        result["ancestry_status"] = "NOT_REACHABLE_FROM_HEAD"
    else:
        result["reachable_from_head"] = None
        result["ancestry_status"] = "ANCESTRY_UNAVAILABLE"
        result["evidence"].append(
            f"Ancestry check returned {ancestry.returncode}: {ancestry.stderr.strip()}"
        )
    diff = inspect_commit_diff(path, sha, result["parent_count"] or 0)
    result.update(diff)
    pr_reference = inspect_local_pr_reference(path, pr_number)
    result["pr_reference_status"] = pr_reference["status"]
    result["pr_reference_commits"] = pr_reference["commits"]
    result["implementation_trace_status"] = (
        "RECORDED_SHA_DIFF_AVAILABLE"
        if result["diff_status"] == "DIFF_AVAILABLE"
        and result["source_files_changed"]
        else "RECORDED_SHA_HAS_NO_SOURCE_DIFF"
        if result["diff_status"] == "DIFF_AVAILABLE"
        else "RECORDED_SHA_DIFF_UNAVAILABLE"
    )
    if result["pr_reference_commits"]:
        result["implementation_trace_status"] += (
            "; LOCAL_PR_REFERENCE_SOURCE_DIFF_AVAILABLE"
            if any(
                item.get("diff_status") == "DIFF_AVAILABLE"
                and item.get("source_files_changed")
                for item in result["pr_reference_commits"]
            )
            else "; LOCAL_PR_REFERENCE_SOURCE_DIFF_UNAVAILABLE"
        )
    if result["parent_count"] != 1:
        result["classification"] = "REQUIRES_MERGE_MAPPING"
    elif result["reachable_from_head"] is None:
        result["classification"] = "ANCESTRY_UNAVAILABLE"
    elif result["reachable_from_head"] is False and result["pr_merged_recorded"].lower() == "true":
        result["classification"] = "REQUIRES_MERGE_MAPPING"
    elif result["reachable_from_head"] is False:
        result["classification"] = "NOT_ON_HEAD_HISTORY"
    elif result["diff_status"] != "DIFF_AVAILABLE":
        result["classification"] = "DIFF_UNAVAILABLE"
    elif not result["source_files_changed"]:
        result["classification"] = "UNSUITABLE_SOURCE_CHANGE"
    else:
        result["classification"] = "REACHABLE_FROM_HEAD"
    result["evidence"].extend(
        [
            f"git cat-file -t: {result['object_type']}",
            f"git merge-base --is-ancestor <sha> HEAD: {result['ancestry_status']}",
            f"parent count: {result['parent_count']}",
            (
                f"diff: {result['diff_status']} "
                f"({result['changed_file_count']}/{result['additions']}/{result['deletions']})"
            ),
        ]
    )
    if result["source_files_changed"]:
        result["evidence"].append(
            "Source paths: " + ", ".join(result["source_files_changed"])
        )
    if result["diff_error"]:
        result["evidence"].append(f"diff unavailable: {result['diff_error']}")
    result["evidence"].append(
        f"local PR-reference search: {result['pr_reference_status']}"
    )
    return result


def main() -> int:
    csv_results = {
        relative: inspect_csv(relative, required)
        for relative, required in REQUIRED_CSVS.items()
    }
    datasets = {
        relative: read_csv(relative)[0]
        for relative in REQUIRED_CSVS
        if (ROOT / relative).is_file()
    }
    config = datasets.get("config/research_repositories.csv", [])
    manifest_rows = datasets.get("config/repository_setup_manifest.csv", [])
    manifest = {row["Repository"]: row for row in manifest_rows}
    repository_results = [
        inspect_repository(row, manifest.get(row["repo_name"], {}))
        for row in config
    ]
    review_rows = datasets.get("data/bug_fix_review_auto.csv", [])
    config_by_name = {row["repo_name"]: row for row in config}
    fix_commits = [
        inspect_fix_commit(row, config_by_name[row["Repository"]])
        for row in review_rows
        if row.get("ReviewStatus") == "VERIFIED_FIX"
        and row.get("Repository") in config_by_name
    ]
    cache_path = ROOT / "data" / "bug_fix_review_timeline_cache.json"
    timeline_cache = {
        "exists": cache_path.is_file(),
        "valid_json": False,
        "record_count": None,
        "complete_count": None,
        "incomplete_count": None,
        "timeline_event_count": None,
        "cross_reference_event_count": None,
        "issue_key_mismatches": [],
    }
    if cache_path.is_file():
        try:
            cache_data = json.loads(cache_path.read_text(encoding="utf-8-sig"))
            records = cache_data.get("Records", [])
            sample_keys = {
                (row.get("Repository"), str(row.get("IssueNumber")))
                for row in datasets.get("data/bug_issue_samples.csv", [])
            }
            timeline_cache.update(
                {
                    "valid_json": True,
                    "record_count": len(records),
                    "complete_count": sum(
                        record.get("Complete") is True for record in records
                    ),
                    "incomplete_count": sum(
                        record.get("Complete") is not True for record in records
                    ),
                    "timeline_event_count": sum(
                        len(record.get("TimelineEvents", [])) for record in records
                    ),
                    "cross_reference_event_count": sum(
                        event.get("Event") == "cross-referenced"
                        for record in records
                        for event in record.get("TimelineEvents", [])
                    ),
                    "issue_key_mismatches": sorted(
                        {
                            f"{record.get('Repository')}#{record.get('IssueNumber')}"
                            for record in records
                            if (
                                record.get("Repository"),
                                str(record.get("IssueNumber")),
                            )
                            not in sample_keys
                        }
                    ),
                }
            )
        except (OSError, json.JSONDecodeError):
            pass
    directories = [
        "config",
        "data",
        "data/repositories",
        "docs",
        "scripts",
    ]
    environment = {
        "verified_at_local": datetime.now().astimezone().isoformat(),
        "project_root": str(ROOT),
        "git_version": subprocess.run(
            ["git", "--version"], capture_output=True, text=True, check=False
        ).stdout.strip(),
        "python_version": sys.version.split()[0],
        "directories": {
            relative: (ROOT / relative).is_dir() for relative in directories
        },
        "required_documents": {
            relative: (ROOT / relative).is_file() for relative in DOCUMENTS
        },
        "research_scripts": {
            relative: (ROOT / relative).is_file() for relative in SCRIPTS
        },
        "git_branch": git(ROOT, "branch", "--show-current").stdout.strip(),
        "git_head": git(ROOT, "rev-parse", "HEAD").stdout.strip(),
        "worktree_status": git(ROOT, "status", "--short").stdout.splitlines(),
    }
    relations = inspect_dataset_relations(datasets) if config and review_rows else {}
    result = {
        "environment": environment,
        "csv_files": csv_results,
        "dataset_relations": relations,
        "repositories": repository_results,
        "verified_fix_commits": fix_commits,
        "timeline_cache": timeline_cache,
        "summary": {
            "repositories_configured": len(config),
            "repositories_with_valid_local_git_and_object_checks": sum(
                row["git_worktree_valid"]
                and row["working_tree_status_exit_code"] == 0
                and row["tree_object_check_exit_code"] == 0
                and row["source_blob_check_exit_code"] == 0
                and row["missing_tree_object_count"] == 0
                and row["missing_source_blob_count"] == 0
                for row in repository_results
            ),
            "repositories_shallow": sum(
                row["is_shallow"] is True for row in repository_results
            ),
            "repository_object_check_failures": sum(
                row["tree_object_check_exit_code"] not in (None, 0)
                or row["source_blob_check_exit_code"] not in (None, 0)
                for row in repository_results
            ),
            "repositories_with_object_store_warnings": sum(
                row["status"].startswith("WARNING") for row in repository_results
            ),
            "verified_fix_records": len(fix_commits),
            "verified_fix_commits_found": sum(
                row["commit_found"] for row in fix_commits
            ),
            "verified_fix_commits_reachable": sum(
                row["reachable_from_head"] is True for row in fix_commits
            ),
            "verified_fix_source_changes": sum(
                bool(row["source_files_changed"])
                for row in fix_commits
                if row["diff_status"] == "DIFF_AVAILABLE"
            ),
            "verified_fix_diffs_unavailable": sum(
                row["diff_status"] == "DIFF_UNAVAILABLE" for row in fix_commits
            ),
            "verified_fix_local_pr_references_found": sum(
                row["pr_reference_status"] == "LOCAL_PR_REFERENCE_FOUND"
                for row in fix_commits
            ),
            "verified_fix_local_pr_source_diff_available_records": sum(
                any(
                    item.get("diff_status") == "DIFF_AVAILABLE"
                    and item.get("source_files_changed")
                    for item in row["pr_reference_commits"]
                )
                for row in fix_commits
            ),
            "verified_fix_local_pr_source_diff_unavailable_records": sum(
                row["pr_reference_status"] == "LOCAL_PR_REFERENCE_FOUND"
                and not any(
                    item.get("diff_status") == "DIFF_AVAILABLE"
                    and item.get("source_files_changed")
                    for item in row["pr_reference_commits"]
                )
                for row in fix_commits
            ),
            "verified_fix_classifications": dict(
                Counter(row["classification"] for row in fix_commits)
            ),
        },
    }
    OUTPUT.parent.mkdir(parents=True, exist_ok=True)
    OUTPUT.write_text(
        json.dumps(result, indent=2, ensure_ascii=False) + "\n",
        encoding="utf-8",
    )
    print(json.dumps(result["summary"], indent=2))
    print(f"Detailed output: {OUTPUT.relative_to(ROOT)}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
