#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
quarto render slides/index.qmd --to revealjs
mkdir -p docs
cp slides/index.html docs/index.html
touch docs/.nojekyll
echo "Built docs/index.html for GitHub Pages."
