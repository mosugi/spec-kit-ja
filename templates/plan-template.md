---
description: "機能開発のための実装計画テンプレート"
scripts:
  sh: scripts/bash/update-agent-context.sh __AGENT__
  ps: scripts/powershell/update-agent-context.ps1 -AgentType __AGENT__
---

# 実装計画: [FEATURE]

**ブランチ**: `[###-feature-name]` | **日付**: [DATE] | **仕様**: [link]
**入力**: `/specs/[###-feature-name]/spec.md`からの機能仕様

## 実行フロー (/planコマンドスコープ)
```
1. 入力パスから機能仕様を読み込む
   → 見つからない場合: ERROR "No feature spec at {path}"
2. 技術コンテキストを記入する（NEEDS CLARIFICATIONをスキャン）
   → コンテキストからプロジェクトタイプを検出（web=frontend+backend, mobile=app+api）
   → プロジェクトタイプに基づいて構造決定を設定
3. 憲章文書の内容に基づいて憲章チェックセクションを記入する
4. 下の憲章チェックセクションを評価する
   → 違反が存在する場合: 複雑性トラッキングに文書化
   → 正当化が不可能な場合: ERROR "まずアプローチを簡素化してください"
   → 進捗トラッキングを更新: 初期憲章チェック
5. フェーズ0を実行 → research.md
   → NEEDS CLARIFICATIONが残っている場合: ERROR "未知の項目を解決してください"
6. フェーズ1を実行 → contracts, data-model.md, quickstart.md, エージェント固有のテンプレートファイル（例：Claude Code用 `CLAUDE.md`、GitHub Copilot用 `.github/copilot-instructions.md`、Gemini CLI用 `GEMINI.md`、Qwen Code用 `QWEN.md`、opencode用 `AGENTS.md`）
7. 憲章チェックセクションを再評価する
   → 新しい違反がある場合: 設計をリファクタリング、フェーズ1に戻る
   → 進捗トラッキングを更新: 設計後憲章チェック
8. フェーズ2を計画 → タスク生成アプローチを説明（tasks.mdは作成しない）
9. 停止 - /tasksコマンドの準備完了
```

**重要**: /planコマンドはステップ7で停止します。フェーズ2-4は他のコマンドで実行されます：
- フェーズ2: /tasksコマンドがtasks.mdを作成
- フェーズ3-4: 実装実行（手動またはツール経由）

## 概要
[機能仕様から抽出: 主要要件 + 調査からの技術アプローチ]

## 技術コンテキスト
**言語/バージョン**: [例：Python 3.11、Swift 5.9、Rust 1.75またはNEEDS CLARIFICATION]
**主要依存関係**: [例：FastAPI、UIKit、LLVMまたはNEEDS CLARIFICATION]
**ストレージ**: [該当する場合、例：PostgreSQL、CoreData、filesまたはN/A]
**テスト**: [例：pytest、XCTest、cargo testまたはNEEDS CLARIFICATION]
**ターゲットプラットフォーム**: [例：Linux server、iOS 15+、WASMまたはNEEDS CLARIFICATION]
**プロジェクトタイプ**: [single/web/mobile - ソース構造を決定]
**パフォーマンス目標**: [ドメイン固有、例：1000 req/s、1M LOC/sec、60 fpsまたはNEEDS CLARIFICATION]
**制約**: [ドメイン固有、例：<200ms p95、<100MBメモリ、オフライン対応またはNEEDS CLARIFICATION]
**スケール/スコープ**: [ドメイン固有、例：10kユーザー、1M LOC、50画面またはNEEDS CLARIFICATION]

## 憲章チェック
*GATE: フェーズ0調査前に合格する必要。フェーズ1設計後に再チェック。*

[憲章ファイルに基づいて決定されるゲート]

## プロジェクト構造

### ドキュメンテーション（この機能）
```
specs/[###-feature]/
├── plan.md              # このファイル（/planコマンド出力）
├── research.md          # フェーズ0出力（/planコマンド）
├── data-model.md        # フェーズ1出力（/planコマンド）
├── quickstart.md        # フェーズ1出力（/planコマンド）
├── contracts/           # フェーズ1出力（/planコマンド）
└── tasks.md             # フェーズ2出力（/tasksコマンド - /planでは作成されない）
```

### ソースコード（リポジトリルート）
```
# オプション1: 単一プロジェクト（デフォルト）
src/
├── models/
├── services/
├── cli/
└── lib/

tests/
├── contract/
├── integration/
└── unit/

# オプション2: Webアプリケーション（"frontend" + "backend"が検出された場合）
backend/
├── src/
│   ├── models/
│   ├── services/
│   └── api/
└── tests/

frontend/
├── src/
│   ├── components/
│   ├── pages/
│   └── services/
└── tests/

# オプション3: モバイル + API（"iOS/Android"が検出された場合）
api/
└── [上記backendと同様]

ios/ or android/
└── [プラットフォーム固有の構造]
```

