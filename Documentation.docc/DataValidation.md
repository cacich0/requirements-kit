# Валидация данных

Используйте RequirementsKit для валидации пользовательского ввода и данных.

## Обзор

RequirementsKit предоставляет встроенные требования для валидации строк, коллекций и числовых значений. Вы также можете создавать собственные валидаторы.

## Валидация строк

### Базовая валидация

```swift
// Не пустая строка
let notEmpty = Requirement<String>.notEmpty()

let result = notEmpty.evaluate("")
// .failed(reason: Reason(message: "String is empty"))
```

### Длина строки

```swift
// Минимальная длина
let minLength = Requirement<String>
  .minLength(8)
  .because("Минимальная длина: 8 символов")

// Максимальная длина
let maxLength = Requirement<String>
  .maxLength(100)
  .because("Максимальная длина: 100 символов")

// Диапазон длины
let lengthRange = Requirement<String>
  .length(min: 8, max: 100)
  .because("Длина должна быть от 8 до 100 символов")
```

### Регулярные выражения

```swift
// Email
let emailValid = Requirement<String>
  .matches(
    pattern: #"^[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}$"#,
    options: .caseInsensitive
  )
  .because("Некорректный email адрес")

let result = emailValid.evaluate("user@example.com")
// .confirmed

// Телефон
let phoneValid = Requirement<String>
  .matches(pattern: #"^\+?\d{10,15}$"#)
  .because("Некорректный номер телефона")

// URL
let urlValid = Requirement<String>
  .matches(pattern: #"^https?://[^\s/$.?#].[^\s]*$"#, options: .caseInsensitive)
  .because("Некорректный URL")
```

### Кастомные правила

```swift
// Содержит хотя бы одну цифру
let containsDigit = Requirement<String> { string in
  string.contains(where: \.isNumber)
    ? .confirmed
    : .failed(reason: Reason(message: "Должна содержать хотя бы одну цифру"))
}

// Содержит заглавную букву
let containsUppercase = Requirement<String> { string in
  string.contains(where: \.isUppercase)
    ? .confirmed
    : .failed(reason: Reason(message: "Должна содержать заглавную букву"))
}

// Содержит спецсимвол
let containsSpecial = Requirement<String> { string in
  let specialChars = CharacterSet(charactersIn: "!@#$%^&*()_+-=[]{}|;:,.<>?")
  return string.unicodeScalars.contains(where: specialChars.contains)
    ? .confirmed
    : .failed(reason: Reason(message: "Должна содержать спецсимвол"))
}
```

### Составная валидация пароля

```swift
let passwordRequirement = #all {
  Requirement<String>.minLength(8)
    .because("Минимум 8 символов")
  
  containsDigit
  
  containsUppercase
  
  containsSpecial
}

let result = passwordRequirement.evaluate("MyPass123!")
// .confirmed
```

## Валидация коллекций

### Базовые проверки

```swift
// Не пустая коллекция
let notEmpty = Requirement<[Item]>.notEmpty()

// Количество элементов
let countRange = Requirement<[Item]>
  .count(min: 1, max: 100)
  .because("Должно быть от 1 до 100 элементов")

// Точное количество
let exactCount = Requirement<[Item]> { items in
  items.count == 5
    ? .confirmed
    : .failed(reason: Reason(message: "Требуется ровно 5 элементов"))
}
```

### Валидация содержимого

```swift
struct Item {
  let id: String
  let price: Double
}

// Все элементы удовлетворяют условию
let allValid = Requirement<[Item]> { items in
  let allPositivePrices = items.allSatisfy { $0.price > 0 }
  return allPositivePrices
    ? .confirmed
    : .failed(reason: Reason(message: "Все цены должны быть положительными"))
}

// Хотя бы один элемент удовлетворяет условию
let hasExpensive = Requirement<[Item]> { items in
  items.contains(where: { $0.price > 1000 })
    ? .confirmed
    : .failed(reason: Reason(message: "Нет дорогих товаров"))
}

// Уникальность
let uniqueIds = Requirement<[Item]> { items in
  let ids = items.map(\.id)
  let uniqueIds = Set(ids)
  return ids.count == uniqueIds.count
    ? .confirmed
    : .failed(reason: Reason(message: "ID должны быть уникальными"))
}
```

