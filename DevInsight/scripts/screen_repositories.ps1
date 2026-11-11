
param(
    [switch]$Pilot
)

$ErrorActionPreference = "Stop"

$configPath = "config\research_repositories.csv"
$outputPath = "data\repository_screening.csv"

$repos = @(Import-Csv $configPath)

if ($repos.Count -ne 10) {
    throw "Expected 10 repositories in configuration."
}

if ($Pilot) {
    $repos = @($repos | Where-Object {
        $_.repo_name -in @("encode/httpx", "felangel/bloc")
    })
}

$headers = @{
    "Accept" = "application/vnd.github+json"
    "User-Agent" = "DevInsight-Research-Screening"
}

function Get-GitHubSample {
    param([string]$Url)

    try {
        $response = Invoke-RestMethod `
            -Uri $Url `
            -Headers $headers `
            -Method Get `
            -TimeoutSec 40

        return [PSCustomObject]@{
            Success = $true
            Data = @($response)
            Error = ""
        }
    }
    catch {
        $statusCode = [int]$_.Exception.Response.StatusCode

        if ($statusCode -in @(403, 429)) {
            throw "GitHub API rejected requests (HTTP $statusCode). Stop and check rate limits or access."
        }

        return [PSCustomObject]@{
            Success = $false
            Data = @()
            Error = $_.Exception.Message
        }
    }
}

$results = foreach ($repo in $repos) {

    Write-Host "`nScreening $($repo.repo_name)" -ForegroundColor Cyan

    $path = Join-Path "data\repositories" $repo.folder_name

    if (-not (Test-Path (Join-Path $path ".git"))) {
        Write-Warning "Missing clone: $($repo.repo_name)"
        continue
    }

    # Local Git history
    $commitCount = [int](git -C $path rev-list --count HEAD)
    if ($LASTEXITCODE -ne 0) {
        throw "Git history error: $($repo.repo_name)"
    }

    # Target-language tracked files
    $files = @(git -C $path ls-files)

    $extension = if ($repo.language -eq "Python") {
        "\.py$"
    } else {
        "\.dart$"
    }

    $sourceCount = @(
        $files | Where-Object { $_ -match $extension }
    ).Count

    # GitHub Actions workflow files (not CI success)
    $workflowCount = @(
        $files | Where-Object {
            $_ -match '^\.github/workflows/[^/]+\.(yml|yaml)$'
        }
    ).Count

    $apiBase = "https://api.github.com/repos/$($repo.repo_name)"

    # These endpoints fetch samples, not complete history.
    $issues = Get-GitHubSample "$apiBase/issues?state=all&sort=updated&direction=desc&per_page=100"
    Start-Sleep -Milliseconds 400

    $pulls = Get-GitHubSample "$apiBase/pulls?state=all&sort=updated&direction=desc&per_page=100"
    Start-Sleep -Milliseconds 400

    $labels = Get-GitHubSample "$apiBase/labels?per_page=100"
    Start-Sleep -Milliseconds 400

    $issueRows = @()
    $bugLabels = @()

    if ($issues.Success) {
        $issueRows = @($issues.Data | Where-Object {
            $null -eq $_.pull_request
        })
    }

    if ($labels.Success) {
        $bugLabels = @(
            $labels.Data | Where-Object {
                $_.name -match '(?i)(^|[\s:/-])(bug|defect|regression)(?=$|[\s:/-])'
            } | ForEach-Object { $_.name }
        )
    }

    $apiStatus = if (
        $issues.Success -and
        $pulls.Success -and
        $labels.Success
    ) {
        "OK"
    } else {
        "PARTIAL"
    }

    [PSCustomObject]@{
        Repository = $repo.repo_name
        Language = $repo.language
        Commits = $commitCount
        SourceFiles = $sourceCount
        WorkflowFiles = $workflowCount
        IssueSample = if ($issues.Success) { $issueRows.Count } else { -1 }
        PRSample = if ($pulls.Success) { $pulls.Data.Count } else { -1 }
        BugLikeLabels = ($bugLabels -join "; ")
        APIStatus = $apiStatus
        Decision = "Manual review required"
    }
}

$results | Export-Csv `
    -Path $outputPath `
    -NoTypeInformation `
    -Encoding UTF8

$results | Format-Table `
    Repository, Language, Commits, SourceFiles, `
    WorkflowFiles, IssueSample, PRSample, APIStatus `
    -AutoSize

Write-Host "`nReport saved: $outputPath" -ForegroundColor Green
Write-Host "Repositories screened:" $results.Count

if ($results.Count -ne $repos.Count) {
    Write-Warning "Some configured repositories were not screened."
}
