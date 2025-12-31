# Обработка результатов

Узнайте, как обрабатывать результаты проверки требований.

## Обзор

``Evaluation`` — это результат проверки требования, который может быть либо подтверждён (`.confirmed`), либо отклонён (`.failed`).

## Evaluation

```swift
public enum Evaluation: Sendable {
  case confirmed
  case failed(reason: Reason)
}
```

## Проверка результата

### Switch statement

Самый явный способ обработки:

```swift
let result = requirement.evaluate(context)

switch result {
case .confirmed:
  print("✅ Требование выполнено")
  performAction()
  
case .failed(let reason):
  print("❌ Требование не выполнено")
  print("Код: \(reason.code)")
  print("Причина: \(reason.message)")
  showError(reason.message)
}
```

### Свойство isConfirmed

Быстрая проверка успешности:

```swift
let result = requirement.evaluate(context)

if result.isConfirmed {
  performAction()
} else {
  showError()
}
```

### Свойство isFailed

```swift
if result.isFailed {
  handleFailure()
}
```

### Свойство reason

Получение причины отказа:

```swift
if let reason = result.reason {
  print("Причина: \(reason.message)")
  print("Код: \(reason.code)")
}
```

## Reason — причина отказа

``Reason`` содержит информацию о том, почему требование не было выполнено:

```swift
public struct Reason: Sendable {
  public let code: String
  public let message: String
}
```

### Создание Reason

```swift
// С кодом и сообщением
let reason = Reason(
  code: "insufficient_balance",
  message: "Недостаточно средств на балансе"
)

// Только с сообщением (код генерируется автоматически)
let reason = Reason(message: "Требуется авторизация")
```

### Использование в требованиях

```swift
let requirement = Requirement<Context> { context in
  guard context.balance >= 100 else {
    return .failed(reason: Reason(
      code: "insufficient_balance",
      message: "Требуется минимум 100, доступно \(context.balance)"
    ))
  }
  
  return .confirmed
}
```

## Получение всех причин отказа

Для композитных требований можно получить все причины отказа:

```swift
let complexRequirement = #all {
  #require(\.user.isLoggedIn)
    .because("Требуется авторизация")
  
  #require(\.user.isVerified)
    .because("Требуется верификация")
  
  #require(\.balance, greaterThan: 100)
    .because("Недостаточно средств")
}

let result = complexRequirement.evaluate(context)

if case .failed = result {
  let allFailures = result.allFailures
  
  print("Найдено \(allFailures.count) ошибок:")
  for (index, failure) in allFailures.enumerated() {
    print("\(index + 1). [\(failure.code)] \(failure.message)")
  }
}
```

Вывод:

```
Найдено 3 ошибок:
1. [auth_required] Требуется авторизация
2. [verification_required] Требуется верификация
3. [insufficient_balance] Недостаточно средств
```

## Паттерны обработки

### Guard let

```swift
func performTrade() {
  let result = canTrade.evaluate(context)
  
  guard result.isConfirmed else {
    if let reason = result.reason {
      showError(reason.message)
    }
    return
  }
  
  // Выполняем операцию
  executeTrade()
}
```

### Throwing функции

Преобразуйте результат в исключение:

```swift
extension Evaluation {
  func get() throws {
    if case .failed(let reason) = self {
      throw RequirementError(reason: reason)
    }
  }
}

struct RequirementError: Error {
  let reason: Reason
  
  var localizedDescription: String {
    reason.message
  }
}

// Использование
func performTrade() throws {
  try canTrade.evaluate(context).get()
  executeTrade()
}
```

### Result type

```swift
extension Evaluation {
  func toResult() -> Result<Void, Reason> {
    switch self {
    case .confirmed:
      return .success(())
    case .failed(let reason):
      return .failure(reason)
    }
  }
}

// Использование
let result = canTrade.evaluate(context).toResult()

switch result {
case .success:
  performAction()
case .failure(let reason):
  handleError(reason)
}
```

### Optional unwrapping

```swift
extension Evaluation {
  var value: Bool? {
    if case .confirmed = self {
      return true
    }
    return nil
  }
}

// Использование
if canTrade.evaluate(context).value != nil {
  performAction()
}
```

## Обработка в UI

### SwiftUI Alert

```swift
struct TradeView: View {
  @State private var showAlert = false
  @State private var errorMessage = ""
  
  let context: TradingContext
  
  var body: some View {
    Button("Торговать") {
      handleTrade()
    }
    .alert("Ошибка", isPresented: $showAlert) {
      Button("OK") { }
    } message: {
      Text(errorMessage)
    }
  }
  
  func handleTrade() {
    let result = canTrade.evaluate(context)
    
    switch result {
    case .confirmed:
      performTrade()
    case .failed(let reason):
      errorMessage = reason.message
      showAlert = true
    }
  }
}
```

### Toast/Banner

```swift
struct ContentView: View {
  @State private var toastMessage: String?
  
  var body: some View {
    VStack {
      // Контент
      
      Button("Действие") {
        handleAction()
      }
    }
    .overlay(alignment: .top) {
      if let message = toastMessage {
        ToastView(message: message) {
          toastMessage = nil
        }
      }
    }
  }
  
  func handleAction() {
    let result = requirement.evaluate(context)
    
    if let reason = result.reason {
      toastMessage = reason.message
    } else {
      performAction()
    }
  }
}
```

