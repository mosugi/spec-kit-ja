# ドキュメント

このフォルダには、[DocFX](https://dotnet.github.io/docfx/)を使用してビルドされるSpec Kitのドキュメントソースファイルが含まれています。

## ローカルビルド

ローカルでドキュメントをビルドするには：

1. DocFXをインストール：
   ```bash
   dotnet tool install -g docfx
   ```

2. ドキュメントをビルド：
   ```bash
   cd docs
   docfx docfx.json --serve
   ```

3. ブラウザで`http://localhost:8080`を開いて、ドキュメントを表示します。

## 構造

- `docfx.json` - DocFX設定ファイル
- `index.md` - メインドキュメントホームページ
- `toc.yml` - 目次の設定
- `installation.md` - インストールガイド
- `quickstart.md` - クイックスタートガイド
- `_site/` - 生成されたドキュメント出力（gitで無視される）

## デプロイメント

ドキュメントは、`main`ブランチに変更がプッシュされると、自動的にビルドされてGitHub Pagesにデプロイされます。ワークフローは`.github/workflows/docs.yml`で定義されています。
