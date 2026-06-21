#!/bin/bash

# Solana SecOps Skill - Standard Installer
# Installs with recommended defaults. For custom options, use ./install-custom.sh

set -e

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
NC='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SOURCE_DIR="$SCRIPT_DIR/skill"

# Standard defaults
SKILLS_DIR="$HOME/.claude/skills"
SECOPS_SKILL_PATH="$SKILLS_DIR/solana-secops"
AGENTS_DIR="$HOME/.claude/agents"
COMMANDS_DIR="$HOME/.claude/commands"
RULES_DIR="$HOME/.claude/rules"

print_banner() {
    echo ""
    echo -e "${MAGENTA}+===============================================================+${NC}"
    echo -e "${MAGENTA}|${NC}   ${WHITE}Solana SecOps Skill${NC}  -  Day-2 Ops & Incident Response   ${MAGENTA}|${NC}"
    echo -e "${MAGENTA}|${NC}   ${CYAN}Verified deploy . authority . pause . monitor . respond${NC}   ${MAGENTA}|${NC}"
    echo -e "${MAGENTA}|${NC}   ${YELLOW}for the Solana AI Kit${NC}                                       ${MAGENTA}|${NC}"
    echo -e "${MAGENTA}+===============================================================+${NC}"
    echo ""
}

print_help() {
    echo "Solana SecOps Skill - Standard Installer"
    echo ""
    echo "Usage: ./install.sh [OPTIONS]"
    echo ""
    echo "Installs with recommended defaults:"
    echo "  - Skill   -> ~/.claude/skills/solana-secops/"
    echo "  - Agents  -> ~/.claude/agents/"
    echo "  - Commands-> ~/.claude/commands/"
    echo "  - Rules   -> ~/.claude/rules/"
    echo ""
    echo "Options:"
    echo "  -y, --yes      Skip confirmation prompt"
    echo "  -h, --help     Show this help"
    echo ""
    echo "For custom installation (project-local, etc.), use: ./install-custom.sh"
    echo ""
}

# Parse arguments
SKIP_CONFIRM=false
while [[ $# -gt 0 ]]; do
    case $1 in
        -y|--yes) SKIP_CONFIRM=true; shift ;;
        -h|--help) print_help; exit 0 ;;
        *) echo "Unknown option: $1"; echo "Use --help for usage information"; exit 1 ;;
    esac
done

print_banner

echo -e "${WHITE}Standard Installation${NC}"
echo ""
echo -e "This will install:"
echo -e "  ${BLUE}*${NC} solana-secops skill -> ${CYAN}$SECOPS_SKILL_PATH${NC}"
echo -e "  ${BLUE}*${NC} agents              -> ${CYAN}$AGENTS_DIR${NC}"
echo -e "  ${BLUE}*${NC} commands            -> ${CYAN}$COMMANDS_DIR${NC}"
echo -e "  ${BLUE}*${NC} rules               -> ${CYAN}$RULES_DIR${NC}"
echo ""

if [ "$SKIP_CONFIRM" = false ]; then
    read -p "Proceed with installation? [Y/n] " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Nn]$ ]]; then
        echo -e "${YELLOW}Installation cancelled${NC}"
        echo -e "For custom options, run: ${CYAN}./install-custom.sh${NC}"
        exit 0
    fi
fi

echo ""

mkdir -p "$SKILLS_DIR" "$AGENTS_DIR" "$COMMANDS_DIR" "$RULES_DIR"

# 1) Skill
echo -e "${CYAN}[1/4]${NC} Installing solana-secops skill..."
if [ -d "$SECOPS_SKILL_PATH" ]; then
    echo -e "  ${YELLOW}->${NC} Removing existing installation"
    rm -rf "$SECOPS_SKILL_PATH"
fi
mkdir -p "$SECOPS_SKILL_PATH"
cp -r "$SOURCE_DIR"/* "$SECOPS_SKILL_PATH/"
# templates ship alongside the skill so command relative links resolve
cp -r "$SCRIPT_DIR/templates" "$SECOPS_SKILL_PATH/../solana-secops-templates" 2>/dev/null || true
echo -e "  ${GREEN}OK${NC} -> $SECOPS_SKILL_PATH"

# 2) Agents
echo -e "${CYAN}[2/4]${NC} Installing agents..."
cp "$SCRIPT_DIR/agents/"*.md "$AGENTS_DIR/" 2>/dev/null || true
echo -e "  ${GREEN}OK${NC} -> incident-commander, secops-engineer"

# 3) Commands
echo -e "${CYAN}[3/4]${NC} Installing commands..."
cp "$SCRIPT_DIR/commands/"*.md "$COMMANDS_DIR/" 2>/dev/null || true
echo -e "  ${GREEN}OK${NC} -> /secops-readiness, /setup-monitoring, /incident"

# 4) Rules
echo -e "${CYAN}[4/4]${NC} Installing rules..."
cp "$SCRIPT_DIR/rules/"*.md "$RULES_DIR/" 2>/dev/null || true
echo -e "  ${GREEN}OK${NC} -> pausable-program"

echo ""
echo -e "${GREEN}+===============================================================+${NC}"
echo -e "${GREEN}|${NC}  ${WHITE}Installation Complete!${NC}                                       ${GREEN}|${NC}"
echo -e "${GREEN}+===============================================================+${NC}"
echo ""
echo -e "${CYAN}Try asking Claude:${NC}"
echo -e "  ${BLUE}*${NC} \"Run a Day-2 readiness review on my program\""
echo -e "  ${BLUE}*${NC} \"Move my upgrade authority to a Squads multisig with a timelock\""
echo -e "  ${BLUE}*${NC} \"Add a guardian pause switch to my Anchor program\""
echo -e "  ${BLUE}*${NC} \"We think we're being exploited\"  (launches the incident runbook)"
echo ""
echo -e "${YELLOW}Companion:${NC} install solana-dev-skill for code-level patterns this skill defers to."
echo ""
echo -e "${MAGENTA}---------------------------------------------------------------${NC}"
echo -e "${YELLOW}            Day-2 ops for the Solana AI Kit${NC}"
echo -e "${MAGENTA}---------------------------------------------------------------${NC}"
echo ""
