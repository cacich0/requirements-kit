import Testing
@testable import RequirementsKit

struct StringMacroContext: Sendable {
  let email: String
  let password: String
  let username: String
  let phone: String
  let website: String
  let name: String
  let description: String
}

@Suite("String Validation Macro Tests")
struct StringValidationMacroTests {
  
  // MARK: - #requireMatches
  
  @Test("#requireMatches проходит при соответствии паттерну")
  func testRequireMatchesPasses() {
    let requirement: Requirement<StringMacroContext> = #requireMatches(\.email, pattern: ValidationPattern.email)
    
    let context = StringMacroContext(
      email: "user@example.com",
      password: "",
      username: "",
      phone: "",
      website: "",
      name: "",
      description: ""
    )
    #expect(requirement.evaluate(context).isConfirmed)
  }
  
  @Test("#requireMatches не проходит при несоответствии паттерну")
  func testRequireMatchesFails() {
    let requirement: Requirement<StringMacroContext> = #requireMatches(\.email, pattern: ValidationPattern.email)
    
    let context = StringMacroContext(
      email: "invalid-email",
      password: "",
      username: "",
      phone: "",
      website: "",
      name: "",
      description: ""
    )
    #expect(requirement.evaluate(context).isFailed)
  }
  
  // MARK: - #requireMinLength
  
  @Test("#requireMinLength проходит если длина >= min")
  func testRequireMinLengthPasses() {
    let requirement: Requirement<StringMacroContext> = #requireMinLength(\.username, 3)
    
    let context = StringMacroContext(
      email: "",
      password: "",
      username: "john",
      phone: "",
      website: "",
      name: "",
      description: ""
    )
    #expect(requirement.evaluate(context).isConfirmed)
  }
  
  @Test("#requireMinLength не проходит если длина < min")
  func testRequireMinLengthFails() {
    let requirement: Requirement<StringMacroContext> = #requireMinLength(\.username, 3)
    
    let context = StringMacroContext(
      email: "",
      password: "",
      username: "jo",
      phone: "",
      website: "",
      name: "",
      description: ""
    )
    #expect(requirement.evaluate(context).isFailed)
  }
  
  // MARK: - #requireMaxLength
  
  @Test("#requireMaxLength проходит если длина <= max")
  func testRequireMaxLengthPasses() {
    let requirement: Requirement<StringMacroContext> = #requireMaxLength(\.username, 20)
    
    let context = StringMacroContext(
      email: "",
      password: "",
      username: "john",
      phone: "",
      website: "",
      name: "",
      description: ""
    )
    #expect(requirement.evaluate(context).isConfirmed)
  }
  
  @Test("#requireMaxLength не проходит если длина > max")
  func testRequireMaxLengthFails() {
    let requirement: Requirement<StringMacroContext> = #requireMaxLength(\.username, 20)
    
    let context = StringMacroContext(
      email: "",
      password: "",
      username: "verylongusernamethatexceedslimit",
      phone: "",
      website: "",
      name: "",
      description: ""
    )
    #expect(requirement.evaluate(context).isFailed)
  }
  
  // MARK: - #requireLength
  
  @Test("#requireLength проходит если длина в диапазоне")
  func testRequireLengthPasses() {
    let requirement: Requirement<StringMacroContext> = #requireLength(\.password, in: 8...128)
    
    let context = StringMacroContext(
      email: "",
      password: "password123",
      username: "",
      phone: "",
      website: "",
      name: "",
      description: ""
    )
    #expect(requirement.evaluate(context).isConfirmed)
  }
  
  @Test("#requireLength не проходит если длина вне диапазона")
  func testRequireLengthFails() {
    let requirement: Requirement<StringMacroContext> = #requireLength(\.password, in: 8...128)
    
    let context = StringMacroContext(
      email: "",
      password: "short",
      username: "",
      phone: "",
      website: "",
      name: "",
      description: ""
    )
    #expect(requirement.evaluate(context).isFailed)
  }
  
  // MARK: - #requireNotBlank
  
  @Test("#requireNotBlank проходит для непробельной строки")
  func testRequireNotBlankPasses() {
    let requirement: Requirement<StringMacroContext> = #requireNotBlank(\.name)
    
    let context = StringMacroContext(
      email: "",
      password: "",
      username: "",
      phone: "",
      website: "",
      name: "John Doe",
      description: ""
    )
    #expect(requirement.evaluate(context).isConfirmed)
  }
  
