# Decision Making

Принятие решений на основе контекста с возвратом конкретных значений.

## Обзор

`Decision` и `AsyncDecision` позволяют декларативно принимать решения на основе контекста, возвращая конкретные значения вместо булевых проверок. Это дополняет систему `Requirement`, предоставляя механизм для выбора между различными вариантами.

### Основные отличия от Requirements

| Аспект | Requirement | Decision |
|--------|-------------|----------|
| Возвращаемый тип | `Evaluation` (confirmed/failed) | `Result?` (generic Optional) |
| Основной метод | `evaluate()` | `decide()` |
| Семантика | Проверка условия | Принятие решения |
| nil результат | Невозможен | Означает "решение не принято" |

### Консистентность API

Обе системы используют одинаковые названия для общих концепций:

| Концепция | Requirement | Decision | Описание |
|-----------|-------------|----------|----------|
| **Альтернативный вариант** | `fallback()`, `orFallback(to:)` | `fallback()`, `orFallback(to:)` | ✅ Одинаково |
| **Условие "если"** | `when()` | `when()` | ✅ Одинаково |
| **Условие "если не"** | `unless()` | `unless()` | ✅ Одинаково |
| **Значение по умолчанию** | N/A | `fallbackDefault()` | Decision-специфично |
| **Логическая композиция** | `all()`, `any()`, `not()` | N/A | Requirement-специфично |
| **Агрегация значений** | N/A | `collect()`, `match()` | Decision-специфично |

## Базовое использование

### Создание решения

```swift
struct RequestContext: Sendable {
    let isAuthenticated: Bool
    let hasSession: Bool
    let userRole: String
}

enum Route: Sendable {
    case dashboard
    case login
    case welcome
    case admin
}

// Способ 1: Прямое создание
let routeDecision = Decision<RequestContext, Route> { ctx in
    if ctx.isAuthenticated {
        return ctx.userRole == "admin" ? .admin : .dashboard
    }
    if ctx.hasSession {
        return .login
    }
    return .welcome
}

// Способ 2: Использование макроса #decide
let routeDecision = #decide { ctx in
    if ctx.isAuthenticated {
        return ctx.userRole == "admin" ? .admin : .dashboard
    }
    if ctx.hasSession {
        return .login
    }
    return .welcome
}

// Принятие решения
let context = RequestContext(
    isAuthenticated: true,
    hasSession: true,
    userRole: "user"
)
let route = routeDecision.decide(context) // .dashboard
```

### Фабричные методы

```swift
// Константное решение
let welcomeDecision = Decision<RequestContext, Route>.constant(.welcome)

// Решение, которое всегда возвращает nil
let neverDecision = Decision<RequestContext, Route>.never

// Создание из замыкания
let decision = Decision<RequestContext, Route>.from { ctx in
    ctx.isAuthenticated ? .dashboard : nil
}
```

## Композиция решений

### fallback / orFallback - Альтернативные решения

```swift
let primaryDecision = Decision<RequestContext, Route> { ctx in
    ctx.isAuthenticated ? .dashboard : nil
}

let fallbackDecision = Decision<RequestContext, Route> { ctx in
    ctx.hasSession ? .login : .welcome
}

// Композиция: если primary вернет nil, используется fallback
let combinedDecision = primaryDecision.fallback(fallbackDecision)

// Альтернативный синтаксис с orFallback
let combinedDecision2 = primaryDecision.orFallback(to: fallbackDecision)

// Альтернатива с замыканием
let decision = primaryDecision.fallback { ctx in
    ctx.hasSession ? .login : .welcome
}

// С константным значением по умолчанию
let withDefault = primaryDecision.fallbackDefault(.welcome)

// Оператор ??
let withOperator = primaryDecision ?? .welcome
```

### FirstMatch - Первое совпадение

```swift
let decision = Decision<RequestContext, Route>.firstMatch {
    // Проверяется по порядку, возвращается первое не-nil значение
    Decision { ctx in
        ctx.isAuthenticated && ctx.userRole == "admin" ? .admin : nil
    }
    Decision { ctx in
        ctx.isAuthenticated ? .dashboard : nil
    }
    Decision { ctx in
        ctx.hasSession ? .login : nil
    }
    Decision.constant(.welcome) // Значение по умолчанию
}
```

## Трансформации

### map - Преобразование результата

```swift
let valueDecision = Decision<RequestContext, Int> { ctx in
    ctx.value
}

let stringDecision = valueDecision.map { value in
    "Value: \(value)"
}
```

### compactMap - Преобразование с фильтрацией

```swift
let decision = Decision<RequestContext, Int> { ctx in
    ctx.value
}

let filtered = decision.compactMap { value -> String? in
    value > 50 ? "High: \(value)" : nil
}
```

### filter - Фильтрация результата

