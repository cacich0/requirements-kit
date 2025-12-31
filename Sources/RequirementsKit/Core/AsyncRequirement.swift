// MARK: - Асинхронные требования

import Foundation

/// Асинхронное требование для проверки условий, требующих async операций
/// (API вызовы, запросы к базе данных и т.д.)
public struct AsyncRequirement<Context: Sendable>: Sendable {
  private let evaluator: @Sendable (Context) async throws -> Evaluation
  
  /// Создает асинхронное требование с пользовательским evaluator
  /// - Parameter evaluator: Асинхронное замыкание для проверки требования
  public init(evaluator: @escaping @Sendable (Context) async throws -> Evaluation) {
    self.evaluator = evaluator
  }
  
  /// Выполняет асинхронную проверку требования
  /// - Parameter context: Контекст для проверки
  /// - Returns: Результат проверки
  public func evaluate(_ context: Context) async throws -> Evaluation {
    try await evaluator(context)
  }
  
  // MARK: - Фабричные методы
  
  /// Всегда подтвержденное требование
  public static var always: AsyncRequirement<Context> {
    AsyncRequirement { _ in .confirmed }
  }
  
  /// Всегда отклоненное требование
  public static var never: AsyncRequirement<Context> {
    AsyncRequirement { _ in
      .failed(reason: Reason(code: "never", message: "Requirement is never met"))
    }
  }
  
  /// Создает асинхронное требование из синхронного
  /// - Parameter requirement: Синхронное требование
  /// - Returns: Асинхронная обертка
  public static func from(_ requirement: Requirement<Context>) -> AsyncRequirement<Context> {
    let evaluator = requirement.evaluate
    return AsyncRequirement { context in
      evaluator(context)
    }
  }
  
  /// Создает асинхронное требование с таймаутом
  /// - Parameters:
  ///   - timeoutSeconds: Таймаут в секундах
  ///   - requirement: Асинхронное требование
  /// - Returns: Требование с таймаутом
  @available(macOS 13.0, iOS 16.0, watchOS 9.0, tvOS 16.0, *)
  public static func withTimeout(
    seconds timeoutSeconds: Double,
    _ requirement: AsyncRequirement<Context>
  ) -> AsyncRequirement<Context> {
    AsyncRequirement { context in
      do {
        return try await withThrowingTaskGroup(of: Evaluation.self) { group in
          group.addTask {
            try await requirement.evaluate(context)
          }
          
          group.addTask {
            try await Task.sleep(for: .seconds(timeoutSeconds))
            throw AsyncRequirementError.timeout
          }
          
          guard let result = try await group.next() else {
            throw AsyncRequirementError.timeout
          }
          
          group.cancelAll()
          return result
        }
      } catch is AsyncRequirementError {
        return .failed(reason: Reason(
          code: "timeout",
          message: "Requirement evaluation timed out"
        ))
      } catch {
        return .failed(reason: Reason(
          code: "error",
          message: String(describing: error)
        ))
      }
    }
  }
}

// MARK: - Ошибки

/// Ошибки асинхронных требований
public enum AsyncRequirementError: Error, Sendable {
  case timeout
  case cancelled
}

// MARK: - Причины отказа

extension AsyncRequirement {
  /// Добавляет причину отказа к требованию
  /// - Parameters:
  ///   - code: Код причины
  ///   - message: Сообщение
  /// - Returns: Требование с обновленной причиной отказа
  public func because(code: String, message: String) -> AsyncRequirement<Context> {
    let evaluator = self.evaluator
    return AsyncRequirement { context in
      let result = try await evaluator(context)
      switch result {
      case .confirmed:
        return .confirmed
      case .failed:
        return .failed(reason: Reason(code: code, message: message))
      }
    }
  }
  
  /// Добавляет причину отказа к требованию (краткий синтаксис)
  /// - Parameter reason: Причина
  /// - Returns: Требование с обновленной причиной отказа
  public func because(_ reason: Reason) -> AsyncRequirement<Context> {
    because(code: reason.code, message: reason.message)
  }
}

// MARK: - Композиция

extension AsyncRequirement {
  /// Композиция: все асинхронные требования должны быть выполнены
  public static func all(_ requirements: [AsyncRequirement<Context>]) -> AsyncRequirement<Context> {
    AsyncRequirement { context in
      var failures: [Reason] = []
      
      for requirement in requirements {
        let result = try await requirement.evaluate(context)
        if case .failed(let reason) = result {
          failures.append(reason)
        }
      }
      
      if failures.isEmpty {
        return .confirmed
      } else {
        return .failed(reason: failures[0])
      }
    }
  }
  
  /// Композиция: все асинхронные требования должны быть выполнены (параллельно)
  public static func allConcurrent(_ requirements: [AsyncRequirement<Context>]) -> AsyncRequirement<Context> {
    AsyncRequirement { context in
      try await withThrowingTaskGroup(of: Evaluation.self) { group in
        for requirement in requirements {
          group.addTask {
            try await requirement.evaluate(context)
          }
        }
        
        var failures: [Reason] = []
        
        for try await result in group {
          if case .failed(let reason) = result {
            failures.append(reason)
          }
        }
        
        if failures.isEmpty {
          return .confirmed
        } else {
          return .failed(reason: failures[0])
        }
      }
    }
  }
  
  /// Композиция: хотя бы одно асинхронное требование должно быть выполнено
  public static func any(_ requirements: [AsyncRequirement<Context>]) -> AsyncRequirement<Context> {
    AsyncRequirement { context in
      for requirement in requirements {
        let result = try await requirement.evaluate(context)
        if case .confirmed = result {
          return .confirmed
        }
      }
      
      return .failed(reason: Reason(
        code: "any_failed",
        message: "None of the alternative requirements were met"
      ))
    }
  }
  
  /// Композиция: хотя бы одно асинхронное требование должно быть выполнено (параллельно, первый успешный)
  public static func anyConcurrent(_ requirements: [AsyncRequirement<Context>]) -> AsyncRequirement<Context> {
    AsyncRequirement { context in
      try await withThrowingTaskGroup(of: Evaluation.self) { group in
        for requirement in requirements {
          group.addTask {
            try await requirement.evaluate(context)
          }
        }
        
        for try await result in group {
          if case .confirmed = result {
            group.cancelAll()
            return .confirmed
          }
        }
        
        return .failed(reason: Reason(
          code: "any_failed",
          message: "None of the alternative requirements were met"
        ))
      }
    }
  }
  
  /// Инверсия асинхронного требования
  public static func not(_ requirement: AsyncRequirement<Context>) -> AsyncRequirement<Context> {
    AsyncRequirement { context in
      let result = try await requirement.evaluate(context)
      
      switch result {
      case .confirmed:
        return .failed(reason: Reason(
          code: "not_failed",
          message: "Requirement should not be met"
        ))
      case .failed:
        return .confirmed
      }
    }
  }
  
  /// Инверсия (fluent API)
  public func not() -> AsyncRequirement<Context> {
    AsyncRequirement.not(self)
  }
}
