# Time Tracker v1 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Нативное macOS-приложение: старт и стоп записей по глобальному хоткею через окно-палитру, ручное добавление и правка записей, категории и теги, Журнал, экспорт в CSV и SQLite.

**Architecture:** Вся логика живёт в локальном Swift Package `TimeTrackerCore` (Domain, PaletteParser, Store поверх SwiftData, view-модели, экспорт) и тестируется командой `swift test` без запуска UI. Приложение `TimeTracker` (SwiftUI, генерируется XcodeGen) тонкое: окна, menu bar и `NSPanel` только отображают состояние view-моделей.

**Tech Stack:** Swift 6.4 (язык Swift 6, строгая конкурентность), SwiftUI, SwiftData, Swift Testing, XcodeGen, SwiftLint, KeyboardShortcuts (только в app-таргете).

**Spec:** `docs/application-design.md`

## Global Constraints

- Xcode 27.0 (27A266a), Swift 6.4, язык Swift 6 со строгой конкурентностью (`swiftLanguageModes: [.v6]`), деплой-таргет macOS 26.0.
- Бэкенда нет, данные только локально (SwiftData).
- Время хранится в UTC (`Date`), показывается в локальной зоне; «сейчас» всегда приходит через `TimeProvider`, `Date()` в логике запрещён.
- Идёт ли таймер, определяется только `end == nil`; одновременно не больше одной такой записи.
- У записи ровно одна категория (проверяет Store), тегов 0 или больше, `title` и `notes` необязательны.
- Модели совместимы с CloudKit: значения по умолчанию у всех полей, опциональные связи, без `@Attribute(.unique)`; уникальность имён проверяет Store без учёта регистра.
- Колонки экспорта строго: `start`, `end`, `duration_seconds`, `category`, `tags`, `title`, `notes`.
- Суффикс палитры `-20m` означает «запуск 20 минут назад»; формат ввода `Категория название #тег #тег [-20m]`.
- UI не содержит бизнес-логики; он общается только со Store и view-моделями.
- TDD: каждый тест сначала виден упавшим (шаг «Run: FAIL» обязателен), потом код. Тесты проверяют поведение, не реализацию, без `sleep` и реального времени.
- Сторонний код (MCP, skills, пакеты) подключается только после прогона cc-audit и ручного просмотра.
- **Режим обучения:** автор учит Swift, опыт у него в JS/TS/React Native. После каждой задачи исполнитель в 3-5 строках объясняет новые Swift-концепции через аналогии с TypeScript/React (раздел «Swift для JS-разработчика» в задаче) и показывает, где это в коде.

## Review Focus

Случаи, которые спецификация подразумевает, но обычные тесты их не поймают (каждый закреплён тестом в указанной задаче):

1. Старт с `-20m`, когда уже идёт таймер: предыдущий должен закончиться в новый `start`, а если новый `start` раньше начала текущего, должна быть ошибка, а не отрицательная длительность (Задача 4).
2. Запись через полночь и переход на летнее время: сумма по дню считается по границам дня, длительность не теряет и не добавляет час (Задача 6).
3. Системные часы ушли назад: остановка таймера не даёт `end < start` (Задача 4).
4. CSV: запятые, кавычки, переводы строк в `title`/`notes` и значения, начинающиеся с `=`, `+`, `-`, `@` (формульная инъекция при открытии в Excel) (Задача 7).
5. Странный ввод палитры: только `#тег`, только `-20m`, лишние пробелы, юникод и эмодзи, категория из двух слов («Deep Work»), регистр, дубликаты тегов (Задача 2).

Дополнительно, обычным тестом в Задаче 4: запущенный таймер переживает пересоздание контейнера (перезапуск приложения) и остаётся запущенным.

---

### Task 0: Каркас проекта и инструменты

**Files:**
- Create: `.gitignore`, `CLAUDE.md`, `project.yml`, `.swiftlint.yml`
- Create: `Packages/TimeTrackerCore/Package.swift`, `Packages/TimeTrackerCore/Sources/TimeTrackerCore/Placeholder.swift`
- Create: `Packages/TimeTrackerCore/Tests/TimeTrackerCoreTests/SmokeTests.swift`
- Create: `App/TimeTrackerApp.swift`
- Modify: `docs/application-design.md` (разделы 3 и 7, см. ниже)

