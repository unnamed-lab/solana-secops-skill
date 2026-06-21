#!/bin/bash

# Solana SecOps Skill - Custom Installer
# Interactive: choose personal (~/.claude) or project-local (./.claude) install.

set -e

GREEN='\033[0;32m'; YELLOW='\033[1;33m'
BLUE='\033[0;34m'; MAGENTA='\033[0;35m'; CYAN='\033[0;36m'; WHITE='\033[1;37m'; NC='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SOURCE_DIR="$SCRIPT_DIR/skill"
SKILL_NAME="solana-secops"

print_banner() {
    echo ""
    echo -e "${MAGENTA}+===============================================================+${NC}"
    echo -e "${MAGENTA}|${NC}   ${WHITE}Solana SecOps Skill${NC}  -  Custom Installer                ${MAGENTA}|${NC}"
    echo -e "${MAGENTA}+===============================================================+${NC}"
    echo ""
}

print_help() {
    echo "Solana SecOps Skill - Custom Installer"
    echo ""
    echo "Usage: ./install-custom.sh [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  --personal        Install to ~/.claude (default)"
    echo "  --project         Install to ./.claude (current project)"
    echo "  --path <dir>      Install to <dir>/.claude"
    echo "  -y, --yes         Use defaults, no prompts"
    echo "  -h, --help        Show this help"
    echo ""
}

BASE=""
SKIP_CONFIRM=false
while [[ $# -gt 0 ]]; do
    case $1 in
        --personal) BASE="$HOME/.claude"; shift ;;
        --project)  BASE="$(pwd)/.claude"; shift ;;
        --path)     BASE="$2/.claude"; shift 2 ;;
        -y|--yes)   SKIP_CONFIRM=true; shift ;;
        -h|--help)  print_help; exit 0 ;;
        *) echo "Unknown option: $1"; print_help; exit 1 ;;
    esac
done

print_banner

if [ -z "$BASE" ]; then
    if [ "$SKIP_CONFIRM" = true ]; then
        BASE="$HOME/.claude"
    else
        echo "Where should the skill be installed?"
        echo -e "  ${CYAN}1)${NC} Personal  (~/.claude)  - available across all your projects"
        echo -e "  ${CYAN}2)${NC} Project   (./.claude)  - just this repo"
        read -p "Choose [1/2] (default 1): " -n 1 -r choice
        echo
        case "$choice" in
            2) BASE="$(pwd)/.claude" ;;
            *) BASE="$HOME/.claude" ;;
        esac
    fi
fi

SKILLS_DIR="$BASE/skills"
SKILL_PATH="$SKILLS_DIR/$SKILL_NAME"

echo ""
echo -e "Installing to: ${CYAN}$BASE${NC}"
echo -e "  ${BLUE}*${NC} skill    -> $SKILL_PATH"
echo -e "  ${BLUE}*${NC} agents   -> $BASE/agents"
echo -e "  ${BLUE}*${NC} commands -> $BASE/commands"
echo -e "  ${BLUE}*${NC} rules    -> $BASE/rules"
echo ""

if [ "$SKIP_CONFIRM" = false ]; then
    read -p "Proceed? [Y/n] " -n 1 -r
    echo
    [[ $REPLY =~ ^[Nn]$ ]] && { echo -e "${YELLOW}Cancelled${NC}"; exit 0; }
fi

mkdir -p "$SKILLS_DIR" "$BASE/agents" "$BASE/commands" "$BASE/rules"

rm -rf "$SKILL_PATH"; mkdir -p "$SKILL_PATH"
cp -r "$SOURCE_DIR"/* "$SKILL_PATH/"
cp -r "$SCRIPT_DIR/templates" "$SKILLS_DIR/$SKILL_NAME-templates" 2>/dev/null || true
cp "$SCRIPT_DIR/agents/"*.md   "$BASE/agents/"   2>/dev/null || true
cp "$SCRIPT_DIR/commands/"*.md "$BASE/commands/" 2>/dev/null || true
cp "$SCRIPT_DIR/rules/"*.md    "$BASE/rules/"    2>/dev/null || true

echo ""
echo -e "${GREEN}Done.${NC} Installed solana-secops to ${CYAN}$BASE${NC}"
echo -e "Ask Claude: ${BLUE}\"Run a Day-2 readiness review on my program\"${NC}"
echo ""
