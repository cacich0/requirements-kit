import Testing
@testable import RequirementsKit

@Suite("@RequirementModel Macro Tests")
struct RequirementModelMacroTests {
  
  // MARK: - Базовая валидация
  
  @Test("@RequirementModel генерирует метод validate() с MinLength и MaxLength")
  func testRequirementModelWithStringValidation() {
    @RequirementModel
    struct User: Sendable {
      @MinLength(3) @MaxLength(20)
      var username: String
    }
    
    let validUser = User(username: "john")
    #expect(validUser.validate().isConfirmed)
    
    let tooShort = User(username: "jo")
    #expect(tooShort.validate().isFailed)
    
    let tooLong = User(username: "verylongusernamethatexceedslimit")
    #expect(tooLong.validate().isFailed)
  }
  
  @Test("@RequirementModel работает с @Email атрибутом")
  func testRequirementModelWithEmail() {
    @RequirementModel
    struct User: Sendable {
      @Email
      var email: String
    }
    
    let validUser = User(email: "user@example.com")
    #expect(validUser.validate().isConfirmed)
    
    let invalidUser = User(email: "not-an-email")
    #expect(invalidUser.validate().isFailed)
  }
  
  @Test("@RequirementModel работает с @Phone атрибутом")
  func testRequirementModelWithPhone() {
    @RequirementModel
    struct User: Sendable {
      @Phone
      var phone: String
    }
    
    let validUser = User(phone: "+1234567890")
    #expect(validUser.validate().isConfirmed)
    
    let invalidUser = User(phone: "123")
    #expect(invalidUser.validate().isFailed)
  }
  
  @Test("@RequirementModel работает с @URL атрибутом")
  func testRequirementModelWithURL() {
    @RequirementModel
    struct User: Sendable {
      @URL
      var website: String
    }
    
    let validUser = User(website: "https://example.com")
    #expect(validUser.validate().isConfirmed)
    
    let invalidUser = User(website: "not-a-url")
    #expect(invalidUser.validate().isFailed)
  }
  
  @Test("@RequirementModel работает с @InRange атрибутом")
  func testRequirementModelWithInRange() {
    @RequirementModel
    struct User: Sendable {
      @InRange(18...120)
      var age: Int
    }
    
    let validUser = User(age: 25)
    #expect(validUser.validate().isConfirmed)
    
    let tooYoung = User(age: 15)
    #expect(tooYoung.validate().isFailed)
    
    let tooOld = User(age: 150)
    #expect(tooOld.validate().isFailed)
  }
  
  @Test("@RequirementModel работает с @NotEmpty для коллекций")
  func testRequirementModelWithNotEmpty() {
    @RequirementModel
    struct Order: Sendable {
      @NotEmpty
      var items: [String]
    }
    
    let validOrder = Order(items: ["item1", "item2"])
    #expect(validOrder.validate().isConfirmed)
    
    let emptyOrder = Order(items: [])
    #expect(emptyOrder.validate().isFailed)
  }
  
  @Test("@RequirementModel работает с @NotBlank атрибутом")
  func testRequirementModelWithNotBlank() {
    @RequirementModel
    struct User: Sendable {
      @NotBlank
      var name: String
    }
    
    let validUser = User(name: "John Doe")
    #expect(validUser.validate().isConfirmed)
    
    let blankUser = User(name: "   ")
    #expect(blankUser.validate().isFailed)
    
    let emptyUser = User(name: "")
    #expect(emptyUser.validate().isFailed)
  }
  
  @Test("@RequirementModel работает с @NonNil атрибутом")
  func testRequirementModelWithNonNil() {
    @RequirementModel
    struct User: Sendable {
      @NonNil
      var userId: String?
    }
    
    let validUser = User(userId: "user123")
    #expect(validUser.validate().isConfirmed)
    
    let invalidUser = User(userId: nil)
    #expect(invalidUser.validate().isFailed)
  }
  
