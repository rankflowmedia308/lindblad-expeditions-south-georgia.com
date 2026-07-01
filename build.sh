#!/usr/bin/env bash
set -eu

HEADER="components/header.html"
FOOTER="components/footer.html"
LAST_UPDATED=$(date +'%B %Y')

TMP_HEADER=$(mktemp)
TMP_FOOTER=$(mktemp)
TMP_CONTENT=$(mktemp)
trap 'rm -f "$TMP_HEADER" "$TMP_FOOTER" "$TMP_CONTENT"' EXIT

# Optional extras — set these globals before each build_page call
EXTRA_SCHEMA=""
EXTRA_CSS=""
EXTRA_JS=""

build_page() {
  local ACTIVE_NAV="$1"
  local CONTENT_FILE="$2"
  local OUT_FILE="$3"
  local TITLE="$4"
  local DESC="$5"
  local CANONICAL="$6"
  local OG_TITLE="$7"
  local OG_DESC="$8"
  local BASE="$9"

  local ROOT_HREF
  if [ -z "$BASE" ]; then ROOT_HREF="./"; else ROOT_HREF="$BASE"; fi

  mkdir -p "$(dirname "$OUT_FILE")"

  # Process header: active nav injection + path conversion
  sed \
    -e "s|<li><a href=\"${ACTIVE_NAV}\"|<li><a href=\"${ACTIVE_NAV}\" class=\"active\"|g" \
    -e "s|href=\"/\"|href=\"${ROOT_HREF}\"|g" \
    -e "s|href=\"/\([^\"]*\)\"|href=\"${BASE}\1\"|g" \
    -e "s|src=\"/\([^\"]*\)\"|src=\"${BASE}\1\"|g" \
    "$HEADER" > "$TMP_HEADER"

  # Process footer: path conversion + last updated
  sed \
    -e "s|href=\"/\"|href=\"${ROOT_HREF}\"|g" \
    -e "s|href=\"/\([^\"]*\)\"|href=\"${BASE}\1\"|g" \
    -e "s|src=\"/\([^\"]*\)\"|src=\"${BASE}\1\"|g" \
    -e "s|__LAST_UPDATED__|${LAST_UPDATED}|g" \
    "$FOOTER" > "$TMP_FOOTER"

  # Process content: path conversion + last updated
  sed \
    -e "s|href=\"/\"|href=\"${ROOT_HREF}\"|g" \
    -e "s|href=\"/\([^\"]*\)\"|href=\"${BASE}\1\"|g" \
    -e "s|src=\"/\([^\"]*\)\"|src=\"${BASE}\1\"|g" \
    -e "s|__LAST_UPDATED__|${LAST_UPDATED}|g" \
    "$CONTENT_FILE" > "$TMP_CONTENT"

  # Optional CSS/JS tags
  local CSS_LINK=""
  local JS_TAG=""
  if [ -n "$EXTRA_CSS" ]; then CSS_LINK="<link rel=\"stylesheet\" href=\"${BASE}${EXTRA_CSS}\">"; fi
  if [ -n "$EXTRA_JS" ]; then JS_TAG="<script src=\"${BASE}${EXTRA_JS}\"></script>"; fi

  {
    printf '<!DOCTYPE html>\n'
    printf '<html lang="en">\n'
    printf '<head>\n'
    printf '<meta charset="UTF-8">\n'
    printf '<meta name="viewport" content="width=device-width, initial-scale=1">\n'
    printf '<title>%s</title>\n' "$TITLE"
    printf '<meta name="description" content="%s">\n' "$DESC"
    printf '<link rel="canonical" href="%s">\n' "$CANONICAL"
    printf '<meta property="og:type" content="article">\n'
    printf '<meta property="og:title" content="%s">\n' "$OG_TITLE"
    printf '<meta property="og:description" content="%s">\n' "$OG_DESC"
    printf '<meta property="og:url" content="%s">\n' "$CANONICAL"
    printf '<link rel="icon" href="%simages/favicon.svg" type="image/svg+xml">\n' "$BASE"
    printf '<link rel="stylesheet" href="%scss/global.css">\n' "$BASE"
    [ -n "$CSS_LINK" ] && printf '%s\n' "$CSS_LINK"
    [ -n "$EXTRA_SCHEMA" ] && printf '%s\n' "$EXTRA_SCHEMA"
    printf '</head>\n'
    printf '<body>\n'
    cat "$TMP_HEADER"
    printf '<main>\n'
    cat "$TMP_CONTENT"
    printf '</main>\n'
    cat "$TMP_FOOTER"
    printf '<script src="%sjs/nav.js"></script>\n' "$BASE"
    [ -n "$JS_TAG" ] && printf '%s\n' "$JS_TAG"
    printf '</body>\n'
    printf '</html>\n'
  } > "$OUT_FILE"

  echo "Built: $OUT_FILE"
}

