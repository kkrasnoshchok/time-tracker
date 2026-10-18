import Foundation

extension StoreError {
    /// Text for the person using the app (shown in the palette and the Journal).
    public var message: String {
        switch self {
        case .emptyName: "Введите название."
        case .duplicateName: "Такое название уже есть."
        case .categoryHasEntries: "В категории есть записи. Сначала перенесите их в другую."
        case .startInFuture: "Время начала не может быть в будущем."
        case .endInFuture: "Время окончания не может быть в будущем."
        case .missingEnd: "Укажите время окончания."
        case .endBeforeStart: "Конец записи раньше её начала."
        case .overlap(let ids): "Пересекается с другими записями: \(ids.count)."
        case .noRunningTimer: "Таймер не запущен."
        case .notFound: "Запись не найдена."
        case .saveFailed(let reason): "Не удалось сохранить: \(reason)"
        }
    }
}
