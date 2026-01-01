# Справочник по макросам

Полное руководство по всем макросам RequirementsKit для декларативного создания требований.

## Обзор

RequirementsKit предоставляет богатый набор макросов для упрощения создания требований. Макросы позволяют писать более читаемый и лаконичный код, автоматически генерируя валидационную логику.

## Типы макросов

### Freestanding Expression Макросы

Используются для создания требований непосредственно в коде:

```swift
let requirement: Requirement<User> = #requireEmail(\.email)
```

### Attached Макросы

Применяются к структурам и классам для автоматической генерации валидационных методов:

```swift
@RequirementModel
struct User {
  @MinLength(3)
  var username: String
}
```

## Категории макросов

### Макросы валидации строк

#### #requireMatches

Проверяет соответствие строки регулярному выражению.

```swift
let requirement: Requirement<Context> = #requireMatches(\.email, pattern: ValidationPattern.email)
```

**Параметры:**
- `keyPath`: KeyPath к строковому свойству
- `pattern`: Регулярное выражение (String)

**Пример:**
```swift
struct FormContext: Sendable {
  let email: String
}

let emailPattern = #"^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$"#
let requirement = #requireMatches(\.email, pattern: emailPattern)

let context = FormContext(email: "user@example.com")
requirement.evaluate(context) // .confirmed
```

---

#### #requireMinLength

Проверяет минимальную длину строки.

```swift
let requirement: Requirement<Context> = #requireMinLength(\.username, 3)
```

**Параметры:**
- `keyPath`: KeyPath к строковому свойству
- `minLength`: Минимальная длина (Int)

**Пример:**
```swift
struct User: Sendable {
  let username: String
}

let requirement = #requireMinLength(\.username, 3)

let user1 = User(username: "john")
requirement.evaluate(user1) // .confirmed

let user2 = User(username: "jo")
requirement.evaluate(user2) // .failed
```

---

#### #requireMaxLength

Проверяет максимальную длину строки.

```swift
let requirement: Requirement<Context> = #requireMaxLength(\.username, 20)
```

**Параметры:**
- `keyPath`: KeyPath к строковому свойству
- `maxLength`: Максимальная длина (Int)

---

#### #requireLength

Проверяет длину строки в заданном диапазоне.

```swift
let requirement: Requirement<Context> = #requireLength(\.password, in: 8...128)
```

**Параметры:**
- `keyPath`: KeyPath к строковому свойству
- `range`: Допустимый диапазон (ClosedRange<Int>)

**Пример:**
```swift
let requirement = #requireLength(\.password, in: 8...20)

let user1 = User(password: "password123")
requirement.evaluate(user1) // .confirmed

let user2 = User(password: "short")
requirement.evaluate(user2) // .failed
```

---

#### #requireNotBlank

Проверяет, что строка не пустая после удаления пробелов.

```swift
let requirement: Requirement<Context> = #requireNotBlank(\.name)
```

**Параметры:**
- `keyPath`: KeyPath к строковому свойству

**Пример:**
```swift
let requirement = #requireNotBlank(\.name)

let user1 = User(name: "John")
requirement.evaluate(user1) // .confirmed

let user2 = User(name: "   ")
requirement.evaluate(user2) // .failed
```

---

#### #requireEmail

Проверяет корректность email адреса.

```swift
let requirement: Requirement<Context> = #requireEmail(\.email)
```

Shorthand для `#requireMatches(\.email, pattern: ValidationPattern.email)`

**Пример:**
```swift
let requirement = #requireEmail(\.email)

let user1 = User(email: "user@example.com")
requirement.evaluate(user1) // .confirmed

let user2 = User(email: "invalid")
requirement.evaluate(user2) // .failed
```

---

#### #requireURL

Проверяет корректность URL.

```swift
let requirement: Requirement<Context> = #requireURL(\.website)
```

Shorthand для `#requireMatches(\.website, pattern: ValidationPattern.url)`

---

#### #requirePhone

Проверяет корректность телефонного номера (международный формат).

```swift
let requirement: Requirement<Context> = #requirePhone(\.phoneNumber)
```