**Interfaces:**
- Produces: package `TimeTrackerCore` (library target `TimeTrackerCore`, test target `TimeTrackerCoreTests`); app-схема `TimeTracker`, генерируемая из `project.yml`.

- [ ] **Step 1: Установить инструменты** (вручную, команды выполняет автор): `brew install xcodegen swiftlint xcbeautify`, затем cc-audit по инструкции из его README и подключение XcodeBuildMCP и apple-docs-mcp после прогона cc-audit. Проверка: `xcodegen --version && swiftlint --version && xcbeautify --version`.
- [ ] **Step 2: Написать падающий смоук-тест** `SmokeTests.swift`: `@Test func packageLoads() { #expect(TimeTrackerCore.version == "0.1.0") }`.
- [ ] **Step 3: Run** `swift test --package-path Packages/TimeTrackerCore`. Expected: FAIL (`version` не определён).
- [ ] **Step 4: Создать package** (swift-tools-version 6.2, `platforms: [.macOS(.v26)]`, язык Swift 6) и `public enum TimeTrackerCore { public static let version = "0.1.0" }` в `Placeholder.swift`.
- [ ] **Step 5: Создать `project.yml`** (приложение `TimeTracker`, bundle id `dev.hesoyam.TimeTracker`, зависимость от локального пакета, `LSUIElement` не задаём: иконка в Dock остаётся) и минимальный `App/TimeTrackerApp.swift` с `@main` приложением, показывающим пустое окно.
- [ ] **Step 6: Создать `CLAUDE.md`** (правила из Global Constraints, команды сборки и тестов) и `.swiftlint.yml` (дефолты плюс `line_length: 120`).
- [ ] **Step 7: Run** `swift test --package-path Packages/TimeTrackerCore`. Expected: PASS. Затем `xcodegen generate && xcodebuild -scheme TimeTracker -destination 'platform=macOS' build | xcbeautify`. Expected: `BUILD SUCCEEDED`. И `swiftlint`: 0 нарушений.
- [ ] **Step 8: Обновить спецификацию.** В §3 заменить «Domain: модели и правила» на «Domain: значимые типы и чистые правила, SwiftData-модели в Store»; в §7 заменить «копия SQLite-файла» на «SQLite-файл с таблицей `entries` тех же колонок».
- [ ] **Step 9: Commit** `git add -A && git commit -m "chore: project scaffold (package, XcodeGen, lint, CLAUDE.md)"`.

**Swift для JS-разработчика:** Swift Package = `package.json` + workspace-пакет (`Package.swift` вместо JSON), `swift test` = `npm test`, `@main` = точка входа. XcodeGen: `project.yml` играет роль конфига вместо бинарного `.xcodeproj`.

---

### Task 1: TimeProvider и TimeSpan (правила пересечений)

**Files:**
- Create: `Packages/TimeTrackerCore/Sources/TimeTrackerCore/Domain/TimeProvider.swift`, `.../Domain/TimeSpan.swift`
- Test: `Packages/TimeTrackerCore/Tests/TimeTrackerCoreTests/TimeSpanTests.swift`, `.../Support/TestTimeProvider.swift`

**Interfaces:**
- Produces:
  - `public protocol TimeProvider: Sendable { func now() -> Date }`, `public struct SystemTimeProvider: TimeProvider`.
  - Тестовый хелпер `TestTimeProvider` (final class, меняемое `current: Date`) в тестовом таргете.
  - `public struct TimeSpan: Equatable, Sendable { public let start: Date; public let end: Date?; public init(start: Date, end: Date?) throws(TimeSpanError) }`
  - `public enum TimeSpanError: Error, Equatable { case endBeforeStart }`
  - `public func overlaps(_ other: TimeSpan, now: Date) -> Bool` и `public func duration(now: Date) -> TimeInterval`.

