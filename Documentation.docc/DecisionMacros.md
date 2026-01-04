# Decision Macros

Красивые декларативные макросы для создания решений на основе контекста.

## Обзор

Decision макросы предоставляют элегантный DSL для создания решений, аналогичный макросам для Requirement. Они позволяют писать выразительный и читаемый код для принятия решений на основе контекста.

## Основные макросы

### #whenDecision - Условные решения

Создает решение на основе условия в контексте:

```swift
struct UserContext: Sendable {
  let isAdmin: Bool
  let isPremium: Bool
  let balance: Double
  let role: UserRole
}

enum Route: Sendable {
  case adminPanel
  case premiumDashboard
  case dashboard
  case welcome
}

// Простое Bool условие
let adminRoute: Decision<UserContext, Route> = 
  #whenDecision(\.isAdmin, return: .adminPanel)

// Сравнение с равенством
let roleRoute: Decision<UserContext, Route> = 
  #whenDecision(\.role, equals: .admin, return: .adminPanel)

// Сравнение с числами
let premiumRoute: Decision<UserContext, Route> = 
  #whenDecision(\.balance, greaterThan: 1000.0, return: .premiumDashboard)
```

Поддерживаемые операторы сравнения:
- `equals:` - равенство
- `notEquals:` - неравенство
- `greaterThan:` - больше
- `greaterThanOrEqual:` - больше или равно
- `lessThan:` - меньше
- `lessThanOrEqual:` - меньше или равно

### #unlessDecision - Инверсия условия

Возвращает значение, если условие **ложно**:

```swift
let accessRoute: Decision<UserContext, Route> = 
  #unlessDecision(\.isBanned, return: .dashboard)
```

### #firstMatch - Композиция решений

Возвращает первое совпадение из списка решений (аналог `#any` для Requirement):

```swift
let route: Decision<UserContext, Route> = #firstMatch {
  #whenDecision(\.isAdmin, return: .adminPanel)
  #whenDecision(\.isPremium, return: .premiumDashboard)
  #whenDecision(\.isLoggedIn, return: .dashboard)
  #orElse(.welcome)
}
```

### #orElse - Значение по умолчанию

Возвращает константное значение (fallback):

```swift
let defaultRoute: Decision<UserContext, Route> = 
  #orElse(.welcome)
```

## Интеграция с Requirement

### #whenMet - Решение на основе требования

Возвращает значение, если требование выполнено:

```swift
struct Order: Sendable {
  let isVIP: Bool
  let total: Double
  let itemCount: Int
}

// Простое требование
let vipDiscount: Decision<Order, Double> = 
  #whenMet(#require(\.isVIP), return: 0.2)

// Сложное требование
let bulkDiscount: Decision<Order, Double> = 
  #whenMet(
    #require(\.total, greaterThan: 1000.0), 
    return: 0.15
  )

// Композиция с несколькими требованиями
let discount: Decision<Order, Double> = #firstMatch {
  #whenMet(#require(\.isVIP), return: 0.2)
  #whenMet(#require(\.total, greaterThan: 1000.0), return: 0.15)
  #whenMet(#require(\.itemCount, greaterThanOrEqual: 10), return: 0.1)
  #orElse(0.0)
}
```

## Практические примеры

### Маршрутизация пользователей

```swift
struct AppContext: Sendable {
  let user: User
  let session: Session?
}

struct User: Sendable {
  let isAdmin: Bool
  let isPremium: Bool
  let isLoggedIn: Bool
  let isBanned: Bool
}

enum AppRoute: Sendable {
  case admin
  case premium
  case home
  case login
  case banned
}

let router: Decision<AppContext, AppRoute> = #firstMatch {
  // Сначала проверяем блокировку
  #whenDecision(\.user.isBanned, return: .banned)
  
  // Затем проверяем привилегии
  #whenDecision(\.user.isAdmin, return: .admin)
  #whenDecision(\.user.isPremium, return: .premium)
  
  // Обычные пользователи
  #whenDecision(\.user.isLoggedIn, return: .home)
  
  // По умолчанию - логин
  #orElse(.login)
}
```

