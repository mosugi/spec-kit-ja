#!/usr/bin/env pwsh
<#!
.SYNOPSIS
plan.mdの情報でエージェントコンテキストファイルを更新（PowerShell版）

.DESCRIPTION
scripts/bash/update-agent-context.shの動作をミラー:
 1. 環境検証
 2. プランデータ抜き出し
 3. エージェントファイル管理（テンプレートから作成または既存を更新）
 4. コンテンツ生成（技術スタック、最近の変更、タイムスタンプ）
 5. マルチエージェントサポート (claude, gemini, copilot, cursor, qwen, opencode, codex, windsurf)

.PARAMETER AgentType
単一のエージェントを更新するためのオプションのエージェントキー。省略された場合、すべての既存エージェントファイルを更新（存在しない場合はデフォルトのClaudeファイルを作成）。

.EXAMPLE
./update-agent-context.ps1 -AgentType claude

.EXAMPLE
./update-agent-context.ps1   # Updates all existing agent files

.NOTES
common.ps1の共通ヘルパー関数に依存
#>
param(
    [Parameter(Position=0)]
    [ValidateSet('claude','gemini','copilot','cursor','qwen','opencode','codex','windsurf','kilocode','auggie','roo')]
    [string]$AgentType
)

$ErrorActionPreference = 'Stop'

# 共通ヘルパーをインポート
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
. (Join-Path $ScriptDir 'common.ps1')

# 環境パスを取得
$envData = Get-FeaturePathsEnv
$REPO_ROOT     = $envData.REPO_ROOT
$CURRENT_BRANCH = $envData.CURRENT_BRANCH
$HAS_GIT       = $envData.HAS_GIT
$IMPL_PLAN     = $envData.IMPL_PLAN
$NEW_PLAN = $IMPL_PLAN

# エージェントファイルパス
$CLAUDE_FILE   = Join-Path $REPO_ROOT 'CLAUDE.md'
$GEMINI_FILE   = Join-Path $REPO_ROOT 'GEMINI.md'
$COPILOT_FILE  = Join-Path $REPO_ROOT '.github/copilot-instructions.md'
$CURSOR_FILE   = Join-Path $REPO_ROOT '.cursor/rules/specify-rules.mdc'
$QWEN_FILE     = Join-Path $REPO_ROOT 'QWEN.md'
$AGENTS_FILE   = Join-Path $REPO_ROOT 'AGENTS.md'
$WINDSURF_FILE = Join-Path $REPO_ROOT '.windsurf/rules/specify-rules.md'
$KILOCODE_FILE = Join-Path $REPO_ROOT '.kilocode/rules/specify-rules.md'
$AUGGIE_FILE   = Join-Path $REPO_ROOT '.augment/rules/specify-rules.md'
$ROO_FILE      = Join-Path $REPO_ROOT '.roo/rules/specify-rules.md'

$TEMPLATE_FILE = Join-Path $REPO_ROOT '.specify/templates/agent-file-template.md'

# 解析されたプランデータのプレースホルダー
$script:NEW_LANG = ''
$script:NEW_FRAMEWORK = ''
$script:NEW_DB = ''
$script:NEW_PROJECT_TYPE = ''

function Write-Info { 
    param(
        [Parameter(Mandatory=$true)]
        [string]$Message
    )
    Write-Host "INFO: $Message" 
}

function Write-Success { 
    param(
        [Parameter(Mandatory=$true)]
        [string]$Message
    )
    Write-Host "$([char]0x2713) $Message" 
}

function Write-WarningMsg { 
    param(
        [Parameter(Mandatory=$true)]
        [string]$Message
    )
    Write-Warning $Message 
}

function Write-Err { 
    param(
        [Parameter(Mandatory=$true)]
        [string]$Message
    )
    Write-Host "ERROR: $Message" -ForegroundColor Red 
}

function Validate-Environment {
    if (-not $CURRENT_BRANCH) {
        Write-Err '現在のフィーチャーを特定できません'
        if ($HAS_GIT) { Write-Info "フィーチャーブランチにいることを確認してください" } else { Write-Info 'SPECIFY_FEATURE環境変数を設定するか、まずフィーチャーを作成してください' }
        exit 1
    }
    if (-not (Test-Path $NEW_PLAN)) {
        Write-Err "$NEW_PLANにplan.mdが見つかりません"
        Write-Info '対応するspecディレクトリを持つフィーチャーで作業していることを確認してください'
        if (-not $HAS_GIT) { Write-Info '使用方法: $env:SPECIFY_FEATURE=your-feature-name またはまず新しいフィーチャーを作成してください' }
        exit 1
    }
    if (-not (Test-Path $TEMPLATE_FILE)) {
        Write-Err "$TEMPLATE_FILEにテンプレートファイルが見つかりません"
        Write-Info 'specify initを実行して.specify/templatesをスキャフォールドするか、agent-file-template.mdをそこに追加してください。'
        exit 1
    }
}

