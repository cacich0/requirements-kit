# RequirementsKit

**RequirementsKit** — это современная Swift-библиотека для декларативного описания и проверки бизнес-требований (business requirements) в вашем приложении. Она позволяет выразить сложную бизнес-логику в виде читаемых, переиспользуемых и композируемых правил без бесконечных цепочек `if/else`.

Вместо императивного подхода:

```swift
if user.isLoggedIn && !user.isBanned && 
   (user.isAdmin || (user.hasPremium && user.balance > 100 && user.kycLevel >= .basic)) {
  // разрешить торговлю
} else {
  // показать сообщение об ошибке
}
```

RequirementsKit предлагает декларативный подход:

```swift
let canTrade = Requirement<TradingContext> = #all {
  #require(\.user.isLoggedIn)
  #require(\.user.isBanned, equals: false)
  
  #any {
    #require(\.user.isAdmin)
    
    #all {
      #require(\.user.hasPremium)
      #require(\.user.balance, greaterThan: 100)
      #require(\.user.kycLevel, greaterThanOrEqual: .basic)
    }
  }
}

let result = canTrade.evaluate(context)
```

## Features

### 🎯 Декларативный синтаксис
- Макросы `#require`, `#all`, `#any`, `#not` для читаемого кода
- Макросы валидации `#requireEmail`, `#requirePhone`, `#requireInRange` и др.
- Attached макрос `@RequirementModel` для автоматической валидации
- Fluent API с методами `.and()`, `.or()`, `.because()`
- Логические операторы `&&`, `||`, `!`

### 🔗 Мощная композиция
- **ALL** — все условия обязательны
- **ANY** — достаточно одного условия
- **NOT** — инверсия требования
- **XOR** — ровно одно из условий
- **WHEN/UNLESS** — условная проверка
- **Fallback** — запасной вариант

### 📊 KeyPath-операторы
Поддержка сравнений через KeyPath:
- `#require(\.balance, greaterThan: 100)`
- `#require(\.role, equals: .admin)`
- `#require(\.kycLevel, greaterThanOrEqual: .basic)`
- `#require(\.email, notEquals: "")`

### 💡 Понятные причины отказа
- Явное описание причины с помощью `.because()`
- Получение всех ошибок через `.allFailures`
- Кастомные коды ошибок для аналитики

### ⚡️ Асинхронность и производительность
- `AsyncRequirement` для async/await операций
- Параллельная проверка с `.allConcurrent()` и `.anyConcurrent()`
- Кэширование результатов с настраиваемым TTL
- Поддержка таймаутов для асинхронных проверок
- **Rate Limiting** — ограничение количества вызовов за период времени
- **Throttling** — минимальный интервал между вызовами
- **Debounce** — отложенное выполнение после завершения ввода

### 🔍 Debugging и трассировка
- Детальная трассировка проверки требований
- Профилирование производительности
- Middleware для логирования и аналитики

### ✅ Валидация данных
- **16 макросов** для валидации строк, коллекций, Optional, диапазонов
- Макрос `@RequirementModel` для автоматической генерации валидации
- Встроенные паттерны: email, phone, URL, UUID
- Композиция валидационных атрибутов

<details>
<summary>Список всех валидационных макросов</summary>

**Строки:**
- `#requireEmail(\.field)` — валидация email
- `#requirePhone(\.field)` — валидация телефона
- `#requireURL(\.field)` — валидация URL
- `#requireMinLength(\.field, n)` — минимальная длина
- `#requireMaxLength(\.field, n)` — максимальная длина
- `#requireLength(\.field, in: range)` — длина в диапазоне
- `#requireNotBlank(\.field)` — не пустая строка
- `#requireMatches(\.field, pattern:)` — regex проверка

**Коллекции:**
- `#requireNotEmpty(\.field)` — не пустая коллекция
- `#requireEmpty(\.field)` — пустая коллекция
- `#requireCount(\.field, min:max:)` — количество элементов

**Optional:**
- `#requireNonNil(\.field)` — значение не nil
- `#requireNil(\.field)` — значение nil
- `#requireSome(\.field, where:)` — Optional с предикатом

