#!/usr/bin/env python3
# /// script
# requires-python = ">=3.11"
# dependencies = [
#     "typer",
#     "rich",
#     "platformdirs",
#     "readchar",
#     "httpx",
# ]
# ///
"""
Specify CLI - Specifyプロジェクトのセットアップツール

Usage:
    uvx specify-cli.py init <project-name>
    uvx specify-cli.py init .
    uvx specify-cli.py init --here

またはグローバルインストール:
    uv tool install --from specify-cli.py specify-cli
    specify init <project-name>
    uvx specify-cli.py init .
    specify init --here
"""

import os
import subprocess
import sys
import zipfile
import tempfile
import shutil
import shlex
import json
from pathlib import Path
from typing import Optional, Tuple

import typer
import httpx
from rich.console import Console
from rich.panel import Panel
from rich.progress import Progress, SpinnerColumn, TextColumn
from rich.text import Text
from rich.live import Live
from rich.align import Align
from rich.table import Table
from rich.tree import Tree
from typer.core import TyperGroup

# For cross-platform keyboard input
import readchar
import ssl
import truststore

ssl_context = truststore.SSLContext(ssl.PROTOCOL_TLS_CLIENT)
client = httpx.Client(verify=ssl_context)

def _github_token(cli_token: str | None = None) -> str | None:
    """サニタイズされたGitHubトークンを返す（CLIの引数が優先）またはNone。"""
    return ((cli_token or os.getenv("GH_TOKEN") or os.getenv("GITHUB_TOKEN") or "").strip()) or None

def _github_auth_headers(cli_token: str | None = None) -> dict:
    """空でないトークンが存在する場合のみ、AuthorizationヘッダーのディクショナリーAを返す。"""
    token = _github_token(cli_token)
    return {"Authorization": f"Bearer {token}"} if token else {}

# 定数
AI_CHOICES = {
    "copilot": "GitHub Copilot",
    "claude": "Claude Code",
    "gemini": "Gemini CLI",
    "cursor": "Cursor",
    "qwen": "Qwen Code",
    "opencode": "opencode",
    "codex": "Codex CLI",
    "windsurf": "Windsurf",
    "kilocode": "Kilo Code",
    "auggie": "Auggie CLI",
    "roo": "Roo Code",
}
# スクリプトタイプの選択肢を追加
SCRIPT_TYPE_CHOICES = {"sh": "POSIX Shell (bash/zsh)", "ps": "PowerShell"}

# migrate-installer後のClaude CLIのローカルインストールパス
CLAUDE_LOCAL_PATH = Path.home() / ".claude" / "local" / "claude"

# ASCIIアートバナー
BANNER = """
███████╗██████╗ ███████╗ ██████╗██╗███████╗██╗   ██╗
██╔════╝██╔══██╗██╔════╝██╔════╝██║██╔════╝╚██╗ ██╔╝
███████╗██████╔╝█████╗  ██║     ██║█████╗   ╚████╔╝ 
╚════██║██╔═══╝ ██╔══╝  ██║     ██║██╔══╝    ╚██╔╝  
███████║██║     ███████╗╚██████╗██║██║        ██║   
╚══════╝╚═╝     ╚══════╝ ╚═════╝╚═╝╚═╝        ╚═╝   
"""

TAGLINE = "GitHub Spec Kit - 仕様駆動開発ツールキット"
class StepTracker:
    """絵文字なしで階層的なステップを追跡および表示。Claude Codeツリー出力と同様。
    アタッチされたリフレッシュコールバックによるライブ自動更新をサポート。
    """
    def __init__(self, title: str):
        self.title = title
        self.steps = []  # list of dicts: {key, label, status, detail}
        self.status_order = {"pending": 0, "running": 1, "done": 2, "error": 3, "skipped": 4}
        self._refresh_cb = None  # callable to trigger UI refresh

    def attach_refresh(self, cb):
        self._refresh_cb = cb

    def add(self, key: str, label: str):
        if key not in [s["key"] for s in self.steps]:
            self.steps.append({"key": key, "label": label, "status": "pending", "detail": ""})
            self._maybe_refresh()

    def start(self, key: str, detail: str = ""):
        self._update(key, status="running", detail=detail)

    def complete(self, key: str, detail: str = ""):
        self._update(key, status="done", detail=detail)

    def error(self, key: str, detail: str = ""):
        self._update(key, status="error", detail=detail)

    def skip(self, key: str, detail: str = ""):
        self._update(key, status="skipped", detail=detail)

    def _update(self, key: str, status: str, detail: str):
        for s in self.steps:
            if s["key"] == key:
                s["status"] = status
                if detail:
                    s["detail"] = detail
                self._maybe_refresh()
                return
        # If not present, add it
        self.steps.append({"key": key, "label": key, "status": status, "detail": detail})
        self._maybe_refresh()

    def _maybe_refresh(self):
        if self._refresh_cb:
            try:
                self._refresh_cb()
            except Exception:
                pass

    def render(self):
        tree = Tree(f"[cyan]{self.title}[/cyan]", guide_style="grey50")
        for step in self.steps:
            label = step["label"]
            detail_text = step["detail"].strip() if step["detail"] else ""

            # Circles (unchanged styling)
            status = step["status"]
            if status == "done":
                symbol = "[green]●[/green]"
            elif status == "pending":
                symbol = "[green dim]○[/green dim]"
            elif status == "running":
                symbol = "[cyan]○[/cyan]"
            elif status == "error":
                symbol = "[red]●[/red]"
            elif status == "skipped":
                symbol = "[yellow]○[/yellow]"
            else:
                symbol = " "

            if status == "pending":
                # Entire line light gray (pending)
                if detail_text:
                    line = f"{symbol} [bright_black]{label} ({detail_text})[/bright_black]"
                else:
                    line = f"{symbol} [bright_black]{label}[/bright_black]"
            else:
                # Label white, detail (if any) light gray in parentheses
                if detail_text:
                    line = f"{symbol} [white]{label}[/white] [bright_black]({detail_text})[/bright_black]"
                else:
                    line = f"{symbol} [white]{label}[/white]"

            tree.add(line)
        return tree



