# Условные требования

Создавайте требования, которые проверяются только при определённых условиях.

## Обзор

Условные требования позволяют применять проверки только когда выполнено определённое условие. RequirementsKit предоставляет несколько операторов для условной логики.

## WHEN — условная проверка

Требование проверяется только если условие истинно:

```swift
// Если пользователь - бета-тестер, требуется активная подписка
let betaRequirement = Requirement<User>.when(\.isBetaTester) {
  #require(\.hasActiveSubscription)
    .because("Бета-тестерам требуется активная подписка")
}
```

### Работа WHEN

- Условие **истинно** → проверяются вложенные требования
- Условие **ложно** → требование автоматически подтверждено (`.confirmed`)

```swift
let user1 = User(isBetaTester: true, hasActiveSubscription: true)
betaRequirement.evaluate(user1) // .confirmed

let user2 = User(isBetaTester: true, hasActiveSubscription: false)
betaRequirement.evaluate(user2) // .failed

let user3 = User(isBetaTester: false, hasActiveSubscription: false)
betaRequirement.evaluate(user3) // .confirmed (не бета-тестер, проверка пропускается)
```

### Вложенные проверки в WHEN

```swift
let premiumFeatureAccess = Requirement<UserContext>.when(\.features.premiumEnabled) {
  #require(\.user.isPremium)
    .because("Требуется Premium подписка")
  
  #require(\.user.subscriptionActive)
    .because("Подписка неактивна")
  
  #require(\.user.paymentMethodValid)
    .because("Требуется действительный способ оплаты")
}
```

## UNLESS — инверсия условия

Требование проверяется только если условие **ложно**:

```swift
// Если НЕ админ, требуется верификация и KYC
let nonAdminRequirements = Requirement<User>.unless(\.isAdmin) {
  #require(\.isVerified)
    .because("Требуется верификация аккаунта")
  
  #require(\.kycCompleted)
    .because("Требуется прохождение KYC")
}
```

### Работа UNLESS

- Условие **ложно** → проверяются вложенные требования
- Условие **истинно** → требование автоматически подтверждено (`.confirmed`)

```swift
let admin = User(isAdmin: true, isVerified: false, kycCompleted: false)
nonAdminRequirements.evaluate(admin) // .confirmed (админ, проверки пропускаются)

let user = User(isAdmin: false, isVerified: true, kycCompleted: true)
nonAdminRequirements.evaluate(user) // .confirmed

let unverifiedUser = User(isAdmin: false, isVerified: false, kycCompleted: false)
nonAdminRequirements.evaluate(unverifiedUser) // .failed
```

## XOR — ровно одно условие

Требование выполнено если **ровно одно** из вложенных требований подтверждено:

```swift
// Пользователь должен иметь ЛИБО trial, ЛИБО premium (не оба и не ни один)
let exclusiveSubscription = Requirement<User>.xor {
  Requirement<User> { 
    $0.subscriptionType == .trial 
      ? .confirmed 
      : .failed(reason: Reason(message: "Not trial")) 
  }
  
  Requirement<User> { 
    $0.subscriptionType == .premium 
      ? .confirmed 
      : .failed(reason: Reason(message: "Not premium")) 
  }
}
```

### Работа XOR

- **0 требований** выполнено → `.failed(reason: "No requirements were met")`
- **1 требование** выполнено → `.confirmed`
- **2+ требований** выполнено → `.failed(reason: "Multiple requirements were met")`

```swift
let trialUser = User(subscriptionType: .trial)
exclusiveSubscription.evaluate(trialUser) // .confirmed ✅

let premiumUser = User(subscriptionType: .premium)
exclusiveSubscription.evaluate(premiumUser) // .confirmed ✅

let freeUser = User(subscriptionType: .free)
exclusiveSubscription.evaluate(freeUser) // .failed ❌ (ни trial, ни premium)

// Если бы пользователь имел и trial, и premium одновременно
// exclusiveSubscription.evaluate(bothUser) // .failed ❌ (оба условия)
```

## Комбинирование условий

### WHEN с вложенным ANY

```swift
let marketingEmailsAccess = Requirement<User>.when(\.emailNotificationsEnabled) {
  #any {
    #require(\.isSubscribedToNewsletter)
    #require(\.isVIP)
    #require(\.hasOptedIntoMarketing)
  }
}
```

### UNLESS с вложенным ALL

```swift
let strictVerification = Requirement<User>.unless(\.isTrustedPartner) {
  #all {
    #require(\.emailVerified)
    #require(\.phoneVerified)
    #require(\.documentVerified)
    #require(\.addressVerified)
  }
}
```

### Вложенные WHEN/UNLESS

```swift
let complexAccess = Requirement<Context>.when(\.features.experimentalEnabled) {
  Requirement.unless(\.user.isInternal) {
    #require(\.user.hasSignedNDA)
      .because("Требуется подписанное NDA для внешних пользователей")
    
    #require(\.user.securityClearance, greaterThanOrEqual: 3)
      .because("Требуется уровень допуска 3+")
  }
}
```

