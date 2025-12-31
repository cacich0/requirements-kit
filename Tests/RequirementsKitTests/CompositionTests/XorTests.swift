import Testing
@testable import RequirementsKit

struct XorContext: Sendable {
  let hasPremium: Bool
  let hasTrialAccess: Bool
  let hasCoupon: Bool
}

@Suite("XOR Composition Tests")
struct XorTests {
  
  @Test("xor() возвращает confirmed когда ровно одно требование выполнено")
  func testXorOneConfirmed() {
    let requirement = Requirement<XorContext>.xor {
      Requirement.require(\.hasPremium)
      Requirement.require(\.hasTrialAccess)
    }
    
    // Только premium
    let onlyPremium = XorContext(hasPremium: true, hasTrialAccess: false, hasCoupon: false)
    #expect(requirement.evaluate(onlyPremium).isConfirmed)
    
    // Только trial
    let onlyTrial = XorContext(hasPremium: false, hasTrialAccess: true, hasCoupon: false)
    #expect(requirement.evaluate(onlyTrial).isConfirmed)
  }
  
  @Test("xor() возвращает failed когда ни одно требование не выполнено")
  func testXorNoneConfirmed() {
    let requirement = Requirement<XorContext>.xor {
      Requirement.require(\.hasPremium)
      Requirement.require(\.hasTrialAccess)
    }
    
    let none = XorContext(hasPremium: false, hasTrialAccess: false, hasCoupon: false)
    let result = requirement.evaluate(none)
    
    #expect(result.isFailed)
    #expect(result.reason?.code == "xor_none")
  }
  
  @Test("xor() возвращает failed когда несколько требований выполнены")
  func testXorMultipleConfirmed() {
    let requirement = Requirement<XorContext>.xor {
      Requirement.require(\.hasPremium)
      Requirement.require(\.hasTrialAccess)
    }
    
    let both = XorContext(hasPremium: true, hasTrialAccess: true, hasCoupon: false)
    let result = requirement.evaluate(both)
    
    #expect(result.isFailed)
    #expect(result.reason?.code == "xor_multiple")
  }
  
  @Test("xor() работает с тремя требованиями")
  func testXorThreeRequirements() {
    let requirement = Requirement<XorContext>.xor {
      Requirement.require(\.hasPremium)
      Requirement.require(\.hasTrialAccess)
      Requirement.require(\.hasCoupon)
    }
    
    // Ровно одно
    let one = XorContext(hasPremium: false, hasTrialAccess: false, hasCoupon: true)
    #expect(requirement.evaluate(one).isConfirmed)
    
    // Два
    let two = XorContext(hasPremium: true, hasTrialAccess: true, hasCoupon: false)
    #expect(requirement.evaluate(two).isFailed)
    
    // Все три
    let three = XorContext(hasPremium: true, hasTrialAccess: true, hasCoupon: true)
    #expect(requirement.evaluate(three).isFailed)
    
    // Ни одного
    let zero = XorContext(hasPremium: false, hasTrialAccess: false, hasCoupon: false)
    #expect(requirement.evaluate(zero).isFailed)
  }
}

