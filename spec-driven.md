# 仕様駆動開発（Specification-Driven Development, SDD）

## パワーの逆転

数十年にわたって、コードこそが王者でした。仕様書はコードに奉仕するもの—コーディングという「本当の仕事」が始まれば捨て去られる足場に過ぎませんでした。私たちは開発を導くためにPRD（プロダクト要求仕様書）を書き、実装を知らせるためにデザイン文書を作成し、アーキテクチャを視覚化するために図表を描きました。しかし、これらは常にコード自体の従属物でした。コードこそが真実でした。その他はせいぜい良き意図に過ぎませんでした。コードが真の情報源であり、それが進歩するにつれて、仕様書がそのペースについていくことはほとんどありませんでした。アセット（コード）と実装が一体である以上、コードから構築することなしに並列実装を持つことは困難でした。

仕様駆動開発（SDD）は、この権力構造を逆転させます。仕様書がコードに奉仕するのではなく、コードが仕様書に奉仕するのです。プロダクト要求仕様書（PRD）は実装のガイドではなく、実装を生成する源泉なのです。技術計画書はコーディングを知らせる文書ではなく、コードを生成する正確な定義なのです。これはソフトウェア構築方法の段階的改善ではありません。開発を推進するものが何かについての根本的な再考なのです。

仕様と実装の間のギャップは、ソフトウェア開発の黎明期からその発展を阻害してきました。私たちはより良い文書化、より詳細な要件、より厳格なプロセスでそれを埋めようと試みてきました。これらのアプローチは、ギャップを不可避なものとして受け入れるため失敗します。それらはギャップを狭めようとはしますが、決して排除しません。SDDは、仕様書とそれから生まれる具体的な実装計画を実行可能にすることで、ギャップを排除します。仕様書と実装計画がコードを生成するとき、ギャップは存在せず—変換があるだけです。

この変換が今や可能になったのは、AIが複雑な仕様書を理解し実装でき、詳細な実装計画を作成できるからです。しかし、構造のない生のAI生成は混沌を生み出します。SDDは、動作するシステムを生成するのに十分正確で、完全で、曖昧さのない仕様書と、それに続く実装計画を通じてその構造を提供します。仕様書が主要なアーティファクトとなります。コードは、特定の言語とフレームワークにおける（実装計画からの実装としての）その表現となります。

この新しい世界では、ソフトウェアの保守は仕様書の進化を意味します。開発チームの意図は自然言語（「**意図駆動開発**」）、デザインアセット、コア原則、その他のガイドラインで表現されます。開発の**共通語**はより高いレベルに移行し、コードは最後の一歩のアプローチとなります。

