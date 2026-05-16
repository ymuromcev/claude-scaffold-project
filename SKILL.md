---
name: scaffold-project
version: 0.4.0
description: |
  Разворачивает скелет нового проекта за один диалог: создаёт CLAUDE.md,
  README, DEVELOPMENT.md, CHANGELOG, incidents.md, rfc/, docs/decisions/,
  private/backlog/ как DB (BL-NN.md + backlog.base для Obsidian Bases) +
  первый BL-1, .gitignore, .env.example. По выбору подключает
  extension-pack под стек (node-cli, python-mcp). Делает git init и
  первый коммит. После этого все следующие задачи в проекте идут через
  скилл dev-workflow.

  Второй режим — back-fill: для проекта, где CLAUDE.md уже есть,
  скилл умеет добавить недостающую дев-обвязку (private/backlog/,
  private/backlog.base, rfc/, incidents.md, CHANGELOG.md) из тех же
  templates, не трогая контент. Существующие файлы не перезаписываются,
  .gitignore только мерджится. См. секцию «Back-fill mode».

  Главная фича — петля обратной связи. При работе в любом проекте, если
  впервые появляется reusable инфра-паттерн (event analytics, auth,
  error tracking, payments, CI, secret-guard, feature flags, db
  migrations) — Claude обязан до коммита предложить вынести его как
  extension-pack для будущих проектов.

  Trigger when (новый проект): «новый проект», «начинаем новый проект»,
  «init project», «scaffold проект», «развернуть проект», «создать
  новый проект», «новый подпроект», «start a new project», «scaffold X»,
  или явный /scaffold-project.

  Trigger when (back-fill в существующем проекте): «причеши проект»,
  «оформи как dev-проект», «back-fill бэклог», «добавь дев-обвязку»,
  «back-fill scaffolding», или /scaffold-project --backfill.

  Также скилл срабатывает обратной стороной — при первом появлении в
  проекте инфра-паттерна, который должен стать extension-pack'ом
  (см. секцию Self-update triggers).
license: MIT
compatibility: claude-code
allowed-tools:
  - Read
  - Write
  - Edit
  - Bash
  - Grep
  - Glob
  - TodoWrite
---

# scaffold-project — bootstrap нового проекта

Когда пользователь говорит «новый проект» — этот скилл разворачивает
полный скелет за один диалог. После scaffold все задачи в проекте идут
через `dev-workflow`.

## Шаг 0 — определить режим

Скилл различает три режима по триггер-фразе пользователя:

| Триггер | Режим |
|---|---|
| «новый проект», «init project», «scaffold проект», «развернуть проект», и т.п. | **fresh / extension** (Шаги 1–5 ниже) |
| «причеши проект», «оформи как dev-проект», «back-fill бэклог», «добавь дев-обвязку», `/scaffold-project --backfill` | **back-fill** (секция «Back-fill mode» — пропускаем Шаги 1–5, идём туда) |

Если триггер двусмысленный (например, просто `/scaffold-project` в каталоге с `CLAUDE.md`) — спросить пользователя один раз: «у проекта уже есть `CLAUDE.md`. Это fresh-init где-то ещё, или back-fill сюда?».

## Шаг 1 — pre-checks (fresh / extension режим)

Перед стартом скилл проверяет целевой каталог:

| Состояние | Действие |
|---|---|
| Каталог не существует / пустой | Продолжаем (mkdir создаст). |
| Не пуст, нет `CLAUDE.md`/`package.json`/`pyproject.toml` | Продолжаем, но предупреждаем «каталог не пуст, продолжить?». |
| Есть `package.json` или `pyproject.toml` без `CLAUDE.md` | Предлагаем **extension mode**: добавить недостающие base-файлы, не трогая существующее. |
| Есть `CLAUDE.md` | Отказ + подсказка: «проект уже инициализирован. Если хочешь добавить недостающую дев-обвязку — скажи `back-fill` или `причеши проект` (см. секцию Back-fill mode)». |

## Шаг 2 — диалог

Скилл задаёт **пять** вопросов. Не больше, не меньше.

1. **Имя проекта** (kebab-case). Валидация: `^[a-z][a-z0-9-]{1,40}$`.
   Не проходит — спрашиваем заново.
2. **Однострочное описание** — 1 предложение, чем проект полезен.
   Если пользователь хочет дать развёрнутый scope — приветствуется,
   уйдёт в `{{SCOPE_DESCRIPTION}}` as-is.
