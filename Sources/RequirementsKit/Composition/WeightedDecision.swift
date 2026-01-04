import Foundation

// MARK: - Взвешенные решения

/// Взвешенное решение для A/B тестирования и экспериментов
public struct WeightedDecision<Context: Sendable, Result: Sendable>: Sendable {
  /// Опция с весом и решением
  public struct Option: Sendable {
    /// Вес опции (должен быть положительным)
    public let weight: Double
    
    /// Решение для данной опции
    public let decision: Decision<Context, Result>
    
    /// Инициализатор
    /// - Parameters:
    ///   - weight: Вес опции (должен быть > 0)
    ///   - decision: Решение
    public init(weight: Double, decision: Decision<Context, Result>) {
      precondition(weight > 0, "Weight must be positive")
      self.weight = weight
      self.decision = decision
    }
  }
  
  private let options: [Option]
  private let seed: UInt64?
  
  /// Создает взвешенное решение
  /// - Parameters:
  ///   - options: Массив опций с весами
  ///   - seed: Опциональное зерно для детерминированного выбора
  public init(options: [Option], seed: UInt64? = nil) {
    precondition(!options.isEmpty, "Options cannot be empty")
    self.options = options
    self.seed = seed
  }
  
  /// Выбирает решение на основе весов
  /// - Parameter context: Контекст для принятия решения
  /// - Returns: Результат выбранного решения
  public func decide(_ context: Context) -> Result? {
    // Вычисляем общий вес
    let totalWeight = options.reduce(0.0) { $0 + $1.weight }
    
    // Генерируем случайное число
    let random: Double
    if let seed = seed {
      // Детерминированная генерация для тестирования
      var generator = SeededRandomNumberGenerator(seed: seed)
      random = Double.random(in: 0..<totalWeight, using: &generator)
    } else {
      random = Double.random(in: 0..<totalWeight)
    }
    
    // Выбираем опцию на основе веса
    var accumulated: Double = 0
    for option in options {
      accumulated += option.weight
      if random < accumulated {
        return option.decision.decide(context)
      }
    }
    
    // Fallback на последнюю опцию (на случай ошибок округления)
    return options.last?.decision.decide(context)
  }
}

// MARK: - Seeded Random Number Generator

/// Генератор случайных чисел с зерном для детерминированности
private struct SeededRandomNumberGenerator: RandomNumberGenerator {
  private var state: UInt64
  
  init(seed: UInt64) {
    self.state = seed
  }
  
  mutating func next() -> UInt64 {
    // Linear congruential generator
    state = state &* 6364136223846793005 &+ 1442695040888963407
    return state
  }
}

// MARK: - Decision Extensions

extension Decision {
  /// Создает взвешенное решение из массива опций
  /// - Parameters:
  ///   - options: Массив опций с весами
  ///   - seed: Опциональное зерно для детерминированного выбора
  /// - Returns: Взвешенное решение
  public static func weighted(
    _ options: [WeightedDecision<Context, Result>.Option],
    seed: UInt64? = nil
  ) -> Decision<Context, Result> {
    let weightedDecision = WeightedDecision(options: options, seed: seed)
    return Decision { context in
      weightedDecision.decide(context)
    }
  }
  
  /// Создает взвешенное решение из массива кортежей
  /// - Parameters:
  ///   - options: Массив кортежей (вес, решение)
  ///   - seed: Опциональное зерно для детерминированного выбора
  /// - Returns: Взвешенное решение
  public static func weighted(
    _ options: [(weight: Double, decision: Decision<Context, Result>)],
    seed: UInt64? = nil
  ) -> Decision<Context, Result> {
    let weightedOptions = options.map { WeightedDecision<Context, Result>.Option(weight: $0.weight, decision: $0.decision) }
    return weighted(weightedOptions, seed: seed)
  }
}

// MARK: - Async Weighted Decisions

/// Взвешенное асинхронное решение для A/B тестирования
public struct WeightedAsyncDecision<Context: Sendable, Result: Sendable>: Sendable {
  /// Опция с весом и асинхронным решением
  public struct Option: Sendable {
    /// Вес опции (должен быть положительным)
    public let weight: Double
    
    /// Асинхронное решение для данной опции
    public let decision: AsyncDecision<Context, Result>
    
    /// Инициализатор
    /// - Parameters:
    ///   - weight: Вес опции (должен быть > 0)
    ///   - decision: Асинхронное решение
    public init(weight: Double, decision: AsyncDecision<Context, Result>) {
      precondition(weight > 0, "Weight must be positive")
      self.weight = weight
      self.decision = decision
    }
  }
  
  private let options: [Option]
  private let seed: UInt64?
  
  /// Создает взвешенное асинхронное решение
  /// - Parameters:
  ///   - options: Массив опций с весами
  ///   - seed: Опциональное зерно для детерминированного выбора
  public init(options: [Option], seed: UInt64? = nil) {
    precondition(!options.isEmpty, "Options cannot be empty")
    self.options = options
    self.seed = seed
  }
  
  /// Выбирает решение на основе весов
  /// - Parameter context: Контекст для принятия решения
  /// - Returns: Результат выбранного решения
  public func decide(_ context: Context) async throws -> Result? {
    // Вычисляем общий вес
    let totalWeight = options.reduce(0.0) { $0 + $1.weight }
    
    // Генерируем случайное число
    let random: Double
    if let seed = seed {
      // Детерминированная генерация для тестирования
      var generator = SeededRandomNumberGenerator(seed: seed)
      random = Double.random(in: 0..<totalWeight, using: &generator)
    } else {
      random = Double.random(in: 0..<totalWeight)
    }
    
    // Выбираем опцию на основе веса
    var accumulated: Double = 0
    for option in options {
      accumulated += option.weight
      if random < accumulated {
        return try await option.decision.decide(context)
      }
    }
    
    // Fallback на последнюю опцию (на случай ошибок округления)
    return try await options.last?.decision.decide(context)
  }
}

// MARK: - AsyncDecision Extensions

extension AsyncDecision {
  /// Создает взвешенное асинхронное решение из массива опций
  /// - Parameters:
  ///   - options: Массив опций с весами
  ///   - seed: Опциональное зерно для детерминированного выбора
  /// - Returns: Взвешенное решение
  public static func weighted(
    _ options: [WeightedAsyncDecision<Context, Result>.Option],
    seed: UInt64? = nil
  ) -> AsyncDecision<Context, Result> {
    let weightedDecision = WeightedAsyncDecision(options: options, seed: seed)
    return AsyncDecision { context in
      try await weightedDecision.decide(context)
    }
  }
  
  /// Создает взвешенное асинхронное решение из массива кортежей
  /// - Parameters:
  ///   - options: Массив кортежей (вес, решение)
  ///   - seed: Опциональное зерно для детерминированного выбора
  /// - Returns: Взвешенное решение
  public static func weighted(
    _ options: [(weight: Double, decision: AsyncDecision<Context, Result>)],
    seed: UInt64? = nil
  ) -> AsyncDecision<Context, Result> {
    let weightedOptions = options.map { WeightedAsyncDecision<Context, Result>.Option(weight: $0.weight, decision: $0.decision) }
    return weighted(weightedOptions, seed: seed)
  }
}