- [ ] **Step 1: Тесты** (имена и проверки): `endBeforeStartThrows` (end раньше start бросает `.endBeforeStart`); `zeroLengthSpanIsValid`; `touchingSpansDoNotOverlap` (A 10:00-11:00, B 11:00-12:00 → false в обе стороны); `partialOverlap` (10:00-11:30 и 11:00-12:00 → true); `containedSpanOverlaps`; `openSpanTreatsNowAsEnd` (open с 10:00, now 10:30, другой 10:15-10:20 → true; другой 11:00-12:00 → false); `durationOfOpenSpanUsesNow`.
- [ ] **Step 2: Run** `swift test --package-path Packages/TimeTrackerCore --filter TimeSpanTests`. Expected: FAIL (типы не определены).
- [ ] **Step 3: Реализовать** типы по сигнатурам выше. Пересечение: полуинтервалы `[start, end)`.
- [ ] **Step 4: Run** тот же фильтр. Expected: все PASS.
- [ ] **Step 5: Commit** `feat(core): TimeProvider and TimeSpan overlap rules`.

**Swift для JS-разработчика:** `struct` — значение, копируется при присвоении (как неизменяемый объект); `throws(TimeSpanError)` — типизированные ошибки; `Optional` вместо `undefined`; `@Test` и `#expect` вместо `it`/`expect`.

---

### Task 2: PaletteParser

**Files:**
- Create: `.../Palette/PaletteCommand.swift`, `.../Palette/PaletteParser.swift`
- Test: `.../PaletteParserTests.swift`

**Interfaces:**
- Produces:
  - `public struct PaletteCommand: Equatable, Sendable { public enum CategoryRef: Equatable, Sendable { case existing(String), unknown(String) }; public var category: CategoryRef; public var title: String?; public var tags: [String]; public var startOffset: TimeInterval }`
  - `public enum PaletteParser { public static func parse(_ input: String, knownCategories: [String]) -> PaletteCommand?; public static func completion(for input: String, knownCategories: [String]) -> String? }`

Правила: категория — самое длинное имя из `knownCategories`, с которого начинается ввод (без учёта регистра, разделитель — пробел или конец); иначе первое слово как `.unknown`. `existing` несёт каноническое имя категории. Теги `#слово` без учёта регистра и без дубликатов, в порядке появления. `-<N>m` (также `h`) в конце ввода даёт `startOffset` в секундах. Остальное, схлопнув пробелы, — `title`. `nil`, если ввод пуст или нет категории (только `#тег` или только `-20m`). `completion` возвращает дополненную строку для Tab, когда ввод — префикс ровно одного или первого по порядку совпадения имени категории.

- [ ] **Step 1: Тесты:** `parsesCategoryTitleTagsAndOffset` (`"Работа созвон #клиентX #созвон -20m"` при `["Работа"]` → existing("Работа"), title "созвон", tags ["клиентx","созвон"], offset 1200); `caseInsensitiveCategoryReturnsCanonicalName`; `twoWordCategoryWinsOverFirstWord` (`"deep work чтение"` при `["Deep Work","Deep"]` → "Deep Work"); `unknownCategoryKeepsFirstWord`; `onlyTagReturnsNil`; `onlyOffsetReturnsNil`; `emptyAndWhitespaceReturnNil`; `extraWhitespaceIsCollapsed`; `unicodeAndEmojiTitleSurvive` (`"Спорт 🏃 бег"`); `duplicateTagsAreMerged`; `hourOffset` (`-2h` → 7200); `offsetInMiddleIsPartOfTitle` (`"Работа -20m созвон"` не считается сдвигом); `completionExtendsUniquePrefix`; `completionReturnsNilWhenNoMatch`.
- [ ] **Step 2: Run** `swift test --package-path Packages/TimeTrackerCore --filter PaletteParserTests`. Expected: FAIL.
- [ ] **Step 3: Реализовать** по правилам выше без регулярных выражений на всё сразу: сначала токенизация, потом разбор.
- [ ] **Step 4: Run** тот же фильтр. Expected: PASS.
- [ ] **Step 5: Commit** `feat(core): palette input parser with tab completion`.

**Swift для JS-разработчика:** `enum` с ассоциированными значениями = discriminated union в TS (`{type:"existing", name}`); `static func` в `enum` без случаев — чистое пространство имён; `String` в Swift — это Unicode-символы, а не UTF-16 как в JS, поэтому эмодзи считаются одним `Character`.

---

### Task 3: Модели SwiftData и категории/теги в Store

**Files:**
- Create: `.../Store/Models.swift`, `.../Store/TimeStore.swift`, `.../Store/StoreError.swift`
- Test: `.../TimeStoreCategoryTests.swift`