## Валидация числовых значений

### Range валидация

```swift
// Диапазон
let ageValid = Requirement<Int>
  .inRange(18...120)
  .because("Возраст должен быть от 18 до 120 лет")

// Больше чем
let positiveBalance = Requirement<Double>
  .greaterThan(0)
  .because("Баланс должен быть положительным")

// Меньше или равно
let withinLimit = Requirement<Double>
  .lessThanOrEqual(10000)
  .because("Превышен лимит в 10,000")

// Между значениями
let discount = Requirement<Double> { value in
  (0...100).contains(value)
    ? .confirmed
    : .failed(reason: Reason(message: "Скидка должна быть от 0% до 100%"))
}
```

### Кратность

```swift
// Кратно числу
let multipleOf5 = Requirement<Int> { value in
  value % 5 == 0
    ? .confirmed
    : .failed(reason: Reason(message: "Должно быть кратно 5"))
}
```

## Комплексная валидация форм

### Регистрационная форма

```swift
struct RegistrationData {
  let username: String
  let email: String
  let password: String
  let age: Int
  let agreedToTerms: Bool
}

enum RegistrationValidation {
  static let username = #all {
    Requirement<String>.notEmpty()
      .because("Имя пользователя обязательно")
    
    Requirement<String>.length(min: 3, max: 20)
      .because("Имя должно быть от 3 до 20 символов")
    
    Requirement<String>.matches(pattern: #"^[a-zA-Z0-9_]+$"#)
      .because("Только буквы, цифры и подчёркивание")
  }
  
  static let email = #all {
    Requirement<String>.notEmpty()
      .because("Email обязателен")
    
    Requirement<String>
      .matches(
        pattern: #"^[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}$"#,
        options: .caseInsensitive
      )
      .because("Некорректный email")
  }
  
  static let password = #all {
    Requirement<String>.minLength(8)
      .because("Минимум 8 символов")
    
    containsDigit
    containsUppercase
    containsSpecial
  }
  
  static let age = Requirement<Int>
    .inRange(18...120)
    .because("Возраст должен быть от 18 до 120 лет")
  
  static let terms = Requirement<Bool>
    .require(\.self)
    .because("Необходимо согласие с условиями")
  
  static let complete = Requirement<RegistrationData> { data in
    var failures: [Reason] = []
    
    if case .failed(let reason) = username.evaluate(data.username) {
      failures.append(reason)
    }
    
    if case .failed(let reason) = email.evaluate(data.email) {
      failures.append(reason)
    }
    
    if case .failed(let reason) = password.evaluate(data.password) {
      failures.append(reason)
    }
    
    if case .failed(let reason) = age.evaluate(data.age) {
      failures.append(reason)
    }
    
    if case .failed(let reason) = terms.evaluate(data.agreedToTerms) {
      failures.append(reason)
    }
    
    if failures.isEmpty {
      return .confirmed
    } else {
      return .failed(reason: failures[0])
    }
  }
}
```

### Использование в SwiftUI