```swift
let decision = Decision<RequestContext, Route> { ctx in
    ctx.isAuthenticated ? .dashboard : .welcome
}

let onlyDashboard = decision.filter { route in
    route == .dashboard
}
// Вернет .dashboard только если условие выполнено, иначе nil
```

## Интеграция с Requirements

Решения могут основываться на требованиях:

```swift
let authRequirement = Requirement<RequestContext> { ctx in
    ctx.isAuthenticated 
        ? .confirmed 
        : .failed(reason: Reason(message: "Not authenticated"))
}

// Вернуть значение, если требование выполнено
let decision = Decision<RequestContext, Route>.when(
    authRequirement,
    return: .dashboard
)

// С вычислением значения
let decision = Decision<RequestContext, Route>.when(authRequirement) { ctx in
    ctx.userRole == "admin" ? .admin : .dashboard
}
```

## Условная логика

### when - Условие "если"

```swift
// Простое условие
let decision = Decision<RequestContext, Route>.when(
    { ctx in ctx.isAuthenticated },
    return: .dashboard
)

// С вычислением значения
let decision = Decision<RequestContext, Route>.when(
    { ctx in ctx.isAuthenticated }
) { ctx in
    ctx.userRole == "admin" ? .admin : .dashboard
}
```

### unless - Условие "если не"

```swift
// Простое отрицательное условие - возвращает значение когда условие ложно
let decision = Decision<RequestContext, Route>.unless(
    { ctx in ctx.isAuthenticated },
    return: .login
)
// Вернет .login если НЕ аутентифицирован, иначе nil

// С вычислением значения
let decision = Decision<RequestContext, Route>.unless(
    { ctx in ctx.isAuthenticated }
) { ctx in
    ctx.hasSession ? .login : .welcome
}
```

## Асинхронные решения

### Базовое использование

```swift
let asyncDecision = AsyncDecision<RequestContext, Route> { ctx in
    // Асинхронные операции
    let user = try await userService.fetch(ctx.userId)
    
    if user.isPremium {
        return .premiumDashboard
    }
    if user.isVerified {
        return .dashboard
    }
    return .welcome
}

// Использование макроса
let asyncDecision = #asyncDecide { ctx in
    let user = try await userService.fetch(ctx.userId)
    return user.isPremium ? .premiumDashboard : .dashboard
}

// Принятие решения
let route = try await asyncDecision.decide(context)
```

### Конверсия из синхронного

```swift
let syncDecision = Decision<RequestContext, Route> { ctx in
    ctx.isAuthenticated ? .dashboard : .welcome
}

let asyncDecision = AsyncDecision<RequestContext, Route>.from(syncDecision)
```

### Таймауты

```swift
@available(macOS 13.0, iOS 16.0, *)
let slowDecision = AsyncDecision<RequestContext, Route> { ctx in
    let result = try await slowService.process(ctx)
    return result.route
}

let withTimeout = AsyncDecision<RequestContext, Route>.withTimeout(
    seconds: 5.0,
    slowDecision
)

// Вернет nil, если операция не завершится за 5 секунд
let route = try await withTimeout.decide(context)
```

### Асинхронные трансформации

```swift
let decision = AsyncDecision<RequestContext, User> { ctx in
    try await userService.fetch(ctx.userId)
}

// Асинхронный map
let routeDecision = decision.asyncMap { user in
    try await routeService.determineRoute(for: user)
}

// Асинхронный compactMap
let filtered = decision.asyncCompactMap { user in
    try await user.isEligible() ? user : nil
}

// Асинхронный filter
let activeOnly = decision.asyncFilter { user in
    try await user.isActive()
}
```

## Property Wrappers

### @Decided - Синхронный wrapper

```swift
struct ViewModel {
    let context: RequestContext
    
    @Decided(decision: routeDecision)
    var currentRoute: Route?
    
    init(context: RequestContext) {
        self.context = context
        _currentRoute = Decided(
            decision: routeDecision,
            context: context,
            defaultValue: .welcome // Опционально
        )
    }
}

let viewModel = ViewModel(context: context)
print(viewModel.currentRoute) // .dashboard

// Доступ к проекции
let newRoute = viewModel.$currentRoute.recalculate(with: newContext)
```

### @AsyncDecided - Асинхронный wrapper

```swift
@MainActor
class ViewModel: ObservableObject {
    let context: RequestContext
    
    @AsyncDecided(decision: asyncRouteDecision)
    var currentRoute: Route?
    
    init(context: RequestContext) {
        self.context = context
        _currentRoute = AsyncDecided(
            decision: asyncRouteDecision,
            context: context,
            defaultValue: .welcome
        )
    }
    
    func loadRoute() async {
        do {
            // Вычисляет и кеширует результат
            try await _currentRoute.evaluate()
            objectWillChange.send()
        } catch {
            print("Error: \(error)")
        }
    }
    
    func refreshRoute() async {
        // Очистить кеш и пересчитать
        _currentRoute.invalidate()
        try? await _currentRoute.evaluate()
        objectWillChange.send()
    }
}
```

