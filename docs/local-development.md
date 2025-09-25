# ローカル開発ガイド

このガイドでは、リリースの公開や `main` ブランチへのコミットを行う前に、ローカルで `specify` CLI の開発を反復する方法を説明します。

> スクリプトには Bash（`.sh`）と PowerShell（`.ps1`）の両方のバリアントがあります。`--script sh|ps` を指定しない限り、CLI は OS に基づいて自動選択します。

## 1. クローンとブランチの切り替え

```bash
git clone https://github.com/mosugi/spec-kit-ja.git
cd spec-kit
# フィーチャーブランチで作業
git checkout -b your-feature-branch
```

## 2. CLI の直接実行（最速のフィードバック）

何もインストールせずに、モジュールエントリーポイント経由で CLI を実行できます：

```bash
# リポジトリルートから
python -m src.specify_cli --help
python -m src.specify_cli init demo-project --ai claude --ignore-agent-tools --script sh
```

スクリプトファイル形式での実行を希望する場合（shebang を使用）：

```bash
python src/specify_cli/__init__.py init demo-project --script ps
```

## 3. 編集可能インストールの使用（分離環境）

エンドユーザーと同じように依存関係を解決するため、`uv` を使用して分離環境を作成します：

```bash
# 仮想環境の作成と有効化（uv が .venv を自動管理）
uv venv
source .venv/bin/activate  # または Windows PowerShell の場合: .venv\Scripts\Activate.ps1

# プロジェクトを編集可能モードでインストール
uv pip install -e .

# これで 'specify' エントリーポイントが利用可能
specify --help
```

編集可能モードのため、コード編集後の再実行時に再インストールは不要です。

## 4. Git から直接 uvx を実行（現在のブランチ）

`uvx` はローカルパス（または Git ref）から実行してユーザーフローをシミュレートできます：

```bash
uvx --from . specify init demo-uvx --ai copilot --ignore-agent-tools --script sh
```

マージせずに特定のブランチを uvx で指定することもできます：

```bash
# 最初に作業ブランチをプッシュ
git push origin your-feature-branch
uvx --from git+https://github.com/mosugi/spec-kit-ja.git@your-feature-branch specify init demo-branch-test --script ps
```

### 4a. 絶対パス uvx（どこからでも実行）

別のディレクトリにいる場合は、`.` の代わりに絶対パスを使用します：

```bash
uvx --from /mnt/c/GitHub/spec-kit specify --help
uvx --from /mnt/c/GitHub/spec-kit specify init demo-anywhere --ai copilot --ignore-agent-tools --script sh
```

便利のため環境変数を設定：
```bash
export SPEC_KIT_SRC=/mnt/c/GitHub/spec-kit
uvx --from "$SPEC_KIT_SRC" specify init demo-env --ai copilot --ignore-agent-tools --script ps
```

（オプション）シェル関数を定義：
```bash
specify-dev() { uvx --from /mnt/c/GitHub/spec-kit specify "$@"; }
# その後
specify-dev --help
```

## 5. スクリプト実行権限ロジックのテスト

`init` の実行後、POSIX システムでシェルスクリプトが実行可能であることを確認します：

```bash
ls -l scripts | grep .sh
# 所有者実行ビットが期待される（例：-rwxr-xr-x）
```
Windows では代わりに `.ps1` スクリプトを使用します（chmod は不要）。

## 6. lint / 基本チェックの実行（独自追加）

現在、強制的な lint 設定はバンドルされていませんが、インポート可能性を簡単にチェックできます：
```bash
python -c "import specify_cli; print('Import OK')"
```

## 7. ローカルでの Wheel ビルド（オプション）

公開前にパッケージングを検証：

```bash
uv build
ls dist/
```
必要に応じて、ビルドされた成果物を新しい使い捨て環境にインストールします。

## 8. 一時ワークスペースの使用

汚れたディレクトリで `init --here` をテストする場合、一時ワークスペースを作成：

```bash
mkdir /tmp/spec-test && cd /tmp/spec-test
python -m src.specify_cli init --here --ai claude --ignore-agent-tools --script sh  # リポジトリがここにコピーされている場合
```
より軽量なサンドボックスが必要な場合は、変更された CLI 部分のみをコピーします。

## 9. ネットワーク / TLS スキップのデバッグ

実験中に TLS 検証をバイパスする必要がある場合：

```bash
specify check --skip-tls
specify init demo --skip-tls --ai gemini --ignore-agent-tools --script ps
```
（ローカル実験のみで使用してください。）

## 10. 高速編集ループのまとめ

| アクション | コマンド |
|--------|---------|
| CLI の直接実行 | `python -m src.specify_cli --help` |
| 編集可能インストール | `uv pip install -e .` の後 `specify ...` |
| ローカル uvx 実行（リポジトリルート） | `uvx --from . specify ...` |
| ローカル uvx 実行（絶対パス） | `uvx --from /mnt/c/GitHub/spec-kit specify ...` |
| Git ブランチ uvx | `uvx --from git+URL@branch specify ...` |
| Wheel ビルド | `uv build` |

## 11. クリーンアップ

ビルド成果物 / 仮想環境を迅速に削除：
```bash
rm -rf .venv dist build *.egg-info
```

## 12. よくある問題

| 症状 | 修正方法 |
|---------|-----|
| `ModuleNotFoundError: typer` | `uv pip install -e .` を実行 |
| スクリプトが実行不可（Linux） | init を再実行または `chmod +x scripts/*.sh` |
| Git ステップがスキップされた | `--no-git` を指定したか Git が未インストール |
| 間違ったスクリプトタイプがダウンロードされた | `--script sh` または `--script ps` を明示的に指定 |
| 企業ネットワークでの TLS エラー | `--skip-tls` を試行（本番用ではありません） |

## 13. 次のステップ

- ドキュメントを更新し、変更したCLIを使用してクイックスタートを実行
- 満足したらPRを開く
- （オプション）変更が `main` にマージされたらリリースタグを作成