**Interfaces:**
- Consumes: `TimeProvider`.
- Produces:
  - `@Model public final class Category { public var id: UUID; public var name: String; public var colorHex: String; public var sortOrder: Int }`, `@Model public final class Tag { id, name }`, `@Model public final class TimeEntry { id: UUID; start: Date; end: Date?; category: Category?; tags: [Tag]; title: String?; notes: String? }` (все с значениями по умолчанию, связи опциональные).
  - `@MainActor public final class TimeStore { public init(container: ModelContainer, time: TimeProvider); public static func inMemory(time: TimeProvider) throws -> TimeStore }`
  - `public func addCategory(name: String, colorHex: String) throws(StoreError) -> Category`, `renameCategory(_:to:)`, `categories() -> [Category]` (по `sortOrder`), `deleteCategory(_:movingEntriesTo: Category?) throws(StoreError)`, `tag(named: String) -> Tag` (создаёт при отсутствии, без учёта регистра).
  - `public enum StoreError: Error, Equatable { case duplicateName, categoryHasEntries, startInFuture, endBeforeStart, overlap([UUID]), noRunningTimer, notFound }`

- [ ] **Step 1: Тесты:** `addCategoryAssignsIncreasingSortOrder`; `duplicateCategoryNameIsRejectedCaseInsensitively` (`"Работа"` и `"работа"` → `.duplicateName`); `renameToExistingNameIsRejected`; `deleteEmptyCategorySucceeds`; `deleteCategoryWithEntriesWithoutDestinationThrows` (→ `.categoryHasEntries`, категория и записи остались); `deleteCategoryWithDestinationMovesEntries`; `tagLookupIsCaseInsensitiveAndReusesInstance`. Записи для тестов создаются прямой вставкой модели через контекст контейнера, так как API записей появляется в Задаче 4.
- [ ] **Step 2: Run** `swift test --package-path Packages/TimeTrackerCore --filter TimeStoreCategoryTests`. Expected: FAIL.
- [ ] **Step 3: Реализовать** модели и методы. Контейнер — `ModelContainer(for: Category.self, Tag.self, TimeEntry.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true))` для `inMemory`.
- [ ] **Step 4: Run** тот же фильтр. Expected: PASS.
- [ ] **Step 5: Commit** `feat(core): SwiftData models and category/tag store`.

**Swift для JS-разработчика:** `@Model` — макрос, который превращает класс в сущность БД (как декоратор TypeORM, но на этапе компиляции); `@MainActor` привязывает класс к главному потоку (в JS такого нет, там один поток); `class` — ссылочный тип, `struct` — значение.

---

### Task 4: Таймер и записи в Store

**Files:**
- Modify: `.../Store/TimeStore.swift`
- Test: `.../TimeStoreEntryTests.swift`

**Interfaces:**
- Consumes: `TimeSpan`, `TimeProvider`, `TimeStore.tag(named:)`, `StoreError`.
- Produces:
  - `@discardableResult public func startTimer(category: Category, title: String?, tags: [String], startedAt: Date? = nil) throws(StoreError) -> TimeEntry`
  - `@discardableResult public func stopTimer() throws(StoreError) -> TimeEntry`
  - `public func runningEntry() -> TimeEntry?`
  - `public func addEntry(span: TimeSpan, category: Category, title: String?, tags: [String], notes: String?, allowOverlap: Bool = false) throws(StoreError) -> TimeEntry`
  - `public func update(_ entry: TimeEntry, span: TimeSpan, category: Category, title: String?, tags: [String], notes: String?, allowOverlap: Bool = false) throws(StoreError)`
  - `public func delete(_ entry: TimeEntry)`, `public func conflicts(for span: TimeSpan, excluding: TimeEntry?) -> [TimeEntry]`, `public func entries(from: Date, to: Date) -> [TimeEntry]` (записи, пересекающие период, по `start`), `public func lastEntry() -> TimeEntry?`, `public func recentTitles(limit: Int) -> [String]` (по частоте, затем свежести).

