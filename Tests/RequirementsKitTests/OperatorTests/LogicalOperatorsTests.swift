import Testing
@testable import RequirementsKit

struct OperatorContext: Sendable {
  let a: Bool
  let b: Bool
  let c: Bool
}

@Suite("Logical Operators Tests")
struct LogicalOperatorsTests {
  
  // MARK: - AND (&&) оператор
  
  @Test("&& возвращает confirmed когда оба требования выполнены")
  func testAndBothConfirmed() {
    let req1 = Requirement<OperatorContext>.require(\.a)
    let req2 = Requirement<OperatorContext>.require(\.b)
    
    let combined = req1 && req2
    let context = OperatorContext(a: true, b: true, c: false)
    
    #expect(combined.evaluate(context).isConfirmed)
  }
  
  @Test("&& возвращает failed когда первое требование не выполнено")
  func testAndFirstFailed() {
    let req1 = Requirement<OperatorContext>.require(\.a)
    let req2 = Requirement<OperatorContext>.require(\.b)
    
    let combined = req1 && req2
    let context = OperatorContext(a: false, b: true, c: false)
    
    #expect(combined.evaluate(context).isFailed)
  }
  
  @Test("&& возвращает failed когда второе требование не выполнено")
  func testAndSecondFailed() {
    let req1 = Requirement<OperatorContext>.require(\.a)
    let req2 = Requirement<OperatorContext>.require(\.b)
    
    let combined = req1 && req2
    let context = OperatorContext(a: true, b: false, c: false)
    
    #expect(combined.evaluate(context).isFailed)
  }
  
  @Test("&& возвращает failed когда оба требования не выполнены")
  func testAndBothFailed() {
    let req1 = Requirement<OperatorContext>.require(\.a)
    let req2 = Requirement<OperatorContext>.require(\.b)
    
    let combined = req1 && req2
    let context = OperatorContext(a: false, b: false, c: false)
    
    #expect(combined.evaluate(context).isFailed)
  }
  
  // MARK: - OR (||) оператор
  
  @Test("|| возвращает confirmed когда оба требования выполнены")
  func testOrBothConfirmed() {
    let req1 = Requirement<OperatorContext>.require(\.a)
    let req2 = Requirement<OperatorContext>.require(\.b)
    
    let combined = req1 || req2
    let context = OperatorContext(a: true, b: true, c: false)
    
    #expect(combined.evaluate(context).isConfirmed)
  }
  
  @Test("|| возвращает confirmed когда только первое требование выполнено")
  func testOrFirstConfirmed() {
    let req1 = Requirement<OperatorContext>.require(\.a)
    let req2 = Requirement<OperatorContext>.require(\.b)
    
    let combined = req1 || req2
    let context = OperatorContext(a: true, b: false, c: false)
    
    #expect(combined.evaluate(context).isConfirmed)
  }
  
  @Test("|| возвращает confirmed когда только второе требование выполнено")
  func testOrSecondConfirmed() {
    let req1 = Requirement<OperatorContext>.require(\.a)
    let req2 = Requirement<OperatorContext>.require(\.b)
    
    let combined = req1 || req2
    let context = OperatorContext(a: false, b: true, c: false)
    
    #expect(combined.evaluate(context).isConfirmed)
  }
  
  @Test("|| возвращает failed когда оба требования не выполнены")
  func testOrBothFailed() {
    let req1 = Requirement<OperatorContext>.require(\.a)
    let req2 = Requirement<OperatorContext>.require(\.b)
    
    let combined = req1 || req2
    let context = OperatorContext(a: false, b: false, c: false)
    
    #expect(combined.evaluate(context).isFailed)
  }
  
  // MARK: - NOT (!) оператор
  
  @Test("! инвертирует confirmed в failed")
  func testNotInvertsConfirmed() {
    let req = Requirement<OperatorContext>.require(\.a)
    let inverted = !req
    
    let context = OperatorContext(a: true, b: false, c: false)
    
    #expect(inverted.evaluate(context).isFailed)
  }
  
  @Test("! инвертирует failed в confirmed")
  func testNotInvertsFailed() {
    let req = Requirement<OperatorContext>.require(\.a)
    let inverted = !req
    
    let context = OperatorContext(a: false, b: false, c: false)
    
    #expect(inverted.evaluate(context).isConfirmed)
  }
  
  @Test("двойное отрицание возвращает исходный результат")
  func testDoubleNegation() {
    let req = Requirement<OperatorContext>.require(\.a)
    let doubleInverted = !(!req)
    
    let trueContext = OperatorContext(a: true, b: false, c: false)
    let falseContext = OperatorContext(a: false, b: false, c: false)
    
    #expect(doubleInverted.evaluate(trueContext).isConfirmed)
    #expect(doubleInverted.evaluate(falseContext).isFailed)
  }
  
  // MARK: - Комбинации операторов
  
  @Test("комбинация && и || работает корректно")
  func testAndOrCombination() {
    let a = Requirement<OperatorContext>.require(\.a)
    let b = Requirement<OperatorContext>.require(\.b)
    let c = Requirement<OperatorContext>.require(\.c)
    
    // (a && b) || c
    let combined = (a && b) || c
    
    // a=true, b=true, c=false -> (true && true) || false = true
    let ctx1 = OperatorContext(a: true, b: true, c: false)
    #expect(combined.evaluate(ctx1).isConfirmed)
    
    // a=true, b=false, c=true -> (true && false) || true = true
    let ctx2 = OperatorContext(a: true, b: false, c: true)
    #expect(combined.evaluate(ctx2).isConfirmed)
    
    // a=false, b=false, c=false -> (false && false) || false = false
    let ctx3 = OperatorContext(a: false, b: false, c: false)
    #expect(combined.evaluate(ctx3).isFailed)
  }
  
  @Test("комбинация ! и && работает корректно")
  func testNotAndCombination() {
    let a = Requirement<OperatorContext>.require(\.a)
    let b = Requirement<OperatorContext>.require(\.b)
    
    // !a && b
    let combined = !a && b
    
    // a=false, b=true -> !false && true = true
    let ctx1 = OperatorContext(a: false, b: true, c: false)
    #expect(combined.evaluate(ctx1).isConfirmed)
    
    // a=true, b=true -> !true && true = false
    let ctx2 = OperatorContext(a: true, b: true, c: false)
    #expect(combined.evaluate(ctx2).isFailed)
  }
  
  // MARK: - Цепочки операторов
  
  @Test("длинная цепочка && работает")
  func testLongAndChain() {
    let a = Requirement<OperatorContext>.require(\.a)
    let b = Requirement<OperatorContext>.require(\.b)
    let c = Requirement<OperatorContext>.require(\.c)
    
    let combined = a && b && c
    
    let allTrue = OperatorContext(a: true, b: true, c: true)
    let oneFalse = OperatorContext(a: true, b: false, c: true)
    
    #expect(combined.evaluate(allTrue).isConfirmed)
    #expect(combined.evaluate(oneFalse).isFailed)
  }
  
  @Test("длинная цепочка || работает")
  func testLongOrChain() {
    let a = Requirement<OperatorContext>.require(\.a)
    let b = Requirement<OperatorContext>.require(\.b)
    let c = Requirement<OperatorContext>.require(\.c)
    
    let combined = a || b || c
    
    let allFalse = OperatorContext(a: false, b: false, c: false)
    let oneTrue = OperatorContext(a: false, b: true, c: false)
    
    #expect(combined.evaluate(allFalse).isFailed)
    #expect(combined.evaluate(oneTrue).isConfirmed)
  }
}

