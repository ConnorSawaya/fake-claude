#!/bin/sh
# Link fake-claude and fakeclaude into ~/.local/bin (or $BIN) so they run from anywhere.
# They stay links into this folder, so a `git pull` here updates them.
set -e
here=$(cd "$(dirname "$0")" && pwd)
bin=${BIN:-$HOME/.local/bin}
mkdir -p "$bin"
for f in fake-claude fakeclaude; do
  chmod +x "$here/$f"
  ln -sf "$here/$f" "$bin/$f"
  echo "linked $bin/$f -> $here/$f"
done
case ":$PATH:" in
  *":$bin:"*) ;;
  *) echo "note: $bin isn't on your PATH. Add this to ~/.zshrc:  export PATH=\"$bin:\$PATH\"" ;;
esac
if [ ! -d /Applications/Ghostty.app ] && [ ! -d "$HOME/Applications/Ghostty.app" ]; then
  echo "note: the grid needs Ghostty 1.3 or later:  brew install --cask ghostty"
fi