### Inline Error

```swift
struct FormField: View {
  let label: String
  @Binding var value: String
  let requirement: Requirement<String>
  
  var error: String? {
    guard !value.isEmpty else { return nil }
    return requirement.evaluate(value).reason?.message
  }
  
  var body: some View {
    VStack(alignment: .leading) {
      TextField(label, text: $value)
        .textFieldStyle(.roundedBorder)
        .overlay {
          if error != nil {
            RoundedRectangle(cornerRadius: 5)
              .stroke(Color.red, lineWidth: 1)
          }
        }
      
      if let error = error {
        Text(error)
          .font(.caption)
          .foregroundColor(.red)
      }
    }
  }
}
```

## Логирование результатов

### Простое логирование

```swift
let result = requirement.evaluate(context)

if result.isConfirmed {
  logger.info("✅ Requirement confirmed")
} else if let reason = result.reason {
  logger.warning("❌ Requirement failed: [\(reason.code)] \(reason.message)")
}
```

### Структурированное логирование

```swift
func logEvaluation(_ result: Evaluation, requirementName: String) {
  let status = result.isConfirmed ? "SUCCESS" : "FAILURE"
  
  var metadata: [String: String] = [
    "requirement": requirementName,
    "status": status
  ]
  
  if let reason = result.reason {
    metadata["error_code"] = reason.code
    metadata["error_message"] = reason.message
  }
  
  logger.log(level: result.isConfirmed ? .info : .warning, metadata: metadata)
}

// Использование
let result = requirement.evaluate(context)
logEvaluation(result, requirementName: "CanTrade")
```

## Аналитика

### Отправка событий

```swift
func trackRequirement(_ result: Evaluation, name: String, context: Context) {
  let event = result.isConfirmed ? "requirement_passed" : "requirement_failed"
  
  var properties: [String: Any] = [
    "requirement_name": name,
    "user_id": context.user.id
  ]
  
  if let reason = result.reason {
    properties["failure_reason"] = reason.message
    properties["failure_code"] = reason.code
  }
  
  Analytics.track(event, properties: properties)
}

// Использование
let result = canTrade.evaluate(context)
trackRequirement(result, name: "CanTrade", context: context)
```

## Обработка асинхронных результатов

### Async/await

```swift
func checkAccess() async {
  do {
    let result = try await asyncRequirement.evaluate(context)
    
    switch result {
    case .confirmed:
      await performAction()
    case .failed(let reason):
      await showError(reason.message)
    }
  } catch {
    await showError("Произошла ошибка: \(error.localizedDescription)")
  }
}
```

### Task с результатом

```swift
struct AsyncView: View {
  @State private var result: Evaluation?
  @State private var isLoading = false
  
  var body: some View {
    VStack {
      if isLoading {
        ProgressView()
      } else if let result = result {
        if result.isConfirmed {
          Text("✅ Доступ разрешён")
        } else if let reason = result.reason {
          Text("❌ \(reason.message)")
            .foregroundColor(.red)
        }
      }
    }
    .task {
      isLoading = true
      defer { isLoading = false }
      
      do {
        result = try await asyncRequirement.evaluate(context)
      } catch {
        result = .failed(reason: Reason(message: error.localizedDescription))
      }
    }
  }
}
```

## Цепочка обработки

```swift
func handleRequirement() {
  let result = requirement.evaluate(context)
  
  switch result {
  case .confirmed:
    performAction()
    logSuccess()
    trackAnalytics("success")
    
  case .failed(let reason):
    showError(reason.message)
    logFailure(reason)
    trackAnalytics("failure", reason: reason)
    suggestAlternative(reason)
  }
}

func suggestAlternative(_ reason: Reason) {
  switch reason.code {
  case "insufficient_balance":
    showTopUpPrompt()
  case "premium_required":
    showUpgradePrompt()
  case "verification_required":
    showVerificationFlow()
  default:
    break
  }
}
```

## Best Practices

### 1. Всегда обрабатывайте оба случая

```swift
// ✅ Хорошо
switch result {
case .confirmed:
  handleSuccess()
case .failed(let reason):
  handleFailure(reason)
}

// ❌ Плохо
if result.isConfirmed {
  handleSuccess()
}
// Что если failed?
```

### 2. Предоставляйте пользователю понятную обратную связь

```swift
// ✅ Хорошо
if let reason = result.reason {
  showUserFriendlyMessage(reason.message)
  suggestNextSteps(reason.code)
}

// ❌ Плохо
if let reason = result.reason {
  print(reason.code) // Пользователь не увидит
}
```

### 3. Логируйте отказы для аналитики

```swift
if case .failed(let reason) = result {
  logger.warning("Requirement failed", metadata: [
    "code": reason.code,
    "message": reason.message,
    "context": String(describing: context)
  ])
}
```

### 4. Используйте коды ошибок для программной обработки

```swift
if let reason = result.reason {
  switch reason.code {
  case "insufficient_balance":
    showTopUpScreen()
  case "verification_required":
    showVerificationScreen()
  default:
    showGenericError(reason.message)
  }
}
```

## Смотрите также

- <doc:ComposingRequirements>
- ``Evaluation``
- ``Reason``

