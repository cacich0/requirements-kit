import Testing
@testable import RequirementsKit

// MARK: - Custom FailureReason для тестов

enum TestAuthFailure: FailureReason {
  case notLoggedIn
  case sessionExpired
  case insufficientPermissions
  
  var code: String {
    switch self {
    case .notLoggedIn: return "auth.not_logged_in"
    case .sessionExpired: return "auth.session_expired"
    case .insufficientPermissions: return "auth.insufficient_permissions"
    }
  }
  
  var message: String {
    switch self {
    case .notLoggedIn: return "Please log in"
    case .sessionExpired: return "Session has expired"
    case .insufficientPermissions: return "You don't have permission"
    }
  }
  
  var severity: Severity {
    switch self {
    case .notLoggedIn: return .error
    case .sessionExpired: return .warning
    case .insufficientPermissions: return .critical
    }
  }
}

struct FailureReasonContext: Sendable {
  let isLoggedIn: Bool
  let isSessionValid: Bool
  let hasPermission: Bool
}

@Suite("FailureReason Tests")
struct FailureReasonTests {
  
  // MARK: - FailureReason protocol
  
  @Test("Custom FailureReason conformance работает")
  func testCustomFailureReason() {
    let failure = TestAuthFailure.notLoggedIn
    
    #expect(failure.code == "auth.not_logged_in")
    #expect(failure.message == "Please log in")
    #expect(failure.severity == .error)
  }
  
  @Test("Reason соответствует FailureReason")
  func testReasonConformsToFailureReason() {
    let reason = Reason(code: "test", message: "Test message")
    
    #expect(reason.code == "test")
    #expect(reason.message == "Test message")
    #expect(reason.severity == .error)
  }
  
  // MARK: - Severity
  
  @Test("Severity сравнение работает корректно")
  func testSeverityComparison() {
    #expect(Severity.info < Severity.warning)
    #expect(Severity.warning < Severity.error)
    #expect(Severity.error < Severity.critical)
    #expect(Severity.info < Severity.critical)
  }
  
  @Test("Severity raw values корректны")
  func testSeverityRawValues() {
    #expect(Severity.info.rawValue == 0)
    #expect(Severity.warning.rawValue == 1)
    #expect(Severity.error.rawValue == 2)
    #expect(Severity.critical.rawValue == 3)
  }
  
  // MARK: - TypedEvaluation
  
  @Test("TypedEvaluation.confirmed работает")
  func testTypedEvaluationConfirmed() {
    let evaluation: TypedEvaluation<TestAuthFailure> = .confirmed
    
    #expect(evaluation.isConfirmed)
    #expect(!evaluation.isFailed)
    #expect(evaluation.reason == nil)
  }
  
  @Test("TypedEvaluation.failed работает")
  func testTypedEvaluationFailed() {
    let evaluation: TypedEvaluation<TestAuthFailure> = .failed(reason: .notLoggedIn)
    
    #expect(!evaluation.isConfirmed)
    #expect(evaluation.isFailed)
    #expect(evaluation.reason == .notLoggedIn)
  }
  
  @Test("TypedEvaluation.toEvaluation() конвертирует корректно")
  func testTypedEvaluationToEvaluation() {
    let typed: TypedEvaluation<TestAuthFailure> = .failed(reason: .sessionExpired)
    let standard = typed.toEvaluation()
    
    #expect(standard.isFailed)
    #expect(standard.reason?.code == "auth.session_expired")
    #expect(standard.reason?.message == "Session has expired")
  }
  
  // MARK: - TypedRequirement
  
  @Test("TypedRequirement.always работает")
  func testTypedRequirementAlways() {
    let requirement = TypedRequirement<FailureReasonContext, TestAuthFailure>.always
    let context = FailureReasonContext(isLoggedIn: false, isSessionValid: false, hasPermission: false)
    
    let result = requirement.evaluate(context)
    #expect(result.isConfirmed)
  }
  
  @Test("TypedRequirement.never работает")
  func testTypedRequirementNever() {
    let requirement = TypedRequirement<FailureReasonContext, TestAuthFailure>.never(reason: .notLoggedIn)
    let context = FailureReasonContext(isLoggedIn: true, isSessionValid: true, hasPermission: true)
    
    let result = requirement.evaluate(context)
    #expect(result.isFailed)
    #expect(result.reason == .notLoggedIn)
  }
  
  @Test("TypedRequirement.require с KeyPath работает")
  func testTypedRequirementRequire() {
    let requirement = TypedRequirement<FailureReasonContext, TestAuthFailure>.require(
      \.isLoggedIn,
      or: .notLoggedIn
    )
    
    let loggedIn = FailureReasonContext(isLoggedIn: true, isSessionValid: true, hasPermission: true)
    let loggedOut = FailureReasonContext(isLoggedIn: false, isSessionValid: true, hasPermission: true)
    
    #expect(requirement.evaluate(loggedIn).isConfirmed)
    #expect(requirement.evaluate(loggedOut).isFailed)
    #expect(requirement.evaluate(loggedOut).reason == .notLoggedIn)
  }
  
  @Test("TypedRequirement.predicate работает")
  func testTypedRequirementPredicate() {
    let requirement = TypedRequirement<FailureReasonContext, TestAuthFailure>.predicate(
      { $0.isLoggedIn && $0.isSessionValid },
      or: .sessionExpired
    )
    
    let valid = FailureReasonContext(isLoggedIn: true, isSessionValid: true, hasPermission: true)
    let invalid = FailureReasonContext(isLoggedIn: true, isSessionValid: false, hasPermission: true)
    
    #expect(requirement.evaluate(valid).isConfirmed)
    #expect(requirement.evaluate(invalid).reason == .sessionExpired)
  }
  
  @Test("TypedRequirement.toRequirement() конвертирует корректно")
  func testTypedRequirementToRequirement() {
    let typed = TypedRequirement<FailureReasonContext, TestAuthFailure>.require(
      \.isLoggedIn,
      or: .notLoggedIn
    )
    let standard = typed.toRequirement()
    
    let context = FailureReasonContext(isLoggedIn: false, isSessionValid: true, hasPermission: true)
    let result = standard.evaluate(context)
    
    #expect(result.isFailed)
    #expect(result.reason?.code == "auth.not_logged_in")
  }
  
  // MARK: - becauseTyped()
  
  @Test("becauseTyped() устанавливает типизированную причину")
  func testBecauseTyped() {
    let requirement = Requirement<FailureReasonContext>
      .require(\.hasPermission)
      .becauseTyped(TestAuthFailure.insufficientPermissions)
    
    let context = FailureReasonContext(isLoggedIn: true, isSessionValid: true, hasPermission: false)
    let result = requirement.evaluate(context)
    
    #expect(result.isFailed)
    #expect(result.reason?.code == "auth.insufficient_permissions")
    #expect(result.reason?.message == "You don't have permission")
  }
  
  // MARK: - CommonFailure
  
  @Test("CommonFailure cases работают")
  func testCommonFailure() {
    let notMet = CommonFailure.notMet
    let conditionFailed = CommonFailure.conditionFailed("test condition")
    let outOfRange = CommonFailure.valueOutOfRange
    
    #expect(notMet.code == "requirement.not_met")
    #expect(conditionFailed.message == "Condition failed: test condition")
    #expect(outOfRange.code == "requirement.value_out_of_range")
  }
}

