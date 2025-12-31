# Продвинутые паттерны

Изучите продвинутые техники использования RequirementsKit для сложных сценариев.

## Обзор

Эта статья описывает продвинутые паттерны и техники для опытных пользователей RequirementsKit.

## Dependency Injection

### Контекст с зависимостями

```swift
struct ServiceContext: Sendable {
  let authService: AuthService
  let permissionService: PermissionService
  let user: User
}

let requirement = Requirement<ServiceContext> { context in
  let isAuthenticated = context.authService.isAuthenticated(context.user)
  let hasPermission = context.permissionService.check(context.user, action: .write)
  
  return (isAuthenticated && hasPermission)
    ? .confirmed
    : .failed(reason: Reason(message: "Access denied"))
}
```

### Factory паттерн

```swift
protocol RequirementFactory {
  func createAccessRequirement() -> Requirement<Context>
}

class ProductionRequirementFactory: RequirementFactory {
  func createAccessRequirement() -> Requirement<Context> {
    #all {
      #require(\.isLoggedIn)
      #require(\.isPremium)
    }
  }
}

class DevelopmentRequirementFactory: RequirementFactory {
  func createAccessRequirement() -> Requirement<Context> {
    // В development все проходит
    .always
  }
}
```

## Strategy Pattern

### Динамический выбор стратегии

```swift
protocol AccessStrategy {
  func requirement(for user: User) -> Requirement<Context>
}

class AdminStrategy: AccessStrategy {
  func requirement(for user: User) -> Requirement<Context> {
    #require(\.user.isAdmin)
  }
}

class PremiumStrategy: AccessStrategy {
  func requirement(for user: User) -> Requirement<Context> {
    #all {
      #require(\.user.isPremium)
      #require(\.user.subscriptionActive)
    }
  }
}

class StandardStrategy: AccessStrategy {
  func requirement(for user: User) -> Requirement<Context> {
    #all {
      #require(\.user.isLoggedIn)
      #require(\.user.isVerified)
    }
  }
}

class AccessManager {
  func selectStrategy(for user: User) -> AccessStrategy {
    if user.isAdmin {
      return AdminStrategy()
    } else if user.isPremium {
      return PremiumStrategy()
    } else {
      return StandardStrategy()
    }
  }
  
  func checkAccess(user: User, context: Context) -> Evaluation {
    let strategy = selectStrategy(for: user)
    let requirement = strategy.requirement(for: user)
    return requirement.evaluate(context)
  }
}
```

## Builder Pattern

### RequirementBuilder

```swift
class RequirementBuilder<Context: Sendable> {
  private var requirements: [Requirement<Context>] = []
  
  func add(_ requirement: Requirement<Context>) -> Self {
    requirements.append(requirement)
    return self
  }
  
  func addIf(_ condition: Bool, _ requirement: Requirement<Context>) -> Self {
    if condition {
      requirements.append(requirement)
    }
    return self
  }
  
  func buildAll() -> Requirement<Context> {
    Requirement.all(requirements)
  }
  
  func buildAny() -> Requirement<Context> {
    Requirement.any(requirements)
  }
}

// Использование
let requirement = RequirementBuilder<UserContext>()
  .add(.require(\.isLoggedIn))
  .addIf(strictMode, .require(\.twoFactorEnabled))
  .addIf(isProdEnvironment, .require(\.ipWhitelisted))
  .buildAll()
```

## Chain of Responsibility

### Цепочка обработчиков

```swift
protocol RequirementHandler {
  var next: RequirementHandler? { get set }
  func handle(context: Context) -> Evaluation
}

class AuthHandler: RequirementHandler {
  var next: RequirementHandler?
  
  func handle(context: Context) -> Evaluation {
    guard context.isLoggedIn else {
      return .failed(reason: Reason(message: "Not logged in"))
    }
    
    return next?.handle(context: context) ?? .confirmed
  }
}

class PermissionHandler: RequirementHandler {
  var next: RequirementHandler?
  
  func handle(context: Context) -> Evaluation {
    guard context.hasPermission else {
      return .failed(reason: Reason(message: "No permission"))
    }
    
    return next?.handle(context: context) ?? .confirmed
  }
}

class RateLimitHandler: RequirementHandler {
  var next: RequirementHandler?
  
  func handle(context: Context) -> Evaluation {
    guard context.withinRateLimit else {
      return .failed(reason: Reason(message: "Rate limit exceeded"))
    }
    
    return next?.handle(context: context) ?? .confirmed
  }
}

// Построение цепочки
let authHandler = AuthHandler()
let permissionHandler = PermissionHandler()
let rateLimitHandler = RateLimitHandler()

authHandler.next = permissionHandler
permissionHandler.next = rateLimitHandler

// Использование
let result = authHandler.handle(context: context)
```

## Specification Pattern

### Composable Specifications