MINI_BANNER = """
╔═╗╔═╗╔═╗╔═╗╦╔═╗╦ ╦
╚═╗╠═╝║╣ ║  ║╠╣ ╚╦╝
╚═╝╩  ╚═╝╚═╝╩╚   ╩ 
"""

def get_key():
    """クロスプラットフォームでreadcharを使用して単一のキー入力を取得。"""
    key = readchar.readkey()
    
    # Arrow keys
    if key == readchar.key.UP or key == readchar.key.CTRL_P:
        return 'up'
    if key == readchar.key.DOWN or key == readchar.key.CTRL_N:
        return 'down'

    # Enter/Returnキー
    if key == readchar.key.ENTER:
        return 'enter'

    # Escapeキー
    if key == readchar.key.ESC:
        return 'escape'

    # Ctrl+C
    if key == readchar.key.CTRL_C:
        raise KeyboardInterrupt

    return key



def select_with_arrows(options: dict, prompt_text: str = "Select an option", default_key: str = None) -> str:
    """
    Rich Live表示と矢印キーを使用したインタラクティブ選択。

    Args:
        options: オプションキーと説明のディクショナリ
        prompt_text: オプションの上に表示するテキスト
        default_key: デフォルトのオプションキー

    Returns:
        選択されたオプションキー
    """
    option_keys = list(options.keys())
    if default_key and default_key in option_keys:
        selected_index = option_keys.index(default_key)
    else:
        selected_index = 0
    
    selected_key = None

    def create_selection_panel():
        """現在の選択がハイライトされた選択パネルを作成。"""
        table = Table.grid(padding=(0, 2))
        table.add_column(style="cyan", justify="left", width=3)
        table.add_column(style="white", justify="left")
        
        for i, key in enumerate(option_keys):
            if i == selected_index:
                table.add_row("▶", f"[cyan]{key}[/cyan] [dim]({options[key]})[/dim]")
            else:
                table.add_row(" ", f"[cyan]{key}[/cyan] [dim]({options[key]})[/dim]")
        
        table.add_row("", "")
        table.add_row("", "[dim]↑/↓でナビゲート、Enterで選択、Escでキャンセル[/dim]")
        
        return Panel(
            table,
            title=f"[bold]{prompt_text}[/bold]",
            border_style="cyan",
            padding=(1, 2)
        )
    
    console.print()

    def run_selection_loop():
        nonlocal selected_key, selected_index
        with Live(create_selection_panel(), console=console, transient=True, auto_refresh=False) as live:
            while True:
                try:
                    key = get_key()
                    if key == 'up':
                        selected_index = (selected_index - 1) % len(option_keys)
                    elif key == 'down':
                        selected_index = (selected_index + 1) % len(option_keys)
                    elif key == 'enter':
                        selected_key = option_keys[selected_index]
                        break
                    elif key == 'escape':
                        console.print("\n[yellow]選択がキャンセルされました[/yellow]")
                        raise typer.Exit(1)
                    
                    live.update(create_selection_panel(), refresh=True)

                except KeyboardInterrupt:
                    console.print("\n[yellow]選択がキャンセルされました[/yellow]")
                    raise typer.Exit(1)

    run_selection_loop()

    if selected_key is None:
        console.print("\n[red]選択が失敗しました。[/red]")
        raise typer.Exit(1)

    # 明示的な選択の出力を抑制; トラッカー/後続ロジックが統合ステータスを報告
    return selected_key



console = Console()


class BannerGroup(TyperGroup):
    """ヘルプの前にバナーを表示するカスタムグループ。"""

    def format_help(self, ctx, formatter):
        # ヘルプの前にバナーを表示
        show_banner()
        super().format_help(ctx, formatter)


app = typer.Typer(
    name="specify",
    help="Specify仕様駆動開発プロジェクトのセットアップツール",
    add_completion=False,
    invoke_without_command=True,
    cls=BannerGroup,
)


def show_banner():
    """ASCIIアートバナーを表示。"""
    # 異なる色でグラデーション効果を作成
    banner_lines = BANNER.strip().split('\n')
    colors = ["bright_blue", "blue", "cyan", "bright_cyan", "white", "bright_white"]
    
    styled_banner = Text()
    for i, line in enumerate(banner_lines):
        color = colors[i % len(colors)]
        styled_banner.append(line + "\n", style=color)
    
    console.print(Align.center(styled_banner))
    console.print(Align.center(Text(TAGLINE, style="italic bright_yellow")))
    console.print()


@app.callback()
def callback(ctx: typer.Context):
    """サブコマンドが指定されていない場合にバナーを表示。"""
    # サブコマンドとヘルプフラグがない場合のみバナーを表示
    # (ヘルプはBannerGroupによって処理される)
    if ctx.invoked_subcommand is None and "--help" not in sys.argv and "-h" not in sys.argv:
        show_banner()
        console.print(Align.center("[dim]'specify --help' で使用方法を確認[/dim]"))
        console.print()


def run_command(cmd: list[str], check_return: bool = True, capture: bool = False, shell: bool = False) -> Optional[str]:
    """シェルコマンドを実行し、オプションで出力をキャプチャ。"""
    try:
        if capture:
            result = subprocess.run(cmd, check=check_return, capture_output=True, text=True, shell=shell)
            return result.stdout.strip()
        else:
            subprocess.run(cmd, check=check_return, shell=shell)
            return None
    except subprocess.CalledProcessError as e:
        if check_return:
            console.print(f"[red]コマンド実行エラー:[/red] {' '.join(cmd)}")
            console.print(f"[red]終了コード:[/red] {e.returncode}")
            if hasattr(e, 'stderr') and e.stderr:
                console.print(f"[red]エラー出力:[/red] {e.stderr}")
            raise
        return None


