# dotfiles

macOS 向けの個人用開発環境をセットアップする dotfiles です。

`install.sh` を実行すると、Homebrew パッケージの導入、Node.js・Java・Rust 環境の準備、各種設定ファイルのシンボリックリンク作成をまとめて行います。

## 対象環境

- macOS（Homebrew のパスは Apple Silicon Mac の `/opt/homebrew` を前提）
- zsh
- Git と Homebrew を導入済みであること

## インストール方法

新しい Mac では、先に Xcode Command Line Tools と Homebrew を導入します。

```sh
xcode-select --install
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

その後、このリポジトリを取得してセットアップを実行します。

```sh
git clone git@github.com:tetsugo02/dotfiles.git ~/dotfiles
cd ~/dotfiles
./install.sh
```

GitHub の SSH 鍵をまだ用意していない場合は HTTPS で clone し、必要に応じて後から remote URL を変更してください。

## セットアップ全体の流れ

`install.sh` は次の順番で処理します。

1. このリポジトリ内の設定ファイルをホームディレクトリへシンボリックリンクする
2. `Brewfile` に記載された CLI、開発環境、フォントを Homebrew で導入する
3. mise 経由で Node.js、npm、pnpm、Java の環境を準備する
4. rustup が既に存在する場合、Rust の stable toolchain を導入して既定にする

リンク先に既存のファイルやリンクがある場合は、上書きせずに `元の名前.backup.YYYYMMDDhhmmss` へ移動します。同じリンクが既に作成済みの場合は何もしないため、`install.sh` は再実行できます。

Homebrew が未導入の場合、Homebrew 部分は案内を表示してスキップします。mise は Homebrew から導入します。rustup 自体は自動導入しません。

## 言語・ランタイム環境

| 言語・環境 | バージョン／方式 | セットアップ内容 |
| --- | --- | --- |
| Node.js | 24.18.0 / mise | mise のグローバル既定として導入 |
| npm | Node.js 24.18.0 同梱版 | Node.js と一緒に mise 管理下へ導入。npm 単体の直接インストールはしない |
| pnpm | 11.15.0 / mise | mise のグローバル既定として導入 |
| Python | 3.14 / Homebrew | `python@3.14` を導入 |
| Java | Temurin 25.0.3 LTS / mise | mise のグローバル既定として導入し、`JAVA_HOME` を自動設定 |
| Rust | stable / rustup | rustup が既に導入済みの場合のみ toolchain を導入し、既定に設定 |

Node.js、npm、pnpm、Java は mise の環境から利用します。mise の shell activation により、Java の切り替え時には `JAVA_HOME` も更新されます。Homebrew 版 Node.js や Java は導入しません。

Rust も新しい Mac へ完全自動では導入されません。必要な場合は先に [rustup](https://rustup.rs/) を導入し、もう一度 `./install.sh` を実行してください。

## Homebrew で導入する環境とツール

### 基本 CLI

| ツール | 用途 |
| --- | --- |
| `git` | バージョン管理 |
| `gh` | GitHub CLI |
| `gnupg` | 署名・暗号化 |
| `ripgrep` | 高速なテキスト検索 |
| `tree` | ディレクトリ構造の表示 |
| `starship` | シェルプロンプト |
| `zsh-autocomplete` | zsh の入力補完 |
| `alacritty` | GPU を利用するターミナルエミュレータ |
| `zellij` | ターミナルワークスペース／マルチプレクサ |

### メディア・文書・開発支援

| ツール | 用途 |
| --- | --- |
| `ffmpeg` | 音声・動画処理 |
| `imagemagick` | 画像処理 |
| `mole` | プロジェクト固有の CLI |
| `repomix` | リポジトリ内容の集約 |
| `codex` | Codex CLI／アプリ |

### フォント

- Noto Sans CJK JP
- Noto Serif CJK JP
- Roboto Mono Nerd Font

## 配置される設定

| リポジトリ内のファイル | リンク先 | 内容 |
| --- | --- | --- |
| `config/zsh/zshrc` | `~/.zshrc` | 補完、Starship、mise、PATH、alias、秘密情報の読み込み |
| `config/zsh/zprofile` | `~/.zprofile` | Homebrew の shell environment |
| `config/zsh/zshenv` | `~/.zshenv` | Cargo 環境の読み込み |
| `config/zsh/profile` | `~/.profile` | ローカル CLI と Cargo 環境の読み込み |
| `config/starship/starship.toml` | `~/.config/starship.toml` | Starship の表示設定 |
| `config/alacritty/alacritty.toml` | `~/.config/alacritty/alacritty.toml` | Alacritty の表示、フォント、キー操作設定 |
| `config/alacritty/themes/ayu_mirage.toml` | `~/.config/alacritty/themes/ayu_mirage.toml` | Alacritty の Ayu Mirage カラーテーマ |
| `config/zellij/config.kdl` | `~/.config/zellij/config.kdl` | Zellij のモードとキーバインド |
| `config/opencode/opencode.json` | `~/.config/opencode/opencode.json` | LiteLLM プロバイダーとモデル設定 |
| `config/git/gitconfig` | `~/.gitconfig` | Git のユーザー名とメールアドレス |
| `config/ssh/config` | `~/.ssh/config` | SSH ホスト、鍵、ProxyJump などの接続設定 |

zsh では `ls --color` と、接続先へ `TERM=xterm-256color` を渡す `ssh` alias も設定します。

## PATH だけを設定する外部環境

以下は `install.sh` や `Brewfile` ではインストールせず、対象が既に存在する場合だけ利用できるようにする設定です。ディレクトリまたは設定ファイルが存在しなければ何も変更しないため、未導入の環境でもエラーにはなりません。

| 対象 | 設定 | 現在の自動セットアップに必要か | 残している理由 |
| --- | --- | --- | --- |
| uv などのローカル CLI | `~/.local/bin/env` があれば読み込む | 不要 | uv の standalone installer などが作成する環境設定を利用するため。uv 自体はこのリポジトリでは導入しない |
| Pixi | `~/.pixi/bin` を PATH に追加 | 不要 | Pixi を別途導入したマシンでコマンドを利用するため |
| 個人用 CLI | `~/my_cli` を PATH に追加 | 不要 | 自作スクリプトや個人用コマンドを直接実行するため |
| Antigravity | `~/.antigravity/antigravity/bin` を PATH に追加 | 不要 | Antigravity を別途導入した場合に実行ファイルを利用するため |
| opencode | `~/.opencode/bin` を PATH に追加 | opencode を使わない場合は不要 | opencode の独自インストーラーで配置された実行ファイルを利用するため。設定ファイルだけはこのリポジトリから配置する |
| Cargo | `~/.cargo/env` があれば読み込む | Rust を使う場合は必要 | rustup が設定する Cargo と Rust toolchain の PATH を有効化するため |

したがって、現在の自動インストールだけに絞れば uv、Pixi、個人用 CLI、Antigravity、opencode の PATH 設定は必須ではありません。一方、存在確認付きで副作用が小さく、別の方法で導入済みのツールを複数の Mac でそのまま利用できるため、互換用の設定として残しています。今後これらを使わないことが確定した場合は、対応する行を `config/zsh/zshrc` または `config/zsh/profile` から削除できます。

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
- 必要に応じて Homebrew ディレクトリの所有者を確認する

```sh
sudo chown -R "$USER":admin /opt/homebrew
```

## 設定変更後の反映

dotfiles 内のリンク済みファイルを変更した場合は、その内容がリンク先にも反映されます。zsh の設定は新しいシェルを開くか、次のコマンドで読み直します。

```sh
source ~/.zshrc
```
