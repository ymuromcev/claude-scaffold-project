# scaffold-project — CHANGELOG

Format: [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

## v0.4.0 — 2026-05-15

### Added
- **Back-fill mode** — второй режим работы скилла. Для проекта, у
  которого уже есть `CLAUDE.md`, скилл умеет добавить недостающую
  дев-обвязку (`private/backlog/_README.md`, `private/backlog.base`,
  `rfc/_README.md`, `docs/decisions/_README.md`, `incidents.md`,
  `CHANGELOG.md`) из тех же `templates/base/`. Существующие файлы
  не перезаписываются, `.gitignore` только мерджится (append недостающих
  строк, без удаления и переупорядочивания существующих). `BL-1` в
  back-fill не создаётся — у проекта свой backlog.
- Новые триггер-фразы: «причеши проект», «оформи как dev-проект»,
  «back-fill бэклог», «добавь дев-обвязку», `/scaffold-project --backfill`.
- Шаг 0 — определение режима по триггер-фразе.
- Алгоритм сканирования с чек-листом (✓ / + / ~ / ⚠), включая детекцию
  не-каноничного frontmatter в существующих `BL-NN.md` и
  legacy-`BACKLOG.md` (флагуем, не трогаем).

### Changed
- Pre-checks для fresh-mode: при наличии `CLAUDE.md` отказ теперь
  сопровождается подсказкой про back-fill, а не глухой стеной.
- Секция «Когда скилл НЕ применяется» уточнена: миграция контента
  существующих backlog/`.md`-файлов под канон — отдельная задача,
  back-fill этим не занимается.

### Reason
В сессии TTRPGs (2026-05-15) обнаружилось, что для проекта с уже
существующим `CLAUDE.md` скилл просто отказывал — и Claude в результате
делал обвязку руками, сочиняя свой формат frontmatter и нарушая
конвенции `ai-job-searcher`. Back-fill mode закрывает эту дыру:
формат теперь всегда берётся из тех же templates, что и для свежих
проектов, и сочинять нечего.

## v0.3.0 — 2026-05-08

### Changed
- **Backlog как DB**, а не страница. Бэклог в `private/backlog/` —
  один таск = один файл `BL-NN.md` с frontmatter (`id`, `title`,
  `status`, `priority`, `tier`, `created`, `tags`, опц. `closed`,
  `refs`, `blocked_by`). Статусы — только 4 (`open`, `in_progress`,
  `done`, `archived`). Версии (`mvp-0`, `v0.5`, `v1.0`, `v2.0`) —
  через теги.
- Добавлен `templates/base/private/backlog.base.tpl` — Obsidian Bases
  view с готовыми таблицами (Active / Archived / Cards). Юзер
  открывает в Obsidian и видит бэклог как DB.
- Шаблон первого таска переименован: `BL-001-scope-and-mvp.md.tpl` →
  `BL-1.md.tpl`. Имя файла больше не содержит slug, нумерация только
  числовая, заголовок живёт в frontmatter.
- `_README.md` бэклога переписан под новый формат: соглашения по
  frontmatter, статусам, тегам, шаблон нового BL.
- Новые плейсхолдеры: `{{today}}` и `{{project_name}}` (frontmatter-
  friendly алиасы к `{{DATE}}` и `{{PROJECT_NAME}}`).

### Removed
- **Не создаём `BACKLOG.md` в корне проекта.** Roadmap живёт через
  теги в BL-NN.md и view'хи в `backlog.base`.

### Reason
Формат «единый BACKLOG.md как страница со списком задач» плохо
скейлится: невозможно фильтровать, сортировать, видеть за пределами 20
строк. ai-job-searcher уже год живёт с DB-форматом — переносим как
стандарт для всех новых проектов.

## v0.2.0 — 2026-05-08

### Added
- Section "Identity & PII rules" — обязательная для проектов с user data.
  Stripe-style opaque random IDs, identifier vs payload separation,
  PII tagging in schemas, logging hygiene, gitignore-by-default для
  user data, right-to-be-forgotten readiness.
- Question 5 on dialog: «Работа с user data?». Если yes — обязательно
  подключаем extension `multi-user-base`.
- Self-update trigger: `multi-user-base` extension для проектов с
  профильно-пользовательской архитектурой.
- Reference to NIST SP 800-122, GDPR Article 25, Cavoukian PbD
  principles, OWASP Privacy Risks Top 10.

### Reason
AIJobSearcher переделка из прототипа в мульти-юзер обошлась в недели
работы. Закладывать архитектуру и PII-практики нужно с первой строчки.

## v0.1.0 — 2026-05-06

Initial release.

### Added
- Base template: `CLAUDE.md`, `README.md`, `DEVELOPMENT.md`, `CHANGELOG.md`,
  `incidents.md`, `.gitignore`, `.env.example`, `rfc/_README.md`,
  `docs/decisions/_README.md`, `private/backlog/_README.md`,
  `BL-001-scope-and-mvp.md`.
- Extension `node-cli`: Node 20+ scaffold with `node --test`.
- Extension `python-mcp`: Python MCP server skeleton with pytest.
- Self-update triggers documented in `SKILL.md`.
- Self-update feedback loop rule added to `~/.claude/CLAUDE.md`.
- RFC 001 — design doc explaining bootstrap, dialog flow, plumbing
  for extensions and the feedback loop.
