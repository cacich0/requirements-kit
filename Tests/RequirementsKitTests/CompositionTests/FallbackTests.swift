import Testing
@testable import RequirementsKit

struct FallbackContext: Sendable {
  let primaryMethod: Bool
  let fallbackMethod: Bool
  let secondaryFallback: Bool
}

@Suite("Fallback Composition Tests")
struct FallbackTests {
  
  // MARK: - .fallback {} метод
  
  @Test("fallback не используется когда основное требование выполнено")
  func testFallbackNotUsedWhenPrimaryPasses() {
    let requirement = Requirement<FallbackContext>
      .require(\.primaryMethod)
      .fallback {
        Requirement.require(\.fallbackMethod)
      }
    
    // Primary проходит -> не проверяем fallback
    let context = FallbackContext(primaryMethod: true, fallbackMethod: false, secondaryFallback: false)
    #expect(requirement.evaluate(context).isConfirmed)
  }
  
  @Test("fallback используется когда основное требование не выполнено")
  func testFallbackUsedWhenPrimaryFails() {
    let requirement = Requirement<FallbackContext>
      .require(\.primaryMethod)
      .fallback {
        Requirement.require(\.fallbackMethod)
      }
    
    // Primary не проходит, fallback проходит
    let context1 = FallbackContext(primaryMethod: false, fallbackMethod: true, secondaryFallback: false)
    #expect(requirement.evaluate(context1).isConfirmed)
    
    // Primary не проходит, fallback не проходит
    let context2 = FallbackContext(primaryMethod: false, fallbackMethod: false, secondaryFallback: false)
    #expect(requirement.evaluate(context2).isFailed)
  }
  
  @Test("fallback с несколькими требованиями")
  func testFallbackMultipleRequirements() {
    let requirement = Requirement<FallbackContext>
      .require(\.primaryMethod)
      .fallback {
        Requirement.require(\.fallbackMethod)
        Requirement.require(\.secondaryFallback)
      }
    
    // Оба fallback требования должны быть выполнены
    let allFallbacksPass = FallbackContext(primaryMethod: false, fallbackMethod: true, secondaryFallback: true)
    #expect(requirement.evaluate(allFallbacksPass).isConfirmed)
    
    let oneFallbackFails = FallbackContext(primaryMethod: false, fallbackMethod: true, secondaryFallback: false)
    #expect(requirement.evaluate(oneFallbackFails).isFailed)
  }
  
  // MARK: - .orFallback(to:) метод
  
  @Test("orFallback(to:) не используется когда основное требование выполнено")
  func testOrFallbackNotUsedWhenPrimaryPasses() {
    let primary = Requirement<FallbackContext>.require(\.primaryMethod)
    let fallback = Requirement<FallbackContext>.require(\.fallbackMethod)
    
    let requirement = primary.orFallback(to: fallback)
    
    let context = FallbackContext(primaryMethod: true, fallbackMethod: false, secondaryFallback: false)
    #expect(requirement.evaluate(context).isConfirmed)
  }
  
  @Test("orFallback(to:) используется когда основное требование не выполнено")
  func testOrFallbackUsedWhenPrimaryFails() {
    let primary = Requirement<FallbackContext>.require(\.primaryMethod)
    let fallback = Requirement<FallbackContext>.require(\.fallbackMethod)
    
    let requirement = primary.orFallback(to: fallback)
    
    // Fallback проходит
    let context1 = FallbackContext(primaryMethod: false, fallbackMethod: true, secondaryFallback: false)
    #expect(requirement.evaluate(context1).isConfirmed)
    
    // Fallback не проходит
    let context2 = FallbackContext(primaryMethod: false, fallbackMethod: false, secondaryFallback: false)
    #expect(requirement.evaluate(context2).isFailed)
  }
  
  // MARK: - Цепочки fallback
  
  @Test("цепочка fallback работает")
  func testFallbackChain() {
    let requirement = Requirement<FallbackContext>
      .require(\.primaryMethod)
      .orFallback(to: Requirement.require(\.fallbackMethod))
      .orFallback(to: Requirement.require(\.secondaryFallback))
    
    // Primary проходит
    let ctx1 = FallbackContext(primaryMethod: true, fallbackMethod: false, secondaryFallback: false)
    #expect(requirement.evaluate(ctx1).isConfirmed)
    
    // Первый fallback проходит
    let ctx2 = FallbackContext(primaryMethod: false, fallbackMethod: true, secondaryFallback: false)
    #expect(requirement.evaluate(ctx2).isConfirmed)
    
    // Второй fallback проходит
    let ctx3 = FallbackContext(primaryMethod: false, fallbackMethod: false, secondaryFallback: true)
    #expect(requirement.evaluate(ctx3).isConfirmed)
    
    // Ничего не проходит
    let ctx4 = FallbackContext(primaryMethod: false, fallbackMethod: false, secondaryFallback: false)
    #expect(requirement.evaluate(ctx4).isFailed)
  }
}

