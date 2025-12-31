import Testing
@testable import RequirementsKit

struct StringContext: Sendable {
  let email: String
  let password: String
  let username: String
  let phone: String
}

@Suite("String Validation Tests")
struct StringValidationTests {
  
  // MARK: - requireNotEmpty (String)
  
  @Test("requireNotEmpty проходит для непустой строки")
  func testRequireNotEmptyPasses() {
    let requirement = Requirement<StringContext>.requireNotEmpty(\.username)
    
    let context = StringContext(email: "", password: "", username: "john", phone: "")
    #expect(requirement.evaluate(context).isConfirmed)
  }
  
  @Test("requireNotEmpty не проходит для пустой строки")
  func testRequireNotEmptyFails() {
    let requirement = Requirement<StringContext>.requireNotEmpty(\.username)
    
    let context = StringContext(email: "", password: "", username: "", phone: "")
    #expect(requirement.evaluate(context).isFailed)
  }
  
  // MARK: - requireNotBlank
  
  @Test("requireNotBlank проходит для непробельной строки")
  func testRequireNotBlankPasses() {
    let requirement = Requirement<StringContext>.requireNotBlank(\.username)
    
    let context = StringContext(email: "", password: "", username: "john", phone: "")
    #expect(requirement.evaluate(context).isConfirmed)
  }
  
  @Test("requireNotBlank не проходит для строки только с пробелами")
  func testRequireNotBlankFails() {
    let requirement = Requirement<StringContext>.requireNotBlank(\.username)
    
    let context = StringContext(email: "", password: "", username: "   ", phone: "")
    #expect(requirement.evaluate(context).isFailed)
  }
  
  @Test("requireNotBlank не проходит для пустой строки")
  func testRequireNotBlankFailsEmpty() {
    let requirement = Requirement<StringContext>.requireNotBlank(\.username)
    
    let context = StringContext(email: "", password: "", username: "", phone: "")
    #expect(requirement.evaluate(context).isFailed)
  }
  
  // MARK: - requireMinLength
  
  @Test("requireMinLength проходит если длина >= min")
  func testRequireMinLengthPasses() {
    let requirement = Requirement<StringContext>.requireMinLength(\.password, minLength: 8)
    
    let context = StringContext(email: "", password: "password123", username: "", phone: "")
    #expect(requirement.evaluate(context).isConfirmed)
  }
  
  @Test("requireMinLength не проходит если длина < min")
  func testRequireMinLengthFails() {
    let requirement = Requirement<StringContext>.requireMinLength(\.password, minLength: 8)
    
    let context = StringContext(email: "", password: "short", username: "", phone: "")
    #expect(requirement.evaluate(context).isFailed)
  }
  
  // MARK: - requireMaxLength
  
  @Test("requireMaxLength проходит если длина <= max")
  func testRequireMaxLengthPasses() {
    let requirement = Requirement<StringContext>.requireMaxLength(\.username, maxLength: 20)
    
    let context = StringContext(email: "", password: "", username: "john", phone: "")
    #expect(requirement.evaluate(context).isConfirmed)
  }
  
  @Test("requireMaxLength не проходит если длина > max")
  func testRequireMaxLengthFails() {
    let requirement = Requirement<StringContext>.requireMaxLength(\.username, maxLength: 5)
    
    let context = StringContext(email: "", password: "", username: "johndoe123", phone: "")
    #expect(requirement.evaluate(context).isFailed)
  }
  
  // MARK: - requireLength
  
  @Test("requireLength проходит если длина в диапазоне")
  func testRequireLengthPasses() {
    let requirement = Requirement<StringContext>.requireLength(\.username, in: 3...20)
    
    let context = StringContext(email: "", password: "", username: "john", phone: "")
    #expect(requirement.evaluate(context).isConfirmed)
  }
  
