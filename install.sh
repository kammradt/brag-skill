#!/bin/bash
set -e

SKILL_DIR="$HOME/.claude/skills/brag"
REPO_URL="https://raw.githubusercontent.com/kammradt/brag-skill/main/SKILL.md"
CLONE_DIR="$HOME/repos/brag-skill"

# ─── Dev mode (symlink) ────────────────────────────────────────────────
if [[ "$1" == "--dev" ]]; then
  REPO_ROOT=""

  # Are we inside a clone of brag-skill already?
  if git -C "$(pwd)" remote get-url origin 2>/dev/null | grep -q "brag-skill"; then
    REPO_ROOT="$(git -C "$(pwd)" rev-parse --show-toplevel)"
    echo "Detected repo at $REPO_ROOT"
  else
    # Clone to ~/repos/brag-skill if not already there
    if [[ -d "$CLONE_DIR/.git" ]]; then
      echo "Repo already exists at $CLONE_DIR"
      REPO_ROOT="$CLONE_DIR"
    else
      echo "Cloning brag-skill to $CLONE_DIR..."
      mkdir -p "$(dirname "$CLONE_DIR")"
      git clone git@github.com:kammradt/brag-skill.git "$CLONE_DIR"
      REPO_ROOT="$CLONE_DIR"
    fi
  fi

  # Back up existing skill dir if it's a real directory (not a symlink)
  if [[ -d "$SKILL_DIR" && ! -L "$SKILL_DIR" ]]; then
    BACKUP="$SKILL_DIR.backup.$(date +%s)"
    echo "Backing up existing $SKILL_DIR to $BACKUP"
    mv "$SKILL_DIR" "$BACKUP"
  fi

  # Remove existing symlink if present
  if [[ -L "$SKILL_DIR" ]]; then
    rm "$SKILL_DIR"
  fi

  # Create parent dir and symlink
  mkdir -p "$(dirname "$SKILL_DIR")"
  ln -s "$REPO_ROOT" "$SKILL_DIR"
  echo "Done! Symlinked $SKILL_DIR -> $REPO_ROOT"
  echo "Edits to the repo are immediately reflected in Claude Code."
  exit 0
fi

# ─── Consumer mode (download) ──────────────────────────────────────────
echo "Installing /brag skill for Claude Code..."

mkdir -p "$SKILL_DIR"

if command -v curl &> /dev/null; then
  curl -sSL "$REPO_URL" -o "$SKILL_DIR/SKILL.md"
elif command -v wget &> /dev/null; then
  wget -q "$REPO_URL" -O "$SKILL_DIR/SKILL.md"
else
  echo "Error: curl or wget is required to install."
  exit 1
fi

echo "Done! /brag is now available in Claude Code."
echo "Try it: /brag last_week"
