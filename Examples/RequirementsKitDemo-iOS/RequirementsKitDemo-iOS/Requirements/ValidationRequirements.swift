import RequirementsKit
import Foundation

// MARK: - Validation Requirements
// Демонстрация: String validation (requireMatches, requireMinLength, requireMaxLength),
// ValidationPattern, Collection validation, Range validation
// Макросы для валидации (#requireEmail, #requireMinLength, #requireMaxLength, и др.)

/// Требования для валидации форм
enum ValidationRequirements {
  
  // MARK: - Примеры с макросами
  
  /// Email валидация через макрос (упрощенная версия)
  static let emailValidMacro: Requirement<FormContext> = #requireEmail(\.email)
  
  /// Username валидация через макросы
  static let usernameValidMacro: Requirement<FormContext> = #all {
    #requireMinLength(\.username, 3)
    #requireMaxLength(\.username, 20)
    #requireMatches(\.username, pattern: ValidationPattern.alphanumeric)
  }
  
  /// Password валидация через макросы
  static let passwordValidMacro: Requirement<FormContext> = #all {
    #requireMinLength(\.password, 8)
    #requireMatches(\.password, pattern: ".*[0-9].*")
    #requireMatches(\.password, pattern: ".*[A-Z].*")
    #requireMatches(\.password, pattern: ".*[a-z].*")
  }
  
  /// Phone валидация через макрос
  static let phoneValidMacro: Requirement<FormContext> = #requirePhone(\.phone)
  
  // MARK: - Email Validation
  
  /// Email не пустой
  static let emailNotEmpty: Requirement<FormContext> =
    Requirement<FormContext>.requireNotBlank(\.email)
      .because(code: "email.required", message: "Email is required")
  
  /// Email соответствует формату
  static let emailFormat: Requirement<FormContext> =
    Requirement<FormContext>.requireMatches(\.email, pattern: ValidationPattern.email)
      .because(code: "email.invalid_format", message: "Please enter a valid email address")
  
  /// Полная валидация email
  static let validEmail: Requirement<FormContext> =
    emailNotEmpty && emailFormat
  
  // MARK: - Username Validation
  
  /// Username не пустой
  static let usernameNotEmpty: Requirement<FormContext> =
    Requirement<FormContext>.requireNotBlank(\.username)
      .because(code: "username.required", message: "Username is required")
  
  /// Username минимальная длина
  static let usernameMinLength: Requirement<FormContext> =
    Requirement<FormContext>.requireMinLength(\.username, minLength: 3)
      .because(code: "username.too_short", message: "Username must be at least 3 characters")
  
  /// Username максимальная длина
  static let usernameMaxLength: Requirement<FormContext> =
    Requirement<FormContext>.requireMaxLength(\.username, maxLength: 20)
      .because(code: "username.too_long", message: "Username must be at most 20 characters")
  
  /// Username только буквы и цифры
  static let usernameAlphanumeric: Requirement<FormContext> =
    Requirement<FormContext>.requireMatches(\.username, pattern: ValidationPattern.alphanumeric)
      .because(code: "username.invalid_chars", message: "Username can only contain letters and numbers")
  
  /// Полная валидация username
  static let validUsername: Requirement<FormContext> = Requirement.all {
    usernameNotEmpty
    usernameMinLength
    usernameMaxLength
    usernameAlphanumeric
  }
  
  // MARK: - Password Validation
  
  /// Password не пустой
  static let passwordNotEmpty: Requirement<FormContext> =
    Requirement<FormContext>.requireNotBlank(\.password)
      .because(code: "password.required", message: "Password is required")
  
  /// Password минимальная длина
  static let passwordMinLength: Requirement<FormContext> =
    Requirement<FormContext>.requireMinLength(\.password, minLength: 8)
      .because(code: "password.too_short", message: "Password must be at least 8 characters")
  
  /// Password содержит цифру
  static let passwordHasDigit: Requirement<FormContext> =
    Requirement<FormContext>.requireMatches(\.password, pattern: ".*[0-9].*")
      .because(code: "password.no_digit", message: "Password must contain at least one digit")
  
  /// Password содержит заглавную букву
  static let passwordHasUppercase: Requirement<FormContext> =
    Requirement<FormContext>.requireMatches(\.password, pattern: ".*[A-Z].*")
      .because(code: "password.no_uppercase", message: "Password must contain at least one uppercase letter")
  
  /// Password содержит строчную букву
  static let passwordHasLowercase: Requirement<FormContext> =
    Requirement<FormContext>.requireMatches(\.password, pattern: ".*[a-z].*")
      .because(code: "password.no_lowercase", message: "Password must contain at least one lowercase letter")
  
  /// Password содержит спецсимвол
  static let passwordHasSpecialChar: Requirement<FormContext> =
    Requirement<FormContext>.requireMatches(\.password, pattern: ".*[!@#$%^&*(),.?\":{}|<>].*")
      .because(code: "password.no_special", message: "Password must contain at least one special character")
  
  /// Полная валидация password
  static let validPassword: Requirement<FormContext> = Requirement.all {
    passwordNotEmpty
    passwordMinLength
    passwordHasDigit
    passwordHasUppercase
    passwordHasLowercase
    passwordHasSpecialChar
  }
  
  /// Пароли совпадают
  static let passwordsMatch: Requirement<FormContext> = Requirement { context in
    context.password == context.confirmPassword
      ? .confirmed
      : .failed(reason: Reason(
          code: "password.mismatch",
          message: "Passwords do not match"
        ))
  }
  
  // MARK: - Phone Validation
  
  /// Phone не пустой
  static let phoneNotEmpty: Requirement<FormContext> =
    Requirement<FormContext>.requireNotBlank(\.phone)
      .because(code: "phone.required", message: "Phone number is required")
  
  /// Phone соответствует международному формату
  static let phoneFormat: Requirement<FormContext> =
    Requirement<FormContext>.requireMatches(\.phone, pattern: ValidationPattern.phoneInternational)
      .because(code: "phone.invalid_format", message: "Please enter a valid phone number (e.g., +1234567890)")
  
  /// Полная валидация phone
  static let validPhone: Requirement<FormContext> =
    phoneNotEmpty && phoneFormat
  
  // MARK: - Age Validation
  
  /// Возраст >= 18
  static let isAdult: Requirement<FormContext> = Requirement { context in
    context.age >= 18
      ? .confirmed
      : .failed(reason: Reason(code: "age.underage", message: "You must be at least 18 years old"))
  }
  
  /// Возраст в допустимом диапазоне
  static let validAge: Requirement<FormContext> = Requirement { context in
    (13...120).contains(context.age)
      ? .confirmed
      : .failed(reason: Reason(code: "age.out_of_range", message: "Age must be between 13 and 120"))
  }
  
  // MARK: - Terms Acceptance
  
  /// Условия приняты
  static let termsAccepted: Requirement<FormContext> =
    Requirement<FormContext>.require(\.acceptedTerms)
      .because(code: "terms.not_accepted", message: "You must accept the terms and conditions")
  
  // MARK: - Complete Form Validation
  
  /// Полная валидация регистрационной формы
  static let validRegistrationForm: Requirement<FormContext> = Requirement.all {
    validEmail
    validUsername
    validPassword
    passwordsMatch
    validPhone
    isAdult
    termsAccepted
  }
  
  /// Валидация формы логина
  static let validLoginForm: Requirement<FormContext> = Requirement.all {
    validEmail
    passwordNotEmpty
  }
  
  /// Валидация формы смены пароля
  static let validPasswordChangeForm: Requirement<FormContext> = Requirement.all {
    validPassword
    passwordsMatch
  }
}

