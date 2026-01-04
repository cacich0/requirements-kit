import SwiftUI
import RequirementsKit

/// Демонстрация системы Decision
struct DecisionDemoView: View {
  @State private var selectedUser: User = .regularUser
  @State private var isFirstLaunch = false
  @State private var hasCompletedOnboarding = true
  @State private var isUrgent = false
  @State private var userPrefersPush = true
  @State private var messageType = "general"
  @State private var paymentAmount: Double = 50
  @State private var isRecurring = false
  @State private var dataSize: Int = 500
  @State private var priority = "normal"
  @State private var availableMemory: Int = 1000
  @State private var resourceOwnerId: UUID?
  @State private var isPublicResource = false
  @State private var isPremiumOnly = false
  
  let users: [User] = [.guest, .regularUser, .adminUser]
  
  var body: some View {
    NavigationView {
      ScrollView {
        VStack(spacing: 20) {
          CategoryHeader(
            title: "Decision System",
            systemImage: "arrow.triangle.branch"
          )
          
          Text("Система принятия решений на основе контекста")
            .font(.subheadline)
            .foregroundStyle(.secondary)
            .multilineTextAlignment(.center)
            .padding(.horizontal)
          
          // Выбор пользователя
          userPickerSection
          
          // Route Decision
          routeDecisionSection
          
          // Notification Strategy Decision
          notificationDecisionSection
          
          // Payment Provider Decision
          paymentDecisionSection
          
          // Processing Strategy Decision
          processingDecisionSection
          
          // Access Level Decision
          accessLevelDecisionSection
        }
        .padding()
      }
      .navigationTitle("Decision")
      #if os(iOS)
      .navigationBarTitleDisplayMode(.inline)
      #endif
    }
  }
  
  // MARK: - User Picker
  
  private var userPickerSection: some View {
    DemoSection(
      title: "Выбор пользователя",
      description: "Выберите пользователя для тестирования решений"
    ) {
      Picker("Пользователь", selection: $selectedUser) {
        Text("Гость").tag(User.guest)
        Text("Обычный").tag(User.regularUser)
        Text("Админ").tag(User.adminUser)
      }
      .pickerStyle(.segmented)
      
      VStack(alignment: .leading, spacing: 6) {
        HStack {
          Label(selectedUser.username, systemImage: "person.circle")
            .font(.headline)
          Spacer()
          if selectedUser.isAdmin {
            Label("Admin", systemImage: "crown")
              .font(.caption)
              .foregroundStyle(.orange)
          } else if selectedUser.isPremium {
            Label("Premium", systemImage: "star")
              .font(.caption)
              .foregroundStyle(.blue)
          }
        }
        
        if !selectedUser.isLoggedIn {
          Label("Не авторизован", systemImage: "person.crop.circle.badge.xmark")
            .font(.caption)
            .foregroundStyle(.secondary)
        }
      }
      .padding(.top, 8)
    }
  }
  
  // MARK: - Route Decision
  
  private var routeDecisionSection: some View {
    DemoSection(
      title: "1. Выбор маршрута приложения",
      description: "AppRoute: Куда направить пользователя"
    ) {
      VStack(alignment: .leading, spacing: 12) {
        Toggle("Первый запуск", isOn: $isFirstLaunch)
        Toggle("Онбординг пройден", isOn: $hasCompletedOnboarding)
        
        Divider()
        
        let context = RouteContext(
          user: selectedUser,
          isFirstLaunch: isFirstLaunch,
          hasCompletedOnboarding: hasCompletedOnboarding
        )
        let route = appRouteDecision.decide(context)
        
        if let route = route {
          DecisionResultView(
            title: "Маршрут",
            value: route.rawValue,
            systemImage: route.systemImage,
            color: .blue
          )
        } else {
          DecisionResultView(
            title: "Маршрут",
            value: "Не определен",
            systemImage: "questionmark.circle",
            color: .gray
          )
        }
      }
      
      CodeExampleCard(code: """
        let route = Decision<RouteContext, AppRoute> { ctx in
          if ctx.isFirstLaunch {
            return .onboarding
          }
          if !ctx.user.isLoggedIn {
            return .login
          }
          return ctx.user.isAdmin ? .adminPanel : .dashboard
        }.decide(context)
        """)
    }
  }
  