**構造決定**: [技術コンテキストでweb/mobileアプリが示されていない限り、オプション1がデフォルト]

## フェーズ0: アウトラインと調査
1. **上記の技術コンテキストから未知の項目を抽出**:
   - 各NEEDS CLARIFICATION → 調査タスク
   - 各依存関係 → ベストプラクティスタスク
   - 各統合 → パターンタスク

2. **調査エージェントを生成して派遣**:
   ```
   技術コンテキストの各未知項目に対して:
     Task: "Research {unknown} for {feature context}"
   各技術選択に対して:
     Task: "Find best practices for {tech} in {domain}"
   ```

3. **調査結果を統合** `research.md`で以下の形式を使用:
   - 決定: [選択されたもの]
   - 根拠: [選択した理由]
   - 検討した代替案: [他に評価したもの]

**出力**: すべてのNEEDS CLARIFICATIONが解決されたresearch.md

## フェーズ1: 設計と契約
*前提条件: research.md完了*

1. **機能仕様からエンティティを抽出** → `data-model.md`:
   - エンティティ名、フィールド、関係
   - 要件からのバリデーションルール
   - 該当する場合の状態遷移

2. **機能要件からAPIコントラクトを生成**:
   - 各ユーザーアクション → エンドポイント
   - 標準的なREST/GraphQLパターンを使用
   - OpenAPI/GraphQLスキーマを `/contracts/` に出力

3. **コントラクトからコントラクトテストを生成**:
   - エンドポイントごとに1つのテストファイル
   - リクエスト/レスポンススキーマをアサート
   - テストは失敗しなければならない（まだ実装なし）

4. **ユーザーストーリーからテストシナリオを抽出**:
   - 各ストーリー → 統合テストシナリオ
   - クイックスタートテスト = ストーリー検証ステップ

5. **エージェントファイルを段階的に更新** (O(1)操作):
   - `{SCRIPT}`を実行
     **重要**: 上記で指定された通りに正確に実行してください。引数を追加または削除しないでください。
   - 存在する場合: 現在の計画から新しい技術のみを追加
   - マーカー間の手動追加を保持
   - 最近の変更を更新（最新3つを保持）
   - トークン効率のため150行未満に維持
   - リポジトリルートに出力

**出力**: data-model.md, /contracts/*, 失敗するテスト, quickstart.md, エージェント固有ファイル

## フェーズ2: タスク計画アプローチ
*このセクションは/tasksコマンドが行うことを説明 - /plan中には実行しない*

**タスク生成戦略**:
- `.specify/templates/tasks-template.md`をベースとして読み込み
- フェーズ1設計文書（contracts、data model、quickstart）からタスクを生成
- 各コントラクト → コントラクトテストタスク [P]
- 各エンティティ → モデル作成タスク [P]
- 各ユーザーストーリー → 統合テストタスク
- テストを合格させるための実装タスク

**順序戦略**:
- TDD順序: 実装前にテスト
- 依存関係順序: Modelsの後にservices、その後にUI
- 並列実行（独立ファイル）に[P]をマーク

**推定出力**: tasks.mdに25-30個の番号付き・順序付きタスク

**重要**: このフェーズは/tasksコマンドで実行され、/planでは実行されない

## フェーズ3+: 将来の実装
*これらのフェーズは/planコマンドの範囲外*

**フェーズ3**: タスク実行（/tasksコマンドがtasks.mdを作成）
**フェーズ4**: 実装（憲章原則に従ってtasks.mdを実行）
**フェーズ5**: 検証（テスト実行、quickstart.md実行、パフォーマンス検証）

## 複雑性トラッキング
*憲章チェックで正当化が必要な違反がある場合のみ記入*

| 違反 | 必要な理由 | より簡単な代替案を拒否した理由 |
|-----------|------------|-------------------------------------|
| [例: 4つ目のプロジェクト] | [現在のニーズ] | [なぜ3つのプロジェクトでは不十分か] |
| [例: Repositoryパターン] | [特定の問題] | [なぜ直接DBアクセスでは不十分か] |


## 進捗トラッキング
*このチェックリストは実行フロー中に更新される*

**フェーズステータス**:
- [ ] フェーズ0: 調査完了 (/planコマンド)
- [ ] フェーズ1: 設計完了 (/planコマンド)
- [ ] フェーズ2: タスク計画完了 (/planコマンド - アプローチの説明のみ)
- [ ] フェーズ3: タスク生成済み (/tasksコマンド)
- [ ] フェーズ4: 実装完了
- [ ] フェーズ5: 検証合格

**ゲートステータス**:
- [ ] 初期憲章チェック: 合格
- [ ] 設計後憲章チェック: 合格
- [ ] すべてのNEEDS CLARIFICATION解決済み
- [ ] 複雑性逸脱の文書化済み

---
*憲章 v2.1.1 に基づく - `/memory/constitution.md` を参照*
