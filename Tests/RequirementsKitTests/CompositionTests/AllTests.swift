import Testing
@testable import RequirementsKit

struct CompositionContext: Sendable {
  let value1: Bool
  let value2: Bool
  let value3: Bool
}

@Suite("ALL Composition Tests")
struct AllTests {
  
  @Test("ALL возвращает confirmed когда все требования выполнены")
  func testAllConfirmed() {
    let requirement = Requirement<CompositionContext>.all {
      #require(\.value1)
      #require(\.value2)
      #require(\.value3)
    }
    
    let context = CompositionContext(value1: true, value2: true, value3: true)
    let result = requirement.evaluate(context)
    
    #expect(result.isConfirmed)
  }
  
  @Test("ALL возвращает failed если хотя бы одно требование не выполнено")
  func testAllFailedWhenOneRequirementFails() {
    let requirement = Requirement<CompositionContext>.all {
      #require(\.value1)
      #require(\.value2)
      #require(\.value3)
    }
    
    let context = CompositionContext(value1: true, value2: false, value3: true)
    let result = requirement.evaluate(context)
    
    #expect(result.isFailed)
  }
  
  @Test("ALL возвращает failed если все требования не выполнены")
  func testAllFailedWhenAllRequirementsFail() {
    let requirement = Requirement<CompositionContext>.all {
      #require(\.value1)
      #require(\.value2)
      #require(\.value3)
    }
    
    let context = CompositionContext(value1: false, value2: false, value3: false)
    let result = requirement.evaluate(context)
    
    #expect(result.isFailed)
  }
  
  @Test("ALL работает с вложенными требованиями")
  func testAllNested() {
    let requirement = Requirement<CompositionContext>.all {
      #require(\.value1)
      
      Requirement.all {
        #require(\.value2)
        #require(\.value3)
      }
    }
    
    let successContext = CompositionContext(value1: true, value2: true, value3: true)
    let failContext = CompositionContext(value1: true, value2: false, value3: true)
    
    #expect(requirement.evaluate(successContext).isConfirmed)
    #expect(requirement.evaluate(failContext).isFailed)
  }
  
  @Test("ALL работает с массивом требований")
  func testAllArray() {
    let requirements = [
      Requirement<CompositionContext>.require(\.value1),
      Requirement<CompositionContext>.require(\.value2)
    ]
    
    let requirement = Requirement<CompositionContext>.all(requirements)
    let context = CompositionContext(value1: true, value2: true, value3: false)
    
    #expect(requirement.evaluate(context).isConfirmed)
  }
}
