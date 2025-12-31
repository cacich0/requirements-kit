import Testing
@testable import RequirementsKit

@Suite("Evaluation Tests")
struct EvaluationTests {
  
  @Test("Evaluation.confirmed возвращает isConfirmed = true")
  func testConfirmedIsConfirmed() {
    let evaluation = Evaluation.confirmed
    
    #expect(evaluation.isConfirmed == true)
    #expect(evaluation.isFailed == false)
    #expect(evaluation.reason == nil)
  }
  
  @Test("Evaluation.failed возвращает isConfirmed = false")
  func testFailedIsNotConfirmed() {
    let reason = Reason(message: "Test failure")
    let evaluation = Evaluation.failed(reason: reason)
    
    #expect(evaluation.isConfirmed == false)
    #expect(evaluation.isFailed == true)
    #expect(evaluation.reason == reason)
  }
  
  @Test("allFailures возвращает причины отказа")
  func testAllFailures() {
    let reason = Reason(message: "Test failure")
    let failedEvaluation = Evaluation.failed(reason: reason)
    let confirmedEvaluation = Evaluation.confirmed
    
    #expect(failedEvaluation.allFailures == [reason])
    #expect(confirmedEvaluation.allFailures.isEmpty)
  }
  
  @Test("Evaluation поддерживает Equatable")
  func testEvaluationEquatable() {
    let reason1 = Reason(message: "Failure 1")
    let reason2 = Reason(message: "Failure 2")
    
    #expect(Evaluation.confirmed == Evaluation.confirmed)
    #expect(Evaluation.failed(reason: reason1) == Evaluation.failed(reason: reason1))
    #expect(Evaluation.failed(reason: reason1) != Evaluation.failed(reason: reason2))
    #expect(Evaluation.confirmed != Evaluation.failed(reason: reason1))
  }
}

