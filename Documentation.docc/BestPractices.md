# Лучшие практики

Рекомендации по эффективному использованию RequirementsKit.

## Обзор

Эта статья содержит проверенные практики и рекомендации для разработки с RequirementsKit.

## Именование

### Используйте глаголы для требований

```swift
// ✅ Хорошо
let canEdit = Requirement<Document>...
let canDelete = Requirement<Document>...
let hasAccess = Requirement<Resource>...
let mayPurchase = Requirement<Product>...

// ❌ Плохо
let edit = Requirement<Document>...
let access = Requirement<Resource>...
let requirement1 = Requirement<Product>...
```

### Описательные имена для контекста

```swift
// ✅ Хорошо
struct TradingContext {
  let user: User
  let tradeAmount: Double
  let asset: Asset
  let region: Region
}

// ❌ Плохо
struct Context {
  let u: User
  let amt: Double
  let a: Asset
  let r: Region
}
```

### Группируйте требования по доменам

```swift
enum AuthRequirements {
  static let isAuthenticated = ...
  static let hasValidSession = ...
  static let twoFactorCompleted = ...
}

enum PaymentRequirements {
  static let hasValidPaymentMethod = ...
  static let sufficientBalance = ...
  static let withinTransactionLimit = ...
}

enum TradingRequirements {
  static let canTrade = ...
  static let canTradeMargin = ...
  static let canTradeOptions = ...
}
```

## Организация кода

### Создавайте переиспользуемые компоненты

```swift
// ✅ Хорошо - переиспользуемый компонент
enum CommonRequirements {
  static let basicAuth = #all {
    #require(\.user.isLoggedIn)
    #require(\.user.isVerified)
  }
  
  static let premiumUser = #all {
    basicAuth
    #require(\.user.isPremium)
    #require(\.subscription.isActive)
  }
}

// Используем в разных местах
let canAccessFeatureA = CommonRequirements.premiumUser
let canAccessFeatureB = CommonRequirements.premiumUser && additionalCheck

// ❌ Плохо - дублирование
let canAccessFeatureA = #all {
  #require(\.user.isLoggedIn)
  #require(\.user.isVerified)
  #require(\.user.isPremium)
  #require(\.subscription.isActive)
}

let canAccessFeatureB = #all {
  #require(\.user.isLoggedIn)  // Дубликат
  #require(\.user.isVerified)  // Дубликат
  #require(\.user.isPremium)   // Дубликат
  #require(\.subscription.isActive)  // Дубликат
  additionalCheck
}
```

### Разделяйте по слоям

```swift
// Domain Layer
struct DomainRequirements {
  static let canCreateOrder = #all {
    #require(\.user.isActive)
    #require(\.inventory.available)
  }
}

// Application Layer
class OrderService {
  func createOrder(context: OrderContext) -> Result<Order, Error> {
    guard DomainRequirements.canCreateOrder.evaluate(context).isConfirmed else {
      return .failure(OrderError.requirementsFailed)
    }
    
    return .success(createOrderInternal(context))
  }
}

// Presentation Layer
struct CreateOrderView: View {
  @Eligibility(by: DomainRequirements.canCreateOrder, context: context)
  var canCreate
  
  var body: some View {
    Button("Create Order") { /* ... */ }
      .disabled(!canCreate.isAllowed)
  }
}
```

## Причины отказа

### Всегда добавляйте понятные причины

```swift
// ✅ Хорошо
#require(\.balance, greaterThan: 100)
  .because("Минимальный баланс для операции: 100")

#require(\.user.isPremium)
  .because(code: "premium_required", message: "Требуется Premium подписка")

// ❌ Плохо
#require(\.balance, greaterThan: 100)  // Без причины
#require(\.user.isPremium)             // Без причины
```

### Используйте коды для программной обработки