  @Test("requireLength не проходит если длина вне диапазона")
  func testRequireLengthFails() {
    let requirement = Requirement<StringContext>.requireLength(\.username, in: 5...10)
    
    let shortContext = StringContext(email: "", password: "", username: "ab", phone: "")
    let longContext = StringContext(email: "", password: "", username: "verylongusername123", phone: "")
    
    #expect(requirement.evaluate(shortContext).isFailed)
    #expect(requirement.evaluate(longContext).isFailed)
  }
  
  // MARK: - requireMatches (regex)
  
  @Test("requireMatches проходит для корректного email")
  func testRequireMatchesEmailPasses() {
    let emailPattern = "[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}"
    let requirement = Requirement<StringContext>.requireMatches(\.email, pattern: emailPattern)
    
    let context = StringContext(email: "test@example.com", password: "", username: "", phone: "")
    #expect(requirement.evaluate(context).isConfirmed)
  }
  
  @Test("requireMatches не проходит для некорректного email")
  func testRequireMatchesEmailFails() {
    let emailPattern = "[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}"
    let requirement = Requirement<StringContext>.requireMatches(\.email, pattern: emailPattern)
    
    let context = StringContext(email: "not-an-email", password: "", username: "", phone: "")
    #expect(requirement.evaluate(context).isFailed)
  }
  
  // MARK: - requireContains (String)
  
  @Test("requireContains проходит если подстрока найдена")
  func testRequireContainsPasses() {
    let requirement = Requirement<StringContext>.requireContains(\.email, substring: "@")
    
    let context = StringContext(email: "test@example.com", password: "", username: "", phone: "")
    #expect(requirement.evaluate(context).isConfirmed)
  }
  
  @Test("requireContains не проходит если подстрока не найдена")
  func testRequireContainsFails() {
    let requirement = Requirement<StringContext>.requireContains(\.email, substring: "@")
    
    let context = StringContext(email: "invalid-email", password: "", username: "", phone: "")
    #expect(requirement.evaluate(context).isFailed)
  }
  
  // MARK: - requirePrefix
  
  @Test("requirePrefix проходит если строка начинается с префикса")
  func testRequirePrefixPasses() {
    let requirement = Requirement<StringContext>.requirePrefix(\.phone, prefix: "+7")
    
    let context = StringContext(email: "", password: "", username: "", phone: "+79991234567")
    #expect(requirement.evaluate(context).isConfirmed)
  }
  
  @Test("requirePrefix не проходит если строка не начинается с префикса")
  func testRequirePrefixFails() {
    let requirement = Requirement<StringContext>.requirePrefix(\.phone, prefix: "+7")
    
    let context = StringContext(email: "", password: "", username: "", phone: "89991234567")
    #expect(requirement.evaluate(context).isFailed)
  }
  
  // MARK: - requireSuffix
  
  @Test("requireSuffix проходит если строка заканчивается суффиксом")
  func testRequireSuffixPasses() {
    let requirement = Requirement<StringContext>.requireSuffix(\.email, suffix: ".com")
    
    let context = StringContext(email: "test@example.com", password: "", username: "", phone: "")
    #expect(requirement.evaluate(context).isConfirmed)
  }
  
  @Test("requireSuffix не проходит если строка не заканчивается суффиксом")
  func testRequireSuffixFails() {
    let requirement = Requirement<StringContext>.requireSuffix(\.email, suffix: ".com")
    
    let context = StringContext(email: "test@example.org", password: "", username: "", phone: "")
    #expect(requirement.evaluate(context).isFailed)
  }
  
  // MARK: - ValidationPattern constants
  
  @Test("ValidationPattern.email работает корректно")
  func testValidationPatternEmail() {
    let requirement = Requirement<StringContext>.requireMatches(\.email, pattern: ValidationPattern.email)
    
    let valid = StringContext(email: "test@example.com", password: "", username: "", phone: "")
    let invalid = StringContext(email: "not-email", password: "", username: "", phone: "")
    
    #expect(requirement.evaluate(valid).isConfirmed)
    #expect(requirement.evaluate(invalid).isFailed)
  }
}

