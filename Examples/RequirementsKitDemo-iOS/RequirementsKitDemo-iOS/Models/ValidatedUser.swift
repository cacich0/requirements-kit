import Foundation
import RequirementsKit

// MARK: - @RequirementModel Examples

/// Пример использования @RequirementModel для автоматической валидации
@RequirementModel
struct ValidatedUser: Sendable {
  @MinLength(3) @MaxLength(20)
  var username: String
  
  @Email
  var email: String
  
  @InRange(18...120)
  var age: Int
  
  @Phone
  var phoneNumber: String
  
  // Обычные свойства без валидации
  var userId: String
  var createdAt: Date
}

// MARK: - Примеры использования

extension ValidatedUser {
  static var sample: ValidatedUser {
    ValidatedUser(
      username: "john",
      email: "john@example.com",
      age: 25,
      phoneNumber: "+1234567890",
      userId: "user123",
      createdAt: Date()
    )
  }
  
  static var invalidUsername: ValidatedUser {
    ValidatedUser(
      username: "jo", // Too short
      email: "john@example.com",
      age: 25,
      phoneNumber: "+1234567890",
      userId: "user123",
      createdAt: Date()
    )
  }
  
  static var invalidEmail: ValidatedUser {
    ValidatedUser(
      username: "john",
      email: "not-an-email",
      age: 25,
      phoneNumber: "+1234567890",
      userId: "user123",
      createdAt: Date()
    )
  }
  
  static var invalidAge: ValidatedUser {
    ValidatedUser(
      username: "john",
      email: "john@example.com",
      age: 15, // Too young
      phoneNumber: "+1234567890",
      userId: "user123",
      createdAt: Date()
    )
  }
}

// MARK: - Более сложный пример

/// Форма регистрации с множественными валидационными атрибутами
@RequirementModel
struct RegistrationForm: Sendable {
  @MinLength(3) @MaxLength(20) @Matches(#"^[a-zA-Z0-9]+$"#)
  var username: String
  
  @Email
  var email: String
  
  @MinLength(8)
  var password: String
  
  @InRange(18...120)
  var age: Int
  
  @Phone
  var phoneNumber: String
  
  @NotEmpty
  var interests: [String]
  
  @URL
  var website: String
  
  @NotBlank
  var fullName: String
}

extension RegistrationForm {
  static var sample: RegistrationForm {
    RegistrationForm(
      username: "john123",
      email: "john@example.com",
      password: "SecurePassword123!",
      age: 25,
      phoneNumber: "+1234567890",
      interests: ["coding", "music", "sports"],
      website: "https://example.com",
      fullName: "John Doe"
    )
  }
}

// MARK: - Модель заказа с валидацией

/// Заказ с автоматической валидацией
@RequirementModel
struct ValidatedOrder: Sendable {
  @NotEmpty
  var items: [String]
  
  @InRange(1.0...100000.0)
  var totalAmount: Double
  
  @NotBlank
  var shippingAddress: String
  
  @NotBlank
  var billingAddress: String
  
  @Phone
  var contactPhone: String
  
  @Email
  var contactEmail: String
  
  // Обычные свойства
  var orderId: String
  var customerId: String
  var orderDate: Date
  var status: OrderStatus
}

enum OrderStatus: String, Sendable {
  case pending
  case processing
  case shipped
  case delivered
  case cancelled
}

extension ValidatedOrder {
  static var sample: ValidatedOrder {
    ValidatedOrder(
      items: ["item1", "item2", "item3"],
      totalAmount: 299.99,
      shippingAddress: "123 Main St, City, State 12345",
      billingAddress: "123 Main St, City, State 12345",
      contactPhone: "+1234567890",
      contactEmail: "customer@example.com",
      orderId: "ORD-001",
      customerId: "CUST-123",
      orderDate: Date(),
      status: .pending
    )
  }
}

// MARK: - Модель профиля с опциональными полями

/// Профиль пользователя с валидацией опциональных полей
@RequirementModel
struct UserProfile: Sendable {
  @MinLength(3) @MaxLength(50)
  var displayName: String
  
  @NonNil
  var userId: String?
  
  // Обычные опциональные свойства
  var bio: String?
  var avatar: String?
  var location: String?
}

extension UserProfile {
  static var sample: UserProfile {
    UserProfile(
      displayName: "John Doe",
      userId: "user123",
      bio: "Software developer",
      avatar: "https://example.com/avatar.jpg",
      location: "San Francisco, CA"
    )
  }
}

// MARK: - Модель с числовыми диапазонами

/// Настройки с валидацией числовых значений
@RequirementModel
struct AppSettings: Sendable {
  @InRange(8...24)
  var fontSize: Int
  
  @InRange(0.5...2.0)
  var animationSpeed: Double
  
  @InRange(1...100)
  var maxCacheSize: Int
  
  @InRange(10...300)
  var requestTimeout: Int
  
  // Обычные свойства
  var theme: String
  var language: String
}

extension AppSettings {
  static var defaultSettings: AppSettings {
    AppSettings(
      fontSize: 14,
      animationSpeed: 1.0,
      maxCacheSize: 50,
      requestTimeout: 30,
      theme: "light",
      language: "en"
    )
  }
}

// MARK: - Комментарии к использованию

/*
 Использование @RequirementModel:
 
 1. Добавьте @RequirementModel к вашей структуре или классу
 2. Добавьте валидационные атрибуты к свойствам
 3. Вызовите метод validate() для проверки
 
 Пример:
 
 let user = ValidatedUser.sample
 let validation = user.validate()
 
 if validation.isConfirmed {
     print("Пользователь валиден!")
 } else {
     print("Ошибки валидации:")
     for failure in validation.allFailures {
         print("- \(failure.message)")
     }
 }
 
 Доступные атрибуты:
 - @MinLength(n) - минимальная длина строки
 - @MaxLength(n) - максимальная длина строки
 - @Email - валидация email
 - @Phone - валидация телефона
 - @URL - валидация URL
 - @InRange(range) - значение в диапазоне
 - @NotEmpty - коллекция не пустая
 - @NonNil - optional не nil
 - @NotBlank - строка не пустая после trim
 - @Matches(pattern) - соответствие regex
 */

