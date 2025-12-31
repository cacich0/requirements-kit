import Testing
@testable import RequirementsKit

struct CollectionContext: Sendable {
  let items: [Int]
  let tags: Set<String>
  let optionalItems: [String]?
}

@Suite("Collection Validation Tests")
struct CollectionValidationTests {
  
  // MARK: - requireNotEmpty
  
  @Test("requireNotEmpty проходит для непустой коллекции")
  func testRequireNotEmptyPasses() {
    let requirement = Requirement<CollectionContext>.requireNotEmpty(\.items)
    
    let context = CollectionContext(items: [1, 2, 3], tags: [], optionalItems: nil)
    #expect(requirement.evaluate(context).isConfirmed)
  }
  
  @Test("requireNotEmpty не проходит для пустой коллекции")
  func testRequireNotEmptyFails() {
    let requirement = Requirement<CollectionContext>.requireNotEmpty(\.items)
    
    let context = CollectionContext(items: [], tags: [], optionalItems: nil)
    #expect(requirement.evaluate(context).isFailed)
  }
  
  // MARK: - requireEmpty
  
  @Test("requireEmpty проходит для пустой коллекции")
  func testRequireEmptyPasses() {
    let requirement = Requirement<CollectionContext>.requireEmpty(\.items)
    
    let context = CollectionContext(items: [], tags: [], optionalItems: nil)
    #expect(requirement.evaluate(context).isConfirmed)
  }
  
  @Test("requireEmpty не проходит для непустой коллекции")
  func testRequireEmptyFails() {
    let requirement = Requirement<CollectionContext>.requireEmpty(\.items)
    
    let context = CollectionContext(items: [1], tags: [], optionalItems: nil)
    #expect(requirement.evaluate(context).isFailed)
  }
  
  // MARK: - requireCount
  
  @Test("requireCount с min проходит если count >= min")
  func testRequireCountMinPasses() {
    let requirement = Requirement<CollectionContext>.requireCount(\.items, min: 2)
    
    let context = CollectionContext(items: [1, 2, 3], tags: [], optionalItems: nil)
    #expect(requirement.evaluate(context).isConfirmed)
  }
  
  @Test("requireCount с min не проходит если count < min")
  func testRequireCountMinFails() {
    let requirement = Requirement<CollectionContext>.requireCount(\.items, min: 5)
    
    let context = CollectionContext(items: [1, 2], tags: [], optionalItems: nil)
    #expect(requirement.evaluate(context).isFailed)
  }
  
  @Test("requireCount с max проходит если count <= max")
  func testRequireCountMaxPasses() {
    let requirement = Requirement<CollectionContext>.requireCount(\.items, max: 5)
    
    let context = CollectionContext(items: [1, 2, 3], tags: [], optionalItems: nil)
    #expect(requirement.evaluate(context).isConfirmed)
  }
  
  @Test("requireCount с max не проходит если count > max")
  func testRequireCountMaxFails() {
    let requirement = Requirement<CollectionContext>.requireCount(\.items, max: 2)
    
    let context = CollectionContext(items: [1, 2, 3, 4], tags: [], optionalItems: nil)
    #expect(requirement.evaluate(context).isFailed)
  }
  
  @Test("requireCount с min и max проходит если count в диапазоне")
  func testRequireCountRangePasses() {
    let requirement = Requirement<CollectionContext>.requireCount(\.items, min: 2, max: 5)
    
    let context = CollectionContext(items: [1, 2, 3], tags: [], optionalItems: nil)
    #expect(requirement.evaluate(context).isConfirmed)
  }
  
  @Test("requireCount с exact count проходит при точном совпадении")
  func testRequireCountExactPasses() {
    let requirement = Requirement<CollectionContext>.requireCount(\.items, min: 3, max: 3)
    
    let context = CollectionContext(items: [1, 2, 3], tags: [], optionalItems: nil)
    #expect(requirement.evaluate(context).isConfirmed)
  }
  