**Диапазоны:**
- `#requireInRange(\.field, range)` — значение в диапазоне
- `#requireBetween(\.field, min:max:)` — значение между min и max

</details>

### 🎨 Интеграция с UI
- Property wrappers `@Eligible` и `@Eligibility`
- SwiftUI интеграция с `ObservableSupport`
- Combine publishers для реактивных приложений

### 🔐 Безопасность и надёжность
- Полная поддержка Swift Concurrency (Sendable, async/await)
- Потокобезопасность (Swift 6.0+)
- Без внешних зависимостей

---

## Quick Start

### Установка

#### Swift Package Manager

Добавьте RequirementsKit в `Package.swift`:

```swift
dependencies: [
  .package(url: "https://github.com/cacich0/requirements-kit.git", from: "1.0.0")
]
```

Или через Xcode: **File → Add Package Dependencies...**

### Базовое использование

#### 1. Определите контекст

Контекст — это структура с данными для принятия решения:

```swift
import RequirementsKit

struct UserContext: Sendable {
  let isLoggedIn: Bool
  let isPremium: Bool
  let balance: Double
}
```

#### 2. Создайте требование

Простое требование через KeyPath:

```swift
let requireLogin = Requirement<UserContext>.require(\.isLoggedIn)

let context = UserContext(isLoggedIn: true, isPremium: false, balance: 50)
let result = requireLogin.evaluate(context)

switch result {
case .confirmed:
  print("✅ Доступ разрешён")
case .failed(let reason):
  print("❌ Отказано: \(reason.message)")
}
```

#### Быстрый старт с макросами валидации

Для простой валидации данных используйте макросы:

```swift
// Валидация email
let emailValid: Requirement<FormContext> = #requireEmail(\.email)

// Валидация с композицией
let formValid: Requirement<FormContext> = #all {
  #requireEmail(\.email)
  #requireMinLength(\.username, 3)
  #requireInRange(\.age, 18...120)
}

// Автоматическая валидация с @RequirementModel
@RequirementModel
struct User: Sendable {
  @Email
  var email: String
  
  @MinLength(3) @MaxLength(20)
  var username: String
  
  @InRange(18...120)
  var age: Int
}

let user = User(email: "user@example.com", username: "john", age: 25)
let validation = user.validate() // Автоматически генерируется!
```

#### 3. Добавьте описание причины

```swift
let requireLogin = Requirement<UserContext>
  .require(\.isLoggedIn)
  .because("Необходима авторизация")
```

### Композиция требований

#### ALL — все условия обязательны

```swift
let canAccessPremium = Requirement<UserContext>.all {
  #require(\.isLoggedIn)
  #require(\.isPremium)
}
```

#### ANY — достаточно одного условия

```swift
let hasSpecialAccess = Requirement<UserContext>.any {
  #require(\.isPremium)
  #require(\.balance, greaterThan: 1000)
}
```

#### Вложенная композиция

```swift
let canTrade = Requirement<UserContext>.all {
  #require(\.isLoggedIn)
    .because("Требуется авторизация")
  
  #any {
    #require(\.isPremium)
      .because("Требуется Premium подписка")
    
    #require(\.balance, greaterThan: 500)
      .because("Недостаточный баланс")
  }
}
```

### Property Wrappers

#### @Eligible — bool доступ

```swift
struct FeatureView {
  @Eligible(by: canTrade, context: userContext)
  var isTradeAllowed: Bool
  
  func showButton() {
    if isTradeAllowed {
      // показать кнопку торговли
    }
  }
}
```

#### @Eligibility — расширенный доступ

```swift
@Eligibility(by: canTrade, context: userContext)
var tradeEligibility

if tradeEligibility.isAllowed {
  trade()
} else {
  showError(tradeEligibility.reason?.message ?? "Доступ запрещён")
}
```

### SwiftUI интеграция