function Extract-PlanField {
    param(
        [Parameter(Mandatory=$true)]
        [string]$FieldPattern,
        [Parameter(Mandatory=$true)]
        [string]$PlanFile
    )
    if (-not (Test-Path $PlanFile)) { return '' }
    # **Language/Version**: Python 3.12 のような行
    $regex = "^\*\*$([Regex]::Escape($FieldPattern))\*\*: (.+)$"
    Get-Content -LiteralPath $PlanFile | ForEach-Object {
        if ($_ -match $regex) { 
            $val = $Matches[1].Trim()
            if ($val -notin @('明確化が必要','N/A')) { return $val }
        }
    } | Select-Object -First 1
}

function Parse-PlanData {
    param(
        [Parameter(Mandatory=$true)]
        [string]$PlanFile
    )
    if (-not (Test-Path $PlanFile)) { Write-Err "Plan file not found: $PlanFile"; return $false }
    Write-Info "$PlanFileからプランデータを解析中"
    $script:NEW_LANG        = Extract-PlanField -FieldPattern 'Language/Version' -PlanFile $PlanFile
    $script:NEW_FRAMEWORK   = Extract-PlanField -FieldPattern 'Primary Dependencies' -PlanFile $PlanFile
    $script:NEW_DB          = Extract-PlanField -FieldPattern 'Storage' -PlanFile $PlanFile
    $script:NEW_PROJECT_TYPE = Extract-PlanField -FieldPattern 'Project Type' -PlanFile $PlanFile

    if ($NEW_LANG) { Write-Info "言語を発見: $NEW_LANG" } else { Write-WarningMsg 'プランに言語情報が見つかりません' }
    if ($NEW_FRAMEWORK) { Write-Info "フレームワークを発見: $NEW_FRAMEWORK" }
    if ($NEW_DB -and $NEW_DB -ne 'N/A') { Write-Info "データベースを発見: $NEW_DB" }
    if ($NEW_PROJECT_TYPE) { Write-Info "プロジェクトタイプを発見: $NEW_PROJECT_TYPE" }
    return $true
}

function Format-TechnologyStack {
    param(
        [Parameter(Mandatory=$false)]
        [string]$Lang,
        [Parameter(Mandatory=$false)]
        [string]$Framework
    )
    $parts = @()
    if ($Lang -and $Lang -ne '明確化が必要') { $parts += $Lang }
    if ($Framework -and $Framework -notin @('明確化が必要','N/A')) { $parts += $Framework }
    if (-not $parts) { return '' }
    return ($parts -join ' + ')
}

function Get-ProjectStructure { 
    param(
        [Parameter(Mandatory=$false)]
        [string]$ProjectType
    )
    if ($ProjectType -match 'web') { return "backend/`nfrontend/`ntests/" } else { return "src/`ntests/" } 
}

function Get-CommandsForLanguage { 
    param(
        [Parameter(Mandatory=$false)]
        [string]$Lang
    )
    switch -Regex ($Lang) {
        'Python' { return "cd src; pytest; ruff check ." }
        'Rust' { return "cargo test; cargo clippy" }
        'JavaScript|TypeScript' { return "npm test; npm run lint" }
        default { return "# $Lang用のコマンドを追加" }
    }
}

function Get-LanguageConventions { 
    param(
        [Parameter(Mandatory=$false)]
        [string]$Lang
    )
    if ($Lang) { "${Lang}: 標準的な規約に従う" } else { '一般: 標準的な規約に従う' } 
}

