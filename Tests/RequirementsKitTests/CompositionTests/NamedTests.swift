import Testing
@testable import RequirementsKit

@Suite("Named Requirements Tests")
struct NamedTests {
  
  @Test("Named requirement работает корректно")
  func testNamedRequirement() {
    let requirement = Requirement<CompositionContext>.named("Test Requirement") {
      #require(\.value1)
      #require(\.value2)
    }
    
    let successContext = CompositionContext(value1: true, value2: true, value3: false)
    let failContext = CompositionContext(value1: true, value2: false, value3: false)
    
    #expect(requirement.evaluate(successContext).isConfirmed)
    #expect(requirement.evaluate(failContext).isFailed)
  }
  
  @Test("Named requirement с одним требованием")
  func testNamedSingleRequirement() {
    let innerRequirement = Requirement<CompositionContext>.require(\.value1)
    let requirement = Requirement<CompositionContext>.named("Single", requirement: innerRequirement)
    
    let context = CompositionContext(value1: true, value2: false, value3: false)
    
    #expect(requirement.evaluate(context).isConfirmed)
  }
  
  @Test("Named requirement через fluent API")
  func testNamedFluentAPI() {
    let requirement = Requirement<CompositionContext>
      .require(\.value1)
      .named("Fluent Named")
    
    let context = CompositionContext(value1: true, value2: false, value3: false)
    
    #expect(requirement.evaluate(context).isConfirmed)
  }
  
  @Test("Named requirement можно комбинировать")
  func testNamedComposition() {
    let premiumAccess = Requirement<CompositionContext>.named("Premium Access") {
      #require(\.value1)
      #require(\.value2)
    }
    
    let fullAccess = Requirement<CompositionContext>.all {
      premiumAccess
      #require(\.value3)
    }
    
    let context = CompositionContext(value1: true, value2: true, value3: true)
    
    #expect(fullAccess.evaluate(context).isConfirmed)
  }
}

