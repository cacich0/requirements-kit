import Foundation

// MARK: - Debounced Requirement

/// Требование с debouncing - отложенное выполнение с отменой предыдущих вызовов
///
/// Debouncing откладывает выполнение требования до тех пор, пока не пройдет
/// указанный интервал без новых вызовов. Если приходит новый вызов до истечения
/// интервала, предыдущий вызов отменяется.
///
/// Примечание: Для синхронных требований debounce работает асинхронно,
/// поэтому результат возвращается через callback.
public final class DebouncedRequirement<Context: Sendable>: @unchecked Sendable {
  private let requirement: Requirement<Context>
  private let delay: TimeInterval
  private let behavior: DebounceBehavior
  
  private var workItem: DispatchWorkItem?
  private let lock = NSLock()
  private let queue = DispatchQueue(label: "com.requirementskit.debounce", qos: .userInitiated)
  
  /// Инициализатор
  /// - Parameters:
  ///   - requirement: Базовое требование
  ///   - delay: Задержка в секундах
  ///   - behavior: Поведение debounce
  public init(
    requirement: Requirement<Context>,
    delay: TimeInterval,
    behavior: DebounceBehavior = .default
  ) {
    self.requirement = requirement
    self.delay = delay
    self.behavior = behavior
  }
  
  /// Оценивает требование с учетом debouncing
  /// - Parameters:
  ///   - context: Контекст для оценки
  ///   - completion: Callback с результатом оценки
  public func evaluate(_ context: Context, completion: @escaping @Sendable (Evaluation) -> Void) {
    lock.lock()
    
    // Обрабатываем behavior
    switch behavior {
    case .cancelPrevious:
      // Отменяем предыдущий запланированный вызов
      workItem?.cancel()
      
    case .ignoreNew:
      // Если есть активный вызов, игнорируем новый
      if let item = workItem, !item.isCancelled {
        lock.unlock()
        return
      }
    }
    
    // Создаем новый work item
    let item = DispatchWorkItem { [weak self] in
      guard let self = self else { return }
      let result = self.requirement.evaluate(context)
      
      // Очищаем workItem после выполнения
      self.lock.lock()
      self.workItem = nil
      self.lock.unlock()
      
      completion(result)
    }
    
    workItem = item
    lock.unlock()
    
    // Планируем выполнение с задержкой
    queue.asyncAfter(deadline: .now() + delay, execute: item)
  }
  
  /// Отменяет запланированное выполнение
  public func cancel() {
    lock.lock()
    defer { lock.unlock() }
    workItem?.cancel()
    workItem = nil
  }
  
  /// Проверяет, есть ли запланированное выполнение
  public var isPending: Bool {
    lock.lock()
    defer { lock.unlock() }
    return workItem != nil && !(workItem?.isCancelled ?? true)
  }
}

// MARK: - Async Debounced Requirement

/// Асинхронное требование с debouncing
///
/// Использует Task и Task.sleep для отложенного выполнения.
public actor AsyncDebouncedRequirement<Context: Sendable> {
  private let requirement: AsyncRequirement<Context>
  private let delay: TimeInterval
  private let behavior: DebounceBehavior
  
  private var pendingTask: Task<Evaluation, Error>?
  
  /// Инициализатор
  /// - Parameters:
  ///   - requirement: Базовое асинхронное требование
  ///   - delay: Задержка в секундах
  ///   - behavior: Поведение debounce
  public init(
    requirement: AsyncRequirement<Context>,
    delay: TimeInterval,
    behavior: DebounceBehavior = .default
  ) {
    self.requirement = requirement
    self.delay = delay
    self.behavior = behavior
  }
  
  /// Оценивает требование с учетом debouncing
  /// - Parameter context: Контекст для оценки
  /// - Returns: Результат оценки после задержки
  @available(macOS 13.0, iOS 16.0, watchOS 9.0, tvOS 16.0, *)
  public func evaluate(_ context: Context) async throws -> Evaluation {
    // Обрабатываем behavior
    switch behavior {
    case .cancelPrevious:
      // Отменяем предыдущий запланированный вызов
      pendingTask?.cancel()
      
    case .ignoreNew:
      // Если есть активный вызов, возвращаем его результат
      if let task = pendingTask, !task.isCancelled {
        return try await task.value
      }
    }
    
    // Создаем новую задачу с задержкой
    let task = Task<Evaluation, Error> { [requirement, delay] in
      try await Task.sleep(for: .seconds(delay))
      
      // Дважды проверяем отмену перед выполнением требования
      guard !Task.isCancelled else {
        throw CancellationError()
      }
      try Task.checkCancellation()
      
      return try await requirement.evaluate(context)
    }
    
    pendingTask = task
    
    do {
      let result = try await task.value
      pendingTask = nil
      return result
    } catch {
      pendingTask = nil
      throw error
    }
  }
  
  /// Отменяет запланированное выполнение
  public func cancel() async {
    pendingTask?.cancel()
    // Не обнуляем pendingTask здесь - пусть evaluate сам его обнулит
  }
  
  /// Проверяет, есть ли запланированное выполнение
  public var isPending: Bool {
    get async {
      pendingTask != nil && !(pendingTask?.isCancelled ?? true)
    }
  }
}

// MARK: - Расширения

extension Requirement {
  /// Создает требование с debouncing
  ///
  /// Примечание: Debounce работает асинхронно, поэтому результат
  /// возвращается через callback.
  ///
  /// - Parameters:
  ///   - delay: Задержка в секундах
  ///   - behavior: Поведение debounce
  /// - Returns: Требование с debouncing
  public func debounce(
    delay: TimeInterval,
    behavior: DebounceBehavior = .default
  ) -> DebouncedRequirement<Context> {
    DebouncedRequirement(
      requirement: self,
      delay: delay,
      behavior: behavior
    )
  }
}

extension AsyncRequirement {
  /// Создает асинхронное требование с debouncing
  /// - Parameters:
  ///   - delay: Задержка в секундах
  ///   - behavior: Поведение debounce
  /// - Returns: Требование с debouncing
  public func debounce(
    delay: TimeInterval,
    behavior: DebounceBehavior = .default
  ) -> AsyncDebouncedRequirement<Context> {
    AsyncDebouncedRequirement(
      requirement: self,
      delay: delay,
      behavior: behavior
    )
  }
}

