import Testing
@testable import RequirementsKit

@Suite("NOT Composition Tests")
struct NotTests {
  
  @Test("NOT инвертирует confirmed в failed")
  func testNotInvertsConfirmed() {
    let requirement = Requirement<CompositionContext>.not(
      #require(\.value1)
    )
    
    let context = CompositionContext(value1: true, value2: false, value3: false)
    let result = requirement.evaluate(context)
    
    #expect(result.isFailed)
  }
  
  @Test("NOT инвертирует failed в confirmed")
  func testNotInvertsFailed() {
    let requirement = Requirement<CompositionContext>.not(
      #require(\.value1)
    )
    
    let context = CompositionContext(value1: false, value2: false, value3: false)
    let result = requirement.evaluate(context)
    
    #expect(result.isConfirmed)
  }
  
  @Test("NOT работает с fluent API")
  func testNotFluentAPI() {
    let requirement = Requirement<CompositionContext>
      .require(\.value1)
      .not()
    
    let context = CompositionContext(value1: false, value2: false, value3: false)
    let result = requirement.evaluate(context)
    
    #expect(result.isConfirmed)
  }
  
  @Test("NOT работает с составными требованиями")
  func testNotWithComposite() {
    let requirement = Requirement<CompositionContext>.not(
      Requirement.all {
        #require(\.value1)
        #require(\.value2)
      }
    )
    
    let context1 = CompositionContext(value1: true, value2: true, value3: false)
    let context2 = CompositionContext(value1: true, value2: false, value3: false)
    
    #expect(requirement.evaluate(context1).isFailed)
    #expect(requirement.evaluate(context2).isConfirmed)
  }
  
  @Test("Двойное NOT возвращает исходный результат")
  func testDoubleNot() {
    let requirement = Requirement<CompositionContext>
      .require(\.value1)
      .not()
      .not()
    
    let context = CompositionContext(value1: true, value2: false, value3: false)
    let result = requirement.evaluate(context)
    
    #expect(result.isConfirmed)
  }
}