## Примеры использования

### Роутинг в приложении

```swift
enum AppRoute: Sendable {
    case onboarding
    case login
    case dashboard
    case settings
}

struct AppContext: Sendable {
    let isFirstLaunch: Bool
    let isAuthenticated: Bool
    let hasCompletedOnboarding: Bool
}

let routeDecision = Decision<AppContext, AppRoute>.firstMatch {
    Decision { ctx in
        ctx.isFirstLaunch && !ctx.hasCompletedOnboarding 
            ? .onboarding 
            : nil
    }
    Decision { ctx in
        !ctx.isAuthenticated ? .login : nil
    }
    Decision.constant(.dashboard)
}

// Использование
let context = AppContext(
    isFirstLaunch: true,
    isAuthenticated: false,
    hasCompletedOnboarding: false
)
let route = routeDecision.decide(context) // .onboarding
```

### Выбор стратегии обработки

```swift
enum ProcessingStrategy: Sendable {
    case fast
    case balanced
    case thorough
}

struct DataContext: Sendable {
    let dataSize: Int
    let priority: String
    let availableMemory: Int
}

let strategyDecision = #decide { ctx in
    if ctx.priority == "urgent" && ctx.dataSize < 1000 {
        return .fast
    }
    if ctx.availableMemory > 10000 {
        return .thorough
    }
    return .balanced
}
```

### Определение уровня доступа

```swift
enum AccessLevel: Sendable {
    case none
    case read
    case write
    case admin
}

struct UserContext: Sendable {
    let userId: String
    let roles: [String]
    let isOwner: Bool
}

let accessDecision = Decision<UserContext, AccessLevel>.firstMatch {
    Decision { ctx in
        ctx.isOwner ? .admin : nil
    }
    Decision { ctx in
        ctx.roles.contains("admin") ? .admin : nil
    }
    Decision { ctx in
        ctx.roles.contains("editor") ? .write : nil
    }
    Decision { ctx in
        ctx.roles.contains("viewer") ? .read : nil
    }
    Decision.constant(.none)
}
```

### Асинхронный выбор провайдера

```swift
enum PaymentProvider: Sendable {
    case stripe
    case paypal
    case applePay
}

struct PaymentContext: Sendable {
    let amount: Decimal
    let currency: String
    let userCountry: String
}

let providerDecision = #asyncDecide { ctx in
    // Проверка доступности провайдеров
    let available = try await paymentService.availableProviders(
        in: ctx.userCountry
    )
    
    if available.contains(.applePay) && ctx.amount < 1000 {
        return .applePay
    }
    
    if available.contains(.stripe) {
        return .stripe
    }
    
    if available.contains(.paypal) {
        return .paypal
    }
    
    return nil // Нет доступных провайдеров
}
```

## Best Practices

### 1. Используйте типобезопасные результаты

```swift
// ✅ Хорошо: типобезопасный enum
enum Route: Sendable {
    case dashboard
    case login
}

let decision = Decision<Context, Route> { ... }

// ❌ Плохо: строки
let decision = Decision<Context, String> { ... }
```

### 2. Предоставляйте значения по умолчанию

```swift
// ✅ Хорошо: всегда есть fallback
let decision = primaryDecision
    .orElse(secondaryDecision)
    .orDefault(.welcome)

// ❌ Плохо: может вернуть nil
let decision = primaryDecision
```

### 3. Используйте FirstMatch для сложной логики

```swift
// ✅ Хорошо: читаемая цепочка проверок
let decision = Decision<Context, Route>.firstMatch {
    Decision { ctx in ctx.isAdmin ? .admin : nil }
    Decision { ctx in ctx.isAuthenticated ? .dashboard : nil }
    Decision.constant(.welcome)
}

// ❌ Плохо: вложенные if-else
let decision = Decision<Context, Route> { ctx in
    if ctx.isAdmin {
        return .admin
    } else {
        if ctx.isAuthenticated {
            return .dashboard
        } else {
            return .welcome
        }
    }
}
```

### 4. Комбинируйте с Requirements

```swift
// ✅ Хорошо: переиспользование логики
let authRequirement = Requirement<Context> { ... }

let decision = Decision<Context, Route>.when(
    authRequirement,
    return: .dashboard
).orDefault(.login)
```

### 5. Обрабатывайте ошибки в async решениях

```swift
// ✅ Хорошо: обработка ошибок
let decision = #asyncDecide { ctx in
    do {
        let data = try await service.fetch(ctx)
        return data.route
    } catch {
        logger.error("Failed to fetch route: \(error)")
        return .fallback
    }
}
```

## См. также

- <doc:GettingStarted>
- <doc:ComposingRequirements>
- <doc:AsyncRequirements>
- <doc:HandlingResults>

