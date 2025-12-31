import Testing
import Foundation
@testable import RequirementsKit

struct TraceContext: Sendable {
  let isValid: Bool
}

@Suite("RequirementTrace Tests")
struct TraceTests {
  
  // MARK: - TracedRequirement
  
  @Test("TracedRequirement создается с именем")
  func testTracedRequirementCreation() {
    let requirement = Requirement<TraceContext>.require(\.isValid)
    let traced = TracedRequirement(requirement: requirement, name: "validity_check")
    
    let context = TraceContext(isValid: true)
    let result = traced.evaluate(context)
    
    #expect(result.isConfirmed)
  }
  
  @Test(".traced() extension создает TracedRequirement")
  func testTracedExtension() {
    let requirement = Requirement<TraceContext>.require(\.isValid)
    let traced = requirement.traced(name: "test_requirement")
    
    let context = TraceContext(isValid: true)
    let result = traced.evaluate(context)
    
    #expect(result.isConfirmed)
  }
  
  // MARK: - evaluateWithTrace()
  
  @Test("evaluateWithTrace() возвращает результат и трассировку")
  func testEvaluateWithTrace() {
    let requirement = Requirement<TraceContext>.require(\.isValid)
    let traced = requirement.traced(name: "my_requirement")
    
    let context = TraceContext(isValid: true)
    let (result, trace) = traced.evaluateWithTrace(context)
    
    #expect(result.isConfirmed)
    #expect(trace.path == ["my_requirement"])
    #expect(trace.evaluation.isConfirmed)
    #expect(trace.duration >= 0)
  }
  
  @Test("evaluateWithTrace() записывает failed результат")
  func testEvaluateWithTraceFailed() {
    let requirement = Requirement<TraceContext>.require(\.isValid)
    let traced = requirement.traced(name: "failing_requirement")
    
    let context = TraceContext(isValid: false)
    let (result, trace) = traced.evaluateWithTrace(context)
    
    #expect(result.isFailed)
    #expect(trace.evaluation.isFailed)
  }
  
  // MARK: - RequirementTrace структура
  
  @Test("RequirementTrace содержит все поля")
  func testRequirementTraceFields() {
    let trace = RequirementTrace(
      path: ["root", "child"],
      evaluation: .confirmed,
      duration: 0.001,
      timestamp: Date(),
      children: []
    )
    
    #expect(trace.path == ["root", "child"])
    #expect(trace.evaluation.isConfirmed)
    #expect(trace.duration == 0.001)
    #expect(trace.children.isEmpty)
  }
  
  @Test("RequirementTrace может иметь вложенные трассировки")
  func testNestedTraces() {
    let childTrace = RequirementTrace(
      path: ["child"],
      evaluation: .confirmed,
      duration: 0.0005
    )
    
    let parentTrace = RequirementTrace(
      path: ["parent"],
      evaluation: .confirmed,
      duration: 0.001,
      children: [childTrace]
    )
    
    #expect(parentTrace.children.count == 1)
    #expect(parentTrace.children[0].path == ["child"])
  }
}

