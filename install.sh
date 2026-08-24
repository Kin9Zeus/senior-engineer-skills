#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────────────────────
#  Devleck Senior Engineer Skills — installer (macOS / Linux / WSL / Git Bash)
#
#  Copies skills/, commands/ and agents/ into your agent's directory.
#  Shows exactly what it will do and asks before overwriting anything.
#
#  Usage:
#    ./install.sh                        install globally, auto-detect the agent
#    ./install.sh --agent cursor         install for a specific agent
#    ./install.sh --project             install into ./.claude/ instead of ~
#    ./install.sh --skills-only         skip commands and agents
#    ./install.sh --uninstall           remove what this installed
#    ./install.sh --dry-run             show what would happen, change nothing
#    ./install.sh --yes                 do not prompt (for CI)
# ─────────────────────────────────────────────────────────────────────────────

set -euo pipefail

# ANSI-C quoting so these hold real escape characters — they must work inside a
# heredoc, where printf's own \033 interpretation does not apply.
LIME=$'\033[38;5;190m'; RED=$'\033[31m'; YEL=$'\033[33m'; GRN=$'\033[32m'
DIM=$'\033[2m'; BLD=$'\033[1m'; OFF=$'\033[0m'

# Honour NO_COLOR and non-TTY output (piping, CI).
if [ -n "${NO_COLOR:-}" ] || [ ! -t 1 ]; then
  LIME=''; RED=''; YEL=''; GRN=''; DIM=''; BLD=''; OFF=''
fi

SRC="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
AGENT=""; PROJECT=0; SKILLS_ONLY=0; UNINSTALL=0; DRY=0; ASSUME_YES=0

SKILL_NAMES=(senior-engineer project-audit project-blueprint security-hardening
  database-engineering api-contracts devops-platform observability-slo
  testing-strategy performance-engineering accessibility-audit
  web-presence-audit privacy-compliance release-readiness engineering-standards)

usage() { sed -n '2,22p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'; exit 0; }

while [ $# -gt 0 ]; do
  case "$1" in
    --agent)       AGENT="${2:-}"; shift 2 ;;
    --project|-p)  PROJECT=1; shift ;;
    --skills-only) SKILLS_ONLY=1; shift ;;
    --uninstall)   UNINSTALL=1; shift ;;
    --dry-run|-n)  DRY=1; shift ;;
    --yes|-y)      ASSUME_YES=1; shift ;;
    --help|-h)     usage ;;
    *) printf "${RED}Unknown option: %s${OFF}\n" "$1" >&2; exit 2 ;;
  esac
done

printf "\n${LIME}${BLD}  Devleck · Senior Engineer Skills${OFF}\n"
printf "${DIM}  15 skills · 7 commands · 4 agents${OFF}\n\n"

# ── Resolve the target directory ─────────────────────────────────────────────
detect_agent() {
  [ -d "$HOME/.claude" ]                    && { echo claude;      return; }
  [ -d "$HOME/.cursor" ]                    && { echo cursor;      return; }
  [ -d "$HOME/.codex" ]                     && { echo codex;       return; }
  [ -d "$HOME/.config/opencode" ]           && { echo opencode;    return; }
  [ -d "$HOME/.gemini/antigravity" ]        && { echo antigravity; return; }
  echo claude
}

[ -z "$AGENT" ] && AGENT="$(detect_agent)"

if [ "$PROJECT" -eq 1 ]; then
  BASE="$(pwd)/.claude"
else
  case "$AGENT" in
    claude)      BASE="$HOME/.claude" ;;
    cursor)      BASE="$HOME/.cursor" ;;
    codex)       BASE="$HOME/.codex" ;;
    opencode)    BASE="$HOME/.config/opencode" ;;
    antigravity) BASE="$HOME/.gemini/antigravity" ;;
    *) printf "${RED}Unknown agent '%s'. Use: claude | cursor | codex | opencode | antigravity${OFF}\n" "$AGENT" >&2; exit 2 ;;
  esac
fi

SKILLS_DIR="$BASE/skills"
CMDS_DIR="$BASE/commands"
AGENTS_DIR="$BASE/agents"

printf "  ${BLD}Agent${OFF}   %s%s\n" "$AGENT" "$([ "$PROJECT" -eq 1 ] && echo ' (project-local)')"
printf "  ${BLD}Target${OFF}  %s\n\n" "$BASE"

