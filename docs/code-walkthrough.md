# Разбор кода: что за что отвечает

Этот документ написан для человека, который знает JS/TS/React и хочет понять, как устроено нативное macOS-приложение, и суметь написать такое же с нуля. Читайте в порядке глав. Названия файлов — ссылки; номера строк не приводятся, потому что они уезжают, а имена типов и функций остаются.

Размер проекта: около 1200 строк логики (`Packages/TimeTrackerCore/Sources`), около 1000 строк интерфейса (`App`), около 1800 строк тестов. Тестов больше, чем самой логики, и это сделано намеренно.

## 1. Главная идея в трёх строках

1. **Вся логика живёт отдельно от окон.** Пакет `TimeTrackerCore` ничего не знает о SwiftUI и окнах. Его можно проверить командой `swift test` за доли секунды.
2. **Интерфейс только показывает состояние и зовёт методы.** Вью читают свойства view-моделей и вызывают их методы. Решений во вью нет.
3. **Единственная дверь к данным — `TimeStore`.** Никто не лезет в базу напрямую.

В React-мире это похоже на: `TimeStore` = слой данных/API-клиент, view-модели = хуки/сторы с логикой (Zustand/MobX), SwiftUI-вью = «глупые» компоненты, пакет = отдельный npm-пакет без зависимости от React.

```
┌──────────────────────────── App (SwiftUI, AppKit) ────────────────────────────┐
│  TimeTrackerApp ─ сцены: MenuBarExtra, Window «Журнал», Settings              │
│  MenuBar/*   Palette/*   Journal/*   Settings/*   Hotkey/*   Export/*         │
│  AppModel (бегущий таймер, часы раз в секунду)   AppEnvironment (где БД)      │
└───────────────────────────────────────┬────────────────────────────────────────┘
                                        │ вызывает методы, читает свойства
┌───────────────────────────────────────▼────────────────────────────────────────┐
│ TimeTrackerCore (Swift Package, без UI)                                        │
│  Palette/   PaletteParser, PaletteViewModel   ← ввод и Enter/Tab/Esc           │
│  Journal/   JournalViewModel, DayGrouping, EntryFilter, EntryDraft, TagInput   │
│  Export/    ExportRow, CSVExporter, SQLiteExporter                             │
│  Store/     TimeStore (+Entries), Models (SwiftData), StoreError               │
│  Domain/    TimeSpan, TimeProvider, DurationFormat   ← чистые правила          │
└────────────────────────────────────────────────────────────────────────────────┘
```

Правило зависимостей: стрелки идут только вниз. `Domain` не знает ни о чём; `Store` знает `Domain`; view-модели знают `Store`; `App` знает всё. Если вы замечаете импорт «наверх», это ошибка проектирования.

## 2. Путь одного действия: «нажал хоткей и запустил таймер»

Это самая важная глава. Пройдите её с открытыми файлами.