### Система скидок

```swift
struct PurchaseContext: Sendable {
  let customer: Customer
  let order: Order
}

struct Customer: Sendable {
  let isVIP: Bool
  let loyaltyPoints: Int
  let membershipYears: Int
}

struct Order: Sendable {
  let total: Double
  let itemCount: Int
}

let discountCalculator: Decision<PurchaseContext, Double> = #firstMatch {
  // VIP клиенты получают максимальную скидку
  #whenMet(
    #all {
      #require(\.customer.isVIP)
      #require(\.order.total, greaterThan: 5000.0)
    },
    return: 0.25
  )
  
  // Постоянные клиенты
  #whenDecision(
    \.customer.membershipYears, 
    greaterThanOrEqual: 5, 
    return: 0.15
  )
  
  // Большие заказы
  #whenDecision(
    \.order.total, 
    greaterThan: 1000.0, 
    return: 0.10
  )
  
  // Оптовые покупки
  #whenDecision(
    \.order.itemCount, 
    greaterThanOrEqual: 10, 
    return: 0.08
  )
  
  // Минимальная скидка для всех
  #orElse(0.05)
}
```

### Выбор уровня обслуживания

```swift
struct ServiceContext: Sendable {
  let user: User
  let subscription: Subscription
  let usage: UsageStats
}

enum ServiceTier: Sendable {
  case enterprise
  case professional
  case standard
  case free
}

let serviceTier: Decision<ServiceContext, ServiceTier> = #firstMatch {
  // Enterprise для крупных клиентов
  #whenMet(
    #all {
      #require(\.subscription.isPaid)
      #require(\.usage.apiCallsPerDay, greaterThan: 10000)
      #require(\.user.teamSize, greaterThanOrEqual: 50)
    },
    return: .enterprise
  )
  
  // Professional для активных пользователей
  #whenMet(
    #all {
      #require(\.subscription.isPaid)
      #require(\.usage.apiCallsPerDay, greaterThan: 1000)
    },
    return: .professional
  )
  
  // Standard для платных подписок
  #whenDecision(\.subscription.isPaid, return: .standard)
  
  // Free tier по умолчанию
  #orElse(.free)
}
```

## Асинхронные макросы

Для асинхронных решений доступны аналогичные макросы с префиксом `async`:

```swift
// Асинхронное условное решение
let asyncRoute: AsyncDecision<UserContext, Route> = 
  #asyncWhenDecision(\.isAdmin, return: .adminPanel)

// Асинхронная композиция
let asyncDecision: AsyncDecision<UserContext, Route> = #asyncFirstMatch {
  #asyncWhenDecision(\.isAdmin, return: .adminPanel)
  #asyncWhenDecision(\.isPremium, return: .premiumDashboard)
  #asyncOrElse(.welcome)
}

// Интеграция с асинхронными требованиями
let asyncDiscount: AsyncDecision<Order, Double> = 
  #asyncWhenMet(someAsyncRequirement, return: 0.2)
```

## Сравнение с Requirement

Decision макросы следуют той же философии, что и Requirement макросы:

| Requirement | Decision | Назначение |
|-------------|----------|------------|
| `#require` | `#whenDecision` | Базовая проверка/условие |
| `#all` | `#firstMatch` | Композиция (все/первое совпадение) |
| `#any` | `#firstMatch` | Альтернативы |
| `#not` | `#unlessDecision` | Инверсия |
| - | `#whenMet` | Интеграция Requirement → Decision |
| - | `#orElse` | Значение по умолчанию |

## Преимущества

1. **Читаемость**: Декларативный синтаксис делает код самодокументируемым
2. **Безопасность типов**: Все проверки типов выполняются на этапе компиляции
3. **Композиция**: Легко комбинировать простые решения в сложные
4. **Консистентность**: Единый стиль с Requirement макросами
5. **Интеграция**: Бесшовная работа с существующими требованиями

## См. также

- <doc:GettingStarted>
- <doc:DecisionMaking>
- <doc:ComposingRequirements>
- <doc:MacroReference>