// MARK: - Order Validation

/// Валидация заказов
enum OrderValidation {
  
  /// Корзина не пустая
  static let cartNotEmpty: Requirement<Order> =
    Requirement<Order>.requireNotEmpty(\.items)
      .because(code: "order.empty_cart", message: "Your cart is empty")
  
  /// Адрес доставки заполнен
  static let hasShippingAddress: Requirement<Order> =
    Requirement<Order>.requireNotBlank(\.shippingAddress)
      .because(code: "order.no_shipping", message: "Shipping address is required")
  
  /// Адрес оплаты заполнен
  static let hasBillingAddress: Requirement<Order> =
    Requirement<Order>.requireNotBlank(\.billingAddress)
      .because(code: "order.no_billing", message: "Billing address is required")
  
  /// Минимальная сумма заказа
  static func minimumOrderAmount(_ amount: Double) -> Requirement<Order> {
    Requirement { order in
      order.totalAmount >= amount
        ? .confirmed
        : .failed(reason: Reason(
            code: "order.below_minimum",
            message: "Minimum order amount is $\(amount)"
          ))
    }
  }
  
  /// Максимальное количество товаров
  static func maxItems(_ count: Int) -> Requirement<Order> {
    Requirement { order in
      order.items.count <= count
        ? .confirmed
        : .failed(reason: Reason(code: "order.too_many_items", message: "Maximum \(count) items per order"))
    }
  }
  
  /// Полная валидация заказа
  static let validOrder: Requirement<Order> = Requirement.all {
    cartNotEmpty
    hasShippingAddress
    hasBillingAddress
    minimumOrderAmount(10)
    maxItems(50)
  }
}

// MARK: - Password Strength

/// Оценка силы пароля
enum PasswordStrength {
  /// Подсчитывает силу пароля
  static func evaluate(_ password: String) -> (score: Int, level: Level) {
    var score = 0
    
    if password.count >= 8 { score += 1 }
    if password.count >= 12 { score += 1 }
    if password.range(of: "[0-9]", options: .regularExpression) != nil { score += 1 }
    if password.range(of: "[A-Z]", options: .regularExpression) != nil { score += 1 }
    if password.range(of: "[a-z]", options: .regularExpression) != nil { score += 1 }
    if password.range(of: "[!@#$%^&*(),.?\":{}|<>]", options: .regularExpression) != nil { score += 1 }
    
    let level: Level
    switch score {
    case 0...2:
      level = .weak
    case 3...4:
      level = .medium
    case 5...6:
      level = .strong
    default:
      level = .weak
    }
    
    return (score, level)
  }
  
  enum Level: String {
    case weak = "Weak"
    case medium = "Medium"
    case strong = "Strong"
    
    var color: String {
      switch self {
      case .weak: return "red"
      case .medium: return "orange"
      case .strong: return "green"
      }
    }
  }
}