1. **Приложение стартует.** [TimeTrackerApp.swift](../App/TimeTrackerApp.swift) в `init()` создаёт хранилище ([AppEnvironment.swift](../App/AppEnvironment.swift): файл `~/Library/Application Support/TimeTracker/store.sqlite`, при первом запуске три категории), затем `AppModel` и `AppCoordinator`.
2. **Хоткей зарегистрирован.** [AppCoordinator.swift](../App/AppCoordinator.swift) создаёт `PaletteController` и [HotkeyService](../App/Hotkey/HotkeyService.swift). Тот через пакет `KeyboardShortcuts` просит систему «сообщи, когда нажмут ⌃⌥T» и вызывает `palette.toggle()`.
3. **Окно показывается.** [PaletteController](../App/Palette/PaletteController.swift): `show()` обнуляет палитру (`viewModel.reset()`), ставит окно в верхнюю треть экрана и делает его ключевым. Само окно — [PalettePanel](../App/Palette/PalettePanel.swift), это `NSPanel`: оно принимает ввод, но не делает наше приложение активным, поэтому фокус потом возвращается в то приложение, где вы работали.
4. **Пользователь печатает.** [PaletteView](../App/Palette/PaletteView.swift) связывает поле ввода с `viewModel.input`. Каждое изменение вызывает `didSet` в [PaletteViewModel](../Packages/TimeTrackerCore/Sources/TimeTrackerCore/Palette/PaletteViewModel.swift), тот пересчитывает `items` (подсказки). Для разбора строки он вызывает [PaletteParser.parse](../Packages/TimeTrackerCore/Sources/TimeTrackerCore/Palette/PaletteParser.swift), который превращает `Работа созвон #клиент -20m` в `PaletteCommand` (категория, название, теги, сдвиг в секундах).
5. **Tab.** `onKeyPress(.tab)` во вью зовёт `viewModel.tab()`; тот спрашивает `PaletteParser.completion` и подставляет `Работа `.
6. **Enter.** `onSubmit` во вью зовёт `viewModel.enter()`. Это конечный автомат из двух шагов: первый Enter может поднять вопрос (`prompt`: «создать категорию?», «пересекается, всё равно?»), второй подтверждает. Внутри `enter()` вызывается `submit()`.
7. **Запуск таймера.** `submit()` находит `EntryCategory` и вызывает `store.startTimer(...)` ([TimeStore+Entries.swift](../Packages/TimeTrackerCore/Sources/TimeTrackerCore/Store/TimeStore+Entries.swift)). Он по порядку проверяет: старт не в будущем; не раньше начала текущего таймера; нет пересечений; только потом закрывает предыдущую запись **в момент нового старта**, вставляет новую и сохраняет.
8. **Обновление интерфейса.** Во вью `handle(outcome)` вызывает `model.refresh()` ([AppModel](../App/AppModel.swift)): тот читает `store.runningEntry()`. Подпись в menu bar (`model.menuBarTitle`) пересчитывается автоматически, потому что `AppModel` — `@Observable`, а подпись читает его свойства. Затем палитра закрывается (`onClose` → `hide()`).
9. **Секундомер.** `AppModel` в `init` запускает цикл `Task { while ... sleep(1s); refresh() }`, поэтому время в menu bar идёт.

Если на любом шаге что-то идёт не так, `submit()` возвращает `PaletteOutcome` (`.failed`, `.overlap`, `.needsCategoryCreation`), а `enter()` превращает его в `prompt`, который вью красиво показывает под полем.

## 3. Другие пути

**Правка записи в Журнале.** [JournalEntriesView](../App/Journal/JournalEntriesView.swift) показывает `journal.groups`. Выбор строки открывает [EntryDetailView](../App/Journal/EntryDetailView.swift) с локальным `@State draft: EntryDraft`. `.onChange(of: draft)` вызывает `journal.save(draft, to: entry)` → [JournalViewModel.save](../Packages/TimeTrackerCore/Sources/TimeTrackerCore/Journal/JournalViewModel.swift) разбирает теги ([TagInput](../Packages/TimeTrackerCore/Sources/TimeTrackerCore/Journal/TagInput.swift)), строит `TimeSpan` и зовёт `store.update(...)`. Ошибка (`.overlap`) показывается красной строкой с кнопкой «Всё равно».

**Список по дням.** `JournalViewModel.reload()` берёт все записи, фильтрует через [EntryFilter](../Packages/TimeTrackerCore/Sources/TimeTrackerCore/Journal/EntryFilter.swift), группирует через [DayGrouping](../Packages/TimeTrackerCore/Sources/TimeTrackerCore/Journal/DayGrouping.swift) (запись показывается под днём старта, а время делится по границам календарных дней).