def check_tool_for_tracker(tool: str, tracker: StepTracker) -> bool:
    """ツールがインストールされているかチェックしてトラッカーを更新。"""
    if shutil.which(tool):
        tracker.complete(tool, "利用可能")
        return True
    else:
        tracker.error(tool, "見つかりません")
        return False


def check_tool(tool: str, install_hint: str) -> bool:
    """ツールがインストールされているか確認。"""

    # `claude migrate-installer`後のClaude CLIの特別な処理
    # 参照: https://github.com/github/spec-kit/issues/123
    # migrate-installerコマンドはPATHから元の実行ファイルを削除し
    # 代わりに~/.claude/local/claudeにエイリアスを作成する
    # このパスはPATH内の他のclaude実行ファイルより優先されるべき
    if tool == "claude":
        if CLAUDE_LOCAL_PATH.exists() and CLAUDE_LOCAL_PATH.is_file():
            return True
    
    if shutil.which(tool):
        return True
    else:
        return False


def is_git_repo(path: Path = None) -> bool:
    """指定されたパスがgitリポジトリ内にあるかチェック。"""
    if path is None:
        path = Path.cwd()

    if not path.is_dir():
        return False

    try:
        # gitコマンドを使用してワークツリー内にあるかチェック
        subprocess.run(
            ["git", "rev-parse", "--is-inside-work-tree"],
            check=True,
            capture_output=True,
            cwd=path,
        )
        return True
    except (subprocess.CalledProcessError, FileNotFoundError):
        return False


def init_git_repo(project_path: Path, quiet: bool = False) -> bool:
    """指定されたパスにgitリポジトリを初期化。
    quiet: Trueの場合コンソール出力を抑制（トラッカーがステータスを処理）
    """
    try:
        original_cwd = Path.cwd()
        os.chdir(project_path)
        if not quiet:
            console.print("[cyan]gitリポジトリを初期化中...[/cyan]")
        subprocess.run(["git", "init"], check=True, capture_output=True)
        subprocess.run(["git", "add", "."], check=True, capture_output=True)
        subprocess.run(["git", "commit", "-m", "Specifyテンプレートからの初期コミット"], check=True, capture_output=True)
        if not quiet:
            console.print("[green]✓[/green] gitリポジトリが初期化されました")
        return True
        
    except subprocess.CalledProcessError as e:
        if not quiet:
            console.print(f"[red]gitリポジトリ初期化エラー:[/red] {e}")
        return False
    finally:
        os.chdir(original_cwd)


def download_template_from_github(ai_assistant: str, download_dir: Path, *, script_type: str = "sh", verbose: bool = True, show_progress: bool = True, client: httpx.Client = None, debug: bool = False, github_token: str = None) -> Tuple[Path, dict]:
    repo_owner = "mosugi"
    repo_name = "spec-kit-ja"
    if client is None:
        client = httpx.Client(verify=ssl_context)
    
    if verbose:
        console.print(f"[cyan]{repo_owner}/{repo_name}から最新リリース情報を取得中...[/cyan]")
    api_url = f"https://api.github.com/repos/{repo_owner}/{repo_name}/releases/latest"
    
    try:
        response = client.get(
            api_url,
            timeout=30,
            follow_redirects=True,
            headers=_github_auth_headers(github_token),
        )
        status = response.status_code
        if status != 200:
            msg = f"GitHub APIが{status}を返しました: {api_url}"
            if debug:
                msg += f"\nResponse headers: {response.headers}\nBody (truncated 500): {response.text[:500]}"
            raise RuntimeError(msg)
        try:
            release_data = response.json()
        except ValueError as je:
            raise RuntimeError(f"リリースJSONのパースに失敗: {je}\nRaw (truncated 400): {response.text[:400]}")
    except Exception as e:
        console.print(f"[red]リリース情報の取得エラー[/red]")
        console.print(Panel(str(e), title="取得エラー", border_style="red"))
        raise typer.Exit(1)
    
    # 指定されたAIアシスタント用のテンプレートアセットを検索
    assets = release_data.get("assets", [])
    pattern = f"spec-kit-template-{ai_assistant}-{script_type}"
    matching_assets = [
        asset for asset in assets
        if pattern in asset["name"] and asset["name"].endswith(".zip")
    ]

    asset = matching_assets[0] if matching_assets else None

    if asset is None:
        console.print(f"[red]一致するリリースアセットが見つかりません[/red] 対象: [bold]{ai_assistant}[/bold] (期待パターン: [bold]{pattern}[/bold])")
        asset_names = [a.get('name', '?') for a in assets]
        console.print(Panel("\n".join(asset_names) or "(アセットなし)", title="利用可能なアセット", border_style="yellow"))
        raise typer.Exit(1)

    download_url = asset["browser_download_url"]
    filename = asset["name"]
    file_size = asset["size"]
    
    if verbose:
        console.print(f"[cyan]テンプレートを発見:[/cyan] {filename}")
        console.print(f"[cyan]サイズ:[/cyan] {file_size:,} バイト")
        console.print(f"[cyan]リリース:[/cyan] {release_data['tag_name']}")

    zip_path = download_dir / filename
    if verbose:
        console.print(f"[cyan]テンプレートをダウンロード中...[/cyan]")
    
    try:
        with client.stream(
            "GET",
            download_url,
            timeout=60,
            follow_redirects=True,
            headers=_github_auth_headers(github_token),
        ) as response:
            if response.status_code != 200:
                body_sample = response.text[:400]
                raise RuntimeError(f"Download failed with {response.status_code}\nHeaders: {response.headers}\nBody (truncated): {body_sample}")
            total_size = int(response.headers.get('content-length', 0))
            with open(zip_path, 'wb') as f:
                if total_size == 0:
                    for chunk in response.iter_bytes(chunk_size=8192):
                        f.write(chunk)
                else:
                    if show_progress:
                        with Progress(
                            SpinnerColumn(),
                            TextColumn("[progress.description]{task.description}"),
                            TextColumn("[progress.percentage]{task.percentage:>3.0f}%"),
                            console=console,
                        ) as progress:
                            task = progress.add_task("Downloading...", total=total_size)
                            downloaded = 0
                            for chunk in response.iter_bytes(chunk_size=8192):
                                f.write(chunk)
                                downloaded += len(chunk)
                                progress.update(task, completed=downloaded)
                    else:
                        for chunk in response.iter_bytes(chunk_size=8192):
                            f.write(chunk)
    except Exception as e:
        console.print(f"[red]テンプレートのダウンロードエラー[/red]")
        detail = str(e)
        if zip_path.exists():
            zip_path.unlink()
        console.print(Panel(detail, title="ダウンロードエラー", border_style="red"))
        raise typer.Exit(1)
    if verbose:
        console.print(f"Downloaded: {filename}")
    metadata = {
        "filename": filename,
        "size": file_size,
        "release": release_data["tag_name"],
        "asset_url": download_url
    }
    return zip_path, metadata