```swift
protocol Specification {
  associatedtype T
  func isSatisfied(by candidate: T) -> Bool
}

struct RequirementSpecification<Context: Sendable>: Specification {
  let requirement: Requirement<Context>
  
  func isSatisfied(by context: Context) -> Bool {
    requirement.evaluate(context).isConfirmed
  }
}

// Композиция спецификаций
struct AndSpecification<T>: Specification {
  let left: any Specification<T>
  let right: any Specification<T>
  
  func isSatisfied(by candidate: T) -> Bool {
    left.isSatisfied(by: candidate) && right.isSatisfied(by: candidate)
  }
}

struct OrSpecification<T>: Specification {
  let left: any Specification<T>
  let right: any Specification<T>
  
  func isSatisfied(by candidate: T) -> Bool {
    left.isSatisfied(by: candidate) || right.isSatisfied(by: candidate)
  }
}
```

## Memoization

### Кэширование с функциональным подходом

```swift
func memoized<Context: Hashable>(
  _ requirement: Requirement<Context>
) -> (Context) -> Evaluation {
  var cache: [Context: Evaluation] = [:]
  let lock = NSLock()
  
  return { context in
    lock.lock()
    defer { lock.unlock() }
    
    if let cached = cache[context] {
      return cached
    }
    
    let result = requirement.evaluate(context)
    cache[context] = result
    return result
  }
}

// Использование
let memoizedEvaluate = memoized(expensiveRequirement)

let result1 = memoizedEvaluate(context) // Вычисляется
let result2 = memoizedEvaluate(context) // Из кэша
```

## Proxy Pattern

### RequirementProxy

```swift
class RequirementProxy<Context: Sendable> {
  private let requirement: Requirement<Context>
  private var evaluationCount = 0
  
  init(requirement: Requirement<Context>) {
    self.requirement = requirement
  }
  
  func evaluate(_ context: Context) -> Evaluation {
    evaluationCount += 1
    
    // Pre-processing
    logEvaluation(count: evaluationCount)
    
    // Actual evaluation
    let result = requirement.evaluate(context)
    
    // Post-processing
    trackMetrics(result: result)
    
    return result
  }
  
  private func logEvaluation(count: Int) {
    print("Evaluation #\(count)")
  }
  
  private func trackMetrics(result: Evaluation) {
    Analytics.track("requirement_evaluated", properties: [
      "result": result.isConfirmed ? "confirmed" : "failed"
    ])
  }
}
```

## Decorator Pattern

### RequirementDecorator

```swift
protocol RequirementDecorator {
  associatedtype Context: Sendable
  func decorate(_ requirement: Requirement<Context>) -> Requirement<Context>
}

struct LoggingDecorator<Context: Sendable>: RequirementDecorator {
  let name: String
  
  func decorate(_ requirement: Requirement<Context>) -> Requirement<Context> {
    Requirement { context in
      print("[\(name)] Evaluating...")
      let result = requirement.evaluate(context)
      print("[\(name)] Result: \(result.isConfirmed ? "✅" : "❌")")
      return result
    }
  }
}

struct TimingDecorator<Context: Sendable>: RequirementDecorator {
  func decorate(_ requirement: Requirement<Context>) -> Requirement<Context> {
    Requirement { context in
      let start = Date()
      let result = requirement.evaluate(context)
      let duration = Date().timeIntervalSince(start)
      print("Duration: \(duration * 1000)ms")
      return result
    }
  }
}

// Использование
let decorated = TimingDecorator<Context>()
  .decorate(
    LoggingDecorator(name: "MyRequirement")
      .decorate(baseRequirement)
  )
```

## Type-safe Context Builder

### Builder с type safety

```swift
protocol ContextComponent {}

struct AuthComponent: ContextComponent {
  let isLoggedIn: Bool
  let userId: String
}

struct PermissionComponent: ContextComponent {
  let permissions: Set<Permission>
}

struct ContextBuilder {
  private var components: [any ContextComponent] = []
  
  func with(_ component: any ContextComponent) -> Self {
    var builder = self
    builder.components.append(component)
    return builder
  }
  
  func build() -> CompositeContext {
    CompositeContext(components: components)
  }
}

struct CompositeContext: Sendable {
  let components: [any ContextComponent]
  
  func get<T: ContextComponent>(_ type: T.Type) -> T? {
    components.first(where: { $0 is T }) as? T
  }
}

// Использование
let context = ContextBuilder()
  .with(AuthComponent(isLoggedIn: true, userId: "123"))
  .with(PermissionComponent(permissions: [.read, .write]))
  .build()

let requirement = Requirement<CompositeContext> { context in
  guard let auth = context.get(AuthComponent.self),
        auth.isLoggedIn else {
    return .failed(reason: Reason(message: "Not logged in"))
  }
  
  guard let perms = context.get(PermissionComponent.self),
        perms.permissions.contains(.write) else {
    return .failed(reason: Reason(message: "No write permission"))
  }
  
  return .confirmed
}
```