**Экспорт.** Кнопка «Экспорт» в тулбаре зовёт [ExportActions](../App/Export/ExportActions.swift) (системный диалог сохранения), тот берёт `journal.exportRows()` (строки с учётом фильтра) и пишет файл через [CSVExporter](../Packages/TimeTrackerCore/Sources/TimeTrackerCore/Export/CSVExporter.swift) или [SQLiteExporter](../Packages/TimeTrackerCore/Sources/TimeTrackerCore/Export/SQLiteExporter.swift).

## 4. Файл за файлом

### Domain: чистые правила, ничего не знают о БД и UI
| Файл | Одна обязанность |
|---|---|
| [TimeProvider.swift](../Packages/TimeTrackerCore/Sources/TimeTrackerCore/Domain/TimeProvider.swift) | «Который час?» как зависимость. В тестах подставляется управляемое время. |
| [TimeSpan.swift](../Packages/TimeTrackerCore/Sources/TimeTrackerCore/Domain/TimeSpan.swift) | Интервал `[start, end)`; `end == nil` значит «идёт». Пересечение и длительность. |
| [DurationFormat.swift](../Packages/TimeTrackerCore/Sources/TimeTrackerCore/Domain/DurationFormat.swift) | `0:42`, `1:02:05`, `1 ч 30 мин`. |

### Store: данные и их инварианты
| Файл | Одна обязанность |
|---|---|
| [Models.swift](../Packages/TimeTrackerCore/Sources/TimeTrackerCore/Store/Models.swift) | Три модели SwiftData: `EntryCategory`, `Tag`, `TimeEntry`. |
| [TimeStore.swift](../Packages/TimeTrackerCore/Sources/TimeTrackerCore/Store/TimeStore.swift) | Создание контейнера БД, категории, теги, сохранение. |
| [TimeStore+Entries.swift](../Packages/TimeTrackerCore/Sources/TimeTrackerCore/Store/TimeStore+Entries.swift) | Таймер, ручные записи, правка, запросы. Здесь живут правила «один таймер», «без пересечений», «не из будущего». |
| [StoreError.swift](../Packages/TimeTrackerCore/Sources/TimeTrackerCore/Store/StoreError.swift) и `+Message` | Список всего, что может пойти не так, и тексты для человека. |

### Palette: ввод
| Файл | Одна обязанность |
|---|---|
| [PaletteCommand.swift](../Packages/TimeTrackerCore/Sources/TimeTrackerCore/Palette/PaletteCommand.swift) | Разобранный ввод: категория (известная/неизвестная), название, теги, сдвиг. |
| [PaletteParser.swift](../Packages/TimeTrackerCore/Sources/TimeTrackerCore/Palette/PaletteParser.swift) | Строка → `PaletteCommand`; дополнение по Tab. |
| [PaletteViewModel.swift](../Packages/TimeTrackerCore/Sources/TimeTrackerCore/Palette/PaletteViewModel.swift) | Состояние окна: `input`, `items`, `prompt`; действия `enter`, `tab`, `cancelPrompt`, `reset`. |

### Journal: список, правка, фильтры
| Файл | Одна обязанность |
|---|---|
| [DayGrouping.swift](../Packages/TimeTrackerCore/Sources/TimeTrackerCore/Journal/DayGrouping.swift) | Группировка записей по дням, суммы с учётом перехода через полночь и летнего времени. |
| [EntryFilter.swift](../Packages/TimeTrackerCore/Sources/TimeTrackerCore/Journal/EntryFilter.swift) | Условия фильтра и `matches`. |
| [EntryDraft.swift](../Packages/TimeTrackerCore/Sources/TimeTrackerCore/Journal/EntryDraft.swift) | Редактируемая копия записи (все поля — строки/даты), чтобы форма не трогала модель БД напрямую. |
| [TagInput.swift](../Packages/TimeTrackerCore/Sources/TimeTrackerCore/Journal/TagInput.swift) | Текст `#a, b` ↔ список тегов. |
| [JournalViewModel.swift](../Packages/TimeTrackerCore/Sources/TimeTrackerCore/Journal/JournalViewModel.swift) | Склеивает всё выше: `groups`, `save`, `delete`, управление категориями, строки экспорта. |