def download_and_extract_template(project_path: Path, ai_assistant: str, script_type: str, is_current_dir: bool = False, *, verbose: bool = True, tracker: StepTracker | None = None, client: httpx.Client = None, debug: bool = False, github_token: str = None) -> Path:
    """Download the latest release and extract it to create a new project.
    Returns project_path. Uses tracker if provided (with keys: fetch, download, extract, cleanup)
    """
    current_dir = Path.cwd()
    
    # Step: fetch + download combined
    if tracker:
        tracker.start("fetch", "GitHub APIに接続中")
    try:
        zip_path, meta = download_template_from_github(
            ai_assistant,
            current_dir,
            script_type=script_type,
            verbose=verbose and tracker is None,
            show_progress=(tracker is None),
            client=client,
            debug=debug,
            github_token=github_token
        )
        if tracker:
            tracker.complete("fetch", f"リリース {meta['release']} ({meta['size']:,} バイト)")
            tracker.add("download", "Download template")
            tracker.complete("download", meta['filename'])
    except Exception as e:
        if tracker:
            tracker.error("fetch", str(e))
        else:
            if verbose:
                console.print(f"[red]テンプレートのダウンロードエラー:[/red] {e}")
        raise
    
    if tracker:
        tracker.add("extract", "Extract template")
        tracker.start("extract")
    elif verbose:
        console.print("Extracting template...")
    
    try:
        # Create project directory only if not using current directory
        if not is_current_dir:
            project_path.mkdir(parents=True)
        
        with zipfile.ZipFile(zip_path, 'r') as zip_ref:
            # List all files in the ZIP for debugging
            zip_contents = zip_ref.namelist()
            if tracker:
                tracker.start("zip-list")
                tracker.complete("zip-list", f"{len(zip_contents)}個のエントリ")
            elif verbose:
                console.print(f"[cyan]ZIPに{len(zip_contents)}個のアイテムが含まれています[/cyan]")
            
            # For current directory, extract to a temp location first
            if is_current_dir:
                with tempfile.TemporaryDirectory() as temp_dir:
                    temp_path = Path(temp_dir)
                    zip_ref.extractall(temp_path)
                    
                    # Check what was extracted
                    extracted_items = list(temp_path.iterdir())
                    if tracker:
                        tracker.start("extracted-summary")
                        tracker.complete("extracted-summary", f"一時 {len(extracted_items)}個のアイテム")
                    elif verbose:
                        console.print(f"[cyan]{len(extracted_items)}個のアイテムを一時場所に展開しました[/cyan]")
                    
                    # Handle GitHub-style ZIP with a single root directory
                    source_dir = temp_path
                    if len(extracted_items) == 1 and extracted_items[0].is_dir():
                        source_dir = extracted_items[0]
                        if tracker:
                            tracker.add("flatten", "Flatten nested directory")
                            tracker.complete("flatten")
                        elif verbose:
                            console.print(f"[cyan]ネストされたディレクトリ構造を発見[/cyan]")
                    
                    # Copy contents to current directory
                    for item in source_dir.iterdir():
                        dest_path = project_path / item.name
                        if item.is_dir():
                            if dest_path.exists():
                                if verbose and not tracker:
                                    console.print(f"[yellow]ディレクトリをマージ中:[/yellow] {item.name}")
                                # Recursively copy directory contents
                                for sub_item in item.rglob('*'):
                                    if sub_item.is_file():
                                        rel_path = sub_item.relative_to(item)
                                        dest_file = dest_path / rel_path
                                        dest_file.parent.mkdir(parents=True, exist_ok=True)
                                        shutil.copy2(sub_item, dest_file)
                            else:
                                shutil.copytree(item, dest_path)
                        else:
                            if dest_path.exists() and verbose and not tracker:
                                console.print(f"[yellow]ファイルを上書き:[/yellow] {item.name}")
                            shutil.copy2(item, dest_path)
                    if verbose and not tracker:
                        console.print(f"[cyan]テンプレートファイルを現在のディレクトリにマージしました[/cyan]")
            else:
                # Extract directly to project directory (original behavior)
                zip_ref.extractall(project_path)
                
                # Check what was extracted
                extracted_items = list(project_path.iterdir())
                if tracker:
                    tracker.start("extracted-summary")
                    tracker.complete("extracted-summary", f"{len(extracted_items)}個のトップレベルアイテム")
                elif verbose:
                    console.print(f"[cyan]{len(extracted_items)}個のアイテムを{project_path}に展開:[/cyan]")
                    for item in extracted_items:
                        console.print(f"  - {item.name} ({'dir' if item.is_dir() else 'file'})")
                
                # Handle GitHub-style ZIP with a single root directory
                if len(extracted_items) == 1 and extracted_items[0].is_dir():
                    # Move contents up one level
                    nested_dir = extracted_items[0]
                    temp_move_dir = project_path.parent / f"{project_path.name}_temp"
                    # Move the nested directory contents to temp location
                    shutil.move(str(nested_dir), str(temp_move_dir))
                    # Remove the now-empty project directory
                    project_path.rmdir()
                    # Rename temp directory to project directory
                    shutil.move(str(temp_move_dir), str(project_path))
                    if tracker:
                        tracker.add("flatten", "Flatten nested directory")
                        tracker.complete("flatten")
                    elif verbose:
                        console.print(f"[cyan]ネストされたディレクトリ構造をフラット化しました[/cyan]")
                    
    except Exception as e:
        if tracker:
            tracker.error("extract", str(e))
        else:
            if verbose:
                console.print(f"[red]テンプレートの展開エラー:[/red] {e}")
                if debug:
                    console.print(Panel(str(e), title="展開エラー", border_style="red"))
        # Clean up project directory if created and not current directory
        if not is_current_dir and project_path.exists():
            shutil.rmtree(project_path)
        raise typer.Exit(1)
    else:
        if tracker:
            tracker.complete("extract")
    finally:
        if tracker:
            tracker.add("cleanup", "Remove temporary archive")
        # Clean up downloaded ZIP file
        if zip_path.exists():
            zip_path.unlink()
            if tracker:
                tracker.complete("cleanup")
            elif verbose:
                console.print(f"Cleaned up: {zip_path.name}")
    
    return project_path


