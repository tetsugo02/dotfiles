# dotfiles

macOS と Linux（Ubuntu）向けの個人用開発環境をセットアップする dotfiles です。

`install.sh` を実行すると，パッケージの導入（macOS は Homebrew，Ubuntu は apt を中心に利用），選択した言語ランタイムの準備，各種設定ファイルのシンボリックリンク作成をまとめて行います．

## 対象環境

- macOS（Homebrew のパスは Apple Silicon Mac の `/opt/homebrew` を前提）または Ubuntu（apt が使えること）
- zsh（Ubuntu では `install.sh` が zsh を導入し、既定シェルに切り替えます）
- Git を導入済みであること（macOS は追加で Homebrew、Ubuntu は `sudo` が使えること）

## インストール方法

### macOS

新しい Mac では、先に Xcode Command Line Tools と Homebrew を導入します。

```sh
xcode-select --install
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

### Ubuntu

Git と `sudo` が使えれば追加の準備は不要です。zsh はまだ入れていなくても構いません（`install.sh` が導入し、既定シェルに切り替えます）。

### 共通

このリポジトリを取得してセットアップを実行します。

```sh
git clone git@github.com:tetsugo02/dotfiles.git ~/dotfiles
cd ~/dotfiles
./install.sh
```

GitHub の SSH 鍵をまだ用意していない場合は HTTPS で clone し、必要に応じて後から remote URL を変更してください。

実行時にまず macOS / Linux のどちらを対象にするか、続けて Alacritty と Ghostty のどちらを導入するかを選択します。入力を受け付けない環境（CI など）では、次のように環境変数で指定してください。

```sh
DOTFILES_OS=linux DOTFILES_TERMINAL=ghostty DOTFILES_RUNTIMES=node,python ./install.sh
```

`DOTFILES_OS` は `macos` か `linux`、`DOTFILES_TERMINAL` は `alacritty` か `ghostty` を指定できます。非対話シェルで `DOTFILES_OS` を省略した場合は `uname -s` から自動判定します。選択したターミナルの設定だけをリンクし，既存のアプリや他方の設定は削除しません．Ghostty を選んだ場合，`ghostty@tip`（macOS）が既に入っていれば競合する通常版のインストールを省きます。

## セットアップ全体の流れ

`install.sh` は次の順番で処理します。

1. macOS と Linux (Ubuntu) のどちらを対象にするか選択する
2. Alacritty と Ghostty のどちらを導入するか選択する
3. チェックボックス形式で言語ランタイムを選択する
4. このリポジトリ内の設定ファイルをホームディレクトリへリンクし，Codex／Claude Code の共通指示を反映する
5. macOS は `Brewfile` の CLI，フォント，Orca を導入する．Ubuntu は apt パッケージ，GitHub CLI，Nerd Font，zsh-autocomplete，starship，Orca を導入し，zsh を既定シェルにする
6. 選択したターミナルを導入する（macOS は Homebrew cask，Ubuntu は apt）
7. 選択したランタイムに必要な管理ツールとランタイムを導入する
8. Rust を選択し，rustup が既に存在する場合は stable toolchain を導入して既定にする
9. codex，Claude Code，herdr をそれぞれの公式 curl インストーラーで導入する（macOS / Ubuntu 共通）

リンク先に既存のファイルやリンクがある場合は、上書きせずに `元の名前.backup.YYYYMMDDhhmmss` へ移動します。同じリンクが既に作成済みの場合は何もしないため、`install.sh` は再実行できます。

macOS で Homebrew が未導入の場合、Homebrew 部分は案内を表示してスキップします。rustup 自体は自動導入しません。

## 言語・ランタイム環境

対話セットアップでは，番号 `1`〜`4` を入力して Enter を押すとチェックが切り替わります．`a` ですべて選択，`n` ですべて解除，空の入力で Enter を押すと確定，`q` でセットアップを中止します．初期選択は Node.js と Python で，Java（JVM）と Rust は未選択です．

```text
1) [x] Node.js + npm + pnpm
2) [x] Python
3) [ ] Java (JVM)
4) [ ] Rust stable (requires rustup)
```

非対話実行では `DOTFILES_RUNTIMES` の指定が必須です．`node`，`python`，`java`，`rust` をカンマで区切るか，`all`／`none` を指定します．空文字列や不正な値はエラーになります．対話実行でもこの変数を指定すると選択画面を省略できます．

```sh
# Node.js と Python のみ
DOTFILES_OS=macos DOTFILES_TERMINAL=ghostty DOTFILES_RUNTIMES=node,python ./install.sh
# Java のみ
DOTFILES_OS=linux DOTFILES_TERMINAL=alacritty DOTFILES_RUNTIMES=java ./install.sh
# ランタイムを導入しない
DOTFILES_OS=linux DOTFILES_TERMINAL=ghostty DOTFILES_RUNTIMES=none ./install.sh
```

未選択のランタイムはインストール・更新しません．既存のランタイムやグローバル設定は削除しません．mise は Node.js または Java を選択した場合のみ，Ubuntu の uv は Python を選択した場合のみ導入します．`Brewfile` 単体では言語ランタイムを導入しません．

| 言語・環境 | バージョン／方式 | セットアップ内容 |
| --- | --- | --- |
| Node.js | 24.18.0 / mise | 選択時に npm・pnpm とともにグローバル既定として導入 |
| npm | Node.js 24.18.0 同梱版 | Node.js と一緒に mise 管理下へ導入。npm 単体の直接インストールはしない |
| pnpm | 11.15.0 / mise | Node.js 選択時にグローバル既定として導入 |
| Python | macOS: 3.14 / Homebrew，Ubuntu: 3.14 / uv | 選択時のみ導入．Ubuntu では uv も必要に応じて導入 |
| Java | Temurin 25.0.3 LTS / mise | 選択時のみグローバル既定として導入し，`JAVA_HOME` を自動設定 |
| Rust | stable / rustup | 選択し，rustup が既に導入済みの場合のみ toolchain を導入し，既定に設定 |

Node.js、npm、pnpm、Java は mise の環境から利用します。mise の shell activation により、Java の切り替え時には `JAVA_HOME` も更新されます。Homebrew 版 Node.js や Java は導入しません。

rustup 自体は自動導入しません．Rust が必要な場合は先に [rustup](https://rustup.rs/) を導入し，`./install.sh` で Rust を選択してください．

codex・Claude Code・herdr は、公式ドキュメントが一番に案内している curl インストーラー（`chatgpt.com/codex/install.sh`、`claude.ai/install.sh`、`herdr.dev/install.sh`）で、macOS / Ubuntu 共通に導入します。いずれもパッケージマネージャーを介さず自己更新するため、Homebrew や npm では管理しません。herdr のキーバインドなどをカスタマイズしたい場合は `herdr --default-config > ~/.config/herdr/config.toml` でデフォルト設定を書き出して編集してください（このリポジトリでは既定設定のまま使う前提で、設定ファイルは管理していません）。

## 導入するツール（OS 別）

### 基本 CLI

| ツール | 用途 | macOS | Ubuntu |
| --- | --- | --- | --- |
| `zsh` | シェル本体 | OS 標準 | apt で導入し既定シェルに切り替え |
| `git` | バージョン管理 | Homebrew | apt |
| `gh` | GitHub CLI | Homebrew | 公式 apt リポジトリ（cli.github.com） |
| `gnupg` | 署名・暗号化 | Homebrew | apt |
| `ripgrep` | 高速なテキスト検索 | Homebrew | apt |
| `tree` | ディレクトリ構造の表示 | Homebrew | apt |
| `starship` | シェルプロンプト | Homebrew | 公式インストーラー（starship.rs/install.sh） |
| `zsh-autocomplete` | zsh の入力補完 | Homebrew | `~/.zsh-autocomplete` へ git clone |

### 選択するターミナル

| ツール | macOS | Ubuntu |
| --- | --- | --- |
| `alacritty` | セットアップで選択した場合に Homebrew cask を導入 | セットアップで選択した場合に apt で導入（`universe` リポジトリが必要な場合あり） |
| `ghostty` | セットアップで選択した場合に Homebrew cask を導入．`ghostty@tip` が既にあればそのまま利用 | セットアップで選択した場合に apt で導入（Ubuntu 26.04 未満では `universe` の有効化や PPA が必要な場合あり） |

### メディア・文書・開発支援

| ツール | 用途 | macOS | Ubuntu |
| --- | --- | --- | --- |
| `ffmpeg` | 音声・動画処理 | Homebrew | apt |
| `imagemagick` | 画像処理 | Homebrew | apt |
| `mole` | Mac クリーンアップ用 CLI | Homebrew | 非対応（macOS 専用ツールのため） |

### AI コーディングエージェント CLI

公式が一番に案内している curl インストーラーを使い、macOS / Ubuntu で同じ方法で導入します（パッケージマネージャー経由にすると自己更新の仕組みと競合するため）。

| ツール | 用途 | 導入方法（共通） |
| --- | --- | --- |
| `codex` | Codex CLI | `curl -fsSL https://chatgpt.com/codex/install.sh \| sh` |
| `claude` (Claude Code) | Claude Code CLI | `curl -fsSL https://claude.ai/install.sh \| bash` |
| `herdr` | ターミナルマルチプレクサ（旧 zellij の代替） | `curl -fsSL https://herdr.dev/install.sh \| sh` |

