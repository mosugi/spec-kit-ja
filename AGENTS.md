# AGENTS.md

## Spec KitとSpecifyについて

**GitHub Spec Kit**は、仕様駆動開発（SDD）を実装するための包括的なツールキットです。これは実装前に明確な仕様を作成することを重視する手法です。このツールキットには、開発チームを構造化されたソフトウェア構築アプローチに導くテンプレート、スクリプト、ワークフローが含まれています。

**Specify CLI**は、Spec Kitフレームワークでプロジェクトをブートストラップするコマンドラインインターフェイスです。仕様駆動開発ワークフローをサポートするために必要なディレクトリ構造、テンプレート、AIエージェント統合を設定します。

このツールキットは複数のAIコーディングアシスタントをサポートし、チームが一貫したプロジェクト構造と開発プラクティスを維持しながら、お好みのツールを使用できるようにします。

---

## 一般的なプラクティス

- Specify CLIの`__init__.py`へのいかなる変更も、`pyproject.toml`でのバージョンアップと`CHANGELOG.md`へのエントリ追加が必要です。

## 新しいエージェントサポートの追加

このセクションでは、Specify CLIに新しいAIエージェント/アシスタントのサポートを追加する方法を説明します。新しいAIツールを仕様駆動開発ワークフローに統合する際の参考としてこのガイドを使用してください。

### 概要

Specifyは、プロジェクト初期化時にエージェント固有のコマンドファイルとディレクトリ構造を生成することで、複数のAIエージェントをサポートします。各エージェントは以下に関して独自の規約を持ちます：

- **コマンドファイル形式**（Markdown、TOMLなど）
- **ディレクトリ構造**（`.claude/commands/`、`.windsurf/workflows/`など）
- **コマンド呼び出しパターン**（スラッシュコマンド、CLIツールなど）
- **引数渡し規約**（`$ARGUMENTS`、`{{args}}`など）

### 現在サポートされているエージェント

| エージェント | ディレクトリ | 形式 | CLIツール | 説明 |
|-------|-----------|---------|----------|-------------|
| **Claude Code** | `.claude/commands/` | Markdown | `claude` | AnthropicのClaude Code CLI |
| **Gemini CLI** | `.gemini/commands/` | TOML | `gemini` | GoogleのGemini CLI |
| **GitHub Copilot** | `.github/prompts/` | Markdown | N/A (IDEベース) | VS CodeのGitHub Copilot |
| **Cursor** | `.cursor/commands/` | Markdown | `cursor-agent` | Cursor CLI |
| **Qwen Code** | `.qwen/commands/` | TOML | `qwen` | AlibabaのQwen Code CLI |
| **opencode** | `.opencode/command/` | Markdown | `opencode` | opencode CLI |
| **Windsurf** | `.windsurf/workflows/` | Markdown | N/A (IDEベース) | Windsurf IDEワークフロー |

### ステップバイステップ統合ガイド

新しいエージェントを追加するために以下のステップに従ってください（Windsurfを例として）：

#### 1. AI_CHOICES定数の更新

`src/specify_cli/__init__.py`の`AI_CHOICES`辞書に新しいエージェントを追加します：

```python
AI_CHOICES = {
    "copilot": "GitHub Copilot",
    "claude": "Claude Code", 
    "gemini": "Gemini CLI",
    "cursor": "Cursor",
    "qwen": "Qwen Code",
    "opencode": "opencode",
    "windsurf": "Windsurf"  # Add new agent here
}
```

同じファイル内の`agent_folder_map`も更新して、セキュリティ通知のために新しいエージェントのフォルダを含めてください：

```python
agent_folder_map = {
    "claude": ".claude/",
    "gemini": ".gemini/",
    "cursor": ".cursor/",
    "qwen": ".qwen/",
    "opencode": ".opencode/",
    "codex": ".codex/",
    "windsurf": ".windsurf/",  # Add new agent folder here
    "kilocode": ".kilocode/",
    "auggie": ".auggie/",
    "copilot": ".github/"
}
```

#### 2. CLIヘルプテキストの更新

新しいエージェントを含むように、すべてのヘルプテキストと例を更新します：

- コマンドオプションヘルプ：`--ai`パラメータの説明
- 関数のdocstringと例
- エージェントリスト付きのエラーメッセージ

#### 3. README文書の更新

`README.md`の**サポートされたAIエージェント**セクションを更新して新しいエージェントを含めます：

- 適切なサポートレベル（Full/Partial）で新しいエージェントをテーブルに追加
- エージェントの公式ウェブサイトリンクを含める
- エージェントの実装に関する関連メモを追加
- テーブルの書式が整列され、一貫していることを確認

#### 4. Update Release Package Script

Modify `.github/workflows/scripts/create-release-packages.sh`:

##### Add to ALL_AGENTS array:
```bash
ALL_AGENTS=(claude gemini copilot cursor qwen opencode windsurf)
```

##### Add case statement for directory structure:
```bash
case $agent in
  # ... existing cases ...
  windsurf)
    mkdir -p "$base_dir/.windsurf/workflows"
    generate_commands windsurf md "\$ARGUMENTS" "$base_dir/.windsurf/workflows" "$script" ;;
esac
```

#### 4. Update GitHub Release Script

