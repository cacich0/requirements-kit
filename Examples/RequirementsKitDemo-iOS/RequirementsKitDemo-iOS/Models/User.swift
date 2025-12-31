import Foundation

// MARK: - User Model

/// Модель пользователя для демонстрации требований
struct User: Sendable, Hashable {
  let id: UUID
  var email: String
  var username: String
  var password: String
  
  // Статус пользователя
  var isLoggedIn: Bool
  var isVerified: Bool
  var isAdmin: Bool
  var isBanned: Bool
  
  // Финансы
  var balance: Double
  var dailyLimit: Double
  var usedDailyLimit: Double
  
  // Подписка
  var subscriptionType: SubscriptionType
  var subscriptionExpiresAt: Date?
  var isBetaTester: Bool
  
  // Дополнительные флаги
  var twoFactorEnabled: Bool
  var kycCompleted: Bool
  var acceptedTerms: Bool
  
  static var guest: User {
    User(
      id: UUID(),
      email: "",
      username: "Guest",
      password: "",
      isLoggedIn: false,
      isVerified: false,
      isAdmin: false,
      isBanned: false,
      balance: 0,
      dailyLimit: 0,
      usedDailyLimit: 0,
      subscriptionType: .free,
      subscriptionExpiresAt: nil,
      isBetaTester: false,
      twoFactorEnabled: false,
      kycCompleted: false,
      acceptedTerms: false
    )
  }
  
  static var regularUser: User {
    User(
      id: UUID(),
      email: "user@example.com",
      username: "john_doe",
      password: "SecurePass123!",
      isLoggedIn: true,
      isVerified: true,
      isAdmin: false,
      isBanned: false,
      balance: 1500.0,
      dailyLimit: 5000.0,
      usedDailyLimit: 500.0,
      subscriptionType: .premium,
      subscriptionExpiresAt: Date().addingTimeInterval(30 * 24 * 60 * 60),
      isBetaTester: false,
      twoFactorEnabled: true,
      kycCompleted: true,
      acceptedTerms: true
    )
  }
  
  static var adminUser: User {
    User(
      id: UUID(),
      email: "admin@example.com",
      username: "admin",
      password: "AdminPass456!",
      isLoggedIn: true,
      isVerified: true,
      isAdmin: true,
      isBanned: false,
      balance: 50000.0,
      dailyLimit: 100000.0,
      usedDailyLimit: 0,
      subscriptionType: .enterprise,
      subscriptionExpiresAt: nil,
      isBetaTester: true,
      twoFactorEnabled: true,
      kycCompleted: true,
      acceptedTerms: true
    )
  }
}

// MARK: - Subscription Type

enum SubscriptionType: String, Sendable, Hashable, CaseIterable {
  case free = "Free"
  case trial = "Trial"
  case premium = "Premium"
  case enterprise = "Enterprise"
  
  var displayName: String { rawValue }
  
  var hasPremiumFeatures: Bool {
    switch self {
    case .free:
      return false
    case .trial, .premium, .enterprise:
      return true
    }
  }
  
  var hasEnterpriseFeatures: Bool {
    self == .enterprise
  }
}

// MARK: - Computed Properties for Requirements

extension User {
  var availableDailyLimit: Double {
    max(0, dailyLimit - usedDailyLimit)
  }
  
  var hasActiveSubscription: Bool {
    guard subscriptionType != .free else { return false }
    guard let expiresAt = subscriptionExpiresAt else { 
      return subscriptionType == .enterprise 
    }
    return expiresAt > Date()
  }
  
  var isPremium: Bool {
    subscriptionType.hasPremiumFeatures && hasActiveSubscription
  }
  
  var isEnterprise: Bool {
    subscriptionType.hasEnterpriseFeatures
  }
  
  var canTrade: Bool {
    isLoggedIn && isVerified && !isBanned && kycCompleted
  }
  
  var hasPositiveBalance: Bool {
    balance > 0
  }
}

