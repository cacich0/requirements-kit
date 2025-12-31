import Testing
@testable import RequirementsKit

@Suite("ANY Composition Tests")
struct AnyTests {
  
  @Test("ANY возвращает confirmed если хотя бы одно требование выполнено")
  func testAnyConfirmedWhenOneRequirementPasses() {
    let requirement = Requirement<CompositionContext>.any {
      #require(\.value1)
      #require(\.value2)
      #require(\.value3)
    }
    
    let context = CompositionContext(value1: false, value2: true, value3: false)
    let result = requirement.evaluate(context)
    
    #expect(result.isConfirmed)
  }
  
  @Test("ANY возвращает confirmed если все требования выполнены")
  func testAnyConfirmedWhenAllRequirementsPass() {
    let requirement = Requirement<CompositionContext>.any {
      #require(\.value1)
      #require(\.value2)
      #require(\.value3)
    }
    
    let context = CompositionContext(value1: true, value2: true, value3: true)
    let result = requirement.evaluate(context)
    
    #expect(result.isConfirmed)
  }
  
  @Test("ANY возвращает failed если все требования не выполнены")
  func testAnyFailedWhenAllRequirementsFail() {
    let requirement = Requirement<CompositionContext>.any {
      #require(\.value1)
      #require(\.value2)
      #require(\.value3)
    }
    
    let context = CompositionContext(value1: false, value2: false, value3: false)
    let result = requirement.evaluate(context)
    
    #expect(result.isFailed)
  }
  
  @Test("ANY работает с вложенными требованиями")
  func testAnyNested() {
    let requirement = Requirement<CompositionContext>.any {
      #require(\.value1)
      
      Requirement.all {
        #require(\.value2)
        #require(\.value3)
      }
    }
    
    let context1 = CompositionContext(value1: true, value2: false, value3: false)
    let context2 = CompositionContext(value1: false, value2: true, value3: true)
    let context3 = CompositionContext(value1: false, value2: false, value3: false)
    
    #expect(requirement.evaluate(context1).isConfirmed)
    #expect(requirement.evaluate(context2).isConfirmed)
    #expect(requirement.evaluate(context3).isFailed)
  }
  
  @Test("ANY работает с массивом требований")
  func testAnyArray() {
    let requirements = [
      Requirement<CompositionContext>.require(\.value1),
      Requirement<CompositionContext>.require(\.value2)
    ]
    
    let requirement = Requirement<CompositionContext>.any(requirements)
    let context = CompositionContext(value1: false, value2: true, value3: false)
    
    #expect(requirement.evaluate(context).isConfirmed)
  }
}

