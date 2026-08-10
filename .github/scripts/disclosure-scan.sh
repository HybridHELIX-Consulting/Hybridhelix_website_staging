#!/usr/bin/env bash
#
# Pre-publish disclosure scan - HybridHELIX Website 4.0
#
# Inspects every file that becomes public output for content that should not
# be published. Companion to the crawl-protection job: that one asks "can this
# page be indexed when it should not be", this one asks "should the words on
# this page be public at all".
#
# Written 8/9/2026 (PSS) after the legal migration published a Tax ID, two
# office phone numbers, and a full client agreement with rate card. Every one
# of those arrived through a good-faith paste of an exported document. The
# failure was the absence of a gate, not the absence of care.
#
# TWO TIERS, and the distinction matters:
#
#   block - categorical. Never belongs on a marketing site. Fails the build.
#   warn  - contextual. Sometimes intended. Annotates the PR, does not fail.
#
# A pattern matcher can be certain that a signature block does not belong on a
# website. It cannot be certain whether a price is one we mean to publish.
# Pretending otherwise produces a gate people learn to route around.
#
# SUPPRESSION, two ways, both reviewable in a diff:
#   1. Put the literal matched text in .disclosure-allow at the repository root.
#   2. Put the marker  disclosure-ok  on the same line.
#
# Suppression is not a loophole. It converts publishing something sensitive
# from an accident into a deliberate, visible act that a reviewer can question.

set -uo pipefail

ALLOW_FILE=".disclosure-allow"
blockers=0
warnings=0

# ---------------------------------------------------------------- allowlist

ALLOW_ENTRIES=()
if [ -f "$ALLOW_FILE" ]; then
  while IFS= read -r raw || [ -n "$raw" ]; do
    raw="${raw%%#*}"
    raw="$(printf '%s' "$raw" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')"
    [ -n "$raw" ] && ALLOW_ENTRIES+=("$raw")
  done < "$ALLOW_FILE"
fi

is_allowed() {
  local candidate="$1" entry
  for entry in ${ALLOW_ENTRIES+"${ALLOW_ENTRIES[@]}"}; do
    [ "$candidate" = "$entry" ] && return 0
  done
  return 1
}

# ------------------------------------------------------------------- corpus
#
# Everything Jekyll copies or renders into _site. .github is excluded because
# this script and the workflow that calls it necessarily contain the very
# patterns they hunt for.

FILES=()
while IFS= read -r f; do
  FILES+=("$f")
done < <(
  find . \
    -path ./_site -prune -o \
    -path ./vendor -prune -o \
    -path ./.git -prune -o \
    -path ./.github -prune -o \
    -path ./node_modules -prune -o \
    -type f \( \
      -name '*.html' -o -name '*.md' -o -name '*.markdown' -o \
      -name '*.yml'  -o -name '*.yaml' -o -name '*.json' -o \
      -name '*.txt'  -o -name '*.css'  -o -name '*.js' \
    \) -print | sort
)

if [ "${#FILES[@]}" -eq 0 ]; then
  echo "No scannable files found."
  exit 0
fi

# -------------------------------------------------------------------- scan

scan() {
  local id="$1" severity="$2" pattern="$3" message="$4"
  local f hit lineno text match

  for f in "${FILES[@]}"; do
    while IFS= read -r hit; do
      lineno="${hit%%:*}"
      text="${hit#*:}"

      case "$text" in *disclosure-ok*) continue ;; esac

      match="$(printf '%s' "$text" | grep -oE "$pattern" | head -n 1)"
      [ -z "$match" ] && continue
      is_allowed "$match" && continue

      if [ "$severity" = "block" ]; then
        echo "::error file=$f,line=$lineno::[$id] $message  (found: $match)"
        blockers=$((blockers + 1))
      else
        echo "::warning file=$f,line=$lineno::[$id] $message  (found: $match)"
        warnings=$((warnings + 1))
      fi
    done < <(grep -nEI "$pattern" "$f" 2>/dev/null || true)
  done
}

# ------------------------------------------------------- blocking patterns

