import Foundation
import RequirementsKit

// MARK: - Rate Limiting Examples

/// Примеры использования Rate Limiting, Throttling и Debounce
struct RateLimitingExamples {
  
  // MARK: - Rate Limiting
  
  /// API с ограничением 10 запросов в минуту
  static let apiRateLimitedRequirement = AsyncRequirement<User> { user in
    // Симуляция API вызова
    try await Task.sleep(nanoseconds: 100_000_000)
    
    guard !user.email.isEmpty else {
      return .failed(reason: Reason(message: "Email is required"))
    }
    
    return .confirmed
  }
  .rateLimit(
    maxCalls: 10,
    timeWindow: 60,
    behavior: .returnFailed(Reason(
      code: "api_rate_limit",
      message: "API rate limit exceeded. Please try again later."
    ))
  )
  
  /// Валидация с кэшированием при превышении лимита
  static let cachedRateLimitRequirement = Requirement<String> { text in
    // Дорогая валидация
    let isValid = text.count >= 5
    return isValid ? .confirmed : .failed(reason: Reason(message: "Too short"))
  }
  .rateLimit(
    maxCalls: 5,
    timeWindow: 10,
    behavior: .returnCached
  )
  
  // MARK: - Throttling
  
  /// Валидация формы с throttling - не чаще раза в секунду
  static let formValidationThrottled = Requirement<ValidatedUser> { user in
    // Проверка уникальности username (дорогая операция)
    let isUnique = true // Заглушка
    
    return isUnique
      ? .confirmed
      : .failed(reason: Reason(code: "username_taken", message: "Username is already taken"))
  }
  .throttle(
    interval: 1.0,
    behavior: .returnCached
  )
  
  /// Автосохранение с throttling - не чаще раза в 5 секунд
  static func createAutoSaveRequirement() -> ThrottledRequirement<String> {
    Requirement<String> { content in
      // Сохранение данных
      print("Saving content:", content)
      return .confirmed
    }
    .throttle(
      interval: 5.0,
      behavior: .skip
    )
  }
  
  // MARK: - Debounce
  
  /// Поиск с debounce - выполняется через 300ms после последнего ввода
  @available(macOS 13.0, iOS 16.0, *)
  static let searchDebounced = AsyncRequirement<String> { query in
    // Симуляция поиска
    try await Task.sleep(nanoseconds: 200_000_000)
    
    guard query.count >= 3 else {
      return .failed(reason: Reason(message: "Query too short"))
    }
    
    return .confirmed
  }
  .debounce(delay: 0.3)
  
  /// Валидация email с debounce
  static let emailValidationDebounced = Requirement<String> { email in
    let isValid = email.contains("@") && email.contains(".")
    return isValid ? .confirmed : .failed(reason: Reason(message: "Invalid email"))
  }
  .debounce(
    delay: 0.5,
    behavior: .cancelPrevious
  )
  
  // MARK: - Комбинирование механизмов
  
  /// Комплексное требование с несколькими механизмами защиты
  @available(macOS 13.0, iOS 16.0, *)
  static let complexRequirement = AsyncRequirement<User> { user in
    // Симуляция сложной проверки
    try await Task.sleep(nanoseconds: 100_000_000)
    
    let isValid = !user.username.isEmpty && !user.email.isEmpty
    return isValid ? .confirmed : .failed(reason: Reason(message: "Invalid user data"))
  }
  .debounce(delay: 0.2)           // Отложить выполнение на 200ms
  // MARK: - Композиция с Rate Limiting
  
  /// Пример использования rate limiting внутри композиции
  static let composedWithRateLimiting = Requirement<User>.all {
    // Email валидация с rate limiting (защита от спама)
    Requirement<User> { user in
      // Симуляция проверки email через API
      let isValid = user.email.contains("@")
      return isValid ? .confirmed : .failed(reason: Reason(message: "Invalid email"))
    }
    .rateLimit(maxCalls: 10, timeWindow: 60, behavior: .returnCached)
    
    // Проверка имени с throttling (не чаще раза в секунду)
    Requirement<User> { user in
      let isValid = user.username.count >= 2
      return isValid ? .confirmed : .failed(reason: Reason(message: "Name too short"))
    }
    .throttle(interval: 1.0, behavior: .returnCached)
    
    // Обычная проверка без ограничений
    Requirement<User>.requireExpression { !$0.email.isEmpty }
  }
  
