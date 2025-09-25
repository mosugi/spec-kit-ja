#!/usr/bin/env bash

# plan.mdからの情報でエージェントコンテキストファイルを更新
#
# このスクリプトは、機能仕様を解析し、AIエージェント固有の設定ファイルを
# プロジェクト情報で更新することにAIエージェントコンテキストファイルを維持します。
#
# 主要機能:
# 1. 環境バリデーション
#    - gitリポジトリ構造とブランチ情報を検証
#    - 必要なplan.mdファイルとテンプレートをチェック
#    - ファイル権限とアクセシビリティを検証
#
# 2. 計画データ抽出
#    - plan.mdファイルを解析してプロジェクトメタデータを抽出
#    - 言語/バージョン、フレームワーク、データベース、プロジェクトタイプを識別
#    - 欠落したり不完全な仕様データを適切に処理
#
# 3. エージェントファイル管理
#    - 必要に応じてテンプレートから新しいエージェントコンテキストファイルを作成
#    - 既存のエージェントファイルを新しいプロジェクト情報で更新
#    - 手動追加とカスタム設定を保持
#    - 複数のAIエージェント形式とディレクトリ構造をサポート
#
# 4. コンテンツ生成
#    - 言語固有のビルド/テストコマンドを生成
#    - 適切なプロジェクトディレクトリ構造を作成
#    - 技術スタックと最近の変更セクションを更新
#    - 一負したフォーマットとタイムスタンプを維持
#
# 5. マルチエージェントサポート
#    - エージェント固有のファイルパスと命名規約を処理
#    - サポート対象: Claude, Gemini, Copilot, Cursor, Qwen, opencode, Codex, Windsurf
#    - 単一エージェントまたは既存の全エージェントファイルを更新可能
#    - エージェントファイルが存在しない場合はデフォルトのClaudeファイルを作成
#
# 使用法: ./update-agent-context.sh [agent_type]
# エージェントタイプ: claude|gemini|copilot|cursor|qwen|opencode|codex|windsurf
# 既存の全エージェントファイルを更新する場合は空で留める

set -e

# 厳密なエラーハンドリングを有効化
set -u
set -o pipefail

#==============================================================================
# 設定とグローバル変数
#==============================================================================

# スクリプトディレクトリを取得し、共通関数を読み込み
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"

# 共通関数から全パスと変数を取得
eval $(get_feature_paths)

NEW_PLAN="$IMPL_PLAN"  # 既存コードとの互換性のためのエイリアス
AGENT_TYPE="${1:-}"

# エージェント固有のファイルパス
CLAUDE_FILE="$REPO_ROOT/CLAUDE.md"
GEMINI_FILE="$REPO_ROOT/GEMINI.md"
COPILOT_FILE="$REPO_ROOT/.github/copilot-instructions.md"
CURSOR_FILE="$REPO_ROOT/.cursor/rules/specify-rules.mdc"
QWEN_FILE="$REPO_ROOT/QWEN.md"
AGENTS_FILE="$REPO_ROOT/AGENTS.md"
WINDSURF_FILE="$REPO_ROOT/.windsurf/rules/specify-rules.md"
KILOCODE_FILE="$REPO_ROOT/.kilocode/rules/specify-rules.md"
AUGGIE_FILE="$REPO_ROOT/.augment/rules/specify-rules.md"
ROO_FILE="$REPO_ROOT/.roo/rules/specify-rules.md"

# テンプレートファイル
TEMPLATE_FILE="$REPO_ROOT/.specify/templates/agent-file-template.md"

# 解析された計画データ用のグローバル変数
NEW_LANG=""
NEW_FRAMEWORK=""
NEW_DB=""
NEW_PROJECT_TYPE=""

#==============================================================================
# ユーティリティ関数
#==============================================================================

log_info() {
    echo "INFO: $1"
}

log_success() {
    echo "✓ $1"
}

log_error() {
    echo "ERROR: $1" >&2
}

log_warning() {
    echo "WARNING: $1" >&2
}

# 一時ファイル用のクリーンアップ関数
cleanup() {
    local exit_code=$?
    rm -f /tmp/agent_update_*_$$
    rm -f /tmp/manual_additions_$$
    exit $exit_code
}

# クリーンアップトラップを設定
trap cleanup EXIT INT TERM