## Lazy Evaluation

### Ленивые требования

```swift
struct LazyRequirement<Context: Sendable>: Sendable {
  private let factory: @Sendable () -> Requirement<Context>
  
  init(_ factory: @escaping @Sendable () -> Requirement<Context>) {
    self.factory = factory
  }
  
  func evaluate(_ context: Context) -> Evaluation {
    // Требование создаётся только при проверке
    let requirement = factory()
    return requirement.evaluate(context)
  }
}

// Использование
let lazy = LazyRequirement {
  // Тяжёлое построение требования
  buildComplexRequirement()
}
```

## Policy Pattern

### Policy-based Requirements

```swift
enum SecurityPolicy {
  case low
  case medium
  case high
  case custom(Requirement<Context>)
  
  func requirement() -> Requirement<Context> {
    switch self {
    case .low:
      return #require(\.isLoggedIn)
      
    case .medium:
      return #all {
        #require(\.isLoggedIn)
        #require(\.isVerified)
      }
      
    case .high:
      return #all {
        #require(\.isLoggedIn)
        #require(\.isVerified)
        #require(\.twoFactorEnabled)
        #require(\.ipWhitelisted)
      }
      
    case .custom(let requirement):
      return requirement
    }
  }
}

// Использование
let policy: SecurityPolicy = .high
let requirement = policy.requirement()
```

## Event Sourcing

### Требования на основе событий

```swift
struct Event {
  let type: EventType
  let timestamp: Date
  let userId: String
}

enum EventType {
  case login
  case logout
  case purchase
  case refund
}

struct EventBasedContext: Sendable {
  let events: [Event]
  let user: User
}

let recentActivityRequirement = Requirement<EventBasedContext> { context in
  let recentEvents = context.events.filter {
    Date().timeIntervalSince($0.timestamp) < 3600 // последний час
  }
  
  guard !recentEvents.isEmpty else {
    return .failed(reason: Reason(message: "No recent activity"))
  }
  
  return .confirmed
}

let noRefundsRequirement = Requirement<EventBasedContext> { context in
  let hasRefunds = context.events.contains { $0.type == .refund }
  
  return !hasRefunds
    ? .confirmed
    : .failed(reason: Reason(message: "Recent refunds found"))
}
```

## DSL для сложных сценариев

### Custom DSL

```swift
@resultBuilder
struct AdvancedRequirementsBuilder<Context: Sendable> {
  static func buildBlock(_ components: Requirement<Context>...) -> [Requirement<Context>] {
    components
  }
  
  static func buildOptional(_ component: [Requirement<Context>]?) -> [Requirement<Context>] {
    component ?? []
  }
  
  static func buildEither(first component: [Requirement<Context>]) -> [Requirement<Context>] {
    component
  }
  
  static func buildEither(second component: [Requirement<Context>]) -> [Requirement<Context>] {
    component
  }
  
  static func buildArray(_ components: [[Requirement<Context>]]) -> [Requirement<Context>] {
    components.flatMap { $0 }
  }
}

func advancedRequirements<Context: Sendable>(
  @AdvancedRequirementsBuilder<Context> builder: () -> [Requirement<Context>]
) -> Requirement<Context> {
  let requirements = builder()
  return Requirement.all(requirements)
}

// Использование
let requirement = advancedRequirements {
  if featureEnabled {
    featureRequirement
  }
  
  for level in accessLevels {
    levelRequirement(level)
  }
  
  baseRequirement
}
```

## Best Practices

### 1. Изолируйте сложную логику

```swift
// ✅ Хорошо
class RequirementService {
  private let complexRequirement: Requirement<Context>
  
  init() {
    complexRequirement = buildComplexRequirement()
  }
  
  func check(_ context: Context) -> Evaluation {
    complexRequirement.evaluate(context)
  }
  
  private func buildComplexRequirement() -> Requirement<Context> {
    // Сложная логика изолирована
    // ...
  }
}
```

### 2. Используйте протоколы для гибкости

```swift
protocol RequirementProvider {
  associatedtype Context: Sendable
  func provide() -> Requirement<Context>
}

struct ProductionProvider: RequirementProvider {
  func provide() -> Requirement<UserContext> {
    strictRequirement
  }
}

struct TestProvider: RequirementProvider {
  func provide() -> Requirement<UserContext> {
    .always
  }
}
```

### 3. Тестируйте сложные паттерны

```swift
func testChainOfResponsibility() {
  let handler = buildHandlerChain()
  let context = TestContext()
  
  let result = handler.handle(context: context)
  
  XCTAssertTrue(result.isConfirmed)
}
```

## Смотрите также

- <doc:BestPractices>
- <doc:ComposingRequirements>
- ``Requirement``

