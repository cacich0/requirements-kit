# Combine интеграция

Используйте RequirementsKit с Combine framework для реактивных приложений.

## Обзор

RequirementsKit предоставляет полную интеграцию с Combine, позволяя создавать реактивные требования, которые автоматически обновляются при изменении контекста.

> Important: Combine интеграция доступна на iOS 13.0+, macOS 10.15+, tvOS 13.0+, watchOS 6.0+

## Publisher из Requirement

### Базовое использование

Создайте Publisher, который испускает ``Evaluation`` при изменении контекста:

```swift
import Combine
import RequirementsKit

let contextPublisher = PassthroughSubject<UserContext, Never>()

let evaluationPublisher = requirement.publisher(context: contextPublisher)

let cancellable = evaluationPublisher
  .sink { evaluation in
    print("Результат: \(evaluation.isConfirmed)")
  }

// Испускаем новый контекст
contextPublisher.send(newContext)
```

### Boolean Publisher

Получите Publisher с булевым результатом:

```swift
let isAllowedPublisher = requirement.isAllowedPublisher(context: contextPublisher)

let cancellable = isAllowedPublisher
  .sink { isAllowed in
    if isAllowed {
      enableButton()
    } else {
      disableButton()
    }
  }
```

### Reason Publisher

Получите Publisher с причинами отказа:

```swift
let reasonPublisher = requirement.reasonPublisher(context: contextPublisher)

let cancellable = reasonPublisher
  .sink { reason in
    if let reason = reason {
      showError(reason.message)
    } else {
      hideError()
    }
  }
```

## ReactiveRequirement

``ReactiveRequirement`` — это ObservableObject, который автоматически обновляется:

```swift
import Combine
import RequirementsKit

class FeatureViewModel: ObservableObject {
  let reactive: ReactiveRequirement<UserContext>
  let contextPublisher = PassthroughSubject<UserContext, Never>()
  
  init() {
    reactive = ReactiveRequirement(
      requirement: canUsePremiumFeature,
      initialContext: UserContext(user: currentUser)
    )
    
    reactive.subscribe(to: contextPublisher)
  }
  
  func updateContext(_ context: UserContext) {
    contextPublisher.send(context)
  }
}

// В SwiftUI View
struct FeatureView: View {
  @StateObject var viewModel = FeatureViewModel()
  
  var body: some View {
    Button("Premium Feature") {
      performAction()
    }
    .disabled(!viewModel.reactive.isAllowed)
  }
}
```

### Свойства ReactiveRequirement

```swift
@Published public private(set) var evaluation: Evaluation
@Published public private(set) var isAllowed: Bool
@Published public private(set) var reason: Reason?
```

## @RequirementPublisher Property Wrapper

Удобный property wrapper для Combine-based требований:

```swift
class ViewModel {
  @RequirementPublisher(by: canTrade, initialContext: initialContext)
  var tradePublisher
  
  init() {
    tradePublisher
      .sink { evaluation in
        print("Can trade: \(evaluation.isConfirmed)")
      }
      .store(in: &cancellables)
  }
  
  func updateContext(_ newContext: TradingContext) {
    $tradePublisher.send(newContext)
  }
  
  private var cancellables = Set<AnyCancellable>()
}
```

## Комбинирование Publishers

### Множественные требования

```swift
let requirement1Publisher = requirement1.isAllowedPublisher(context: context1)
let requirement2Publisher = requirement2.isAllowedPublisher(context: context2)

// Оба должны быть true
let bothAllowed = Publishers.CombineLatest(requirement1Publisher, requirement2Publisher)
  .map { $0 && $1 }
  .eraseToAnyPublisher()

bothAllowed
  .sink { isAllowed in
    updateUI(enabled: isAllowed)
  }
  .store(in: &cancellables)
```

### Merge нескольких Requirements

```swift
let publisher1 = req1.isAllowedPublisher(context: context1)
let publisher2 = req2.isAllowedPublisher(context: context2)
let publisher3 = req3.isAllowedPublisher(context: context3)

// Обновляется при изменении любого
Publishers.Merge3(publisher1, publisher2, publisher3)
  .sink { _ in
    refreshUI()
  }
  .store(in: &cancellables)
```

## Операторы Combine

### Debounce для частых изменений

```swift
let debouncedPublisher = requirement
  .isAllowedPublisher(context: contextPublisher)
  .debounce(for: .milliseconds(300), scheduler: DispatchQueue.main)
  .removeDuplicates()

debouncedPublisher
  .sink { isAllowed in
    // Вызывается не чаще раз в 300ms
    updateUI(enabled: isAllowed)
  }
  .store(in: &cancellables)
```

### Filter для специфичных событий

```swift
requirement
  .publisher(context: contextPublisher)
  .filter { $0.isFailed }
  .compactMap { $0.reason }
  .sink { reason in
    logFailure(reason)
  }
  .store(in: &cancellables)
```

### Map для трансформации

```swift
requirement
  .publisher(context: contextPublisher)
  .map { evaluation -> String in
    evaluation.isConfirmed ? "✅ Allowed" : "❌ Denied"
  }
  .assign(to: \.statusText, on: viewModel)
  .store(in: &cancellables)
```

## Практические примеры

### Real-time доступ к функциям