- [ ] **Step 1: Тесты:** `startCreatesRunningEntry`; `secondStartStopsPreviousAtNewStart` (первый с 10:00, второй стартует в 10:30 → у первого `end == 10:30`); `startWithOffsetStopsPreviousAtOffsetStart` (**Review Focus 1**: идёт с 10:00, now 10:30, `startedAt` 10:10 → `end` предыдущего 10:10); `startBeforeRunningStartThrows` (идёт с 10:00, `startedAt` 09:50 → `.endBeforeStart`, running остался прежним); `startInFutureThrows` (`.startInFuture`); `stopSetsEndToNow`; `stopWhenClockWentBackNeverProducesEndBeforeStart` (**Review Focus 3**: start 10:00, now откатился на 09:55 → `end == 10:00`); `stopWithoutRunningThrows` (`.noRunningTimer`); `runningTimerSurvivesContainerRecreation` (файловое хранилище во временной папке, пересоздать `TimeStore`, `runningEntry()` не nil); `addEntryRejectsOverlapWithIds` (`.overlap([id])`); `addEntryTouchingNeighborIsAllowed`; `addEntryAllowOverlapSucceeds`; `addEntryWithFutureStartThrows`; `updateChangesFieldsAndKeepsIdentity`; `updateOverlapCheckExcludesItself`; `entriesQueryIncludesEntryCrossingRangeBoundary`; `recentTitlesOrderedByFrequencyThenRecency`; `lastEntryReturnsMostRecentlyStarted`.
- [ ] **Step 2: Run** `swift test --package-path Packages/TimeTrackerCore --filter TimeStoreEntryTests`. Expected: FAIL.
- [ ] **Step 3: Реализовать.** При `startTimer` предыдущий останавливается в `startedAt ?? now`. Ошибки приоритета: сначала `.startInFuture`, потом `.endBeforeStart`. Остановка: `end = max(now, start)`.
- [ ] **Step 4: Run** тот же фильтр. Expected: PASS.
- [ ] **Step 5: Commit** `feat(core): timer and entry operations in store`.

**Swift для JS-разработчика:** `throws` + `try` вместо `try/catch` с неявными исключениями: компилятор заставляет пометить каждый вызов; `@discardableResult` разрешает не использовать возвращаемое значение; значения по умолчанию у параметров (`= nil`) как в TS.

---

### Task 5: PaletteViewModel

**Files:**
- Create: `.../Palette/PaletteViewModel.swift`
- Test: `.../PaletteViewModelTests.swift`

**Interfaces:**
- Consumes: `PaletteParser`, `TimeStore` (все методы Задачи 4 и 3).
- Produces:
  - `public enum PaletteItem: Equatable, Sendable { case stopCurrent, repeatLast(title: String?, category: String), createCategory(String), suggestion(String) }`
  - `public enum PaletteOutcome: Equatable { case started, stopped, needsCategoryCreation(String), overlap([UUID]), failed(StoreError), nothing }`
  - `@MainActor @Observable public final class PaletteViewModel { public init(store: TimeStore, time: TimeProvider); public var input: String; public private(set) var items: [PaletteItem]; public func tab(); public func submit(allowOverlap: Bool = false) -> PaletteOutcome; public func createCategoryAndSubmit(colorHex: String) -> PaletteOutcome }`

Поведение: при пустом `input` и идущем таймере `items.first == .stopCurrent`, `submit()` останавливает; при пустом `input` и остановленном таймере `items.first == .repeatLast`, `submit()` запускает копию последней записи; для `.unknown` категории `items.first == .createCategory(name)`, а `submit()` возвращает `.needsCategoryCreation` и ничего не меняет.

- [ ] **Step 1: Тесты:** `emptyInputWhileRunningOffersStop`; `emptySubmitWhileRunningStops`; `emptyInputWhileIdleOffersRepeatLast`; `submitStartsTimerWithParsedTagsAndTitle`; `submitWithUnknownCategoryDoesNotCreateIt` (категорий в Store по-прежнему столько же); `createCategoryAndSubmitCreatesThenStarts`; `submitWhileRunningSwitchesTimer`; `submitWithOffsetBeforeRunningStartReportsFailedEndBeforeStart`; `tabCompletesCategoryName`; `suggestionsComeFromRecentTitles`; `successfulSubmitClearsInput`.
- [ ] **Step 2: Run** `swift test --package-path Packages/TimeTrackerCore --filter PaletteViewModelTests`. Expected: FAIL.
- [ ] **Step 3: Реализовать** `PaletteViewModel` поверх Store и парсера. `items` пересчитываются при смене `input` (`didSet`).
- [ ] **Step 4: Run** тот же фильтр. Expected: PASS.
- [ ] **Step 5: Commit** `feat(core): palette view model`.