  // MARK: - Notification Decision
  
  private var notificationDecisionSection: some View {
    DemoSection(
      title: "2. Стратегия уведомлений",
      description: "Как лучше уведомить пользователя"
    ) {
      VStack(alignment: .leading, spacing: 12) {
        Toggle("Срочное уведомление", isOn: $isUrgent)
        Toggle("Push доступен", isOn: $userPrefersPush)
        
        Picker("Тип сообщения", selection: $messageType) {
          Text("Общее").tag("general")
          Text("Финансы").tag("financial")
          Text("Безопасность").tag("security")
        }
        .pickerStyle(.segmented)
        
        Divider()
        
        let context = NotificationContext(
          user: selectedUser,
          isUrgent: isUrgent,
          messageType: messageType,
          userPrefersPush: userPrefersPush
        )
        let strategy = notificationStrategyDecision.decide(context)
        
        if let strategy = strategy {
          DecisionResultView(
            title: "Способ уведомления",
            value: strategy.rawValue,
            systemImage: strategy.systemImage,
            color: .green
          )
        }
      }
      
      CodeExampleCard(code: """
        let strategy = Decision<Context, NotificationStrategy> {
          if ctx.isUrgent && ctx.userPrefersPush {
            return .push
          }
          if ctx.messageType == "financial" {
            return .email
          }
          return .inApp
        }.decide(context)
        """)
    }
  }
  
  // MARK: - Payment Decision
  
  private var paymentDecisionSection: some View {
    DemoSection(
      title: "3. Провайдер оплаты",
      description: "Оптимальный способ оплаты"
    ) {
      VStack(alignment: .leading, spacing: 12) {
        HStack {
          Text("Сумма:")
          Spacer()
          Text("\(Int(paymentAmount))₽")
            .fontWeight(.semibold)
        }
        Slider(value: $paymentAmount, in: 10...20000, step: 10)
        
        Toggle("Регулярный платеж", isOn: $isRecurring)
        
        Divider()
        
        let context = PaymentContext(
          amount: paymentAmount,
          user: selectedUser,
          isRecurring: isRecurring,
          currency: "RUB"
        )
        let provider = paymentProviderDecision.decide(context)
        
        if let provider = provider {
          DecisionResultView(
            title: "Провайдер",
            value: provider.rawValue,
            systemImage: provider.systemImage,
            color: .purple
          )
        }
      }
      
      CodeExampleCard(code: """
        let provider = Decision<Context, PaymentProvider> {
          if ctx.amount < 100 {
            return .applePay
          }
          if ctx.amount >= 10000 {
            return .bankTransfer
          }
          return ctx.isRecurring ? .stripe : .paypal
        }.fallback { .applePay }
        .decide(context)
        """)
    }
  }
  
  // MARK: - Processing Strategy Decision
  
