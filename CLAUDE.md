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
- Тонкий SwiftUI-код (связка вью с view-моделью) проверяется руками, логика выносится в чистые тестируемые хелперы; ревью не откладывает отсутствие тестов на такой код отдельным пунктом.
- Ручной проход по приложению (визуальный, VoiceOver, сценарии вроде «долго») делает автор один раз в конце эпика, не на каждую историю. История с ручным AC не блокируется на проход; результат записывается в ретро как «автор сообщил».
- Тема коммита называет историю: `feat(1-4): …`, `test(1-6): …`. Без этого `git_evidence.py` в ретро не привязывает коммиты к историям.
- Автор учит Swift (опыт JS/TS/React Native): после каждой задачи кратко объяснять новые концепции через аналогии с TypeScript/React.

## Процесс (spec-driven, BMAD)
- BMAD 6.12.4 (модули `core` и `bmm`, версия закреплена) ведёт идею → spec → задачи → реализацию. Навыки лежат в `.claude/skills/bmad-*`, конфиг в `_bmad/`, артефакты в `_bmad-output/`.
- Не знаешь, с чего начать: `bmad-help`. Фича: `bmad-prd` → `bmad-ux` / `bmad-architecture` → `bmad-create-epics-and-stories` → `bmad-sprint-planning` → `bmad-build` → `bmad-code-review`. Мелочи: `bmad-spec` + `bmad-build`.
- Superpowers остаётся набором отдельных навыков (TDD, отладка, ревью), но spec и планы пишем через BMAD. Старые спеки лежат в `docs/superpowers/`.
- Обновление BMAD: только осознанно, с пересмотром архива по правилу про сторонний код; внешние модули не ставим.
- Статус эпика (`epic-N` в `sprint-status.yaml`) переключаем в `done` вручную, одной строкой, когда закрыта последняя история или в конце ретро. `sprint_status.py update` ставит только `epic-N-retrospective`, поэтому без этого шага ключ эпика зависает в `in-progress`.
- Личные настройки BMAD (имя, язык) в `_bmad/custom/config.user.toml`, он в `.gitignore`.
- Дорожная карта: `docs/superpowers/specs/2026-11-01-bmad-and-ui-roadmap-design.md`.

## Команды
```bash
swift test --package-path Packages/TimeTrackerCore            # тесты логики
swift test --package-path Packages/TimeTrackerCore --filter X # один набор
xcodegen generate                                             # собрать TimeTracker.xcodeproj из project.yml
xcodebuild -scheme TimeTracker -destination 'platform=macOS' build | xcbeautify
xcodebuild test -scheme TimeTracker -destination 'platform=macOS'  # тесты приложения (App/), Core ими не покрыт
swiftlint
scripts/check-tokens.sh                                    # guard: нет hex/системных цветов/акцента/своих размеров шрифта во всём App/
scripts/test-check-tokens.sh                               # тесты guard на фикстурах
```
Guard сканирует весь `App/`; `scripts/token-guard-paths.txt` содержит одну строку `App`, исключения (слой токенов под `Design/` и `Support/CategoryTone.swift`) заданы в `check-tokens.sh`. Перед каждым коммитом guard запускает pre-commit хук `scripts/git-hooks/pre-commit`; после клона включи его: `git config core.hooksPath scripts/git-hooks`.
Перед тем как закончить UI-задачу, запусти `scripts/check-tokens.sh`. Коды выхода: 0 чисто, 1 нарушения (выводит `файл:строка`), 2 ошибка запуска. После любой правки guard или его паттернов запусти `scripts/test-check-tokens.sh`; новый паттерн сначала добавь в фикстуру и увидь FAIL. `App/Support/CategoryTone.swift` в списке не числится намеренно: его hex это ключи данных.
`TimeTracker.xcodeproj` не коммитится, его генерирует XcodeGen.

## MCP (project-local)
XcodeBuildMCP 2.7.0 (телеметрия Sentry выключена) и apple-docs-mcp 1.0.26, версии зафиксированы.
