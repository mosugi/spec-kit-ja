# [PROJECT_NAME] 憲法
<!-- 例: Spec憲法、TaskFlow憲法など -->

## 基本原則

### [PRINCIPLE_1_NAME]
<!-- 例: I. ライブラリファースト -->
[PRINCIPLE_1_DESCRIPTION]
<!-- 例: すべての機能は独立したライブラリとして開始する；ライブラリは自己完結型で、独立してテスト可能で、文書化されている必要がある；明確な目的が必要 - 組織のためだけのライブラリは禁止 -->

### [PRINCIPLE_2_NAME]
<!-- 例: II. CLIインターフェース -->
[PRINCIPLE_2_DESCRIPTION]
<!-- 例: すべてのライブラリはCLI経由で機能を公開する；テキスト入出力プロトコル: stdin/args → stdout、エラー → stderr；JSONと人間が読める形式の両方をサポート -->

### [PRINCIPLE_3_NAME]
<!-- 例: III. テストファースト（絶対厳守） -->
[PRINCIPLE_3_DESCRIPTION]
<!-- 例: TDDは必須: テスト作成 → ユーザー承認 → テスト失敗 → その後実装；Red-Green-Refactorサイクルを厳格に実行 -->

### [PRINCIPLE_4_NAME]
<!-- 例: IV. 統合テスト -->
[PRINCIPLE_4_DESCRIPTION]
<!-- 例: 統合テストが必要な重点領域: 新しいライブラリの契約テスト、契約変更、サービス間通信、共有スキーマ -->

### [PRINCIPLE_5_NAME]
<!-- 例: V. 可観測性、VI. バージョン管理と破壊的変更、VII. 簡潔性 -->
[PRINCIPLE_5_DESCRIPTION]
<!-- 例: テキストI/Oはデバッグ可能性を保証する；構造化ログが必要；または: MAJOR.MINOR.BUILD形式；または: シンプルに始める、YAGNI原則 -->

## [SECTION_2_NAME]
<!-- 例: 追加制約、セキュリティ要件、パフォーマンス基準など -->

[SECTION_2_CONTENT]
<!-- 例: 技術スタック要件、コンプライアンス基準、デプロイメントポリシーなど -->

## [SECTION_3_NAME]
<!-- 例: 開発ワークフロー、レビュープロセス、品質ゲートなど -->

[SECTION_3_CONTENT]
<!-- 例: コードレビュー要件、テストゲート、デプロイメント承認プロセスなど -->

## ガバナンス
<!-- 例: 憲法はその他すべての慣行に優先する；修正には文書化、承認、移行計画が必要 -->

[GOVERNANCE_RULES]
<!-- 例: すべてのPR/レビューはコンプライアンス検証が必須；複雑性は正当化が必要；ランタイム開発ガイダンスには[GUIDANCE_FILE]を使用 -->

**バージョン**: [CONSTITUTION_VERSION] | **批准日**: [RATIFICATION_DATE] | **最終修正**: [LAST_AMENDED_DATE]
<!-- 例: バージョン: 2.1.1 | 批准日: 2025-06-13 | 最終修正: 2025-07-16 -->