import Testing
@testable import RequirementsKit

@Suite("Eligibility Property Wrapper Tests")
struct EligibilityTests {
  
  @Test("Eligibility возвращает isAllowed = true когда требование выполнено")
  func testEligibilityAllowed() {
    let context = EligibleTestContext(isAllowed: true, value: 100)
    let requirement = Requirement<EligibleTestContext>.require(\.isAllowed)
    
    @Eligibility(by: requirement, context: context)
    var eligibility
    
    #expect(eligibility.isAllowed == true)
    #expect(eligibility.isDenied == false)
    #expect(eligibility.reason == nil)
  }
  
  @Test("Eligibility возвращает isAllowed = false и причину когда требование не выполнено")
  func testEligibilityDenied() {
    let context = EligibleTestContext(isAllowed: false, value: 100)
    let requirement = Requirement<EligibleTestContext>
      .require(\.isAllowed)
      .because("Access denied")
    
    @Eligibility(by: requirement, context: context)
    var eligibility
    
    #expect(eligibility.isAllowed == false)
    #expect(eligibility.isDenied == true)
    #expect(eligibility.reason?.message == "Access denied")
  }
  
  @Test("Eligibility projectedValue работает корректно")
  func testEligibilityProjectedValue() {
    let context = EligibleTestContext(isAllowed: true, value: 100)
    let requirement = Requirement<EligibleTestContext>.require(\.isAllowed)
    
    @Eligibility(by: requirement, context: context)
    var eligibility
    
    #expect($eligibility.isAllowed == true)
  }
  
  @Test("Eligibility работает со сложными требованиями")
  func testEligibilityComplexRequirement() {
    let context = EligibleTestContext(isAllowed: true, value: 50)
    let requirement = Requirement<EligibleTestContext>.all {
      #require(\.isAllowed)
      #require(\.value, greaterThan: 100).because("Insufficient balance")
    }
    
    @Eligibility(by: requirement, context: context)
    var eligibility
    
    #expect(eligibility.isAllowed == false)
    #expect(eligibility.reason?.message == "Insufficient balance")
  }
  
  @Test("Eligibility.allFailures возвращает все причины отказа")
  func testEligibilityAllFailures() {
    let context = EligibleTestContext(isAllowed: false, value: 100)
    let requirement = Requirement<EligibleTestContext>
      .require(\.isAllowed)
      .because("Not allowed")
    
    @Eligibility(by: requirement, context: context)
    var eligibility
    
    let failures = eligibility.allFailures
    #expect(failures.count == 1)
    #expect(failures[0].message == "Not allowed")
  }
}