#==============================================================================
# バリデーション関数
#==============================================================================

validate_environment() {
    # 現在のブランチ/機能があるかチェック（gitまたは非git）
    if [[ -z "$CURRENT_BRANCH" ]]; then
        log_error "Unable to determine current feature"
        if [[ "$HAS_GIT" == "true" ]]; then
            log_info "機能ブランチ上にいることを確認してください"
        else
            log_info "SPECIFY_FEATURE環境変数を設定するか、まず機能を作成してください"
        fi
        exit 1
    fi
    
    # plan.mdが存在するかチェック
    if [[ ! -f "$NEW_PLAN" ]]; then
        log_error "No plan.md found at $NEW_PLAN"
        log_info "対応する仕様ディレクトリを持つ機能で作業していることを確認してください"
        if [[ "$HAS_GIT" != "true" ]]; then
            log_info "使用方法: export SPECIFY_FEATURE=your-feature-name またはまず新しい機能を作成してください"
        fi
        exit 1
    fi
    
    # テンプレートが存在するかチェック（新しいファイル用）
    if [[ ! -f "$TEMPLATE_FILE" ]]; then
        log_warning "Template file not found at $TEMPLATE_FILE"
        log_warning "新しいエージェントファイルの作成に失敗します"
    fi
}

#==============================================================================
# 計画解析関数
#==============================================================================

extract_plan_field() {
    local field_pattern="$1"
    local plan_file="$2"
    
    grep "^\*\*${field_pattern}\*\*: " "$plan_file" 2>/dev/null | \
        head -1 | \
        sed "s|^\*\*${field_pattern}\*\*: ||" | \
        sed 's/^[ \t]*//;s/[ \t]*$//' | \
        grep -v "NEEDS CLARIFICATION" | \
        grep -v "^N/A$" || echo ""
}

parse_plan_data() {
    local plan_file="$1"
    
    if [[ ! -f "$plan_file" ]]; then
        log_error "Plan file not found: $plan_file"
        return 1
    fi
    
    if [[ ! -r "$plan_file" ]]; then
        log_error "Plan file is not readable: $plan_file"
        return 1
    fi
    
    log_info "$plan_fileから計画データを解析中"
    
    NEW_LANG=$(extract_plan_field "Language/Version" "$plan_file")
    NEW_FRAMEWORK=$(extract_plan_field "Primary Dependencies" "$plan_file")
    NEW_DB=$(extract_plan_field "Storage" "$plan_file")
    NEW_PROJECT_TYPE=$(extract_plan_field "Project Type" "$plan_file")
    
    # 発見した内容をログ出力
    if [[ -n "$NEW_LANG" ]]; then
        log_info "言語を発見: $NEW_LANG"
    else
        log_warning "計画に言語情報が見つかりません"
    fi
    
    if [[ -n "$NEW_FRAMEWORK" ]]; then
        log_info "フレームワークを発見: $NEW_FRAMEWORK"
    fi
    
    if [[ -n "$NEW_DB" ]] && [[ "$NEW_DB" != "N/A" ]]; then
        log_info "データベースを発見: $NEW_DB"
    fi
    
    if [[ -n "$NEW_PROJECT_TYPE" ]]; then
        log_info "プロジェクトタイプを発見: $NEW_PROJECT_TYPE"
    fi
}

