// MARK: - ALL (Все требования должны быть выполнены)

extension Requirement {
  /// Создает составное требование, где все вложенные требования должны быть выполнены
  /// - Parameter builder: Замыкание, которое строит список требований
  /// - Returns: Требование, которое выполнено только если все вложенные требования выполнены
  public static func all(
    @RequirementsBuilder<Context> builder: () -> [Requirement<Context>]
  ) -> Requirement<Context> {
    let requirements = builder()
    
    return Requirement { context in
      var failures: [Reason] = []
      
      for requirement in requirements {
        let result = requirement.evaluate(context)
        if case .failed(let reason) = result {
          failures.append(reason)
        }
      }
      
      if failures.isEmpty {
        return .confirmed
      } else {
        // Возвращаем первую причину отказа (можно изменить логику)
        return .failed(reason: failures[0])
      }
    }
  }
  
  /// Создает составное требование из массива требований (все должны быть выполнены)
  /// - Parameter requirements: Массив требований
  /// - Returns: Требование, которое выполнено только если все требования выполнены
  public static func all(_ requirements: [Requirement<Context>]) -> Requirement<Context> {
    Requirement { context in
      var failures: [Reason] = []
      
      for requirement in requirements {
        let result = requirement.evaluate(context)
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