def ensure_executable_scripts(project_path: Path, tracker: StepTracker | None = None) -> None:
    """Ensure POSIX .sh scripts under .specify/scripts (recursively) have execute bits (no-op on Windows)."""
    if os.name == "nt":
        return  # Windows: skip silently
    scripts_root = project_path / ".specify" / "scripts"
    if not scripts_root.is_dir():
        return
    failures: list[str] = []
    updated = 0
    for script in scripts_root.rglob("*.sh"):
        try:
            if script.is_symlink() or not script.is_file():
                continue
            try:
                with script.open("rb") as f:
                    if f.read(2) != b"#!":
                        continue
            except Exception:
                continue
            st = script.stat(); mode = st.st_mode
            if mode & 0o111:
                continue
            new_mode = mode
            if mode & 0o400: new_mode |= 0o100
            if mode & 0o040: new_mode |= 0o010
            if mode & 0o004: new_mode |= 0o001
            if not (new_mode & 0o100):
                new_mode |= 0o100
            os.chmod(script, new_mode)
            updated += 1
        except Exception as e:
            failures.append(f"{script.relative_to(scripts_root)}: {e}")
    if tracker:
        detail = f"{updated} updated" + (f", {len(failures)} failed" if failures else "")
        tracker.add("chmod", "Set script permissions recursively")
        (tracker.error if failures else tracker.complete)("chmod", detail)
    else:
        if updated:
            console.print(f"[cyan]{updated}個のスクリプトの実行権限を再帰的に更新しました[/cyan]")
        if failures:
            console.print("[yellow]一部のスクリプトを更新できませんでした:[/yellow]")
            for f in failures:
                console.print(f"  - {f}")

