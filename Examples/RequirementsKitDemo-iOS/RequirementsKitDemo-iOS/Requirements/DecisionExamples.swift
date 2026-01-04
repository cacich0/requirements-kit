import Foundation
import RequirementsKit

// MARK: - App Route Decision

enum AppRoute: String, Sendable, CaseIterable {
  case onboarding = "Онбординг"
  case login = "Вход"
  case dashboard = "Главная"
  case premiumDashboard = "Premium"
  case adminPanel = "Админ-панель"
  
  var systemImage: String {
    switch self {
    case .onboarding:
      return "hand.wave"
    case .login:
      return "person.badge.key"
    case .dashboard:
      return "house"
    case .premiumDashboard:
      return "crown"
    case .adminPanel:
      return "gear.badge"
    }
  }
}

struct RouteContext: Sendable {
  let user: User
  let isFirstLaunch: Bool
  let hasCompletedOnboarding: Bool
}

/// Решение о маршруте приложения на основе состояния пользователя
let appRouteDecision = Decision<RouteContext, AppRoute> { ctx in
  // Первый запуск - показываем онбординг
  if ctx.isFirstLaunch && !ctx.hasCompletedOnboarding {
    return .onboarding
  }
  
  // Не авторизован - показываем логин
  if !ctx.user.isLoggedIn {
    return .login
  }
  
  // Админ - админ-панель
  if ctx.user.isAdmin {
    return .adminPanel
  }
  
  // Premium пользователь - premium дашборд
  if ctx.user.isPremium {
    return .premiumDashboard
  }
  
  // Обычный пользователь - стандартный дашборд
  return .dashboard
}

// MARK: - Notification Strategy Decision

enum NotificationStrategy: String, Sendable, CaseIterable {
  case push = "Push-уведомление"
  case email = "Email"
  case sms = "SMS"
  case inApp = "В приложении"
  case none = "Без уведомлений"
  
  var systemImage: String {
    switch self {
    case .push:
      return "bell.badge"
    case .email:
      return "envelope"
    case .sms:
      return "message"
    case .inApp:
      return "app.badge"
    case .none:
      return "bell.slash"
    }
  }
}

struct NotificationContext: Sendable {
  let user: User
  let isUrgent: Bool
  let messageType: String
  let userPrefersPush: Bool
}

/// Решение о способе уведомления пользователя
let notificationStrategyDecision = Decision<NotificationContext, NotificationStrategy> { ctx in
  // Пользователь не авторизован - только в приложении
  guard ctx.user.isLoggedIn else {
    return .inApp
  }
  
  // Срочное уведомление и есть push
  if ctx.isUrgent && ctx.userPrefersPush {
    return .push
  }
  
  // Финансовые операции - предпочтение email для надежности
  if ctx.messageType == "financial" {
    return .email
  }
  
  // Premium пользователи получают SMS
  if ctx.user.isPremium && ctx.messageType == "security" {
    return .sms
  }
  
  // По умолчанию - push если доступен
  if ctx.userPrefersPush {
    return .push
  }
  
  // Иначе email
  return .email
}

// MARK: - Payment Provider Decision

enum PaymentProvider: String, Sendable, CaseIterable {
  case stripe = "Stripe"
  case paypal = "PayPal"
  case applePay = "Apple Pay"
  case bankTransfer = "Банковский перевод"
  
  var systemImage: String {
    switch self {
    case .stripe:
      return "creditcard"
    case .paypal:
      return "dollarsign.circle"
    case .applePay:
      return "apple.logo"
    case .bankTransfer:
      return "building.columns"
    }
  }
}

struct PaymentContext: Sendable {
  let amount: Double
  let user: User
  let isRecurring: Bool
  let currency: String
}

/// Решение о выборе провайдера оплаты
let paymentProviderDecision = Decision<PaymentContext, PaymentProvider> { ctx in
  // Маленькие суммы (до 100) - Apple Pay для удобства
  if ctx.amount < 100 && !ctx.isRecurring {
    return .applePay
  }
  
  // Большие суммы (от 10000) - банковский перевод для надежности
  if ctx.amount >= 10000 {
    return .bankTransfer
  }
  
  // Подписки и регулярные платежи - Stripe
  if ctx.isRecurring {
    return .stripe
  }
  
  // Premium пользователи - предпочтение Stripe
  if ctx.user.isPremium {
    return .stripe
  }
  
  // По умолчанию - PayPal (широкая поддержка)
  return .paypal
}
  .fallback { ctx in
    // Запасной вариант если основной провайдер недоступен
    ctx.amount < 500 ? .applePay : .bankTransfer
  }

