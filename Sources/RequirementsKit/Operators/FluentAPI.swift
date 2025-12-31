// MARK: - Fluent API для Requirement

extension Requirement {
  /// Комбинирует с другим требованием (AND)
  /// - Parameter other: Другое требование
  /// - Returns: Композитное требование
  public func and(_ other: Requirement<Context>) -> Requirement<Context> {
    self && other
  }
  
  /// Комбинирует с KeyPath требованием (AND)
  /// - Parameter keyPath: KeyPath к булевому значению
  /// - Returns: Композитное требование
  public func and(_ keyPath: KeyPath<Context, Bool> & Sendable) -> Requirement<Context> {
    self && Requirement.require(keyPath)
  }
  
  /// Комбинирует с другим требованием (OR)
  /// - Parameter other: Другое требование
  /// - Returns: Композитное требование
  public func or(_ other: Requirement<Context>) -> Requirement<Context> {
    self || other
  }
  
  /// Комбинирует с KeyPath требованием (OR)
  /// - Parameter keyPath: KeyPath к булевому значению
  /// - Returns: Композитное требование
  public func or(_ keyPath: KeyPath<Context, Bool> & Sendable) -> Requirement<Context> {
    self || Requirement.require(keyPath)
  }
  
  /// Логирует результат оценки (только в DEBUG)
  /// - Parameter label: Метка для логирования
  /// - Returns: Требование с логированием
  public func logged(_ label: String = "") -> Requirement<Context> {
    let original = self
    return Requirement { context in
      let result = original.evaluate(context)
      #if DEBUG
      let status = result.isConfirmed ? "✅" : "❌"
      let reasonText = result.reason.map { " - \($0.message)" } ?? ""
      print("[\(label)] \(status)\(reasonText)")
      #endif
      return result
    }
  }
  
  /// Проверяет требование и возвращает результат
  /// - Parameter context: Контекст для проверки
  /// - Returns: true если требование выполнено
  public func check(_ context: Context) -> Bool {
    evaluate(context).isConfirmed
  }
  
  /// Проверяет требование и выбрасывает ошибку при неудаче
  /// - Parameter context: Контекст для проверки
  /// - Throws: RequirementError если требование не выполнено
  public func require(_ context: Context) throws {
    let result = evaluate(context)
    if case .failed(let reason) = result {
      throw RequirementError.notMet(reason: reason)
    }
  }
}

// MARK: - RequirementError

/// Ошибка при нарушении требования
public enum RequirementError: Error, Sendable {
  case notMet(reason: Reason)
}

// MARK: - Fluent API для AsyncRequirement

extension AsyncRequirement {
  /// Комбинирует с другим асинхронным требованием (AND)
  public func and(_ other: AsyncRequirement<Context>) -> AsyncRequirement<Context> {
    self && other
  }
  
  /// Комбинирует с синхронным требованием (AND)
  public func and(_ other: Requirement<Context>) -> AsyncRequirement<Context> {
    self && other
  }
  
  /// Комбинирует с другим асинхронным требованием (OR)
  public func or(_ other: AsyncRequirement<Context>) -> AsyncRequirement<Context> {
    self || other
  }
  
  /// Комбинирует с синхронным требованием (OR)
  public func or(_ other: Requirement<Context>) -> AsyncRequirement<Context> {
    self || other
  }
  
  /// Проверяет требование и возвращает результат
  /// - Parameter context: Контекст для проверки
  /// - Returns: true если требование выполнено
  public func check(_ context: Context) async throws -> Bool {
    try await evaluate(context).isConfirmed
  }
  
  /// Проверяет требование и выбрасывает ошибку при неудаче
  /// - Parameter context: Контекст для проверки
  /// - Throws: RequirementError если требование не выполнено
  public func require(_ context: Context) async throws {
    let result = try await evaluate(context)
    if case .failed(let reason) = result {
      throw RequirementError.notMet(reason: reason)
    }
  }
}

// MARK: - Chaining Builder

/// Построитель цепочек требований
public struct RequirementChain<Context: Sendable> {
  private var requirements: [Requirement<Context>] = []
  
  public init() {}
  
  /// Добавляет требование в цепочку
  public mutating func add(_ requirement: Requirement<Context>) {
    requirements.append(requirement)
  }
  
  /// Добавляет KeyPath требование в цепочку
  public mutating func add(_ keyPath: KeyPath<Context, Bool> & Sendable) {
    requirements.append(Requirement.require(keyPath))
  }
  
  /// Собирает все требования в одно (AND)
  public func buildAll() -> Requirement<Context> {
    Requirement.all(requirements)
  }
  
  /// Собирает все требования в одно (ANY)
  public func buildAny() -> Requirement<Context> {
    Requirement.any(requirements)
  }
}

// MARK: - Convenience extensions

extension Requirement {
  /// Создает требование из предиката
  /// - Parameter predicate: Предикат для проверки
  /// - Returns: Требование на основе предиката
  public static func predicate(
    _ predicate: @escaping @Sendable (Context) -> Bool
  ) -> Requirement<Context> {
    Requirement { context in
      predicate(context) 
        ? .confirmed 
        : .failed(reason: Reason(message: "Predicate not satisfied"))
    }
  }
}

