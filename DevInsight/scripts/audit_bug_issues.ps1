
param(
    [switch]$Pilot
)

$ErrorActionPreference = "Stop"

$repos = @(
    Import-Csv "config\research_repositories.csv"
)

$bugLabels = @{
    "encode/httpx" = "bug"
    "fastapi/fastapi" = "bug"
    "pallets/flask" = "bug"
    "pydantic/pydantic" = "bug V2"
    "pytest-dev/pytest" = "type: bug"
    "felangel/bloc" = "bug"
    "rrousselGit/riverpod" = "bug"
    "cfug/dio" = "s: bug"
    "firebase/flutterfire" = "type: bug"
    "fluttercommunity/plus_plugins" = "bug"
}

if ($Pilot) {
    $repos = @(
        $repos | Where-Object {
            $_.repo_name -in @(
                "fastapi/fastapi",
                "felangel/bloc"
            )
        }
    )
}

$headers = @{
    Accept = "application/vnd.github+json"
    "User-Agent" = "DevInsight-Research-Audit"
    "X-GitHub-Api-Version" = "2022-11-28"
}

$rate = Invoke-RestMethod `
    -Uri "https://api.github.com/rate_limit" `
    -Headers $headers `
    -TimeoutSec 30

$remaining = [int]$rate.resources.core.remaining

Write-Host "GitHub API requests remaining: $remaining"

if ($remaining -lt $repos.Count) {
    throw "Insufficient API quota. Do not rerun until the limit resets."
}

$summary = @()
$samples = @()

foreach ($repo in $repos) {

    $name = $repo.repo_name
    $label = $bugLabels[$name]

    if (-not $label) {
        throw "Missing bug label for $name"
    }

    Write-Host "`nAuditing: $name" -ForegroundColor Cyan

    $encodedLabel = [Uri]::EscapeDataString($label)

    $url = "https://api.github.com/repos/$name/issues" +
           "?state=all&labels=$encodedLabel&per_page=100"

    try {
        $rawResponse = Invoke-RestMethod `
            -Uri $url `
            -Headers $headers `
            -Method Get `
            -TimeoutSec 40 `
            -ErrorAction Stop

        # Explicitly enumerate the API response.
        # Avoid treating a JSON array as one object.
        $records = @()

        foreach ($item in $rawResponse) {
            if ($item -is [array]) {
                foreach ($nested in $item) {
                    $records += $nested
                }
            }
            else {
                $records += $item
            }
        }

        $issues = @(
            $records | Where-Object {
                $null -eq $_.pull_request
            }
        )

        $prs = @(
            $records | Where-Object {
                $null -ne $_.pull_request
            }
        )

        Write-Host "API records: $($records.Count)"
        Write-Host "Bug issues: $($issues.Count)"
        Write-Host "PR records: $($prs.Count)"

        $summary += [PSCustomObject]@{
            Repository = $name
            Language = $repo.language
            LabelUsed = $label
            BugIssueSample = $issues.Count
            PRsInSample = $prs.Count
            PageLimitReached = ($records.Count -eq 100)
            Status = "OK"
        }

        foreach ($issue in ($issues | Select-Object -First 3)) {
            $samples += [PSCustomObject]@{
                Repository = $name
                IssueNumber = $issue.number
                Title = $issue.title
                State = $issue.state
                URL = $issue.html_url
                CreatedAt = $issue.created_at
                ClosedAt = $issue.closed_at
                VerifiedFixLink = "Not reviewed"
            }
        }
    }
    catch {
        Write-Warning "Failed: ${name}: $($_.Exception.Message)"

        $summary += [PSCustomObject]@{
            Repository = $name
            Language = $repo.language
            LabelUsed = $label
            BugIssueSample = -1
            PRsInSample = -1
            PageLimitReached = $false
            Status = "API_ERROR"
        }
    }

    Start-Sleep -Milliseconds 600
}

$suffix = if ($Pilot) { "_pilot" } else { "" }

$summaryPath = "data/repository_bug_audit$suffix.csv"
$samplesPath = "data/bug_issue_samples$suffix.csv"

$summary | Export-Csv `
    -Path $summaryPath `
    -NoTypeInformation `
    -Encoding UTF8

$samples | Export-Csv `
    -Path $samplesPath `
    -NoTypeInformation `
    -Encoding UTF8

$summary | Format-Table `
    Repository, LabelUsed, BugIssueSample, `
    PRsInSample, PageLimitReached, Status `
    -AutoSize

Write-Host "`nAudit finished." -ForegroundColor Green
Write-Host "Repositories audited:" $summary.Count
Write-Host "Report:" $summaryPath
Write-Host "Samples:" $samplesPath