```swift
struct RegistrationView: View {
  @State private var username = ""
  @State private var email = ""
  @State private var password = ""
  @State private var age = ""
  @State private var agreedToTerms = false
  
  @State private var errors: [String] = []
  
  var usernameError: String? {
    guard !username.isEmpty else { return nil }
    if case .failed(let reason) = RegistrationValidation.username.evaluate(username) {
      return reason.message
    }
    return nil
  }
  
  var emailError: String? {
    guard !email.isEmpty else { return nil }
    if case .failed(let reason) = RegistrationValidation.email.evaluate(email) {
      return reason.message
    }
    return nil
  }
  
  var passwordError: String? {
    guard !password.isEmpty else { return nil }
    if case .failed(let reason) = RegistrationValidation.password.evaluate(password) {
      return reason.message
    }
    return nil
  }
  
  var canSubmit: Bool {
    usernameError == nil &&
    emailError == nil &&
    passwordError == nil &&
    agreedToTerms &&
    !username.isEmpty &&
    !email.isEmpty &&
    !password.isEmpty
  }
  
  var body: some View {
    Form {
      Section("Учётная запись") {
        TextField("Имя пользователя", text: $username)
        if let error = usernameError {
          ErrorText(error)
        }
        
        TextField("Email", text: $email)
          .textInputAutocapitalization(.never)
          .keyboardType(.emailAddress)
        if let error = emailError {
          ErrorText(error)
        }
        
        SecureField("Пароль", text: $password)
        if let error = passwordError {
          ErrorText(error)
        }
      }
      
      Section("Персональные данные") {
        TextField("Возраст", text: $age)
          .keyboardType(.numberPad)
      }
      
      Section {
        Toggle("Я согласен с условиями использования", isOn: $agreedToTerms)
      }
      
      Button("Зарегистрироваться") {
        register()
      }
      .disabled(!canSubmit)
    }
  }
  
  func register() {
    guard let ageInt = Int(age) else { return }
    
    let data = RegistrationData(
      username: username,
      email: email,
      password: password,
      age: ageInt,
      agreedToTerms: agreedToTerms
    )
    
    let result = RegistrationValidation.complete.evaluate(data)
    
    switch result {
    case .confirmed:
      // Регистрация
      print("✅ Регистрация успешна")
    case .failed(let reason):
      errors = [reason.message]
    }
  }
}

struct ErrorText: View {
  let message: String
  
  init(_ message: String) {
    self.message = message
  }
  
  var body: some View {
    Text(message)
      .font(.caption)
      .foregroundColor(.red)
  }
}
```

## Асинхронная валидация

### Проверка уникальности через API

```swift
let usernameAvailable = AsyncRequirement<String> { username in
  let isAvailable = try await api.checkUsernameAvailability(username)
  
  return isAvailable
    ? .confirmed
    : .failed(reason: Reason(
        code: "username_taken",
        message: "Имя пользователя уже занято"
      ))
}
```

### Комбинированная валидация

```swift
// Сначала синхронная валидация
guard RegistrationValidation.username.evaluate(username).isConfirmed else {
  return .failed(reason: Reason(message: "Некорректное имя пользователя"))
}

// Затем асинхронная проверка доступности
let result = try await usernameAvailable.evaluate(username)
```

## Best Practices

### 1. Валидируйте на клиенте и сервере

```swift
// Клиентская валидация для UX
let clientValidation = RegistrationValidation.username

// Серверная валидация для безопасности
let serverValidation = AsyncRequirement<String> { username in
  try await api.validateUsername(username)
}
```

### 2. Предоставляйте понятные сообщения

```swift
// ✅ Хорошо
let password = Requirement<String>
  .minLength(8)
  .because("Пароль должен содержать минимум 8 символов")

// ❌ Плохо
let password = Requirement<String>
  .minLength(8)
  .because("Invalid")
```

### 3. Группируйте связанные валидации

```swift
enum EmailValidation {
  static let format = Requirement<String>
    .matches(pattern: #"^[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}$"#, options: .caseInsensitive)
    .because("Некорректный формат email")
  
  static let notDisposable = Requirement<String> { email in
    let disposableDomains = ["tempmail.com", "10minutemail.com"]
    let domain = email.split(separator: "@").last.map(String.init) ?? ""
    
    return !disposableDomains.contains(domain)
      ? .confirmed
      : .failed(reason: Reason(message: "Временные email не допускаются"))
  }
  
  static let complete = format && notDisposable
}
```

### 4. Валидируйте инкрементально

```swift
// Показывайте ошибки только после начала ввода
@State private var hasStartedTyping = false

var passwordError: String? {
  guard hasStartedTyping else { return nil }
  // ... валидация
}

TextField("Password", text: $password)
  .onChange(of: password) { _, _ in
    hasStartedTyping = true
  }
```

## Смотрите также

- <doc:SwiftUIIntegration>
- <doc:AsyncRequirements>

