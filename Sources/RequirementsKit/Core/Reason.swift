/// Причина отказа в выполнении требования.
public struct Reason: Hashable, Sendable {
  /// Уникальный код причины
  public let code: String
  
  /// Человекочитаемое описание причины
  public let message: String
  
  /// Создает новую причину отказа
  /// - Parameters:
  ///   - code: Уникальный код причины
  ///   - message: Человекочитаемое описание причины
  public init(code: String, message: String) {
    self.code = code
    self.message = message
  }
  
  /// Создает причину отказа только с сообщением (код генерируется автоматически)
  /// - Parameter message: Человекочитаемое описание причины
  public init(message: String) {
    self.code = "requirement_failed"
    self.message = message
  }
}

extension Reason: CustomStringConvertible {
  public var description: String {
    "[\(code)] \(message)"
  }
}

