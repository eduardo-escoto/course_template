# Course repo template (Copier)

This repo is a [Copier](https://copier.readthedocs.io) template. It generates one repo per
course: LaTeX homework write-ups, LaTeX lecture notes, optional Python, and a root `Makefile`.
You're editing the **template**, not a course. The reference instance is
`~/PhD/classes/FA26/CSE250A`, the course repo it was modelled on. Usage for humans is in
`README.md`.

## Layout

```
course/
├── AGENTS.md / CLAUDE.md   # this file (CLAUDE.md just imports it)
├── README.md               # how to copy/update a course repo from this template
├── copier.yml              # questions, Jinja settings, post-copy/update messages
└── template/               # _subdirectory: everything in here becomes the course repo
    ├── [[ _copier_conf.answers_file ]].jinja       # -> .copier-answers.yml
    ├── [% if use_python %]pyproject.toml[% endif %].jinja
    ├── [% if use_python %].python-version[% endif %].jinja
    ├── AGENTS.md.jinja, README.md.jinja   # the generated repo's own docs
    ├── CLAUDE.md, Makefile, .gitignore, .vscode/tasks.json     # copied verbatim
    ├── .vscode/settings.json.jinja        # Python settings only if use_python
    ├── scripts/course.sh                  # verbatim; sources course.conf
    ├── scripts/course.conf.jinja          # slide prefix, annotated marker, homework PDF pattern
    ├── tex/course.sty.jinja               # course/student info macros are templated
    ├── tex/hw_template.tex, tex/lecture_template.tex   # verbatim (filled later by make new-*)
    └── course/{slides,readings}/, notes/, homework/, exams/, projects/   # .gitkeep only
```

## How templating works here

- **Only `*.jinja` files are rendered.** Everything else is copied byte-for-byte. Keep files
  verbatim unless they need an answer. If a file only needs one or two values, move those values
  into a small rendered file. That's why `course.conf` exists and `course.sh` isn't templated.
- **Square-bracket delimiters** (set in `copier.yml` `_envops`), because LaTeX and bash use
  `{{`, `{%` and `{#1}` everywhere:
  - variables: `[[ var ]]`
  - blocks: `[% if x %] ... [% endif %]`
  - comments: `[#= ... =#]`. Not `[#`, which collides with `\left[#1`.

  These delimiters also apply to defaults, validators and `when:` inside `copier.yml`.
- **`trim_blocks` and `lstrip_blocks` are on.** A block tag on a line of its own leaves no blank
  line. A tag that **ends** a line of text also eats that line's newline, so write `+%]` there,
  e.g. `[% endif +%]`. Don't use `[%-` / `-%]`; they fight trim_blocks.
- **LaTeX values** in `course.sty.jinja` go through the `tex()` macro at the top of the file,
  which escapes `& % $ # _`. It matches `latex_escape` in `course.sh`. Copier filters loaded
  through `_jinja_extensions` would need `--trust`, so use macros.
- **Conditional files** use the conditional in the filename. An empty rendered name means the
  file is skipped.
- **Computed answers** (`term_code`, `course_slug`) are ordinary questions with Jinja defaults, so
  the user can override them and they're saved for `copier update`.

## Adding or changing something

- **New question:** add it to `copier.yml`, give it a `help`, and give it a sensible `default`
  or a `validator` if it's required. Use it in the `.jinja` files, mention it in `README.md`'s
  "What's templated" table, and test both a fresh copy and an update. Renaming or removing a
  question breaks `copier update` for existing course repos unless you add a `_migrations` entry.
- **Improving the course machinery** (Makefile, `course.sh`, `course.sty`, the tex templates,
  `.vscode/`): these usually start in a real course repo. Port the change here and keep the two in
  sync. Keep it generic: no course codes, names, IDs or dates hard-coded outside answers.
- **Generated docs** (`template/AGENTS.md.jinja`, `template/README.md.jinja`) describe the course
  repo's own workflow. Update them whenever the machinery changes. This file only describes the
  template.

## Testing (always, before telling the user it works)

Render into the scratchpad or `/tmp`, never into a real course folder. `--vcs-ref HEAD` renders
the last commit; without it, Copier uses the latest tag plus uncommitted changes, with a warning.

```sh
# 1. Fidelity: render with CSE250A's answers and diff against the reference repo.
#    Expected differences: generic AGENTS intro, no hw1/hw2 notes, unpinned deps.
uvx --python 3.12 copier copy --defaults \
  -d course_code="CSE 250A" -d course_title="Probabilistic Reasoning and Learning" \
  -d cross_listed="CSE 150A" -d term="Fall 2026" -d instructor="Trevor Bonjour" \
  -d student_name=X -d student_pid=X -d student_email=x@ucsd.edu \
  -d hw_pdf_pattern='cse150a_250a_fa26_hw{N}.pdf' . "$OUT"
for f in Makefile scripts/course.sh tex/course.sty AGENTS.md README.md .vscode/settings.json; do
  diff ~/PhD/classes/FA26/CSE250A/$f "$OUT/$f"; done

# 2. Machinery: in a render, run make new-lec / new-hw / slides (touch fake slide PDFs) and make.
# 3. Variants: -d use_python=false; answers containing & and _ (must still compile).
# 4. Update: copy the template to a scratch dir, commit + tag there, render, commit the render,
#    change the scratch template, tag again, then `copier update --defaults` in the render.
```

## Rules

- **Never commit, tag or push in this repo without asking.** `copier update` follows git tags,
  so a tag is effectively a release to every course repo.
- Run Copier as `uvx --python 3.12 copier ...`. Don't install it globally.
- Never modify real course repos as a side effect of testing.
- Store personal defaults (name, PID, email) in Copier's user settings
  (`~/Library/Application Support/copier/settings.yml`), never as defaults in `copier.yml`.
- macOS: `sed -i ''`, and the filesystem is case-insensitive, so do case-only renames via a
  temporary name.