scan "TAXID" "block" \
  '(EIN|FEIN|Tax[[:space:]]*(ID|Identification)|Taxpayer[[:space:]]*(ID|Identification)|Employer[[:space:]]*Identification)[[:space:]]*(Number|No\.?|#)?[[:space:]]*:?[[:space:]]*[0-9]{2}-?[0-9]{7}' \
  'Federal tax identification number. This is used to impersonate a business and does not belong on a public page.'

scan "TAXID-BARE" "block" \
  '\b[0-9]{2}-[0-9]{7}\b' \
  'Looks like an EIN (two digits, dash, seven digits). If it is genuinely something else, allowlist it.'

scan "SSN" "block" \
  '\b[0-9]{3}-[0-9]{2}-[0-9]{4}\b' \
  'Looks like a Social Security number.'

scan "FILLIN" "block" \
  '(Client|Customer|Company|Contractor|Name|Address|Phone|Email|Date|Title|Signature|By|Printed[[:space:]]+Name)[[:space:]]*:?[[:space:]]*_{3,}' \
  'Blank fill-in field. A signature-ready contract is being published as if it were a web page. See AUTHORING.md Rule 7.'

scan "SIGBLOCK" "block" \
  'IN[[:space:]]+WITNESS[[:space:]]+WHEREOF' \
  'Contract execution clause. This is an instrument to be signed, not a page to be read.'

scan "CREDENTIAL" "block" \
  '(ghp_[A-Za-z0-9]{20,}|github_pat_[A-Za-z0-9_]{20,}|AKIA[0-9A-Z]{16}|sk-[A-Za-z0-9]{20,}|-----BEGIN[[:space:]]+[A-Z ]*PRIVATE[[:space:]]+KEY-----)' \
  'Looks like a credential. Rotate it before doing anything else - assume it is already compromised.'

# -------------------------------------------------------- advisory patterns

scan "PHONE" "warn" \
  '(\+1[[:space:].-]?)?\(?[0-9]{3}\)?[[:space:].-][0-9]{3}[[:space:].-][0-9]{4}' \
  'Phone number on a public page. Confirm this is a number we want harvested, then allowlist it to silence this.'

scan "RATE" "warn" \
  '\$[0-9][0-9,]*(\.[0-9]{2})?[[:space:]]*(/|per[[:space:]]+)(hr|hour|mo|month|yr|year|week|session)' \
  'Rate or retainer figure. Confirm this is published pricing and not contract terms for one engagement.'

scan "CONTRACT" "warn" \
  '(circumvention|liquidated[[:space:]]+damages|hereinafter[[:space:]]+referred[[:space:]]+to|shall[[:space:]]+indemnify|Effective[[:space:]]+Date[[:space:]]*:[[:space:]]*_)' \
  'Contract vocabulary. Check that this document class belongs at this URL - a client agreement is not a site policy.'

scan "ADDRESS" "warn" \
  '(Suite|Ste\.?|Apt\.?|Unit)[[:space:]]*#?[[:space:]]*[A-Z]?[0-9]{2,}' \
  'Street address detail. Legitimate on a contact or legal page - just confirm it is current before it ships.'

# ------------------------------------------------------------------ verdict

echo
if [ "$blockers" -eq 0 ] && [ "$warnings" -eq 0 ]; then
  echo "Disclosure scan clean. Nothing flagged across ${#FILES[@]} files."
  exit 0
fi

echo "Disclosure scan: $blockers blocking, $warnings advisory, across ${#FILES[@]} files."

if [ "$warnings" -gt 0 ]; then
  echo
  echo "Advisory findings do not fail this build. They are annotations for the"
  echo "reviewer. If each one is intended, add it to $ALLOW_FILE so the next"
  echo "reviewer is not re-deciding a question you already settled."
fi

if [ "$blockers" -gt 0 ]; then
  echo
  echo "Blocking findings must be removed, or explicitly waived with an inline"
  echo "disclosure-ok marker or an entry in $ALLOW_FILE. Waiving is allowed and"
  echo "visible - it just has to be a decision somebody made on purpose."
  exit 1
fi

exit 0
