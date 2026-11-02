# Time Tracker (macOS)

Личный трекер времени: SwiftUI-приложение в menu bar + Dock, хоткей-палитра, SwiftData, экспорт CSV/SQLite.
Дизайн: `docs/application-design.md`. План: `docs/superpowers/plans/2026-10-18-time-tracker-v1.md`.

## Правила
- Swift 6 (язык Swift 6, строгая конкурентность), Xcode 27, macOS 26+. Бэкенда нет.
- Вся логика в пакете `Packages/TimeTrackerCore`; приложение (`App/`) только отображает состояние view-моделей. UI без бизнес-логики.
- TDD обязателен: сначала падающий тест (увидеть FAIL), потом код. Тесты проверяют поведение, без `sleep` и реального времени.
- «Сейчас» всегда через `TimeProvider`, `Date()` в логике запрещён. Время хранится в UTC.
- Идёт ли таймер, определяет только `end == nil`; одновременно не больше одной такой записи.
- Модели совместимы с CloudKit: значения по умолчанию, опциональные связи, без `@Attribute(.unique)`.
- Сторонний код (MCP, skills, пакеты) подключается после ручной проверки (cc-audit даёт много ложных срабатываний, на него не полагаться).
- Автор учит Swift (опыт JS/TS/React Native): после каждой задачи кратко объяснять новые концепции через аналогии с TypeScript/React.

## Процесс (spec-driven, BMAD)
- BMAD 6.12.4 (модули `core` и `bmm`, версия закреплена) ведёт идею → spec → задачи → реализацию. Навыки лежат в `.claude/skills/bmad-*`, конфиг в `_bmad/`, артефакты в `_bmad-output/`.
- Не знаешь, с чего начать: `bmad-help`. Фича: `bmad-prd` → `bmad-ux` / `bmad-architecture` → `bmad-create-epics-and-stories` → `bmad-sprint-planning` → `bmad-build` → `bmad-code-review`. Мелочи: `bmad-spec` + `bmad-build`.
- Superpowers остаётся набором отдельных навыков (TDD, отладка, ревью), но spec и планы пишем через BMAD. Старые спеки лежат в `docs/superpowers/`.
- Обновление BMAD: только осознанно, с пересмотром архива по правилу про сторонний код; внешние модули не ставим.
- Личные настройки BMAD (имя, язык) в `_bmad/custom/config.user.toml`, он в `.gitignore`.
- Дорожная карта: `docs/superpowers/specs/2026-11-01-bmad-and-ui-roadmap-design.md`.

## Команды
```bash
swift test --package-path Packages/TimeTrackerCore            # тесты логики
swift test --package-path Packages/TimeTrackerCore --filter X # один набор
xcodegen generate                                             # собрать TimeTracker.xcodeproj из project.yml
xcodebuild -scheme TimeTracker -destination 'platform=macOS' build | xcbeautify
swiftlint
scripts/check-tokens.sh                                    # guard: нет hex/.red/системного акцента/своих размеров шрифта в мигрированных файлах
scripts/test-check-tokens.sh                               # тесты guard на фикстурах
```
Список мигрированных путей для guard лежит в `scripts/token-guard-paths.txt` (по одному пути в строке); каждый следующий эпик добавляет туда свои файлы.
`TimeTracker.xcodeproj` не коммитится, его генерирует XcodeGen.

## MCP (project-local)
XcodeBuildMCP 2.7.0 (телеметрия Sentry выключена) и apple-docs-mcp 1.0.26, версии зафиксированы.
