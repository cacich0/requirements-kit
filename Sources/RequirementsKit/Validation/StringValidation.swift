import Foundation

// MARK: - Валидация строк

extension Requirement {
  /// Проверяет строку на соответствие регулярному выражению
  /// - Parameters:
  ///   - keyPath: Путь к строке
  ///   - pattern: Регулярное выражение
  /// - Returns: Требование
  public static func requireMatches(
    _ keyPath: KeyPath<Context, String> & Sendable,
    pattern: String
  ) -> Requirement<Context> {
    Requirement { context in
      let value = context[keyPath: keyPath]
      
      guard let regex = try? NSRegularExpression(pattern: pattern) else {
        return .failed(reason: Reason(
          code: "string.invalid_pattern",
          message: "Invalid regex pattern"
        ))
      }
      
      let range = NSRange(value.startIndex..., in: value)
      let match = regex.firstMatch(in: value, range: range)
      
      return match != nil
        ? .confirmed
        : .failed(reason: Reason(
            code: "string.pattern_mismatch",
            message: "String does not match pattern"
          ))
    }
  }
  
  /// Проверяет минимальную длину строки
  /// - Parameters:
  ///   - keyPath: Путь к строке
  ///   - minLength: Минимальная длина
  /// - Returns: Требование
  public static func requireMinLength(
    _ keyPath: KeyPath<Context, String> & Sendable,
    minLength: Int
  ) -> Requirement<Context> {
    Requirement { context in
      let value = context[keyPath: keyPath]
      
      return value.count >= minLength
        ? .confirmed
        : .failed(reason: Reason(
            code: "string.too_short",
            message: "String must be at least \(minLength) characters"
          ))
    }
  }
  
  /// Проверяет максимальную длину строки
  /// - Parameters:
  ///   - keyPath: Путь к строке
  ///   - maxLength: Максимальная длина
  /// - Returns: Требование
  public static func requireMaxLength(
    _ keyPath: KeyPath<Context, String> & Sendable,
    maxLength: Int
  ) -> Requirement<Context> {
    Requirement { context in
      let value = context[keyPath: keyPath]
      
      return value.count <= maxLength
        ? .confirmed
        : .failed(reason: Reason(
            code: "string.too_long",
            message: "String must be at most \(maxLength) characters"
          ))
    }
  }
  
  /// Проверяет длину строки в диапазоне
  /// - Parameters:
  ///   - keyPath: Путь к строке
  ///   - range: Допустимый диапазон длины
  /// - Returns: Требование
  public static func requireLength(
    _ keyPath: KeyPath<Context, String> & Sendable,
    in range: ClosedRange<Int>
  ) -> Requirement<Context> {
    Requirement { context in
      let value = context[keyPath: keyPath]
      
      return range.contains(value.count)
        ? .confirmed
        : .failed(reason: Reason(
            code: "string.length_out_of_range",
            message: "String length must be between \(range.lowerBound) and \(range.upperBound)"
          ))
    }
  }
  
  /// Проверяет, что строка не пустая
  /// - Parameter keyPath: Путь к строке
  /// - Returns: Требование
  public static func requireNotBlank(
    _ keyPath: KeyPath<Context, String> & Sendable
  ) -> Requirement<Context> {
    Requirement { context in
      let value = context[keyPath: keyPath]
      let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
      
      return !trimmed.isEmpty
        ? .confirmed
        : .failed(reason: Reason(
            code: "string.blank",
            message: "String must not be blank"
          ))
    }
  }
  
  /// Проверяет, что строка содержит подстроку
  /// - Parameters:
  ///   - keyPath: Путь к строке
  ///   - substring: Подстрока для поиска
  /// - Returns: Требование
  public static func requireContains(
    _ keyPath: KeyPath<Context, String> & Sendable,
    substring: String
  ) -> Requirement<Context> {
    Requirement { context in
      let value = context[keyPath: keyPath]
      
      return value.contains(substring)
        ? .confirmed
        : .failed(reason: Reason(
            code: "string.missing_substring",
            message: "String must contain '\(substring)'"
          ))
    }
  }
  
  /// Проверяет, что строка начинается с префикса
  /// - Parameters:
  ///   - keyPath: Путь к строке
  ///   - prefix: Префикс
  /// - Returns: Требование
  public static func requirePrefix(
    _ keyPath: KeyPath<Context, String> & Sendable,
    prefix: String
  ) -> Requirement<Context> {
    Requirement { context in
      let value = context[keyPath: keyPath]
      
      return value.hasPrefix(prefix)
        ? .confirmed
        : .failed(reason: Reason(
            code: "string.missing_prefix",
            message: "String must start with '\(prefix)'"
          ))
    }
  }
  
  /// Проверяет, что строка заканчивается суффиксом
  /// - Parameters:
  ///   - keyPath: Путь к строке
  ///   - suffix: Суффикс
  /// - Returns: Требование
  public static func requireSuffix(
    _ keyPath: KeyPath<Context, String> & Sendable,
    suffix: String
  ) -> Requirement<Context> {
    Requirement { context in
      let value = context[keyPath: keyPath]
      
      return value.hasSuffix(suffix)
        ? .confirmed
        : .failed(reason: Reason(
            code: "string.missing_suffix",
            message: "String must end with '\(suffix)'"
          ))
    }
  }
}

// MARK: - Предустановленные паттерны

/// Часто используемые regex паттерны
public enum ValidationPattern {
  /// Email паттерн
  public static let email = #"^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$"#
  
  /// URL паттерн
  public static let url = #"^https?://[^\s/$.?#].[^\s]*$"#
  
  /// Телефон (международный формат)
  public static let phoneInternational = #"^\+[1-9]\d{1,14}$"#
  
  /// UUID паттерн
  public static let uuid = #"^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$"#
  
  /// Только буквы
  public static let alphabetic = #"^[a-zA-Z]+$"#
  
  /// Только цифры
  public static let numeric = #"^[0-9]+$"#
  
  /// Буквы и цифры
  public static let alphanumeric = #"^[a-zA-Z0-9]+$"#
}