function New-AgentFile {
    param(
        [Parameter(Mandatory=$true)]
        [string]$TargetFile,
        [Parameter(Mandatory=$true)]
        [string]$ProjectName,
        [Parameter(Mandatory=$true)]
        [datetime]$Date
    )
    if (-not (Test-Path $TEMPLATE_FILE)) { Write-Err "$TEMPLATE_FILEにテンプレートが見つかりません"; return $false }
    $temp = New-TemporaryFile
    Copy-Item -LiteralPath $TEMPLATE_FILE -Destination $temp -Force

    $projectStructure = Get-ProjectStructure -ProjectType $NEW_PROJECT_TYPE
    $commands = Get-CommandsForLanguage -Lang $NEW_LANG
    $languageConventions = Get-LanguageConventions -Lang $NEW_LANG

    $escaped_lang = $NEW_LANG
    $escaped_framework = $NEW_FRAMEWORK
    $escaped_branch = $CURRENT_BRANCH

    $content = Get-Content -LiteralPath $temp -Raw
    $content = $content -replace '\[PROJECT NAME\]',$ProjectName
    $content = $content -replace '\[DATE\]',$Date.ToString('yyyy-MM-dd')
    
    # 技術スタック文字列を安全に構築
    $techStackForTemplate = ""
    if ($escaped_lang -and $escaped_framework) {
        $techStackForTemplate = "- $escaped_lang + $escaped_framework ($escaped_branch)"
    } elseif ($escaped_lang) {
        $techStackForTemplate = "- $escaped_lang ($escaped_branch)"
    } elseif ($escaped_framework) {
        $techStackForTemplate = "- $escaped_framework ($escaped_branch)"
    }
    
    $content = $content -replace '\[EXTRACTED FROM ALL PLAN.MD FILES\]',$techStackForTemplate
    # プロジェクト構造は手動で埋め込み（改行を維持）
    $escapedStructure = [Regex]::Escape($projectStructure)
    $content = $content -replace '\[ACTUAL STRUCTURE FROM PLANS\]',$escapedStructure
    # すべての置換後にエスケープされた改行プレースホルダーを置換
    $content = $content -replace '\[ONLY COMMANDS FOR ACTIVE TECHNOLOGIES\]',$commands
    $content = $content -replace '\[LANGUAGE-SPECIFIC, ONLY FOR LANGUAGES IN USE\]',$languageConventions
    
    # 最近の変更文字列を安全に構築
    $recentChangesForTemplate = ""
    if ($escaped_lang -and $escaped_framework) {
        $recentChangesForTemplate = "- ${escaped_branch}: Added ${escaped_lang} + ${escaped_framework}"
    } elseif ($escaped_lang) {
        $recentChangesForTemplate = "- ${escaped_branch}: Added ${escaped_lang}"
    } elseif ($escaped_framework) {
        $recentChangesForTemplate = "- ${escaped_branch}: Added ${escaped_framework}"
    }
    
    $content = $content -replace '\[LAST 3 FEATURES AND WHAT THEY ADDED\]',$recentChangesForTemplate
    # Escapeで導入されたリテラル\nシーケンスを実際の改行に変換
    $content = $content -replace '\\n',[Environment]::NewLine

    $parent = Split-Path -Parent $TargetFile
    if (-not (Test-Path $parent)) { New-Item -ItemType Directory -Path $parent | Out-Null }
    Set-Content -LiteralPath $TargetFile -Value $content -NoNewline
    Remove-Item $temp -Force
    return $true
}