Shorthand для `#requireMatches(\.phoneNumber, pattern: ValidationPattern.phoneInternational)`

**Пример:**
```swift
let requirement = #requirePhone(\.phone)

let user1 = User(phone: "+1234567890")
requirement.evaluate(user1) // .confirmed

let user2 = User(phone: "123")
requirement.evaluate(user2) // .failed
```

---

### Макросы валидации коллекций

#### #requireCount

Проверяет количество элементов в коллекции.

```swift
let requirement: Requirement<Context> = #requireCount(\.items, min: 1, max: 50)
```

**Параметры:**
- `keyPath`: KeyPath к коллекции
- `min`: Минимальное количество (опционально)
- `max`: Максимальное количество (опционально)

**Пример:**
```swift
struct Order: Sendable {
  let items: [String]
}

let requirement = #requireCount(\.items, min: 1, max: 10)

let order1 = Order(items: ["item1", "item2"])
requirement.evaluate(order1) // .confirmed

let order2 = Order(items: [])
requirement.evaluate(order2) // .failed
```

---

#### #requireNotEmpty

Проверяет, что коллекция не пустая.

```swift
let requirement: Requirement<Context> = #requireNotEmpty(\.cart)
```

**Параметры:**
- `keyPath`: KeyPath к коллекции

**Пример:**
```swift
let requirement = #requireNotEmpty(\.items)

let order1 = Order(items: ["item1"])
requirement.evaluate(order1) // .confirmed

let order2 = Order(items: [])
requirement.evaluate(order2) // .failed
```

---

#### #requireEmpty

Проверяет, что коллекция пустая.

```swift
let requirement: Requirement<Context> = #requireEmpty(\.errors)
```

**Параметры:**
- `keyPath`: KeyPath к коллекции

---

### Макросы для Optional значений

#### #requireNonNil

Проверяет, что Optional значение не nil.

```swift
let requirement: Requirement<Context> = #requireNonNil(\.userId)
```

**Параметры:**
- `keyPath`: KeyPath к Optional свойству

**Пример:**
```swift
struct Context: Sendable {
  let userId: String?
}

let requirement = #requireNonNil(\.userId)

let context1 = Context(userId: "user123")
requirement.evaluate(context1) // .confirmed

let context2 = Context(userId: nil)
requirement.evaluate(context2) // .failed
```

---

#### #requireNil

Проверяет, что Optional значение nil.

```swift
let requirement: Requirement<Context> = #requireNil(\.tempData)
```

**Параметры:**
- `keyPath`: KeyPath к Optional свойству

---

#### #requireSome

Проверяет, что Optional содержит значение, удовлетворяющее предикату.

```swift
let requirement: Requirement<Context> = #requireSome(\.age, where: { $0 >= 18 })
```

**Параметры:**
- `keyPath`: KeyPath к Optional свойству
- `predicate`: Замыкание для проверки значения

**Пример:**
```swift
struct Context: Sendable {
  let age: Int?
}

let requirement = #requireSome(\.age, where: { $0 >= 18 })

let context1 = Context(age: 25)
requirement.evaluate(context1) // .confirmed

let context2 = Context(age: 15)
requirement.evaluate(context2) // .failed

let context3 = Context(age: nil)
requirement.evaluate(context3) // .failed
```

---

### Макросы для работы с диапазонами

#### #requireInRange

Проверяет, что значение находится в заданном диапазоне.

```swift
let requirement: Requirement<Context> = #requireInRange(\.age, 18...120)
```

**Параметры:**
- `keyPath`: KeyPath к Comparable свойству
- `range`: Допустимый диапазон (ClosedRange)

**Пример:**
```swift
struct User: Sendable {
  let age: Int
}

let requirement = #requireInRange(\.age, 18...120)

let user1 = User(age: 25)
requirement.evaluate(user1) // .confirmed

let user2 = User(age: 15)
requirement.evaluate(user2) // .failed
```

---

#### #requireBetween

Проверяет, что значение находится между min и max.

```swift
let requirement: Requirement<Context> = #requireBetween(\.amount, min: 10, max: 1000)
```

**Параметры:**
- `keyPath`: KeyPath к Comparable свойству
- `min`: Минимальное значение
- `max`: Максимальное значение

