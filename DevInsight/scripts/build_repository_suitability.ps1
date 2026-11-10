
$ErrorActionPreference = "Stop"

# Step 1: Load existing research files
$repos = @(Import-Csv "config\research_repositories.csv")
$screening = @(Import-Csv "data\repository_screening.csv")
$reviews = @(Import-Csv "data\bug_fix_review_auto.csv")

if ($repos.Count -ne 10) {
    throw "Expected 10 configured repositories."
}

if ($reviews.Count -ne 30) {
    throw "Expected 30 reviewed issues."
}

Write-Host "Building repository suitability matrix..." -ForegroundColor Cyan

# Step 2: Evaluate each repository
$matrix = @(
    foreach ($repo in $repos) {

        $name = $repo.repo_name

        $screenRows = @(
            $screening | Where-Object {
                $_.Repository -eq $name
            }
        )

        $items = @(
            $reviews | Where-Object {
                $_.Repository -eq $name
            }
        )

        if ($screenRows.Count -ne 1 -or $items.Count -ne 3) {
            throw "Incomplete or duplicate evidence: $name"
        }

        $s = $screenRows[0]

        if ($s.APIStatus -ne "OK") {
            throw "Incomplete screening API status: $name"
        }

        $verified = @(
            $items | Where-Object {
                $_.ReviewStatus -eq "VERIFIED_FIX"
            }
        ).Count

        $candidates = @(
            $items | Where-Object {
                $_.ReviewStatus -eq "CANDIDATE_FIX"
            }
        ).Count

        $noFix = @(
            $items | Where-Object {
                $_.ReviewStatus -eq "BUG_NO_FIX_LINK"
            }
        ).Count

        $notBug = @(
            $items | Where-Object {
                $_.ReviewStatus -eq "NOT_A_BUG"
            }
        ).Count

        $unclear = @(
            $items | Where-Object {
                $_.ReviewStatus -eq "UNCLEAR"
            }
        ).Count

        $apiErrors = @(
            $items | Where-Object {
                $_.ReviewStatus -eq "API_ERROR"
            }
        ).Count

        if (($verified + $candidates + $noFix + $notBug + $unclear + $apiErrors) -ne 3) {
            throw "Invalid review classification: $name"
        }

        $sampleStatus = if ($verified -gt 0) {
            "PROMISING_SAMPLE"
        }
        else {
            "FURTHER_REVIEW"
        }

        [PSCustomObject]@{
            Repository = $name
            Language = $repo.language
            Commits = [int]$s.Commits
            SourceFiles = [int]$s.SourceFiles
            WorkflowFiles = [int]$s.WorkflowFiles
            BugLabels = $s.BugLikeLabels
            ReviewedIssues = $items.Count
            VerifiedFixes = $verified
            CandidateFixes = $candidates
            BugsWithoutFix = $noFix
            NotABug = $notBug
            Unclear = $unclear
            APIErrors = $apiErrors
            SampleAssessment = $sampleStatus
            Selection = "PROVISIONAL_KEEP"
        }
    }
)

# Step 3: Save matrix
$matrixPath = "data\repository_suitability_matrix.csv"

$matrix | Export-Csv `
    -Path $matrixPath `
    -NoTypeInformation `
    -Encoding UTF8

# Step 4: Calculate summary
$promising = @(
    $matrix | Where-Object {
        $_.SampleAssessment -eq "PROMISING_SAMPLE"
    }
).Count

$furtherReview = @(
    $matrix | Where-Object {
        $_.SampleAssessment -eq "FURTHER_REVIEW"
    }
).Count

$verifiedTotal = ($matrix | Measure-Object -Property VerifiedFixes -Sum).Sum
$candidateTotal = ($matrix | Measure-Object -Property CandidateFixes -Sum).Sum

# Step 5: Prepare Markdown report
$reportLines = @(
    "# DevInsight - First-Half Repository Selection Report"
    ""
    "## 1. Objective"
    ""
    "Document the provisional selection of ten public GitHub repositories for the first 50% project evaluation."
    ""
    "## 2. Dataset Scope"
    ""
    "- Repositories: $($matrix.Count)"
    "- Python repositories: 5"
    "- Dart repositories: 5"
    "- Reviewed GitHub issues: 30"
    "- Verified fix relationships in sample: $verifiedTotal"
    "- Candidate fix relationships in sample: $candidateTotal"
    ""
    "## 3. Repository Assessment"
    ""
    "| Repository | Language | Commits | Workflow Files | Verified Fixes | Candidates | Assessment |"
    "|---|---|---:|---:|---:|---:|---|"
)

foreach ($item in $matrix) {
    $reportLines += "| $($item.Repository) | $($item.Language) | $($item.Commits) | $($item.WorkflowFiles) | $($item.VerifiedFixes) | $($item.CandidateFixes) | $($item.SampleAssessment) |"
}

$reportLines += @(
    ""
    "## 4. Initial Findings"
    ""
    "- Repositories with at least one verified fix in the three-issue sample: $promising"
    "- Repositories needing further fix evidence: $furtherReview"
    "- All ten repositories are retained provisionally."
    ""
    "## 5. Research Limitations"
    ""
    "- Three issues per repository are insufficient for a final repository-wide quality judgment."
    "- Candidate PRs must not be treated as merged fixes."
    "- Commit counts are not equivalent to labeled ML training observations."
    "- Workflow configuration files do not establish CI run history or CI reliability."
    "- This report is a preliminary repository selection, not final research validation."
    ""
    "## 6. First-Half Evaluation Scope"
    ""
    "Completed: Repository cloning, history verification, screening, initial bug audit, and evidence review."
    ""
    "Deferred: Full historical dataset extraction, defect-label validation, ML training, RQ1/RQ2 experiments, and RQ3."
    ""
    "## 7. Provisional Selection Decision"
    ""
    "Retain all ten repositories for the next development stage, with targeted quality checks required for weaker evidence samples."
    ""
    "## 8. Supporting Evidence"
    ""
    "- config/research_repositories.csv"
    "- config/repository_setup_manifest.csv"
    "- data/repository_screening.csv"
    "- data/repository_bug_audit.csv"
    "- data/bug_fix_review_auto.csv"
    "- docs/bug_fix_evidence_review.md"
)

$reportPath = "docs\repository_selection_first_half.md"

$reportLines | Set-Content `
    -Path $reportPath `
    -Encoding UTF8

# Step 6: Display results
$matrix | Format-Table `
    Repository, Language, Commits, VerifiedFixes, `
    CandidateFixes, SampleAssessment `
    -AutoSize

Write-Host "`nSuitability preparation completed!" -ForegroundColor Green

Write-Host "Total repositories:" $matrix.Count
Write-Host "Promising samples:" $promising
Write-Host "Further review required:" $furtherReview
Write-Host "Verified fixes in samples:" $verifiedTotal
Write-Host "Candidate fixes in samples:" $candidateTotal

Write-Host "`nGenerated files:"
Write-Host $matrixPath
Write-Host $reportPath
