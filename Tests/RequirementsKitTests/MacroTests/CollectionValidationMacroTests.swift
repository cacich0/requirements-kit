import Testing
@testable import RequirementsKit

struct CollectionMacroContext: Sendable {
  let items: [String]
  let numbers: [Int]
  let tags: [String]
  let errors: [String]
}

@Suite("Collection Validation Macro Tests")
struct CollectionValidationMacroTests {
  
  // MARK: - #requireCount
  
  @Test("#requireCount проходит если количество в допустимых пределах")
  func testRequireCountPasses() {
    let requirement: Requirement<CollectionMacroContext> = #requireCount(\.items, min: 1, max: 10)
    
    let context = CollectionMacroContext(
      items: ["item1", "item2", "item3"],
      numbers: [],
      tags: [],
      errors: []
    )
    #expect(requirement.evaluate(context).isConfirmed)
  }
  
  @Test("#requireCount не проходит если количество меньше min")
  func testRequireCountFailsMin() {
    let requirement: Requirement<CollectionMacroContext> = #requireCount(\.items, min: 5, max: 10)
    
    let context = CollectionMacroContext(
      items: ["item1", "item2"],
      numbers: [],
      tags: [],
      errors: []
    )
    #expect(requirement.evaluate(context).isFailed)
  }
  
  @Test("#requireCount не проходит если количество больше max")
  func testRequireCountFailsMax() {
    let requirement: Requirement<CollectionMacroContext> = #requireCount(\.items, min: 1, max: 3)
    
    let context = CollectionMacroContext(
      items: ["item1", "item2", "item3", "item4", "item5"],
      numbers: [],
      tags: [],
      errors: []
    )
    #expect(requirement.evaluate(context).isFailed)
  }
  
  @Test("#requireCount с только min проходит если количество >= min")
  func testRequireCountMinOnly() {
    let requirement: Requirement<CollectionMacroContext> = #requireCount(\.items, min: 2)
    
    let context = CollectionMacroContext(
      items: ["item1", "item2", "item3"],
      numbers: [],
      tags: [],
      errors: []
    )
    #expect(requirement.evaluate(context).isConfirmed)
  }
  
  @Test("#requireCount с только max проходит если количество <= max")
  func testRequireCountMaxOnly() {
    let requirement: Requirement<CollectionMacroContext> = #requireCount(\.items, max: 5)
    
    let context = CollectionMacroContext(
      items: ["item1", "item2"],
      numbers: [],
      tags: [],
      errors: []
    )
    #expect(requirement.evaluate(context).isConfirmed)
  }
  
  // MARK: - #requireNotEmpty
  
  @Test("#requireNotEmpty проходит для непустой коллекции")
  func testRequireNotEmptyPasses() {
    let requirement: Requirement<CollectionMacroContext> = #requireNotEmpty(\.items)
    
    let context = CollectionMacroContext(
      items: ["item1"],
      numbers: [],
      tags: [],
      errors: []
    )
    #expect(requirement.evaluate(context).isConfirmed)
  }
  
  @Test("#requireNotEmpty не проходит для пустой коллекции")
  func testRequireNotEmptyFails() {
    let requirement: Requirement<CollectionMacroContext> = #requireNotEmpty(\.items)
    
    let context = CollectionMacroContext(
      items: [],
      numbers: [],
      tags: [],
      errors: []
    )
    #expect(requirement.evaluate(context).isFailed)
  }
  
  // MARK: - #requireEmpty
  
  @Test("#requireEmpty проходит для пустой коллекции")
  func testRequireEmptyPasses() {
    let requirement: Requirement<CollectionMacroContext> = #requireEmpty(\.errors)
    
    let context = CollectionMacroContext(
      items: [],
      numbers: [],
      tags: [],
      errors: []
    )
    #expect(requirement.evaluate(context).isConfirmed)
  }
  
  @Test("#requireEmpty не проходит для непустой коллекции")
  func testRequireEmptyFails() {
    let requirement: Requirement<CollectionMacroContext> = #requireEmpty(\.errors)
    
    let context = CollectionMacroContext(
      items: [],
      numbers: [],
      tags: [],
      errors: ["error1"]
    )
    #expect(requirement.evaluate(context).isFailed)
  }
  
  // MARK: - Работа с разными типами коллекций
  
  @Test("#requireNotEmpty работает с Int массивами")
  func testRequireNotEmptyWithInts() {
    let requirement: Requirement<CollectionMacroContext> = #requireNotEmpty(\.numbers)
    
    let validContext = CollectionMacroContext(
      items: [],
      numbers: [1, 2, 3],
      tags: [],
      errors: []
    )
    #expect(requirement.evaluate(validContext).isConfirmed)
    
    let invalidContext = CollectionMacroContext(
      items: [],
      numbers: [],
      tags: [],
      errors: []
    )
    #expect(requirement.evaluate(invalidContext).isFailed)
  }
  
  // MARK: - Композиция макросов коллекций
  
  @Test("Композиция макросов валидации коллекций работает")
  func testComposedCollectionValidation() {
    let requirement: Requirement<CollectionMacroContext> = #all {
      #requireNotEmpty(\.items)
      #requireCount(\.items, min: 1, max: 10)
      #requireEmpty(\.errors)
    }
    
    let validContext = CollectionMacroContext(
      items: ["item1", "item2"],
      numbers: [],
      tags: [],
      errors: []
    )
    #expect(requirement.evaluate(validContext).isConfirmed)
    
    let invalidContext1 = CollectionMacroContext(
      items: [],
      numbers: [],
      tags: [],
      errors: []
    )
    #expect(requirement.evaluate(invalidContext1).isFailed)
    
    let invalidContext2 = CollectionMacroContext(
      items: ["item1"],
      numbers: [],
      tags: [],
      errors: ["error"]
    )
    #expect(requirement.evaluate(invalidContext2).isFailed)
  }
  
  // MARK: - Комбинация с другими макросами
  
  @Test("Комбинация макросов коллекций и условий")
  func testCollectionMacrosWithConditions() {
    struct TestContext: Sendable {
      let items: [String]
      let isProduction: Bool
    }
    
    let requirement: Requirement<TestContext> = #when(\.isProduction) {
      #requireCount(\.items, min: 1)
    }
    
    let prodContext = TestContext(items: ["item1"], isProduction: true)
    #expect(requirement.evaluate(prodContext).isConfirmed)
    
    let devContext = TestContext(items: [], isProduction: false)
    #expect(requirement.evaluate(devContext).isConfirmed)
  }
}