3. **Стек**:
   - `node-cli` — Node 20+ CLI или библиотека, тесты через `node --test`.
   - `python-mcp` — Python MCP-сервер или скрипт, тесты через `pytest`.
   - `both` — оба extension'а.
   - `none` — только base, никакого языкового скелета.
4. **Внешние сервисы, которые предполагаются сразу** (Notion / Gmail /
   Stripe / Sentry / другое). Список справочный — попадёт в
   `.env.example` и в комментарий к BL-001. Если ничего — `none`.
5. **Работа с user data?** — `yes` / `no`. Это любые
   пользовательские данные: профили, контент пользователя, сообщения,
   email/telegram-чаты, транзакции. Если `yes` — обязательно подключаем
   extension `multi-user-base` (см. секцию «Identity & PII rules»).
   Это не «потом докрутим» — потом стоит недели работы.

## Шаг 3 — preview + approve

Перед записью — плоский список файлов, которые скилл создаст:

```
<project-root>/
├── CLAUDE.md
├── README.md
├── DEVELOPMENT.md
├── CHANGELOG.md
├── incidents.md
├── .gitignore
├── .env.example
├── rfc/_README.md
├── docs/decisions/_README.md
├── private/backlog.base                  # Obsidian Bases view
├── private/backlog/_README.md            # конвенции: frontmatter, статусы, теги версий
├── private/backlog/BL-1.md               # первый таск (scaffold), in_progress
├── package.json                          (если node-cli)
├── engine/index.js                       (если node-cli)
├── engine/index.test.js                  (если node-cli)
├── pyproject.toml                        (если python-mcp)
├── server.py                             (если python-mcp)
└── tests/test_smoke.py                   (если python-mcp)
```

**Жду явного «ok» от пользователя.**

## Шаг 4 — запись

По approve:

0. **Pre-flight check.** До любых mkdir / write:
   - `git --version` отвечает (git установлен).
   - `git config --get user.name` и `git config --get user.email` оба
     возвращают значение.
   Если что-то из этого не выполнено — отказ с понятным сообщением
   («настрой `git config --global user.email …` и попробуй заново»).
   **Никаких файлов не создаём, пока pre-flight красный** — иначе
   получим скаффолд без коммита и тупик в следующем запуске («есть
   CLAUDE.md, отказ»).
1. `mkdir -p <project-root>` если не существует. Запомним флаг
   `created_root = (true | false)` — пригодится для отката.
2. Для каждого файла из `templates/base/` (и выбранных
   `templates/extensions/<name>/`):
   - читаем шаблон,
   - подменяем плейсхолдеры (см. ниже),
   - пишем в `<project-root>/<relative-path>` без `.tpl` в имени.
   - **исключение**: файл `README.md` в корне каждого
     `templates/extensions/<name>/` — это документация самого extension'а
     (для скилла, не для проекта). Не копируется в проект.
   - запоминаем список **записанных файлов** (`created_files[]`) —
     для отката.
3. Sanity-check: `grep -l '{{' <created_files[]>` (только по
   только-что-записанным файлам, не по всему каталогу — иначе ловим
   ложные срабатывания на `_README.md`-примерах). Если что-то
   осталось — error и **откат**:
   - **fresh-mode** (`created_root = true`): `rm -rf` всего каталога.
   - **extension-mode** (`created_root = false`): удаляем только
     `created_files[]`, не трогая ничего другого. **Никогда не
     удаляем целиком чужой каталог.**
4. `cd <project-root>` → `git init` → `git add .` →
   `git commit -m "scaffold from scaffold-project v{{SCAFFOLD_VERSION}}"`.
5. Спросить про push в origin (по правилу из workspace-CLAUDE.md
   «после каждого коммита спрашивать про push»). Если remote ещё нет —
   предложить `gh repo create` (с подтверждением).

## Плейсхолдеры