```swift
struct TradeButton: View {
  @Eligibility(by: canTrade, context: userContext)
  var eligibility
  
  var body: some View {
    VStack {
      Button("Торговать") {
        performTrade()
      }
      .disabled(!eligibility.isAllowed)
      
      if let reason = eligibility.reason {
        Text(reason.message)
          .foregroundColor(.red)
          .font(.caption)
      }
    }
  }
}
```

### Логические операторы

RequirementsKit поддерживает стандартные логические операторы:

```swift
let requirement1 = Requirement<UserContext>.require(\.isLoggedIn)
let requirement2 = Requirement<UserContext>.require(\.isPremium)

// AND
let both = requirement1 && requirement2

// OR
let either = requirement1 || requirement2

// NOT
let notPremium = !requirement2
```

### Fluent API

```swift
let requirement = Requirement<UserContext>
  .require(\.isLoggedIn)
  .and(\.isPremium)
  .and { context in
    context.balance > 100
  }
  .because("Недостаточно прав доступа")
```

---

## Advanced Usage

### Условные требования

#### WHEN — проверка при условии

```swift
// Если пользователь бета-тестер, требуется подписка
let betaRequirement = Requirement<User>.when(\.isBetaTester) {
  #require(\.hasActiveSubscription)
}
```

#### UNLESS — проверка если условие НЕ выполнено

```swift
// Если НЕ админ, требуется верификация
let verificationRequired = Requirement<User>.unless(\.isAdmin) {
  #require(\.isVerified)
  #require(\.kycCompleted)
}
```

#### XOR — ровно одно условие

```swift
// Либо trial, либо premium (не оба одновременно)
let exclusiveSubscription = Requirement<User>.xor {
  Requirement<User> { $0.subscriptionType == .trial ? .confirmed : .failed(reason: Reason(message: "Not trial")) }
  Requirement<User> { $0.subscriptionType == .premium ? .confirmed : .failed(reason: Reason(message: "Not premium")) }
}
```

### Fallback требования

Если основное требование не выполнено, проверяется запасное:

```swift
let marginTradingAccess = Requirement<TradingContext>
  .require(\.user.isEnterprise)
  .fallback {
    Requirement<TradingContext>.require(\.user.isPremium)
    Requirement<TradingContext>.require(\.user.kycCompleted)
  }
  .because("Требуется Enterprise или верифицированный Premium")
```

### Именованные требования

Для логирования и отладки:

```swift
let premiumAccess = Requirement.named("Premium Access Check") {
  #require(\.user.hasPremium)
  #require(\.user.subscriptionActive)
}
```

С логированием:

```swift
let requirement = Requirement<UserContext>
  .require(\.isLoggedIn)
  .logged("Authentication Check")
```

### Асинхронные требования

#### Базовое использование

```swift
let checkApiAccess = AsyncRequirement<UserContext> { context in
  let hasAccess = try await apiService.checkAccess(userId: context.userId)
  return hasAccess ? .confirmed : .failed(reason: Reason(message: "API access denied"))
}

// Проверка
let result = try await checkApiAccess.evaluate(context)
```

#### Композиция асинхронных требований

```swift
// Последовательная проверка
let allChecks = AsyncRequirement.all([
  checkApiAccess,
  checkDatabaseAccess,
  checkPermissions
])

// Параллельная проверка (быстрее)
let allChecksConcurrent = AsyncRequirement.allConcurrent([
  checkApiAccess,
  checkDatabaseAccess,
  checkPermissions
])
```

#### Таймауты

```swift
@available(iOS 16.0, *)
let timedRequirement = AsyncRequirement.withTimeout(
  seconds: 5.0,
  checkApiAccess
)
```

### Кэширование результатов

Для требований, которые проверяются часто и редко меняются:

```swift
// Бессрочное кэширование
let cached = requirement.cached()

// С TTL (время жизни кэша)
let cachedWithTTL = requirement.cached(ttl: 60.0) // 60 секунд

// Использование
let result = cached.evaluate(context) // первый раз вычисляется
let result2 = cached.evaluate(context) // берётся из кэша

// Инвалидация
cached.invalidate(context)
cached.invalidateAll()
```

