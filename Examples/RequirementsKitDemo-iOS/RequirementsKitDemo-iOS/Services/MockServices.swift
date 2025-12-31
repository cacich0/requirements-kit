import Foundation
import RequirementsKit

// MARK: - Mock Subscription Service

/// Сервис проверки подписок (симуляция)
actor MockSubscriptionService {
  static let shared = MockSubscriptionService()
  
  private var subscriptionCache: [UUID: SubscriptionStatus] = [:]
  
  struct SubscriptionStatus: Sendable {
    let isActive: Bool
    let type: SubscriptionType
    let expiresAt: Date?
    let usagePercent: Double
  }
  
  /// Проверяет статус подписки пользователя
  func checkSubscription(userId: UUID) async throws -> SubscriptionStatus {
    // Симуляция задержки API
    try await Task.sleep(for: .milliseconds(Int.random(in: 200...800)))
    
    // Симуляция случайных результатов
    if let cached = subscriptionCache[userId] {
      return cached
    }
    
    let status = SubscriptionStatus(
      isActive: Bool.random() ? true : Bool.random(),
      type: SubscriptionType.allCases.randomElement() ?? .free,
      expiresAt: Date().addingTimeInterval(Double.random(in: -86400...2592000)),
      usagePercent: Double.random(in: 0...100)
    )
    
    subscriptionCache[userId] = status
    return status
  }
  
  /// Сбрасывает кэш
  func resetCache() {
    subscriptionCache.removeAll()
  }
}

// MARK: - Mock KYC Service

/// Сервис проверки KYC (симуляция)
actor MockKYCService {
  static let shared = MockKYCService()
  
  enum KYCStatus: String, Sendable {
    case notStarted = "Not Started"
    case pending = "Pending"
    case approved = "Approved"
    case rejected = "Rejected"
  }
  
  /// Проверяет статус KYC пользователя
  func checkKYCStatus(userId: UUID) async throws -> KYCStatus {
    try await Task.sleep(for: .milliseconds(Int.random(in: 300...600)))
    
    let statuses: [KYCStatus] = [.approved, .approved, .approved, .pending, .rejected]
    return statuses.randomElement() ?? .pending
  }
  
  /// Инициирует проверку KYC
  func initiateKYC(userId: UUID) async throws -> Bool {
    try await Task.sleep(for: .milliseconds(500))
    return true
  }
}

// MARK: - Mock Trading Service

/// Сервис торговых операций (симуляция)
actor MockTradingService {
  static let shared = MockTradingService()
  
  struct TradeValidationResult: Sendable {
    let isValid: Bool
    let errorMessage: String?
    let estimatedFee: Double
    let estimatedTotal: Double
  }
  
  /// Валидирует торговую операцию
  func validateTrade(
    userId: UUID,
    amount: Double,
    asset: String,
    type: TradeType
  ) async throws -> TradeValidationResult {
    try await Task.sleep(for: .milliseconds(Int.random(in: 100...400)))
    
    let fee = amount * 0.001 // 0.1% комиссия
    
    // Симуляция валидации
    if amount < 1 {
      return TradeValidationResult(
        isValid: false,
        errorMessage: "Minimum trade amount is 1",
        estimatedFee: fee,
        estimatedTotal: amount + fee
      )
    }
    
    if amount > 1000000 {
      return TradeValidationResult(
        isValid: false,
        errorMessage: "Maximum trade amount is 1,000,000",
        estimatedFee: fee,
        estimatedTotal: amount + fee
      )
    }
    
    return TradeValidationResult(
      isValid: true,
      errorMessage: nil,
      estimatedFee: fee,
      estimatedTotal: amount + fee
    )
  }
  
  /// Проверяет доступность актива
  func checkAssetAvailability(asset: String) async throws -> Bool {
    try await Task.sleep(for: .milliseconds(100))
    
    let availableAssets = ["BTC", "ETH", "USDT", "SOL", "XRP"]
    return availableAssets.contains(asset.uppercased())
  }
}