| Плейсхолдер | Источник |
|---|---|
| `{{PROJECT_NAME}}` | ответ пользователя |
| `{{PROJECT_NAME_UPPER}}` | UPPER_SNAKE_CASE из имени (`-` → `_`) |
| `{{SHORT_DESCRIPTION}}` | ответ на вопрос 2, первое предложение |
| `{{SCOPE_DESCRIPTION}}` | ответ на вопрос 2 целиком (или то же, что short) |
| `{{STACK}}` | human-readable mapping: `node-cli` → `Node.js 20+ (CLI / library)`, `python-mcp` → `Python 3.11+ (MCP server)`, `both` → `Node.js 20+ + Python 3.11+`, `none` → `TBD — choose during BL-001` |
| `{{DATE}}` | сегодняшняя дата `YYYY-MM-DD` |
| `{{AUTHOR}}` | `git config user.name`, или `unknown` |
| `{{SCAFFOLD_VERSION}}` | версия скилла из его `CHANGELOG.md` |
| `{{EXTERNAL_SERVICES}}` | ответ на вопрос 4, или `none` |
| `{{today}}` | сегодняшняя дата `YYYY-MM-DD` (alias к `{{DATE}}` для frontmatter) |
| `{{project_name}}` | то же что `{{PROJECT_NAME}}` (alias для frontmatter-шаблонов) |

Подмена — простой текстовый replaceAll по содержимому файла.

## Шаг 5 — после scaffold

После первого коммита Claude:

1. Резюмирует что создано (файлы, какие extensions подключены).
2. Указывает на `private/backlog/BL-1.md` как первую задачу
   (`in_progress`, scaffold). Открыть `private/backlog.base` в Obsidian
   — увидишь backlog как таблицу с view'ми Active / Archived / Cards.
3. Напоминает: «дальше работаем через `dev-workflow`. Все M/L задачи —
   через RFC, тесты, code-review».

## Back-fill mode — добавить дев-обвязку в существующий проект

Режим для проектов, у которых уже есть `CLAUDE.md` и свой контент, но
нет (или есть не вся) дев-обвязка: `private/backlog/`, `backlog.base`,
`rfc/`, `incidents.md`, `CHANGELOG.md`. Скилл добавляет недостающее
**из тех же `templates/base/`**, чтобы формат был один к одному с тем,
что получают свежие проекты.

**Зачем:** раньше Claude в таких проектах делал обвязку руками, сочинял
собственные поля в frontmatter, нарушал конвенции и потом приходилось
переделывать. Back-fill mode закрывает эту дыру — формат всегда из
templates, ничего не сочиняется.

### Когда триггерится

- Триггер-фраза: «причеши проект», «оформи как dev-проект»,
  «back-fill бэклог», «добавь дев-обвязку», `/scaffold-project --backfill`.
- Каталог: `CLAUDE.md` уже существует (иначе это fresh-init, не back-fill).

### Что back-fill делает (scope)

| Файл шаблона | Действие |
|---|---|
| `templates/base/CHANGELOG.md.tpl` | добавить если нет |
| `templates/base/incidents.md.tpl` | добавить если нет |
| `templates/base/rfc/_README.md` | добавить если `rfc/_README.md` нет |
| `templates/base/docs/decisions/_README.md` | добавить если нет (опционально, спросить) |
| `templates/base/private/backlog/_README.md` | добавить если `private/backlog/_README.md` нет |
| `templates/base/private/backlog.base.tpl` | добавить если `private/backlog.base` нет |
| `templates/base/.gitignore.tpl` | **merge**: если в существующем `.gitignore` нет правила, закрывающего `private/` — append блок про private и Obsidian. Иначе не трогать. |

### Что back-fill НЕ делает (out of scope)

- **Не перезаписывает** существующие `CLAUDE.md`, `README.md`,
  `DEVELOPMENT.md`, `.env.example`, `CHANGELOG.md`, `incidents.md`,
  `.gitignore` — только добавляет недостающие или мерджит `.gitignore`.
- **Не создаёт BL-1.** В fresh-mode `BL-1` — это «задача scaffold».
  В back-fill у проекта уже есть свой backlog и/или своя первая
  задача — навязывать наш не нужно.
- **Не мигрирует** существующий `BACKLOG.md` или `tasks/` в формат
  `private/backlog/BL-NN.md`. Если найден `BACKLOG.md` — скилл скажет
  «найден старый формат, миграция руками или отдельной задачей,
  back-fill не трогает».
- **Не нормализует frontmatter** существующих `BL-NN.md`. Если в них
  не-каноничные поля (`area`, `type`, статусы вроде `wip`/`backlog`) —
  скилл предупреждает, но не правит. Это отдельная задача (см.
  `dev-workflow groom`).
- **Не подключает stack-extensions** (`node-cli`, `python-mcp`) — у
  существующего проекта стек свой.