### Export
| Файл | Одна обязанность |
|---|---|
| [ExportRow.swift](../Packages/TimeTrackerCore/Sources/TimeTrackerCore/Export/ExportRow.swift) | Плоская строка экспорта (колонки зафиксированы в дизайне). |
| [CSVExporter.swift](../Packages/TimeTrackerCore/Sources/TimeTrackerCore/Export/CSVExporter.swift) | CSV по RFC 4180 + защита от формул в Excel. |
| [SQLiteExporter.swift](../Packages/TimeTrackerCore/Sources/TimeTrackerCore/Export/SQLiteExporter.swift) | Отдельный `.sqlite` с таблицей `entries` через C-API SQLite. |

### App: тонкий слой интерфейса
| Файл | Одна обязанность |
|---|---|
| [TimeTrackerApp.swift](../App/TimeTrackerApp.swift) | Точка входа и список сцен (menu bar, окно Журнала, настройки). |
| [AppEnvironment.swift](../App/AppEnvironment.swift) | Где лежит БД, стартовые категории. |
| [AppModel.swift](../App/AppModel.swift) | Какой таймер идёт сейчас и «часы» раз в секунду. |
| [AppCoordinator.swift](../App/AppCoordinator.swift) | Связывает хоткей с окном палитры. |
| `Hotkey/`, `Palette/` | Хоткей, плавающее окно, его содержимое. |
| `MenuBar/` | Всплывающее окно у значка в menu bar. |
| `Journal/` | Окно Журнала, форма записи, вкладка категорий. |
| `Settings/`, `Export/`, `Support/` | Настройка хоткея, диалог сохранения, `Color(hex:)`. |

## 5. Почему сделано именно так

| Решение | Зачем |
|---|---|
| `TimeProvider` вместо `Date()` | Тесты управляют временем. Иначе проверять «часы ушли назад» или «через полночь» невозможно. |
| Идёт ли таймер, решает только `end == nil` | Нет отдельного флага, который может разойтись с данными. Состояние выводится из данных. |
| Все проверки до первой записи | Если проверка не прошла, данные не тронуты (`guard ... else { throw }` сверху). |
| Типизированные ошибки `throws(StoreError)` | Компилятор знает полный список ошибок; вью обязано решить, что показать на каждую. |
| `EntryDraft` вместо правки модели прямо в форме | Пользователь может ввести невалидное промежуточное состояние; модель БД при этом не портится. |
| Двухшаговый Enter в view-модели | Логику «вопрос → подтверждение» можно тестировать без окна. |
| Local-first (SQLite на диске, без сервера) | Проще, быстрее, работает без сети. Модели совместимы с CloudKit на случай синхронизации. |
| Экспорт отдельным файлом, а не копией БД | Живую базу с журналом копировать небезопасно; у внутренних таблиц SwiftData неудобные имена колонок. |

## 6. Словарь Swift для JS/React-разработчика