**Swift для JS-разработчика:** `@Observable` — аналог MobX/Zustand-стора: SwiftUI сам перерисует вью при изменении свойств, `useState` не нужен; `private(set)` = публичное чтение, приватная запись.

---

### Task 6: Группировка по дням и фильтры Журнала

**Files:**
- Create: `.../Journal/DayGrouping.swift`, `.../Journal/EntryFilter.swift`
- Test: `.../DayGroupingTests.swift`, `.../EntryFilterTests.swift`

**Interfaces:**
- Consumes: `TimeEntry`.
- Produces:
  - `public struct DayGroup: Equatable { public let day: Date; public let entries: [TimeEntry]; public let total: TimeInterval }`
  - `public enum DayGrouping { public static func group(_ entries: [TimeEntry], calendar: Calendar, now: Date) -> [DayGroup] }` — дни по убыванию; запись показывается в группе дня своего `start`; `total` дня учитывает только ту часть записи, что попала в этот день (запись через полночь делит время по дням).
  - `public struct EntryFilter: Equatable { public var category: UUID?; public var tag: UUID?; public var from: Date?; public var to: Date?; public var text: String; public func matches(_ entry: TimeEntry) -> Bool }` (текст ищет по `title`, `notes` и именам тегов без учёта регистра).

- [ ] **Step 1: Тесты:** `groupsByStartDayDescending`; `entryCrossingMidnightSplitsTotalsBetweenDays` (**Review Focus 2**: 23:00-01:00 → 1ч в первом дне, 1ч во втором, показана под первым); `dstSpringForwardDayHasTwentyThreeHourWindow` (календарь `America/New_York`, 2026-03-08, запись 00:00-23:59 даёт ровно реальную длительность без «потерянного» часа); `runningEntryUsesNowForTotal`; `emptyInputGivesNoGroups`; `filterByCategory`; `filterByTag`; `filterByTextMatchesNotesTitleAndTags`; `filterByRange`; `combinedFilters`. Календарь и зона передаются явно.
- [ ] **Step 2: Run** `swift test --package-path Packages/TimeTrackerCore --filter "DayGroupingTests|EntryFilterTests"`. Expected: FAIL.
- [ ] **Step 3: Реализовать.** Границы дня через `calendar.startOfDay(for:)` и `calendar.date(byAdding: .day, ...)`, а не прибавлением 86400 секунд.
- [ ] **Step 4: Run** тот же фильтр. Expected: PASS.
- [ ] **Step 5: Commit** `feat(core): journal day grouping and filters`.

**Swift для JS-разработчика:** `Calendar`/`TimeZone` — аналог `Intl` и date-fns, но встроены; никаких `new Date()` в логике: время приходит снаружи, как инъекция зависимости.

---

### Task 7: Экспорт CSV и SQLite

**Files:**
- Create: `.../Export/ExportRow.swift`, `.../Export/CSVExporter.swift`, `.../Export/SQLiteExporter.swift`
- Test: `.../CSVExporterTests.swift`, `.../SQLiteExporterTests.swift`

**Interfaces:**
- Consumes: `TimeEntry`.
- Produces:
  - `public struct ExportRow: Equatable, Sendable { start: Date; end: Date?; durationSeconds: Int; category: String; tags: [String]; title: String; notes: String; public init(entry: TimeEntry, now: Date) }`
  - `public enum CSVExporter { public static let header = "start,end,duration_seconds,category,tags,title,notes"; public static func csv(_ rows: [ExportRow]) -> String }` — даты в ISO 8601 UTC, теги через `;`.
  - `public enum SQLiteExporter { public static func write(_ rows: [ExportRow], to url: URL) throws }` — таблица `entries` с теми же колонками, `PRAGMA user_version = 1`.

