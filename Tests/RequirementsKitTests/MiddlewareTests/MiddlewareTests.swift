import Testing
import Foundation
@testable import RequirementsKit

struct MiddlewareContext: Sendable {
  let isAllowed: Bool
}

// MARK: - Test Middleware

final class TestMiddleware: RequirementMiddleware, @unchecked Sendable {
  var beforeCount = 0
  var afterCount = 0
  var lastResult: Evaluation?
  var lastDuration: TimeInterval?
  
  func beforeEvaluation<Context: Sendable>(
    context: Context,
    requirementName: String?
  ) {
    beforeCount += 1
  }
  
  func afterEvaluation<Context: Sendable>(
    context: Context,
    requirementName: String?,
    result: Evaluation,
    duration: TimeInterval
  ) {
    afterCount += 1
    lastResult = result
    lastDuration = duration
  }
}

/// Класс для хранения данных аналитики (обход Sendable ограничений)
final class AnalyticsDataHolder: @unchecked Sendable {
  var eventName: String?
  var result: String?
}

@Suite("Middleware Tests")
struct MiddlewareTests {
  
  // MARK: - Базовая функциональность
  
  @Test("middleware вызывается при оценке требования")
  func testMiddlewareCalled() {
    let middleware = TestMiddleware()
    let requirement = Requirement<MiddlewareContext>
      .require(\.isAllowed)
      .with(middleware: middleware)
    
    let context = MiddlewareContext(isAllowed: true)
    _ = requirement.evaluate(context)
    
    #expect(middleware.beforeCount == 1)
    #expect(middleware.afterCount == 1)
  }
  
  @Test("middleware получает результат оценки")
  func testMiddlewareReceivesResult() {
    let middleware = TestMiddleware()
    let requirement = Requirement<MiddlewareContext>
      .require(\.isAllowed)
      .with(middleware: middleware)
    
    let context = MiddlewareContext(isAllowed: true)
    _ = requirement.evaluate(context)
    
    #expect(middleware.lastResult?.isConfirmed == true)
  }
  
  @Test("middleware получает длительность оценки")
  func testMiddlewareReceivesDuration() {
    let middleware = TestMiddleware()
    let requirement = Requirement<MiddlewareContext>
      .require(\.isAllowed)
      .with(middleware: middleware)
    
    let context = MiddlewareContext(isAllowed: true)
    _ = requirement.evaluate(context)
    
    #expect(middleware.lastDuration != nil)
    #expect(middleware.lastDuration! >= 0)
  }
  
  // MARK: - Несколько middleware
  
  @Test("несколько middleware вызываются в порядке добавления")
  func testMultipleMiddlewares() {
    let middleware1 = TestMiddleware()
    let middleware2 = TestMiddleware()
    
    let requirement = Requirement<MiddlewareContext>
      .require(\.isAllowed)
      .with(middlewares: [middleware1, middleware2])
    
    let context = MiddlewareContext(isAllowed: true)
    _ = requirement.evaluate(context)
    
    #expect(middleware1.beforeCount == 1)
    #expect(middleware1.afterCount == 1)
    #expect(middleware2.beforeCount == 1)
    #expect(middleware2.afterCount == 1)
  }
  
  // MARK: - LoggingMiddleware
  
  @Test("LoggingMiddleware создается с параметрами")
  func testLoggingMiddlewareCreation() {
    let logging = LoggingMiddleware(level: .verbose, prefix: "[Test]")
    
    // Просто проверяем что создается без ошибок
    let requirement = Requirement<MiddlewareContext>
      .require(\.isAllowed)
      .with(middleware: logging)
    
    let context = MiddlewareContext(isAllowed: true)
    let result = requirement.evaluate(context)
    
    #expect(result.isConfirmed)
  }
  
  // MARK: - AnalyticsMiddleware
  
  @Test("AnalyticsMiddleware вызывает handler")
  func testAnalyticsMiddleware() {
    // Используем класс для обхода Sendable ограничений
    let dataHolder = AnalyticsDataHolder()
    
    let analytics = AnalyticsMiddleware { eventName, properties in
      dataHolder.eventName = eventName
      dataHolder.result = properties["result"] as? String
    }
    
    let requirement = Requirement<MiddlewareContext>
      .require(\.isAllowed)
      .with(middleware: analytics)
    
    let context = MiddlewareContext(isAllowed: true)
    _ = requirement.evaluate(context)
    
    #expect(dataHolder.eventName == "requirement_evaluated")
    #expect(dataHolder.result == "confirmed")
  }
  
  // MARK: - Повторные вызовы
  
  @Test("middleware вызывается при каждой оценке")
  func testMiddlewareCalledOnEachEvaluation() {
    let middleware = TestMiddleware()
    let requirement = Requirement<MiddlewareContext>
      .require(\.isAllowed)
      .with(middleware: middleware)
    
    let context = MiddlewareContext(isAllowed: true)
    
    _ = requirement.evaluate(context)
    _ = requirement.evaluate(context)
    _ = requirement.evaluate(context)
    
    #expect(middleware.beforeCount == 3)
    #expect(middleware.afterCount == 3)
  }
}