### Rate Limiting, Throttling и Debounce

Контролируйте частоту выполнения требований для оптимизации производительности и защиты от перегрузки.

#### Rate Limiting

Ограничивает количество вызовов за период времени (например, максимум 100 запросов в минуту):

```swift
let apiRequirement = AsyncRequirement<User> { user in
    let response = try await api.fetchUserData(user.id)
    return response.isValid ? .confirmed : .failed(reason: Reason(message: "Invalid"))
}
.rateLimit(
    maxCalls: 100,
    timeWindow: 60,
    behavior: .returnCached // При превышении вернуть кэш
)

// Использование
do {
    let result = try await apiRequirement.evaluate(user)
    print("Result:", result)
} catch {
    print("Error:", error)
}
```

**Поведение при превышении лимита:**
- `.returnFailed(Reason(...))` — вернуть ошибку (по умолчанию)
- `.returnCached` — вернуть последний успешный результат
- `.skip` — пропустить проверку и вернуть .confirmed

#### Throttling

Гарантирует минимальный интервал между вызовами (например, не чаще раза в секунду):

```swift
let validationRequirement = Requirement<String> { text in
    // Дорогая валидация
    expensiveValidation(text)
}
.throttle(
    interval: 1.0,
    behavior: .returnCached
)

let result1 = validationRequirement.evaluate("text1") // ✅ Выполнится
let result2 = validationRequirement.evaluate("text2") // ↩️ Вернёт кэш
```

#### Debounce

Откладывает выполнение до тех пор, пока не пройдет интервал без новых вызовов (идеально для поиска):

```swift
@available(macOS 13.0, iOS 16.0, *)
let searchRequirement = AsyncRequirement<String> { query in
    let results = try await api.search(query: query)
    return results.isEmpty ? .failed(reason: Reason(message: "No results")) : .confirmed
}
.debounce(delay: 0.3) // Подождать 300ms после последнего ввода

// Использование в SwiftUI
func performSearch(_ text: String) async {
    do {
        let result = try await searchRequirement.evaluate(text)
        // Обновить UI
    } catch {
        print("Search error:", error)
    }
}
```

**Комбинирование механизмов:**

```swift
let complexRequirement = AsyncRequirement<Request> { request in
    try await api.execute(request)
}
.debounce(delay: 0.2)           // Отложить на 200ms
.throttle(interval: 0.5)         // Минимум 0.5 сек между вызовами
.rateLimit(                      // Максимум 50 запросов в минуту
    maxCalls: 50,
    timeWindow: 60,
    behavior: .returnCached
)
```

**Использование внутри композиции:**

```swift
// Rate limiting и throttling можно применять к отдельным требованиям!
let requirement = Requirement<User>.all {
    // Первое требование с rate limiting
    Requirement<User> { user in
        validateWithAPI(user.email)
    }
    .rateLimit(maxCalls: 10, timeWindow: 60)
    
    // Второе требование с throttling
    Requirement<User> { user in
        checkDatabase(user.id)
    }
    .throttle(interval: 1.0, behavior: .returnCached)
    
    // Обычное требование
    Requirement<User>.require(\.isActive)
}
```

**Когда использовать:**
- **Rate Limiting**: API с ограничением запросов, защита от DDoS
- **Throttling**: Автосохранение, регулярные обновления
- **Debounce**: Поиск при вводе, валидация форм в реальном времени

Подробнее: [Документация Rate Limiting](Documentation.docc/RateLimitingAndThrottling.md)

### Middleware

Middleware позволяет перехватывать проверку требований для логирования и аналитики.

#### Logging Middleware

```swift
let loggingMiddleware = LoggingMiddleware(
  level: .verbose,
  prefix: "[Requirement]"
)

let requirement = canTrade
  .with(middleware: loggingMiddleware)
```

Вывод:

```
[Requirement] Evaluating: unnamed
[Requirement] ✅ unnamed (2.34ms)
```

#### Analytics Middleware