- **Не делает `git init`** — проект уже git.

### Алгоритм

1. **Pre-check.** Убедиться, что `CLAUDE.md` существует в cwd. Если
   нет — отказ «back-fill применяется в существующем проекте, а здесь
   нет CLAUDE.md. Если хотел fresh-init — скажи "новый проект"».

2. **Сканирование.** Для каждого пункта из таблицы scope выше — проверить
   target. Собрать checklist:
   - ✓ файл присутствует (для backlog — проверить что есть хотя бы
     `_README.md` или `BL-*.md`);
   - `+` файл отсутствует, будем добавлять;
   - `~` файл существует, но требуется merge (`.gitignore`);
   - `⚠` файл существует, но в нём подозрительные несоответствия (см.
     ниже) — не трогаем, флагуем пользователю.

   Дополнительные проверки:
   - `private/backlog/BL-*.md` существуют → прочитать frontmatter первого
     попавшегося. Если поля отличаются от каноничных (например, есть
     `area`/`type`/`updated`/`related` или статус не из набора
     `open|in_progress|done|archived`) — `⚠` с пояснением.
   - В корне есть `BACKLOG.md` → `⚠` «старый формат, миграция вручную».

3. **Render checklist** пользователю. Пример:
   ```
   Back-fill сканер по <project-root>:
     ✓ CHANGELOG.md
     ✓ incidents.md
     ✓ rfc/_README.md
     + docs/decisions/_README.md
     ✓ private/backlog/_README.md
     ✓ private/backlog.base
     ~ .gitignore (добавить блок про private/)
     ⚠ private/backlog/BL-3.md содержит поле `area:` (не в каноне) — не трогаю
   ```

4. **Если все строки `✓`** — вывести «всё уже на месте, ничего делать
   не надо» и завершиться. Никаких записей, никаких коммитов.

5. **Иначе — preview.** Показать ровно те файлы, которые будут записаны
   (`+`) или смерджены (`~`). Никаких других файлов в preview быть не
   должно.

6. **Один вопрос approve**: «добавить?» — yes / no.

7. **На yes:**
   - `mkdir -p` для родительских каталогов под новые файлы.
   - Для каждого `+`: прочитать шаблон, подменить плейсхолдеры,
     записать. Запомнить в `created_files[]`.
   - Для `~` `.gitignore`: прочитать существующий → если каких-то
     строк из шаблона нет, дописать в конец отдельным блоком с
     комментарием `# Added by scaffold-project back-fill v{{SCAFFOLD_VERSION}}`.
     **Никогда не удалять и не переупорядочивать существующие строки.**
   - Sanity-check: `grep -l '{{' <created_files[]>` — если остатки
     плейсхолдеров, error и **откат только `created_files[]`** (не
     трогать ничего другого в каталоге).

8. **Git.** `git add` только тех файлов, которые попадают в git (не
   `private/`, потому что он gitignored). Предложить коммит-сообщение:
   ```
   chore: back-fill dev scaffolding via scaffold-project v{{SCAFFOLD_VERSION}}
   ```
   **Не коммитим без явного approve пользователя** (правило из global
   CLAUDE.md).

### Плейсхолдеры в back-fill

Только те, что встречаются в файлах из scope:
- `{{SCAFFOLD_VERSION}}` — версия скилла из его `CHANGELOG.md`.
- `{{DATE}}` — сегодня `YYYY-MM-DD`.
- `{{PROJECT_NAME}}` — `basename` cwd (как fallback, если в файле
  плейсхолдер встретится; в текущих шаблонах back-fill scope его нет).

### Edge cases

- **Каталог не git-репозиторий** → выполнить back-fill, но не предлагать
  `git add`/коммит. Сказать «это не git-репо, инициализируй git руками,
  если хочешь».
- **Есть `CLAUDE.md`, но нет любого другого индикатора проекта (только
  пустой CLAUDE.md)** → продолжить back-fill, это валидный случай.
- **Пользователь сказал «новый проект» в каталоге с CLAUDE.md** →
  отказ + подсказка про back-fill (см. Шаг 1).
- **Пользователь сказал «back-fill» в пустом каталоге** → отказ «здесь
  нет CLAUDE.md, ты, видимо, хотел fresh-init. Скажи "новый проект"».

## Self-update triggers — петля обратной связи

