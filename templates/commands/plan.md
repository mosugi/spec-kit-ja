---
description: plan templateを使用して設計成果物を生成する実装計画ワークフローを実行します。
scripts:
  sh: scripts/bash/setup-plan.sh --json
  ps: scripts/powershell/setup-plan.ps1 -Json
---

ユーザー入力は、エージェントから直接提供される場合とコマンド引数として提供される場合があります。プロンプトを進める前に**必ず**考慮してください（空でない場合）。

ユーザー入力:

$ARGUMENTS

引数として提供された実装の詳細に基づいて、以下を実行してください：

1. リポジトリルートから `{SCRIPT}` を実行し、JSONを解析してFEATURE_SPEC、IMPL_PLAN、SPECS_DIR、BRANCHを取得します。今後のすべてのファイルパスは絶対パスにする必要があります。
   - 進める前に、FEATURE_SPECに少なくとも1つの`Session`サブヘッディングを持つ`## Clarifications`セクションがあるかを確認してください。欠落している、または明らかに曖昧な領域が残っている場合（曖昧な形容詞、未解決の重要な選択肢）は、一時停止し、手戻りを減らすために最初に`/clarify`を実行するようユーザーに指示してください。次の場合のみ続行してください：(a) Clarificationsが存在する、または (b) 明示的なユーザーオーバーライドが提供されている（例："proceed without clarification"）。明確化を自分で作り出そうとしないでください。
2. フィーチャー仕様を読み込み、分析して以下を理解してください：
   - フィーチャー要件とユーザーストーリー
   - 機能要件と非機能要件
   - 成功基準と受け入れ基準
   - 言及されている技術的制約や依存関係

3. `/memory/constitution.md`の憲章を読み込み、憲章要件を理解してください。

4. 実装計画テンプレートを実行してください：
   - `/templates/plan-template.md`を読み込み（既にIMPL_PLANパスにコピー済み）
   - 入力パスをFEATURE_SPECに設定
   - Execution Flow（メイン）機能のステップ1-9を実行
   - テンプレートは自己完結型で実行可能
   - 指定されたエラーハンドリングとゲートチェックに従う
   - テンプレートが$SPECS_DIRでのアーティファクト生成を導くようにする：
     * Phase 0でresearch.mdを生成
     * Phase 1でdata-model.md、contracts/、quickstart.mdを生成
     * Phase 2でtasks.mdを生成
   - 引数からユーザー提供の詳細をTechnical Contextに組み込む：{ARGS}
   - 各フェーズを完了するごとにProgress Trackingを更新

5. 実行が完了したことを確認してください：
   - Progress Trackingがすべてのフェーズが完了していることを示すかチェック
   - 必要なすべてのアーティファクトが生成されたことを確認
   - 実行でERROR状態がないことを確認

6. ブランチ名、ファイルパス、生成されたアーティファクトとともに結果を報告してください。

パスの問題を避けるため、すべてのファイル操作でリポジトリルートからの絶対パスを使用してください。