```swift
let analyticsMiddleware = AnalyticsMiddleware { eventName, properties in
  Analytics.track(eventName, properties: properties)
}

let requirement = canTrade
  .with(middleware: analyticsMiddleware)
```

Отправляет события:

```json
{
  "event": "requirement_evaluated",
  "requirement_name": "canTrade",
  "result": "confirmed",
  "duration_ms": 2.34
}
```

#### Множественные Middleware

```swift
let requirement = canTrade
  .with(middlewares: [
    loggingMiddleware,
    analyticsMiddleware,
    customMiddleware
  ])
```

### Combine интеграция

#### Publisher из Requirement

```swift
import Combine

let contextPublisher = PassthroughSubject<UserContext, Never>()

let evaluationPublisher = requirement.publisher(context: contextPublisher)

evaluationPublisher
  .sink { evaluation in
    print("Результат: \(evaluation.isConfirmed)")
  }
  .store(in: &cancellables)

// Испускаем новый контекст
contextPublisher.send(newContext)
```

#### ReactiveRequirement

```swift
let reactiveRequirement = ReactiveRequirement(
  requirement: canTrade,
  initialContext: context
)

reactiveRequirement.subscribe(to: contextPublisher)

// Реактивные свойства
print(reactiveRequirement.isAllowed) // true/false
print(reactiveRequirement.reason?.message) // "..."
```

#### Property Wrapper для Combine

```swift
@RequirementPublisher(by: canTrade, initialContext: context)
var tradePublisher

tradePublisher
  .sink { evaluation in
    // обработка изменений
  }
  .store(in: &cancellables)

// Обновить контекст
$tradePublisher.send(newContext)
```

### Валидация данных

RequirementsKit предоставляет мощные макросы для валидации строк, коллекций, опциональных значений и диапазонов.

#### Макросы валидации строк

```swift
struct FormContext: Sendable {
  let email: String
  let username: String
  let password: String
  let phone: String
  let website: String
}

// Email валидация
let emailValid: Requirement<FormContext> = #requireEmail(\.email)

// Username с проверкой длины
let usernameValid: Requirement<FormContext> = #all {
  #requireMinLength(\.username, 3)
  #requireMaxLength(\.username, 20)
  #requireMatches(\.username, pattern: ValidationPattern.alphanumeric)
}

// Password с комплексной валидацией
let passwordValid: Requirement<FormContext> = #all {
  #requireLength(\.password, in: 8...128)
  #requireMatches(\.password, pattern: ".*[0-9].*")     // содержит цифру
  #requireMatches(\.password, pattern: ".*[A-Z].*")     // содержит заглавную букву
  #requireMatches(\.password, pattern: ".*[a-z].*")     // содержит строчную букву
}

// Телефон в международном формате
let phoneValid: Requirement<FormContext> = #requirePhone(\.phone)

// URL валидация
let websiteValid: Requirement<FormContext> = #requireURL(\.website)

// Не пустая строка (после trim)
let nameValid: Requirement<FormContext> = #requireNotBlank(\.name)
```

**Доступные макросы:**
- `#requireEmail(\.field)` — валидация email
- `#requirePhone(\.field)` — валидация телефона
- `#requireURL(\.field)` — валидация URL
- `#requireMinLength(\.field, 3)` — минимальная длина
- `#requireMaxLength(\.field, 20)` — максимальная длина
- `#requireLength(\.field, in: 8...20)` — длина в диапазоне
- `#requireNotBlank(\.field)` — не пустая строка
- `#requireMatches(\.field, pattern: "...")` — regex проверка

#### Макросы валидации коллекций

```swift
struct OrderContext: Sendable {
  let items: [String]
  let errors: [String]
}

// Коллекция не пустая
let hasItems: Requirement<OrderContext> = #requireNotEmpty(\.items)

// Количество элементов в диапазоне
let validItemCount: Requirement<OrderContext> = #requireCount(\.items, min: 1, max: 100)

// Коллекция пустая (для проверки отсутствия ошибок)
let noErrors: Requirement<OrderContext> = #requireEmpty(\.errors)

// Комплексная валидация корзины
let validCart: Requirement<OrderContext> = #all {
  #requireNotEmpty(\.items)
  #requireCount(\.items, min: 1, max: 50)
  #requireEmpty(\.errors)
}
```