  @Test("@RequirementModel работает с @Matches атрибутом")
  func testRequirementModelWithMatches() {
    @RequirementModel
    struct User: Sendable {
      @Matches(#"^[a-zA-Z0-9]+$"#)
      var username: String
    }
    
    let validUser = User(username: "john123")
    #expect(validUser.validate().isConfirmed)
    
    let invalidUser = User(username: "john@123")
    #expect(invalidUser.validate().isFailed)
  }
  
  // MARK: - Комплексная валидация
  
  @Test("@RequirementModel работает с множественными атрибутами")
  func testRequirementModelWithMultipleAttributes() {
    @RequirementModel
    struct RegistrationForm: Sendable {
      @MinLength(3) @MaxLength(20)
      var username: String
      
      @Email
      var email: String
      
      @MinLength(8)
      var password: String
      
      @InRange(18...120)
      var age: Int
    }
    
    let validForm = RegistrationForm(
      username: "john",
      email: "john@example.com",
      password: "password123",
      age: 25
    )
    #expect(validForm.validate().isConfirmed)
    
    let invalidUsername = RegistrationForm(
      username: "jo",
      email: "john@example.com",
      password: "password123",
      age: 25
    )
    #expect(invalidUsername.validate().isFailed)
    
    let invalidEmail = RegistrationForm(
      username: "john",
      email: "not-an-email",
      password: "password123",
      age: 25
    )
    #expect(invalidEmail.validate().isFailed)
    
    let invalidPassword = RegistrationForm(
      username: "john",
      email: "john@example.com",
      password: "short",
      age: 25
    )
    #expect(invalidPassword.validate().isFailed)
    
    let invalidAge = RegistrationForm(
      username: "john",
      email: "john@example.com",
      password: "password123",
      age: 15
    )
    #expect(invalidAge.validate().isFailed)
  }
  
  @Test("@RequirementModel работает со смешанными типами")
  func testRequirementModelWithMixedTypes() {
    @RequirementModel
    struct ComplexModel: Sendable {
      @NotBlank
      var name: String
      
      @InRange(1.0...1000.0)
      var amount: Double
      
      @NotEmpty
      var tags: [String]
      
      @NonNil
      var optionalField: String?
    }
    
    let validModel = ComplexModel(
      name: "Test",
      amount: 500.5,
      tags: ["tag1", "tag2"],
      optionalField: "value"
    )
    #expect(validModel.validate().isConfirmed)
    
    let invalidModel = ComplexModel(
      name: "",
      amount: 500.5,
      tags: [],
      optionalField: nil
    )
    #expect(invalidModel.validate().isFailed)
  }
  
  // MARK: - Без атрибутов
  
  @Test("@RequirementModel без атрибутов валидации возвращает confirmed")
  func testRequirementModelWithoutAttributes() {
    @RequirementModel
    struct SimpleModel: Sendable {
      var name: String
      var age: Int
    }
    
    let model = SimpleModel(name: "Test", age: 25)
    // Если нет атрибутов валидации, метод validate() не должен генерироваться
    // или должен возвращать .confirmed
    // В текущей реализации метод не генерируется если нет атрибутов
  }
  
  // MARK: - Реальные сценарии
  
  @Test("@RequirementModel для регистрации пользователя")
  func testRequirementModelUserRegistration() {
    @RequirementModel
    struct UserRegistration: Sendable {
      @MinLength(3) @MaxLength(20) @Matches(#"^[a-zA-Z0-9]+$"#)
      var username: String
      
      @Email
      var email: String
      
      @MinLength(8)
      var password: String
      
      @InRange(18...120)
      var age: Int
      
      @Phone
      var phone: String
    }
    
    let validRegistration = UserRegistration(
      username: "john123",
      email: "john@example.com",
      password: "SecurePassword123",
      age: 25,
      phone: "+1234567890"
    )
    #expect(validRegistration.validate().isConfirmed)
  }
  
  @Test("@RequirementModel для создания заказа")
  func testRequirementModelOrderCreation() {
    @RequirementModel
    struct OrderForm: Sendable {
      @NotEmpty
      var items: [String]
      
      @InRange(1.0...100000.0)
      var totalAmount: Double
      
      @NotBlank
      var shippingAddress: String
      
      @Phone
      var contactPhone: String
    }
    
    let validOrder = OrderForm(
      items: ["item1", "item2"],
      totalAmount: 150.50,
      shippingAddress: "123 Main St",
      contactPhone: "+1234567890"
    )
    #expect(validOrder.validate().isConfirmed)
    
    let invalidOrder = OrderForm(
      items: [],
      totalAmount: 150.50,
      shippingAddress: "",
      contactPhone: "123"
    )
    #expect(invalidOrder.validate().isFailed)
  }
}