- [ ] **Step 1: Тесты CSV:** `headerMatchesSpecColumns`; `quotesFieldsWithCommasQuotesAndNewlines` (`He said "hi", ok\nbye` → поле в кавычках, внутренние кавычки удвоены); `neutralizesFormulaPrefix` (**Review Focus 4**: `=SUM(A1)`, `+1`, `-1`, `@cmd` в `title` → начинаются с `'`); `runningEntryHasEmptyEndAndDurationUntilNow`; `emptyNotesAreEmptyField`; `multipleTagsJoinedBySemicolon`; `unicodeSurvivesRoundTrip`. **SQLite:** `writesRowsWithSameColumns` (открыть файл через `sqlite3`, прочитать `entries`, сравнить значения); `userVersionIsOne`; `overwritesExistingFile`.
- [ ] **Step 2: Run** `swift test --package-path Packages/TimeTrackerCore --filter "CSVExporterTests|SQLiteExporterTests"`. Expected: FAIL.
- [ ] **Step 3: Реализовать.** CSV пишется руками (RFC 4180, CRLF), SQLite через системную библиотеку `import SQLite3` без сторонних пакетов.
- [ ] **Step 4: Run** тот же фильтр. Expected: PASS.
- [ ] **Step 5: Commit** `feat(core): CSV and SQLite export`.

**Swift для JS-разработчика:** `import SQLite3` — вызов C-библиотеки напрямую (в JS для этого нужен нативный аддон); `Date` форматируется через `ISO8601FormatStyle`, а не `toISOString()`.

---

### Task 8: Оболочка приложения и menu bar

**Files:**
- Create: `App/AppEnvironment.swift` (создаёт `TimeStore` на файловом контейнере), `App/MenuBar/MenuBarContent.swift`, `App/MenuBar/RunningTimerView.swift`
- Modify: `App/TimeTrackerApp.swift`

**Interfaces:**
- Consumes: `TimeStore`, `TimeEntry`.
- Produces: `AppEnvironment` (`@MainActor`, `static let shared`) с `store: TimeStore`; сцены `MenuBarExtra` и `WindowGroup("Журнал")`.

- [ ] **Step 1:** Добавить `MenuBarExtra` с текстом текущего таймера («Работа 0:42») или значком, когда таймер не идёт. Popover: категория, время, кнопка «Остановить», многострочное поле «Описание» (пишет в `entry.notes` сразу), кнопка «Открыть журнал».
- [ ] **Step 2:** Закрытие окна Журнала не завершает приложение (`applicationShouldTerminateAfterLastWindowClosed` → `false`).
- [ ] **Step 3: Run** `xcodegen generate && xcodebuild -scheme TimeTracker -destination 'platform=macOS' build | xcbeautify`. Expected: `BUILD SUCCEEDED`; `swiftlint` без нарушений.
- [ ] **Step 4: Ручная проверка** (скриншоты через computer-use): иконка в menu bar появляется; иконка в Dock есть; закрытие окна не закрывает приложение; запуск тестового таймера из временной кнопки показывает время и сохраняет описание после перезапуска приложения.
- [ ] **Step 5: Commit** `feat(app): menu bar item and app shell`.

**Swift для JS-разработчика:** `View` — это аналог компонента React, `body` — функция рендера; `@State`/`@Bindable` примерно соответствуют `useState` и контролируемым полям; `Scene` — окно приложения (аналог корневого `<App>` на каждое окно).

---

### Task 9: Хоткей и окно-палитра

**Files:**
- Modify: `project.yml` (зависимость KeyboardShortcuts), `App/TimeTrackerApp.swift`
- Create: `App/Palette/PalettePanel.swift` (`NSPanel`), `App/Palette/PaletteView.swift`, `App/Hotkey/HotkeyService.swift`

**Interfaces:**
- Consumes: `PaletteViewModel`, `PaletteOutcome`.
- Produces: `HotkeyService` (`@MainActor`, `start(onToggle: @escaping () -> Void)`); `KeyboardShortcuts.Name.togglePalette` с дефолтом `⌃⌥T`.

