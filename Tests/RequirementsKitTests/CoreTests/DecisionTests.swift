import Testing
@testable import RequirementsKit

// MARK: - Test Context

struct DecisionTestContext: Sendable {
  let isAuthenticated: Bool
  let hasSession: Bool
  let userRole: String
  let value: Int
}

enum Route: Sendable, Equatable {
  case dashboard
  case login
  case welcome
  case admin
  case user
}

// MARK: - Decision Tests

@Suite("Decision Tests")
struct DecisionTests {
  
  // MARK: - Базовые тесты
  
  @Test("Decision возвращает значение")
  func decisionReturnsValue() {
    let decision = Decision<DecisionTestContext, Route> { ctx in
      ctx.isAuthenticated ? .dashboard : nil
    }
    
    let authenticatedContext = DecisionTestContext(
      isAuthenticated: true,
      hasSession: true,
      userRole: "user",
      value: 100
    )
    
    let result = decision.decide(authenticatedContext)
    #expect(result == .dashboard)
  }
  
  @Test("Decision возвращает nil")
  func decisionReturnsNil() {
    let decision = Decision<DecisionTestContext, Route> { ctx in
      ctx.isAuthenticated ? .dashboard : nil
    }
    
    let unauthenticatedContext = DecisionTestContext(
      isAuthenticated: false,
      hasSession: false,
      userRole: "guest",
      value: 0
    )
    
    let result = decision.decide(unauthenticatedContext)
    #expect(result == nil)
  }
  
  @Test("Decision.constant возвращает константное значение")
  func constantDecision() {
    let decision = Decision<DecisionTestContext, Route>.constant(.welcome)
    
    let context = DecisionTestContext(
      isAuthenticated: false,
      hasSession: false,
      userRole: "guest",
      value: 0
    )
    
    let result = decision.decide(context)
    #expect(result == .welcome)
  }
  
  @Test("Decision.never всегда возвращает nil")
  func neverDecision() {
    let decision = Decision<DecisionTestContext, Route>.never
    
    let context = DecisionTestContext(
      isAuthenticated: true,
      hasSession: true,
      userRole: "admin",
      value: 100
    )
    
    let result = decision.decide(context)
    #expect(result == nil)
  }
  
  // MARK: - Композиция с fallback
  
  @Test("fallback с другим Decision работает корректно")
  func fallbackWithDecision() {
    let primary = Decision<DecisionTestContext, Route> { ctx in
      ctx.isAuthenticated ? .dashboard : nil
    }
    
    let fallback = Decision<DecisionTestContext, Route> { ctx in
      ctx.hasSession ? .login : .welcome
    }
    
    let combined = primary.fallback(fallback)
    
    // Тест 1: primary возвращает значение
    let authenticatedContext = DecisionTestContext(
      isAuthenticated: true,
      hasSession: true,
      userRole: "user",
      value: 100
    )
    #expect(combined.decide(authenticatedContext) == .dashboard)
    
    // Тест 2: primary возвращает nil, fallback возвращает значение
    let sessionContext = DecisionTestContext(
      isAuthenticated: false,
      hasSession: true,
      userRole: "guest",
      value: 0
    )
    #expect(combined.decide(sessionContext) == .login)
    
    // Тест 3: оба возвращают nil
    let noContext = DecisionTestContext(
      isAuthenticated: false,
      hasSession: false,
      userRole: "guest",
      value: 0
    )
    #expect(combined.decide(noContext) == .welcome)
  }
  
  @Test("fallback с замыканием работает корректно")
  func fallbackWithClosure() {
    let primary = Decision<DecisionTestContext, Route> { ctx in
      ctx.isAuthenticated ? .dashboard : nil
    }
    
    let combined = primary.fallback { ctx in
      ctx.hasSession ? .login : .welcome
    }
    
    let sessionContext = DecisionTestContext(
      isAuthenticated: false,
      hasSession: true,
      userRole: "guest",
      value: 0
    )
    #expect(combined.decide(sessionContext) == .login)
  }
  
  @Test("fallbackDefault возвращает значение по умолчанию")
  func fallbackDefault() {
    let decision = Decision<DecisionTestContext, Route> { ctx in
      ctx.isAuthenticated ? .dashboard : nil
    }
    
    let withDefault = decision.fallbackDefault(.welcome)
    
    let unauthenticatedContext = DecisionTestContext(
      isAuthenticated: false,
      hasSession: false,
      userRole: "guest",
      value: 0
    )
    
    #expect(withDefault.decide(unauthenticatedContext) == .welcome)
  }
  
  // MARK: - Трансформации
  