# ── Uninstall ────────────────────────────────────────────────────────────────
if [ "$UNINSTALL" -eq 1 ]; then
  printf "${YEL}This will remove:${OFF}\n"
  for s in "${SKILL_NAMES[@]}"; do [ -e "$SKILLS_DIR/$s" ] && printf "    %s\n" "$SKILLS_DIR/$s"; done
  for f in "$CMDS_DIR"/snr-*.md; do [ -e "$f" ] && printf "    %s\n" "$f"; done
  for f in "$AGENTS_DIR"/snr-*.md; do [ -e "$f" ] && printf "    %s\n" "$f"; done
  echo
  if [ "$ASSUME_YES" -eq 0 ]; then
    read -r -p "  Proceed? [y/N] " a; case "$a" in [yY]*) ;; *) echo "  Cancelled."; exit 0 ;; esac
  fi
  for s in "${SKILL_NAMES[@]}"; do rm -rf "${SKILLS_DIR:?}/$s"; done
  rm -f "$CMDS_DIR"/snr-*.md "$AGENTS_DIR"/snr-*.md 2>/dev/null || true
  printf "\n  ${GRN}Removed.${OFF} Restart your agent to apply.\n\n"
  exit 0
fi

# ── Sanity check the source ──────────────────────────────────────────────────
[ -d "$SRC/skills" ] || { printf "${RED}  No skills/ directory found next to this script.\n  Run it from inside the cloned repository.${OFF}\n\n" >&2; exit 1; }

FOUND=0
for s in "${SKILL_NAMES[@]}"; do [ -f "$SRC/skills/$s/SKILL.md" ] && FOUND=$((FOUND+1)); done
[ "$FOUND" -eq 0 ] && { printf "${RED}  skills/ contains no SKILL.md files. Is the clone complete?${OFF}\n\n" >&2; exit 1; }

# ── Plan ─────────────────────────────────────────────────────────────────────
printf "  ${BLD}Will install${OFF}\n"
printf "    %s skills   → %s/\n" "$FOUND" "$SKILLS_DIR"
if [ "$SKILLS_ONLY" -eq 0 ]; then
  NC=$(ls -1 "$SRC/commands"/*.md 2>/dev/null | wc -l | tr -d ' ')
  NA=$(ls -1 "$SRC/agents"/*.md   2>/dev/null | wc -l | tr -d ' ')
  [ "${NC:-0}" -gt 0 ] && printf "    %s commands → %s/\n" "$NC" "$CMDS_DIR"
  [ "${NA:-0}" -gt 0 ] && printf "    %s agents   → %s/\n" "$NA" "$AGENTS_DIR"
fi

CONFLICTS=()
for s in "${SKILL_NAMES[@]}"; do [ -e "$SKILLS_DIR/$s" ] && CONFLICTS+=("$s"); done
if [ ${#CONFLICTS[@]} -gt 0 ]; then
  printf "\n  ${YEL}Already present (will be replaced):${OFF}\n"
  for c in "${CONFLICTS[@]}"; do printf "    %s\n" "$c"; done
fi

echo
if [ "$DRY" -eq 1 ]; then printf "  ${DIM}--dry-run: nothing was changed.${OFF}\n\n"; exit 0; fi
if [ "$ASSUME_YES" -eq 0 ]; then
  read -r -p "  Proceed? [Y/n] " a; case "$a" in [nN]*) echo "  Cancelled."; exit 0 ;; esac
fi

# ── Install ──────────────────────────────────────────────────────────────────
mkdir -p "$SKILLS_DIR"
for s in "${SKILL_NAMES[@]}"; do
  [ -d "$SRC/skills/$s" ] || continue
  rm -rf "${SKILLS_DIR:?}/$s"
  cp -R "$SRC/skills/$s" "$SKILLS_DIR/$s"
  find "$SKILLS_DIR/$s" -name '*.sh' -exec chmod +x {} \; 2>/dev/null || true
  printf "  ${GRN}✓${OFF} %s\n" "$s"
done

if [ "$SKILLS_ONLY" -eq 0 ]; then
  if ls "$SRC/commands"/*.md >/dev/null 2>&1; then
    mkdir -p "$CMDS_DIR"; cp "$SRC/commands"/*.md "$CMDS_DIR/"
    printf "  ${GRN}✓${OFF} commands\n"
  fi
  if ls "$SRC/agents"/*.md >/dev/null 2>&1; then
    mkdir -p "$AGENTS_DIR"; cp "$SRC/agents"/*.md "$AGENTS_DIR/"
    printf "  ${GRN}✓${OFF} agents\n"
  fi
fi

cat <<EOF

  ${GRN}${BLD}Installed.${OFF}  Restart your agent, then try:

    ${LIME}/snr-audit${OFF}        full audit of the current repository
    ${LIME}/snr-scorecard${OFF}    fast 15-domain rating
    ${LIME}/snr-build${OFF}        architect and scaffold something new
    ${LIME}/snr-ship${OFF}         go/no-go release gate

  Or just describe the work — the skills activate on their own.

  ${DIM}Docs: https://github.com/Kin9Zeus/senior-engineer-skills${OFF}

EOF
