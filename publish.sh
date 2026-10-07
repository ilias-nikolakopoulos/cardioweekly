#!/bin/bash
# Build the CardioWeekly GitHub Pages site from the local web edition and push it.
# Source: ~/cardiology weekly report/web (latest.html is body-only; archive.html and issues/*.html are full documents).
set -euo pipefail
SRC="$HOME/cardiology weekly report/web"
SITE="$(cd "$(dirname "$0")" && pwd)"
GH="$HOME/.local/bin/gh"

[ -f "$SRC/latest.html" ] || { echo "publish.sh: $SRC/latest.html not found" >&2; exit 1; }

# latest.html -> index.html as a full document: the leading <title>/<style> go in <head>.
python3 - "$SRC/latest.html" "$SITE/index.html" <<'PY'
import re, sys
src, out = sys.argv[1], sys.argv[2]
s = open(src, encoding="utf-8").read().strip()
head, body = "", s
m = re.match(r"\s*((?:<title>.*?</title>\s*)?(?:<style>.*?</style>\s*)+)", s, re.S)
if m:
    head, body = m.group(1).strip(), s[m.end():]
doc = ('<!doctype html>\n<html lang="en">\n<head>\n<meta charset="utf-8">\n'
       '<meta name="viewport" content="width=device-width, initial-scale=1, viewport-fit=cover">\n'
       + head + '\n</head>\n<body>\n' + body.strip() + '\n</body>\n</html>\n')
open(out, "w", encoding="utf-8").write(doc)
PY

cp "$SRC/archive.html" "$SITE/archive.html"
if [ -d "$SRC/issues" ]; then
  mkdir -p "$SITE/issues"
  cp "$SRC"/issues/*.html "$SITE/issues/" 2>/dev/null || true
fi

cd "$SITE"
git add -A
if git diff --cached --quiet; then
  echo "publish.sh: no changes to publish"
  exit 0
fi
git commit -q -m "Publish CardioWeekly issue of $(date +%Y-%m-%d)"
git -c credential.helper= -c credential.helper="!$GH auth git-credential" push -q origin main
echo "publish.sh: pushed $(git rev-parse --short HEAD) to https://ilias-nikolakopoulos.github.io/cardioweekly/"
