import Testing
import Foundation
@testable import RequirementsKit

struct ProfilingContext: Sendable {
  let value: Int
}

@Suite("Profiling Tests")
struct ProfilingTests {
  
  // MARK: - ProfiledRequirement
  
  @Test("ProfiledRequirement создается из требования")
  func testProfiledRequirementCreation() {
    let requirement = Requirement<ProfilingContext> { $0.value > 0 ? .confirmed : .failed(reason: Reason(message: "Not positive")) }
    let profiled = ProfiledRequirement(requirement: requirement)
    
    let context = ProfilingContext(value: 5)
    let (result, _) = profiled.evaluateWithMetrics(context)
    
    #expect(result.isConfirmed)
  }
  
  @Test(".profiled() extension создает ProfiledRequirement")
  func testProfiledExtension() {
    let requirement = Requirement<ProfilingContext> { $0.value > 0 ? .confirmed : .failed(reason: Reason(message: "Not positive")) }
    let profiled = requirement.profiled()
    
    let context = ProfilingContext(value: 5)
    let (result, _) = profiled.evaluateWithMetrics(context)
    
    #expect(result.isConfirmed)
  }
  
  // MARK: - evaluateWithMetrics()
  
  @Test("evaluateWithMetrics() возвращает результат и метрики")
  func testEvaluateWithMetrics() {
    let requirement = Requirement<ProfilingContext> { _ in .confirmed }
    let profiled = ProfiledRequirement(requirement: requirement)
    
    let context = ProfilingContext(value: 5)
    let (result, metrics) = profiled.evaluateWithMetrics(context)
    
    #expect(result.isConfirmed)
    #expect(metrics.duration >= 0)
    #expect(metrics.evaluationCount == 1)
  }
  
  @Test("evaluateWithMetrics() накапливает статистику")
  func testMetricsAccumulation() {
    let requirement = Requirement<ProfilingContext> { _ in .confirmed }
    let profiled = ProfiledRequirement(requirement: requirement)
    
    let context = ProfilingContext(value: 5)
    
    _ = profiled.evaluateWithMetrics(context)
    _ = profiled.evaluateWithMetrics(context)
    let (_, metrics) = profiled.evaluateWithMetrics(context)
    
    #expect(metrics.evaluationCount == 3)
  }
  
  // MARK: - PerformanceMetrics
  
  @Test("PerformanceMetrics содержит правильные значения после нескольких вызовов")
  func testPerformanceMetricsValues() {
    let requirement = Requirement<ProfilingContext> { _ in .confirmed }
    let profiled = ProfiledRequirement(requirement: requirement)
    
    let context = ProfilingContext(value: 5)
    
    _ = profiled.evaluateWithMetrics(context)
    _ = profiled.evaluateWithMetrics(context)
    _ = profiled.evaluateWithMetrics(context)
    
    let metrics = profiled.metrics!
    
    #expect(metrics.evaluationCount == 3)
    #expect(metrics.averageDuration >= 0)
    #expect(metrics.minDuration >= 0)
    #expect(metrics.maxDuration >= metrics.minDuration)
  }
  
  @Test("metrics property возвращает nil до первой оценки")
  func testMetricsNilBeforeFirstEvaluation() {
    let requirement = Requirement<ProfilingContext> { _ in .confirmed }
    let profiled = ProfiledRequirement(requirement: requirement)
    
    #expect(profiled.metrics == nil)
  }
  
  // MARK: - reset()
  
  @Test("reset() очищает статистику")
  func testReset() {
    let requirement = Requirement<ProfilingContext> { _ in .confirmed }
    let profiled = ProfiledRequirement(requirement: requirement)
    
    let context = ProfilingContext(value: 5)
    
    _ = profiled.evaluateWithMetrics(context)
    _ = profiled.evaluateWithMetrics(context)
    
    #expect(profiled.metrics?.evaluationCount == 2)
    
    profiled.reset()
    
    #expect(profiled.metrics == nil)
  }
  
  @Test("после reset() счетчик начинается заново")
  func testResetAndRestart() {
    let requirement = Requirement<ProfilingContext> { _ in .confirmed }
    let profiled = ProfiledRequirement(requirement: requirement)
    
    let context = ProfilingContext(value: 5)
    
    _ = profiled.evaluateWithMetrics(context)
    _ = profiled.evaluateWithMetrics(context)
    
    profiled.reset()
    
    let (_, metrics) = profiled.evaluateWithMetrics(context)
    
    #expect(metrics.evaluationCount == 1)
  }
}

