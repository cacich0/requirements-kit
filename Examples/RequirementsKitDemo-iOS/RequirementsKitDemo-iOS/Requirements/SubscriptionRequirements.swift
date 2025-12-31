import RequirementsKit
import Foundation

// MARK: - Subscription Requirements
// Демонстрация: AsyncRequirement, #asyncRequire, withTimeout, cached, profiled, traced

/// Контекст подписки для async проверок
struct SubscriptionContext: Sendable, Hashable {
  var user: User
  var requestedFeature: PremiumFeature
  var currentDate: Date
  
  static var sample: SubscriptionContext {
    SubscriptionContext(
      user: .regularUser,
      requestedFeature: .advancedAnalytics,
      currentDate: Date()
    )
  }
}

/// Премиум-функции
enum PremiumFeature: String, Sendable, Hashable, CaseIterable {
  case advancedAnalytics = "Advanced Analytics"
  case apiAccess = "API Access"
  case prioritySupport = "Priority Support"
  case unlimitedExports = "Unlimited Exports"
  case customBranding = "Custom Branding"
  case teamManagement = "Team Management"
  
  var displayName: String { rawValue }
  
  var requiredTier: SubscriptionType {
    switch self {
    case .advancedAnalytics, .prioritySupport:
      return .premium
    case .apiAccess, .unlimitedExports:
      return .premium
    case .customBranding, .teamManagement:
      return .enterprise
    }
  }
}

/// Требования для подписок
enum SubscriptionRequirements {
  
  // MARK: - Синхронные требования
  
  /// Имеет активную подписку
  static let hasActiveSubscription: Requirement<SubscriptionContext> =
    Requirement<SubscriptionContext>.require(\.user.hasActiveSubscription)
      .because(code: "subscription.inactive", message: "No active subscription")
  
  /// Имеет премиум подписку
  static let hasPremium: Requirement<SubscriptionContext> =
    Requirement<SubscriptionContext>.require(\.user.isPremium)
      .because(code: "subscription.not_premium", message: "Premium subscription required")
  
  /// Имеет enterprise подписку
  static let hasEnterprise: Requirement<SubscriptionContext> =
    Requirement<SubscriptionContext>.require(\.user.isEnterprise)
      .because(code: "subscription.not_enterprise", message: "Enterprise subscription required")
  
  // MARK: - Async Requirements
  
  /// Проверяет подписку через "API" (симуляция)
  static let verifySubscriptionAsync: AsyncRequirement<SubscriptionContext> =
    AsyncRequirement { context in
      // Симуляция API вызова
      try await Task.sleep(for: .milliseconds(500))
      
      guard context.user.hasActiveSubscription else {
        return .failed(reason: Reason(
          code: "subscription.api_check_failed",
          message: "Subscription verification failed"
        ))
      }
      
      return .confirmed
    }
  
  /// Проверяет лимиты использования через "API"
  static let checkUsageLimits: AsyncRequirement<SubscriptionContext> =
    AsyncRequirement { context in
      // Симуляция проверки лимитов
      try await Task.sleep(for: .milliseconds(300))
      
      // Симулируем что Enterprise не имеет лимитов
      if context.user.isEnterprise {
        return .confirmed
      }
      
      // Для других подписок - проверяем "лимит"
      let usagePercentage = Double.random(in: 0...100)
      if usagePercentage > 80 {
        return .failed(reason: Reason(
          code: "subscription.usage_limit_warning",
          message: "Usage limit reached (\(Int(usagePercentage))%)"
        ))
      }
      
      return .confirmed
    }
  
  // MARK: - Async с таймаутом
  
  /// Проверка подписки с таймаутом
  @available(macOS 13.0, iOS 16.0, *)
  static let verifyWithTimeout: AsyncRequirement<SubscriptionContext> =
    AsyncRequirement.withTimeout(seconds: 2.0, verifySubscriptionAsync)
  
  // MARK: - Композиция async требований
  
  /// Все async проверки последовательно
  static let fullAsyncCheck: AsyncRequirement<SubscriptionContext> =
    AsyncRequirement.all([verifySubscriptionAsync, checkUsageLimits])
  
  /// Все async проверки параллельно
  static let fullAsyncCheckConcurrent: AsyncRequirement<SubscriptionContext> =
    AsyncRequirement.allConcurrent([verifySubscriptionAsync, checkUsageLimits])
  
  // MARK: - Комбинация sync и async
  