# ── JSON-LD schemas for homepage (single-quoted: no $ interpolation) ──────────
HOMEPAGE_SCHEMA=$(cat <<'JSONLD'
<script type="application/ld+json">
{
  "@context": "https://schema.org",
  "@type": "Article",
  "headline": "Lindblad Expeditions South Georgia Cruise: Itinerary, Price & Alternatives 2026/2027",
  "description": "Independent comparison of Lindblad Expeditions South Georgia itinerary against smaller expedition operators, covering route, pricing, ships, and landing methodology.",
  "url": "https://lindblad-expeditions-south-georgia.com/",
  "author": { "@type": "Organization", "name": "South Georgia Review Editorial Team" },
  "publisher": { "@type": "Organization", "name": "South Georgia Review", "url": "https://lindblad-expeditions-south-georgia.com/" }
}
</script>
<script type="application/ld+json">
{
  "@context": "https://schema.org",
  "@type": "FAQPage",
  "mainEntity": [
    { "@type": "Question", "name": "How much does a Lindblad South Georgia cruise cost?", "acceptedAnswer": { "@type": "Answer", "text": "Lindblad's South Georgia, Antarctica & Falklands itinerary starts from $22,715 per person for 21-22 days, excluding international flights and travel insurance." } },
    { "@type": "Question", "name": "What ships does Lindblad use for South Georgia?", "acceptedAnswer": { "@type": "Answer", "text": "Lindblad runs the National Geographic Endurance (138 passengers, Polar Class 5), Resolution (138 passengers, Polar Class 5), or Explorer (148 passengers) on this route." } },
    { "@type": "Question", "name": "Is there a smaller-ship alternative to Lindblad for South Georgia?", "acceptedAnswer": { "@type": "Answer", "text": "Yes - Poseidon Expeditions operates the 114-passenger M/V Sea Spirit. Because it stays under IAATO's 100-guest landing limit, all guests go ashore simultaneously instead of splitting into rotating groups." } },
    { "@type": "Question", "name": "What wildlife will I see at South Georgia?", "acceptedAnswer": { "@type": "Answer", "text": "South Georgia is known for large king penguin colonies at St. Andrew's Bay, southern elephant seals, and humpback and fin whale sightings during crossings." } },
    { "@type": "Question", "name": "Why do landings get split into groups on some ships?", "acceptedAnswer": { "@type": "Answer", "text": "IAATO limits shore landings to 100 guests per site. Ships above 100 passengers must rotate landing groups. Ships at or below that threshold land everyone at once." } }
  ]
}
</script>
JSONLD
)

