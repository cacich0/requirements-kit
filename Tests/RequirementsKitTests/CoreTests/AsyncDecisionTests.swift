import Testing
@testable import RequirementsKit

// MARK: - Async Decision Tests

@Suite("AsyncDecision Tests")
struct AsyncDecisionTests {
  
  // MARK: - Базовые тесты
  
  @Test("AsyncDecision возвращает значение")
  func asyncDecisionReturnsValue() async throws {
    let decision = AsyncDecision<DecisionTestContext, Route> { ctx in
      // Симуляция async операции
      try await Task.sleep(nanoseconds: 10_000_000) // 0.01 секунды
      return ctx.isAuthenticated ? .dashboard : nil
    }
    
    let authenticatedContext = DecisionTestContext(
      isAuthenticated: true,
      hasSession: true,
      userRole: "user",
      value: 100
    )
    
    let result = try await decision.decide(authenticatedContext)
    #expect(result == .dashboard)
  }
  
  @Test("AsyncDecision возвращает nil")
  func asyncDecisionReturnsNil() async throws {
    let decision = AsyncDecision<DecisionTestContext, Route> { ctx in
      try await Task.sleep(nanoseconds: 10_000_000)
      return ctx.isAuthenticated ? .dashboard : nil
    }
    
    let unauthenticatedContext = DecisionTestContext(
      isAuthenticated: false,
      hasSession: false,
      userRole: "guest",
      value: 0
    )
    
    let result = try await decision.decide(unauthenticatedContext)
    #expect(result == nil)
  }
  
  @Test("AsyncDecision.constant возвращает константное значение")
  func asyncConstantDecision() async throws {
    let decision = AsyncDecision<DecisionTestContext, Route>.constant(.welcome)
    
    let context = DecisionTestContext(
      isAuthenticated: false,
      hasSession: false,
      userRole: "guest",
      value: 0
    )
    
    let result = try await decision.decide(context)
    #expect(result == .welcome)
  }
  
  @Test("AsyncDecision.never всегда возвращает nil")
  func asyncNeverDecision() async throws {
    let decision = AsyncDecision<DecisionTestContext, Route>.never
    
    let context = DecisionTestContext(
      isAuthenticated: true,
      hasSession: true,
      userRole: "admin",
      value: 100
    )
    
    let result = try await decision.decide(context)
    #expect(result == nil)
  }
  
  // MARK: - Конверсия из синхронного
  
  @Test("AsyncDecision.from конвертирует синхронное решение")
  func fromSyncDecision() async throws {
    let syncDecision = Decision<DecisionTestContext, Route> { ctx in
      ctx.isAuthenticated ? .dashboard : .welcome
    }
    
    let asyncDecision = AsyncDecision<DecisionTestContext, Route>.from(syncDecision)
    
    let context = DecisionTestContext(
      isAuthenticated: true,
      hasSession: true,
      userRole: "user",
      value: 100
    )
    
    let result = try await asyncDecision.decide(context)
    #expect(result == .dashboard)
  }
  
  // MARK: - Композиция с fallback
  
  @Test("fallback с AsyncDecision работает корректно")
  func asyncFallbackWithDecision() async throws {
    let primary = AsyncDecision<DecisionTestContext, Route> { ctx in
      try await Task.sleep(nanoseconds: 10_000_000)
      return ctx.isAuthenticated ? .dashboard : nil
    }
    
    let fallback = AsyncDecision<DecisionTestContext, Route> { ctx in
      try await Task.sleep(nanoseconds: 10_000_000)
      return ctx.hasSession ? .login : .welcome
    }
    
    let combined = primary.fallback(fallback)
    
    // Тест 1: primary возвращает значение
    let authenticatedContext = DecisionTestContext(
      isAuthenticated: true,
      hasSession: true,
      userRole: "user",
      value: 100
    )
    let result1 = try await combined.decide(authenticatedContext)
    #expect(result1 == .dashboard)
    
    // Тест 2: primary возвращает nil, fallback возвращает значение
    let sessionContext = DecisionTestContext(
      isAuthenticated: false,
      hasSession: true,
      userRole: "guest",
      value: 0
    )
    let result2 = try await combined.decide(sessionContext)
    #expect(result2 == .login)
    
    // Тест 3: оба возвращают nil
    let noContext = DecisionTestContext(
      isAuthenticated: false,
      hasSession: false,
      userRole: "guest",
      value: 0
    )
    let result3 = try await combined.decide(noContext)
    #expect(result3 == .welcome)
  }
  