  private var processingDecisionSection: some View {
    DemoSection(
      title: "4. Стратегия обработки",
      description: "Как обрабатывать данные"
    ) {
      VStack(alignment: .leading, spacing: 12) {
        HStack {
          Text("Размер данных:")
          Spacer()
          Text("\(dataSize) KB")
            .fontWeight(.semibold)
        }
        Slider(value: Binding(
          get: { Double(dataSize) },
          set: { dataSize = Int($0) }
        ), in: 10...2000, step: 10)
        
        HStack {
          Text("Память:")
          Spacer()
          Text("\(availableMemory) MB")
            .fontWeight(.semibold)
        }
        Slider(value: Binding(
          get: { Double(availableMemory) },
          set: { availableMemory = Int($0) }
        ), in: 100...2000, step: 50)
        
        Picker("Приоритет", selection: $priority) {
          Text("Низкий").tag("low")
          Text("Обычный").tag("normal")
          Text("Срочный").tag("urgent")
          Text("Критичный").tag("critical")
        }
        .pickerStyle(.segmented)
        
        Divider()
        
        let context = DataContext(
          dataSize: dataSize,
          priority: priority,
          user: selectedUser,
          availableMemory: availableMemory
        )
        let strategy = processingStrategyDecision.decide(context)
        
        if let strategy = strategy {
          VStack(alignment: .leading, spacing: 8) {
            DecisionResultView(
              title: "Стратегия",
              value: strategy.rawValue,
              systemImage: strategy.systemImage,
              color: .orange
            )
            
            Text(strategy.description)
              .font(.caption)
              .foregroundStyle(.secondary)
              .padding(.leading, 40)
          }
        }
      }
      
      CodeExampleCard(code: """
        let strategy = Decision<DataContext, ProcessingStrategy> {
          if ctx.priority == "critical" {
            return .realtime
          }
          if ctx.user.isAdmin {
            return .thorough
          }
          if ctx.dataSize < 100 {
            return .fast
          }
          return .balanced
        }.decide(context)
        """)
    }
  }
  
  // MARK: - Access Level Decision
  
  private var accessLevelDecisionSection: some View {
    DemoSection(
      title: "5. Уровень доступа к ресурсу",
      description: "Какие действия разрешены пользователю"
    ) {
      VStack(alignment: .leading, spacing: 12) {
        Toggle("Пользователь - владелец", isOn: Binding(
          get: { resourceOwnerId == selectedUser.id },
          set: { resourceOwnerId = $0 ? selectedUser.id : nil }
        ))
        
        Toggle("Публичный ресурс", isOn: $isPublicResource)
        Toggle("Только для Premium", isOn: $isPremiumOnly)
        
        Divider()
        
        let context = ResourceContext(
          user: selectedUser,
          resourceOwnerId: resourceOwnerId,
          isPublic: isPublicResource,
          isPremiumOnly: isPremiumOnly
        )
        let accessLevel = accessLevelDecision.decide(context)
        
        if let accessLevel = accessLevel {
          VStack(alignment: .leading, spacing: 8) {
            DecisionResultView(
              title: "Уровень доступа",
              value: accessLevel.rawValue,
              systemImage: accessLevel.systemImage,
              color: accessLevel == .none ? .red : .green
            )
            
            Text(accessLevel.description)
              .font(.caption)
              .foregroundStyle(.secondary)
              .padding(.leading, 40)
          }
        }
      }
      
      CodeExampleCard(code: """
        let access = Decision<ResourceContext, AccessLevel> {
          if ctx.user.isBanned {
            return .none
          }
          if ctx.resourceOwnerId == ctx.user.id {
            return .owner
          }
          if ctx.user.isAdmin {
            return .admin
          }
          if ctx.user.isVerified {
            return .write
          }
          return ctx.isPublic ? .read : .none
        }.decide(context)
        """)
    }
  }
}

// MARK: - Decision Result View

struct DecisionResultView: View {
  let title: String
  let value: String
  let systemImage: String
  let color: Color
  
  var body: some View {
    HStack(spacing: 12) {
      Image(systemName: systemImage)
        .font(.title2)
        .foregroundStyle(color)
        .frame(width: 32)
      
      VStack(alignment: .leading, spacing: 2) {
        Text(title)
          .font(.caption)
          .foregroundStyle(.secondary)
        
        Text(value)
          .font(.headline)
      }
      
      Spacer()
    }
    .padding()
    .background {
      RoundedRectangle(cornerRadius: 8)
        .fill(color.opacity(0.1))
    }
  }
}

#Preview {
  DecisionDemoView()
}


