R='\033[0;31m'; G='\033[0;32m'; Y='\033[0;33m'
C='\033[0;36m'; M='\033[0;35m'; B='\033[1m'; X='\033[0m'

echo -e ""
echo -e "${{M}}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${{X}}"
echo -e "${{B}}${{M}}  ESCALATION — Merge PR #{pr}${{X}}"
echo -e "${{M}}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${{X}}"
echo -e ""
echo -e "  ${{B}}Title:${{X}}    {title}"
echo -e "  ${{B}}Author:${{X}}   {author}"
echo -e "  ${{B}}Changes:${{X}}  +{additions}/-{deletions}"
echo -e "  ${{B}}Stuck:${{X}}    ${{Y}}{age} minutes${{X}}"
echo -e "  ${{B}}Reason:${{X}}   ${{R}}{reasons}${{X}}"
echo -e "  ${{B}}Checks:${{X}}  ${{G}}{checks_pass} pass${{X}}, ${{R}}{checks_fail} fail${{X}}"
echo -e ""

CURRENT_USER=$(gh api user 2>/dev/null | jq -r '.login' 2>/dev/null || echo "unknown")
if echo "$CURRENT_USER" | grep -qE "eqdmc-agent-bots|eqdmc-merge-bot"; then
  echo -e "  ${{Y}}⚠  Auth: $CURRENT_USER (app — cannot self-approve)${{X}}"
  echo -e "  ${{Y}}   Approve via CLI first:${{X}}"
  echo -e "   ${{C}}gh pr review {pr} -R {repo} --approve${{X}}"
elif echo "$CURRENT_USER" | grep -q "eqdmc-admin"; then
  echo -e "  ${{G}}✅ Auth: $CURRENT_USER — can approve directly${{X}}"
fi

echo -e ""
echo -e "${{C}}───── CONFIRMATION ──────────────────────────────────────────${{X}}"
read -p "  ${{B}}Approve and merge?${{X}} (y/n) " -r ANS

if [ "$ANS" = "y" ]; then
  gh pr review {pr} -R {repo} --approve 2>&1 | sed 's/^/  /' || true
  echo -e "  ${{B}}Merging...${{X}}"
  gh pr merge {pr} -R {repo} --squash 2>&1 | sed 's/^/  /' && \
    echo -e "  ${{G}}✅ PR #{pr} merged.${{X}}" || \
    echo -e "  ${{R}}❌ Merge failed.${{X}} Fix conflicts and re-run rax."
else
  echo -e "  ${{R}}❌ Escalation skipped.${{X}}"
fi