```swift
class FeatureAccessManager: ObservableObject {
  @Published var canEditDocuments = false
  @Published var canDeleteDocuments = false
  @Published var canShareDocuments = false
  
  private let contextPublisher = CurrentValueSubject<UserContext, Never>(UserContext.initial)
  private var cancellables = Set<AnyCancellable>()
  
  init() {
    setupRequirements()
  }
  
  func updateUser(_ user: User) {
    contextPublisher.send(UserContext(user: user))
  }
  
  private func setupRequirements() {
    editRequirement
      .isAllowedPublisher(context: contextPublisher.eraseToAnyPublisher())
      .assign(to: &$canEditDocuments)
    
    deleteRequirement
      .isAllowedPublisher(context: contextPublisher.eraseToAnyPublisher())
      .assign(to: &$canDeleteDocuments)
    
    shareRequirement
      .isAllowedPublisher(context: contextPublisher.eraseToAnyPublisher())
      .assign(to: &$canShareDocuments)
  }
}
```

### Form валидация

```swift
class RegistrationViewModel: ObservableObject {
  @Published var email = ""
  @Published var password = ""
  @Published var age = ""
  
  @Published var isFormValid = false
  @Published var errors: [String] = []
  
  private var cancellables = Set<AnyCancellable>()
  
  init() {
    setupValidation()
  }
  
  private func setupValidation() {
    let emailPublisher = $email
      .map { email in
        emailRequirement.evaluate(email)
      }
    
    let passwordPublisher = $password
      .map { password in
        passwordRequirement.evaluate(password)
      }
    
    let agePublisher = $age
      .map { age in
        Int(age).map { ageRequirement.evaluate($0) } ?? .failed(reason: Reason(message: "Invalid age"))
      }
    
    // Комбинируем все валидации
    Publishers.CombineLatest3(emailPublisher, passwordPublisher, agePublisher)
      .map { emailResult, passwordResult, ageResult in
        emailResult.isConfirmed && passwordResult.isConfirmed && ageResult.isConfirmed
      }
      .assign(to: &$isFormValid)
    
    // Собираем ошибки
    Publishers.CombineLatest3(emailPublisher, passwordPublisher, agePublisher)
      .map { emailResult, passwordResult, ageResult in
        [emailResult, passwordResult, ageResult]
          .compactMap { $0.reason?.message }
      }
      .assign(to: &$errors)
  }
}
```

### Live поиск с валидацией

```swift
class SearchViewModel: ObservableObject {
  @Published var searchQuery = ""
  @Published var canSearch = false
  @Published var validationMessage: String?
  
  private var cancellables = Set<AnyCancellable>()
  
  init() {
    $searchQuery
      .debounce(for: .milliseconds(300), scheduler: DispatchQueue.main)
      .map { query in
        searchQueryRequirement.evaluate(query)
      }
      .sink { [weak self] evaluation in
        self?.canSearch = evaluation.isConfirmed
        self?.validationMessage = evaluation.reason?.message
      }
      .store(in: &cancellables)
  }
}
```

### Реактивный доступ к API

```swift
class APIAccessManager: ObservableObject {
  @Published var hasAPIAccess = false
  @Published var rateLimitRemaining = 100
  
  private let contextSubject: CurrentValueSubject<APIContext, Never>
  private var cancellables = Set<AnyCancellable>()
  
  init(initialContext: APIContext) {
    self.contextSubject = CurrentValueSubject(initialContext)
    
    apiAccessRequirement
      .isAllowedPublisher(context: contextSubject.eraseToAnyPublisher())
      .assign(to: &$hasAPIAccess)
  }
  
  func updateRateLimit(_ remaining: Int) {
    var context = contextSubject.value
    context.rateLimitRemaining = remaining
    contextSubject.send(context)
  }
}
```

## Интеграция с SwiftUI

### @Published + Requirement

```swift
class ContentViewModel: ObservableObject {
  @Published var user: User {
    didSet {
      updateAccess()
    }
  }
  
  @Published var canAccessPremium = false
  
  private func updateAccess() {
    let context = UserContext(user: user)
    canAccessPremium = premiumRequirement.evaluate(context).isConfirmed
  }
  
  init(user: User) {
    self.user = user
    updateAccess()
  }
}
```

### Combine + ObservedRequirement

```swift
struct DashboardView: View {
  @StateObject var accessManager = FeatureAccessManager()
  
  var body: some View {
    VStack {
      if accessManager.canEditDocuments {
        EditButton()
      }
      
      if accessManager.canDeleteDocuments {
        DeleteButton()
      }
      
      if accessManager.canShareDocuments {
        ShareButton()
      }
    }
    .onReceive(userPublisher) { user in
      accessManager.updateUser(user)
    }
  }
}
```

## Best Practices

### 1. Используйте CurrentValueSubject для текущего состояния

```swift
// ✅ Хорошо - сохраняет текущее значение
let contextSubject = CurrentValueSubject<Context, Never>(initialContext)

// ❌ Плохо - теряет текущее значение
let contextSubject = PassthroughSubject<Context, Never>()
```

### 2. Debounce для частых изменений

```swift
// ✅ Хорошо - избегаем лишних проверок
$searchText
  .debounce(for: .milliseconds(300), scheduler: DispatchQueue.main)
  .map { text in requirement.evaluate(text) }
  .sink { /* ... */ }
```

### 3. Управляйте подписками

```swift
// ✅ Хорошо - сохраняем cancellables
private var cancellables = Set<AnyCancellable>()

publisher.sink { /* ... */ }
  .store(in: &cancellables)

// ❌ Плохо - подписка сразу отменяется
_ = publisher.sink { /* ... */ }
```

### 4. Используйте weak self в замыканиях

```swift
// ✅ Хорошо - избегаем retain cycles
publisher
  .sink { [weak self] value in
    self?.handleValue(value)
  }
  .store(in: &cancellables)
```

## Смотрите также

- <doc:SwiftUIIntegration>
- ``ReactiveRequirement``
- ``RequirementPublisher``