| Понятие | Аналог в JS/React | Где посмотреть |
|---|---|---|
| `struct` (значение, копируется) | неизменяемый объект/`Object.freeze` | `TimeSpan`, `PaletteCommand`, `EntryDraft` |
| `class` (ссылка) | обычный объект | `TimeStore`, модели, view-модели |
| `enum` с данными | discriminated union | `PaletteItem`, `PalettePrompt`, `StoreError` |
| `Optional` (`T?`) | `T \| undefined`, но компилятор заставляет проверять | `end: Date?` |
| `protocol` | `interface` | `TimeProvider` |
| `throws` / `try` | исключения, но помеченные в сигнатуре | все методы `TimeStore` |
| `guard let ... else` | ранний `return` с распаковкой | `PaletteViewModel`, `JournalViewModel.save` |
| `extension` | добавить методы типу в другом файле | `TimeStore+Entries.swift` |
| `@Observable` | MobX `observable` / Zustand-стор | `AppModel`, `PaletteViewModel` |
| `@State` | `useState` | `EntryDetailView.draft` |
| `@Bindable`, `$x` | контролируемое поле `value`+`onChange` | `PaletteView` (`$viewModel.input`) |
| `View`, `body` | компонент и его рендер | все файлы в `App/` |
| `@MainActor` | «только главный поток» (в JS поток один) | `TimeStore`, view-модели |
| `Sendable` | «можно передавать между потоками» | `TimeProvider`, `PaletteCommand` |
| `@Model` (SwiftData) | сущность ORM (TypeORM `@Entity`) | `Models.swift` |
| `#Predicate`, `FetchDescriptor` | `where` и запрос в ORM | `TimeStore.swift`, `+Entries.swift` |
| `defer { ... }` | `finally` | `PaletteViewModel.submit`, SQLite-экспорт |
| Swift Testing: `@Test`, `#expect` | `it`, `expect().toBe()` | `Tests/` |
| Swift Package (`Package.swift`) | `package.json` + workspace | `Packages/TimeTrackerCore` |
| XcodeGen `project.yml` | конфиг сборки вместо ручного `.xcodeproj` | корень проекта |

Подробные заметки по каждой задаче лежат в [learning-notes.md](learning-notes.md).

## 7. В каком порядке читать код (снизу вверх)

1. [TimeSpan.swift](../Packages/TimeTrackerCore/Sources/TimeTrackerCore/Domain/TimeSpan.swift) и [TimeSpanTests.swift](../Packages/TimeTrackerCore/Tests/TimeTrackerCoreTests/TimeSpanTests.swift). Самый маленький чистый кусок; поймёте стиль «тест как документация».
2. [PaletteParser.swift](../Packages/TimeTrackerCore/Sources/TimeTrackerCore/Palette/PaletteParser.swift) + тесты. Работа со строками и Optional без БД.
3. [Models.swift](../Packages/TimeTrackerCore/Sources/TimeTrackerCore/Store/Models.swift), затем [TimeStore.swift](../Packages/TimeTrackerCore/Sources/TimeTrackerCore/Store/TimeStore.swift). Как SwiftData описывает данные и запросы.
4. [TimeStore+Entries.swift](../Packages/TimeTrackerCore/Sources/TimeTrackerCore/Store/TimeStore%2BEntries.swift) + [TimeStoreEntryTests.swift](../Packages/TimeTrackerCore/Tests/TimeTrackerCoreTests/TimeStoreEntryTests.swift). Ядро правил. Читайте тест, потом код.
5. [PaletteViewModel.swift](../Packages/TimeTrackerCore/Sources/TimeTrackerCore/Palette/PaletteViewModel.swift) + [PalettePromptTests.swift](../Packages/TimeTrackerCore/Tests/TimeTrackerCoreTests/PalettePromptTests.swift). Конечный автомат.
6. [JournalViewModel.swift](../Packages/TimeTrackerCore/Sources/TimeTrackerCore/Journal/JournalViewModel.swift), [DayGrouping.swift](../Packages/TimeTrackerCore/Sources/TimeTrackerCore/Journal/DayGrouping.swift).
7. Экспорт: [CSVExporter.swift](../Packages/TimeTrackerCore/Sources/TimeTrackerCore/Export/CSVExporter.swift), затем [SQLiteExporter.swift](../Packages/TimeTrackerCore/Sources/TimeTrackerCore/Export/SQLiteExporter.swift).
8. Только потом интерфейс: [TimeTrackerApp.swift](../App/TimeTrackerApp.swift), [AppModel.swift](../App/AppModel.swift), [MenuBarContent.swift](../App/MenuBar/MenuBarContent.swift), [PaletteView.swift](../App/Palette/PaletteView.swift), [JournalEntriesView.swift](../App/Journal/JournalEntriesView.swift).

