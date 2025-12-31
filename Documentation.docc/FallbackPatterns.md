# Fallback паттерны

Создавайте запасные варианты для требований с помощью fallback логики.

## Обзор

Fallback паттерны позволяют определить альтернативные требования, которые проверяются если основное требование не выполнено.

## Метод .fallback()

Базовый fallback:

```swift
let accessRequirement = Requirement<UserContext>
  .require(\.user.isAdmin)
  .fallback {
    #require(\.user.isPremium)
    #require(\.user.isVerified)
  }
```

### Логика работы

1. Проверяется основное требование (`isAdmin`)
2. Если выполнено → возвращается `.confirmed`
3. Если не выполнено → проверяются fallback требования
4. Если все fallback выполнены → `.confirmed`
5. Если хотя бы один fallback не выполнен → `.failed`

```swift
// Админ - сразу доступ
let admin = UserContext(user: User(isAdmin: true, isPremium: false, isVerified: false))
accessRequirement.evaluate(admin) // .confirmed

// Не админ, но premium и верифицирован - доступ через fallback
let premiumUser = UserContext(user: User(isAdmin: false, isPremium: true, isVerified: true))
accessRequirement.evaluate(premiumUser) // .confirmed

// Не админ, premium но не верифицирован - отказ
let unverified = UserContext(user: User(isAdmin: false, isPremium: true, isVerified: false))
accessRequirement.evaluate(unverified) // .failed
```

## Метод .orFallback()

Простой fallback из одного требования:

```swift
let paymentMethod = creditCardRequirement
  .orFallback(to: paypalRequirement)
  .orFallback(to: cryptoRequirement)
```

## Множественные fallback уровни

```swift
let accessLevel = Requirement<UserContext>
  .require(\.user.isOwner)
  .fallback {
    #require(\.user.isAdmin)
  }
  .orFallback(to: Requirement<UserContext>.all {
    #require(\.user.isModerator)
    #require(\.user.hasBeenMemberForYears, greaterThan: 1)
  })
  .orFallback(to: Requirement<UserContext>.all {
    #require(\.user.isPremium)
    #require(\.user.isVerified)
    #require(\.user.kycCompleted)
  })
```

Проверка идёт сверху вниз:
1. Owner? → доступ
2. Admin? → доступ
3. Moderator + 1+ год? → доступ
4. Premium + верификация + KYC? → доступ
5. Иначе → отказ

## Практические примеры

### Платёжные методы

```swift
enum PaymentRequirements {
  static let creditCard = Requirement<PaymentContext> { context in
    context.creditCard != nil && context.creditCard!.isValid
      ? .confirmed
      : .failed(reason: Reason(message: "No valid credit card"))
  }
  
  static let paypal = Requirement<PaymentContext> { context in
    context.paypalAccount != nil && context.paypalAccount!.isConnected
      ? .confirmed
      : .failed(reason: Reason(message: "PayPal not connected"))
  }
  
  static let balance = Requirement<PaymentContext> { context in
    context.accountBalance >= context.amount
      ? .confirmed
      : .failed(reason: Reason(message: "Insufficient balance"))
  }
  
  static let anyValid = creditCard
    .orFallback(to: paypal)
    .orFallback(to: balance)
    .because("No valid payment method available")
}
```

### Аутентификация

```swift
let authenticationMethod = Requirement<AuthContext>
  .require(\.biometricAvailable)
  .fallback {
    #require(\.hasSavedPassword)
  }
  .orFallback(to: Requirement<AuthContext>.require(\.canUseOTP))
  .because("No authentication method available")
```

Порядок приоритета:
1. Биометрия (Face ID / Touch ID)
2. Сохранённый пароль
3. OTP (одноразовый пароль)

### Доставка уведомлений

```swift
let notificationDelivery = Requirement<NotificationContext>
  .require(\.pushEnabled)
  .fallback {
    #require(\.emailVerified)
  }
  .orFallback(to: Requirement<NotificationContext>.require(\.smsEnabled))
  .orFallback(to: Requirement<NotificationContext>.require(\.canUseInApp))
  .because("No notification channel available")
```

### Региональный доступ

```swift
let regionalAccess = Requirement<AccessContext>
  .require(\.isInHomeRegion)
  .fallback {
    #require(\.hasInternationalPlan)
    #require(\.isInAllowedRegion)
  }
  .orFallback(to: Requirement<AccessContext>.all {
    #require(\.hasVPNEnabled)
    #require(\.vpnRegionIsAllowed)
  })
```

### Хранилище файлов

```swift
struct StorageContext {
  let localSpaceAvailable: Int64
  let cloudConnected: Bool
  let cloudSpaceAvailable: Int64
  let fileSize: Int64
}

let canStore = Requirement<StorageContext> { context in
  context.localSpaceAvailable >= context.fileSize
    ? .confirmed
    : .failed(reason: Reason(message: "Not enough local space"))
}
.fallback {
  Requirement<StorageContext> { context in
    guard context.cloudConnected else {
      return .failed(reason: Reason(message: "Cloud not connected"))
    }
    
    return context.cloudSpaceAvailable >= context.fileSize
      ? .confirmed
      : .failed(reason: Reason(message: "Not enough cloud space"))
  }
}
.because("Cannot store file: insufficient space")
```