  @Test("#requireNotBlank не проходит для строки с пробелами")
  func testRequireNotBlankFails() {
    let requirement: Requirement<StringMacroContext> = #requireNotBlank(\.name)
    
    let context = StringMacroContext(
      email: "",
      password: "",
      username: "",
      phone: "",
      website: "",
      name: "   ",
      description: ""
    )
    #expect(requirement.evaluate(context).isFailed)
  }
  
  @Test("#requireNotBlank не проходит для пустой строки")
  func testRequireNotBlankFailsEmpty() {
    let requirement: Requirement<StringMacroContext> = #requireNotBlank(\.name)
    
    let context = StringMacroContext(
      email: "",
      password: "",
      username: "",
      phone: "",
      website: "",
      name: "",
      description: ""
    )
    #expect(requirement.evaluate(context).isFailed)
  }
  
  // MARK: - #requireEmail
  
  @Test("#requireEmail проходит для валидного email")
  func testRequireEmailPasses() {
    let requirement: Requirement<StringMacroContext> = #requireEmail(\.email)
    
    let context = StringMacroContext(
      email: "user@example.com",
      password: "",
      username: "",
      phone: "",
      website: "",
      name: "",
      description: ""
    )
    #expect(requirement.evaluate(context).isConfirmed)
  }
  
  @Test("#requireEmail не проходит для невалидного email")
  func testRequireEmailFails() {
    let requirement: Requirement<StringMacroContext> = #requireEmail(\.email)
    
    let context = StringMacroContext(
      email: "not-an-email",
      password: "",
      username: "",
      phone: "",
      website: "",
      name: "",
      description: ""
    )
    #expect(requirement.evaluate(context).isFailed)
  }
  
  // MARK: - #requireURL
  
  @Test("#requireURL проходит для валидного URL")
  func testRequireURLPasses() {
    let requirement: Requirement<StringMacroContext> = #requireURL(\.website)
    
    let context = StringMacroContext(
      email: "",
      password: "",
      username: "",
      phone: "",
      website: "https://example.com",
      name: "",
      description: ""
    )
    #expect(requirement.evaluate(context).isConfirmed)
  }
  
  @Test("#requireURL не проходит для невалидного URL")
  func testRequireURLFails() {
    let requirement: Requirement<StringMacroContext> = #requireURL(\.website)
    
    let context = StringMacroContext(
      email: "",
      password: "",
      username: "",
      phone: "",
      website: "not-a-url",
      name: "",
      description: ""
    )
    #expect(requirement.evaluate(context).isFailed)
  }
  
  // MARK: - #requirePhone
  
  @Test("#requirePhone проходит для валидного международного телефона")
  func testRequirePhonePasses() {
    let requirement: Requirement<StringMacroContext> = #requirePhone(\.phone)
    
    let context = StringMacroContext(
      email: "",
      password: "",
      username: "",
      phone: "+1234567890",
      website: "",
      name: "",
      description: ""
    )
    #expect(requirement.evaluate(context).isConfirmed)
  }
  
  @Test("#requirePhone не проходит для невалидного телефона")
  func testRequirePhoneFails() {
    let requirement: Requirement<StringMacroContext> = #requirePhone(\.phone)
    
    let context = StringMacroContext(
      email: "",
      password: "",
      username: "",
      phone: "123",
      website: "",
      name: "",
      description: ""
    )
    #expect(requirement.evaluate(context).isFailed)
  }
  
  // MARK: - Композиция макросов
  
  @Test("Композиция макросов валидации строк работает")
  func testComposedStringValidation() {
    let requirement: Requirement<StringMacroContext> = #all {
      #requireMinLength(\.username, 3)
      #requireMaxLength(\.username, 20)
      #requireEmail(\.email)
      #requireNotBlank(\.name)
    }
    
    let validContext = StringMacroContext(
      email: "user@example.com",
      password: "",
      username: "john",
      phone: "",
      website: "",
      name: "John Doe",
      description: ""
    )
    #expect(requirement.evaluate(validContext).isConfirmed)
    
    let invalidContext = StringMacroContext(
      email: "invalid",
      password: "",
      username: "jo",
      phone: "",
      website: "",
      name: "",
      description: ""
    )
    #expect(requirement.evaluate(invalidContext).isFailed)
  }
}

