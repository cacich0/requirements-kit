# Логическая композиция

Комбинируйте требования с помощью логических операторов и композиционных паттернов.

## Обзор

RequirementsKit предоставляет несколько способов логической композиции требований: макросы, логические операторы и fluent API.

## Макросы композиции

### #all — логическое AND

Все вложенные требования должны быть выполнены:

```swift
let requirement = #all {
  #require(\.user.isLoggedIn)
  #require(\.user.isVerified)
  #require(\.user.kycCompleted)
}
```

Эквивалентно:

```swift
isLoggedIn AND isVerified AND kycCompleted
```

### #any — логическое OR

Достаточно выполнения хотя бы одного требования:

```swift
let requirement = #any {
  #require(\.user.isAdmin)
  #require(\.user.isPremium)
  #require(\.user.isVIP)
}
```

Эквивалентно:

```swift
isAdmin OR isPremium OR isVIP
```

### #not — логическое NOT

Инверсия требования:

```swift
let requirement = #not(#require(\.user.isBanned))
```

Эквивалентно:

```swift
NOT isBanned
```

## Логические операторы

### && (AND оператор)

```swift
let requirement1 = Requirement<Context>.require(\.isLoggedIn)
let requirement2 = Requirement<Context>.require(\.isVerified)

let combined = requirement1 && requirement2
```

### || (OR оператор)

```swift
let adminAccess = Requirement<Context>.require(\.isAdmin)
let premiumAccess = Requirement<Context>.require(\.isPremium)

let hasSpecialAccess = adminAccess || premiumAccess
```

### ! (NOT оператор)

```swift
let banned = Requirement<Context>.require(\.isBanned)
let notBanned = !banned
```

### Комбинирование операторов

```swift
let requirement = (req1 && req2) || (req3 && req4)
```

Приоритет операторов:
1. `!` (NOT) — наивысший
2. `&&` (AND)
3. `||` (OR) — наименьший

```swift
// Эквивалентно: ((!banned) && verified) || admin
let access = !banned && verified || admin
```

Используйте скобки для явного порядка:

```swift
let access = (!banned && verified) || admin
```

## Вложенная композиция

### Многоуровневая логика

```swift
let canTrade = #all {
  // Уровень 1: Базовая авторизация
  #require(\.user.isLoggedIn)
  #require(\.user.isVerified)
  #not(#require(\.user.isBanned))
  
  // Уровень 2: Права доступа (ANY)
  #any {
    #require(\.user.isAdmin)
    
    // Уровень 3: Премиум требования (ALL)
    #all {
      #require(\.user.isPremium)
      #require(\.balance, greaterThan: 100)
      #require(\.kycLevel, greaterThanOrEqual: .basic)
    }
  }
}
```

Эквивалентно:

```
(isLoggedIn AND isVerified AND NOT isBanned) 
  AND 
(isAdmin OR (isPremium AND balance > 100 AND kycLevel >= basic))
```

## Таблицы истинности

### AND (ALL)

| A | B | A AND B |
|---|---|---------|
| T | T | **T** |
| T | F | F |
| F | T | F |
| F | F | F |

```swift
#all {
  requirementA  // T
  requirementB  // T
}
// Результат: confirmed ✅
```

### OR (ANY)

| A | B | A OR B |
|---|---|--------|
| T | T | **T** |
| T | F | **T** |
| F | T | **T** |
| F | F | F |

```swift
#any {
  requirementA  // F
  requirementB  // T
}
// Результат: confirmed ✅
```

### NOT

| A | NOT A |
|---|-------|
| T | F |
| F | **T** |

```swift
#not(requirement) // requirement = F
// Результат: confirmed ✅
```

## De Morgan's Laws

RequirementsKit следует законам Де Моргана:

### NOT (A AND B) = (NOT A) OR (NOT B)

```swift
// Эквивалентны:
let req1 = !( requirementA && requirementB )

let req2 = !requirementA || !requirementB
```

### NOT (A OR B) = (NOT A) AND (NOT B)

```swift
// Эквивалентны:
let req1 = !( requirementA || requirementB )

let req2 = !requirementA && !requirementB
```

## Short-circuit evaluation

### ALL останавливается на первом false

```swift
let requirement = #all {
  fastCheck           // false ❌ - останавливаемся здесь
  expensiveCheck      // НЕ выполняется
  veryExpensiveCheck  // НЕ выполняется
}
```

### ANY останавливается на первом true

```swift
let requirement = #any {
  fastCheck           // true ✅ - останавливаемся здесь
  expensiveCheck      // НЕ выполняется
  veryExpensiveCheck  // НЕ выполняется
}
```

## Оптимизация композиции

### Располагайте быстрые проверки первыми

```swift
// ✅ Хорошо
let requirement = #all {
  #require(\.isLoggedIn)       // O(1) - быстро
  #require(\.isPremium)        // O(1) - быстро
  expensiveDatabaseCheck       // O(n) - медленно
  complexCalculation           // O(n²) - очень медленно
}

// ❌ Плохо
let requirement = #all {
  complexCalculation           // Всегда выполняется
  expensiveDatabaseCheck       // Всегда выполняется
  #require(\.isLoggedIn)       // Может отсечь рано
}
```

### Группируйте по вероятности отказа

```swift
// ✅ Хорошо - частые отказы в начале
let requirement = #all {
  #require(\.isLoggedIn)       // ~30% отказов
  #require(\.isPremium)        // ~60% отказов
  #require(\.balance, greaterThan: 1000)  // ~80% отказов
  rarelyFailingCheck           // ~5% отказов
}
```

