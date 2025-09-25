#!/usr/bin/env pwsh

# 統合前提条件チェックスクリプト（PowerShell版）
#
# このスクリプトはSpec-Driven Developmentワークフローの統一された前提条件チェックを提供します。
# 以前は複数のスクリプトに分散していた機能を統合したものです。
#
# 使用方法: ./check-prerequisites.ps1 [オプション]
#
# オプション:
#   -Json               JSON形式で出力
#   -RequireTasks       tasks.mdの存在を必須とする（実装フェーズ用）
#   -IncludeTasks       AVAILABLE_DOCSリストにtasks.mdを含める
#   -PathsOnly          パス変数のみを出力（検証なし）
#   -Help, -h           ヘルプメッセージを表示

[CmdletBinding()]
param(
    [switch]$Json,
    [switch]$RequireTasks,
    [switch]$IncludeTasks,
    [switch]$PathsOnly,
    [switch]$Help
)

$ErrorActionPreference = 'Stop'

# ヘルプが要求された場合は表示
if ($Help) {
    Write-Output @"
Usage: check-prerequisites.ps1 [OPTIONS]

Consolidated prerequisite checking for Spec-Driven Development workflow.

OPTIONS:
  -Json               Output in JSON format
  -RequireTasks       Require tasks.md to exist (for implementation phase)
  -IncludeTasks       Include tasks.md in AVAILABLE_DOCS list
  -PathsOnly          Only output path variables (no prerequisite validation)
  -Help, -h           Show this help message

EXAMPLES:
  # Check task prerequisites (plan.md required)
  .\check-prerequisites.ps1 -Json
  
  # Check implementation prerequisites (plan.md + tasks.md required)
  .\check-prerequisites.ps1 -Json -RequireTasks -IncludeTasks
  
  # Get feature paths only (no validation)
  .\check-prerequisites.ps1 -PathsOnly

"@
    exit 0
}

# 共通関数を読み込み
. "$PSScriptRoot/common.ps1"

# フィーチャーパスを取得してブランチを検証
$paths = Get-FeaturePathsEnv

if (-not (Test-FeatureBranch -Branch $paths.CURRENT_BRANCH -HasGit:$paths.HAS_GIT)) { 
    exit 1 
}

# パスのみモードの場合、パスを出力して終了（-Json -PathsOnlyの組み合わせをサポート）
if ($PathsOnly) {
    if ($Json) {
        [PSCustomObject]@{
            REPO_ROOT    = $paths.REPO_ROOT
            BRANCH       = $paths.CURRENT_BRANCH
            FEATURE_DIR  = $paths.FEATURE_DIR
            FEATURE_SPEC = $paths.FEATURE_SPEC
            IMPL_PLAN    = $paths.IMPL_PLAN
            TASKS        = $paths.TASKS
        } | ConvertTo-Json -Compress
    } else {
        Write-Output "REPO_ROOT: $($paths.REPO_ROOT)"
        Write-Output "BRANCH: $($paths.CURRENT_BRANCH)"
        Write-Output "FEATURE_DIR: $($paths.FEATURE_DIR)"
        Write-Output "FEATURE_SPEC: $($paths.FEATURE_SPEC)"
        Write-Output "IMPL_PLAN: $($paths.IMPL_PLAN)"
        Write-Output "TASKS: $($paths.TASKS)"
    }
    exit 0
}

# 必要なディレクトリとファイルを検証
if (-not (Test-Path $paths.FEATURE_DIR -PathType Container)) {
    Write-Output "ERROR: Feature directory not found: $($paths.FEATURE_DIR)"
    Write-Output "Run /specify first to create the feature structure."
    exit 1
}

if (-not (Test-Path $paths.IMPL_PLAN -PathType Leaf)) {
    Write-Output "ERROR: plan.md not found in $($paths.FEATURE_DIR)"
    Write-Output "Run /plan first to create the implementation plan."
    exit 1
}

# 必要な場合はtasks.mdの存在をチェック
if ($RequireTasks -and -not (Test-Path $paths.TASKS -PathType Leaf)) {
    Write-Output "ERROR: tasks.md not found in $($paths.FEATURE_DIR)"
    Write-Output "Run /tasks first to create the task list."
    exit 1
}

# 利用可能なドキュメントのリストを構築
$docs = @()

# これらのオプションドキュメントを常にチェック
if (Test-Path $paths.RESEARCH) { $docs += 'research.md' }
if (Test-Path $paths.DATA_MODEL) { $docs += 'data-model.md' }

# contractsディレクトリをチェック（存在し、ファイルがある場合のみ）
if ((Test-Path $paths.CONTRACTS_DIR) -and (Get-ChildItem -Path $paths.CONTRACTS_DIR -ErrorAction SilentlyContinue | Select-Object -First 1)) { 
    $docs += 'contracts/' 
}

if (Test-Path $paths.QUICKSTART) { $docs += 'quickstart.md' }

# 要求され、存在する場合はtasks.mdを含める
if ($IncludeTasks -and (Test-Path $paths.TASKS)) { 
    $docs += 'tasks.md' 
}

# 結果を出力
if ($Json) {
    # JSON出力
    [PSCustomObject]@{ 
        FEATURE_DIR = $paths.FEATURE_DIR
        AVAILABLE_DOCS = $docs 
    } | ConvertTo-Json -Compress
} else {
    # テキスト出力
    Write-Output "FEATURE_DIR:$($paths.FEATURE_DIR)"
    Write-Output "AVAILABLE_DOCS:"
    
    # 各潜在的なドキュメントのステータスを表示
    Test-FileExists -Path $paths.RESEARCH -Description 'research.md' | Out-Null
    Test-FileExists -Path $paths.DATA_MODEL -Description 'data-model.md' | Out-Null
    Test-DirHasFiles -Path $paths.CONTRACTS_DIR -Description 'contracts/' | Out-Null
    Test-FileExists -Path $paths.QUICKSTART -Description 'quickstart.md' | Out-Null
    
    if ($IncludeTasks) {
        Test-FileExists -Path $paths.TASKS -Description 'tasks.md' | Out-Null
    }
}