function Update-ExistingAgentFile {
    param(
        [Parameter(Mandatory=$true)]
        [string]$TargetFile,
        [Parameter(Mandatory=$true)]
        [datetime]$Date
    )
    if (-not (Test-Path $TargetFile)) { return (New-AgentFile -TargetFile $TargetFile -ProjectName (Split-Path $REPO_ROOT -Leaf) -Date $Date) }

    $techStack = Format-TechnologyStack -Lang $NEW_LANG -Framework $NEW_FRAMEWORK
    $newTechEntries = @()
    if ($techStack) {
        $escapedTechStack = [Regex]::Escape($techStack)
        if (-not (Select-String -Pattern $escapedTechStack -Path $TargetFile -Quiet)) { 
            $newTechEntries += "- $techStack ($CURRENT_BRANCH)" 
        }
    }
    if ($NEW_DB -and $NEW_DB -notin @('N/A','明確化が必要')) {
        $escapedDB = [Regex]::Escape($NEW_DB)
        if (-not (Select-String -Pattern $escapedDB -Path $TargetFile -Quiet)) { 
            $newTechEntries += "- $NEW_DB ($CURRENT_BRANCH)" 
        }
    }
    $newChangeEntry = ''
    if ($techStack) { $newChangeEntry = "- ${CURRENT_BRANCH}: Added ${techStack}" }
    elseif ($NEW_DB -and $NEW_DB -notin @('N/A','明確化が必要')) { $newChangeEntry = "- ${CURRENT_BRANCH}: Added ${NEW_DB}" }

    $lines = Get-Content -LiteralPath $TargetFile
    $output = New-Object System.Collections.Generic.List[string]
    $inTech = $false; $inChanges = $false; $techAdded = $false; $changeAdded = $false; $existingChanges = 0

    for ($i=0; $i -lt $lines.Count; $i++) {
        $line = $lines[$i]
        if ($line -eq '## Active Technologies') {
            $output.Add($line)
            $inTech = $true
            continue
        }
        if ($inTech -and $line -match '^##\s') {
            if (-not $techAdded -and $newTechEntries.Count -gt 0) { $newTechEntries | ForEach-Object { $output.Add($_) }; $techAdded = $true }
            $output.Add($line); $inTech = $false; continue
        }
        if ($inTech -and [string]::IsNullOrWhiteSpace($line)) {
            if (-not $techAdded -and $newTechEntries.Count -gt 0) { $newTechEntries | ForEach-Object { $output.Add($_) }; $techAdded = $true }
            $output.Add($line); continue
        }
        if ($line -eq '## Recent Changes') {
            $output.Add($line)
            if ($newChangeEntry) { $output.Add($newChangeEntry); $changeAdded = $true }
            $inChanges = $true
            continue
        }
        if ($inChanges -and $line -match '^##\s') { $output.Add($line); $inChanges = $false; continue }
        if ($inChanges -and $line -match '^- ') {
            if ($existingChanges -lt 2) { $output.Add($line); $existingChanges++ }
            continue
        }
        if ($line -match '\*\*Last updated\*\*: .*\d{4}-\d{2}-\d{2}') {
            $output.Add(($line -replace '\d{4}-\d{2}-\d{2}',$Date.ToString('yyyy-MM-dd')))
            continue
        }
        $output.Add($line)
    }

    # ループ後チェック: まだActive Technologiesセクションにいて新しいエントリを追加していない場合
    if ($inTech -and -not $techAdded -and $newTechEntries.Count -gt 0) {
        $newTechEntries | ForEach-Object { $output.Add($_) }
    }

    Set-Content -LiteralPath $TargetFile -Value ($output -join [Environment]::NewLine)
    return $true
}

function Update-AgentFile {
    param(
        [Parameter(Mandatory=$true)]
        [string]$TargetFile,
        [Parameter(Mandatory=$true)]
        [string]$AgentName
    )
    if (-not $TargetFile -or -not $AgentName) { Write-Err 'Update-AgentFileはTargetFileとAgentNameが必要です'; return $false }
    Write-Info "$AgentNameコンテキストファイルを更新中: $TargetFile"
    $projectName = Split-Path $REPO_ROOT -Leaf
    $date = Get-Date

    $dir = Split-Path -Parent $TargetFile
    if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Path $dir | Out-Null }

    if (-not (Test-Path $TargetFile)) {
        if (New-AgentFile -TargetFile $TargetFile -ProjectName $projectName -Date $date) { Write-Success "新しい$AgentNameコンテキストファイルを作成しました" } else { Write-Err '新しいエージェントファイルの作成に失敗しました'; return $false }
    } else {
        try {
            if (Update-ExistingAgentFile -TargetFile $TargetFile -Date $date) { Write-Success "既存の$AgentNameコンテキストファイルを更新しました" } else { Write-Err 'エージェントファイルの更新に失敗しました'; return $false }
        } catch {
            Write-Err "既存ファイルにアクセスまたは更新できません: $TargetFile. $_"
            return $false
        }
    }
    return $true
}

function Update-SpecificAgent {
    param(
        [Parameter(Mandatory=$true)]
        [string]$Type
    )
    switch ($Type) {
        'claude'   { Update-AgentFile -TargetFile $CLAUDE_FILE   -AgentName 'Claude Code' }
        'gemini'   { Update-AgentFile -TargetFile $GEMINI_FILE   -AgentName 'Gemini CLI' }
        'copilot'  { Update-AgentFile -TargetFile $COPILOT_FILE  -AgentName 'GitHub Copilot' }
        'cursor'   { Update-AgentFile -TargetFile $CURSOR_FILE   -AgentName 'Cursor IDE' }
        'qwen'     { Update-AgentFile -TargetFile $QWEN_FILE     -AgentName 'Qwen Code' }
        'opencode' { Update-AgentFile -TargetFile $AGENTS_FILE   -AgentName 'opencode' }
        'codex'    { Update-AgentFile -TargetFile $AGENTS_FILE   -AgentName 'Codex CLI' }
        'windsurf' { Update-AgentFile -TargetFile $WINDSURF_FILE -AgentName 'Windsurf' }
        'kilocode' { Update-AgentFile -TargetFile $KILOCODE_FILE -AgentName 'Kilo Code' }
        'auggie'   { Update-AgentFile -TargetFile $AUGGIE_FILE   -AgentName 'Auggie CLI' }
        'roo'      { Update-AgentFile -TargetFile $ROO_FILE      -AgentName 'Roo Code' }
        default { Write-Err "不明なエージェントタイプ '$Type'"; Write-Err '期待値: claude|gemini|copilot|cursor|qwen|opencode|codex|windsurf|kilocode|auggie|roo'; return $false }
    }
}

