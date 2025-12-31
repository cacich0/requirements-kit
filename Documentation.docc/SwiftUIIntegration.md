# Интеграция со SwiftUI

Используйте RequirementsKit в SwiftUI-приложениях с помощью property wrappers и reactive паттернов.

## Обзор

RequirementsKit предоставляет несколько способов интеграции со SwiftUI через property wrappers, обсервацию и Combine publishers.

## Property Wrappers

### @Eligible — булев доступ

``Eligible`` предоставляет простой булев результат проверки требования:

```swift
struct FeatureView: View {
  @Eligible(by: canUsePremiumFeature, context: userContext)
  var canUseFeature: Bool
  
  var body: some View {
    VStack {
      if canUseFeature {
        PremiumFeatureButton()
      } else {
        UpgradePrompt()
      }
    }
  }
}
```

### @Eligibility — расширенный доступ

``Eligibility`` предоставляет детальную информацию о результате проверки:

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

#### Свойства Eligibility

```swift
tradeEligibility.isAllowed  // Bool - разрешено ли действие
tradeEligibility.reason     // Reason? - причина отказа (если есть)
```

## Реактивное обновление

### @ObservedRequirement

Используйте ``ObservedRequirement`` для автоматического обновления UI при изменении контекста:

```swift
@Observable
class UserSession {
  var user: User
  var balance: Double
  
  var context: UserContext {
    UserContext(user: user, balance: balance)
  }
}

struct ContentView: View {
  @State var session = UserSession()
  
  @ObservedRequirement(
    by: canTrade,
    contextProvider: { session in session.context }
  )
  var tradeAccess
  
  var body: some View {
    VStack {
      Text("Баланс: \(session.balance)")
      
      Button("Торговать") {
        trade()
      }
      .disabled(!tradeAccess.isAllowed)
      
      if let reason = tradeAccess.reason {
        Text(reason.message)
          .foregroundColor(.red)
      }
    }
    .onChange(of: session.balance) { _, _ in
      // tradeAccess автоматически обновится
    }
  }
}
```

## Интеграция с @Observable

```swift
import SwiftUI
import Observation

@Observable
class FeatureViewModel {
  var user: User
  var features: FeatureFlags
  
  var context: FeatureContext {
    FeatureContext(user: user, features: features)
  }
  
  var canAccessFeature: Bool {
    featureRequirement.evaluate(context).isConfirmed
  }
  
  private let featureRequirement = #all {
    #require(\.user.isPremium)
    #require(\.features.experimentalEnabled)
  }
}

struct FeatureView: View {
  @State private var viewModel = FeatureViewModel()
  
  var body: some View {
    VStack {
      if viewModel.canAccessFeature {
        ExperimentalFeature()
      } else {
        LockedFeaturePlaceholder()
      }
      
      Toggle("Premium", isOn: $viewModel.user.isPremium)
    }
  }
}
```

## Динамический UI

### Условное отображение

```swift
struct DashboardView: View {
  let context: UserContext
  
  var body: some View {
    VStack {
      // Всегда показываем
      BasicFeatures()
      
      // Условно показываем
      if canAccessAnalytics.evaluate(context).isConfirmed {
        AnalyticsView()
      }
      
      if canAccessReports.evaluate(context).isConfirmed {
        ReportsView()
      }
      
      if canManageTeam.evaluate(context).isConfirmed {
        TeamManagementView()
      }
    }
  }
}
```

### Условная стилизация

```swift
struct FeatureCard: View {
  let feature: Feature
  let context: UserContext
  
  var body: some View {
    let canAccess = feature.requirement.evaluate(context).isConfirmed
    
    VStack {
      Text(feature.title)
        .font(.headline)
      
      Text(feature.description)
        .font(.caption)
    }
    .opacity(canAccess ? 1.0 : 0.5)
    .overlay {
      if !canAccess {
        Image(systemName: "lock.fill")
          .foregroundColor(.gray)
      }
    }
  }
}
```

## Обработка состояний

### Loading состояние для асинхронных требований

```swift
struct AsyncFeatureView: View {
  @State private var isChecking = false
  @State private var canAccess = false
  @State private var errorMessage: String?
  
  let context: UserContext
  
  var body: some View {
    VStack {
      if isChecking {
        ProgressView()
          .progressViewStyle(.circular)
      } else if canAccess {
        FeatureContent()
      } else {
        VStack {
          Text("Доступ запрещён")
            .font(.headline)
          
          if let error = errorMessage {
            Text(error)
              .font(.caption)
              .foregroundColor(.red)
          }
        }
      }
    }
    .task {
      await checkAccess()
    }
  }
  
  func checkAccess() async {
    isChecking = true
    defer { isChecking = false }
    
    do {
      let result = try await asyncRequirement.evaluate(context)
      canAccess = result.isConfirmed
      errorMessage = result.reason?.message
    } catch {
      errorMessage = error.localizedDescription
    }
  }
}
```

## Формы с валидацией