@app.command()
def init(
    project_name: str = typer.Argument(None, help="新しいプロジェクトディレクトリ名 (--here使用時はオプション)"),
    ai_assistant: str = typer.Option(None, "--ai", help="使用するAIアシスタント: claude, gemini, copilot, cursor, qwen, opencode, codex, windsurf, kilocode, またはauggie"),
    script_type: str = typer.Option(None, "--script", help="使用するスクリプトタイプ: sh または ps"),
    ignore_agent_tools: bool = typer.Option(False, "--ignore-agent-tools", help="Claude CodeなどのAIエージェントツールのチェックをスキップ"),
    no_git: bool = typer.Option(False, "--no-git", help="gitリポジトリの初期化をスキップ"),
    here: bool = typer.Option(False, "--here", help="新しいディレクトリを作成せず、現在のディレクトリでプロジェクトを初期化"),
    force: bool = typer.Option(False, "--force", help="--here使用時に強制的にマージ/上書き(確認をスキップ)"),
    skip_tls: bool = typer.Option(False, "--skip-tls", help="SSL/TLS検証をスキップ(非推奨)"),
    debug: bool = typer.Option(False, "--debug", help="ネットワークと抽出失敗時の詳細な診断出力を表示"),
    github_token: str = typer.Option(None, "--github-token", help="APIリクエストで使用するGitHubトークン (またはGH_TOKENやGITHUB_TOKEN環境変数を設定)"),
):
    """
    最新のテンプレートから新しいSpecifyプロジェクトを初期化。

    このコマンドは以下を実行します:
    1. 必要なツールがインストールされているか確認 (gitはオプション)
    2. AIアシスタントを選択 (Claude Code, Gemini CLI, GitHub Copilot, Cursor, Qwen Code, opencode, Codex CLI, Windsurf, Kilo Code, またはAuggie CLI)
    3. GitHubから適切なテンプレートをダウンロード
    4. テンプレートを新しいプロジェクトディレクトリまたは現在のディレクトリに展開
    5. 新しいgitリポジトリを初期化 (--no-gitでなく、既存のリポジトリがない場合)
    6. オプションでAIアシスタントコマンドをセットアップ

    例:
        specify init my-project
        specify init my-project --ai claude
        specify init my-project --ai gemini
        specify init my-project --ai copilot --no-git
        specify init my-project --ai cursor
        specify init my-project --ai qwen
        specify init my-project --ai opencode
        specify init my-project --ai codex
        specify init my-project --ai windsurf
        specify init my-project --ai auggie
        specify init --ignore-agent-tools my-project
        specify init . --ai claude         # Initialize in current directory
        specify init .                     # Initialize in current directory (interactive AI selection)
        specify init --here --ai claude    # Alternative syntax for current directory
        specify init --here --ai codex
        specify init --here
        specify init --here --force  # 現在のディレクトリが空でない場合の確認をスキップ
    """
    # Show banner first
    show_banner()
    
    # Handle '.' as shorthand for current directory (equivalent to --here)
    if project_name == ".":
        here = True
        project_name = None  # Clear project_name to use existing validation logic

    # Validate arguments
    if here and project_name:
        console.print("[red]エラー:[/red] プロジェクト名と--hereフラグを両方指定することはできません")
        raise typer.Exit(1)
    
    if not here and not project_name:
        console.print("[red]エラー:[/red] プロジェクト名を指定するか、--hereフラグを使用してください")
        raise typer.Exit(1)
    
    # Determine project directory
    if here:
        project_name = Path.cwd().name
        project_path = Path.cwd()
        
        # Check if current directory has any files
        existing_items = list(project_path.iterdir())
        if existing_items:
            console.print(f"[yellow]警告:[/yellow] 現在のディレクトリは空ではありません ({len(existing_items)}個のアイテム)")
            console.print("[yellow]テンプレートファイルは既存の内容とマージされ、既存のファイルを上書きする可能性があります[/yellow]")
            if force:
                console.print("[cyan]--forceが指定されました: 確認をスキップしてマージを実行します[/cyan]")
            else:
                # Ask for confirmation
                response = typer.confirm("Do you want to continue?")
                if not response:
                    console.print("[yellow]操作がキャンセルされました[/yellow]")
                    raise typer.Exit(0)
    else:
        project_path = Path(project_name).resolve()
        # Check if project directory already exists
        if project_path.exists():
            error_panel = Panel(
                f"ディレクトリ '[cyan]{project_name}[/cyan]' は既に存在します\n"
                "別のプロジェクト名を選択するか、既存のディレクトリを削除してください。",
                title="[red]ディレクトリの競合[/red]",
                border_style="red",
                padding=(1, 2)
            )
            console.print()
            console.print(error_panel)
            raise typer.Exit(1)
    
    # Create formatted setup info with column alignment
    current_dir = Path.cwd()
    
    setup_lines = [
        "[cyan]Specifyプロジェクトのセットアップ[/cyan]",
        "",
        f"{'プロジェクト':<15} [green]{project_path.name}[/green]",
        f"{'作業パス':<15} [dim]{current_dir}[/dim]",
    ]
    
    # Add target path only if different from working dir
    if not here:
        setup_lines.append(f"{'対象パス':<15} [dim]{project_path}[/dim]")
    
    console.print(Panel("\n".join(setup_lines), border_style="cyan", padding=(1, 2)))
    
    # Check git only if we might need it (not --no-git)
    # Only set to True if the user wants it and the tool is available
    should_init_git = False
    if not no_git:
        should_init_git = check_tool("git", "https://git-scm.com/downloads")
        if not should_init_git:
            console.print("[yellow]Gitが見つかりません - リポジトリの初期化をスキップします[/yellow]")

    # AI assistant selection
    if ai_assistant:
        if ai_assistant not in AI_CHOICES:
            console.print(f"[red]エラー:[/red] 無効なAIアシスタント '{ai_assistant}'。以下から選択: {', '.join(AI_CHOICES.keys())}")
            raise typer.Exit(1)
        selected_ai = ai_assistant
    else:
        # 矢印キー選択インターフェースを使用
        selected_ai = select_with_arrows(
            AI_CHOICES,
            "AIアシスタントを選択:",
            "copilot"
        )
    
    # Check agent tools unless ignored
    if not ignore_agent_tools:
        agent_tool_missing = False
        install_url = ""
        if selected_ai == "claude":
            if not check_tool("claude", "https://docs.anthropic.com/en/docs/claude-code/setup"):
                install_url = "https://docs.anthropic.com/en/docs/claude-code/setup"
                agent_tool_missing = True
        elif selected_ai == "gemini":
            if not check_tool("gemini", "https://github.com/google-gemini/gemini-cli"):
                install_url = "https://github.com/google-gemini/gemini-cli"
                agent_tool_missing = True
        elif selected_ai == "qwen":
            if not check_tool("qwen", "https://github.com/QwenLM/qwen-code"):
                install_url = "https://github.com/QwenLM/qwen-code"
                agent_tool_missing = True
        elif selected_ai == "opencode":
            if not check_tool("opencode", "https://opencode.ai"):
                install_url = "https://opencode.ai"
                agent_tool_missing = True
        elif selected_ai == "codex":
            if not check_tool("codex", "https://github.com/openai/codex"):
                install_url = "https://github.com/openai/codex"
                agent_tool_missing = True
        elif selected_ai == "auggie":
            if not check_tool("auggie", "https://docs.augmentcode.com/cli/setup-auggie/install-auggie-cli"):
                install_url = "https://docs.augmentcode.com/cli/setup-auggie/install-auggie-cli"
                agent_tool_missing = True
        # GitHub Copilot and Cursor checks are not needed as they're typically available in supported IDEs

        if agent_tool_missing:
            error_panel = Panel(
                f"[cyan]{selected_ai}[/cyan] が見つかりません\n"
                f"インストール: [cyan]{install_url}[/cyan]\n"
                f"{AI_CHOICES[selected_ai]}はこのプロジェクトタイプを続行するために必要です。\n\n"
                "ヒント: [cyan]--ignore-agent-tools[/cyan]を使用してこのチェックをスキップ",
                title="[red]エージェント検出エラー[/red]",
                border_style="red",
                padding=(1, 2)
            )
            console.print()
            console.print(error_panel)
            raise typer.Exit(1)
    
    # Determine script type (explicit, interactive, or OS default)
    if script_type:
        if script_type not in SCRIPT_TYPE_CHOICES:
            console.print(f"[red]エラー:[/red] 無効なスクリプトタイプ '{script_type}'。以下から選択: {', '.join(SCRIPT_TYPE_CHOICES.keys())}")
            raise typer.Exit(1)
        selected_script = script_type
    else:
        # Auto-detect default
        default_script = "ps" if os.name == "nt" else "sh"
        # Provide interactive selection similar to AI if stdin is a TTY
        if sys.stdin.isatty():
            selected_script = select_with_arrows(SCRIPT_TYPE_CHOICES, "スクリプトタイプを選択 (またはEnterキー)", default_script)
        else:
            selected_script = default_script
    
    console.print(f"[cyan]選択されたAIアシスタント:[/cyan] {selected_ai}")
    console.print(f"[cyan]選択されたスクリプトタイプ:[/cyan] {selected_script}")
    
    # Download and set up project
    # New tree-based progress (no emojis); include earlier substeps
    tracker = StepTracker("Specifyプロジェクトの初期化")
    # Flag to allow suppressing legacy headings
    sys._specify_tracker_active = True
    # Pre steps recorded as completed before live rendering
    tracker.add("precheck", "必要なツールの確認")
    tracker.complete("precheck", "ok")
    tracker.add("ai-select", "AIアシスタントの選択")
    tracker.complete("ai-select", f"{selected_ai}")
    tracker.add("script-select", "スクリプトタイプの選択")
    tracker.complete("script-select", selected_script)
    for key, label in [
        ("fetch", "最新リリースの取得"),
        ("download", "テンプレートのダウンロード"),
        ("extract", "テンプレートの展開"),
        ("zip-list", "アーカイブの内容"),
        ("extracted-summary", "展開サマリー"),
        ("chmod", "スクリプトの実行可能化"),
        ("cleanup", "クリーンアップ"),
        ("git", "gitリポジトリの初期化"),
        ("final", "完了")
    ]:
        tracker.add(key, label)

    # Use transient so live tree is replaced by the final static render (avoids duplicate output)
    with Live(tracker.render(), console=console, refresh_per_second=8, transient=True) as live:
        tracker.attach_refresh(lambda: live.update(tracker.render()))
        try:
            # Create a httpx client with verify based on skip_tls
            verify = not skip_tls
            local_ssl_context = ssl_context if verify else False
            local_client = httpx.Client(verify=local_ssl_context)

            download_and_extract_template(project_path, selected_ai, selected_script, here, verbose=False, tracker=tracker, client=local_client, debug=debug, github_token=github_token)

            # Ensure scripts are executable (POSIX)
            ensure_executable_scripts(project_path, tracker=tracker)

            # Git step
            if not no_git:
                tracker.start("git")
                if is_git_repo(project_path):
                    tracker.complete("git", "既存のリポジトリを検出")
                elif should_init_git:
                    if init_git_repo(project_path, quiet=True):
                        tracker.complete("git", "初期化完了")
                    else:
                        tracker.error("git", "初期化失敗")
                else:
                    tracker.skip("git", "gitが利用不可")
            else:
                tracker.skip("git", "--no-gitフラグ")

            tracker.complete("final", "プロジェクト準備完了")
        except Exception as e:
            tracker.error("final", str(e))
            console.print(Panel(f"初期化に失敗しました: {e}", title="失敗", border_style="red"))
            if debug:
                _env_pairs = [
                    ("Python", sys.version.split()[0]),
                    ("Platform", sys.platform),
                    ("CWD", str(Path.cwd())),
                ]
                _label_width = max(len(k) for k, _ in _env_pairs)
                env_lines = [f"{k.ljust(_label_width)} → [bright_black]{v}[/bright_black]" for k, v in _env_pairs]
                console.print(Panel("\n".join(env_lines), title="デバッグ環境", border_style="magenta"))
            if not here and project_path.exists():
                shutil.rmtree(project_path)
            raise typer.Exit(1)
        finally:
            # Force final render
            pass

    # Final static tree (ensures finished state visible after Live context ends)
    console.print(tracker.render())
    console.print("\n[bold green]プロジェクトの準備が整いました。[/bold green]")
    
    # Agent folder security notice
    agent_folder_map = {
        "claude": ".claude/",
        "gemini": ".gemini/",
        "cursor": ".cursor/",
        "qwen": ".qwen/",
        "opencode": ".opencode/",
        "codex": ".codex/",
        "windsurf": ".windsurf/",
        "kilocode": ".kilocode/",
        "auggie": ".augment/",
        "copilot": ".github/",
        "roo": ".roo/"
    }
    
    if selected_ai in agent_folder_map:
        agent_folder = agent_folder_map[selected_ai]
        security_notice = Panel(
            f"一部のエージェントは、プロジェクト内のエージェントフォルダに資格情報、認証トークン、またはその他の識別情報やプライベートな成果物を保存する場合があります。\n"
            f"偶発的な資格情報の漏洩を防ぐために、[cyan]{agent_folder}[/cyan]（またはその一部）を[cyan].gitignore[/cyan]に追加することを検討してください。",
            title="[yellow]エージェントフォルダのセキュリティ[/yellow]",
            border_style="yellow",
            padding=(1, 2)
        )
        console.print()
        console.print(security_notice)
    
    # Boxed "Next steps" section
    steps_lines = []
    if not here:
        steps_lines.append(f"1. プロジェクトフォルダに移動: [cyan]cd {project_name}[/cyan]")
        step_num = 2
    else:
        steps_lines.append("1. 既にプロジェクトディレクトリにいます！")
        step_num = 2

    # Add Codex-specific setup step if needed
    if selected_ai == "codex":
        codex_path = project_path / ".codex"
        quoted_path = shlex.quote(str(codex_path))
        if os.name == "nt":  # Windows
            cmd = f"setx CODEX_HOME {quoted_path}"
        else:  # Unix-like systems
            cmd = f"export CODEX_HOME={quoted_path}"
        
        steps_lines.append(f"{step_num}. Codex実行前に[cyan]CODEX_HOME[/cyan]環境変数を設定: [cyan]{cmd}[/cyan]")
        step_num += 1

    steps_lines.append(f"{step_num}. AIエージェントでスラッシュコマンドを使い始める:")
    steps_lines.append("   2.1 [cyan]/constitution[/] - プロジェクト原則の確立")
    steps_lines.append("   2.2 [cyan]/specify[/] - 仕様の作成")
    steps_lines.append("   2.3 [cyan]/clarify[/] - 仕様の明確化とリスク低減 ([cyan]/plan[/cyan]の前に実行)")
    steps_lines.append("   2.4 [cyan]/plan[/] - 実装計画の作成")
    steps_lines.append("   2.5 [cyan]/tasks[/] - アクショナブルなタスクの生成")
    steps_lines.append("   2.6 [cyan]/analyze[/] - 整合性の検証と不一致の検出 (読み取り専用)")
    steps_lines.append("   2.7 [cyan]/implement[/] - 実装の実行")

    steps_panel = Panel("\n".join(steps_lines), title="次のステップ", border_style="cyan", padding=(1,2))
    console.print()
    console.print(steps_panel)

    enhancement_lines = [
        "Optional commands that you can use for your specs [bright_black](improve quality & confidence)[/bright_black]",
        "",
        f"○ [cyan]/clarify[/] [bright_black](optional)[/bright_black] - Ask structured questions to de-risk ambiguous areas before planning (run before [cyan]/plan[/] if used)",
        f"○ [cyan]/analyze[/] [bright_black](optional)[/bright_black] - Cross-artifact consistency & alignment report (after [cyan]/tasks[/], before [cyan]/implement[/])"
    ]
    enhancements_panel = Panel("\n".join(enhancement_lines), title="Enhancement Commands", border_style="cyan", padding=(1,2))
    console.print()
    console.print(enhancements_panel)

    if selected_ai == "codex":
        warning_text = """[bold yellow]重要な注意:[/bold yellow]

Codexではカスタムプロンプトがまだ引数をサポートしていません。[cyan].codex/prompts/[/cyan]内のプロンプトファイルに追加のプロジェクト指示を直接指定する必要があるかもしれません。

詳細情報: [cyan]https://github.com/openai/codex/issues/2890[/cyan]"""
        
        warning_panel = Panel(warning_text, title="Codexでのスラッシュコマンド", border_style="yellow", padding=(1,2))
        console.print()
        console.print(warning_panel)