format_technology_stack() {
    local lang="$1"
    local framework="$2"
    local parts=()
    
    # 空でない部分を追加
    [[ -n "$lang" && "$lang" != "NEEDS CLARIFICATION" ]] && parts+=("$lang")
    [[ -n "$framework" && "$framework" != "NEEDS CLARIFICATION" && "$framework" != "N/A" ]] && parts+=("$framework")
    
    # 適切なフォーマットで結合
    if [[ ${#parts[@]} -eq 0 ]]; then
        echo ""
    elif [[ ${#parts[@]} -eq 1 ]]; then
        echo "${parts[0]}"
    else
        # 複数の部分を" + "で結合
        local result="${parts[0]}"
        for ((i=1; i<${#parts[@]}; i++)); do
            result="$result + ${parts[i]}"
        done
        echo "$result"
    fi
}

#==============================================================================
# テンプレートとコンテンツ生成関数
#==============================================================================

get_project_structure() {
    local project_type="$1"
    
    if [[ "$project_type" == *"web"* ]]; then
        echo "backend/\\nfrontend/\\ntests/"
    else
        echo "src/\\ntests/"
    fi
}

get_commands_for_language() {
    local lang="$1"
    
    case "$lang" in
        *"Python"*)
            echo "cd src && pytest && ruff check ."
            ;;
        *"Rust"*)
            echo "cargo test && cargo clippy"
            ;;
        *"JavaScript"*|*"TypeScript"*)
            echo "npm test && npm run lint"
            ;;
        *)
            echo "# $lang用のコマンドを追加"
            ;;
    esac
}

get_language_conventions() {
    local lang="$1"
    echo "$lang: Follow standard conventions"
}

create_new_agent_file() {
    local target_file="$1"
    local temp_file="$2"
    local project_name="$3"
    local current_date="$4"
    
    if [[ ! -f "$TEMPLATE_FILE" ]]; then
        log_error "Template not found at $TEMPLATE_FILE"
        return 1
    fi
    
    if [[ ! -r "$TEMPLATE_FILE" ]]; then
        log_error "Template file is not readable: $TEMPLATE_FILE"
        return 1
    fi
    
    log_info "テンプレートから新しいエージェントコンテキストファイルを作成中..."
    
    if ! cp "$TEMPLATE_FILE" "$temp_file"; then
        log_error "Failed to copy template file"
        return 1
    fi
    
    # テンプレートプレースホルダーを置換
    local project_structure
    project_structure=$(get_project_structure "$NEW_PROJECT_TYPE")
    
    local commands
    commands=$(get_commands_for_language "$NEW_LANG")
    
    local language_conventions
    language_conventions=$(get_language_conventions "$NEW_LANG")
    
    # より安全なアプローチでエラーチェック付きで置換を実行
    # 異なる区切り文字を使用するかエスケープしてsed用の特殊文字をエスケープ
    local escaped_lang=$(printf '%s\n' "$NEW_LANG" | sed 's/[\[\.*^$()+{}|]/\\&/g')
    local escaped_framework=$(printf '%s\n' "$NEW_FRAMEWORK" | sed 's/[\[\.*^$()+{}|]/\\&/g')
    local escaped_branch=$(printf '%s\n' "$CURRENT_BRANCH" | sed 's/[\[\.*^$()+{}|]/\\&/g')
    
    # 条件付きで技術スタックと最近の変更文字列を構築
    local tech_stack
    if [[ -n "$escaped_lang" && -n "$escaped_framework" ]]; then
        tech_stack="- $escaped_lang + $escaped_framework ($escaped_branch)"
    elif [[ -n "$escaped_lang" ]]; then
        tech_stack="- $escaped_lang ($escaped_branch)"
    elif [[ -n "$escaped_framework" ]]; then
        tech_stack="- $escaped_framework ($escaped_branch)"
    else
        tech_stack="- ($escaped_branch)"
    fi

    local recent_change
    if [[ -n "$escaped_lang" && -n "$escaped_framework" ]]; then
        recent_change="- $escaped_branch: Added $escaped_lang + $escaped_framework"
    elif [[ -n "$escaped_lang" ]]; then
        recent_change="- $escaped_branch: Added $escaped_lang"
    elif [[ -n "$escaped_framework" ]]; then
        recent_change="- $escaped_branch: Added $escaped_framework"
    else
        recent_change="- $escaped_branch: Added"
    fi

    local substitutions=(
        "s|\[PROJECT NAME\]|$project_name|"
        "s|\[DATE\]|$current_date|"
        "s|\[EXTRACTED FROM ALL PLAN.MD FILES\]|$tech_stack|"
        "s|\[ACTUAL STRUCTURE FROM PLANS\]|$project_structure|g"
        "s|\[ONLY COMMANDS FOR ACTIVE TECHNOLOGIES\]|$commands|"
        "s|\[LANGUAGE-SPECIFIC, ONLY FOR LANGUAGES IN USE\]|$language_conventions|"
        "s|\[LAST 3 FEATURES AND WHAT THEY ADDED\]|$recent_change|"
    )
    
    for substitution in "${substitutions[@]}"; do
        if ! sed -i.bak -e "$substitution" "$temp_file"; then
            log_error "Failed to perform substitution: $substitution"
            rm -f "$temp_file" "$temp_file.bak"
            return 1
        fi
    done
    
    # \nシーケンスを実際の改行文字に変換
    newline=$(printf '\n')
    sed -i.bak2 "s/\\\\n/${newline}/g" "$temp_file"
    
    # バックアップファイルをクリーンアップ
    rm -f "$temp_file.bak" "$temp_file.bak2"
    
    return 0
}




update_existing_agent_file() {
    local target_file="$1"
    local current_date="$2"
    
    log_info "既存のエージェントコンテキストファイルを更新中..."
    
    # アトミック更新用の単一一時ファイルを使用
    local temp_file
    temp_file=$(mktemp) || {
        log_error "Failed to create temporary file"
        return 1
    }
    
    # ファイルを一度のパスで処理
    local tech_stack=$(format_technology_stack "$NEW_LANG" "$NEW_FRAMEWORK")
    local new_tech_entries=()
    local new_change_entry=""
    
    # 新しい技術エントリを準備
    if [[ -n "$tech_stack" ]] && ! grep -q "$tech_stack" "$target_file"; then
        new_tech_entries+=("- $tech_stack ($CURRENT_BRANCH)")
    fi
    
    if [[ -n "$NEW_DB" ]] && [[ "$NEW_DB" != "N/A" ]] && [[ "$NEW_DB" != "NEEDS CLARIFICATION" ]] && ! grep -q "$NEW_DB" "$target_file"; then
        new_tech_entries+=("- $NEW_DB ($CURRENT_BRANCH)")
    fi
    
    # 新しい変更エントリを準備
    if [[ -n "$tech_stack" ]]; then
        new_change_entry="- $CURRENT_BRANCH: Added $tech_stack"
    elif [[ -n "$NEW_DB" ]] && [[ "$NEW_DB" != "N/A" ]] && [[ "$NEW_DB" != "NEEDS CLARIFICATION" ]]; then
        new_change_entry="- $CURRENT_BRANCH: Added $NEW_DB"
    fi
    
    # ファイルを行ごとに処理
    local in_tech_section=false
    local in_changes_section=false
    local tech_entries_added=false
    local changes_entries_added=false
    local existing_changes_count=0
    
    while IFS= read -r line || [[ -n "$line" ]]; do
        # アクティブテクノロジーセクションを処理
        if [[ "$line" == "## Active Technologies" ]]; then
            echo "$line" >> "$temp_file"
            in_tech_section=true
            continue
        elif [[ $in_tech_section == true ]] && [[ "$line" =~ ^##[[:space:]] ]]; then
            # セクションを閉じる前に新しい技術エントリを追加
            if [[ $tech_entries_added == false ]] && [[ ${#new_tech_entries[@]} -gt 0 ]]; then
                printf '%s\n' "${new_tech_entries[@]}" >> "$temp_file"
                tech_entries_added=true
            fi
            echo "$line" >> "$temp_file"
            in_tech_section=false
            continue
        elif [[ $in_tech_section == true ]] && [[ -z "$line" ]]; then
            # 技術セクションの空行前に新しい技術エントリを追加
            if [[ $tech_entries_added == false ]] && [[ ${#new_tech_entries[@]} -gt 0 ]]; then
                printf '%s\n' "${new_tech_entries[@]}" >> "$temp_file"
                tech_entries_added=true
            fi
            echo "$line" >> "$temp_file"
            continue
        fi
        
        # 最近の変更セクションを処理
        if [[ "$line" == "## Recent Changes" ]]; then
            echo "$line" >> "$temp_file"
            # ヘッダーの直後に新しい変更エントリを追加
            if [[ -n "$new_change_entry" ]]; then
                echo "$new_change_entry" >> "$temp_file"
            fi
            in_changes_section=true
            changes_entries_added=true
            continue
        elif [[ $in_changes_section == true ]] && [[ "$line" =~ ^##[[:space:]] ]]; then
            echo "$line" >> "$temp_file"
            in_changes_section=false
            continue
        elif [[ $in_changes_section == true ]] && [[ "$line" == "- "* ]]; then
            # 既存の変更の最初の2つだけを保持
            if [[ $existing_changes_count -lt 2 ]]; then
                echo "$line" >> "$temp_file"
                ((existing_changes_count++))
            fi
            continue
        fi
        
        # タイムスタンプを更新
        if [[ "$line" =~ \*\*Last\ updated\*\*:.*[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9] ]]; then
            echo "$line" | sed "s/[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]/$current_date/" >> "$temp_file"
        else
            echo "$line" >> "$temp_file"
        fi
    done < "$target_file"
    
    # ループ後チェック: まだアクティブテクノロジーセクションにいて新しいエントリを追加していない場合
    if [[ $in_tech_section == true ]] && [[ $tech_entries_added == false ]] && [[ ${#new_tech_entries[@]} -gt 0 ]]; then
        printf '%s\n' "${new_tech_entries[@]}" >> "$temp_file"
    fi
    
    # 一時ファイルをターゲットにアトミックに移動
    if ! mv "$temp_file" "$target_file"; then
        log_error "Failed to update target file"
        rm -f "$temp_file"
        return 1
    fi
    
    return 0
}
#==============================================================================
# メインエージェントファイル更新関数
#==============================================================================

update_agent_file() {
    local target_file="$1"
    local agent_name="$2"
    
    if [[ -z "$target_file" ]] || [[ -z "$agent_name" ]]; then
        log_error "update_agent_file requires target_file and agent_name parameters"
        return 1
    fi
    
    log_info "$agent_nameコンテキストファイルを更新中: $target_file"
    
    local project_name
    project_name=$(basename "$REPO_ROOT")
    local current_date
    current_date=$(date +%Y-%m-%d)
    
    # ディレクトリが存在しない場合は作成
    local target_dir
    target_dir=$(dirname "$target_file")
    if [[ ! -d "$target_dir" ]]; then
        if ! mkdir -p "$target_dir"; then
            log_error "Failed to create directory: $target_dir"
            return 1
        fi
    fi
    
    if [[ ! -f "$target_file" ]]; then
        # テンプレートから新しいファイルを作成
        local temp_file
        temp_file=$(mktemp) || {
            log_error "Failed to create temporary file"
            return 1
        }
        
        if create_new_agent_file "$target_file" "$temp_file" "$project_name" "$current_date"; then
            if mv "$temp_file" "$target_file"; then
                log_success "新しい$agent_nameコンテキストファイルを作成しました"
            else
                log_error "Failed to move temporary file to $target_file"
                rm -f "$temp_file"
                return 1
            fi
        else
            log_error "Failed to create new agent file"
            rm -f "$temp_file"
            return 1
        fi
    else
        # 既存ファイルを更新
        if [[ ! -r "$target_file" ]]; then
            log_error "Cannot read existing file: $target_file"
            return 1
        fi
        
        if [[ ! -w "$target_file" ]]; then
            log_error "Cannot write to existing file: $target_file"
            return 1
        fi
        
        if update_existing_agent_file "$target_file" "$current_date"; then
            log_success "既存の$agent_nameコンテキストファイルを更新しました"
        else
            log_error "Failed to update existing agent file"
            return 1
        fi
    fi
    
    return 0
}

#==============================================================================
# エージェント選択と処理
#==============================================================================

update_specific_agent() {
    local agent_type="$1"
    
    case "$agent_type" in
        claude)
            update_agent_file "$CLAUDE_FILE" "Claude Code"
            ;;
        gemini)
            update_agent_file "$GEMINI_FILE" "Gemini CLI"
            ;;
        copilot)
            update_agent_file "$COPILOT_FILE" "GitHub Copilot"
            ;;
        cursor)
            update_agent_file "$CURSOR_FILE" "Cursor IDE"
            ;;
        qwen)
            update_agent_file "$QWEN_FILE" "Qwen Code"
            ;;
        opencode)
            update_agent_file "$AGENTS_FILE" "opencode"
            ;;
        codex)
            update_agent_file "$AGENTS_FILE" "Codex CLI"
            ;;
        windsurf)
            update_agent_file "$WINDSURF_FILE" "Windsurf"
            ;;
        kilocode)
            update_agent_file "$KILOCODE_FILE" "Kilo Code"
            ;;
        auggie)
            update_agent_file "$AUGGIE_FILE" "Auggie CLI"
            ;;
        roo)
            update_agent_file "$ROO_FILE" "Roo Code"
            ;;
        *)
            log_error "Unknown agent type '$agent_type'"
            log_error "Expected: claude|gemini|copilot|cursor|qwen|opencode|codex|windsurf|kilocode|auggie|roo"
            exit 1
            ;;
    esac
}

update_all_existing_agents() {
    local found_agent=false
    
    # 各可能なエージェントファイルをチェックし、存在する場合は更新
    if [[ -f "$CLAUDE_FILE" ]]; then
        update_agent_file "$CLAUDE_FILE" "Claude Code"
        found_agent=true
    fi
    
    if [[ -f "$GEMINI_FILE" ]]; then
        update_agent_file "$GEMINI_FILE" "Gemini CLI"
        found_agent=true
    fi
    
    if [[ -f "$COPILOT_FILE" ]]; then
        update_agent_file "$COPILOT_FILE" "GitHub Copilot"
        found_agent=true
    fi
    
    if [[ -f "$CURSOR_FILE" ]]; then
        update_agent_file "$CURSOR_FILE" "Cursor IDE"
        found_agent=true
    fi
    
    if [[ -f "$QWEN_FILE" ]]; then
        update_agent_file "$QWEN_FILE" "Qwen Code"
        found_agent=true
    fi
    
    if [[ -f "$AGENTS_FILE" ]]; then
        update_agent_file "$AGENTS_FILE" "Codex/opencode"
        found_agent=true
    fi
    
    if [[ -f "$WINDSURF_FILE" ]]; then
        update_agent_file "$WINDSURF_FILE" "Windsurf"
        found_agent=true
    fi
    
    if [[ -f "$KILOCODE_FILE" ]]; then
        update_agent_file "$KILOCODE_FILE" "Kilo Code"
        found_agent=true
    fi

    if [[ -f "$AUGGIE_FILE" ]]; then
        update_agent_file "$AUGGIE_FILE" "Auggie CLI"
        found_agent=true
    fi
    
    if [[ -f "$ROO_FILE" ]]; then
        update_agent_file "$ROO_FILE" "Roo Code"
        found_agent=true
    fi
    
    # エージェントファイルが存在しない場合は、デフォルトのClaudeファイルを作成
    if [[ "$found_agent" == false ]]; then
        log_info "既存のエージェントファイルが見つかりません、デフォルトのClaudeファイルを作成中..."
        update_agent_file "$CLAUDE_FILE" "Claude Code"
    fi
}
print_summary() {
    echo
    log_info "変更の概要:"
    
    if [[ -n "$NEW_LANG" ]]; then
        echo "  - 言語を追加: $NEW_LANG"
    fi
    
    if [[ -n "$NEW_FRAMEWORK" ]]; then
        echo "  - フレームワークを追加: $NEW_FRAMEWORK"
    fi
    
    if [[ -n "$NEW_DB" ]] && [[ "$NEW_DB" != "N/A" ]]; then
        echo "  - データベースを追加: $NEW_DB"
    fi
    
    echo
    log_info "使用方法: $0 [claude|gemini|copilot|cursor|qwen|opencode|codex|windsurf|kilocode|auggie|roo]"
}

#==============================================================================
# メイン実行
#==============================================================================

main() {
    # 続行する前に環境をバリデート
    validate_environment
    
    log_info "=== 機能$CURRENT_BRANCHのエージェントコンテキストファイルを更新中 ==="
    
    # 計画ファイルを解析してプロジェクト情報を抽出
    if ! parse_plan_data "$NEW_PLAN"; then
        log_error "Failed to parse plan data"
        exit 1
    fi
    
    # エージェントタイプ引数に基づいて処理
    local success=true
    
    if [[ -z "$AGENT_TYPE" ]]; then
        # 特定のエージェントが指定されていない - 既存の全エージェントファイルを更新
        log_info "エージェントが指定されていません、既存の全エージェントファイルを更新中..."
        if ! update_all_existing_agents; then
            success=false
        fi
    else
        # 特定のエージェントが指定されている - そのエージェントのみを更新
        log_info "特定のエージェントを更新中: $AGENT_TYPE"
        if ! update_specific_agent "$AGENT_TYPE"; then
            success=false
        fi
    fi
    
    # 概要を出力
    print_summary
    
    if [[ "$success" == true ]]; then
        log_success "エージェントコンテキスト更新が正常に完了しました"
        exit 0
    else
        log_error "エージェントコンテキスト更新がエラーで完了しました"
        exit 1
    fi
}

# スクリプトが直接実行された場合はメイン関数を実行
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