## Fallback с причинами

Сохраняйте информацию о том, почему основное требование не сработало:

```swift
extension Requirement {
  func fallbackWithContext(
    @RequirementsBuilder<Context> _ builder: () -> [Requirement<Context>]
  ) -> Requirement<Context> {
    let primary = self
    let fallbacks = builder()
    
    return Requirement { context in
      let primaryResult = primary.evaluate(context)
      
      if case .confirmed = primaryResult {
        return .confirmed
      }
      
      // Запоминаем причину отказа основного требования
      let primaryReason = primaryResult.reason
      
      // Проверяем fallback
      for fallback in fallbacks {
        let result = fallback.evaluate(context)
        if case .failed = result {
          return result
        }
      }
      
      // Fallback сработал, но логируем что основное не прошло
      #if DEBUG
      if let reason = primaryReason {
        print("ℹ️ Primary requirement failed (\(reason.message)), using fallback")
      }
      #endif
      
      return .confirmed
    }
  }
}
```

## Условный fallback

Fallback только при определённых условиях:

```swift
extension Requirement {
  func conditionalFallback(
    when condition: @escaping (Context) -> Bool,
    to fallback: Requirement<Context>
  ) -> Requirement<Context> {
    let primary = self
    
    return Requirement { context in
      let primaryResult = primary.evaluate(context)
      
      if case .confirmed = primaryResult {
        return .confirmed
      }
      
      // Используем fallback только если условие выполнено
      if condition(context) {
        return fallback.evaluate(context)
      }
      
      return primaryResult
    }
  }
}

// Использование
let requirement = creditCardPayment
  .conditionalFallback(
    when: { $0.allowAlternativePayments },
    to: paypalPayment
  )
```

## Fallback цепочка с приоритетами

```swift
struct PrioritizedRequirement<Context: Sendable> {
  let priority: Int
  let requirement: Requirement<Context>
  let name: String
}

func evaluateWithPriority(
  _ requirements: [PrioritizedRequirement<Context>],
  context: Context
) -> Evaluation {
  // Сортируем по приоритету
  let sorted = requirements.sorted { $0.priority > $1.priority }
  
  for prioritized in sorted {
    let result = prioritized.requirement.evaluate(context)
    
    if case .confirmed = result {
      #if DEBUG
      print("✅ Used: \(prioritized.name) (priority: \(prioritized.priority))")
      #endif
      return .confirmed
    }
  }
  
  return .failed(reason: Reason(
    code: "all_fallbacks_failed",
    message: "No requirements met"
  ))
}

// Использование
let requirements = [
  PrioritizedRequirement(priority: 10, requirement: ownerAccess, name: "Owner"),
  PrioritizedRequirement(priority: 8, requirement: adminAccess, name: "Admin"),
  PrioritizedRequirement(priority: 5, requirement: moderatorAccess, name: "Moderator"),
  PrioritizedRequirement(priority: 1, requirement: regularAccess, name: "Regular")
]

let result = evaluateWithPriority(requirements, context: context)
```

## Best Practices

### 1. Упорядочивайте от более строгих к менее строгим

```swift
// ✅ Хорошо - от самого строгого к менее строгому
let access = requireOwner
  .orFallback(to: requireAdmin)
  .orFallback(to: requireModerator)
  .orFallback(to: requireBasicUser)

// ❌ Плохо - неправильный порядок
let access = requireBasicUser
  .orFallback(to: requireOwner) // Никогда не дойдёт до этого
```

### 2. Добавляйте понятные причины

```swift
// ✅ Хорошо
let payment = creditCard
  .orFallback(to: paypal)
  .because("Требуется действительный способ оплаты")

// ❌ Плохо
let payment = creditCard.orFallback(to: paypal)
```

### 3. Используйте fallback для graceful degradation

```swift
// Если основная фича недоступна, предложим базовую
let featureAccess = newFeatureRequirement
  .orFallback(to: legacyFeatureRequirement)
  .because("Feature temporarily unavailable")
```

### 4. Логируйте использование fallback

```swift
let requirementWithLogging = primaryRequirement
  .fallback {
    fallbackRequirement
      .logged("Using fallback")
  }
```

### 5. Не делайте слишком длинные цепочки

```swift
// ✅ Хорошо - 2-3 уровня
let payment = primary.orFallback(to: secondary).orFallback(to: tertiary)

// ❌ Плохо - слишком много уровней (сложно поддерживать)
let payment = r1.orFallback(to: r2).orFallback(to: r3)
  .orFallback(to: r4).orFallback(to: r5).orFallback(to: r6)
```

## Смотрите также

- <doc:ComposingRequirements>
- <doc:ConditionalRequirements>
- ``Requirement``