- [ ] **Step 1: Безопасность.** Прогнать пакет KeyboardShortcuts через cc-audit и просмотреть исходники; результат записать в `docs/moodboard.md` одной строкой. Только после этого добавить в `project.yml`.
- [ ] **Step 2:** `PalettePanel`: не активирующая панель по центру экрана, поле ввода сразу в фокусе, закрывается по Esc и повторному хоткею, после Enter возвращает фокус предыдущему приложению. `PaletteView` показывает `items`, текущий таймер и ошибки в самом окне (в том числе кнопки «всё равно» для `.overlap` и «Создать категорию» для `.needsCategoryCreation`).
- [ ] **Step 3: Run** `xcodebuild -scheme TimeTracker -destination 'platform=macOS' build | xcbeautify`. Expected: `BUILD SUCCEEDED`.
- [ ] **Step 4: Ручной чек-лист** (с скриншотами): хоткей открывает и закрывает палитру из любого приложения; Tab дополняет категорию; Enter запускает таймер, фокус возвращается в прежнее приложение; пустой Enter при идущем таймере останавливает; `-20m` стартует задним числом; неизвестная категория предлагает создание; пересечение показывает предупреждение; первый запрос системных прав описан в `README`-заметке в `CLAUDE.md`.
- [ ] **Step 5: Commit** `feat(app): global hotkey and spotlight-style palette`.

**Swift для JS-разработчика:** `NSPanel` — это AppKit (старый императивный слой macOS под SwiftUI); SwiftUI встраивается в него через `NSHostingView` — как React в произвольный DOM-узел через `createRoot`.

---

### Task 10: Журнал, категории и настройки

**Files:**
- Create: `App/Journal/JournalView.swift`, `App/Journal/EntryDetailView.swift`, `App/Journal/AddEntrySheet.swift`, `App/Journal/CategoriesView.swift`, `App/Settings/SettingsView.swift`, `App/Export/ExportActions.swift`

**Interfaces:**
- Consumes: `DayGrouping`, `EntryFilter`, `TimeStore` (все методы), `CSVExporter`, `SQLiteExporter`, `StoreError`.

- [ ] **Step 1:** Список по дням (`DayGroup`, сумма часов), панель справа для правки: время начала/конца, категория, теги, название, описание; сохранение сразу; ошибки `.overlap`/`.endBeforeStart` показываются рядом с полем.
- [ ] **Step 2:** `AddEntrySheet` для записи за любой прошлый промежуток, фильтры и поиск (`EntryFilter`), вкладка «Категории» (цвет, порядок, переименование, перенос записей при удалении по `deleteCategory(_:movingEntriesTo:)`).
- [ ] **Step 3:** Настройки: рекордер хоткея. Меню «Экспорт» → CSV и SQLite через `NSSavePanel`, строки получаются из `ExportRow(entry:now:)`.
- [ ] **Step 4: Run** сборка (`BUILD SUCCEEDED`) и `swift test --package-path Packages/TimeTrackerCore` (всё PASS).
- [ ] **Step 5: Ручной чек-лист** (со скриншотами): правка времени сохраняется; пересечение предупреждает, «всё равно» сохраняет; удаление категории с записями требует переноса; экспорт CSV открывается в Numbers без ошибок, SQLite открывается через `sqlite3 file 'select count(*) from entries'`.
- [ ] **Step 6: Commit** `feat(app): journal, categories, settings and export`.

**Swift для JS-разработчика:** `List`, `Form`, `Table` — готовые компоненты вместо `div` + CSS; `@Query` (если понадобится) — запрос к БД прямо во вью, как `useQuery`.

---

### Task 11: Контроль качества тестов

**Files:**
- Create: `scripts/coverage.sh`, `docs/testing.md`

- [ ] **Step 1:** `scripts/coverage.sh`: `swift test --package-path Packages/TimeTrackerCore --enable-code-coverage`, затем `llvm-cov report` по путям из `swift test --show-codecov-path`; скрипт завершается с ошибкой, если покрытие Domain, Palette, Store или Export ниже 90% по строкам.
- [ ] **Step 2: Run** `bash scripts/coverage.sh`. Expected: код возврата 0 и таблица с покрытием выше порога.
- [ ] **Step 3:** Проверить, подходит ли Muter (или альтернатива) для Swift 6.4, на модулях Domain/Palette/Store. Если совместим, запустить один раз и записать долю выживших мутантов и список ненайденных мутаций в `docs/testing.md`; если нет, записать причину.
- [ ] **Step 4:** Для каждого выжившего мутанта в Domain/Palette/Store добавить тест (красный на мутанте, зелёный на оригинале) или записать причину отказа.
- [ ] **Step 5:** Итоговый ручной чек-лист хоткея и палитры в `docs/testing.md` (повтор Задачи 9) и прогон `swiftlint`, `swift test`, сборки.
- [ ] **Step 6: Commit** `chore: coverage gate and testing notes`.