Когда пользователь работает **внутри проекта**, созданного через
scaffold-project (или живущего по тем же конвенциям), и впервые
появляется один из паттернов ниже — **до коммита** Claude **обязан**
сказать:

> «Это первый раз, когда мы делаем X в этом проекте. Хочешь, я вынесу
> обвязку в `~/.claude/skills/scaffold-project/templates/extensions/<name>/`,
> чтобы следующие проекты получали её сразу?»

| Триггер | Имя extension'а |
|---|---|
| Профильно-пользовательская архитектура (multi-user, identity, PII разделение) | `multi-user-base` |
| Подключение event analytics (PostHog/Amplitude/Mixpanel/GA4) | `ui-analytics` |
| Подключение error tracking (Sentry/Bugsnag/Rollbar) | `error-tracking` |
| Auth-флоу (OAuth/Clerk/Supabase Auth/Auth0) | `auth` |
| Платежи (Stripe/Paddle/LemonSqueezy) | `payments` |
| Первый GitHub Actions workflow | `ci-github` |
| Pre-commit secret-guard, написанный руками | `secret-guard` |
| Feature flags (GrowthBook/LaunchDarkly/Unleash) | `feature-flags` |
| DB migrations (Prisma/Alembic/Knex) | `db-migrations` |
| Dockerfile + deploy-config (Fly/Railway/Render) | `deploy-saas` |
| UI SPA scaffold (React/Vue/Svelte) | `ui-spa` |
| MCP server в Node | `mcp-node` |

**Решение принимает пользователь.** Если «не сейчас» — в этом же
проекте Claude больше не спрашивает про этот паттерн (на текущую
сессию). В другом проекте — спросит снова.

### Как добавить новый extension (по approve пользователя)

1. Создать каталог
   `~/.claude/skills/scaffold-project/templates/extensions/<name>/`.
2. Положить туда файлы паттерна с плейсхолдерами вместо
   project-specific значений (имена, токены, URL, продакт-named
   константы).
3. Добавить короткий `README.md` в самом extension'е: что включает,
   когда подключать, какие env-vars ждёт, как тестировать локально.
4. Обновить `CHANGELOG.md` скилла: новая запись «extension `<name>`
   added» с датой и кратким резюме.
