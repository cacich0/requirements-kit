// MARK: - Условная композиция

extension Requirement {
  /// Создает условное требование - проверяется только если условие истинно
  /// - Parameters:
  ///   - condition: KeyPath к булевому условию
  ///   - builder: Builder для требований
  /// - Returns: Требование, которое проверяется только при выполнении условия
  public static func when(
    _ condition: KeyPath<Context, Bool> & Sendable,
    @RequirementsBuilder<Context> builder: () -> [Requirement<Context>]
  ) -> Requirement<Context> {
    let requirements = builder()
    
    return Requirement { context in
      // Если условие не выполнено, требование считается выполненным
      guard context[keyPath: condition] else {
        return .confirmed
      }
      
      // Проверяем все вложенные требования
      for requirement in requirements {
        let result = requirement.evaluate(context)
        if case .failed = result {
          return result
        }
      }
      
      return .confirmed
    }
  }
  
  /// Создает условное требование - проверяется только если условие ложно
  /// - Parameters:
  ///   - condition: KeyPath к булевому условию
  ///   - builder: Builder для требований
  /// - Returns: Требование, которое проверяется только при невыполнении условия
  public static func unless(
    _ condition: KeyPath<Context, Bool> & Sendable,
    @RequirementsBuilder<Context> builder: () -> [Requirement<Context>]
  ) -> Requirement<Context> {
    let requirements = builder()
    
    return Requirement { context in
      // Если условие выполнено, требование считается выполненным
      guard !context[keyPath: condition] else {
        return .confirmed
      }
      
      // Проверяем все вложенные требования
      for requirement in requirements {
        let result = requirement.evaluate(context)
        if case .failed = result {
          return result
        }
      }
      
      return .confirmed
    }
  }
  
  /// XOR композиция - ровно одно требование должно быть выполнено
  /// - Parameter builder: Builder для требований
  /// - Returns: Требование, которое выполнено если ровно одно вложенное требование выполнено
  public static func xor(
    @RequirementsBuilder<Context> builder: () -> [Requirement<Context>]
  ) -> Requirement<Context> {
    let requirements = builder()
    
    return Requirement { context in
      var confirmedCount = 0
      
      for requirement in requirements {
        let result = requirement.evaluate(context)
        if case .confirmed = result {
          confirmedCount += 1
        }
      }
      
      if confirmedCount == 1 {
        return .confirmed
      } else if confirmedCount == 0 {
        return .failed(reason: Reason(
          code: "xor_none",
          message: "No requirements were met"
        ))
      } else {
        return .failed(reason: Reason(
          code: "xor_multiple",
          message: "Multiple requirements were met, expected exactly one"
        ))
      }
    }
  }
  
  /// Мягкое требование - не блокирует, но отмечает предупреждение
  /// - Parameter keyPath: KeyPath к булевому значению
  /// - Returns: Требование, которое всегда подтверждено (для использования с middleware)
  public static func warn(
    _ keyPath: KeyPath<Context, Bool> & Sendable
  ) -> Requirement<Context> {
    // Мягкие требования всегда подтверждены, но могут логироваться через middleware
    Requirement { context in
      let value = context[keyPath: keyPath]
      if !value {
        // В production использовать middleware для логирования
        #if DEBUG
        print("⚠️ Warning: requirement not met at \(keyPath)")
        #endif
      }
      return .confirmed
    }
  }
}

// MARK: - Fallback

extension Requirement {
  /// Создает требование с fallback - если основное требование не выполнено,
  /// проверяется fallback
  /// - Parameter fallbackBuilder: Builder для fallback требований
  /// - Returns: Требование с fallback логикой
  public func fallback(
    @RequirementsBuilder<Context> _ fallbackBuilder: () -> [Requirement<Context>]
  ) -> Requirement<Context> {
    let primaryRequirement = self
    let fallbackRequirements = fallbackBuilder()
    
    return Requirement { context in
      let primaryResult = primaryRequirement.evaluate(context)
      
      // Если основное требование выполнено - возвращаем его
      if case .confirmed = primaryResult {
        return .confirmed
      }
      
      // Проверяем fallback требования
      for requirement in fallbackRequirements {
        let result = requirement.evaluate(context)
        if case .failed = result {
          return result
        }
      }
      
      return .confirmed
    }
  }
  
  /// Создает требование с fallback из другого требования
  /// - Parameter fallback: Fallback требование
  /// - Returns: Требование с fallback логикой
  public func orFallback(to fallback: Requirement<Context>) -> Requirement<Context> {
    let primaryRequirement = self
    
    return Requirement { context in
      let primaryResult = primaryRequirement.evaluate(context)
      
      if case .confirmed = primaryResult {
        return .confirmed
      }
      
      return fallback.evaluate(context)
    }
  }
}

