> [!NOTE]
> このリポジトリは [Spec Kit](https://github.com/github/spec-kit) の非公式の日本語翻訳版です。
> オリジナルのリポジトリは GitHub, Inc. が管理しており、最新の更新や公式サポートはそちらで提供されています。
> この翻訳版はコミュニティによって維持されており、内容の正確性や最新性については保証されません。
> 最新版に追従する機能なども日本語版には含まれない場合がありますので、実験的な用途にのみご利用ください。

<div align="center">
    <img src="./media/logo_small.webp"/>
    <h1>🌱 Spec Kit</h1>
    <h3><em>高品質なソフトウェアをより高速に構築しましょう。</em></h3>
</div>

<p align="center">
    <strong>仕様駆動開発の支援によって、組織が差別化されていないコードの記述ではなくプロダクトシナリオに集中できるようにする取り組みです。</strong>
</p>

[![Release](https://github.com/github/spec-kit/actions/workflows/release.yml/badge.svg)](https://github.com/github/spec-kit/actions/workflows/release.yml)

---

## 目次

- [🤔 仕様駆動開発とは？](#-仕様駆動開発とは)
- [⚡ 始め方](#-始め方)
- [📽️ ビデオ概要](#️-ビデオ概要)
- [🤖 サポートされたAIエージェント](#-サポートされたaiエージェント)
- [🔧 Specify CLIリファレンス](#-specify-cliリファレンス)
- [📚 コア哲学](#-コア哲学)
- [🌟 開発フェーズ](#-開発フェーズ)
- [🎯 実験目標](#-実験目標)
- [🔧 前提条件](#-前提条件)
- [📖 さらに学ぶ](#-さらに学ぶ)
- [📋 詳細なプロセス](#-詳細なプロセス)
- [🔍 トラブルシューティング](#-トラブルシューティング)
- [👥 メンテナ](#-メンテナ)
- [💬 サポート](#-サポート)
- [🙏 謝辞](#-謝辞)
- [📄 ライセンス](#-ライセンス)

## 🤔 仕様駆動開発とは？

仕様駆動開発は、従来のソフトウェア開発の**台本をヒックリ返します**。何十年もの間、コードこそが王でした—仕様書は、コーディングという「本当の作業」が始まると構築しては破棄してしまう足場に過ぎませんでした。仕様駆動開発はこれを変えます：**仕様書が実行可能になり**、単に導くだけでなく直接動作する実装を生成します。

## ⚡ 始め方

### 1. Specifyのインストール

使用したいインストール方法を選択してください：

#### オプション1：永続インストール（推奨）

一度インストールしてどこでも使用：

```bash
uv tool install specify-cli --from git+https://github.com/mosugi/spec-kit-ja.git
```

次に、ツールを直接使用：

```bash
specify init <PROJECT_NAME>
specify check
```

#### オプション2：一度だけの使用

インストールなしで直接実行：

```bash
uvx --from git+https://github.com/mosugi/spec-kit-ja.git specify init <PROJECT_NAME>
```

**永続インストールのメリット：**

- ツールがインストールされ、PATHで使用可能
- シェルエイリアスを作成する必要がない
- `uv tool list`、`uv tool upgrade`、`uv tool uninstall`によるより良いツール管理
- よりクリーンなシェル設定

### 2. プロジェクト原則の確立

**`/constitution`**コマンドを使用して、その後のすべての開発を導くプロジェクトの基本原則と開発ガイドラインを作成します。

```bash
/constitution コード品質、テスト基準、ユーザーエクスペリエンスの一貫性、パフォーマンス要件に焦点を当てた原則を作成する
```

### 3. 仕様の作成

**`/specify`**コマンドを使用して、何を構築したいかを説明します。技術スタックではなく、**何**と**なぜ**に焦点を当ててください。

```bash
/specify 写真を別々のフォトアルバムで整理できるアプリケーションを構築する。アルバムは日付でグループ化され、メインページでドラッグアンドドロップで再構成できる。アルバムは他のネストしたアルバム内にはない。各アルバム内では、写真はタイル状のインターフェースでプレビューされる。
```

### 4. 技術実装計画の作成

**`/plan`**コマンドを使用して、技術スタックとアーキテクチャの選択を提供します。

```bash
/plan アプリケーションは最小限のライブラリでViteを使用する。可能な限りバニラHTML、CSS、JavaScriptを使用する。画像はどこにもアップロードされず、メタデータはローカルのSQLiteデータベースに保存される。
```

### 5. タスクに分解

**`/tasks`**を使用して、実装計画から実行可能なタスクリストを作成します。

```bash
/tasks
```

### 6. 実装の実行

**`/implement`**を使用して、すべてのタスクを実行し、計画に従って機能を構築します。

```bash
/implement
```

詳細な手順については、[包括的なガイド](./spec-driven.md)をご覧ください。

## 📽️ ビデオ概要

Spec Kitの動作を確認したいですか？[ビデオ概要](https://www.youtube.com/watch?v=a9eR1xsfvHg&pp=0gcJCckJAYcqIYzv)をご覧ください！

[![Spec Kit video header](/media/spec-kit-video-header.jpg)](https://www.youtube.com/watch?v=a9eR1xsfvHg&pp=0gcJCckJAYcqIYzv)

## 🤖 サポートされたAIエージェント

| エージェント                                                     | サポート | 備考                                             |
|-----------------------------------------------------------|---------|---------------------------------------------------|
| [Claude Code](https://www.anthropic.com/claude-code)      | ✅ |                                                   |
| [GitHub Copilot](https://code.visualstudio.com/)          | ✅ |                                                   |
| [Gemini CLI](https://github.com/google-gemini/gemini-cli) | ✅ |                                                   |
| [Cursor](https://cursor.sh/)                              | ✅ |                                                   |
| [Qwen Code](https://github.com/QwenLM/qwen-code)          | ✅ |                                                   |
| [opencode](https://opencode.ai/)                          | ✅ |                                                   |
| [Windsurf](https://windsurf.com/)                         | ✅ |                                                   |
| [Kilo Code](https://github.com/Kilo-Org/kilocode)         | ✅ |                                                   |
| [Auggie CLI](https://docs.augmentcode.com/cli/overview)   | ✅ |                                                   |
| [Roo Code](https://roocode.com/)                          | ✅ |                                                   |
| [Codex CLI](https://github.com/openai/codex)              | ⚠️ | Codexは[サポートしていません](https://github.com/openai/codex/issues/2890)スラッシュコマンドのカスタム引数を。  |

## 🔧 Specify CLIリファレンス

`specify`コマンドは以下のオプションをサポートしています：

### コマンド

| コマンド     | 説明                                                    |
|-------------|----------------------------------------------------------------|
| `init`      | 最新テンプレートから新しいSpecifyプロジェクトを初期化      |
| `check`     | インストール済みツールをチェック (`git`, `claude`, `gemini`, `code`/`code-insiders`, `cursor-agent`, `windsurf`, `qwen`, `opencode`, `codex`) |

### `specify init` 引数とオプション

| 引数/オプション        | タイプ     | 説明                                                                  |
|------------------------|----------|------------------------------------------------------------------------------|
| `<project-name>`       | 引数 | 新しいプロジェクトディレクトリ名 (`--here`使用時は省略可)            |
| `--ai`                 | オプション   | 使用するAIアシスタント: `claude`, `gemini`, `copilot`, `cursor`, `qwen`, `opencode`, `codex`, `windsurf`, `kilocode`, `auggie`, or `roo` |
| `--script`             | オプション   | 使用するスクリプト種別: `sh` (bash/zsh) または `ps` (PowerShell)                 |
| `--ignore-agent-tools` | フラグ     | Claude CodeなどのAIエージェントツールのチェックをスキップ                             |
| `--no-git`             | フラグ     | gitリポジトリの初期化をスキップ                                          |
| `--here`               | フラグ     | 新しいディレクトリを作成せず、現在のディレクトリでプロジェクトを初期化   |
| `--force`              | フラグ     | 空でないディレクトリで`--here`使用時に強制マージ/上書き（確認をスキップ） |
| `--skip-tls`           | フラグ     | SSL/TLS検証をスキップ（推奨されません）                                 |
| `--debug`              | フラグ     | トラブルシューティング用の詳細デバッグ出力を有効化                            |
| `--github-token`       | オプション   | API要求用GitHubトークン（またはGH_TOKEN/GITHUB_TOKEN環境変数を設定）  |

### 例

```bash
# 基本的なプロジェクト初期化
specify init my-project

# 特定のAIアシスタントで初期化
specify init my-project --ai claude

# Cursorサポートで初期化
specify init my-project --ai cursor

# Windsurfサポートで初期化
specify init my-project --ai windsurf

# PowerShellスクリプトで初期化（Windows/クロスプラットフォーム）
specify init my-project --ai copilot --script ps

# 現在のディレクトリで初期化
specify init --here --ai copilot

# 確認なしで現在の（空でない）ディレクトリに強制マージ
specify init --here --force --ai copilot

# git初期化をスキップ
specify init my-project --ai gemini --no-git

# トラブルシューティング用デバッグ出力を有効化
specify init my-project --ai claude --debug

# API要求用GitHubトークンを使用（企業環境で有用）
specify init my-project --ai claude --github-token ghp_your_token_here

# システム要件をチェック
specify check
```

### 利用可能なスラッシュコマンド

`specify init`実行後、AIコーディングエージェントは構造化開発のために以下のスラッシュコマンドにアクセスできます：

| コマンド         | 説明                                                           |
|-----------------|-----------------------------------------------------------------------|
| `/constitution` | プロジェクトの基本原則と開発ガイドラインを作成または更新 |
| `/specify`      | 構築したいものを定義（要件とユーザーストーリー）        |
| `/clarify`      | 不明確な領域を明確化（明示的にスキップしない限り`/plan`前に実行必須；以前の`/quizme`） |
| `/plan`         | 選択した技術スタックで技術実装計画を作成     |
| `/tasks`        | 実装用の実行可能なタスクリストを生成                     |
| `/analyze`      | クロス成果物の一貫性とカバレッジ分析（/tasks後、/implement前に実行） |
| `/implement`    | 計画に従って機能を構築するためにすべてのタスクを実行         |

### 環境変数

| 変数         | 説明                                                                                    |
|------------------|------------------------------------------------------------------------------------------------|
| `SPECIFY_FEATURE` | Git以外のリポジトリの機能検出を上書き。Gitブランチを使用しない場合に特定の機能で作業するため、機能ディレクトリ名（例：`001-photo-albums`）に設定。<br/>**`/plan`またはフォローアップコマンド使用前に、作業しているエージェントのコンテキストで設定する必要があります。 |

## 📚 コア哲学

仕様駆動開発は以下を重視する構造化されたプロセスです：

- **意図駆動開発** - 「_方法_」の前に仕様が「_何_」を定義
- **豊富な仕様作成** - ガードレールと組織原則を使用
- **多段階の洗練** - プロンプトからのワンショットコード生成ではなく
- **高度な依存** - 仕様解釈のための先進AI モデル能力への

## 🌟 開発フェーズ

| フェーズ | 焦点 | 主要活動 |
|-------|-------|----------------|
| **0から1の開発**（「グリーンフィールド」） | ゼロから生成 | <ul><li>高レベル要件から開始</li><li>仕様を生成</li><li>実装ステップを計画</li><li>本番対応アプリケーションを構築</li></ul> |
| **創造的探索** | 並行実装 | <ul><li>多様なソリューションを探索</li><li>複数の技術スタックとアーキテクチャをサポート</li><li>UXパターンを実験</li></ul> |
| **反復的強化**（「ブラウンフィールド」） | ブラウンフィールド近代化 | <ul><li>機能を反復的に追加</li><li>レガシーシステムを近代化</li><li>プロセスを適応</li></ul> |

## 🎯 実験目標

私たちの研究と実験は以下に焦点を当てています：

### 技術独立性

- 多様な技術スタックを使用してアプリケーションを作成
- 仕様駆動開発が特定の技術、プログラミング言語、フレームワークに縛られないプロセスという仮説を検証

### 企業制約

- ミッションクリティカルなアプリケーション開発を実証
- 組織的制約（クラウドプロバイダー、技術スタック、エンジニアリング実践）を組み込み
- 企業デザインシステムとコンプライアンス要件をサポート

### ユーザー中心の開発

- 異なるユーザーコホートと好みに向けたアプリケーションを構築
- 様々な開発アプローチをサポート（バイブコーディングからAIネイティブ開発まで）

### 創造的で反復的なプロセス

- 並行実装探索の概念を検証
- 堅牢な反復的機能開発ワークフローを提供
- アップグレードと近代化タスクを処理するプロセスを拡張

## 🔧 前提条件

- **Linux/macOS**（またはWindows上のWSL2）
- AIコーディングエージェント：[Claude Code](https://www.anthropic.com/claude-code)、[GitHub Copilot](https://code.visualstudio.com/)、[Gemini CLI](https://github.com/google-gemini/gemini-cli)、[Cursor](https://cursor.sh/)、[Qwen CLI](https://github.com/QwenLM/qwen-code)、[opencode](https://opencode.ai/)、[Codex CLI](https://github.com/openai/codex)、または[Windsurf](https://windsurf.com/)
- パッケージ管理用の[uv](https://docs.astral.sh/uv/)
- [Python 3.11+](https://www.python.org/downloads/)
- [Git](https://git-scm.com/downloads)

エージェントで問題が発生した場合は、統合を改善できるようissueを開いてください。

## 📖 さらに学ぶ

- **[完全な仕様駆動開発方法論](./spec-driven.md)** - 全プロセスの詳細な説明
- **[詳細なウォークスルー](#-詳細なプロセス)** - ステップバイステップ実装ガイド

---

## 📋 詳細なプロセス

<details>
<summary>クリックして詳細なステップバイステップウォークスルーを展開</summary>

Specify CLIを使用してプロジェクトをブートストラップできます。これにより、環境に必要なアーティファクトが持ち込まれます。実行：

```bash
specify init <project_name>
```

または現在のディレクトリで初期化：

```bash
specify init --here
# ディレクトリに既にファイルがある場合の確認をスキップ
specify init --here --force
```

![Specify CLI bootstrapping a new project in the terminal](./media/specify_cli.gif)

使用しているAIエージェントを選択するよう求められます。ターミナルで直接事前に指定することもできます：

```bash
specify init <project_name> --ai claude
specify init <project_name> --ai gemini
specify init <project_name> --ai copilot
specify init <project_name> --ai cursor
specify init <project_name> --ai qwen
specify init <project_name> --ai opencode
specify init <project_name> --ai codex
specify init <project_name> --ai windsurf
# または現在のディレクトリで：
specify init --here --ai claude
specify init --here --ai codex
# 空でない現在のディレクトリに強制マージ
specify init --here --force --ai claude
```

CLIはClaude Code、Gemini CLI、Cursor CLI、Qwen CLI、opencode、またはCodex CLIがインストールされているかチェックします。インストールされていない場合、または適切なツールをチェックせずにテンプレートを取得したい場合は、コマンドに`--ignore-agent-tools`を使用してください：

```bash
specify init <project_name> --ai claude --ignore-agent-tools
```

### **ステップ1：** プロジェクト原則の確立

プロジェクトフォルダに移動し、AIエージェントを実行します。この例では`claude`を使用しています。

![Bootstrapping Claude Code environment](./media/bootstrap-claude-code.gif)

`/constitution`、`/specify`、`/plan`、`/tasks`、`/implement`コマンドが利用可能であることを確認できれば、正しく設定されています。

最初のステップは、`/constitution`コマンドを使用してプロジェクトの基本原則を確立することです。これにより、その後のすべての開発フェーズで一貫した意思決定を確保できます：

```text
/constitution コード品質、テスト基準、ユーザーエクスペリエンスの一貫性、パフォーマンス要件に焦点を当てた原則を作成する。これらの原則が技術的決定と実装選択をどのように導くべきかのガバナンスを含める。
```

このステップでは、AIエージェントが仕様、計画、実装フェーズで参照するプロジェクトの基本ガイドラインを含む`/memory/constitution.md`ファイルを作成または更新します。

### **ステップ2：** プロジェクト仕様の作成

プロジェクトの原則が確立されたら、機能仕様を作成できます。`/specify`コマンドを使用して、開発したいプロジェクトの具体的な要件を提供します。

>[!IMPORTANT]
>_何_を構築しようとしているか、_なぜ_なのかについて可能な限り明確にしてください。**この時点では技術スタックに焦点を当てないでください**。

プロンプトの例：

```text
チーム生産性プラットフォームTaskifyを開発する。ユーザーがプロジェクトを作成し、チームメンバーを追加し、
タスクを割り当て、コメントし、カンバンスタイルでボード間でタスクを移動できるようにする必要がある。この機能の初期フェーズでは、
「Create Taskify」と呼ぶことにし、複数のユーザーを持つが、ユーザーは事前に宣言され、事前定義される。
2つの異なるカテゴリで5人のユーザーが欲しい：1人のプロダクトマネージャーと4人のエンジニア。3つの
異なるサンプルプロジェクトを作成しよう。各タスクのステータス用に「To Do、」
「In Progress、」「In Review、」「Done」などの標準カンバン列を持つ。基本機能が
設定されていることを確認するための最初のテストなので、このアプリケーションにはログインはない。タスクカード用のUIでは、
カンバン作業ボードの異なる列間でタスクの現在のステータスを変更できるようにする必要がある。
特定のカードに無制限の数のコメントを残すことができるようにする必要がある。そのタスク
カードから、有効なユーザーの1人を割り当てることができるようにする必要がある。Taskifyを最初に起動すると、選択する5人のユーザーのリストが
表示される。パスワードは不要。ユーザーをクリックすると、プロジェクトのリストを表示するメインビューに移動する。
プロジェクトをクリックすると、そのプロジェクトのカンバンボードを開く。列が表示される。
異なる列間でカードをドラッグアンドドロップできる。現在ログインしているユーザーに
割り当てられたカードは、他のすべてのカードとは異なる色で表示されるため、素早く
自分のものを確認できる。自分が作成したコメントは編集できるが、他の人が作成したコメントは編集できない。
自分が作成したコメントは削除できるが、他の誰かが作成したコメントは削除できない。
```

このプロンプトを入力した後、Claude Codeが計画と仕様書作成プロセスを開始するのが見えるはずです。Claude Codeは、リポジトリを設定するために組み込みスクリプトの一部もトリガーします。

このステップが完了すると、新しいブランチ（例：`001-create-taskify`）が作成され、`specs/001-create-taskify`ディレクトリに新しい仕様が作成されているはずです。

生成された仕様には、テンプレートで定義されたユーザーストーリーと機能要件のセットが含まれているはずです。

この段階では、プロジェクトフォルダの内容は以下のようになっているはずです：

```text
├── memory
│	 └── constitution.md
├── scripts
│	 ├── check-prerequisites.sh
│	 ├── common.sh
│	 ├── create-new-feature.sh
│	 ├── setup-plan.sh
│	 └── update-claude-md.sh
├── specs
│	 └── 001-create-taskify
│	     └── spec.md
└── templates
    ├── plan-template.md
    ├── spec-template.md
    └── tasks-template.md
```

### **ステップ3：** 機能仕様の明確化（計画前に必須）

ベースライン仕様が作成されたら、最初の試行で適切にキャプチャされなかった要件を明確にできます。

下流での手戻りを減らすため、技術計画を作成する**前に**構造化された明確化ワークフローを実行する必要があります。

推奨順序：
1. `/clarify`（構造化）を使用 – 明確化セクションに回答を記録する連続的なカバレッジベースの質問。
2. まだ曖昧に感じる場合は、任意でアドホックな自由形式の改良を追加。

意図的に明確化をスキップしたい場合（例：スパイクまたは探索的プロトタイプ）は、エージェントが欠落した明確化でブロックされないように明示的に述べてください。

自由形式の改良プロンプトの例（`/clarify`後に必要な場合）：

```text
作成する各サンプルプロジェクトまたはプロジェクトについて、5から15の
タスクの可変数があり、それぞれが異なる完了状態にランダムに分散されている必要がある。各完了段階に少なくとも
1つのタスクがあることを確認する。
```

また、Claude Codeに**レビューと受け入れチェックリスト**を検証してもらい、検証済み/要件を満たすものにチェックを入れ、そうでないものはチェックを入れずに残すように依頼する必要があります。以下のプロンプトを使用できます：

```text
レビューと受け入れチェックリストを読み、機能仕様が基準を満たす場合はチェックリストの各項目にチェックを入れる。満たさない場合は空のままにする。
```

Claude Codeとの相互作用を仕様に関する明確化と質問の機会として使用することが重要です - **最初の試行を最終的なものとして扱わないでください**。

### **ステップ4：** 計画の生成

技術スタックやその他の技術要件について具体的に説明できるようになりました。プロジェクトテンプレートに組み込まれた`/plan`コマンドを以下のようなプロンプトで使用できます：

```text
.NET Aspireを使用して生成し、データベースとしてPostgresを使用する予定です。フロントエンドは
ドラッグアンドドロップタスクボード、リアルタイム更新機能を持つBlazor serverを使用する必要があります。プロジェクトAPI、
タスクAPI、通知APIを含むREST APIを作成する必要があります。
```

このステップの出力には、多数の実装詳細ドキュメントが含まれ、ディレクトリツリーは以下のようになります：

```text
.
├── CLAUDE.md
├── memory
│	 └── constitution.md
├── scripts
│	 ├── check-prerequisites.sh
│	 ├── common.sh
│	 ├── create-new-feature.sh
│	 ├── setup-plan.sh
│	 └── update-claude-md.sh
├── specs
│	 └── 001-create-taskify
│	     ├── contracts
│	     │	 ├── api-spec.json
│	     │	 └── signalr-spec.md
│	     ├── data-model.md
│	     ├── plan.md
│	     ├── quickstart.md
│	     ├── research.md
│	     └── spec.md
└── templates
    ├── CLAUDE-template.md
    ├── plan-template.md
    ├── spec-template.md
    └── tasks-template.md
```

指示に基づいて適切な技術スタックが使用されていることを確認するため、`research.md`ドキュメントをチェックしてください。コンポーネントが目立つ場合はClaude Codeに改良を依頼するか、使用したいプラットフォーム/フレームワーク（例：.NET）のローカルインストール版をチェックしてもらうこともできます。

さらに、選択した技術スタックが急速に変化するもの（例：.NET Aspire、JSフレームワーク）の場合、Claude Codeに詳細を研究してもらいたい場合があります。以下のようなプロンプトで：

```text
.NET Aspireは急速に変化するライブラリであるため、実装計画と実装詳細を確認し、追加研究の恩恵を受けられる領域を探してほしい。さらなる研究が必要だと特定した領域について、このTaskifyアプリケーションで使用する予定の特定の
バージョンに関する追加詳細で研究ドキュメントを更新し、ウェブからの研究を使用して詳細を明確にするため並行研究タスクを生成してほしい。
```

このプロセス中に、Claude Codeが間違ったことを研究してしまう場合があります。以下のようなプロンプトで正しい方向に導くことができます：

```text
これを一連のステップに分解する必要があると思います。まず、実装中に行う必要があるタスクのリストを特定し、
確信がないか、さらなる研究の恩恵を受けられるものを書き出してください。そして、これらの各タスクについて、
個別の研究タスクを立ち上げ、非常に具体的なタスクをすべて並行で研究するという結果になるようにしてほしい。あなたがしていたのは
.NET Aspire全般を研究しているように見えたが、この場合はあまり役に立たないと思います。
あまりにも的外れな研究です。研究は特定の的を絞った質問を解決するのに役立つ必要があります。
```

>[!NOTE]
>Claude Codeは過度に熱心になり、要求していないコンポーネントを追加する場合があります。変更の根拠と出典を明確にするように依頼してください。

### **ステップ5：** Claude Codeに計画を検証してもらう

計画が整ったら、Claude Codeに実行してもらい、欠落している部分がないことを確認する必要があります。以下のようなプロンプトを使用できます：

```text
実装計画と実装詳細ファイルを監査し、確認してほしい。
これを読んで、実行する必要があるタスクの順序があるかどうかを判断する観点で読み通してください。
ここに十分な情報があるかわからないからです。例えば、
コア実装を見ると、コア実装または改良の各ステップを進む際に
実装詳細の適切な箇所を参照できると有用でしょう。
```

これは実装計画を改良し、Claude Codeが計画サイクルで見逃した潜在的な盲点を避けるのに役立ちます。初期改良パスが完了したら、実装に取りかかる前に、Claude Codeにもう一度チェックリストを確認してもらいます。

[GitHub CLI](https://docs.github.com/en/github-cli/github-cli)がインストールされている場合、Claude Codeに現在のブランチから`main`への詳細な説明付きプルリクエストを作成してもらい、作業が適切に追跡されるようにすることもできます。

>[!NOTE]
>エージェントに実装してもらう前に、過度に設計された部分がないかClaude Codeに詳細をクロスチェックしてもらうことも価値があります（覚えておいてください - 過度に熱心になることがあります）。過度に設計されたコンポーネントや決定が存在する場合、Claude Codeに解決してもらえます。Claude Codeが計画を確立する際に遵守すべき基本的な要素として[憲法](base/memory/constitution.md)に従うことを確認してください。

### ステップ6: 実装

準備ができたら、`/implement`コマンドを使用して実装計画を実行します：

```text
/implement
```

`/implement`コマンドは以下を行います：
- すべての前提条件が整っていることを検証（憲法、仕様、計画、タスク）
- `tasks.md`からタスクの分解を解析
- 依存関係と並行実行マーカーを尊重して、正しい順序でタスクを実行
- タスク計画で定義されたTDDアプローチに従う
- 進捗更新を提供し、エラーを適切に処理

>[!IMPORTANT]
>AIエージェントは（`dotnet`、`npm`などの）ローカルCLIコマンドを実行します - 必要なツールがマシンにインストールされていることを確認してください。

実装が完了したら、アプリケーションをテストし、CLIログで見えない可能性があるランタイムエラー（例：ブラウザコンソールエラー）を解決してください。そのようなエラーをAIエージェントにコピーペーストして解決してもらうことができます。

</details>

---

## 🔍 トラブルシューティング

### LinuxでのGit Credential Manager

LinuxでGit認証に問題がある場合は、Git Credential Managerをインストールできます：

```bash
#!/usr/bin/env bash
set -e
echo "Git Credential Manager v2.6.1をダウンロード中..."
wget https://github.com/git-ecosystem/git-credential-manager/releases/download/v2.6.1/gcm-linux_amd64.2.6.1.deb
echo "Git Credential Managerをインストール中..."
sudo dpkg -i gcm-linux_amd64.2.6.1.deb
echo "GitでGCMを使用するよう設定中..."
git config --global credential.helper manager
echo "クリーンアップ中..."
rm gcm-linux_amd64.2.6.1.deb
```

## 👥 メンテナ

- Den Delimarsky ([@localden](https://github.com/localden))
- John Lam ([@jflam](https://github.com/jflam))

## 💬 サポート

サポートについては、[GitHubのissue](https://github.com/github/spec-kit/issues/new)を開いてください。バグレポート、機能要求、仕様駆動開発の使用に関する質問を歓迎します。

## 🙏 謝辞

このプロジェクトは[John Lam](https://github.com/jflam)の作業と研究に大きく影響を受け、それに基づいています。

## 📄 ライセンス

このプロジェクトはMITオープンソースライセンスの条項の下でライセンスされています。完全な条項については[LICENSE](./LICENSE)ファイルを参照してください。