#### Макросы для Optional значений

```swift
struct UserContext: Sendable {
  let userId: String?
  let age: Int?
  let tempData: String?
}

// Значение должно быть не nil
let userIdRequired: Requirement<UserContext> = #requireNonNil(\.userId)

// Значение должно быть nil
let noTempData: Requirement<UserContext> = #requireNil(\.tempData)

// Optional с предикатом
let adultUser: Requirement<UserContext> = #requireSome(\.age, where: { $0 >= 18 })

// Комплексная проверка
let validUser: Requirement<UserContext> = #all {
  #requireNonNil(\.userId)
  #requireSome(\.age, where: { $0 >= 18 })
  #requireNil(\.tempData)
}
```

#### Макросы для диапазонов

```swift
struct ProfileContext: Sendable {
  let age: Int
  let temperature: Double
  let score: Int
}

// Возраст в диапазоне
let validAge: Requirement<ProfileContext> = #requireInRange(\.age, 18...120)

// Температура в диапазоне
let validTemp: Requirement<ProfileContext> = #requireInRange(\.temperature, -40.0...50.0)

// Score между min и max
let validScore: Requirement<ProfileContext> = #requireBetween(\.score, min: 0, max: 100)
```

### @RequirementModel — Автоматическая валидация

Используйте attached макрос `@RequirementModel` для автоматической генерации метода `validate()` на основе валидационных атрибутов:

#### Базовый пример

```swift
import RequirementsKit

@RequirementModel
struct User: Sendable {
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

// Использование
let user = User(
  username: "john",
  email: "john@example.com",
  age: 25,
  phoneNumber: "+1234567890",
  userId: "user123",
  createdAt: Date()
)

let validation = user.validate()

if validation.isConfirmed {
  print("✅ Пользователь валиден")
} else {
  print("❌ Ошибки валидации:")
  for failure in validation.allFailures {
    print("  - \(failure.message)")
  }
}
```

#### Доступные атрибуты

```swift
@RequirementModel
struct RegistrationForm: Sendable {
  // Строковые атрибуты
  @MinLength(3) @MaxLength(20) @Matches(#"^[a-zA-Z0-9]+$"#)
  var username: String
  
  @Email
  var email: String
  
  @MinLength(8)
  var password: String
  
  @Phone
  var phoneNumber: String
  
  @URL
  var website: String
  
  @NotBlank
  var fullName: String
  
  // Числовые атрибуты
  @InRange(18...120)
  var age: Int
  
  @InRange(0.5...2.0)
  var animationSpeed: Double
  
  // Коллекции
  @NotEmpty
  var interests: [String]
  
  // Optional
  @NonNil
  var userId: String?
}
```

**Список атрибутов:**
- `@MinLength(n)` — минимальная длина строки
- `@MaxLength(n)` — максимальная длина строки
- `@Email` — валидация email
- `@Phone` — валидация телефона
- `@URL` — валидация URL
- `@NotBlank` — строка не пустая (после trim)
- `@Matches(pattern)` — соответствие regex
- `@InRange(range)` — значение в диапазоне
- `@NotEmpty` — коллекция не пустая
- `@NonNil` — optional не nil

#### Реальный пример: Форма заказа

```swift
@RequirementModel
struct OrderForm: Sendable {
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
  var orderDate: Date
}

// Создание и валидация
let order = OrderForm(
  items: ["item1", "item2"],
  totalAmount: 299.99,
  shippingAddress: "123 Main St",
  billingAddress: "123 Main St",
  contactPhone: "+1234567890",
  contactEmail: "customer@example.com",
  orderId: "ORD-001",
  orderDate: Date()
)

let validation = order.validate()

// Обработка результата
switch validation {
case .confirmed:
  processOrder(order)
  
case .failed:
  showErrors(validation.allFailures)
}
```

