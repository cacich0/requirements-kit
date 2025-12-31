# Композиция требований

Узнайте, как комбинировать простые требования в сложные бизнес-правила.

## Обзор

RequirementsKit предоставляет мощные инструменты для композиции требований. Вы можете комбинировать простые правила в сложные бизнес-логики используя логические операторы, макросы и fluent API.

## Базовые операторы композиции

### ALL — все условия обязательны

Используйте `#all` когда все вложенные требования должны быть выполнены:

```swift
let hasFullAccess = #all {
  #require(\.user.isLoggedIn)
  #require(\.user.isVerified)
  #require(\.user.kycCompleted)
}
```

Альтернативный синтаксис через статический метод:

```swift
let hasFullAccess = Requirement<UserContext>.all {
  #require(\.user.isLoggedIn)
  #require(\.user.isVerified)
  #require(\.user.kycCompleted)
}
```

### ANY — достаточно одного условия

Используйте `#any` когда достаточно выполнения хотя бы одного требования:

```swift
let hasPremiumAccess = #any {
  #require(\.user.isAdmin)
  #require(\.user.isPremium)
  #require(\.user.isEnterprise)
}
```

### NOT — инверсия требования

Используйте `#not` для инверсии условия:

```swift
let notBanned = #not(#require(\.user.isBanned))
```

Или через оператор `!`:

```swift
let notBanned = !Requirement<UserContext>.require(\.user.isBanned)
```

## Вложенная композиция

Комбинируйте операторы для создания сложных правил:

```swift
let canTrade = #all {
  // Базовые требования
  #require(\.user.isLoggedIn)
  #require(\.user.isVerified)
  #not(#require(\.user.isBanned))
  
  // Финансовые требования
  #any {
    // Либо админ
    #require(\.user.isAdmin)
    
    // Либо премиум с балансом
    #all {
      #require(\.user.isPremium)
      #require(\.balance, greaterThan: 100)
      #require(\.kycLevel, greaterThanOrEqual: .basic)
    }
  }
}
```

## Логические операторы

RequirementsKit поддерживает стандартные логические операторы:

### AND оператор (&&)

```swift
let requirement1 = Requirement<UserContext>.require(\.user.isLoggedIn)
let requirement2 = Requirement<UserContext>.require(\.user.isVerified)

let both = requirement1 && requirement2
```

### OR оператор (||)

```swift
let adminOrPremium = 
  Requirement<UserContext>.require(\.user.isAdmin) ||
  Requirement<UserContext>.require(\.user.isPremium)
```

### NOT оператор (!)

```swift
let notBanned = !Requirement<UserContext>.require(\.user.isBanned)
```

### Комбинации

```swift
let complexRule = (requirement1 && requirement2) || requirement3
```

## Fluent API

Используйте цепочку методов для построения требований:

```swift
let requirement = Requirement<UserContext>
  .require(\.user.isLoggedIn)
  .and(\.user.isVerified)
  .and(\.user.isPremium)
  .because("Требуется авторизованный верифицированный Premium пользователь")
```

### Метод .and()

Добавляет дополнительное требование через AND:

```swift
let req = Requirement<Context>
  .require(\.isActive)
  .and(\.isVerified)
  .and { context in
    context.balance > 100
  }
```

### Метод .or()

Добавляет альтернативное требование через OR:

```swift
let req = Requirement<Context>
  .require(\.isAdmin)
  .or(\.isPremium)
```

## Именованные требования

Присваивайте имена требованиям для логирования и отладки:

```swift
let premiumAccess = Requirement.named("Premium Access") {
  #require(\.user.isPremium)
  #require(\.subscription.isActive)
}
```

С методом `.logged()`:

```swift
let requirement = Requirement<UserContext>
  .require(\.user.isLoggedIn)
  .logged("Login Check")
  .and(\.user.isPremium)
  .logged("Premium Check")
```

## Переиспользование требований

Создавайте переиспользуемые компоненты:

```swift
enum Requirements {
  static let isAuthenticated = #all {
    #require(\.user.isLoggedIn)
    #require(\.user.isVerified)
  }
  
  static let hasFinancialAccess = #all {
    isAuthenticated
    #require(\.user.kycCompleted)
    #require(\.balance, greaterThan: 0)
  }
  
  static let canTrade = #all {
    hasFinancialAccess
    #require(\.features.tradingEnabled)
  }
}
```

## Динамическое построение

Создавайте требования на основе параметров:

```swift
func balanceRequirement(minimum: Double) -> Requirement<UserContext> {
  Requirement { context in
    context.balance >= minimum
      ? .confirmed
      : .failed(reason: Reason(
          code: "insufficient_balance",
          message: "Требуется минимум \(minimum)"
        ))
  }
}

let canBuyPremium = #all {
  #require(\.user.isLoggedIn)
  balanceRequirement(minimum: 100)
}
```

## Best Practices

### 1. Группируйте связанные требования

```swift
// ✅ Хорошо
let authRequirements = #all {
  #require(\.isLoggedIn)
  #require(\.isVerified)
}

let financialRequirements = #all {
  #require(\.balance, greaterThan: 100)
  #require(\.kycCompleted)
}

let canTrade = authRequirements && financialRequirements
```

```swift
// ❌ Плохо
let canTrade = #all {
  #require(\.isLoggedIn)
  #require(\.isVerified)
  #require(\.balance, greaterThan: 100)
  #require(\.kycCompleted)
}
```

### 2. Используйте явные имена

```swift
// ✅ Хорошо
let canAccessAdminPanel = #all { /* ... */ }
let hasValidSubscription = #all { /* ... */ }

// ❌ Плохо
let check1 = #all { /* ... */ }
let requirement = #all { /* ... */ }
```

### 3. Добавляйте понятные причины отказа

```swift
// ✅ Хорошо
#require(\.balance, greaterThan: 100)
  .because("Минимальный баланс для операции: 100")

// ❌ Плохо
#require(\.balance, greaterThan: 100)
```

## Смотрите также

- <doc:ConditionalRequirements>
- <doc:FallbackPatterns>
- <doc:LogicalComposition>
- ``Requirement``

