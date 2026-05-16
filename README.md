# claude-scaffold-project

A [Claude Code](https://claude.com/claude-code) skill that bootstraps a
brand-new project in a single conversation — folders, conventions,
first backlog item, `git init`, first commit — with a built-in
**feedback loop** that promotes reusable infrastructure patterns into
extension packs as they emerge in your projects.

The companion to [claude-dev-workflow](https://github.com/ymuromcev/claude-dev-workflow):
this one creates the structure, that one enforces how you work inside it.

> ⚠️ The skill itself ([SKILL.md](SKILL.md)) is written in **Russian**.
> This README in English explains what it does and how to adopt it.

## What it does

When you tell Claude Code "starting a new project X" (or
`/scaffold-project`), the skill:

1. **Asks four questions** — project name, one-line description,
   stack (`node-cli` / `python-mcp` / `both` / `none`), expected
   external services.

2. **Shows a preview** of every file that will be created. Waits for
   explicit approval.

3. **Runs a pre-flight check** before touching the filesystem —
   `git --version`, `git config user.name`, `git config user.email`.
   Aborts with a clear message if any of these are missing, so you
   don't end up with a half-scaffolded directory and a failed commit.

4. **Writes the base scaffold**:
   - `CLAUDE.md` — project-level rules for Claude Code.
   - `README.md`, `DEVELOPMENT.md`, `CHANGELOG.md`, `incidents.md`.
   - `.gitignore`, `.env.example` — sensible defaults.
   - `rfc/_README.md` — where M/L design docs live.
   - `docs/decisions/_README.md` — ADR folder.
   - `private/backlog/BL-001-scope-and-mvp.md` — your first task,
     forcing you to define MVP scope before writing any code.

5. **Plus an optional extension pack** for the chosen stack:
   - `node-cli` — `package.json` + `engine/index.js` + a smoke test
     using Node 20+'s built-in `node --test`.
   - `python-mcp` — `pyproject.toml` + `server.py` + `pytest` smoke.

6. **Sanity-checks** the output. If any `{{...}}` placeholder leaked
   through, the scaffold rolls back: full `rm -rf` if Claude created
   the root directory itself, or surgical removal of only its own
   files if it added to an existing directory.

7. **Runs `git init` + first commit**. Asks if you want to
   `gh repo create` and push.

After that, your new project is ready: it has a backlog with a real
first task, conventions documented for both you and Claude Code, and
hooks into [claude-dev-workflow](https://github.com/ymuromcev/claude-dev-workflow)
for the rest of development.

## Back-fill mode (for projects that already have a CLAUDE.md)

Sometimes you start a project before adopting `scaffold-project`, and
later want to add the same dev scaffolding (backlog as a DB, RFC
folder, incident log, changelog) — without rewriting the project's
existing `CLAUDE.md` or content.

Triggers (Russian): «причеши проект», «оформи как dev-проект»,
«back-fill бэклог», «добавь дев-обвязку», or
`/scaffold-project --backfill`.

What it does:

1. Detects `CLAUDE.md` is already present — switches into back-fill
   mode instead of refusing.
2. Scans for missing dev scaffolding and prints a checklist:
   ```
   ✓ CHANGELOG.md
   + private/backlog/_README.md
   + private/backlog.base
   ~ .gitignore (will append private/ block)
   ⚠ private/backlog/BL-3.md has non-canonical `area:` field — won't touch
   ```
3. Shows a preview of additions only, asks one yes/no.
4. On approve: writes only the missing files, merges `.gitignore` by
   appending (never reorders or deletes), proposes a commit message,
   asks before committing.

What it explicitly **does not** do:

- Overwrite existing files (`CLAUDE.md`, `README.md`, etc.).
- Create the `BL-1` "scaffold" task — your project has its own backlog.
- Migrate a legacy `BACKLOG.md` into `private/backlog/BL-NN.md` (that's
  a separate task).
- Normalize the frontmatter of existing `BL-NN.md` files — flags them
  but doesn't touch them.
- Run `git init` or install stack extensions (`node-cli`, `python-mcp`).

If everything is already in place, it prints "all in place, nothing
to do" and exits without touching anything.

## The feedback loop (the actual interesting part)

The non-obvious feature: when you're working inside *any* project and
hit a reusable infrastructure pattern for the first time —
event analytics, error tracking, auth, payments, CI, secret-guard,
feature flags, DB migrations, deploy config, UI scaffold, or an MCP
server in Node — the skill triggers in **reverse mode**:

> "This is the first time we're doing X in this project. Want me to
> extract the boilerplate into
> `~/.claude/skills/scaffold-project/templates/extensions/<name>/`
> so the next project gets it for free?"

You approve or skip. If you approve, the next project that opts in
during the wizard gets the same setup automatically. The skill grows
with you instead of going stale on day one.

This is the whole reason the skill exists separately from a one-shot
boilerplate. Most scaffolders are write-once; this one accumulates
your conventions as a side effect of using them.

## What it is *not*

- **Not a CLI tool** like `cookiecutter`, `yo`, or `create-react-app`.
  No npm package, no pip install. The skill is policy + templates that
  Claude Code reads at session start and applies through normal
  conversation.
- **Not opinionated about your code stack.** Base templates assume
  nothing language-specific. Stack extensions are explicitly opt-in
  and minimal — they prove the pipeline works (one file + one smoke
  test), not provide a framework.
- **Not a corporate IDP.** This is a personal-scale "paved road" / 
  "golden path" — the same idea Platform Engineering teams build at
  larger orgs, but for one person across many side projects.

## Installation

```bash
# Clone the repo somewhere persistent
git clone https://github.com/ymuromcev/claude-scaffold-project.git ~/Code/claude-scaffold-project

# Symlink into Claude Code's skills directory
ln -s ~/Code/claude-scaffold-project ~/.claude/skills/scaffold-project
```

Verify: in a Claude Code session, the skill appears in `/help` →
skills list under `scaffold-project`. It auto-triggers on phrases like
"new project", "init project", "starting a new project", "scaffold X",
or the explicit `/scaffold-project`.

## Repository layout

```
.
├── SKILL.md                       — main skill document (Russian)
├── CHANGELOG.md
├── rfc/
│   └── 001-bootstrap.md           — design doc for the skill itself
└── templates/
    ├── base/                      — files every project gets
    │   ├── CLAUDE.md.tpl
    │   ├── README.md.tpl
    │   ├── DEVELOPMENT.md.tpl
    │   ├── CHANGELOG.md.tpl
    │   ├── incidents.md.tpl
    │   ├── .gitignore.tpl
    │   ├── .env.example.tpl
    │   ├── rfc/_README.md
    │   ├── docs/decisions/_README.md
    │   └── private/backlog/
    │       ├── _README.md
    │       └── BL-001-scope-and-mvp.md.tpl
    └── extensions/
        ├── node-cli/              — Node 20+ CLI / library
        │   ├── README.md          (extension docs, NOT copied)
        │   ├── package.json.tpl
        │   ├── engine/index.js.tpl
        │   └── engine/index.test.js.tpl
        └── python-mcp/            — Python MCP server
            ├── README.md          (extension docs, NOT copied)
            ├── pyproject.toml.tpl
            ├── server.py.tpl
            └── tests/test_smoke.py.tpl
```

The `.tpl` extension is stripped on copy. Files at
`templates/extensions/<name>/README.md` document the extension itself
for the skill — they are explicitly **not** copied into target
projects (this avoids overwriting the project's own README).

## Pairing with claude-dev-workflow

Generated `CLAUDE.md` references
[claude-dev-workflow](https://github.com/ymuromcev/claude-dev-workflow)
as the development workflow skill. Both are designed to be used
together, but each works on its own:

- **scaffold-project** creates the structure (including the `rfc/`
  folder) once, at project start.
- **dev-workflow** runs every time you write code in *any* project,
  enforcing tiered development with RFC-gating and multi-agent review.

## Why publish this?

Two reasons:

1. **Portfolio transparency.** This is part of my actual day-to-day
   workflow — the same skill I use to start every new side project.
   Showing it explains how I think about AI-augmented developer
   experience more honestly than a one-page resume bullet.
2. **Possible reuse.** If anyone else finds the *self-augmenting
   template* pattern useful — templates that grow new sections as you
   discover reusable infra in your real projects — the skill is
   MIT-licensed and copyable.

## License

[MIT](LICENSE).
