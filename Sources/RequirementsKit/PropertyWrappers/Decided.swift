import Foundation

// MARK: - Property Wrapper для Decision

/// Property wrapper для автоматического принятия решения на основе контекста
///
/// Использование:
/// ```swift
/// struct ViewModel {
///   let context: RequestContext
///
///   @Decided(decision: routeDecision)
///   var currentRoute: Route
///
///   init(context: RequestContext) {
///     self.context = context
///     _currentRoute = Decided(decision: routeDecision, context: context)
///   }
/// }
/// ```
@propertyWrapper
public struct Decided<Context: Sendable, Result: Sendable>: Sendable {
  private let decision: Decision<Context, Result>
  private let context: Context
  private let defaultValue: Result?
  
  /// Создает property wrapper с решением и контекстом
  /// - Parameters:
  ///   - decision: Решение для принятия
  ///   - context: Контекст для принятия решения
  ///   - defaultValue: Значение по умолчанию, если решение вернет nil
  public init(
    decision: Decision<Context, Result>,
    context: Context,
    defaultValue: Result? = nil
  ) {
    self.decision = decision
    self.context = context
    self.defaultValue = defaultValue
  }
  
  /// Возвращает результат решения
  public var wrappedValue: Result? {
    decision.decide(context) ?? defaultValue
  }
  
  /// Возвращает проекцию с доступом к решению и контексту
  public var projectedValue: DecidedProjection<Context, Result> {
    DecidedProjection(decision: decision, context: context, result: wrappedValue)
  }
}

/// Проекция для property wrapper Decided
public struct DecidedProjection<Context: Sendable, Result: Sendable>: Sendable {
  public let decision: Decision<Context, Result>
  public let context: Context
  public let result: Result?
  
  /// Пересчитывает решение с новым контекстом
  /// - Parameter newContext: Новый контекст
  /// - Returns: Результат решения для нового контекста
  public func recalculate(with newContext: Context) -> Result? {
    decision.decide(newContext)
  }
}

// MARK: - Property Wrapper для AsyncDecision

/// Property wrapper для автоматического принятия асинхронного решения на основе контекста
///
/// Использование:
/// ```swift
/// @MainActor
/// class ViewModel: ObservableObject {
///   let context: RequestContext
///
///   @AsyncDecided(decision: routeDecision)
///   var currentRoute: Route?
///
///   init(context: RequestContext) {
///     self.context = context
///     _currentRoute = AsyncDecided(decision: routeDecision, context: context)
///   }
///
///   func loadRoute() async {
///     await _currentRoute.evaluate()
///   }
/// }
/// ```
@propertyWrapper
public final class AsyncDecided<Context: Sendable, Result: Sendable>: Sendable {
  private let decision: AsyncDecision<Context, Result>
  private let context: Context
  private let defaultValue: Result?
  private let storage: AsyncDecidedStorage<Result>
  
  /// Создает property wrapper с асинхронным решением и контекстом
  /// - Parameters:
  ///   - decision: Асинхронное решение для принятия
  ///   - context: Контекст для принятия решения
  ///   - defaultValue: Значение по умолчанию, если решение вернет nil
  public init(
    decision: AsyncDecision<Context, Result>,
    context: Context,
    defaultValue: Result? = nil
  ) {
    self.decision = decision
    self.context = context
    self.defaultValue = defaultValue
    self.storage = AsyncDecidedStorage()
  }
  
  /// Возвращает кешированный результат решения или значение по умолчанию
  /// Примечание: Для получения актуального значения используйте $property.evaluate()
  public var wrappedValue: Result? {
    defaultValue
  }
  
  /// Возвращает проекцию с доступом к решению и методам
  public var projectedValue: AsyncDecidedProjection<Context, Result> {
    AsyncDecidedProjection(wrapper: self, defaultValue: defaultValue)
  }
  
  /// Вычисляет решение асинхронно и кеширует результат
  @discardableResult
  func evaluate() async throws -> Result? {
    let result = try await decision.decide(context)
    await storage.setCachedResult(result)
    return result ?? defaultValue
  }
  
  /// Вычисляет решение с новым контекстом
  /// - Parameter newContext: Новый контекст
  /// - Returns: Результат решения
  func evaluate(with newContext: Context) async throws -> Result? {
    let result = try await decision.decide(newContext)
    await storage.setCachedResult(result)
    return result ?? defaultValue
  }
  
  /// Получает кешированный результат
  func getCachedResult() async -> Result? {
    await storage.getCachedResult() ?? defaultValue
  }
  
  /// Очищает кешированный результат
  func invalidate() async {
    await storage.setCachedResult(nil)
  }
}

/// Actor для thread-safe хранения кешированного результата
private actor AsyncDecidedStorage<Result: Sendable> {
  private var cachedResult: Result?
  
  func getCachedResult() -> Result? {
    cachedResult
  }
  
  func setCachedResult(_ result: Result?) {
    cachedResult = result
  }
}

/// Проекция для property wrapper AsyncDecided
public struct AsyncDecidedProjection<Context: Sendable, Result: Sendable>: Sendable {
  private let wrapper: AsyncDecided<Context, Result>
  private let defaultValue: Result?
  
  init(wrapper: AsyncDecided<Context, Result>, defaultValue: Result?) {
    self.wrapper = wrapper
    self.defaultValue = defaultValue
  }
  
  /// Вычисляет решение асинхронно и возвращает результат
  public func evaluate() async throws -> Result? {
    try await wrapper.evaluate()
  }
  
  /// Вычисляет решение с новым контекстом
  /// - Parameter newContext: Новый контекст
  /// - Returns: Результат решения
  public func evaluate(with newContext: Context) async throws -> Result? {
    try await wrapper.evaluate(with: newContext)
  }
  
  /// Получает текущий кешированный результат
  public func value() async -> Result? {
    await wrapper.getCachedResult()
  }
  
  /// Очищает кешированный результат
  public func invalidate() async {
    await wrapper.invalidate()
  }
}

// MARK: - Удобные расширения

extension Decided where Result: Equatable {
  /// Проверяет, равен ли результат решения ожидаемому значению
  /// - Parameter expected: Ожидаемое значение
  /// - Returns: true, если результат равен ожидаемому значению
  public func isEqual(to expected: Result) -> Bool {
    wrappedValue == expected
  }
}

extension AsyncDecided where Result: Equatable {
  /// Проверяет, равен ли кешированный результат решения ожидаемому значению
  /// - Parameter expected: Ожидаемое значение
  /// - Returns: true, если результат равен ожидаемому значению
  public func isEqual(to expected: Result) async -> Bool {
    await getCachedResult() == expected
  }
}

