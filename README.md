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

### 🔍 Debugging и трассировка
- Детальная трассировка проверки требований
- Профилирование производительности
- Middleware для логирования и аналитики

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

#### String валидация

```swift
import RequirementsKit

let emailValid = Requirement<String>
  .notEmpty()
  .matches(pattern: #"^[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}$"#, options: .caseInsensitive)
  .because("Некорректный email")

let email = "user@example.com"
let result = emailValid.evaluate(email)
```

#### Collection валидация

```swift
let hasItems = Requirement<[Item]>
  .notEmpty()
  .count(min: 1, max: 100)
  .because("Корзина должна содержать от 1 до 100 товаров")
```

#### Range валидация

```swift
let ageValid = Requirement<Int>
  .inRange(18...120)
  .because("Возраст должен быть от 18 до 120 лет")
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
- [Примеры использования](Examples/)

---

## Поддержка

Если у вас есть вопросы или предложения, создайте Issue в репозитории.
