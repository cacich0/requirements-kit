import Foundation

// MARK: - Rate Limit Behavior

/// Поведение при превышении лимита вызовов
public enum RateLimitBehavior: Sendable {
  /// Вернуть .failed с указанной причиной
  case returnFailed(Reason)
  
  /// Вернуть последний закэшированный успешный результат
  case returnCached
  
  /// Пропустить проверку и вернуть .confirmed
  case skip
  
  /// Поведение по умолчанию - вернуть ошибку с кодом rate_limit_exceeded
  public static var `default`: RateLimitBehavior {
    .returnFailed(Reason(
      code: "rate_limit_exceeded",
      message: "Rate limit exceeded"
    ))
  }
}

// MARK: - Throttle Behavior

/// Поведение при throttling (слишком частые вызовы)
public enum ThrottleBehavior: Sendable {
  /// Вернуть .failed с указанной причиной
  case returnFailed(Reason)
  
  /// Вернуть последний закэшированный результат
  case returnCached
  
  /// Пропустить проверку и вернуть .confirmed
  case skip
  
  /// Поведение по умолчанию - вернуть кэшированный результат
  public static var `default`: ThrottleBehavior {
    .returnCached
  }
}

// MARK: - Debounce Behavior

/// Поведение для debounce
public enum DebounceBehavior: Sendable {
  /// Отменить предыдущий вызов и запланировать новый
  case cancelPrevious
  
  /// Игнорировать новый вызов, если предыдущий еще в ожидании
  case ignoreNew
  
  /// Поведение по умолчанию - отменить предыдущий вызов
  public static var `default`: DebounceBehavior {
    .cancelPrevious
  }
}