```swift
// ✅ Хорошо
let requirement = #require(\.balance, greaterThan: 100)
  .because(
    code: "insufficient_balance",
    message: "Недостаточно средств на балансе"
  )

// Обработка
if let reason = result.reason {
  switch reason.code {
  case "insufficient_balance":
    showTopUpScreen()
  case "premium_required":
    showUpgradeScreen()
  default:
    showGenericError(reason.message)
  }
}
```

### Локализуйте сообщения

```swift
extension Reason {
  static func insufficientBalance(_ amount: Double) -> Reason {
    Reason(
      code: "insufficient_balance",
      message: String(localized: "Требуется минимум \(amount)",
                     comment: "Insufficient balance error")
    )
  }
}
```

## Производительность

### Располагайте быстрые проверки первыми

```swift
// ✅ Хорошо
let requirement = #all {
  #require(\.isLoggedIn)       // Быстро - O(1)
  #require(\.isPremium)        // Быстро - O(1)
  expensiveDatabaseCheck       // Медленно - I/O
  complexCalculation           // Медленно - CPU
}

// ❌ Плохо
let requirement = #all {
  complexCalculation           // Выполняется всегда
  expensiveDatabaseCheck       // Выполняется всегда
  #require(\.isLoggedIn)       // Может отсечь рано
}
```

### Кэшируйте дорогие операции

```swift
// ✅ Хорошо - кэшируем
let cached = expensiveRequirement.cached(ttl: 60.0)

// ❌ Плохо - пересчитываем каждый раз
let result = expensiveRequirement.evaluate(context)
```

### Используйте параллельную проверку

```swift
// ✅ Хорошо - параллельно
let checks = AsyncRequirement.allConcurrent([
  checkAPI,
  checkDatabase,
  checkFiles
])

// ❌ Плохо - последовательно (медленнее)
let checks = AsyncRequirement.all([
  checkAPI,     // 100ms
  checkDatabase, // 100ms
  checkFiles    // 100ms
]) // Итого: ~300ms вместо ~100ms
```

## Тестирование

### Создавайте тестовые контексты

```swift
extension UserContext {
  static var testLoggedIn: UserContext {
    UserContext(
      user: User(isLoggedIn: true, isVerified: true),
      features: FeatureFlags.default
    )
  }
  
  static var testGuest: UserContext {
    UserContext(
      user: User(isLoggedIn: false, isVerified: false),
      features: FeatureFlags.default
    )
  }
  
  static var testAdmin: UserContext {
    UserContext(
      user: User(isLoggedIn: true, isVerified: true, isAdmin: true),
      features: FeatureFlags.default
    )
  }
}

// В тестах
func testCanAccessAdminPanel() {
  let result = adminPanelRequirement.evaluate(.testAdmin)
  XCTAssertTrue(result.isConfirmed)
}
```

### Тестируйте граничные случаи

```swift
func testBalanceRequirement() {
  // Граница: ровно минимум
  let exactMinimum = UserContext(balance: 100)
  XCTAssertTrue(balanceRequirement.evaluate(exactMinimum).isConfirmed)
  
  // Чуть меньше минимума
  let belowMinimum = UserContext(balance: 99.99)
  XCTAssertFalse(balanceRequirement.evaluate(belowMinimum).isConfirmed)
  
  // Чуть больше минимума
  let aboveMinimum = UserContext(balance: 100.01)
  XCTAssertTrue(balanceRequirement.evaluate(aboveMinimum).isConfirmed)
}
```

### Используйте моки для async требований

```swift
class MockAuthService: AuthService {
  var shouldSucceed = true
  
  func checkAccess(userId: String) async -> Bool {
    shouldSucceed
  }
}

func testAsyncRequirement() async throws {
  let mockService = MockAuthService()
  let requirement = AsyncRequirement<Context> { context in
    let hasAccess = await mockService.checkAccess(userId: context.userId)
    return hasAccess ? .confirmed : .failed(reason: Reason(message: "No access"))
  }
  
  // Test success
  mockService.shouldSucceed = true
  let successResult = try await requirement.evaluate(testContext)
  XCTAssertTrue(successResult.isConfirmed)
  
  // Test failure
  mockService.shouldSucceed = false
  let failureResult = try await requirement.evaluate(testContext)
  XCTAssertFalse(failureResult.isConfirmed)
}
```