```swift
struct RegistrationForm: View {
  @State private var email = ""
  @State private var password = ""
  @State private var age = ""
  
  var emailValid: Bool {
    emailRequirement.evaluate(email).isConfirmed
  }
  
  var passwordValid: Bool {
    passwordRequirement.evaluate(password).isConfirmed
  }
  
  var ageValid: Bool {
    if let ageInt = Int(age) {
      return ageRequirement.evaluate(ageInt).isConfirmed
    }
    return false
  }
  
  var canSubmit: Bool {
    emailValid && passwordValid && ageValid
  }
  
  var body: some View {
    Form {
      Section("Email") {
        TextField("Email", text: $email)
          .textInputAutocapitalization(.never)
          .keyboardType(.emailAddress)
        
        if !email.isEmpty && !emailValid {
          Text("Некорректный email")
            .foregroundColor(.red)
            .font(.caption)
        }
      }
      
      Section("Пароль") {
        SecureField("Пароль", text: $password)
        
        if !password.isEmpty && !passwordValid {
          Text("Пароль должен содержать минимум 8 символов")
            .foregroundColor(.red)
            .font(.caption)
        }
      }
      
      Section("Возраст") {
        TextField("Возраст", text: $age)
          .keyboardType(.numberPad)
        
        if !age.isEmpty && !ageValid {
          Text("Возраст должен быть от 18 до 120")
            .foregroundColor(.red)
            .font(.caption)
        }
      }
      
      Button("Зарегистрироваться") {
        register()
      }
      .disabled(!canSubmit)
    }
  }
  
  func register() {
    // Регистрация
  }
}

// Требования для валидации
let emailRequirement = Requirement<String>
  .notEmpty()
  .matches(pattern: #"^[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}$"#, options: .caseInsensitive)

let passwordRequirement = Requirement<String>
  .minLength(8)

let ageRequirement = Requirement<Int>
  .inRange(18...120)
```

## Списки с фильтрацией

```swift
struct FeatureListView: View {
  let allFeatures: [Feature]
  let context: UserContext
  
  var availableFeatures: [Feature] {
    allFeatures.filter { feature in
      feature.requirement.evaluate(context).isConfirmed
    }
  }
  
  var lockedFeatures: [Feature] {
    allFeatures.filter { feature in
      !feature.requirement.evaluate(context).isConfirmed
    }
  }
  
  var body: some View {
    List {
      Section("Доступные функции") {
        ForEach(availableFeatures) { feature in
          FeatureRow(feature: feature)
        }
      }
      
      Section("Заблокированные функции") {
        ForEach(lockedFeatures) { feature in
          FeatureRow(feature: feature)
            .opacity(0.5)
            .overlay(alignment: .trailing) {
              Image(systemName: "lock.fill")
                .foregroundColor(.gray)
            }
        }
      }
    }
  }
}
```

## Настройки с правами доступа

```swift
struct SettingsView: View {
  @State private var viewModel: SettingsViewModel
  
  var body: some View {
    List {
      Section("Общие") {
        Toggle("Уведомления", isOn: $viewModel.notificationsEnabled)
        Toggle("Dark Mode", isOn: $viewModel.darkModeEnabled)
      }
      
      if canAccessAdvancedSettings.evaluate(viewModel.context).isConfirmed {
        Section("Дополнительно") {
          Toggle("Developer Mode", isOn: $viewModel.developerMode)
          Toggle("Debug Logging", isOn: $viewModel.debugLogging)
        }
      }
      
      if canManageTeam.evaluate(viewModel.context).isConfirmed {
        Section("Управление командой") {
          NavigationLink("Участники") {
            TeamMembersView()
          }
          NavigationLink("Приглашения") {
            InvitationsView()
          }
        }
      }
      
      if isAdmin.evaluate(viewModel.context).isConfirmed {
        Section("Администрирование") {
          NavigationLink("Пользователи") {
            UsersManagementView()
          }
          NavigationLink("Система") {
            SystemSettingsView()
          }
        }
      }
    }
  }
}
```

## Toolbar с условными кнопками

```swift
struct DocumentView: View {
  let document: Document
  let context: UserContext
  
  var body: some View {
    DocumentContent(document: document)
      .toolbar {
        ToolbarItemGroup(placement: .primaryAction) {
          if canEdit.evaluate(context).isConfirmed {
            Button("Редактировать") {
              edit()
            }
          }
          
          if canShare.evaluate(context).isConfirmed {
            ShareLink(item: document.url)
          }
          
          if canDelete.evaluate(context).isConfirmed {
            Button(role: .destructive) {
              delete()
            } label: {
              Label("Удалить", systemImage: "trash")
            }
          }
        }
      }
  }
}
```

## Best Practices

### 1. Кэшируйте требования в ViewModel

```swift
// ✅ Хорошо
class ViewModel {
  private let canTradeRequirement = #all { /* ... */ }
  
  func canTrade(context: TradingContext) -> Bool {
    canTradeRequirement.evaluate(context).isConfirmed
  }
}

// ❌ Плохо
class ViewModel {
  func canTrade(context: TradingContext) -> Bool {
    // Создаётся новое требование при каждом вызове
    (#all { /* ... */ }).evaluate(context).isConfirmed
  }
}
```

### 2. Используйте computed properties

```swift
// ✅ Хорошо
@Observable
class ViewModel {
  var user: User
  
  var canAccessPremium: Bool {
    premiumRequirement.evaluate(context).isConfirmed
  }
}

// View автоматически обновится при изменении user
```

### 3. Группируйте проверки доступа

```swift
struct AccessControl {
  let context: UserContext
  
  var canEdit: Bool {
    editRequirement.evaluate(context).isConfirmed
  }
  
  var canDelete: Bool {
    deleteRequirement.evaluate(context).isConfirmed
  }
  
  var canShare: Bool {
    shareRequirement.evaluate(context).isConfirmed
  }
}

struct DocumentView: View {
  let access: AccessControl
  
  var body: some View {
    // Используем access.canEdit, access.canDelete, etc.
  }
}
```

## Смотрите также

- <doc:CombineIntegration>
- ``Eligible``
- ``Eligibility``
- ``ObservedRequirement``