// MARK: - Processing Strategy Decision

enum ProcessingStrategy: String, Sendable, CaseIterable {
  case fast = "Быстрая обработка"
  case balanced = "Сбалансированная"
  case thorough = "Тщательная"
  case realtime = "Реального времени"
  
  var systemImage: String {
    switch self {
    case .fast:
      return "hare"
    case .balanced:
      return "scale.3d"
    case .thorough:
      return "tortoise"
    case .realtime:
      return "bolt"
    }
  }
  
  var description: String {
    switch self {
    case .fast:
      return "Минимальная задержка, базовая проверка"
    case .balanced:
      return "Оптимальное соотношение скорости и качества"
    case .thorough:
      return "Максимальная точность и проверки"
    case .realtime:
      return "Мгновенная обработка для критичных операций"
    }
  }
}

struct DataContext: Sendable {
  let dataSize: Int // в KB
  let priority: String
  let user: User
  let availableMemory: Int // в MB
}

/// Решение о стратегии обработки данных
let processingStrategyDecision = Decision<DataContext, ProcessingStrategy> { ctx in
  // Критичные операции - реалтайм
  if ctx.priority == "critical" {
    return .realtime
  }
  
  // Admin или enterprise - всегда тщательная обработка
  if ctx.user.isAdmin || ctx.user.isEnterprise {
    return .thorough
  }
  
  // Срочные задачи и маленький размер - быстрая
  if ctx.priority == "urgent" && ctx.dataSize < 100 {
    return .fast
  }
  
  // Большой размер данных и есть память - тщательная
  if ctx.dataSize > 1000 && ctx.availableMemory > 500 {
    return .thorough
  }
  
  // Средний приоритет - сбалансированная
  if ctx.priority == "normal" {
    return .balanced
  }
  
  // По умолчанию - быстрая для низкого приоритета
  return .fast
}

// MARK: - Access Level Decision

enum AccessLevel: String, Sendable, CaseIterable {
  case none = "Нет доступа"
  case read = "Чтение"
  case write = "Запись"
  case admin = "Администратор"
  case owner = "Владелец"
  
  var systemImage: String {
    switch self {
    case .none:
      return "lock"
    case .read:
      return "eye"
    case .write:
      return "pencil"
    case .admin:
      return "key"
    case .owner:
      return "crown"
    }
  }
  
  var description: String {
    switch self {
    case .none:
      return "Доступ запрещен"
    case .read:
      return "Только просмотр"
    case .write:
      return "Просмотр и редактирование"
    case .admin:
      return "Полный контроль"
    case .owner:
      return "Владелец с максимальными правами"
    }
  }
}

struct ResourceContext: Sendable {
  let user: User
  let resourceOwnerId: UUID?
  let isPublic: Bool
  let isPremiumOnly: Bool
}

/// Решение об уровне доступа к ресурсу
let accessLevelDecision = Decision<ResourceContext, AccessLevel> { ctx in
  // Забанен - нет доступа
  if ctx.user.isBanned {
    return .none
  }
  
  // Владелец ресурса
  if let ownerId = ctx.resourceOwnerId, ownerId == ctx.user.id {
    return .owner
  }
  
  // Администратор - полный доступ
  if ctx.user.isAdmin {
    return .admin
  }
  
  // Требуется Premium, но у пользователя его нет
  if ctx.isPremiumOnly && !ctx.user.isPremium {
    return .none
  }
  
  // Не авторизован и не публичный ресурс
  if !ctx.user.isLoggedIn && !ctx.isPublic {
    return .none
  }
  
  // Верифицированный пользователь - может редактировать
  if ctx.user.isVerified && ctx.user.isLoggedIn {
    return .write
  }
  
  // Авторизован но не верифицирован - только чтение
  if ctx.user.isLoggedIn {
    return .read
  }
  
  // Публичный ресурс для неавторизованных - только чтение
  if ctx.isPublic {
    return .read
  }
  
  // По умолчанию - нет доступа
  return .none
}

// MARK: - Integration with Requirements

/// Пример интеграции Decision с Requirement
let premiumFeatureDecision = Decision<User, String>.when(
  Requirement<User> { user in
    user.isPremium 
      ? .confirmed 
      : .failed(reason: Reason(message: "Требуется Premium"))
  },
  return: "Premium Feature Unlocked"
).fallbackDefault("Standard Feature")