#### Композиция с другими требованиями

`@RequirementModel` генерирует метод `validate()`, который можно комбинировать с другими требованиями:

```swift
@RequirementModel
struct User: Sendable {
  @Email
  var email: String
  
  @MinLength(8)
  var password: String
}

// Дополнительные бизнес-требования
let additionalChecks: Requirement<User> = #all {
  Requirement { context in
    context.password != context.email
      ? .confirmed
      : .failed(reason: Reason(message: "Пароль не должен совпадать с email"))
  }
  
  Requirement { context in
    !commonPasswords.contains(context.password)
      ? .confirmed
      : .failed(reason: Reason(message: "Слишком простой пароль"))
  }
}

// Полная валидация
let user = User(email: "user@example.com", password: "SecurePass123")

// Проверяем встроенную валидацию
let basicValidation = user.validate()
guard basicValidation.isConfirmed else {
  print("Ошибки валидации формы")
  return
}

// Проверяем дополнительные требования
let additionalValidation = additionalChecks.evaluate(user)
guard additionalValidation.isConfirmed else {
  print("Ошибки бизнес-логики")
  return
}

print("✅ Регистрация успешна")
```

### Получение всех причин отказа

```swift
let result = requirement.evaluate(context)

if case .failed = result {
  // Получить все причины
  let allFailures = result.allFailures
  
  for failure in allFailures {
    print("❌ \(failure.message)")
  }
}
```

---

## Debugging and Tracing

### Трассировка требований

RequirementTrace позволяет отследить, какие именно требования были проверены и сколько времени это заняло:

```swift
let traced = requirement.traced(name: "Main Requirement")

let (evaluation, trace) = traced.evaluateWithTrace(context)

print("Результат: \(evaluation.isConfirmed)")
print("Длительность: \(trace.duration * 1000)ms")
print("Путь: \(trace.path.joined(separator: " → "))")
```

#### Вложенная трассировка

```swift
let complexRequirement = Requirement<UserContext>.all {
  Requirement<UserContext>
    .require(\.isLoggedIn)
    .named("Login Check")
  
  Requirement<UserContext>
    .require(\.isPremium)
    .named("Premium Check")
}
.traced(name: "Complete Check")

let (_, trace) = complexRequirement.evaluateWithTrace(context)

// trace.children содержит трассировки вложенных требований
for child in trace.children {
  print("- \(child.path): \(child.duration)s")
}
```

### Профилирование производительности

ProfiledRequirement собирает статистику о времени выполнения:

```swift
let profiled = requirement.profiled()

// Выполняем несколько раз
for _ in 0..<100 {
  let (evaluation, metrics) = profiled.evaluateWithMetrics(context)
  
  print("Оценка #\(metrics.evaluationCount)")
  print("- Длительность: \(metrics.duration)s")
  print("- Средняя: \(metrics.averageDuration)s")
  print("- Мин/Макс: \(metrics.minDuration)s / \(metrics.maxDuration)s")
}

// Получить сводную статистику
if let metrics = profiled.metrics {
  print("Всего оценок: \(metrics.evaluationCount)")
  print("Средняя длительность: \(metrics.averageDuration)s")
  print("Диапазон: \(metrics.minDuration)s - \(metrics.maxDuration)s")
}

// Сбросить статистику
profiled.reset()
```

### Debug-логирование

Для детального логирования в Debug-режиме:

```swift
#if DEBUG
let requirement = Requirement<UserContext>
  .require(\.isLoggedIn)
  .logged("Auth Check")
  .and(\.isPremium)
  .logged("Premium Check")
  .with(middleware: LoggingMiddleware(level: .verbose))
#else
let requirement = Requirement<UserContext>
  .require(\.isLoggedIn)
  .and(\.isPremium)
#endif
```

### Детальный анализ ошибок

```swift
let result = requirement.evaluate(context)

if case .failed(let reason) = result {
  print("Код ошибки: \(reason.code)")
  print("Сообщение: \(reason.message)")
  
  // Дополнительная информация
  if let metadata = reason.metadata {
    print("Метаданные: \(metadata)")
  }
}
```

