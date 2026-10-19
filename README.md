# martok-dots
Chancellors use vim

## Install

```sh
git clone https://github.com/chancellor-martok/martok-dots.git
cd martok-dots && ./install.sh
```

`install.sh` is idempotent. It:

- installs missing dependencies (zsh, git, curl, ripgrep, Node.js, Neovim >= 0.11) via apt (Neovim from GitHub releases), apk (Alpine), or Homebrew (macOS)
- installs Oh My Zsh to `~/.oh-my-zsh` if absent
- symlinks `.zshrc`, `.zsh-custom` (custom `agnoster` theme), and `.config/nvim` into `$HOME`, backing up existing files to `~/.dotfiles-backup/`
- on Linux, sets zsh as the login shell when sudo is available
- installs Neovim plugins from `lazy-lock.json`

Set `NVIM_VERSION` (e.g. `v0.12.5`) to pin the Neovim release on Linux.

## Codespaces

In [Codespaces settings](https://github.com/settings/codespaces), enable **Automatically install dotfiles** and select this repo. It applies to newly created codespaces only.

The `agnoster` theme needs a Powerline/Nerd Font in your local terminal or VS Code (`terminal.integrated.fontFamily`).
