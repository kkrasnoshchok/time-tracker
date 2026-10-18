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

## Команды
```bash
swift test --package-path Packages/TimeTrackerCore            # тесты логики
swift test --package-path Packages/TimeTrackerCore --filter X # один набор
xcodegen generate                                             # собрать TimeTracker.xcodeproj из project.yml
xcodebuild -scheme TimeTracker -destination 'platform=macOS' build | xcbeautify
swiftlint
```
`TimeTracker.xcodeproj` не коммитится, его генерирует XcodeGen.

## MCP (project-local)
XcodeBuildMCP 2.7.0 (телеметрия Sentry выключена) и apple-docs-mcp 1.0.26, версии зафиксированы.
