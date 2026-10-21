#!/usr/bin/env bash
# Installs these dotfiles. Run automatically by GitHub Codespaces; safe to rerun locally.
set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKUP_DIR="$HOME/.dotfiles-backup/$(date +%Y%m%d%H%M%S)"
NVIM_VERSION="${NVIM_VERSION:-stable}"
OS="$(uname -s)"
export PATH="$HOME/.local/bin:$PATH"

log() { printf '==> %s\n' "$*"; }
warn() { printf 'warning: %s\n' "$*" >&2; }
have() { command -v "$1" >/dev/null 2>&1; }

SUDO=""
CAN_ROOT=false
if [ "$(id -u)" -eq 0 ]; then
  CAN_ROOT=true
elif have sudo && sudo -n true 2>/dev/null; then
  SUDO="sudo"
  CAN_ROOT=true
fi

nvim_is_recent() {
  have nvim || return 1
  local version major minor
  version="$(nvim --version 2>/dev/null | head -n1)" || return 1
  [[ "$version" =~ ^NVIM\ v([0-9]+)\.([0-9]+) ]] || return 1
  major="${BASH_REMATCH[1]}"
  minor="${BASH_REMATCH[2]}"
  [ "$major" -gt 0 ] || [ "$minor" -ge 11 ]
}

is_musl() {
  [ -f /etc/alpine-release ] || { have ldd && ldd --version 2>&1 | grep -qi musl; }
}

# Remove a previously downloaded Neovim that can't run here (e.g. glibc build on musl).
remove_broken_local_nvim() {
  local bin="$HOME/.local/bin/nvim"
  if [ -L "$bin" ] && ! "$bin" --version >/dev/null 2>&1; then
    log "Removing non-working Neovim at $bin"
    rm -f "$bin"
    rm -rf "$HOME/.local/opt/nvim"
  fi
}

# Some base images ship a ~/.zprofile that sources a missing ~/.profile.
ensure_profile() {
  if [ -f "$HOME/.zprofile" ] && [ ! -e "$HOME/.profile" ] \
    && grep -q '\.profile' "$HOME/.zprofile"; then
    log "Creating empty ~/.profile (sourced by ~/.zprofile)"
    touch "$HOME/.profile"
  fi
}

node_available() {
  have node || [ -s "${NVM_DIR:-$HOME/.nvm}/nvm.sh" ]
}

install_packages() {
  local pkgs=()
  if [ "$OS" = "Linux" ] && have apt-get; then
    have zsh || pkgs+=(zsh)
    have git || pkgs+=(git)
    have curl || pkgs+=(curl)
    have rg || pkgs+=(ripgrep)
    have tmux || pkgs+=(tmux)
    node_available || pkgs+=(nodejs npm)
    [ "${#pkgs[@]}" -eq 0 ] && return
    if ! $CAN_ROOT; then
      warn "cannot install ${pkgs[*]} without root/sudo; install them manually"
      return
    fi
    log "Installing ${pkgs[*]}"
    $SUDO apt-get update -qq
    $SUDO env DEBIAN_FRONTEND=noninteractive apt-get install -y -qq --no-install-recommends "${pkgs[@]}"
  elif [ "$OS" = "Linux" ] && have apk; then
    have zsh || pkgs+=(zsh)
    have git || pkgs+=(git)
    have curl || pkgs+=(curl)
    have rg || pkgs+=(ripgrep)
    have tmux || pkgs+=(tmux)
    node_available || pkgs+=(nodejs npm)
    nvim_is_recent || pkgs+=(neovim)
    [ "${#pkgs[@]}" -eq 0 ] && return
    if ! $CAN_ROOT; then
      warn "cannot install ${pkgs[*]} without root/sudo; install them manually"
      return
    fi
    log "Installing ${pkgs[*]}"
    $SUDO apk add --no-cache --quiet "${pkgs[@]}"
  elif [ "$OS" = "Darwin" ] && have brew; then
    have rg || pkgs+=(ripgrep)
    have tmux || pkgs+=(tmux)
    node_available || pkgs+=(node)
    nvim_is_recent || pkgs+=(neovim)
    [ "${#pkgs[@]}" -eq 0 ] && return
    log "Installing ${pkgs[*]}"
    brew install "${pkgs[@]}"
  else
    warn "unsupported package manager; ensure zsh, git, curl, ripgrep, tmux, node, and neovim >= 0.11 are installed"
  fi
}