## Обработка ошибок

### Всегда обрабатывайте оба случая

```swift
// ✅ Хорошо
switch requirement.evaluate(context) {
case .confirmed:
  performAction()
case .failed(let reason):
  handleError(reason)
}

// ❌ Плохо
if requirement.evaluate(context).isConfirmed {
  performAction()
}
// Что если failed?
```

### Предоставляйте пользователю действия

```swift
// ✅ Хорошо - предлагаем действие
if let reason = result.reason {
  switch reason.code {
  case "insufficient_balance":
    showError(reason.message, action: "Пополнить счёт") {
      showTopUpScreen()
    }
  case "premium_required":
    showError(reason.message, action: "Купить Premium") {
      showUpgradeScreen()
    }
  default:
    showError(reason.message)
  }
}

// ❌ Плохо - только сообщение
if let reason = result.reason {
  showError(reason.message)
}
```

## Отладка

### Используйте именованные требования

```swift
// ✅ Хорошо
let requirement = Requirement.named("Trading Access Check") {
  #require(\.user.isLoggedIn)
  #require(\.user.isVerified)
}
.traced(name: "Trading")

// ❌ Плохо
let requirement = #all {
  #require(\.user.isLoggedIn)
  #require(\.user.isVerified)
}
```

### Логируйте критичные проверки

```swift
// ✅ Хорошо
let paymentCheck = requirement
  .with(middlewares: [
    LoggingMiddleware(level: .info, prefix: "[Payment]"),
    AnalyticsMiddleware { event, props in
      Analytics.track(event, properties: props)
    }
  ])

// ❌ Плохо - без логирования
let paymentCheck = requirement
```

## Безопасность

### Не храните секреты в контексте

```swift
// ✅ Хорошо - храним только идентификаторы
struct SecureContext {
  let userId: String
  let sessionId: String
  
  func getToken() async throws -> String {
    try await SecureStorage.shared.getToken(userId: userId)
  }
}

// ❌ Плохо - секреты в контексте
struct InsecureContext {
  let userId: String
  let password: String  // ❌
  let apiKey: String    // ❌
}
```

### Валидируйте на клиенте и сервере

```swift
// Клиент
let clientValidation = userInputRequirement

// Сервер
let serverValidation = AsyncRequirement<Input> { input in
  try await api.validateInput(input)
}

// Используем оба
guard clientValidation.evaluate(input).isConfirmed else {
  return  // Быстрый отказ на клиенте
}

let result = try await serverValidation.evaluate(input)
// Финальная проверка на сервере
```

## Документация

### Документируйте сложные требования

```swift
/// Проверяет возможность совершения маржинальной торговли.
///
/// Требования:
/// 1. Базовая авторизация (login + verify + not banned)
/// 2. Один из вариантов:
///    - Enterprise аккаунт
///    - Premium с пройденным KYC
///
/// - Parameter context: Контекст торговой операции
/// - Returns: `.confirmed` если разрешено, `.failed` с причиной если запрещено
let marginTradingAccess = Requirement<TradingContext> ...
```

### Добавляйте примеры использования

```swift
/// Проверяет возможность редактирования документа
///
/// ```swift
/// let context = DocumentContext(user: currentUser, document: document)
/// let result = canEditDocument.evaluate(context)
///
/// switch result {
/// case .confirmed:
///   showEditor()
/// case .failed(let reason):
///   showError(reason.message)
/// }
/// ```
let canEditDocument = ...
```

## Смотрите также

- <doc:AdvancedPatterns>
- <doc:DebuggingAndTracing>
- <doc:CachingAndPerformance>