Приём чтения: открывайте тест рядом с кодом и спрашивайте себя «что сломается, если я изменю эту строку?». Мы так проверяли тесты мутациями вручную.

## 8. Как написать такое же самому с нуля

Порядок, который мы прошли, и который стоит повторить своими руками:

1. **Пакет и пустой тест.** `Package.swift`, один тест, `swift test`. Убедитесь, что цикл «красный → зелёный» работает.
2. **Модель времени.** `TimeSpan` (интервал, пересечение), `TimeProvider`. Пишите тесты первыми.
3. **Парсер ввода.** Строка → структура. Самое весёлое место для тестов на странные случаи (юникод, пробелы, дубликаты).
4. **Хранилище.** Модели SwiftData, `TimeStore` с категориями; затем таймер и ручные записи. Правила проверяйте тестами на хранилище в памяти.
5. **View-модели.** Палитра и Журнал как классы с `@Observable`; всё, что можно, проверяйте без UI.
6. **Оболочка приложения.** `@main`, `MenuBarExtra`, окно. Покажите одно число из `AppModel`.
7. **Окно палитры.** `NSPanel` + SwiftUI внутри; хоткей через готовый пакет.
8. **Журнал.** Список, форма, фильтры.
9. **Экспорт.**
10. **Контроль качества.** Покрытие, мутации вручную, чек-лист для UI.

### Упражнения на закрепление (по возрастанию сложности)
1. Научите `PaletteParser` суффиксу `-1h30m` (сейчас поддерживаются только `-20m` и `-2h`). Сначала напишите тесты, включая странные случаи (`-0m`, `-1h90m`, `-h`).
2. Добавьте категории-«избранное» с горячими цифрами `1`…`9` в палитре.
3. Добавьте поле «проект» к записи: что поменяется в `Models`, `EntryDraft`, экспорте и тестах? Составьте список затронутых файлов до того, как начнёте.
4. Добавьте в Журнал вид «неделя»: сумма по категориям за неделю. Начните с чистой функции и теста, как `DayGrouping`.
5. Сделайте уведомление «таймер идёт больше 4 часов». Где живут часы? Что нужно протестировать, а что нет?
6. Добавьте синхронизацию через CloudKit. Что в моделях уже подготовлено, а что придётся менять?

## 9. Грабли, на которые мы наступили (учитесь на них)

| Что случилось | Урок |
|---|---|
| Тип `Category` конфликтовал с типом из Objective-C | Импорты Apple-фреймворков приносят скрытые глобальные имена; берите осмысленные имена типов (`EntryCategory`). |
| `"\r\n"` в Swift — один `Character` | Строка Swift не UTF-16; сравнивайте через `isNewline`, а не через `== "\n"`. Это ломало CSV. |
| `didSet` срабатывает на запись того же значения | `TextField` при Enter заново присваивал текст и стирал вопрос «создать категорию?». Сравнивайте со старым значением. Юнит-тест этого не показывал; помог стенд, шлющий настоящие нажатия окну. |
| Сложные выражения в `#expect` не компилировались | Выносите ожидаемое значение в `let expected: [T] = [...]`. |
| `+86400` секунд вместо границ дня | В дни перевода часов сутки не 24 часа. Всегда используйте `Calendar`. |
| Инструмент мутаций Muter ломает файлы с кириллицей | Инструментам нужно не верить на слово; важное перепроверяйте вручную. |
| Сторонние пакеты и MCP | Читайте исходники и фиксируйте версию, а не `@latest`. |

## 10. Куда смотреть дальше

- Документация Apple прямо в сессии: подключённый MCP `apple-docs` (ищите `MenuBarExtra`, `NSPanel`, `SwiftData`).
- Как это проверялось: [testing.md](testing.md) (команды, мутации, чек-лист).
- Решения и причины: [application-design.md](application-design.md).
- Что менялось и почему: `.superpowers/sdd/.../progress.md` (локальный журнал решений, в git не попадает) и история коммитов `git log --oneline`.