install_neovim_linux() {
  nvim_is_recent && return
  if is_musl; then
    warn "Neovim >= 0.11 not available; GitHub release builds need glibc, so install it with your package manager"
    return
  fi
  local arch
  case "$(uname -m)" in
    x86_64 | amd64) arch="x86_64" ;;
    aarch64 | arm64) arch="arm64" ;;
    *) warn "no Neovim release for $(uname -m); install Neovim >= 0.11 manually"; return ;;
  esac
  local url="https://github.com/neovim/neovim/releases/download/${NVIM_VERSION}/nvim-linux-${arch}.tar.gz"
  local dest="$HOME/.local/opt/nvim"
  log "Installing Neovim (${NVIM_VERSION}) to $dest"
  rm -rf "$dest"
  mkdir -p "$dest" "$HOME/.local/bin"
  curl -fsSL "$url" | tar -xz -C "$dest" --strip-components=1
  ln -sfn "$dest/bin/nvim" "$HOME/.local/bin/nvim"
}

install_oh_my_zsh() {
  if [ -d "$HOME/.oh-my-zsh" ]; then
    return
  fi
  log "Installing Oh My Zsh"
  git clone --quiet --depth=1 https://github.com/ohmyzsh/ohmyzsh.git "$HOME/.oh-my-zsh"
}

link() {
  local src="$DOTFILES_DIR/$1" dest="$HOME/$1"
  if [ -L "$dest" ] && [ "$(readlink "$dest")" = "$src" ]; then
    return
  fi
  if [ -e "$dest" ] || [ -L "$dest" ]; then
    mkdir -p "$BACKUP_DIR/$(dirname "$1")"
    mv "$dest" "$BACKUP_DIR/$1"
    log "Backed up existing $dest to $BACKUP_DIR/$1"
  fi
  mkdir -p "$(dirname "$dest")"
  ln -s "$src" "$dest"
  log "Linked $dest"
}

set_default_shell() {
  [ "$OS" = "Linux" ] || return 0
  local zsh_path user
  zsh_path="$(command -v zsh || true)"
  user="$(id -un)"
  [ -n "$zsh_path" ] || return 0
  [ "$(getent passwd "$user" | cut -d: -f7)" = "$zsh_path" ] && return 0
  if $CAN_ROOT; then
    log "Setting default shell to $zsh_path"
    $SUDO chsh -s "$zsh_path" "$user" || warn "could not change default shell"
  else
    warn "cannot change default shell without root/sudo; run: chsh -s $zsh_path"
  fi
}

install_tmux_plugins() {
  have tmux || { warn "tmux not found; skipping tmux plugin install"; return; }
  local tpm="$HOME/.tmux/plugins/tpm"
  if [ ! -d "$tpm" ]; then
    log "Installing tmux plugin manager"
    git clone --quiet --depth=1 https://github.com/tmux-plugins/tpm "$tpm"
  fi
  log "Installing tmux plugins"
  "$tpm/bin/install_plugins" >/dev/null 2>&1 \
    || warn "tmux plugin install reported errors; press prefix + I inside tmux"
}

install_nvim_plugins() {
  have nvim || { warn "nvim not found; skipping plugin install"; return; }
  log "Installing Neovim plugins"
  nvim --headless "+Lazy! restore" +qa >/dev/null 2>&1 \
    || warn "Neovim plugin install reported errors; open nvim and run :Lazy"
}

remove_broken_local_nvim
install_packages
[ "$OS" = "Linux" ] && install_neovim_linux
install_oh_my_zsh
ensure_profile
link .zshrc
link .zsh-custom
link .config/nvim
link .tmux.conf
set_default_shell
install_tmux_plugins
install_nvim_plugins
log "Done"