// MARK: - Mock Rate Limiter

/// Сервис ограничения запросов (симуляция)
actor MockRateLimiter {
  static let shared = MockRateLimiter()
  
  private var requestCounts: [UUID: Int] = [:]
  private var lastReset: Date = Date()
  
  private let maxRequestsPerMinute = 60
  
  /// Проверяет лимит запросов
  func checkRateLimit(userId: UUID) async -> Bool {
    // Сброс каждую минуту
    if Date().timeIntervalSince(lastReset) > 60 {
      requestCounts.removeAll()
      lastReset = Date()
    }
    
    let count = requestCounts[userId, default: 0]
    
    if count >= maxRequestsPerMinute {
      return false
    }
    
    requestCounts[userId] = count + 1
    return true
  }
  
  /// Текущее количество запросов
  func currentCount(for userId: UUID) -> Int {
    requestCounts[userId, default: 0]
  }
}

// MARK: - Async Requirements with Services

/// Async требования, использующие mock сервисы
enum ServiceRequirements {
  
  /// Проверка подписки через сервис
  static let checkSubscriptionViaService: AsyncRequirement<User> = AsyncRequirement { user in
    do {
      let status = try await MockSubscriptionService.shared.checkSubscription(userId: user.id)
      
      if status.isActive {
        return .confirmed
      } else {
        return .failed(reason: Reason(
          code: "service.subscription_inactive",
          message: "Subscription is not active"
        ))
      }
    } catch {
      return .failed(reason: Reason(
        code: "service.error",
        message: "Failed to check subscription: \(error.localizedDescription)"
      ))
    }
  }
  
  /// Проверка KYC через сервис
  static let checkKYCViaService: AsyncRequirement<User> = AsyncRequirement { user in
    do {
      let status = try await MockKYCService.shared.checkKYCStatus(userId: user.id)
      
      switch status {
      case .approved:
        return .confirmed
      case .pending:
        return .failed(reason: Reason(
          code: "kyc.pending",
          message: "KYC verification is pending"
        ))
      case .rejected:
        return .failed(reason: Reason(
          code: "kyc.rejected",
          message: "KYC verification was rejected"
        ))
      case .notStarted:
        return .failed(reason: Reason(
          code: "kyc.not_started",
          message: "Please complete KYC verification"
        ))
      }
    } catch {
      return .failed(reason: Reason(
        code: "service.error",
        message: "Failed to check KYC: \(error.localizedDescription)"
      ))
    }
  }
  
  /// Проверка rate limit
  static let checkRateLimit: AsyncRequirement<User> = AsyncRequirement { user in
    let allowed = await MockRateLimiter.shared.checkRateLimit(userId: user.id)
    
    if allowed {
      return .confirmed
    } else {
      return .failed(reason: Reason(
        code: "rate_limit.exceeded",
        message: "Rate limit exceeded. Please try again later."
      ))
    }
  }
  
  /// Проверка торговой операции через сервис
  static func validateTradeViaService(amount: Double, asset: String, type: TradeType) -> AsyncRequirement<User> {
    AsyncRequirement { user in
      do {
        let result = try await MockTradingService.shared.validateTrade(
          userId: user.id,
          amount: amount,
          asset: asset,
          type: type
        )
        
        if result.isValid {
          return .confirmed
        } else {
          return .failed(reason: Reason(
            code: "trade.validation_failed",
            message: result.errorMessage ?? "Trade validation failed"
          ))
        }
      } catch {
        return .failed(reason: Reason(
          code: "service.error",
          message: "Trade validation error: \(error.localizedDescription)"
        ))
      }
    }
  }
  
  /// Полная проверка перед торговлей
  static func fullTradeCheck(amount: Double, asset: String, type: TradeType) -> AsyncRequirement<User> {
    AsyncRequirement.allConcurrent([
      checkSubscriptionViaService,
      checkKYCViaService,
      checkRateLimit,
      validateTradeViaService(amount: amount, asset: asset, type: type)
    ])
  }
}

