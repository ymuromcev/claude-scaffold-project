---
id: BL-1
title: "Scaffold проекта {{project_name}}"
status: in_progress
priority: P0
tier: M
created: {{today}}
refs: []
tags: [mvp-0, infra]
---

## Context

Развернуть скелет проекта `{{project_name}}/` так, чтобы можно было открыть в Obsidian, увидеть BL-базу через `backlog.base`, прочитать `CLAUDE.md` и ADR 001 (если есть user data) и понять, куда копать дальше.

## Plan

- [ ] Базовые файлы: `CLAUDE.md`, `README.md`, `DEVELOPMENT.md`, `CHANGELOG.md`, `incidents.md`, `.gitignore`, `.env.example`.
- [ ] (если применимо) ADR `docs/decisions/001-multi-user-architecture.md` — Identity, PII, Storage abstraction.
- [ ] (если multi-user) `core/_README.md`, `shared/_README.md`, `profiles/.gitignore` + `_README.md`.
- [ ] Backlog как DB: `private/backlog/BL-NN.md` + `private/backlog.base`.
- [ ] Pre-commit secret-guard: `.githooks/pre-commit` с `gitleaks` (warning-only).
- [ ] Первый коммит — после явного approve пользователя.

## Definition of Done

- Все базовые файлы созданы и читаются в Obsidian.
- Backlog видится как таблица в `backlog.base`.
- (если есть user data) ADR 001 фиксирует архитектурные решения.
- (если multi-user) `profiles/` гитнорится корректно.
- `gitleaks` pre-commit хук установлен.
- Первый коммит сделан с approve.

## Notes

BL-1 — сам scaffold, RFC отдельный не пишется (вся «дизайн-доковая» работа — в ADR 001).