  @Test("map преобразует результат")
  func mapTransformsResult() {
    let decision = Decision<DecisionTestContext, Int> { ctx in
      ctx.value
    }
    
    let mapped = decision.map { value in
      "Value: \(value)"
    }
    
    let context = DecisionTestContext(
      isAuthenticated: true,
      hasSession: true,
      userRole: "user",
      value: 42
    )
    
    #expect(mapped.decide(context) == "Value: 42")
  }
  
  @Test("compactMap фильтрует и преобразует результат")
  func compactMapFiltersAndTransforms() {
    let decision = Decision<DecisionTestContext, Int> { ctx in
      ctx.value
    }
    
    let mapped = decision.compactMap { value -> String? in
      value > 50 ? "High: \(value)" : nil
    }
    
    let lowContext = DecisionTestContext(
      isAuthenticated: true,
      hasSession: true,
      userRole: "user",
      value: 30
    )
    #expect(mapped.decide(lowContext) == nil)
    
    let highContext = DecisionTestContext(
      isAuthenticated: true,
      hasSession: true,
      userRole: "user",
      value: 100
    )
    #expect(mapped.decide(highContext) == "High: 100")
  }
  
  @Test("filter фильтрует результат по условию")
  func filterByPredicate() {
    let decision = Decision<DecisionTestContext, Route> { ctx in
      ctx.isAuthenticated ? .dashboard : nil
    }
    
    let filtered = decision.filter { route in
      route == .dashboard
    }
    
    let context = DecisionTestContext(
      isAuthenticated: true,
      hasSession: true,
      userRole: "user",
      value: 100
    )
    
    #expect(filtered.decide(context) == .dashboard)
  }
  
  @Test("filter возвращает nil при несоответствии условию")
  func filterReturnsNilWhenPredicateFails() {
    let decision = Decision<DecisionTestContext, Route> { ctx in
      .login
    }
    
    let filtered = decision.filter { route in
      route == .dashboard
    }
    
    let context = DecisionTestContext(
      isAuthenticated: false,
      hasSession: true,
      userRole: "guest",
      value: 0
    )
    
    #expect(filtered.decide(context) == nil)
  }
  
  // MARK: - Интеграция с Requirements
  
  @Test("when с Requirement возвращает значение при выполнении требования")
  func whenRequirementReturnsValueOnSuccess() {
    let requirement = Requirement<DecisionTestContext> { ctx in
      ctx.isAuthenticated ? .confirmed : .failed(reason: Reason(message: "Not authenticated"))
    }
    
    let decision = Decision<DecisionTestContext, Route>.when(requirement, return: .dashboard)
    
    let authenticatedContext = DecisionTestContext(
      isAuthenticated: true,
      hasSession: true,
      userRole: "user",
      value: 100
    )
    #expect(decision.decide(authenticatedContext) == .dashboard)
    
    let unauthenticatedContext = DecisionTestContext(
      isAuthenticated: false,
      hasSession: false,
      userRole: "guest",
      value: 0
    )
    #expect(decision.decide(unauthenticatedContext) == nil)
  }
  
  @Test("when с Requirement и замыканием работает корректно")
  func whenRequirementWithClosureWorksCorrectly() {
    let requirement = Requirement<DecisionTestContext> { ctx in
      ctx.isAuthenticated ? .confirmed : .failed(reason: Reason(message: "Not authenticated"))
    }
    
    let decision = Decision<DecisionTestContext, Route>.when(requirement) { ctx in
      ctx.userRole == "admin" ? .admin : .user
    }
    
    let adminContext = DecisionTestContext(
      isAuthenticated: true,
      hasSession: true,
      userRole: "admin",
      value: 100
    )
    #expect(decision.decide(adminContext) == .admin)
    
    let userContext = DecisionTestContext(
      isAuthenticated: true,
      hasSession: true,
      userRole: "user",
      value: 100
    )
    #expect(decision.decide(userContext) == .user)
  }
  
  // MARK: - Условная логика
  
  @Test("when с условием возвращает значение")
  func whenConditionReturnsValue() {
    let decision = Decision<DecisionTestContext, Route>.when(
      { ctx in ctx.isAuthenticated },
      return: .dashboard
    )
    
    let authenticatedContext = DecisionTestContext(
      isAuthenticated: true,
      hasSession: true,
      userRole: "user",
      value: 100
    )
    #expect(decision.decide(authenticatedContext) == .dashboard)
    
    let unauthenticatedContext = DecisionTestContext(
      isAuthenticated: false,
      hasSession: false,
      userRole: "guest",
      value: 0
    )
    #expect(decision.decide(unauthenticatedContext) == nil)
  }
  
  @Test("when с замыканием работает корректно")
  func whenConditionWithClosureWorksCorrectly() {
    let decision = Decision<DecisionTestContext, Route>.when(
      { ctx in ctx.isAuthenticated }
    ) { ctx in
      ctx.userRole == "admin" ? .admin : .user
    }
    
    let adminContext = DecisionTestContext(
      isAuthenticated: true,
      hasSession: true,
      userRole: "admin",
      value: 100
    )
    #expect(decision.decide(adminContext) == .admin)
  }
  
