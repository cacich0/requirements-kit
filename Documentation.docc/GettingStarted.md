# Начало работы

Быстрое руководство по использованию RequirementsKit для декларативного описания бизнес-требований.

## Обзор

RequirementsKit позволяет выразить сложную бизнес-логику в виде декларативных, читаемых и переиспользуемых требований. Эта статья познакомит вас с основами библиотеки.

## Установка

### Swift Package Manager

Добавьте RequirementsKit в ваш `Package.swift`:

```swift
dependencies: [
  .package(url: "https://github.com/cacich0/requirements-kit.git", from: "1.0.0")
]
```

### Xcode

1. Откройте ваш проект в Xcode
2. Выберите **File → Add Package Dependencies...**
3. Введите URL репозитория: `https://github.com/cacich0/requirements-kit.git`
4. Выберите версию и нажмите **Add Package**

## Основные концепции

### Context — контекст

Контекст содержит все данные, необходимые для принятия решения:

```swift
import RequirementsKit

struct UserContext: Sendable {
  let user: User
  let featureFlags: FeatureFlags
  let environment: Environment
}
```

> Important: Контекст должен быть `Sendable` для поддержки concurrency.

### Requirement — требование

``Requirement`` — это правило, которое можно проверить для заданного контекста:

```swift
let isLoggedIn = Requirement<UserContext>.require(\.user.isLoggedIn)
```

### Evaluation — результат

``Evaluation`` — результат проверки требования:

```swift
let result = isLoggedIn.evaluate(context)

switch result {
case .confirmed:
  print("✅ Требование выполнено")
case .failed(let reason):
  print("❌ Отказано: \(reason.message)")
}
```

## Создание первого требования

### Простое требование через KeyPath

```swift
let isLoggedIn = Requirement<UserContext>.require(\.user.isLoggedIn)

let context = UserContext(
  user: User(isLoggedIn: true),
  featureFlags: FeatureFlags.default,
  environment: .production
)

let result = isLoggedIn.evaluate(context)
// .confirmed
```

### Добавление причины отказа

```swift
let isLoggedIn = Requirement<UserContext>
  .require(\.user.isLoggedIn)
  .because("Необходима авторизация для доступа к этой функции")

let result = isLoggedIn.evaluate(context)
// .failed(reason: Reason(message: "Необходима авторизация..."))
```

### Использование макроса #require

RequirementsKit предоставляет макросы для более чистого синтаксиса:

```swift
let isLoggedIn = #require(\.user.isLoggedIn)
  .because("Требуется авторизация")
```

## Композиция требований

### ALL — все условия обязательны

```swift
let canAccessFeature = #all {
  #require(\.user.isLoggedIn)
    .because("Требуется авторизация")
  
  #require(\.user.isVerified)
    .because("Требуется верификация аккаунта")
  
  #require(\.featureFlags.featureEnabled)
    .because("Функция временно недоступна")
}
```

### ANY — достаточно одного условия

```swift
let hasSpecialAccess = #any {
  #require(\.user.isAdmin)
  #require(\.user.isPremium)
  #require(\.user.isVIP)
}
```

### Вложенная композиция

```swift
let canTrade = #all {
  // Базовые требования
  #require(\.user.isLoggedIn)
  #require(\.user.isVerified)
  
  // Финансовые требования
  #any {
    #require(\.user.isAdmin)
    
    #all {
      #require(\.user.hasPremium)
      #require(\.balance, greaterThan: 100)
    }
  }
}
```

## KeyPath операторы

RequirementsKit предоставляет операторы сравнения для KeyPath:

```swift
// Равенство
#require(\.user.role, equals: .admin)

// Не равно
#require(\.user.email, notEquals: "")

// Больше чем
#require(\.balance, greaterThan: 100)

// Больше или равно
#require(\.kycLevel, greaterThanOrEqual: .basic)

// Меньше чем
#require(\.age, lessThan: 65)

// Меньше или равно
#require(\.riskScore, lessThanOrEqual: 50)
```

## Обработка результатов

### Switch statement

```swift
let result = requirement.evaluate(context)

switch result {
case .confirmed:
  performAction()
  
case .failed(let reason):
  showError(reason.message)
  logFailure(reason.code)
}
```

### Guard statement

```swift
func performTrade() {
  let result = canTrade.evaluate(context)
  
  guard result.isConfirmed else {
    if let reason = result.reason {
      showError(reason.message)
    }
    return
  }
  
  executeTrade()
}
```

### If statement

```swift
if canTrade.evaluate(context).isConfirmed {
  showTradeButton()
} else {
  hideTradeButton()
}
```

## Использование с SwiftUI

### Property Wrapper @Eligible

Булев результат проверки:

```swift
import SwiftUI
import RequirementsKit

struct FeatureView: View {
  @Eligible(by: canUsePremiumFeature, context: userContext)
  var canUseFeature: Bool
  
  var body: some View {
    if canUseFeature {
      PremiumFeatureButton()
    } else {
      UpgradePrompt()
    }
  }
}
```

### Property Wrapper @Eligibility

Детальная информация о результате:

```swift
struct TradeView: View {
  @Eligibility(by: canTrade, context: tradingContext)
  var tradeEligibility
  
  var body: some View {
    VStack {
      Button("Торговать") {
        performTrade()
      }
      .disabled(!tradeEligibility.isAllowed)
      
      if let reason = tradeEligibility.reason {
        Text(reason.message)
          .foregroundColor(.red)
          .font(.caption)
      }
    }
  }
}
```

## Полный пример

```swift
import RequirementsKit
import SwiftUI

// 1. Определяем контекст
struct TradingContext: Sendable {
  let user: User
  let balance: Double
  let tradeAmount: Double
}

// 2. Создаём требования
let canTrade = #all {
  #require(\.user.isLoggedIn)
    .because("Требуется авторизация")
  
  #require(\.user.isVerified)
    .because("Требуется верификация аккаунта")
  
  Requirement<TradingContext> { context in
    context.balance >= context.tradeAmount
      ? .confirmed
      : .failed(reason: Reason(
          code: "insufficient_balance",
          message: "Недостаточно средств: нужно \(context.tradeAmount), доступно \(context.balance)"
        ))
  }
}

// 3. Используем в SwiftUI
struct TradingView: View {
  let context: TradingContext
  
  var body: some View {
    VStack {
      Text("Баланс: \(context.balance)")
      
      Button("Торговать") {
        performTrade()
      }
      .disabled(!canTrade.evaluate(context).isConfirmed)
    }
  }
  
  func performTrade() {
    let result = canTrade.evaluate(context)
    
    switch result {
    case .confirmed:
      // Выполняем торговую операцию
      print("✅ Торговля разрешена")
      
    case .failed(let reason):
      // Показываем ошибку пользователю
      print("❌ [\(reason.code)] \(reason.message)")
    }
  }
}
```

## Следующие шаги

Теперь, когда вы знакомы с основами, изучите более продвинутые возможности:

- <doc:ComposingRequirements> — узнайте о сложной композиции требований
- <doc:HandlingResults> — научитесь эффективно обрабатывать результаты
- <doc:SwiftUIIntegration> — глубокая интеграция со SwiftUI
- <doc:AsyncRequirements> — работайте с асинхронными требованиями
- <doc:DebuggingAndTracing> — отладка и трассировка требований

## Смотрите также

- ``Requirement``
- ``Evaluation``
- ``Reason``
- ``Eligible``
- ``Eligibility``