  @Test("requireCount с exact count не проходит при несовпадении")
  func testRequireCountExactFails() {
    let requirement = Requirement<CollectionContext>.requireCount(\.items, min: 5, max: 5)
    
    let context = CollectionContext(items: [1, 2, 3], tags: [], optionalItems: nil)
    #expect(requirement.evaluate(context).isFailed)
  }
  
  // MARK: - requireContains
  
  @Test("requireContains проходит если элемент присутствует")
  func testRequireContainsPasses() {
    let requirement = Requirement<CollectionContext>.requireContains(\.items, element: 2)
    
    let context = CollectionContext(items: [1, 2, 3], tags: [], optionalItems: nil)
    #expect(requirement.evaluate(context).isConfirmed)
  }
  
  @Test("requireContains не проходит если элемент отсутствует")
  func testRequireContainsFails() {
    let requirement = Requirement<CollectionContext>.requireContains(\.items, element: 5)
    
    let context = CollectionContext(items: [1, 2, 3], tags: [], optionalItems: nil)
    #expect(requirement.evaluate(context).isFailed)
  }
  
  // MARK: - requireAll (все элементы удовлетворяют условию)
  
  @Test("requireAll проходит если все элементы удовлетворяют условию")
  func testRequireAllElementsPasses() {
    let requirement = Requirement<CollectionContext>.requireAll(\.items) { $0 > 0 }
    
    let context = CollectionContext(items: [1, 2, 3], tags: [], optionalItems: nil)
    #expect(requirement.evaluate(context).isConfirmed)
  }
  
  @Test("requireAll не проходит если хотя бы один элемент не удовлетворяет")
  func testRequireAllElementsFails() {
    let requirement = Requirement<CollectionContext>.requireAll(\.items) { $0 > 0 }
    
    let context = CollectionContext(items: [1, -1, 3], tags: [], optionalItems: nil)
    #expect(requirement.evaluate(context).isFailed)
  }
  
  // MARK: - requireAny (хотя бы один элемент удовлетворяет)
  
  @Test("requireAny проходит если хотя бы один элемент удовлетворяет")
  func testRequireAnyElementsPasses() {
    let requirement = Requirement<CollectionContext>.requireAny(\.items) { $0 > 5 }
    
    let context = CollectionContext(items: [1, 2, 10], tags: [], optionalItems: nil)
    #expect(requirement.evaluate(context).isConfirmed)
  }
  
  @Test("requireAny не проходит если ни один элемент не удовлетворяет")
  func testRequireAnyElementsFails() {
    let requirement = Requirement<CollectionContext>.requireAny(\.items) { $0 > 10 }
    
    let context = CollectionContext(items: [1, 2, 3], tags: [], optionalItems: nil)
    #expect(requirement.evaluate(context).isFailed)
  }
  
  // MARK: - requireNone (ни один элемент не удовлетворяет)
  
  @Test("requireNone проходит если ни один элемент не удовлетворяет")
  func testRequireNoneElementsPasses() {
    let requirement = Requirement<CollectionContext>.requireNone(\.items) { $0 < 0 }
    
    let context = CollectionContext(items: [1, 2, 3], tags: [], optionalItems: nil)
    #expect(requirement.evaluate(context).isConfirmed)
  }
  
  @Test("requireNone не проходит если хотя бы один элемент удовлетворяет")
  func testRequireNoneElementsFails() {
    let requirement = Requirement<CollectionContext>.requireNone(\.items) { $0 < 0 }
    
    let context = CollectionContext(items: [1, -1, 3], tags: [], optionalItems: nil)
    #expect(requirement.evaluate(context).isFailed)
  }
  
  // MARK: - Set операции
  
  @Test("requireNotEmpty работает с Set")
  func testRequireNotEmptySet() {
    let requirement = Requirement<CollectionContext>.requireNotEmpty(\.tags)
    
    let hasTag = CollectionContext(items: [], tags: ["swift", "ios"], optionalItems: nil)
    let noTag = CollectionContext(items: [], tags: [], optionalItems: nil)
    
    #expect(requirement.evaluate(hasTag).isConfirmed)
    #expect(requirement.evaluate(noTag).isFailed)
  }
}

