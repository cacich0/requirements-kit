// MARK: - ANY (Хотя бы одно требование должно быть выполнено)

extension Requirement {
  /// Создает составное требование, где хотя бы одно вложенное требование должно быть выполнено
  /// - Parameter builder: Замыкание, которое строит список требований
  /// - Returns: Требование, которое выполнено если хотя бы одно вложенное требование выполнено
  public static func any(
    @RequirementsBuilder<Context> builder: () -> [Requirement<Context>]
  ) -> Requirement<Context> {
    let requirements = builder()
    
    return Requirement { context in
      var failures: [Reason] = []
      
      for requirement in requirements {
        let result = requirement.evaluate(context)
        if case .confirmed = result {
          return .confirmed
        } else if case .failed(let reason) = result {
          failures.append(reason)
        }
      }
      
      // Ни одно требование не выполнено
      if failures.isEmpty {
        return .failed(reason: Reason(message: "No requirements provided"))
      } else {
        return .failed(reason: Reason(
          code: "any_failed",
          message: "None of the alternative requirements were met"
        ))
      }
    }
  }
  
  /// Создает составное требование из массива требований (хотя бы одно должно быть выполнено)
  /// - Parameter requirements: Массив требований
  /// - Returns: Требование, которое выполнено если хотя бы одно требование выполнено
  public static func any(_ requirements: [Requirement<Context>]) -> Requirement<Context> {
    Requirement { context in
      var failures: [Reason] = []
      
      for requirement in requirements {
        let result = requirement.evaluate(context)
        if case .confirmed = result {
          return .confirmed
        } else if case .failed(let reason) = result {
          failures.append(reason)
        }
      }
      
      if failures.isEmpty {
        return .failed(reason: Reason(message: "No requirements provided"))
      } else {
        return .failed(reason: Reason(
          code: "any_failed",
          message: "None of the alternative requirements were met"
        ))
      }
    }
  }
}

