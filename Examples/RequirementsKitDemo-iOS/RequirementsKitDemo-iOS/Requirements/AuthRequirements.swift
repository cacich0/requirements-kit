import Foundation
import RequirementsKit

// MARK: - Auth Requirements
// Демонстрация: макросы #require, #all, #any, #not, #when, #unless, #xor

/// Требования для авторизации и контроля доступа
enum AuthRequirements {
  
  // MARK: - Базовые требования через макросы
  
  /// Пользователь должен быть авторизован
  static let isLoggedIn: Requirement<User> = #require(\.isLoggedIn)
  
  /// Пользователь должен быть верифицирован
  static let isVerified: Requirement<User> = #require(\.isVerified)
  
  /// Пользователь не должен быть заблокирован
  static let notBanned: Requirement<User> = #not(#require(\.isBanned))
  
  /// Пользователь - администратор
  static let isAdmin: Requirement<User> = #require(\.isAdmin)
  
  // MARK: - Композиция через #all
  
  /// Полный доступ к аккаунту
  /// Требует: авторизация + верификация + не заблокирован
  static let hasFullAccess: Requirement<User> = #all {
    #require(\.isLoggedIn)
    #require(\.isVerified)
    #not(#require(\.isBanned))
  }
  
  // MARK: - Композиция через #any
  
  /// Доступ к премиум-функциям
  /// Требует: админ ИЛИ премиум-подписка ИЛИ enterprise
  static let hasPremiumAccess: Requirement<User> = #any {
    #require(\.isAdmin)
    #require(\.isPremium)
    #require(\.isEnterprise)
  }
  
  // MARK: - Условные требования через #when
  
  /// Если пользователь - бета-тестер, требуется подписка
  static let betaTesterRequirement: Requirement<User> = #when(\.isBetaTester) {
    #require(\.hasActiveSubscription)
  }
  
  // MARK: - #unless (инверсия условия)
  
  /// Если пользователь НЕ админ, требуется верификация
  static let nonAdminVerification: Requirement<User> = #unless(\.isAdmin) {
    #require(\.isVerified)
    #require(\.kycCompleted)
  }
  
  // MARK: - #xor (ровно одно из условий)
  
  /// Пользователь должен иметь ЛИБО trial, ЛИБО premium (не оба и не ни одного)
  static let exclusiveSubscription: Requirement<User> = #xor {
    Requirement<User> { $0.subscriptionType == .trial ? .confirmed : .failed(reason: Reason(message: "Not trial")) }
    Requirement<User> { $0.subscriptionType == .premium ? .confirmed : .failed(reason: Reason(message: "Not premium")) }
  }
  
  // MARK: - Комбинированные сложные требования
  
  /// Полные права на управление аккаунтом
  static let canManageAccount: Requirement<User> = #all {
    #require(\.isLoggedIn)
    #require(\.isVerified)
    #require(\.twoFactorEnabled)
    #not(#require(\.isBanned))
  }
  
  /// Доступ к административной панели
  static let canAccessAdminPanel: Requirement<User> = #all {
    #require(\.isLoggedIn)
    #require(\.isAdmin)
    #require(\.twoFactorEnabled)
  }
  
  /// Может ли пользователь приглашать других
  static let canInviteUsers: Requirement<User> = #any {
    // Админ всегда может
    #require(\.isAdmin)
    // Или верифицированный пользователь с enterprise подпиской
    #all {
      #require(\.isVerified)
      #require(\.isEnterprise)
    }
  }
}

// MARK: - Auth Context for Complex Scenarios

/// Расширенный контекст авторизации
struct AuthContext: Sendable, Hashable {
  var user: User
  var ipAddress: String
  var userAgent: String
  var isTrustedDevice: Bool
  var lastLoginDate: Date?
  var failedLoginAttempts: Int
  
  static var sample: AuthContext {
    AuthContext(
      user: .regularUser,
      ipAddress: "192.168.1.1",
      userAgent: "Safari/17.0",
      isTrustedDevice: true,
      lastLoginDate: Date().addingTimeInterval(-3600),
      failedLoginAttempts: 0
    )
  }
}

// MARK: - Extended Auth Requirements

extension AuthRequirements {
  /// Требование для безопасного входа
  static let secureLogin: Requirement<AuthContext> = Requirement.all {
    Requirement<AuthContext>.require(\.user.isLoggedIn)
    Requirement<AuthContext>.require(\.isTrustedDevice)
    Requirement<AuthContext> { context in
      context.failedLoginAttempts < 5
        ? .confirmed
        : .failed(reason: Reason(
            code: "too_many_attempts",
            message: "Too many failed login attempts"
          ))
    }
  }
  
  /// Подозрительная активность
  static let noSuspiciousActivity: Requirement<AuthContext> = Requirement.all {
    Requirement<AuthContext> { context in
      context.failedLoginAttempts < 3
        ? .confirmed
        : .failed(reason: Reason(
            code: "suspicious_activity",
            message: "Suspicious login activity detected"
          ))
    }
    Requirement<AuthContext>.require(\.isTrustedDevice)
  }
}