5. Обновить таблицу выше (триггер → имя extension'а), если паттерн
   новый.
6. Обновить Шаг 2 / вопрос про стек, если extension может быть
   подключён на старте проекта (а не только инкрементально).
7. Если extension должен подсказывать threat-model в RFC (для auth,
   payments, secret-guard) — упомянуть это в его README.

После этого вынос в текущем проекте идёт как обычно: код в проекте
коммитится, а его обобщённая копия живёт в скилле.

## Backlog как DB (Obsidian Bases)

С v0.3.0 бэклог скаффолдится как **база**, а не как страница.

- Один таск = один файл `BL-NN.md` (только номер, без слага в имени).
- В каждом — frontmatter: `id`, `title`, `status`, `priority`, `tier`, `created`, `tags` (опц. `closed`, `refs`, `blocked_by`).
- Статусы — **только** 4: `open`, `in_progress`, `done`, `archived`.
- Версии (`mvp-0`, `v0.5`, `v1.0`, `v2.0`) — через теги, не отдельные поля.
- `private/backlog.base` — Obsidian Bases view с готовыми таблицами (Active / Archived / Cards). Юзер открывает в Obsidian и видит всё как DB.

Конвенции расписаны в `templates/base/private/backlog/_README.md`. Шаблон первого таска — в `BL-1.md.tpl`. Правило: **не создавать единый `BACKLOG.md`** в корне проекта — все таски только в `private/backlog/`.

## Identity & PII rules (обязательно для проектов с user data)

Когда проект работает с данными пользователей (профили, контент,
сообщения, любая user-generated information) — следующие правила
применяются **с первой строчки кода**. Это не «потом докрутим».

База: NIST SP 800-122 (US guide on PII protection), GDPR Article 25
(Privacy by Design), Cavoukian's 7 PbD principles, OWASP Privacy Risks
Top 10.

### ID generation

- **Формат**: `<type-prefix>_<crypto-random base32, 12+ chars>`. Примеры:
  `prof_a7k2m9pq3x4y`, `usr_b3n5p8qr2t6w`, `card_c9j7f2k4l8m1`.
  Stripe-style — индустриальный стандарт.
- **Источник random**: криптографически безопасный (`secrets.token_bytes`
  в Python, `crypto.randomBytes` в Node, библиотеки `nanoid`/`uuid`).
  **Никогда** `Math.random()`.
- **Внутренний primary key (если БД)**: UUID v7 или ULID — sortable по
  времени, дружат с DB-индексами.

**Что запрещено:**
- Имя / email / телефон / любые PII в ID, пути, имени файла, JSON-ключе,
  URL-параметре.
- Sequential integers как public-facing ID (выдают масштаб, предсказуемы).
- Hash от PII как ID (rainbow table откатывает).
- Переиспользование ID после удаления сущности.

### PII handling

| Правило | Реализация |
|---|---|
| **Identifier ≠ Payload** | ID — это ID. PII (display_name, email, identities) — отдельное поле/файл/колонка. |
| **PII tagging в schema** | В schemas (YAML/JSON Schema/Pydantic) каждое поле размечено: `pii_class: non-pii / pii / sensitive`. |
| **Pseudonymization in logs** | Логи всегда оперируют ID, никогда именами/email. Структурированный логгер с redaction (`structlog`/`pino`). |
| **Data minimization** | Не собирать поля, которые не нужны. Не нужен email — не спрашиваем. |
| **PII out of git** | Папка с user data (`profiles/`, `data/`) гитнорится by default. В коммит едут только schemas, конвенции, `_README.md`. |
| **Right to be forgotten** | Архитектура поддерживает hard delete с первого дня (даже если фича не used). Schema резервирует поле под crypto-shredding. |
| **Secrets отдельно от данных** | `connections/` или `.env` — двойной gitignore guard, никаких токенов в profile.yaml. Локально — OS keychain (`keyring`/`keytar`), в проде — vault. |

### Multi-user-ready архитектура (extension `multi-user-base`)

Если на Шаге 2 ответ «yes» по user data — раскатываем структуру:

```
<project>/
├── core/                    # engine: profile-agnostic код, схемы
│   ├── lib/id.py            # генератор Stripe-style ID
│   └── schemas/             # YAML/JSON schemas с PII-tagging
├── shared/                  # common baseline (правила, шаблоны)
├── profiles/                # gitignored по дефолту
│   ├── .gitignore           # ignore *, кроме _README.md и .gitignore
│   ├── _README.md           # как добавить профиль (генерация ID + scaffold)
│   └── prof_<random>/       # данные одного профиля
│       ├── profile.yaml
│       ├── connections/     # двойной gitignore
│       └── ...
└── .config/active-profile   # gitignored, локально хранит ID активного профиля
```

При SaaS-пивоте `profiles/` заменяется на DB-lookup через ту же
абстракцию `loadProfile(id)` / `saveCard(profile, card)`. Engine код
остаётся.

### Pre-commit secret-guard

Для проектов с user data — `gitleaks` или `trufflehog` как pre-commit
хук с первого дня. Ловит токены, ключи, PII-паттерны, которые могут
случайно утечь в коммит.

## Edge cases

- **Пустой `package.json`/`pyproject.toml`** в каталоге → extension
  mode, diff, approve.
- **Уже инициализирован через scaffold** (`CLAUDE.md` существует) →
  отказ. Миграция — отдельная задача, не в scope.
- **Версия шаблона старее текущей** → отказ, показ diff'а изменений с
  прошлой версии.
- **`git init` падает** (нет git, нет user.name/user.email) → понятное
  сообщение, каталог оставляем как есть, без коммита.
- **Имя проекта не валидно** → просим ввести заново.
- **Остатки `{{...}}` в выходных файлах** → error, откат каталога если
  мы его создали.
- **Пользователь отвечает «не сейчас»** на self-update предложение →
  не повторяем для того же паттерна в этой же сессии.

## Когда скилл НЕ применяется

- Внутри уже существующего проекта без явного запроса «init» или
  «back-fill» — там работает `dev-workflow`.
- Продакт-задачи, тексты, оформление гипотез.
- Миграция контента (старый `BACKLOG.md` → `private/backlog/BL-NN.md`,
  переписывание frontmatter существующих BL под канон) — отдельная
  задача. Back-fill только добавляет недостающее, не нормализует
  существующее.

## Версионирование

Версия скилла — в его `CHANGELOG.md` и во всех файлах через
`{{SCAFFOLD_VERSION}}`. Бамп версии — при любом изменении шаблонов
или процесса диалога.
