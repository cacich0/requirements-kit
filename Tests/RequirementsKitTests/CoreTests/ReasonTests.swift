import Testing
@testable import RequirementsKit

@Suite("Reason Tests")
struct ReasonTests {
  
  @Test("Reason инициализируется с кодом и сообщением")
  func testReasonInitWithCodeAndMessage() {
    let reason = Reason(code: "auth_required", message: "Требуется авторизация")
    
    #expect(reason.code == "auth_required")
    #expect(reason.message == "Требуется авторизация")
  }
  
  @Test("Reason инициализируется только с сообщением")
  func testReasonInitWithMessageOnly() {
    let reason = Reason(message: "Недостаточно средств")
    
    #expect(reason.code == "requirement_failed")
    #expect(reason.message == "Недостаточно средств")
  }
  
  @Test("Reason поддерживает Hashable")
  func testReasonHashable() {
    let reason1 = Reason(code: "error", message: "Message")
    let reason2 = Reason(code: "error", message: "Message")
    let reason3 = Reason(code: "other", message: "Message")
    
    #expect(reason1 == reason2)
    #expect(reason1 != reason3)
  }
  
  @Test("Reason имеет правильное строковое представление")
  func testReasonDescription() {
    let reason = Reason(code: "test_error", message: "Test message")
    
    #expect(reason.description == "[test_error] Test message")
  }
}