  /// Комбинированная проверка
  static let combinedCheck: AsyncRequirement<SubscriptionContext> =
    AsyncRequirement.from(hasActiveSubscription) && verifySubscriptionAsync
  
  // MARK: - Feature Access Requirements
  
  /// Проверяет доступ к конкретной функции
  static func canAccessFeature(_ feature: PremiumFeature) -> Requirement<SubscriptionContext> {
    Requirement { context in
      let requiredTier = feature.requiredTier
      
      switch requiredTier {
      case .free:
        return .confirmed
      case .trial:
        return context.user.hasActiveSubscription
          ? .confirmed
          : .failed(reason: Reason(
              code: "feature.trial_required",
              message: "\(feature.displayName) requires at least Trial subscription"
            ))
      case .premium:
        return context.user.isPremium || context.user.isEnterprise
          ? .confirmed
          : .failed(reason: Reason(
              code: "feature.premium_required",
              message: "\(feature.displayName) requires Premium subscription"
            ))
      case .enterprise:
        return context.user.isEnterprise
          ? .confirmed
          : .failed(reason: Reason(
              code: "feature.enterprise_required",
              message: "\(feature.displayName) requires Enterprise subscription"
            ))
      }
    }
  }
  
  /// Async проверка доступа к функции
  static func canAccessFeatureAsync(_ feature: PremiumFeature) -> AsyncRequirement<SubscriptionContext> {
    AsyncRequirement { context in
      // Симуляция проверки через сервер
      try await Task.sleep(for: .milliseconds(200))
      
      let syncResult = canAccessFeature(feature).evaluate(context)
      return syncResult
    }
  }
}

// MARK: - Caching Examples

extension SubscriptionRequirements {
  /// Кэшированная проверка подписки (TTL 60 секунд)
  static let cachedSubscriptionCheck: CachedRequirement<SubscriptionContext> =
    hasActiveSubscription.cached(ttl: 60)
  
  /// Кэшированная проверка премиума (без TTL - постоянный кэш)
  static let cachedPremiumCheck: CachedRequirement<SubscriptionContext> =
    hasPremium.cached()
}

// MARK: - Profiling & Tracing Examples

extension SubscriptionRequirements {
  /// Профилируемая проверка подписки
  static let profiledSubscriptionCheck: ProfiledRequirement<SubscriptionContext> =
    hasActiveSubscription.profiled()
  
  /// Трассируемая проверка подписки
  static let tracedSubscriptionCheck: TracedRequirement<SubscriptionContext> =
    hasActiveSubscription.traced(name: "SubscriptionCheck")
  
  /// Полная проверка с трассировкой
  static let tracedFullCheck: TracedRequirement<SubscriptionContext> =
    Requirement<SubscriptionContext>.all {
      hasActiveSubscription
      hasPremium
    }.traced(name: "FullSubscriptionCheck")
}

// MARK: - Trial & Expiration

extension SubscriptionRequirements {
  /// Проверка что trial не истек
  static let trialNotExpired: Requirement<SubscriptionContext> = Requirement { context in
    guard context.user.subscriptionType == .trial else {
      return .confirmed // Не trial - пропускаем
    }
    
    guard let expiresAt = context.user.subscriptionExpiresAt else {
      return .failed(reason: Reason(
        code: "subscription.trial_no_expiry",
        message: "Trial subscription has no expiry date"
      ))
    }
    
    return expiresAt > context.currentDate
      ? .confirmed
      : .failed(reason: Reason(
          code: "subscription.trial_expired",
          message: "Trial subscription has expired"
        ))
  }
  
  /// Дней до истечения подписки
  static func expiresInDays(_ minDays: Int) -> Requirement<SubscriptionContext> {
    Requirement { context in
      guard let expiresAt = context.user.subscriptionExpiresAt else {
        // Enterprise без срока действия
        return context.user.isEnterprise
          ? .confirmed
          : .failed(reason: Reason(
              code: "subscription.no_expiry_date",
              message: "No subscription expiry date"
            ))
      }
      
      let daysRemaining = Calendar.current.dateComponents(
        [.day],
        from: context.currentDate,
        to: expiresAt
      ).day ?? 0
      
      return daysRemaining >= minDays
        ? .confirmed
        : .failed(reason: Reason(
            code: "subscription.expiring_soon",
            message: "Subscription expires in \(daysRemaining) days"
          ))
    }
  }
}