### Orca

[Orca](https://www.onorca.dev/) は，複数のコーディングエージェントを並行して動かすデスクトップ開発環境です．[公式インストール手順](https://www.onorca.dev/docs/install)に従い，次の方法で導入します．

| OS | 導入方法 |
| --- | --- |
| macOS | `Brewfile` の `stablyai/orca/orca` cask を Homebrew で導入 |
| Ubuntu | 公式 GitHub Releases の `.deb` を取得し，`sudo apt-get install -y` で依存関係とともに導入 |

macOS で Orca だけを導入する場合は，次を実行します．

```sh
brew install --cask stablyai/orca/orca
```

Ubuntu は `install.sh` の `install_orca_linux` が amd64／arm64 を自動判定します．導入バージョンは `ORCA_VERSION`（現在 `1.4.240`）で固定し，導入済みの場合はスキップします．その他のアーキテクチャでは案内を表示してスキップします．GNOME のスクリーンリーダーとの名前の競合を避けるため，Linux 版の起動コマンドは `orca-ide` です．

Ubuntu の更新はアプリ内の更新案内に従ってパッケージを導入します．dotfiles で新規導入する版を更新する場合は，`install.sh` の `ORCA_VERSION` も更新してください．macOS では `brew upgrade --cask orca` で更新できます．

### フォント

- Noto Sans CJK JP
- Noto Serif CJK JP
- Roboto Mono Nerd Font

macOS は Homebrew cask（`font-noto-sans-cjk-jp` など）で導入します。Ubuntu では Noto CJK を apt パッケージ（`fonts-noto-cjk` / `fonts-noto-cjk-extra`）で、Roboto Mono Nerd Font を GitHub リリースから取得して `~/.local/share/fonts` に展開し、`fc-cache` でキャッシュを更新します。

## 配置される設定

| リポジトリ内のファイル | リンク先 | 内容 |
| --- | --- | --- |
| `config/zsh/zshrc` | `~/.zshrc` | 補完、Starship、mise、PATH、alias、秘密情報の読み込み |
| `config/zsh/zprofile` | `~/.zprofile` | Homebrew の shell environment（Homebrew が無い環境では何もしない） |
| `config/zsh/zshenv` | `~/.zshenv` | Cargo 環境の読み込み |
| `config/zsh/profile` | `~/.profile` | ローカル CLI と Cargo 環境の読み込み |
| `config/starship/starship.toml` | `~/.config/starship.toml` | Starship の表示設定 |
| `config/alacritty/alacritty.toml` | `~/.config/alacritty/alacritty.toml` | Alacritty の表示、フォント、キー操作設定 |
| `config/alacritty/themes/ayu_mirage.toml` | `~/.config/alacritty/themes/ayu_mirage.toml` | Alacritty の Ayu Mirage カラーテーマ |
| `config/ghostty/config` | `~/.config/ghostty/config` | Ghostty のフォント，Ayu Mirage 配色，初期サイズ，カーソル，キー操作設定 |
| `config/opencode/opencode.json` | `~/.config/opencode/opencode.json` | LiteLLM プロバイダーとモデル設定 |
| `config/git/gitconfig` | `~/.gitconfig` | Git のユーザー名とメールアドレス |
| `config/ssh/config` | `~/.ssh/config` | SSH ホスト、鍵、ProxyJump などの接続設定 |

zsh では `ls --color` と、接続先へ `TERM=xterm-256color` を渡す `ssh` alias も設定します。

Alacritty と Ghostty の設定は，選択した方だけをリンクします．Ghostty のスクロールバックはバイト単位のため，Alacritty の10万行と同じ行数にはなりません．

herdr（ターミナルマルチプレクサ）は設定ファイルを管理せず、既定のキーバインドのまま利用する前提です。

## PATH だけを設定する外部環境

以下は `install.sh` や `Brewfile` ではインストールせず、対象が既に存在する場合だけ利用できるようにする設定です。ディレクトリまたは設定ファイルが存在しなければ何も変更しないため、未導入の環境でもエラーにはなりません。

| 対象 | 設定 | 現在の自動セットアップに必要か | 残している理由 |
| --- | --- | --- | --- |
| uv などのローカル CLI | `~/.local/bin/env` があれば読み込む | Ubuntu で Python を選択した場合に必要（uv は install.sh が導入する） | uv の standalone installer が作成する環境設定を利用するため |
| Pixi | `~/.pixi/bin` を PATH に追加 | 不要 | Pixi を別途導入したマシンでコマンドを利用するため |
| 個人用 CLI | `~/my_cli` を PATH に追加 | 不要 | 自作スクリプトや個人用コマンドを直接実行するため |
| Antigravity | `~/.antigravity/antigravity/bin` を PATH に追加 | 不要 | Antigravity を別途導入した場合に実行ファイルを利用するため |
| opencode | `~/.opencode/bin` を PATH に追加 | opencode を使わない場合は不要 | opencode の独自インストーラーで配置された実行ファイルを利用するため。設定ファイルだけはこのリポジトリから配置する |
| Cargo | `~/.cargo/env` があれば読み込む | Rust を使う場合は必要 | rustup が設定する Cargo と Rust toolchain の PATH を有効化するため |
| `~/.local/bin` | PATH に追加（zshrc の `path_prepend`） | Ubuntu では必要（uv・starship・mise などの既定インストール先） | 公式インストーラーが配置する実行ファイルを両 OS で共通に使えるようにするため |

したがって、現在の自動インストールだけに絞れば Pixi、個人用 CLI、Antigravity、opencode の PATH 設定は必須ではありません。一方、存在確認付きで副作用が小さく、別の方法で導入済みのツールを複数のマシンでそのまま利用できるため、互換用の設定として残しています。今後これらを使わないことが確定した場合は、対応する行を `config/zsh/zshrc` または `config/zsh/profile` から削除できます。

## 秘密情報

API キーなどの秘密情報は Git で管理しません。サンプルをコピーして、ローカルファイルへ値を設定します。

```sh
mkdir -p ~/.config/zsh
cp config/zsh/secrets.zsh.example ~/.config/zsh/secrets.zsh
```

現在のサンプルには次の環境変数があります。

- `KAGGLE_API_TOKEN`
- `KEIOAIC_LLM_API_KEY`

`~/.config/zsh/secrets.zsh` は `.zshrc` から、ファイルが存在する場合だけ読み込まれます。実際の秘密情報をこのリポジトリへコミットしないでください。

## 手動で必要な作業

- SSH 秘密鍵を `~/.ssh` に作成または移行する
- `gh auth login -h github.com` で GitHub CLI を認証する
- rustup と Rust が必要なら rustup を先に導入する
- App Store や各ベンダーのアプリへログインする
- 必要に応じて Homebrew ディレクトリの所有者を確認する（macOS）

```sh
sudo chown -R "$USER":admin /opt/homebrew
```

- Ubuntu では `install.sh` が `sudo apt-get` と `chsh` を実行するため、パスワード入力を求められることがあります

## 設定変更後の反映

### Codex と Claude Code の共通指示

`config/agents/instructions.md` を共通の指示として管理します．`install.sh` はこの内容を `~/.codex/AGENTS.md` と `~/.claude/CLAUDE.md` に追記します．`CODEX_HOME` または `CLAUDE_CONFIG_DIR` を指定している場合は，そのディレクトリを使用します．

既存の指示は残し，`DOTFILES_AGENT_INSTRUCTIONS_START` / `DOTFILES_AGENT_INSTRUCTIONS_END` のコメントで囲んだ部分だけを再実行時に更新します．ファイルがなければ作成し，変更前の既存ファイルは `.backup.XXXXXXXX` に保存します．区切りが壊れている場合は，そのファイルを変更せずエラーにします．既存の指示と共通指示が重なる場合も，管理範囲外の指示は自動削除しません．

共通指示を変更した後や，パッケージの導入を行わず指示だけを反映する場合は，次を実行します．

```sh
bash scripts/sync-agent-instructions.sh
```

2026-10-26 の確認時点では，グローバルの `~/.codex/AGENTS.md` に CodeGraph の利用方針，日本語の句読点，文書と実装が食い違う場合の方針があり，`~/.claude/CLAUDE.md` は存在しませんでした．この3項目を共通指示の初期内容としています．

### リンク済みの設定

dotfiles 内のリンク済みファイルを変更した場合は、その内容がリンク先にも反映されます。zsh の設定は新しいシェルを開くか、次のコマンドで読み直します。

```sh
source ~/.zshrc
```