**Пример:**
```swift
struct Transaction: Sendable {
  let amount: Double
}

let requirement = #requireBetween(\.amount, min: 10.0, max: 1000.0)

let tx1 = Transaction(amount: 500.0)
requirement.evaluate(tx1) // .confirmed

let tx2 = Transaction(amount: 5.0)
requirement.evaluate(tx2) // .failed
```

---

## Attached макрос @RequirementModel

Автоматически генерирует метод `validate()` на основе валидационных атрибутов.

### Использование

```swift
@RequirementModel
struct User: Sendable {
  @MinLength(3) @MaxLength(20)
  var username: String
  
  @Email
  var email: String
  
  @InRange(18...120)
  var age: Int
}

let user = User(username: "john", email: "john@example.com", age: 25)
let result = user.validate()
```

### Поддерживаемые атрибуты

#### @MinLength

```swift
@MinLength(3)
var username: String
```

#### @MaxLength

```swift
@MaxLength(20)
var username: String
```

#### @Email

```swift
@Email
var email: String
```

#### @Phone

```swift
@Phone
var phoneNumber: String
```

#### @URL

```swift
@URL
var website: String
```

#### @NotEmpty

```swift
@NotEmpty
var items: [String]
```

#### @InRange

```swift
@InRange(18...120)
var age: Int
```

#### @NonNil

```swift
@NonNil
var userId: String?
```

#### @NotBlank

```swift
@NotBlank
var name: String
```

#### @Matches

```swift
@Matches(#"^[a-zA-Z0-9]+$"#)
var username: String
```

### Комплексный пример

```swift
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
}

let form = RegistrationForm(
  username: "john123",
  email: "john@example.com",
  password: "SecurePassword123",
  age: 25,
  phoneNumber: "+1234567890",
  interests: ["coding", "music"]
)

let validation = form.validate()
if validation.isConfirmed {
  print("Форма валидна")
} else {
  print("Ошибки:", validation.allFailures)
}
```

## Композиция макросов

Все макросы можно комбинировать с композиционными макросами.

### С #all

```swift
let requirement: Requirement<User> = #all {
  #requireMinLength(\.username, 3)
  #requireMaxLength(\.username, 20)
  #requireEmail(\.email)
  #requireInRange(\.age, 18...120)
}
```

### С #any

```swift
let requirement: Requirement<User> = #any {
  #requireEmail(\.primaryEmail)
  #requireEmail(\.secondaryEmail)
}
```

### С #when

```swift
let requirement: Requirement<User> = #when(\.isPremium) {
  #requireNonNil(\.userId)
  #requireNotEmpty(\.preferences)
}
```

### Вложенная композиция

```swift
let requirement: Requirement<User> = #all {
  #requireNotBlank(\.name)
  #any {
    #requireEmail(\.primaryEmail)
    #requireEmail(\.secondaryEmail)
  }
  #when(\.isEnterprise) {
    #requirePhone(\.supportPhone)
    #requireNotEmpty(\.departments)
  }
}
```

## Лучшие практики

### 1. Используйте специализированные макросы

**Хорошо:**
```swift
#requireEmail(\.email)
```

**Плохо:**
```swift
#requireMatches(\.email, pattern: ValidationPattern.email)
```

### 2. Комбинируйте атрибуты в @RequirementModel

```swift
@RequirementModel
struct User {
  @MinLength(3) @MaxLength(20) @Matches(#"^[a-zA-Z0-9]+$"#)
  var username: String
}
```

### 3. Используйте семантичные имена

```swift
let usernameValid = #all {
  #requireMinLength(\.username, 3)
  #requireMaxLength(\.username, 20)
}
```

### 4. Разделяйте сложные требования

```swift
let emailValid = #requireEmail(\.email)
let usernameValid = #requireMinLength(\.username, 3)
let passwordValid = #requireMinLength(\.password, 8)

let formValid = #all {
  emailValid
  usernameValid
  passwordValid
}
```

## См. также

- <doc:GettingStarted>
- <doc:DataValidation>
- <doc:ComposingRequirements>
- <doc:HandlingResults>

