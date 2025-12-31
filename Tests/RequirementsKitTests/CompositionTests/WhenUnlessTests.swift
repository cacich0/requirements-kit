import Testing
@testable import RequirementsKit

struct ConditionalContext: Sendable {
  let featureEnabled: Bool
  let isBetaTester: Bool
  let isRestricted: Bool
  let canTrade: Bool
}

@Suite("When/Unless Composition Tests")
struct WhenUnlessTests {
  
  // MARK: - when()
  
  @Test("when() проверяет требования только если условие истинно")
  func testWhenConditionTrue() {
    let requirement = Requirement<ConditionalContext>.when(\.featureEnabled) {
      Requirement.require(\.isBetaTester)
    }
    
    // Условие true, isBetaTester true -> confirmed
    let context1 = ConditionalContext(featureEnabled: true, isBetaTester: true, isRestricted: false, canTrade: true)
    #expect(requirement.evaluate(context1).isConfirmed)
    
    // Условие true, isBetaTester false -> failed
    let context2 = ConditionalContext(featureEnabled: true, isBetaTester: false, isRestricted: false, canTrade: true)
    #expect(requirement.evaluate(context2).isFailed)
  }
  
  @Test("when() пропускает проверку если условие ложно")
  func testWhenConditionFalse() {
    let requirement = Requirement<ConditionalContext>.when(\.featureEnabled) {
      Requirement.require(\.isBetaTester)
    }
    
    // Условие false -> всегда confirmed (независимо от isBetaTester)
    let context = ConditionalContext(featureEnabled: false, isBetaTester: false, isRestricted: false, canTrade: true)
    #expect(requirement.evaluate(context).isConfirmed)
  }
  
  @Test("when() работает с несколькими требованиями")
  func testWhenMultipleRequirements() {
    let requirement = Requirement<ConditionalContext>.when(\.featureEnabled) {
      Requirement.require(\.isBetaTester)
      Requirement.require(\.canTrade)
    }
    
    let allTrue = ConditionalContext(featureEnabled: true, isBetaTester: true, isRestricted: false, canTrade: true)
    let oneFalse = ConditionalContext(featureEnabled: true, isBetaTester: true, isRestricted: false, canTrade: false)
    
    #expect(requirement.evaluate(allTrue).isConfirmed)
    #expect(requirement.evaluate(oneFalse).isFailed)
  }
  
  // MARK: - unless()
  
  @Test("unless() проверяет требования только если условие ложно")
  func testUnlessConditionFalse() {
    let requirement = Requirement<ConditionalContext>.unless(\.isRestricted) {
      Requirement.require(\.canTrade)
    }
    
    // Условие false (не ограничен), canTrade true -> confirmed
    let context1 = ConditionalContext(featureEnabled: true, isBetaTester: true, isRestricted: false, canTrade: true)
    #expect(requirement.evaluate(context1).isConfirmed)
    
    // Условие false, canTrade false -> failed
    let context2 = ConditionalContext(featureEnabled: true, isBetaTester: true, isRestricted: false, canTrade: false)
    #expect(requirement.evaluate(context2).isFailed)
  }
  
  @Test("unless() пропускает проверку если условие истинно")
  func testUnlessConditionTrue() {
    let requirement = Requirement<ConditionalContext>.unless(\.isRestricted) {
      Requirement.require(\.canTrade)
    }
    
    // Условие true (ограничен) -> всегда confirmed (пропускаем проверку)
    let context = ConditionalContext(featureEnabled: true, isBetaTester: true, isRestricted: true, canTrade: false)
    #expect(requirement.evaluate(context).isConfirmed)
  }
  
  // MARK: - warn()
  
  @Test("warn() всегда возвращает confirmed")
  func testWarnAlwaysConfirmed() {
    let requirement = Requirement<ConditionalContext>.warn(\.isBetaTester)
    
    let betaTester = ConditionalContext(featureEnabled: true, isBetaTester: true, isRestricted: false, canTrade: true)
    let notBetaTester = ConditionalContext(featureEnabled: true, isBetaTester: false, isRestricted: false, canTrade: true)
    
    // warn() всегда confirmed (мягкое требование)
    #expect(requirement.evaluate(betaTester).isConfirmed)
    #expect(requirement.evaluate(notBetaTester).isConfirmed)
  }
  
  // MARK: - Комбинации
  
  @Test("when() и unless() могут комбинироваться")
  func testWhenAndUnlessCombined() {
    let requirement = Requirement<ConditionalContext>.all {
      Requirement.when(\.featureEnabled) {
        Requirement.require(\.isBetaTester)
      }
      Requirement.unless(\.isRestricted) {
        Requirement.require(\.canTrade)
      }
    }
    
    // Оба условия проходят
    let valid = ConditionalContext(featureEnabled: true, isBetaTester: true, isRestricted: false, canTrade: true)
    #expect(requirement.evaluate(valid).isConfirmed)
    
    // when не проходит (featureEnabled=true, но isBetaTester=false)
    let failWhen = ConditionalContext(featureEnabled: true, isBetaTester: false, isRestricted: false, canTrade: true)
    #expect(requirement.evaluate(failWhen).isFailed)
    
    // unless не проходит (isRestricted=false, но canTrade=false)
    let failUnless = ConditionalContext(featureEnabled: false, isBetaTester: false, isRestricted: false, canTrade: false)
    #expect(requirement.evaluate(failUnless).isFailed)
  }
}

