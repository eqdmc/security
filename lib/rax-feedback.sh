#!/bin/bash
# rax-feedback.sh — Reusable feedback collection for any eqdmc tool.
#
# Sources the rax SSOT config, reads the feedback method, prompts the user
# with the appropriate questions, logs the result, and creates a GitHub issue.
#
# Usage:
#   source lib/rax-feedback.sh
#   collect_feedback "action-id-123" "Purpose of this action"
#
# The feedback method is controlled by packages/rax.yaml → feedback.method.
# Change it there to experiment with different formats across all tools.

_RAX_FB_SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$_RAX_FB_SCRIPT_DIR/rax-config.sh"

collect_feedback() {
  local action_id="${1:-unknown}"
  local purpose="${2:-unknown}"
  local method="${RAX_FEEDBACK_METHOD:-yn-goal-text}"

  local sat=""
  local achieved=""
  local improve=""
  local nps=""

  echo ""
  printf "${GREEN}───── FEEDBACK ───────────────────────────────────────────${RESET}\n"
  echo ""

  case "$method" in
    yn-goal-text)
      printf "  ${BOLD}Q1${RESET}  Were you satisfied with this rax action? ${DIM}(y/n, Enter=skip)${RESET}\n  > "
      read -r sat
      echo ""
      printf "  ${BOLD}Q2${RESET}  Did this achieve what you needed? ${DIM}(y/n, Enter=skip)${RESET}\n  > "
      read -r achieved
      echo ""
      printf "  ${BOLD}Q3${RESET}  What could be improved? ${DIM}(Enter to skip)${RESET}\n  > "
      read -r improve
      echo ""
      ;;

    scale-goal-text)
      printf "  ${BOLD}Q1${RESET}  How satisfied are you? ${DIM}(1-5, 1=not at all 5=very, 0=skip)${RESET}\n  > "
      read -r sat
      echo ""
      printf "  ${BOLD}Q2${RESET}  Did this achieve what you needed? ${DIM}(y/n, Enter=skip)${RESET}\n  > "
      read -r achieved
      echo ""
      printf "  ${BOLD}Q3${RESET}  What could be improved? ${DIM}(Enter to skip)${RESET}\n  > "
      read -r improve
      echo ""
      ;;

    nps-text)
      printf "  ${BOLD}Q1${RESET}  How likely would you recommend rax to others? ${DIM}(0-10, 0=not likely 10=very, Enter=skip)${RESET}\n  > "
      read -r nps
      echo ""
      printf "  ${BOLD}Q2${RESET}  What could be improved? ${DIM}(Enter to skip)${RESET}\n  > "
      read -r improve
      echo ""
      ;;

    text-only)
      printf "  ${BOLD}Q1${RESET}  What could be improved? ${DIM}(Enter to skip)${RESET}\n  > "
      read -r improve
      echo ""
      ;;
  esac

  # Submit if anything was answered
  if [ -n "$sat" ] || [ -n "$achieved" ] || [ -n "$improve" ] || [ -n "$nps" ]; then
    if command -v rax-feedback >/dev/null 2>&1; then
      rax-feedback \
        --action "$action_id" \
        --satisfaction "$sat" \
        --achieved "$achieved" \
        --improve "$improve" \
        --note "method=$method nps=$nps" 2>&1 | sed 's/^/  /'
    fi
    printf "\n  ${GREEN}${CHECK} Feedback submitted — thank you${RESET}\n"
  else
    printf "  ${DIM}Feedback skipped${RESET}\n"
  fi

  unset sat achieved improve nps method
}

# Export the function so it's available to sourcing scripts
export -f collect_feedback