function Update-AllExistingAgents {
    $found = $false
    $ok = $true
    if (Test-Path $CLAUDE_FILE)   { if (-not (Update-AgentFile -TargetFile $CLAUDE_FILE   -AgentName 'Claude Code')) { $ok = $false }; $found = $true }
    if (Test-Path $GEMINI_FILE)   { if (-not (Update-AgentFile -TargetFile $GEMINI_FILE   -AgentName 'Gemini CLI')) { $ok = $false }; $found = $true }
    if (Test-Path $COPILOT_FILE)  { if (-not (Update-AgentFile -TargetFile $COPILOT_FILE  -AgentName 'GitHub Copilot')) { $ok = $false }; $found = $true }
    if (Test-Path $CURSOR_FILE)   { if (-not (Update-AgentFile -TargetFile $CURSOR_FILE   -AgentName 'Cursor IDE')) { $ok = $false }; $found = $true }
    if (Test-Path $QWEN_FILE)     { if (-not (Update-AgentFile -TargetFile $QWEN_FILE     -AgentName 'Qwen Code')) { $ok = $false }; $found = $true }
    if (Test-Path $AGENTS_FILE)   { if (-not (Update-AgentFile -TargetFile $AGENTS_FILE   -AgentName 'Codex/opencode')) { $ok = $false }; $found = $true }
    if (Test-Path $WINDSURF_FILE) { if (-not (Update-AgentFile -TargetFile $WINDSURF_FILE -AgentName 'Windsurf')) { $ok = $false }; $found = $true }
    if (Test-Path $KILOCODE_FILE) { if (-not (Update-AgentFile -TargetFile $KILOCODE_FILE -AgentName 'Kilo Code')) { $ok = $false }; $found = $true }
    if (Test-Path $AUGGIE_FILE)   { if (-not (Update-AgentFile -TargetFile $AUGGIE_FILE   -AgentName 'Auggie CLI')) { $ok = $false }; $found = $true }
    if (Test-Path $ROO_FILE)      { if (-not (Update-AgentFile -TargetFile $ROO_FILE      -AgentName 'Roo Code')) { $ok = $false }; $found = $true }
    if (-not $found) {
        Write-Info '既存のエージェントファイルが見つかりません、デフォルトのClaudeファイルを作成中...'
        if (-not (Update-AgentFile -TargetFile $CLAUDE_FILE -AgentName 'Claude Code')) { $ok = $false }
    }
    return $ok
}

function Print-Summary {
    Write-Host ''
    Write-Info '変更の概要:'
    if ($NEW_LANG) { Write-Host "  - 追加された言語: $NEW_LANG" }
    if ($NEW_FRAMEWORK) { Write-Host "  - 追加されたフレームワーク: $NEW_FRAMEWORK" }
    if ($NEW_DB -and $NEW_DB -ne 'N/A') { Write-Host "  - 追加されたデータベース: $NEW_DB" }
    Write-Host ''
    Write-Info '使用方法: ./update-agent-context.ps1 [-AgentType claude|gemini|copilot|cursor|qwen|opencode|codex|windsurf|kilocode|auggie|roo]'
}

function Main {
    Validate-Environment
    Write-Info "=== フィーチャー $CURRENT_BRANCH のエージェントコンテキストファイルを更新中 ==="
    if (-not (Parse-PlanData -PlanFile $NEW_PLAN)) { Write-Err 'プランデータの解析に失敗しました'; exit 1 }
    $success = $true
    if ($AgentType) {
        Write-Info "特定のエージェントを更新中: $AgentType"
        if (-not (Update-SpecificAgent -Type $AgentType)) { $success = $false }
    }
    else {
        Write-Info 'エージェントが指定されていません、すべての既存エージェントファイルを更新中...'
        if (-not (Update-AllExistingAgents)) { $success = $false }
    }
    Print-Summary
    if ($success) { Write-Success 'エージェントコンテキストの更新が正常に完了しました'; exit 0 } else { Write-Err 'エージェントコンテキストの更新がエラーで完了しました'; exit 1 }
}

Main