  /// Асинхронная композиция с rate limiting
  @available(macOS 13.0, iOS 16.0, *)
  static let asyncComposedWithRateLimiting = AsyncRequirement<User>.all {
    // API проверка с rate limiting
    AsyncRequirement<User> { user in
      try await Task.sleep(nanoseconds: 50_000_000)
      return user.email.contains("@") ? .confirmed : .failed(reason: Reason(message: "Invalid"))
    }
    .rateLimit(maxCalls: 5, timeWindow: 60)
    
    // Database проверка с throttling
    AsyncRequirement<User> { user in
      try await Task.sleep(nanoseconds: 30_000_000)
      return user.username.count >= 2 ? .confirmed : .failed(reason: Reason(message: "Invalid"))
    }
    .throttle(interval: 2.0, behavior: .returnCached)
    
    // Debounce для поиска
    AsyncRequirement<User> { user in
      try await Task.sleep(nanoseconds: 20_000_000)
      return .confirmed
    }
    .debounce(delay: 0.3)
  }
  
  // MARK: - Практические примеры
  
  /// Пример: Проверка доступности username с throttling
  static func checkUsernameAvailability(_ username: String) -> Evaluation {
    let requirement = Requirement<String> { name in
      // Проверка в базе данных (дорогая операция)
      let isAvailable = name.count >= 3 // Упрощенная логика
      return isAvailable
        ? .confirmed
        : .failed(reason: Reason(message: "Username not available"))
    }
    .throttle(interval: 1.0)
    
    return requirement.evaluate(username)
  }
  
  /// Пример: Поиск продуктов с debounce
  @available(macOS 13.0, iOS 16.0, *)
  static func searchProducts(_ query: String) async throws -> Evaluation {
    let requirement = AsyncRequirement<String> { searchQuery in
      // API вызов для поиска
      try await Task.sleep(nanoseconds: 300_000_000)
      
      guard !searchQuery.isEmpty else {
        return .failed(reason: Reason(message: "Search query is empty"))
      }
      
      return .confirmed
    }
    .debounce(delay: 0.3)
    
    return try await requirement.evaluate(query)
  }
  
  /// Пример: Ограничение API запросов с rate limiting
  @available(macOS 13.0, iOS 16.0, *)
  static func makeAPIRequest<T>(_ request: T) async throws -> Evaluation where T: Sendable {
    let requirement = AsyncRequirement<T> { req in
      // API запрос
      try await Task.sleep(nanoseconds: 100_000_000)
      return .confirmed
    }
    .rateLimit(
      maxCalls: 100,
      timeWindow: 60,
      behavior: .returnFailed(Reason(
        code: "rate_limit",
        message: "Too many requests. Please wait."
      ))
    )
    
    return try await requirement.evaluate(request)
  }
}

// MARK: - Helper Extensions

extension RateLimitingExamples {
  /// Демонстрация использования в SwiftUI ViewModel
  @available(macOS 13.0, iOS 16.0, *)
  @MainActor
  class SearchViewModel: ObservableObject {
    @Published var searchQuery: String = ""
    @Published var isSearching: Bool = false
    @Published var results: [String] = []
    
    private let searchRequirement = AsyncRequirement<String> { query in
      // Симуляция API запроса
      try await Task.sleep(nanoseconds: 500_000_000)
      return .confirmed
    }
    .debounce(delay: 0.3)
    
    func performSearch() async {
      isSearching = true
      defer { isSearching = false }
      
      do {
        let result = try await searchRequirement.evaluate(searchQuery)
        if result.isConfirmed {
          // Обновить результаты
          results = ["Result 1", "Result 2", "Result 3"]
        }
      } catch {
        print("Search error:", error)
      }
    }
  }
}

