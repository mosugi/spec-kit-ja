# インストールガイド

## 前提条件

- **Linux/macOS**（またはWindows; WSLなしでPowerShellスクリプトがサポートされています）
- AIコーディングエージェント: [Claude Code](https://www.anthropic.com/claude-code)、[GitHub Copilot](https://code.visualstudio.com/)、または[Gemini CLI](https://github.com/google-gemini/gemini-cli)
- パッケージ管理用の[uv](https://docs.astral.sh/uv/)
- [Python 3.11+](https://www.python.org/downloads/)
- [Git](https://git-scm.com/downloads)

## インストール

### 新しいプロジェクトの初期化

最も簡単な方法は、新しいプロジェクトを初期化することです：

```bash
uvx --from git+https://github.com/mosugi/spec-kit-ja.git specify init <PROJECT_NAME>
```

または現在のディレクトリで初期化する場合：

```bash
uvx --from git+https://github.com/mosugi/spec-kit-ja.git specify init --here
```

### AIエージェントの指定

初期化時にAIエージェントを事前に指定できます：

```bash
uvx --from git+https://github.com/mosugi/spec-kit-ja.git specify init <project_name> --ai claude
uvx --from git+https://github.com/mosugi/spec-kit-ja.git specify init <project_name> --ai gemini
uvx --from git+https://github.com/mosugi/spec-kit-ja.git specify init <project_name> --ai copilot
```

### スクリプトタイプの指定（Shell vs PowerShell）

すべての自動化スクリプトには、Bash（`.sh`）とPowerShell（`.ps1`）の両方のバリエーションがあります。

自動動作：
- Windowsデフォルト：`ps`
- その他のOSデフォルト：`sh`
- インタラクティブモード：`--script`を渡さない限りプロンプトが表示されます

特定のスクリプトタイプを強制する場合：
```bash
uvx --from git+https://github.com/mosugi/spec-kit-ja.git specify init <project_name> --script sh
uvx --from git+https://github.com/mosugi/spec-kit-ja.git specify init <project_name> --script ps
```

### エージェントツールチェックを無視

適切なツールをチェックせずにテンプレートを取得したい場合：

```bash
uvx --from git+https://github.com/mosugi/spec-kit-ja.git specify init <project_name> --ai claude --ignore-agent-tools
```

## 動作確認

初期化後、AIエージェントで以下のコマンドが利用可能になっているはずです：
- `/specify` - 仕様書の作成
- `/plan` - 実装計画の生成
- `/tasks` - 実行可能なタスクへの分解

`.specify/scripts`ディレクトリには`.sh`と`.ps1`の両方のスクリプトが含まれます。

## トラブルシューティング

### LinuxでのGit Credential Manager

LinuxでGit認証に問題がある場合は、Git Credential Managerをインストールできます：

```bash
#!/usr/bin/env bash
set -e
echo "Git Credential Manager v2.6.1をダウンロードしています..."
wget https://github.com/git-ecosystem/git-credential-manager/releases/download/v2.6.1/gcm-linux_amd64.2.6.1.deb
echo "Git Credential Managerをインストールしています..."
sudo dpkg -i gcm-linux_amd64.2.6.1.deb
echo "GitでGCMを使用するように設定しています..."
git config --global credential.helper manager
echo "クリーンアップ中..."
rm gcm-linux_amd64.2.6.1.deb
```
