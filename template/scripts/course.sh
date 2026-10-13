#!/usr/bin/env bash
# Scaffolding helpers behind the root Makefile. Run from the repo root (the Makefile does).
#
#   course.sh new-hw N [DUE]
#       Create homework/hwN/ (hwN.tex from tex/hw_template.tex, plus figures/, code/,
#       handout/). Put the course's files for the assignment in handout/, with the official
#       PDF named per HW_PDF_PATTERN.
#
#   course.sh new-lec "Topic Name" [N] [DATE]
#       Create notes/NN-topic-name/lecNN.tex from tex/lecture_template.tex.
#       N defaults to one past the highest existing notes/NN-*; DATE defaults to today
#       (pass DATE="" to leave it blank). Then files any dropped-in slides (see below).
#
#   course.sh slides
#       Rename PDFs dropped into course/slides/ as e.g. "Lecture NN.pdf" / "Lecture NN - post.pdf"
#       to lecNN-<topic>.pdf / lecNN-<topic>-annotated.pdf, taking <topic> from the
#       matching notes/NN-<topic>/ folder.
#
#   Course-specific names (slide prefix, annotated marker, PDF pattern): scripts/course.conf
set -euo pipefail

SLIDES=course/slides
source "$(dirname "$0")/course.conf"

slugify() {
  printf '%s' "$1" | tr '[:upper:]' '[:lower:]' | sed -E 's/[^a-z0-9]+/-/g; s/^-+//; s/-+$//'
}

# Escape LaTeX special characters (& % $ # _) so text is safe inside \newcommand.
latex_escape() {
  printf '%s' "$1" | sed -e 's/[&%$#_]/\\&/g'
}

# Escape a string for use on the replacement side of a sed s||| command.
sed_escape() {
  printf '%s' "$1" | sed -e 's/[\\&|]/\\&/g'
}

# set_field FILE MACRO VALUE: rewrite the line "\newcommand{\MACRO}{...}" in FILE.
set_field() {
  local value
  value=$(sed_escape "$(latex_escape "$3")")
  sed -i '' -e "s|^\\\\newcommand{\\\\$2}{[^}]*}|\\\\newcommand{\\\\$2}{$value}|" "$1"
}

# Drop the template's own "how to use this template" header (everything before \documentclass).
strip_header() {
  sed -i '' -e '1,/^\\documentclass/{/^\\documentclass/!d;}' "$1"
}

import_slides() {
  shopt -s nullglob
  local f n post dirs slug dest
  for f in "$SLIDES/$SLIDE_PREFIX "[0-9]*.pdf; do
    n=$(basename "$f" | sed -E "s/^$SLIDE_PREFIX ([0-9]+).*/\\1/")
    n=$(printf '%02d' "$((10#$n))")
    post=""
    [[ "$(basename "$f")" == *"$ANNOTATED_MARKER"* ]] && post="-annotated"
    dirs=(notes/"$n"-*/)
    if [[ ${#dirs[@]} -eq 0 ]]; then
      echo "skip: '$f' -- no notes/$n-*/ yet to take the topic from (run: make new-lec TOPIC=\"...\")"
      continue
    fi
    slug=$(basename "${dirs[0]}"); slug=${slug#"$n"-}
    dest="$SLIDES/lec$n-$slug$post.pdf"
    if [[ -e "$dest" ]]; then
      echo "skip: '$f' -- $dest already exists"
      continue
    fi
    mv "$f" "$dest"
    echo "filed: '$f' -> $dest"
  done
  shopt -u nullglob
}

new_hw() {
  local n=${1:?usage: course.sh new-hw N [DUE]}
  local due=${2:-Day Mon DD, 11:59 PM PT}
  n=$((10#$n))
  local dir="homework/hw$n"
  if [[ -e "$dir/hw$n.tex" ]]; then
    echo "error: $dir/hw$n.tex already exists -- not overwriting" >&2
    exit 1
  fi
  mkdir -p "$dir"/{figures,code,handout}
  touch "$dir"/{figures,code,handout}/.gitkeep
  cp tex/hw_template.tex "$dir/hw$n.tex"
  strip_header "$dir/hw$n.tex"
  set_field "$dir/hw$n.tex" hwnum "$n"
  set_field "$dir/hw$n.tex" duedate "$due"
  sed -i '' -e "s|{problem}{N\\.1}|{problem}{$n.1}|" "$dir/hw$n.tex"
  echo "created: $dir/hw$n.tex"
  echo "  put the course's files in $dir/handout/, the assignment PDF as ${HW_PDF_PATTERN//\{N\}/$n}"
}

new_lec() {
  local topic=${1:?usage: course.sh new-lec \"Topic\" [N] [DATE]}
  local n=${2:-}
  local date
  if [[ $# -ge 3 ]]; then date=$3; else date=$(date "+%B %-d, %Y"); fi

  if [[ -z "$n" ]]; then
    local last
    last=$(find notes -maxdepth 1 -type d -name '[0-9][0-9]-*' 2>/dev/null \
             | sed -E 's|.*/([0-9]+)-.*|\1|' | sort -n | tail -1)
    n=$(( 10#${last:-0} + 1 ))
  fi
  n=$(printf '%02d' "$((10#$n))")

  local existing
  shopt -s nullglob; existing=(notes/"$n"-*/); shopt -u nullglob
  if [[ ${#existing[@]} -gt 0 ]]; then
    echo "error: ${existing[0]} already exists -- not overwriting" >&2
    exit 1
  fi

  local dir="notes/$n-$(slugify "$topic")"
  mkdir -p "$dir/figures"
  touch "$dir/figures/.gitkeep"
  cp tex/lecture_template.tex "$dir/lec$n.tex"
  strip_header "$dir/lec$n.tex"
  set_field "$dir/lec$n.tex" lecnum "$n"
  set_field "$dir/lec$n.tex" lectopic "$topic"
  set_field "$dir/lec$n.tex" lecdate "$date"
  echo "created: $dir/lec$n.tex"
  import_slides
}

case "${1:-}" in
  new-hw)  shift; new_hw "$@" ;;
  new-lec) shift; new_lec "$@" ;;
  slides)  import_slides ;;
  *)       sed -n '2,19p' "$0"; exit 1 ;;
esac
