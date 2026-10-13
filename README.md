# Course repo template

A [Copier](https://copier.readthedocs.io) template for one course: LaTeX homework write-ups,
LaTeX lecture notes and (optionally) Python code, all driven from one root `Makefile`.
It's modelled on `~/PhD/classes/FA26/CSE250A`.

> Working on the template itself (with or without an AI assistant)? See [`AGENTS.md`](AGENTS.md):
> template syntax, conventions, and how to test.

## Create a new course repo

```sh
uvx --python 3.12 copier copy ~/templates/course ~/PhD/classes/WI27/CSE257
```

Copier asks for:

- the course (code, title, cross-listing, school, term, instructor)
- you (name, PID, email)
- how the course names its files: the official homework PDF pattern (e.g.
  `cse150a_250a_fa26_hw{N}.pdf`), and the slide prefix and annotated-slide marker (e.g.
  `Lecture 06.pdf` / `Lecture 06 - post.pdf`)
- whether to set up a uv Python environment

Afterwards it prints the next steps (`git init`, `uv sync`, `make new-lec ...`). The generated
repo's own `README.md` explains how to use it day to day.

To skip retyping your personal details for every course, put them in Copier's user settings at
`~/Library/Application Support/copier/settings.yml` on macOS:

```yaml
defaults:
  student_name: ...
  student_pid: ...
  student_email: ...
```

## Update an existing course repo

Commit everything in the course repo first, then run:

```sh
cd ~/PhD/classes/WI27/CSE257
uvx --python 3.12 copier update            # re-asks nothing, keeps answers from .copier-answers.yml
uvx --python 3.12 copier update --defaults # same, non-interactive
```

Copier does a three-way merge: changes you made in the course repo survive, and conflicts show up
as conflict markers. `copier update` uses the latest **git tag** of this repo, so tag releases
(`git tag v0.2.0`) after changing the template.

## What's templated

Only files ending in `.jinja` are rendered. Everything else is copied verbatim.

| File | Templated content |
| --- | --- |
| `tex/course.sty` | course/student info macros (`\coursecode`, `\studentname`, ...), LaTeX-escaped |
| `scripts/course.conf` | slide prefix, annotated marker, official homework PDF pattern |
| `AGENTS.md`, `README.md` | course header, PDF naming, slide names; Python sections only if `use_python` |
| `.vscode/settings.json` | Python interpreter settings only if `use_python` |
| `pyproject.toml`, `.python-version` | only if `use_python`; project name, Python version, dependencies |
| `.copier-answers.yml` | the answers, for `copier update` |

`tex/hw_template.tex` and `tex/lecture_template.tex` aren't rendered by Copier. They pull every
course-specific value from `course.sty`, and `make new-hw` / `make new-lec` fill in their
per-document fields (number, due date, topic, date).

## Template syntax

LaTeX is full of `{{`, `{%` and `{#1}`, so `copier.yml` switches Jinja to square brackets:

| Purpose | Syntax |
| --- | --- |
| Variable | `[[ var ]]` |
| Block | `[% if x %] ... [% endif %]` |
| Comment | `[#= ... =#]` |

`trim_blocks` and `lstrip_blocks` are on, so a block tag on a line of its own leaves no blank line.

## Developing the template

Test a render without touching a real course:

```sh
uvx --python 3.12 copier copy --defaults --vcs-ref HEAD \
  -d course_code="CSE 999" -d course_title="Test" -d term="Fall 2026" -d instructor=X \
  -d student_name=Me -d student_pid=A0 -d student_email=me@x.edu \
  . /tmp/course-test && make -C /tmp/course-test new-lec TOPIC="Intro"
```

`--vcs-ref HEAD` renders the latest commit. Without it, Copier uses the latest tag, and
uncommitted changes are included with a warning.