デバッグは、不正なコードを生成する仕様書とその実装計画を修正することを意味します。リファクタリングは、明確性のための再構築を意味します。開発ワークフロー全体が、仕様書を中心的な真実の源として再編成され、実装計画とコードは継続的に再生成される出力となります。新機能でアプリを更新したり、創造的存在である私たちが新しい並列実装を作成することは、仕様書を再訪し新しい実装計画を作成することを意味します。したがって、このプロセスは 0 -> 1, (1', ..), 2, 3, N です。

開発チームは、創造性、実験、批判的思考に集中します。

## 実践におけるSDDワークフロー

ワークフローは、しばしば曖昧で不完全なアイデアから始まります。AIとの反復的な対話を通じて、このアイデアは包括的なPRDとなります。AIは明確化の質問をし、エッジケースを特定し、正確な受け入れ基準の定義を支援します。従来の開発では何日もの会議と文書化が必要だったことが、集中的な仕様作成作業の数時間で実現されます。これは従来のSDLCを変革します—要件と設計は、個別のフェーズではなく継続的な活動となります。これは**チームプロセス**を支持し、チームでレビューされた仕様書が表現され、バージョン管理され、ブランチで作成され、マージされます。

プロダクトマネージャーが受け入れ基準を更新すると、実装計画は影響を受ける技術決定に自動的にフラグを立てます。アーキテクトがより良いパターンを発見すると、PRDは新しい可能性を反映して更新されます。

この仕様作成プロセス全体を通して、研究エージェントが重要なコンテキストを収集します。彼らはライブラリの互換性、パフォーマンスベンチマーク、セキュリティの影響を調査します。組織の制約が自動的に発見・適用されます—あなたの会社のデータベース標準、認証要件、デプロイメントポリシーがすべての仕様書にシームレスに統合されます。

PRDから、AIは要件を技術決定にマッピングする実装計画を生成します。すべての技術選択には文書化された根拠があります。すべてのアーキテクチャ決定は特定の要件にさかのぼることができます。このプロセス全体を通して、一貫性検証が継続的に品質を向上させます。AIは仕様書の曖昧さ、矛盾、ギャップを分析します—一回限りのゲートとしてではなく、継続的な改善として。

コード生成は、仕様書とその実装計画が十分安定したらすぐに始まりますが、それらが「完成」している必要はありません。初期の生成は探索的かもしれません—仕様書が実際に意味をなすかをテストします。ドメインコンセプトはデータモデルになります。ユーザーストーリーはAPIエンドポイントになります。受け入れシナリオはテストになります。これは仕様書を通じて開発とテストを統合します—テストシナリオはコード後に書かれるのではなく、実装とテストの両方を生成する仕様書の一部なのです。

フィードバックループは初期開発を超えて拡張されます。本番メトリクスとインシデントは単にホットフィックスを引き起こすだけでなく、次の再生成のために仕様書を更新します。パフォーマンスボトルネックは新しい非機能要件となります。セキュリティ脆弱性は将来のすべての生成に影響する制約となります。仕様書、実装、運用の現実の間のこの反復的なダンスこそが、真の理解が生まれる場所であり、従来のSDLCが継続的進化に変革される場所なのです。

## なぜ今SDDが重要なのか

3つのトレンドがSDDを可能にするだけでなく必要なものにしています：

第一に、AI機能は自然言語仕様から動作するコードを確実に生成できる閾値に達しました。これは開発者を置き換えることではなく—仕様から実装への機械的な翻訳を自動化することで彼らの効果を増幅することです。探索と創造性を増幅し、「やり直し」を簡単にサポートし、追加、削減、批判的思考をサポートできます。

第二に、ソフトウェアの複雑さは指数関数的に増大し続けています。現代のシステムは何十ものサービス、フレームワーク、依存関係を統合します。手動プロセスを通じてこれらすべての部品を元の意図と一致させ続けることは、ますます困難になっています。SDDは仕様駆動生成を通じて体系的な整合性を提供します。フレームワークは、人間優先ではなくAI優先のサポートを提供するように、または再利用可能なコンポーネントを中心に設計されるように進化するかもしれません。

第三に、変化のペースが加速しています。要件は今日、かつてないほど迅速に変化します。方向転換はもはや例外的ではありません—期待されるものです。現代のプロダクト開発は、ユーザーフィードバック、市場状況、競争圧力に基づく迅速な反復を要求します。従来の開発では、これらの変化を混乱として扱います。各方向転換には、文書、設計、コードを通じた変更の手動伝播が必要です。結果は、速度を制限する慎重で遅い更新か、技術的負債を蓄積する迅速で無謀な変更のどちらかです。

SDDは仮定実験をサポートできます：「Tシャツをもっと売るというビジネスニーズを促進するためにアプリケーションを再実装または変更する必要がある場合、それをどのように実装し実験するか？」

SDDは要件変更を障害から通常のワークフローに変換します。仕様が実装を駆動する場合、方向転換は手動の書き直しではなく体系的な再生成となります。PRDのコア要件を変更すると、影響を受ける実装計画が自動的に更新されます。ユーザーストーリーを修正すると、対応するAPIエンドポイントが再生成されます。これは初期開発だけの話ではありません—避けられない変化を通じてエンジニアリング速度を維持することなのです。

## コア原則

**共通語としての仕様書**: 仕様書が主要なアーティファクトとなります。コードは、特定の言語とフレームワークにおけるその表現となります。ソフトウェアの保守は、仕様書の進化を意味します。

**実行可能な仕様書**: 仕様書は、動作するシステムを生成するのに十分正確で、完全で、曖昧さがないものでなければなりません。これは意図と実装の間のギャップを排除します。

**継続的改善**: 一貫性検証は一度限りのゲートではなく、継続的に実行されます。AIは進行中のプロセスとして、仕様書の曖昧さ、矛盾、ギャップを分析します。

**研究駆動のコンテキスト**: 研究エージェントが仕様プロセス全体を通じて重要なコンテキストを収集し、技術オプション、パフォーマンスへの影響、組織の制約を調査します。

**双方向フィードバック**: 本番環境の現実が仕様の進化を知らせます。メトリクス、インシデント、運用から得た学習が仕様改善のインプットとなります。

**探索のためのブランチング**: 同じ仕様から複数の実装アプローチを生成し、パフォーマンス、保守性、ユーザーエクスペリエンス、コストという異なる最適化ターゲットを探索します。

## 実装アプローチ

現在、SDDを実践するには既存のツールを組み合わせ、プロセス全体を通じて規律を維持する必要があります。この手法は以下で実践できます：

- 反復的な仕様開発のためのAIアシスタント
- 技術的コンテキスト収集のための研究エージェント
- 仕様から実装への翻訳のためのコード生成ツール
- 仕様優先ワークフローに適応したバージョン管理システム
- 仕様文書のAI分析による一貫性チェック

重要なのは、仕様書を真実の源として扱い、コードをその逆ではなく仕様書に奉仕する生成された出力として扱うことです。

## コマンドによるSDDの効率化

SDD手法は、仕様 → 計画 → タスク化のワークフローを自動化する3つの強力なコマンドによって大幅に強化されます：

### `/specify` コマンド

このコマンドは、シンプルな機能記述（ユーザープロンプト）を自動リポジトリ管理付きの完全で構造化された仕様に変換します：

1. **自動機能番号付け**: 既存の仕様をスキャンして次の機能番号を決定（例：001, 002, 003）
2. **ブランチ作成**: あなたの記述からセマンティックなブランチ名を生成し、自動的に作成
3. **テンプレートベース生成**: 機能仕様テンプレートをコピーし、あなたの要件でカスタマイズ
4. **ディレクトリ構造**: すべての関連文書のための適切な `specs/[branch-name]/` 構造を作成

### `/plan` コマンド

機能仕様が存在すると、このコマンドは包括的な実装計画を作成します：

1. **仕様分析**: 機能要件、ユーザーストーリー、受け入れ基準を読み取り理解
2. **憲法遵守**: プロジェクト憲法とアーキテクチャ原則との整合を確保
3. **技術的翻訳**: ビジネス要件を技術アーキテクチャと実装詳細に変換
4. **詳細文書**: データモデル、API契約、テストシナリオのためのサポート文書を生成
5. **クイックスタート検証**: 主要な検証シナリオを捕捉したクイックスタートガイドを作成

### `/tasks` コマンド

計画が作成された後、このコマンドは計画と関連設計文書を分析して実行可能なタスクリストを生成します：

1. **入力**: `plan.md`（必須）と、存在する場合は `data-model.md`、`contracts/`、`research.md` を読み取り
2. **タスク導出**: 契約、エンティティ、シナリオを特定のタスクに変換
3. **並列化**: 独立したタスクに `[P]` をマークし、安全な並列グループを概説
4. **出力**: 機能ディレクトリに `tasks.md` を書き込み、タスクエージェントによる実行の準備完了

### 例：チャット機能の構築

以下は、これらのコマンドが従来の開発ワークフローをどのように変革するかです：

**従来のアプローチ:**

```text
1. 文書にPRDを書く（2-3時間）
2. 設計文書を作成する（2-3時間）
3. プロジェクト構造を手動で設定する（30分）
4. 技術仕様を書く（3-4時間）
5. テスト計画を作成する（2時間）
合計：約12時間の文書作成作業
```

**SDDコマンドアプローチ:**

```bash
# ステップ1: 機能仕様を作成（5分）
/specify メッセージ履歴とユーザープレゼンス機能付きのリアルタイムチャットシステム

# これにより自動的に：
# - ブランチ "003-chat-system" を作成
# - specs/003-chat-system/spec.md を生成
# - 構造化された要件で内容を構成

# ステップ2: 実装計画を生成（5分）
/plan リアルタイムメッセージングにWebSocket、履歴にPostgreSQL、プレゼンスにRedisを使用

# ステップ3: 実行可能なタスクを生成（5分）
/tasks

# これにより自動的に作成されます：
# - specs/003-chat-system/plan.md
# - specs/003-chat-system/research.md（WebSocketライブラリ比較）
# - specs/003-chat-system/data-model.md（MessageとUserスキーマ）
# - specs/003-chat-system/contracts/（WebSocketイベント、RESTエンドポイント）
# - specs/003-chat-system/quickstart.md（主要な検証シナリオ）
# - specs/003-chat-system/tasks.md（計画から導出されたタスクリスト）
```

15分で、以下が手に入ります：

- ユーザーストーリーと受け入れ基準を含む完全な機能仕様
- 技術選択と根拠を含む詳細な実装計画
- コード生成の準備ができたAPI契約とデータモデル
- 自動および手動テストの両方のための包括的なテストシナリオ
- すべての文書が機能ブランチで適切にバージョン管理される

### 構造化された自動化の力

これらのコマンドは単に時間を節約するだけでなく、一貫性と完全性を強制します：

1. **忘れられた詳細なし**: テンプレートが非機能要件からエラーハンドリングまで、すべての側面が考慮されることを保証
2. **追跡可能な決定**: すべての技術選択が特定の要件にリンクバック
3. **生きた文書**: 仕様がコードを生成するため、コードと同期を保つ
4. **高速反復**: 要件を変更し、数日でなく数分で計画を再生成

これらのコマンドは、仕様を静的な文書ではなく実行可能なアーティファクトとして扱うことでSDD原則を体現します。仕様プロセスを必要悪から開発の推進力へと変革します。

### テンプレート駆動品質：構造がLLMをより優れた結果に向けて制約する方法

これらのコマンドの真の力は、自動化だけでなく、テンプレートがLLMの行動をより高品質な仕様に向けて導く方法にあります。テンプレートは、LLMの出力を生産的な方法で制約する洗練されたプロンプトとして機能します：

#### 1. **Preventing Premature Implementation Details**

The feature specification template explicitly instructs:

```text
- ✅ Focus on WHAT users need and WHY
- ❌ Avoid HOW to implement (no tech stack, APIs, code structure)
```

This constraint forces the LLM to maintain proper abstraction levels. When an LLM might naturally jump to "implement using React with Redux," the template keeps it focused on "users need real-time updates of their data." This separation ensures specifications remain stable even as implementation technologies change.

#### 2. **Forcing Explicit Uncertainty Markers**

Both templates mandate the use of `[NEEDS CLARIFICATION]` markers:

```text
When creating this spec from a user prompt:
1. **Mark all ambiguities**: Use [NEEDS CLARIFICATION: specific question]
2. **Don't guess**: If the prompt doesn't specify something, mark it
```

This prevents the common LLM behavior of making plausible but potentially incorrect assumptions. Instead of guessing that a "login system" uses email/password authentication, the LLM must mark it as `[NEEDS CLARIFICATION: auth method not specified - email/password, SSO, OAuth?]`.

#### 3. **Structured Thinking Through Checklists**

The templates include comprehensive checklists that act as "unit tests" for the specification:

```markdown
### Requirement Completeness
- [ ] No [NEEDS CLARIFICATION] markers remain
- [ ] Requirements are testable and unambiguous
- [ ] Success criteria are measurable
```

These checklists force the LLM to self-review its output systematically, catching gaps that might otherwise slip through. It's like giving the LLM a quality assurance framework.

#### 4. **Constitutional Compliance Through Gates**

The implementation plan template enforces architectural principles through phase gates:

```markdown
### Phase -1: Pre-Implementation Gates
#### Simplicity Gate (Article VII)
- [ ] Using ≤3 projects?
- [ ] No future-proofing?
#### Anti-Abstraction Gate (Article VIII)
- [ ] Using framework directly?
- [ ] Single model representation?
```

These gates prevent over-engineering by making the LLM explicitly justify any complexity. If a gate fails, the LLM must document why in the "Complexity Tracking" section, creating accountability for architectural decisions.

#### 5. **Hierarchical Detail Management**

The templates enforce proper information architecture:

```text
**IMPORTANT**: This implementation plan should remain high-level and readable.
Any code samples, detailed algorithms, or extensive technical specifications
must be placed in the appropriate `implementation-details/` file
```

This prevents the common problem of specifications becoming unreadable code dumps. The LLM learns to maintain appropriate detail levels, extracting complexity to separate files while keeping the main document navigable.

#### 6. **Test-First Thinking**

The implementation template enforces test-first development:

```text
### File Creation Order
1. Create `contracts/` with API specifications
2. Create test files in order: contract → integration → e2e → unit
3. Create source files to make tests pass
```

This ordering constraint ensures the LLM thinks about testability and contracts before implementation, leading to more robust and verifiable specifications.

#### 7. **Preventing Speculative Features**

Templates explicitly discourage speculation:

```text
- [ ] No speculative or "might need" features
- [ ] All phases have clear prerequisites and deliverables
```

This stops the LLM from adding "nice to have" features that complicate implementation. Every feature must trace back to a concrete user story with clear acceptance criteria.

### The Compound Effect

These constraints work together to produce specifications that are:

- **Complete**: Checklists ensure nothing is forgotten
- **Unambiguous**: Forced clarification markers highlight uncertainties
- **Testable**: Test-first thinking baked into the process
- **Maintainable**: Proper abstraction levels and information hierarchy
- **Implementable**: Clear phases with concrete deliverables

The templates transform the LLM from a creative writer into a disciplined specification engineer, channeling its capabilities toward producing consistently high-quality, executable specifications that truly drive development.

## 憲法的基盤：アーキテクチャ規律の強制

SDDの中核には憲法—仕様がコードになる方法を統治する不変の原則の集合—があります。憲法（`memory/constitution.md`）はシステムのアーキテクチャDNAとして機能し、生成されたすべての実装が一貫性、シンプルさ、品質を維持することを保証します。

### 開発の9章

憲法は、開発プロセスのあらゆる側面を形作る9つの章を定義します：

#### Article I: Library-First Principle

Every feature must begin as a standalone library—no exceptions. This forces modular design from the start:

```text
Every feature in Specify MUST begin its existence as a standalone library.
No feature shall be implemented directly within application code without
first being abstracted into a reusable library component.
```

This principle ensures that specifications generate modular, reusable code rather than monolithic applications. When the LLM generates an implementation plan, it must structure features as libraries with clear boundaries and minimal dependencies.

#### Article II: CLI Interface Mandate

Every library must expose its functionality through a command-line interface:

```text
All CLI interfaces MUST:
- Accept text as input (via stdin, arguments, or files)
- Produce text as output (via stdout)
- Support JSON format for structured data exchange
```

This enforces observability and testability. The LLM cannot hide functionality inside opaque classes—everything must be accessible and verifiable through text-based interfaces.

#### Article III: Test-First Imperative

The most transformative article—no code before tests:

```text
This is NON-NEGOTIABLE: All implementation MUST follow strict Test-Driven Development.
No implementation code shall be written before:
1. Unit tests are written
2. Tests are validated and approved by the user
3. Tests are confirmed to FAIL (Red phase)
```

This completely inverts traditional AI code generation. Instead of generating code and hoping it works, the LLM must first generate comprehensive tests that define behavior, get them approved, and only then generate implementation.

#### Articles VII & VIII: Simplicity and Anti-Abstraction

These paired articles combat over-engineering:

```text
Section 7.3: Minimal Project Structure
- Maximum 3 projects for initial implementation
- Additional projects require documented justification

Section 8.1: Framework Trust
- Use framework features directly rather than wrapping them
```

When an LLM might naturally create elaborate abstractions, these articles force it to justify every layer of complexity. The implementation plan template's "Phase -1 Gates" directly enforce these principles.

#### Article IX: Integration-First Testing

Prioritizes real-world testing over isolated unit tests:

```text
Tests MUST use realistic environments:
- Prefer real databases over mocks
- Use actual service instances over stubs
- Contract tests mandatory before implementation
```

This ensures generated code works in practice, not just in theory.

### Constitutional Enforcement Through Templates

The implementation plan template operationalizes these articles through concrete checkpoints:

```markdown
### Phase -1: Pre-Implementation Gates
#### Simplicity Gate (Article VII)
- [ ] Using ≤3 projects?
- [ ] No future-proofing?

#### Anti-Abstraction Gate (Article VIII)
- [ ] Using framework directly?
- [ ] Single model representation?

#### Integration-First Gate (Article IX)
- [ ] Contracts defined?
- [ ] Contract tests written?
```

These gates act as compile-time checks for architectural principles. The LLM cannot proceed without either passing the gates or documenting justified exceptions in the "Complexity Tracking" section.

### The Power of Immutable Principles

The constitution's power lies in its immutability. While implementation details can evolve, the core principles remain constant. This provides:

1. **Consistency Across Time**: Code generated today follows the same principles as code generated next year
2. **Consistency Across LLMs**: Different AI models produce architecturally compatible code
3. **Architectural Integrity**: Every feature reinforces rather than undermines the system design
4. **Quality Guarantees**: Test-first, library-first, and simplicity principles ensure maintainable code

### Constitutional Evolution

While principles are immutable, their application can evolve:

```text
Section 4.2: Amendment Process
Modifications to this constitution require:
- Explicit documentation of the rationale for change
- Review and approval by project maintainers
- Backwards compatibility assessment
```

This allows the methodology to learn and improve while maintaining stability. The constitution shows its own evolution with dated amendments, demonstrating how principles can be refined based on real-world experience.

### Beyond Rules: A Development Philosophy

The constitution isn't just a rulebook—it's a philosophy that shapes how LLMs think about code generation:

- **Observability Over Opacity**: Everything must be inspectable through CLI interfaces
- **Simplicity Over Cleverness**: Start simple, add complexity only when proven necessary
- **Integration Over Isolation**: Test in real environments, not artificial ones
- **Modularity Over Monoliths**: Every feature is a library with clear boundaries

By embedding these principles into the specification and planning process, SDD ensures that generated code isn't just functional—it's maintainable, testable, and architecturally sound. The constitution transforms AI from a code generator into an architectural partner that respects and reinforces system design principles.

## 変革

これは開発者を置き換えたり、創造性を自動化したりすることではありません。機械的な翻訳を自動化することで人間の能力を増幅することです。仕様、研究、コードが一緒に進化する緊密なフィードバックループを作成することで、各反復がより深い理解と意図と実装の間のより良い整合性をもたらします。

ソフトウェア開発には、意図と実装の間の整合性を維持するためのより良いツールが必要です。SDDは、単にコードを導くだけでなくコードを生成する実行可能な仕様を通じてこの整合性を達成するための手法を提供します。
