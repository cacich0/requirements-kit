// MARK: - Валидация коллекций

extension Requirement {
  /// Проверяет, что все элементы коллекции удовлетворяют условию
  /// - Parameters:
  ///   - keyPath: Путь к коллекции
  ///   - predicate: Предикат для каждого элемента
  /// - Returns: Требование
  public static func requireAll<Element: Sendable>(
    _ keyPath: KeyPath<Context, [Element]> & Sendable,
    where predicate: @escaping @Sendable (Element) -> Bool
  ) -> Requirement<Context> {
    Requirement { context in
      let collection = context[keyPath: keyPath]
      let allMatch = collection.allSatisfy(predicate)
      
      return allMatch
        ? .confirmed
        : .failed(reason: Reason(
            code: "collection.not_all_match",
            message: "Not all elements satisfy the requirement"
          ))
    }
  }
  
  /// Проверяет, что хотя бы один элемент удовлетворяет условию
  /// - Parameters:
  ///   - keyPath: Путь к коллекции
  ///   - predicate: Предикат для элемента
  /// - Returns: Требование
  public static func requireAny<Element: Sendable>(
    _ keyPath: KeyPath<Context, [Element]> & Sendable,
    where predicate: @escaping @Sendable (Element) -> Bool
  ) -> Requirement<Context> {
    Requirement { context in
      let collection = context[keyPath: keyPath]
      let anyMatch = collection.contains(where: predicate)
      
      return anyMatch
        ? .confirmed
        : .failed(reason: Reason(
            code: "collection.none_match",
            message: "No elements satisfy the requirement"
          ))
    }
  }
  
  /// Проверяет, что ни один элемент не удовлетворяет условию
  /// - Parameters:
  ///   - keyPath: Путь к коллекции
  ///   - predicate: Предикат для элемента
  /// - Returns: Требование
  public static func requireNone<Element: Sendable>(
    _ keyPath: KeyPath<Context, [Element]> & Sendable,
    where predicate: @escaping @Sendable (Element) -> Bool
  ) -> Requirement<Context> {
    Requirement { context in
      let collection = context[keyPath: keyPath]
      let noneMatch = !collection.contains(where: predicate)
      
      return noneMatch
        ? .confirmed
        : .failed(reason: Reason(
            code: "collection.some_match",
            message: "Some elements match when none should"
          ))
    }
  }
  
  /// Проверяет количество элементов в коллекции
  /// - Parameters:
  ///   - keyPath: Путь к коллекции
  ///   - min: Минимальное количество (опционально)
  ///   - max: Максимальное количество (опционально)
  /// - Returns: Требование
  public static func requireCount<C: Collection & Sendable>(
    _ keyPath: KeyPath<Context, C> & Sendable,
    min: Int? = nil,
    max: Int? = nil
  ) -> Requirement<Context> {
    Requirement { context in
      let collection = context[keyPath: keyPath]
      let count = collection.count
      
      if let min = min, count < min {
        return .failed(reason: Reason(
          code: "collection.count_too_small",
          message: "Collection has \(count) elements, minimum is \(min)"
        ))
      }
      
      if let max = max, count > max {
        return .failed(reason: Reason(
          code: "collection.count_too_large",
          message: "Collection has \(count) elements, maximum is \(max)"
        ))
      }
      
      return .confirmed
    }
  }
  
  /// Проверяет, что коллекция не пустая
  /// - Parameter keyPath: Путь к коллекции
  /// - Returns: Требование
  public static func requireNotEmpty<C: Collection & Sendable>(
    _ keyPath: KeyPath<Context, C> & Sendable
  ) -> Requirement<Context> {
    Requirement { context in
      let collection = context[keyPath: keyPath]
      
      return !collection.isEmpty
        ? .confirmed
        : .failed(reason: Reason(
            code: "collection.empty",
            message: "Collection must not be empty"
          ))
    }
  }
  
  /// Проверяет, что коллекция пустая
  /// - Parameter keyPath: Путь к коллекции
  /// - Returns: Требование
  public static func requireEmpty<C: Collection & Sendable>(
    _ keyPath: KeyPath<Context, C> & Sendable
  ) -> Requirement<Context> {
    Requirement { context in
      let collection = context[keyPath: keyPath]
      
      return collection.isEmpty
        ? .confirmed
        : .failed(reason: Reason(
            code: "collection.not_empty",
            message: "Collection must be empty"
          ))
    }
  }
  
  /// Проверяет, что коллекция содержит элемент
  /// - Parameters:
  ///   - keyPath: Путь к коллекции
  ///   - element: Элемент для поиска
  /// - Returns: Требование
  public static func requireContains<Element: Equatable & Sendable>(
    _ keyPath: KeyPath<Context, [Element]> & Sendable,
    element: Element
  ) -> Requirement<Context> {
    Requirement { context in
      let collection = context[keyPath: keyPath]
      
      return collection.contains(element)
        ? .confirmed
        : .failed(reason: Reason(
            code: "collection.missing_element",
            message: "Collection does not contain required element"
          ))
    }
  }
}

