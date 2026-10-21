# martok-dots
Chancellors use vim

## Install

```sh
git clone https://github.com/chancellor-martok/martok-dots.git
cd martok-dots && ./install.sh
```

`install.sh` is idempotent. It:

- installs missing dependencies (zsh, git, curl, ripgrep, tmux, Node.js, Neovim >= 0.11) via apt (Neovim from GitHub releases), apk (Alpine), or Homebrew (macOS)
- installs Oh My Zsh to `~/.oh-my-zsh` if absent
- symlinks `.zshrc`, `.zsh-custom` (custom `agnoster` theme), `.tmux.conf`, and `.config/nvim` into `$HOME`, backing up existing files to `~/.dotfiles-backup/`
- on Linux, sets zsh as the login shell when sudo is available
- installs tmux plugins (via TPM) and Neovim plugins (from `lazy-lock.json`)

Set `NVIM_VERSION` (e.g. `v0.12.5`) to pin the Neovim release on Linux.

## Codespaces

In [Codespaces settings](https://github.com/settings/codespaces), enable **Automatically install dotfiles** and select this repo. It applies to newly created codespaces only.

### tmux sessions

Codespaces stop after the idle timeout, which ends all processes, including tmux. [tmux-resurrect](https://github.com/tmux-plugins/tmux-resurrect) and [tmux-continuum](https://github.com/tmux-plugins/tmux-continuum) save sessions, windows, panes, working directories, and pane contents every 15 minutes, and restore them when tmux starts. Running commands are not resumed. In Codespaces, saves go to `/workspaces/.tmux-resurrect` so they also survive rebuilds. Save manually with `prefix + Ctrl-s`.

Interactive terminal logins in a codespace (e.g. `gh codespace ssh`) automatically attach to the `main` tmux session. VS Code's integrated terminal is excluded; set `NO_TMUX=1` to skip.

The `agnoster` theme needs a Powerline/Nerd Font in your local terminal or VS Code (`terminal.integrated.fontFamily`).