## Практические примеры

### Региональные ограничения

```swift
struct TradingContext {
  let user: User
  let region: Region
  let asset: Asset
}

let regionalRestrictions = Requirement<TradingContext>.when(\.asset.isRegulated) {
  Requirement.unless(\.region.allowsAllAssets) {
    Requirement<TradingContext> { context in
      context.region.allowedAssets.contains(context.asset.id)
        ? .confirmed
        : .failed(reason: Reason(
            code: "asset_restricted",
            message: "Этот актив недоступен в вашем регионе"
          ))
    }
  }
}
```

### Возрастные ограничения

```swift
let ageRestrictedContent = Requirement<ContentContext>.when(\.content.hasAgeRestriction) {
  Requirement<ContentContext> { context in
    context.user.age >= context.content.minimumAge
      ? .confirmed
      : .failed(reason: Reason(
          code: "age_restricted",
          message: "Контент доступен только для \(context.content.minimumAge)+"
        ))
  }
}
```

### Временные ограничения

```swift
let businessHoursRestriction = Requirement<Context>.when(\.settings.enforceBusinessHours) {
  Requirement<Context> { context in
    let hour = Calendar.current.component(.hour, from: Date())
    return (9...17).contains(hour)
      ? .confirmed
      : .failed(reason: Reason(
          code: "outside_business_hours",
          message: "Операция доступна только в рабочие часы (9:00-17:00)"
        ))
  }
}
```

### Feature Flags

```swift
struct FeatureFlagsContext {
  let features: FeatureFlags
  let user: User
}

let featureGate = Requirement<FeatureFlagsContext>.when(\.features.newUIEnabled) {
  #any {
    // Если включена новая фича, доступ либо для админов
    #require(\.user.isAdmin)
    
    // Либо для бета-тестеров
    #require(\.user.isBetaTester)
    
    // Либо для процента пользователей (A/B test)
    Requirement<FeatureFlagsContext> { context in
      let userIdHash = context.user.id.hashValue
      return (userIdHash % 100) < context.features.rolloutPercentage
        ? .confirmed
        : .failed(reason: Reason(message: "Not in rollout"))
    }
  }
}
```

## Warn — мягкое предупреждение

Мягкое требование, которое не блокирует действие, но может логироваться:

```swift
let performanceWarning = Requirement<Context>.warn(\.metrics.isHighLoad)

// Всегда возвращает .confirmed, но может залогировать предупреждение
let result = performanceWarning.evaluate(context) // .confirmed
```

Используйте с middleware для логирования:

```swift
let warnRequirement = Requirement<Context>
  .warn(\.isDeprecatedAPI)
  .with(middleware: LoggingMiddleware(level: .warning))
```

## Best Practices

### 1. Используйте WHEN для опциональной логики

```swift
// ✅ Хорошо - условная проверка
let requirement = Requirement<Context>.when(\.features.strictMode) {
  strictValidation
}

// ❌ Плохо - императивная логика
let requirement = Requirement<Context> { context in
  if context.features.strictMode {
    return strictValidation.evaluate(context)
  }
  return .confirmed
}
```

### 2. Используйте UNLESS для "всех кроме"

```swift
// ✅ Хорошо - читаемо
let requirement = Requirement<User>.unless(\.isAdmin) {
  verificationRequired
}

// ❌ Хуже - двойное отрицание
let requirement = Requirement<User>.when(\.isAdmin.not) {
  verificationRequired
}
```

### 3. XOR для взаимоисключающих состояний

```swift
// ✅ Хорошо - явно выражена логика "или/или"
let paymentMethod = Requirement.xor {
  creditCardValid
  paypalConnected
  cryptoWalletLinked
}

// ❌ Плохо - сложнее читать
let paymentMethod = Requirement { context in
  let methods = [
    creditCardValid.evaluate(context).isConfirmed,
    paypalConnected.evaluate(context).isConfirmed,
    cryptoWalletLinked.evaluate(context).isConfirmed
  ]
  let count = methods.filter { $0 }.count
  return count == 1 ? .confirmed : .failed(...)
}
```

### 4. Именуйте сложные условия

```swift
// ✅ Хорошо - понятные имена
let isHighRiskTransaction = Requirement<Transaction>.when(\.amount, greaterThan: 10000)
let requiresAdditionalVerification = Requirement<User>.unless(\.isVerifiedMerchant)

let requirement = isHighRiskTransaction && requiresAdditionalVerification

// ❌ Плохо - сложно читать
let requirement = Requirement<Context>.when(\.transaction.amount, greaterThan: 10000) {
  Requirement.unless(\.user.isVerifiedMerchant) {
    // ...
  }
}
```

## Смотрите также

- <doc:ComposingRequirements>
- <doc:FallbackPatterns>
- <doc:LogicalComposition>