  @Test("fallbackDefault возвращает значение по умолчанию")
  func asyncFallbackDefault() async throws {
    let decision = AsyncDecision<DecisionTestContext, Route> { ctx in
      try await Task.sleep(nanoseconds: 10_000_000)
      return ctx.isAuthenticated ? .dashboard : nil
    }
    
    let withDefault = decision.fallbackDefault(.welcome)
    
    let unauthenticatedContext = DecisionTestContext(
      isAuthenticated: false,
      hasSession: false,
      userRole: "guest",
      value: 0
    )
    
    let result = try await withDefault.decide(unauthenticatedContext)
    #expect(result == .welcome)
  }
  
  // MARK: - Трансформации
  
  @Test("map преобразует результат")
  func asyncMapTransformsResult() async throws {
    let decision = AsyncDecision<DecisionTestContext, Int> { ctx in
      try await Task.sleep(nanoseconds: 10_000_000)
      return ctx.value
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
    
    let result = try await mapped.decide(context)
    #expect(result == "Value: 42")
  }
  
  @Test("asyncMap с асинхронной трансформацией работает")
  func asyncMapWithAsyncTransform() async throws {
    let decision = AsyncDecision<DecisionTestContext, Int> { ctx in
      try await Task.sleep(nanoseconds: 10_000_000)
      return ctx.value
    }
    
    let mapped = decision.asyncMap { value in
      try await Task.sleep(nanoseconds: 10_000_000)
      return "Value: \(value)"
    }
    
    let context = DecisionTestContext(
      isAuthenticated: true,
      hasSession: true,
      userRole: "user",
      value: 42
    )
    
    let result = try await mapped.decide(context)
    #expect(result == "Value: 42")
  }
  
  @Test("compactMap фильтрует и преобразует результат")
  func asyncCompactMapFiltersAndTransforms() async throws {
    let decision = AsyncDecision<DecisionTestContext, Int> { ctx in
      try await Task.sleep(nanoseconds: 10_000_000)
      return ctx.value
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
    let result1 = try await mapped.decide(lowContext)
    #expect(result1 == nil)
    
    let highContext = DecisionTestContext(
      isAuthenticated: true,
      hasSession: true,
      userRole: "user",
      value: 100
    )
    let result2 = try await mapped.decide(highContext)
    #expect(result2 == "High: 100")
  }
  
  @Test("filter фильтрует результат по условию")
  func asyncFilterByPredicate() async throws {
    let decision = AsyncDecision<DecisionTestContext, Route> { ctx in
      try await Task.sleep(nanoseconds: 10_000_000)
      return ctx.isAuthenticated ? .dashboard : nil
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
    
    let result = try await filtered.decide(context)
    #expect(result == .dashboard)
  }
  
  @Test("asyncFilter с асинхронным предикатом работает")
  func asyncFilterWithAsyncPredicate() async throws {
    let decision = AsyncDecision<DecisionTestContext, Route> { ctx in
      try await Task.sleep(nanoseconds: 10_000_000)
      return .dashboard
    }
    
    let filtered = decision.asyncFilter { route in
      try await Task.sleep(nanoseconds: 10_000_000)
      return route == .dashboard
    }
    
    let context = DecisionTestContext(
      isAuthenticated: true,
      hasSession: true,
      userRole: "user",
      value: 100
    )
    
    let result = try await filtered.decide(context)
    #expect(result == .dashboard)
  }
  
  // MARK: - Интеграция с AsyncRequirements
  
  @Test("when с AsyncRequirement возвращает значение при выполнении")
  func whenAsyncRequirementReturnsValueOnSuccess() async throws {
    let requirement = AsyncRequirement<DecisionTestContext> { ctx in
      try await Task.sleep(nanoseconds: 10_000_000)
      return ctx.isAuthenticated ? .confirmed : .failed(reason: Reason(message: "Not authenticated"))
    }
    
    let decision = AsyncDecision<DecisionTestContext, Route>.when(requirement, return: .dashboard)
    
    let authenticatedContext = DecisionTestContext(
      isAuthenticated: true,
      hasSession: true,
      userRole: "user",
      value: 100
    )
    let result1 = try await decision.decide(authenticatedContext)
    #expect(result1 == .dashboard)
    
    let unauthenticatedContext = DecisionTestContext(
      isAuthenticated: false,
      hasSession: false,
      userRole: "guest",
      value: 0
    )
    let result2 = try await decision.decide(unauthenticatedContext)
    #expect(result2 == nil)
  }
  
  @Test("when с AsyncRequirement и замыканием работает")
  func whenAsyncRequirementWithAsyncClosure() async throws {
    let requirement = AsyncRequirement<DecisionTestContext> { ctx in
      try await Task.sleep(nanoseconds: 10_000_000)
      return ctx.isAuthenticated ? .confirmed : .failed(reason: Reason(message: "Not authenticated"))
    }
    
    let decision = AsyncDecision<DecisionTestContext, Route>.when(requirement) { ctx in
      try await Task.sleep(nanoseconds: 10_000_000)
      return ctx.userRole == "admin" ? .admin : .user
    }
    
    let adminContext = DecisionTestContext(
      isAuthenticated: true,
      hasSession: true,
      userRole: "admin",
      value: 100
    )
    let result = try await decision.decide(adminContext)
    #expect(result == .admin)
  }
  
  @Test("when с синхронным Requirement работает")
  func whenSyncRequirementWorks() async throws {
    let requirement = Requirement<DecisionTestContext> { ctx in
      ctx.isAuthenticated ? .confirmed : .failed(reason: Reason(message: "Not authenticated"))
    }
    
    let decision = AsyncDecision<DecisionTestContext, Route>.when(requirement, return: .dashboard)
    
    let authenticatedContext = DecisionTestContext(
      isAuthenticated: true,
      hasSession: true,
      userRole: "user",
      value: 100
    )
    let result = try await decision.decide(authenticatedContext)
    #expect(result == .dashboard)
  }
  
  // MARK: - Условная логика
  
  @Test("when с асинхронным условием возвращает значение")
  func asyncWhenConditionReturnsValue() async throws {
    let decision = AsyncDecision<DecisionTestContext, Route>.when(
      { ctx in
        try await Task.sleep(nanoseconds: 10_000_000)
        return ctx.isAuthenticated
      },
      return: .dashboard
    )
    
    let authenticatedContext = DecisionTestContext(
      isAuthenticated: true,
      hasSession: true,
      userRole: "user",
      value: 100
    )
    let result1 = try await decision.decide(authenticatedContext)
    #expect(result1 == .dashboard)
    
    let unauthenticatedContext = DecisionTestContext(
      isAuthenticated: false,
      hasSession: false,
      userRole: "guest",
      value: 0
    )
    let result2 = try await decision.decide(unauthenticatedContext)
    #expect(result2 == nil)
  }
  
  @Test("when с асинхронным замыканием работает")
  func asyncWhenConditionWithAsyncClosure() async throws {
    let decision = AsyncDecision<DecisionTestContext, Route>.when(
      { ctx in
        try await Task.sleep(nanoseconds: 10_000_000)
        return ctx.isAuthenticated
      }
    ) { ctx in
      try await Task.sleep(nanoseconds: 10_000_000)
      return ctx.userRole == "admin" ? .admin : .user
    }
    
    let adminContext = DecisionTestContext(
      isAuthenticated: true,
      hasSession: true,
      userRole: "admin",
      value: 100
    )
    let result = try await decision.decide(adminContext)
    #expect(result == .admin)
  }
  
  @Test("unless с асинхронным условием возвращает значение когда условие ложно")
  func asyncUnlessConditionReturnsValueWhenFalse() async throws {
    let decision = AsyncDecision<DecisionTestContext, Route>.unless(
      { ctx in
        try await Task.sleep(nanoseconds: 10_000_000)
        return ctx.isAuthenticated
      },
      return: .login
    )
    
    // Не аутентифицирован - unless вернет значение
    let unauthenticatedContext = DecisionTestContext(
      isAuthenticated: false,
      hasSession: false,
      userRole: "guest",
      value: 0
    )
    let result1 = try await decision.decide(unauthenticatedContext)
    #expect(result1 == .login)
    
    // Аутентифицирован - unless вернет nil
    let authenticatedContext = DecisionTestContext(
      isAuthenticated: true,
      hasSession: true,
      userRole: "user",
      value: 100
    )
    let result2 = try await decision.decide(authenticatedContext)
    #expect(result2 == nil)
  }
  
  @Test("unless с асинхронным замыканием работает корректно")
  func asyncUnlessConditionWithAsyncClosure() async throws {
    let decision = AsyncDecision<DecisionTestContext, Route>.unless(
      { ctx in
        try await Task.sleep(nanoseconds: 10_000_000)
        return ctx.isAuthenticated
      }
    ) { ctx in
      try await Task.sleep(nanoseconds: 10_000_000)
      return ctx.hasSession ? .login : .welcome
    }
    
    // Не аутентифицирован, есть сессия - вернет login
    let sessionContext = DecisionTestContext(
      isAuthenticated: false,
      hasSession: true,
      userRole: "guest",
      value: 0
    )
    let result1 = try await decision.decide(sessionContext)
    #expect(result1 == .login)
    
    // Не аутентифицирован, нет сессии - вернет welcome
    let noSessionContext = DecisionTestContext(
      isAuthenticated: false,
      hasSession: false,
      userRole: "guest",
      value: 0
    )
    let result2 = try await decision.decide(noSessionContext)
    #expect(result2 == .welcome)
    
    // Аутентифицирован - вернет nil
    let authenticatedContext = DecisionTestContext(
      isAuthenticated: true,
      hasSession: true,
      userRole: "user",
      value: 100
    )
    let result3 = try await decision.decide(authenticatedContext)
    #expect(result3 == nil)
  }
  
  // MARK: - FirstMatch с Builder
  
  @Test("firstMatch выбирает первое подходящее решение")
  func asyncFirstMatchSelectsFirstMatching() async throws {
    let decision = AsyncDecision<DecisionTestContext, Route>.firstMatch {
      AsyncDecision { ctx in
        try await Task.sleep(nanoseconds: 10_000_000)
        return ctx.isAuthenticated && ctx.userRole == "admin" ? .admin : nil
      }
      AsyncDecision { ctx in
        try await Task.sleep(nanoseconds: 10_000_000)
        return ctx.isAuthenticated ? .user : nil
      }
      AsyncDecision { ctx in
        try await Task.sleep(nanoseconds: 10_000_000)
        return ctx.hasSession ? .login : nil
      }
      AsyncDecision.constant(.welcome)
    }
    
    let adminContext = DecisionTestContext(
      isAuthenticated: true,
      hasSession: true,
      userRole: "admin",
      value: 100
    )
    let result1 = try await decision.decide(adminContext)
    #expect(result1 == .admin)
    
    let userContext = DecisionTestContext(
      isAuthenticated: true,
      hasSession: true,
      userRole: "user",
      value: 100
    )
    let result2 = try await decision.decide(userContext)
    #expect(result2 == .user)
    
    let sessionContext = DecisionTestContext(
      isAuthenticated: false,
      hasSession: true,
      userRole: "guest",
      value: 0
    )
    let result3 = try await decision.decide(sessionContext)
    #expect(result3 == .login)
    
    let noContext = DecisionTestContext(
      isAuthenticated: false,
      hasSession: false,
      userRole: "guest",
      value: 0
    )
    let result4 = try await decision.decide(noContext)
    #expect(result4 == .welcome)
  }
  
  // MARK: - Таймауты
  
  @available(macOS 13.0, iOS 16.0, watchOS 9.0, tvOS 16.0, *)
  @Test("withTimeout возвращает nil при превышении времени")
  func timeoutReturnsNilOnExpiry() async throws {
    let slowDecision = AsyncDecision<DecisionTestContext, Route> { ctx in
      try await Task.sleep(for: .seconds(2))
      return .dashboard
    }
    
    let withTimeout = AsyncDecision<DecisionTestContext, Route>.withTimeout(
      seconds: 0.1,
      slowDecision
    )
    
    let context = DecisionTestContext(
      isAuthenticated: true,
      hasSession: true,
      userRole: "user",
      value: 100
    )
    
    let result = try await withTimeout.decide(context)
    #expect(result == nil) // Должен вернуть nil из-за таймаута
  }
  
  @available(macOS 13.0, iOS 16.0, watchOS 9.0, tvOS 16.0, *)
  @Test("withTimeout возвращает результат при успешном выполнении")
  func timeoutReturnsResultOnSuccess() async throws {
    let fastDecision = AsyncDecision<DecisionTestContext, Route> { ctx in
      try await Task.sleep(for: .milliseconds(10))
      return .dashboard
    }
    
    let withTimeout = AsyncDecision<DecisionTestContext, Route>.withTimeout(
      seconds: 1.0,
      fastDecision
    )
    
    let context = DecisionTestContext(
      isAuthenticated: true,
      hasSession: true,
      userRole: "user",
      value: 100
    )
    
    let result = try await withTimeout.decide(context)
    #expect(result == .dashboard)
  }
}