## Именованная композиция

```swift
let authChecks = #all {
  #require(\.isLoggedIn)
  #require(\.isVerified)
}
.named("Authentication Checks")

let permissionChecks = #all {
  #require(\.isPremium)
  #require(\.hasPermission)
}
.named("Permission Checks")

let fullAccess = authChecks && permissionChecks
```

## Динамическая композиция

### Условное добавление требований

```swift
func buildRequirement(strict: Bool) -> Requirement<Context> {
  var requirements: [Requirement<Context>] = [
    .require(\.isLoggedIn),
    .require(\.isVerified)
  ]
  
  if strict {
    requirements.append(.require(\.kycCompleted))
    requirements.append(.require(\.twoFactorEnabled))
  }
  
  return Requirement.all(requirements)
}
```

### Композиция на основе конфигурации

```swift
struct AccessConfig {
  let requireAuth: Bool
  let requirePremium: Bool
  let requireKYC: Bool
}

func createRequirement(config: AccessConfig) -> Requirement<Context> {
  var checks: [Requirement<Context>] = []
  
  if config.requireAuth {
    checks.append(authRequirement)
  }
  
  if config.requirePremium {
    checks.append(premiumRequirement)
  }
  
  if config.requireKYC {
    checks.append(kycRequirement)
  }
  
  return Requirement.all(checks)
}
```

## Паттерны композиции

### Пирамида проверок

```swift
let pyramid = #all {
  // База: всегда требуется
  #require(\.isLoggedIn)
  
  // Уровень 2: большинство пользователей
  #any {
    #require(\.isPremium)
    #require(\.isAdmin)
  }
  
  // Уровень 3: специальные случаи
  #when(\.needsSpecialAccess) {
    #require(\.hasSignedNDA)
    #require(\.securityClearance, greaterThan: 5)
  }
}
```

### Слоёная проверка

```swift
struct LayeredRequirement {
  let layer1 = #all {  // Базовая безопасность
    #require(\.isNotBot)
    #require(\.ipNotBlocked)
  }
  
  let layer2 = #all {  // Авторизация
    #require(\.isLoggedIn)
    #require(\.sessionValid)
  }
  
  let layer3 = #all {  // Права доступа
    #require(\.hasPermission)
    #require(\.withinRateLimit)
  }
  
  let complete = layer1 && layer2 && layer3
}
```

### Матрица доступа

```swift
enum AccessMatrix {
  static func requirement(role: Role, action: Action) -> Requirement<Context> {
    switch (role, action) {
    case (.owner, _):
      return .always
      
    case (.admin, .read), (.admin, .write):
      return authRequirement
      
    case (.admin, .delete):
      return authRequirement && twoFactorRequirement
      
    case (.user, .read):
      return authRequirement
      
    case (.user, .write):
      return authRequirement && premiumRequirement
      
    case (.user, .delete):
      return .never(reason: Reason(message: "Insufficient permissions"))
      
    case (.guest, .read):
      return publicContentRequirement
      
    default:
      return .never(reason: Reason(message: "Access denied"))
    }
  }
}
```

## Best Practices

### 1. Используйте понятные имена

```swift
// ✅ Хорошо
let canEditDocument = isOwner || (isCollaborator && hasEditPermission)
let canDeleteDocument = isOwner && !documentIsLocked

// ❌ Плохо
let req1 = r1 || (r2 && r3)
let req2 = r1 && !r4
```

### 2. Избегайте слишком глубокой вложенности

```swift
// ✅ Хорошо - разбито на части
let basicAuth = #all {
  #require(\.isLoggedIn)
  #require(\.isVerified)
}

let advancedAuth = #all {
  basicAuth
  #require(\.twoFactorEnabled)
  #require(\.ipWhitelisted)
}

// ❌ Плохо - слишком вложенно
let requirement = #all {
  #any {
    #all {
      #require(\.a)
      #any {
        #require(\.b)
        #all {
          // ...
        }
      }
    }
  }
}
```

### 3. Документируйте сложную логику

```swift
/// Проверяет доступ к торговле
/// 
/// Требования:
/// 1. Базовая авторизация (login + verify)
/// 2. НЕ заблокирован
/// 3. Финансовые права (админ ИЛИ (premium + balance + KYC))
let canTrade = #all {
  // 1. Базовая авторизация
  #require(\.user.isLoggedIn)
  #require(\.user.isVerified)
  
  // 2. Не заблокирован
  #not(#require(\.user.isBanned))
  
  // 3. Финансовые права
  #any {
    #require(\.user.isAdmin)
    
    #all {
      #require(\.user.isPremium)
      #require(\.balance, greaterThan: 100)
      #require(\.kycLevel, greaterThanOrEqual: .basic)
    }
  }
}
```

### 4. Переиспользуйте композиции

```swift
// Определяем один раз
enum CommonRequirements {
  static let basicAuth = #all {
    #require(\.isLoggedIn)
    #require(\.isVerified)
  }
  
  static let premiumUser = #all {
    basicAuth
    #require(\.isPremium)
    #require(\.subscriptionActive)
  }
}

// Используем многократно
let canAccessFeatureA = CommonRequirements.premiumUser
let canAccessFeatureB = CommonRequirements.premiumUser && additionalCheck
```

## Смотрите также

- <doc:ComposingRequirements>
- <doc:ConditionalRequirements>
- ``Requirement``