Modify `.github/workflows/scripts/create-github-release.sh` to include the new agent's packages:

```bash
gh release create "$VERSION" \
  # ... existing packages ...
  .genreleases/spec-kit-template-windsurf-sh-"$VERSION".zip \
  .genreleases/spec-kit-template-windsurf-ps-"$VERSION".zip \
  # Add new agent packages here
```

#### 5. Update Agent Context Scripts

##### Bash script (`scripts/bash/update-agent-context.sh`):

Add file variable:
```bash
WINDSURF_FILE="$REPO_ROOT/.windsurf/rules/specify-rules.md"
```

Add to case statement:
```bash
case "$AGENT_TYPE" in
  # ... existing cases ...
  windsurf) update_agent_file "$WINDSURF_FILE" "Windsurf" ;;
  "") 
    # ... existing checks ...
    [ -f "$WINDSURF_FILE" ] && update_agent_file "$WINDSURF_FILE" "Windsurf";
    # Update default creation condition
    ;;
esac
```

##### PowerShell script (`scripts/powershell/update-agent-context.ps1`):

Add file variable:
```powershell
$windsurfFile = Join-Path $repoRoot '.windsurf/rules/specify-rules.md'
```

Add to switch statement:
```powershell
switch ($AgentType) {
    # ... existing cases ...
    'windsurf' { Update-AgentFile $windsurfFile 'Windsurf' }
    '' {
        foreach ($pair in @(
            # ... existing pairs ...
            @{file=$windsurfFile; name='Windsurf'}
        )) {
            if (Test-Path $pair.file) { Update-AgentFile $pair.file $pair.name }
        }
        # Update default creation condition
    }
}
```

#### 6. Update CLI Tool Checks (Optional)

For agents that require CLI tools, add checks in the `check()` command and agent validation:

```python
# In check() command
tracker.add("windsurf", "Windsurf IDE (optional)")
windsurf_ok = check_tool_for_tracker("windsurf", "https://windsurf.com/", tracker)

# In init validation (only if CLI tool required)
elif selected_ai == "windsurf":
    if not check_tool("windsurf", "Install from: https://windsurf.com/"):
        console.print("[red]Error:[/red] Windsurf CLI is required for Windsurf projects")
        agent_tool_missing = True
```

**Note**: Skip CLI checks for IDE-based agents (Copilot, Windsurf).

## エージェントカテゴリ

### CLIベースエージェント
コマンドラインツールのインストールが必要：
- **Claude Code**: `claude` CLI
- **Gemini CLI**: `gemini` CLI
- **Cursor**: `cursor-agent` CLI
- **Qwen Code**: `qwen` CLI
- **opencode**: `opencode` CLI

### IDEベースエージェント
統合開発環境内で動作：
- **GitHub Copilot**: VS Code/互換エディタに組み込み
- **Windsurf**: Windsurf IDEに組み込み

## コマンドファイル形式

### Markdown形式
使用者：Claude、Cursor、opencode、Windsurf

```markdown
---
description: "コマンドの説明"
---

{SCRIPT}と$ARGUMENTSプレースホルダ付きのコマンド内容。
```

### TOML形式
使用者：Gemini、Qwen

```toml
description = "コマンドの説明"

prompt = """
{SCRIPT}と{{args}}プレースホルダ付きのコマンド内容。
"""
```

## ディレクトリ規約

- **CLIエージェント**: 通常`.<agent-name>/commands/`
- **IDEエージェント**: IDE固有のパターンに従う：
  - Copilot: `.github/prompts/`
  - Cursor: `.cursor/commands/`
  - Windsurf: `.windsurf/workflows/`

## 引数パターン

異なるエージェントは異なる引数プレースホルダを使用します：
- **Markdown/プロンプトベース**: `$ARGUMENTS`
- **TOMLベース**: `{{args}}`
- **スクリプトプレースホルダ**: `{SCRIPT}`（実際のスクリプトパスで置換）
- **エージェントプレースホルダ**: `__AGENT__`（エージェント名で置換）

## 新しいエージェント統合のテスト

1. **ビルドテスト**: パッケージ作成スクリプトをローカルで実行
2. **CLIテスト**: `specify init --ai <agent>` コマンドをテスト
3. **ファイル生成**: 正しいディレクトリ構造とファイルを検証
4. **コマンド検証**: 生成されたコマンドがエージェントで動作することを確認
5. **コンテキスト更新**: エージェントコンテキスト更新スクリプトをテスト

## よくある落とし穴

1. **更新スクリプトの忘れ**: bashとPowerShellスクリプトの両方を更新する必要があります
2. **CLIチェックの漏れ**: 実際にCLIツールを持つエージェントのみ追加
3. **間違った引数形式**: 各エージェントタイプに正しいプレースホルダ形式を使用
4. **ディレクトリ名**: エージェント固有の規約に正確に従う
5. **ヘルプテキストの非一貫性**: すべてのユーザー向けテキストを一貫して更新

## 将来の検討事項

新しいエージェントを追加する際は：
- エージェントのネイティブコマンド/ワークフローパターンを考慮
- 仕様駆動開発プロセスとの互換性を確保
- 特別な要件や制限を文書化
- 学んだ教訓でこのガイドを更新

---

*This documentation should be updated whenever new agents are added to maintain accuracy and completeness.*