  @Test("unless с условием возвращает значение когда условие ложно")
  func unlessConditionReturnsValueWhenFalse() {
    let decision = Decision<DecisionTestContext, Route>.unless(
      { ctx in ctx.isAuthenticated },
      return: .login
    )
    
    // Не аутентифицирован - unless вернет значение
    let unauthenticatedContext = DecisionTestContext(
      isAuthenticated: false,
      hasSession: false,
      userRole: "guest",
      value: 0
    )
    #expect(decision.decide(unauthenticatedContext) == .login)
    
    // Аутентифицирован - unless вернет nil
    let authenticatedContext = DecisionTestContext(
      isAuthenticated: true,
      hasSession: true,
      userRole: "user",
      value: 100
    )
    #expect(decision.decide(authenticatedContext) == nil)
  }
  
  @Test("unless с замыканием работает корректно")
  func unlessConditionWithClosureWorksCorrectly() {
    let decision = Decision<DecisionTestContext, Route>.unless(
      { ctx in ctx.isAuthenticated }
    ) { ctx in
      ctx.hasSession ? .login : .welcome
    }
    
    // Не аутентифицирован, есть сессия - вернет login
    let sessionContext = DecisionTestContext(
      isAuthenticated: false,
      hasSession: true,
      userRole: "guest",
      value: 0
    )
    #expect(decision.decide(sessionContext) == .login)
    
    // Не аутентифицирован, нет сессии - вернет welcome
    let noSessionContext = DecisionTestContext(
      isAuthenticated: false,
      hasSession: false,
      userRole: "guest",
      value: 0
    )
    #expect(decision.decide(noSessionContext) == .welcome)
    
    // Аутентифицирован - вернет nil
    let authenticatedContext = DecisionTestContext(
      isAuthenticated: true,
      hasSession: true,
      userRole: "user",
      value: 100
    )
    #expect(decision.decide(authenticatedContext) == nil)
  }
  
  // MARK: - Цепочки решений
  
  @Test("Цепочка решений работает последовательно")
  func chainedDecisionsWorkSequentially() {
    let decision = Decision<DecisionTestContext, Route> { ctx in
      if ctx.isAuthenticated && ctx.userRole == "admin" {
        return .admin
      }
      if ctx.isAuthenticated {
        return .user
      }
      if ctx.hasSession {
        return .login
      }
      return .welcome
    }
    
    let adminContext = DecisionTestContext(
      isAuthenticated: true,
      hasSession: true,
      userRole: "admin",
      value: 100
    )
    #expect(decision.decide(adminContext) == .admin)
    
    let userContext = DecisionTestContext(
      isAuthenticated: true,
      hasSession: true,
      userRole: "user",
      value: 100
    )
    #expect(decision.decide(userContext) == .user)
    
    let sessionContext = DecisionTestContext(
      isAuthenticated: false,
      hasSession: true,
      userRole: "guest",
      value: 0
    )
    #expect(decision.decide(sessionContext) == .login)
    
    let noContext = DecisionTestContext(
      isAuthenticated: false,
      hasSession: false,
      userRole: "guest",
      value: 0
    )
    #expect(decision.decide(noContext) == .welcome)
  }
  
  // MARK: - FirstMatch с Builder
  
  @Test("firstMatch выбирает первое подходящее решение")
  func firstMatchSelectsFirstMatching() {
    let decision = Decision<DecisionTestContext, Route>.firstMatch {
      Decision { ctx in
        ctx.isAuthenticated && ctx.userRole == "admin" ? .admin : nil
      }
      Decision { ctx in
        ctx.isAuthenticated ? .user : nil
      }
      Decision { ctx in
        ctx.hasSession ? .login : nil
      }
      Decision.constant(.welcome)
    }
    
    let adminContext = DecisionTestContext(
      isAuthenticated: true,
      hasSession: true,
      userRole: "admin",
      value: 100
    )
    #expect(decision.decide(adminContext) == .admin)
    
    let userContext = DecisionTestContext(
      isAuthenticated: true,
      hasSession: true,
      userRole: "user",
      value: 100
    )
    #expect(decision.decide(userContext) == .user)
    
    let sessionContext = DecisionTestContext(
      isAuthenticated: false,
      hasSession: true,
      userRole: "guest",
      value: 0
    )
    #expect(decision.decide(sessionContext) == .login)
    
    let noContext = DecisionTestContext(
      isAuthenticated: false,
      hasSession: false,
      userRole: "guest",
      value: 0
    )
    #expect(decision.decide(noContext) == .welcome)
  }
}
