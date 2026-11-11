$ErrorActionPreference = "Stop"

$inputPath = "data\bug_issue_samples.csv"
$cachePath = "data\bug_fix_review_timeline_cache.json"
$headers = @{
    Accept = "application/vnd.github+json"
    "User-Agent" = "DevInsight-Bug-Fix-Evidence-Review"
    "X-GitHub-Api-Version" = "2022-11-28"
}

if (-not [string]::IsNullOrWhiteSpace($env:GITHUB_TOKEN)) {
    $headers.Authorization = "Bearer $env:GITHUB_TOKEN"
}

$cache = @{}
if (Test-Path $cachePath) {
    $cachedDocument = Get-Content -Raw $cachePath | ConvertFrom-Json
    foreach ($record in $cachedDocument.records) {
        if ($record.Complete -and $record.TimelineFormatVersion -ne 3) {
            $normalizedEvents = @()
            $sourceText = (@($record.TimelineEvents) | ForEach-Object {
                [string]$_.SourceURL
            }) -join " "
            $sourceURLs = @(
                [regex]::Matches($sourceText, "https://github\.com/[^\s;]+") |
                    ForEach-Object { $_.Value } |
                    Select-Object -Unique
            )
            $crossReferenceIndex = 0

            foreach ($oldEvent in @($record.TimelineEvents)) {
                $eventNames = @($oldEvent.Event)
                for ($index = 0; $index -lt $eventNames.Count; $index++) {
                    $sourceUrl = ""
                    $sourceTitle = ""
                    $sourceNumber = $null
                    $isPullRequest = $false

                    if ($eventNames[$index] -eq "cross-referenced") {
                        if ($crossReferenceIndex -lt $sourceURLs.Count) {
                            $sourceUrl = $sourceURLs[$crossReferenceIndex]
                        }
                        $crossReferenceIndex++
                        $isPullRequest = $sourceUrl -match "/pull/"
                    }

                    $commitSHA = $null
                    if ($oldEvent.CommitSHA -is [array]) {
                        $commitSHA = $oldEvent.CommitSHA[$index]
                    } else {
                        $commitSHA = $oldEvent.CommitSHA
                    }

                    $createdAt = $null
                    if ($oldEvent.CreatedAt -is [array]) {
                        $createdAt = $oldEvent.CreatedAt[$index]
                    } else {
                        $createdAt = $oldEvent.CreatedAt
                    }

                    $normalizedEvents += [PSCustomObject]@{
                        Event = [string]$eventNames[$index]
                        CreatedAt = $createdAt
                        CommitSHA = $commitSHA
                        SourceURL = $sourceUrl
                        SourceTitle = $sourceTitle
                        SourceNumber = $sourceNumber
                        SourceIsPullRequest = $isPullRequest
                    }
                }
            }
            $record.TimelineEvents = @($normalizedEvents)
            $record | Add-Member -NotePropertyName TimelineFormatVersion -NotePropertyValue 3 -Force
        }
        $cache["$($record.Repository)#$($record.IssueNumber)"] = $record
    }
}

function Save-TimelineCache {
    $document = [PSCustomObject]@{
        UpdatedAtUTC = [DateTime]::UtcNow.ToString("o")
        Records = @($cache.Values | Sort-Object Repository, IssueNumber)
    }
    $json = ConvertTo-Json -InputObject $document -Depth 20
    [System.IO.File]::WriteAllText(
        (Join-Path (Get-Location) $cachePath),
        $json,
        (New-Object System.Text.UTF8Encoding($false))
    )
}

function Get-HttpStatus {
    param($ErrorRecord)
    if ($ErrorRecord.Exception.Response) {
        try {
            return [int]$ErrorRecord.Exception.Response.StatusCode
        } catch {
            return 0
        }
    }
    return 0
}

$issues = @(Import-Csv $inputPath)
foreach ($issue in $issues) {
    $key = "$($issue.Repository)#$($issue.IssueNumber)"
    if ($cache.ContainsKey($key) -and $cache[$key].Complete) {
        Write-Host "Cached: $key"
        continue
    }

    $timeline = @()
    $nextUrl = "https://api.github.com/repos/$($issue.Repository)/issues/$($issue.IssueNumber)/timeline?per_page=100"
    $failure = ""
    $rateLimited = $false

    while ($nextUrl) {
        $response = $null
        for ($attempt = 1; $attempt -le 3; $attempt++) {
            try {
                $response = Invoke-WebRequest `
                    -UseBasicParsing `
                    -Uri $nextUrl `
                    -Headers $headers `
                    -Method Get `
                    -TimeoutSec 30 `
                    -ErrorAction Stop
                break
            } catch {
                $status = Get-HttpStatus $_
                if ($status -in @(403, 429)) {
                    $retryAfter = $_.Exception.Response.Headers["Retry-After"]
                    $resetAt = $_.Exception.Response.Headers["X-RateLimit-Reset"]
                    $failure = "HTTP $status; Retry-After=$retryAfter; X-RateLimit-Reset=$resetAt"
                    $rateLimited = $true
                    break
                }

                if (($status -ge 500 -and $status -le 599) -or $status -eq 0) {
                    if ($attempt -lt 3) {
                        Start-Sleep -Seconds ([Math]::Pow(2, $attempt - 1))
                        continue
                    }
                }
                $failure = if ($status) {
                    "HTTP $status; $($_.Exception.Message)"
                } else {
                    "Request failed after $attempt attempt(s): $($_.Exception.Message)"
                }
                break
            }
        }

        if (-not $response) {
            break
        }

        try {
            $events = ConvertFrom-Json -InputObject $response.Content
        } catch {
            $failure = "Incomplete JSON response: $($_.Exception.Message)"
            break
        }

        if ($null -eq $events -and $response.Content.Trim() -ne "[]") {
            $failure = "Incomplete timeline response: JSON contained no event collection."
            break
        }

        foreach ($event in $events) {
            $sourceIssue = $event.source.issue
            $timeline += [PSCustomObject]@{
                Event = $event.event
                CreatedAt = $event.created_at
                CommitSHA = $event.commit_id
                SourceURL = if ($sourceIssue) { $sourceIssue.html_url } else { "" }
                SourceTitle = if ($sourceIssue) { $sourceIssue.title } else { "" }
                SourceNumber = if ($sourceIssue) { $sourceIssue.number } else { $null }
                SourceIsPullRequest = [bool]($sourceIssue.pull_request)
            }
        }

        $nextUrl = $null
        $linkHeader = $response.Headers["Link"]
        if ($linkHeader -match '<([^>]+)>;\s*rel="next"') {
            $nextUrl = $Matches[1]
        }
    }

    $record = [PSCustomObject]@{
        Repository = $issue.Repository
        IssueNumber = $issue.IssueNumber
        IssueURL = $issue.URL
        Complete = [string]::IsNullOrEmpty($failure)
        Error = $failure
        TimelineEvents = @($timeline)
        TimelineFormatVersion = 3
        CheckedAtUTC = [DateTime]::UtcNow.ToString("o")
    }
    $cache[$key] = $record
    Save-TimelineCache

    if ($failure) {
        Write-Warning "${key}: $failure"
    } else {
        Write-Host "Retrieved $key ($($timeline.Count) timeline event(s))"
    }

    if ($rateLimited) {
        Write-Warning "Stopped on rate limiting. Completed timeline results are checkpointed in $cachePath; rerun after the indicated reset."
        break
    }
}

$completed = @($cache.Values | Where-Object { $_.Complete }).Count
Save-TimelineCache
Write-Host "Complete timelines: $completed / $($issues.Count)"
Write-Host "Cache: $cachePath"
