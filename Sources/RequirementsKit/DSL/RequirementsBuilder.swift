/// Result Builder для декларативного описания требований
@resultBuilder
public enum RequirementsBuilder<Context: Sendable> {
  
  /// Собирает блок из нескольких требований
  public static func buildBlock(_ components: [Requirement<Context>]...) -> [Requirement<Context>] {
    components.flatMap { $0 }
  }
  
  /// Преобразует одно требование в массив
  public static func buildExpression(_ expression: Requirement<Context>) -> [Requirement<Context>] {
    [expression]
  }
  
  /// Преобразует KeyPath в требование
  public static func buildExpression(_ keyPath: KeyPath<Context, Bool> & Sendable) -> [Requirement<Context>] {
    [Requirement<Context>.require(keyPath)]
  }
  
  /// Обрабатывает опциональные требования (if без else)
  public static func buildOptional(_ component: [Requirement<Context>]?) -> [Requirement<Context>] {
    component ?? []
  }
  
  /// Обрабатывает первую ветку if-else
  public static func buildEither(first component: [Requirement<Context>]) -> [Requirement<Context>] {
    component
  }
  
  /// Обрабатывает вторую ветку if-else
  public static func buildEither(second component: [Requirement<Context>]) -> [Requirement<Context>] {
    component
  }
  
  /// Обрабатывает массивы требований (for-in)
  public static func buildArray(_ components: [[Requirement<Context>]]) -> [Requirement<Context>] {
    components.flatMap { $0 }
  }
  
  /// Поддержка limited availability (if #available)
  public static func buildLimitedAvailability(_ component: [Requirement<Context>]) -> [Requirement<Context>] {
    component
  }
  
  /// Финальная трансформация результата
  public static func buildFinalResult(_ component: [Requirement<Context>]) -> [Requirement<Context>] {
    component
  }
}

// MARK: - Rate Limiting Support

extension RequirementsBuilder {
  /// Поддержка RateLimitedRequirement в builder
  public static func buildExpression(
    _ expression: RateLimitedRequirement<Context>
  ) -> [Requirement<Context>] {
    [Requirement { context in
      expression.evaluate(context)
    }]
  }
  
  /// Поддержка ThrottledRequirement в builder
  public static func buildExpression(
    _ expression: ThrottledRequirement<Context>
  ) -> [Requirement<Context>] {
    [Requirement { context in
      expression.evaluate(context)
    }]
  }
}