@app.command()
def check():
    """必要なツールがすべてインストールされているか確認。"""
    show_banner()
    console.print("[bold]インストールされているツールを確認中...[/bold]\n")

    tracker = StepTracker("利用可能なツールの確認")
    
    tracker.add("git", "Gitバージョン管理")
    tracker.add("claude", "Claude Code CLI")
    tracker.add("gemini", "Gemini CLI")
    tracker.add("qwen", "Qwen Code CLI")
    tracker.add("code", "Visual Studio Code")
    tracker.add("code-insiders", "Visual Studio Code Insiders")
    tracker.add("cursor-agent", "Cursor IDEエージェント")
    tracker.add("windsurf", "Windsurf IDE")
    tracker.add("kilocode", "Kilo Code IDE")
    tracker.add("opencode", "opencode")
    tracker.add("codex", "Codex CLI")
    tracker.add("auggie", "Auggie CLI")
    
    git_ok = check_tool_for_tracker("git", tracker)
    claude_ok = check_tool_for_tracker("claude", tracker)  
    gemini_ok = check_tool_for_tracker("gemini", tracker)
    qwen_ok = check_tool_for_tracker("qwen", tracker)
    code_ok = check_tool_for_tracker("code", tracker)
    code_insiders_ok = check_tool_for_tracker("code-insiders", tracker)
    cursor_ok = check_tool_for_tracker("cursor-agent", tracker)
    windsurf_ok = check_tool_for_tracker("windsurf", tracker)
    kilocode_ok = check_tool_for_tracker("kilocode", tracker)
    opencode_ok = check_tool_for_tracker("opencode", tracker)
    codex_ok = check_tool_for_tracker("codex", tracker)
    auggie_ok = check_tool_for_tracker("auggie", tracker)

    console.print(tracker.render())

    console.print("\n[bold green]Specify CLIは使用可能です！[/bold green]")

    if not git_ok:
        console.print("[dim]ヒント: リポジトリ管理のためにgitをインストールしてください[/dim]")
    if not (claude_ok or gemini_ok or cursor_ok or qwen_ok or windsurf_ok or kilocode_ok or opencode_ok or codex_ok or auggie_ok):
        console.print("[dim]ヒント: 最適な体験のためにAIアシスタントをインストールしてください[/dim]")


def main():
    app()


if __name__ == "__main__":
    main()
