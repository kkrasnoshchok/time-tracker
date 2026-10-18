# Swift для JS-разработчика: заметки по задачам

Короткие объяснения новых концепций через аналогии с TypeScript/React. Пополняется после каждой задачи.

## Task 0: пакет и проект
- `Package.swift` = `package.json` + конфиг workspace, `swift test` = `npm test`, `@main` = точка входа приложения.
- XcodeGen: `project.yml` описывает проект текстом вместо бинарного `.xcodeproj` (его мы не коммитим, как `node_modules`).
- `@testable import X` даёт тестам доступ к `internal`-коду модуля; без него видно только `public`.

## Task 1: TimeProvider и TimeSpan
- `struct` это значение: при присваивании копируется (как неизменяемый объект с `Object.freeze`). `class` это ссылка, как обычный объект JS.
- `let` это `const`, `var` это `let`. `Date?` (Optional) это `Date | undefined`, но компилятор заставляет его обработать.
- `throws(TimeSpanError)` это типизированные ошибки: в TS `throw` принимает что угодно, здесь тип ошибки часть сигнатуры.
- `protocol TimeProvider` это TS `interface`. Мы передаём «источник времени» как зависимость, потому что вызов `Date()` внутри логики сделал бы тесты нестабильными (как `Date.now()` без `jest.useFakeTimers`).
- `Sendable` обещает компилятору, что тип можно безопасно передавать между потоками (в JS поток один, поэтому такого понятия нет).
- `Mutex` (в тестовом хелпере) защищает общее изменяемое значение от гонок между потоками.
- Тесты: `@Test` = `it(...)`, `#expect(a == b)` = `expect(a).toBe(b)`, `#expect(throws: E) { ... }` = `expect(() => ...).toThrow(E)`.

## Task 2: PaletteParser
- `enum PaletteParser` без `case` это «пустое» пространство имён со статическими функциями, как модуль с экспортами в TS; создать экземпляр нельзя.
- `enum` с ассоциированными значениями (`case existing(String)`, `case unknown(String)`) это discriminated union: в TS это `{ type: "existing", name: string } | { type: "unknown", word: string }`. `switch` обязан разобрать все варианты.
- `String` в Swift состоит из `Character` (то, что человек видит как один символ), а не из UTF-16 как в JS: `"🔥".count == 1`, а в JS `"🔥".length == 2`.
- `split(whereSeparator:)`, `map`, `prefix`, `dropFirst`, `joined` это те же `split`, `map`, `slice`, `join`, только ленивые и безопасные по границам. `\.isWhitespace` это key path: короткая запись `{ $0.isWhitespace }`.
- `guard let x = ... else { return }` это ранний выход с распаковкой Optional: в TS аналог `if (x == null) return;`, после которого `x` уже не `undefined`.
- Кортеж `(name: String, wordCount: Int)` это лёгкий безымянный объект `{ name, wordCount }` без объявления типа.
