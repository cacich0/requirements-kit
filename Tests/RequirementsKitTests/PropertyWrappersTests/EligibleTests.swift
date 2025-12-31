import Testing
@testable import RequirementsKit

struct EligibleTestContext: Sendable {
  let isAllowed: Bool
  let value: Int
}

@Suite("Eligible Property Wrapper Tests")
struct EligibleTests {
  
  @Test("Eligible возвращает true когда требование выполнено")
  func testEligibleTrue() {
    let context = EligibleTestContext(isAllowed: true, value: 100)
    let requirement = Requirement<EligibleTestContext>.require(\.isAllowed)
    
    @Eligible(by: requirement, context: context)
    var isEligible: Bool
    
    #expect(isEligible == true)
  }
  
  @Test("Eligible возвращает false когда требование не выполнено")
  func testEligibleFalse() {
    let context = EligibleTestContext(isAllowed: false, value: 100)
    let requirement = Requirement<EligibleTestContext>.require(\.isAllowed)
    
    @Eligible(by: requirement, context: context)
    var isEligible: Bool
    
    #expect(isEligible == false)
  }
  
  @Test("Eligible работает со сложными требованиями")
  func testEligibleComplexRequirement() {
    let context = EligibleTestContext(isAllowed: true, value: 150)
    let requirement = Requirement<EligibleTestContext>.all {
      #require(\.isAllowed)
      #require(\.value, greaterThan: 100)
    }
    
    @Eligible(by: requirement, context: context)
    var isEligible: Bool
    
    #expect(isEligible == true)
  }
  
  @Test("Eligible работает с композицией ANY")
  func testEligibleAnyComposition() {
    let context = EligibleTestContext(isAllowed: false, value: 150)
    let requirement = Requirement<EligibleTestContext>.any {
      #require(\.isAllowed)
      #require(\.value, greaterThan: 100)
    }
    
    @Eligible(by: requirement, context: context)
    var isEligible: Bool
    
    #expect(isEligible == true)
  }
}

