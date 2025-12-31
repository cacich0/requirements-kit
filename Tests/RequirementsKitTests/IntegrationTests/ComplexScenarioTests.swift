import Testing
@testable import RequirementsKit

// Пример из ТЗ: Trading Context
struct UserContext: Sendable {
  struct User: Sendable {
    let isLoggedIn: Bool
    let isBanned: Bool
    let isAdmin: Bool
    let hasPremium: Bool
    let balance: Double
    let kycLevel: KYCLevel
  }
  
  enum KYCLevel: Int, Comparable, Sendable {
    case none = 0
    case basic = 1
    case advanced = 2
    
    static func < (lhs: KYCLevel, rhs: KYCLevel) -> Bool {
      lhs.rawValue < rhs.rawValue
    }
  }
  
  struct FeatureFlags: Sendable {
    let tradingEnabled: Bool
  }
  
  let user: User
  let featureFlags: FeatureFlags
}

@Suite("Complex Scenario Tests (Trading Example)")
struct ComplexScenarioTests {
  
  @Test("Сложный сценарий трейдинга - администратор имеет доступ")
  func testTradingAccessAdmin() {
    let canTrade = Requirement<UserContext>.all {
      #require(\.user.isLoggedIn)
      #require(\.user.isBanned, equals: false)
      #require(\.featureFlags.tradingEnabled)
      
      Requirement.any {
        #require(\.user.isAdmin)
        
        Requirement.all {
          #require(\.user.hasPremium)
          #require(\.user.balance, greaterThan: 100)
          #require(\.user.kycLevel, greaterThanOrEqual: .basic)
        }
      }
    }
    
    let adminContext = UserContext(
      user: .init(
        isLoggedIn: true,
        isBanned: false,
        isAdmin: true,
        hasPremium: false,
        balance: 0,
        kycLevel: .none
      ),
      featureFlags: .init(tradingEnabled: true)
    )
    
    let result = canTrade.evaluate(adminContext)
    #expect(result.isConfirmed)
  }
  
  @Test("Сложный сценарий трейдинга - премиум пользователь с достаточным балансом")
  func testTradingAccessPremiumUser() {
    let canTrade = Requirement<UserContext>.all {
      #require(\.user.isLoggedIn)
      #require(\.user.isBanned, equals: false)
      #require(\.featureFlags.tradingEnabled)
      
      Requirement.any {
        #require(\.user.isAdmin)
        
        Requirement.all {
          #require(\.user.hasPremium)
          #require(\.user.balance, greaterThan: 100)
          #require(\.user.kycLevel, greaterThanOrEqual: .basic)
        }
      }
    }
    
    let premiumContext = UserContext(
      user: .init(
        isLoggedIn: true,
        isBanned: false,
        isAdmin: false,
        hasPremium: true,
        balance: 150,
        kycLevel: .basic
      ),
      featureFlags: .init(tradingEnabled: true)
    )
    
    let result = canTrade.evaluate(premiumContext)
    #expect(result.isConfirmed)
  }
  
  @Test("Сложный сценарий трейдинга - доступ запрещён (не авторизован)")
  func testTradingAccessDeniedNotLoggedIn() {
    let canTrade = Requirement<UserContext>.all {
      #require(\.user.isLoggedIn).because("Требуется авторизация")
      #require(\.user.isBanned, equals: false)
      #require(\.featureFlags.tradingEnabled)
      
      Requirement.any {
        #require(\.user.isAdmin)
        
        Requirement.all {
          #require(\.user.hasPremium)
          #require(\.user.balance, greaterThan: 100)
          #require(\.user.kycLevel, greaterThanOrEqual: .basic)
        }
      }
    }
    
    let guestContext = UserContext(
      user: .init(
        isLoggedIn: false,
        isBanned: false,
        isAdmin: false,
        hasPremium: true,
        balance: 200,
        kycLevel: .advanced
      ),
      featureFlags: .init(tradingEnabled: true)
    )
    
    let result = canTrade.evaluate(guestContext)
    #expect(result.isFailed)
    #expect(result.reason?.message == "Требуется авторизация")
  }
  
  @Test("Сложный сценарий трейдинга - доступ запрещён (забанен)")
  func testTradingAccessDeniedBanned() {
    let canTrade = Requirement<UserContext>.all {
      #require(\.user.isLoggedIn)
      #require(\.user.isBanned, equals: false).because("Пользователь заблокирован")
      #require(\.featureFlags.tradingEnabled)
      
      Requirement.any {
        #require(\.user.isAdmin)
        
        Requirement.all {
          #require(\.user.hasPremium)
          #require(\.user.balance, greaterThan: 100)
          #require(\.user.kycLevel, greaterThanOrEqual: .basic)
        }
      }
    }
    
    let bannedContext = UserContext(
      user: .init(
        isLoggedIn: true,
        isBanned: true,
        isAdmin: false,
        hasPremium: true,
        balance: 200,
        kycLevel: .advanced
      ),
      featureFlags: .init(tradingEnabled: true)
    )
    
    let result = canTrade.evaluate(bannedContext)
    #expect(result.isFailed)
    #expect(result.reason?.message == "Пользователь заблокирован")
  }
  
  @Test("Сложный сценарий трейдинга - недостаточный баланс")
  func testTradingAccessDeniedInsufficientBalance() {
    let canTrade = Requirement<UserContext>.all {
      #require(\.user.isLoggedIn)
      #require(\.user.isBanned, equals: false)
      #require(\.featureFlags.tradingEnabled)
      
      Requirement.any {
        #require(\.user.isAdmin)
        
        Requirement.all {
          #require(\.user.hasPremium)
          #require(\.user.balance, greaterThan: 100).because("Недостаточно средств")
          #require(\.user.kycLevel, greaterThanOrEqual: .basic)
        }
      }
    }
    
    let poorUserContext = UserContext(
      user: .init(
        isLoggedIn: true,
        isBanned: false,
        isAdmin: false,
        hasPremium: true,
        balance: 50,
        kycLevel: .basic
      ),
      featureFlags: .init(tradingEnabled: true)
    )
    
    let result = canTrade.evaluate(poorUserContext)
    #expect(result.isFailed)
  }
}