# ── Homepage ──────────────────────────────────────────────────────────────────
EXTRA_SCHEMA="$HOMEPAGE_SCHEMA"
EXTRA_CSS="css/ranking.css"
EXTRA_JS="js/reviews.js"
build_page "/" \
  "content/main-ranking.html" \
  "index.html" \
  "Lindblad South Georgia Cruise: Itinerary, Price & Alternatives 2026" \
  "Lindblad Expeditions South Georgia cruise: route, \$22,715 price, ship specs, and 3 small-ship alternatives compared for 2026/2027 departures." \
  "https://lindblad-expeditions-south-georgia.com/" \
  "Lindblad Expeditions South Georgia: Itinerary, Price & Top Alternatives" \
  "Full breakdown of Lindblad's South Georgia route, ships, and pricing — plus 3 small-ship operators worth comparing before you book." \
  ""

# ── Inner pages ───────────────────────────────────────────────────────────────
EXTRA_SCHEMA=""
EXTRA_CSS=""
EXTRA_JS=""

build_page "/about/" \
  "content/about.html" \
  "about/index.html" \
  "About This Polar Cruise Comparison Site | South Georgia Rankings" \
  "Who runs this site, why it covers Lindblad Expeditions' South Georgia route, and how we research and compare polar expedition operators." \
  "https://lindblad-expeditions-south-georgia.com/about/" \
  "About This Polar Cruise Comparison Site | South Georgia Rankings" \
  "Who runs this site, why it covers Lindblad Expeditions' South Georgia route, and how we research and compare polar expedition operators." \
  "../"

build_page "/editorial-policy/" \
  "content/editorial-policy.html" \
  "editorial-policy/index.html" \
  "Editorial Policy: How We Rank Polar Cruise Operators" \
  "How this site evaluates and ranks Antarctic and South Georgia expedition cruise operators, including data sources and ranking criteria." \
  "https://lindblad-expeditions-south-georgia.com/editorial-policy/" \
  "Editorial Policy: How We Rank Polar Cruise Operators" \
  "How this site evaluates and ranks Antarctic and South Georgia expedition cruise operators, including data sources and ranking criteria." \
  "../"

build_page "/our-mission/" \
  "content/our-mission.html" \
  "our-mission/index.html" \
  "Our Mission | South Georgia Cruise Comparison Site" \
  "Why this site compares Lindblad Expeditions and other polar operators on the South Georgia route, and what we want travelers to get out of it." \
  "https://lindblad-expeditions-south-georgia.com/our-mission/" \
  "Our Mission | South Georgia Cruise Comparison Site" \
  "Why this site compares Lindblad Expeditions and other polar operators on the South Georgia route, and what we want travelers to get out of it." \
  "../"

build_page "/contact/" \
  "content/contact.html" \
  "contact/index.html" \
  "Contact Us | South Georgia Cruise Comparison Site" \
  "Get in touch with questions about our South Georgia operator comparisons, corrections, or editorial inquiries." \
  "https://lindblad-expeditions-south-georgia.com/contact/" \
  "Contact Us | South Georgia Cruise Comparison Site" \
  "Get in touch with questions about our South Georgia operator comparisons, corrections, or editorial inquiries." \
  "../"

build_page "/terms-and-conditions/" \
  "content/terms-and-conditions.html" \
  "terms-and-conditions/index.html" \
  "Terms & Conditions | South Georgia Cruise Comparison Site" \
  "Terms of use for this site, including affiliate disclosure and limitations on the accuracy of third-party operator information." \
  "https://lindblad-expeditions-south-georgia.com/terms-and-conditions/" \
  "Terms & Conditions | South Georgia Cruise Comparison Site" \
  "Terms of use for this site, including affiliate disclosure and limitations on the accuracy of third-party operator information." \
  "../"

build_page "/cookie-policy/" \
  "content/cookie-policy.html" \
  "cookie-policy/index.html" \
  "Cookie Policy | South Georgia Cruise Comparison Site" \
  "How this site uses cookies and how to manage your cookie preferences." \
  "https://lindblad-expeditions-south-georgia.com/cookie-policy/" \
  "Cookie Policy | South Georgia Cruise Comparison Site" \
  "How this site uses cookies and how to manage your cookie preferences." \
  "../"

echo ""
echo "All pages built successfully."