### Middleware для отладки

Создайте собственный middleware для детального анализа:

```swift
struct DebugMiddleware: RequirementMiddleware {
  func beforeEvaluation<Context: Sendable>(
    context: Context,
    requirementName: String?
  ) {
    print("🔍 Проверка: \(requirementName ?? "unknown")")
    print("📊 Контекст: \(context)")
  }
  
  func afterEvaluation<Context: Sendable>(
    context: Context,
    requirementName: String?,
    result: Evaluation,
    duration: TimeInterval
  ) {
    let status = result.isConfirmed ? "✅ Успех" : "❌ Отказ"
    print("\(status): \(requirementName ?? "unknown") (\(duration * 1000)ms)")
    
    if let reason = result.reason {
      print("   Причина: \(reason.message)")
    }
  }
}

// Использование
let debugRequirement = requirement
  .with(middleware: DebugMiddleware())

let result = debugRequirement.evaluate(context)
```

Вывод:

```
🔍 Проверка: Main Requirement
📊 Контекст: UserContext(isLoggedIn: true, isPremium: false, balance: 50.0)
❌ Отказ: Main Requirement (0.15ms)
   Причина: Требуется Premium подписка
```

### Визуализация требований

Для сложных требований можно создать строковое представление структуры:

```swift
extension Requirement {
  func describe(indent: String = "") -> String {
    // Реализация зависит от ваших потребностей
    "\(indent)Requirement<\(Context.self)>"
  }
}

print(complexRequirement.describe())
```

---

## Примеры из реальной жизни

### Система доступа к торговле

```swift
struct TradingContext {
  let user: User
  let tradeAmount: Double
  let remainingDailyLimit: Double
  let tradeType: TradeType
}

let canTrade = Requirement<TradingContext>.all {
  // Базовые требования
  #require(\.user.isLoggedIn)
    .because("Требуется авторизация")
  
  #require(\.user.isVerified)
    .because("Требуется верификация аккаунта")
  
  #require(\.user.kycCompleted)
    .because("Требуется прохождение KYC")
  
  Requirement<TradingContext>.predicate { !$0.user.isBanned }
    .because("Аккаунт заблокирован")
  
  // Финансовые проверки
  Requirement<TradingContext> { context in
    context.user.balance >= context.tradeAmount
      ? .confirmed
      : .failed(reason: Reason(
          code: "insufficient_balance",
          message: "Недостаточно средств: нужно \(context.tradeAmount), есть \(context.user.balance)"
        ))
  }
  
  Requirement<TradingContext> { context in
    context.tradeAmount <= context.remainingDailyLimit
      ? .confirmed
      : .failed(reason: Reason(
          code: "daily_limit_exceeded",
          message: "Превышен дневной лимит: осталось \(context.remainingDailyLimit)"
        ))
  }
  
  // Проверка маржи (опционально)
  Requirement<TradingContext>.when(\.useMargin) {
    Requirement.any {
      #require(\.user.isEnterprise)
      
      Requirement.all {
        #require(\.user.isPremium)
        #require(\.user.kycCompleted)
      }
    }
    .because("Маржинальная торговля требует Enterprise или Premium с KYC")
  }
}
.named("CanTrade")
.traced(name: "Trading Access Check")
```

---

## Системные требования

- **Swift 6.0+**
- **iOS 13.0+** / **macOS 10.15+** / **tvOS 13.0+** / **watchOS 6.0+**
- **Без внешних зависимостей**

---

## Лицензия

MIT License

---

## Автор

RequirementsKit создан для упрощения описания бизнес-логики в Swift приложениях.

---

## Дополнительные ресурсы

- [Документация API](Documentation.docc/)
- [Справочник по макросам](Documentation.docc/MacroReference.md) 📝 **НОВОЕ**
- [Примеры использования](Examples/)
- [Демо-приложение iOS](Examples/RequirementsKitDemo-iOS/)

---

## Поддержка

Если у вас есть вопросы или предложения, создайте Issue в репозитории.
