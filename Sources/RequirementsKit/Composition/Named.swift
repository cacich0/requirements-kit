// MARK: - Named Requirements (Именованные требования)

extension Requirement {
  /// Создает именованное требование для целей логирования и аналитики
  /// - Parameters:
  ///   - name: Имя требования
  ///   - builder: Замыкание, которое строит требование
  /// - Returns: Именованное требование
  public static func named(
    _ name: String,
    @RequirementsBuilder<Context> builder: () -> [Requirement<Context>]
  ) -> Requirement<Context> {
    let requirements = builder()
    let combinedRequirement = Requirement.all(requirements)
    
    return Requirement { context in
      let result = combinedRequirement.evaluate(context)
      
      // Можно добавить логирование или аналитику здесь
      // print("[Requirement: \(name)] Result: \(result)")
      
      return result
    }
  }
  
  /// Создает именованное требование из одного требования
  /// - Parameters:
  ///   - name: Имя требования
  ///   - requirement: Требование
  /// - Returns: Именованное требование
  public static func named(
    _ name: String,
    requirement: Requirement<Context>
  ) -> Requirement<Context> {
    Requirement { context in
      let result = requirement.evaluate(context)
      
      // Можно добавить логирование или аналитику здесь
      // print("[Requirement: \(name)] Result: \(result)")
      
      return result
    }
  }
  
  /// Добавляет имя к существующему требованию (fluent API)
  /// - Parameter name: Имя требования
  /// - Returns: Именованное требование
  public func named(_ name: String) -> Requirement<Context> {
    Requirement.named(name, requirement: self)
  }
}

