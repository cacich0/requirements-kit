#if canImport(SwiftUI) && canImport(Combine)

import SwiftUI
import Combine

// MARK: - RequirementEligibility

/// Результат проверки требования для использования в SwiftUI
public struct RequirementEligibility: Sendable, Equatable {
  /// Требование выполнено
  public let isAllowed: Bool
  
  /// Требование не выполнено
  public var isDenied: Bool { !isAllowed }
  
  /// Причина отказа (nil если требование выполнено)
  public let reason: Reason?
  
  /// Исходный результат оценки
  public let evaluation: Evaluation
  
  public init(evaluation: Evaluation) {
    self.evaluation = evaluation
    self.isAllowed = evaluation.isConfirmed
    self.reason = evaluation.reason
  }
  
  public static func == (lhs: RequirementEligibility, rhs: RequirementEligibility) -> Bool {
    lhs.isAllowed == rhs.isAllowed && lhs.reason == rhs.reason
  }
}

// MARK: - RequirementObserver

/// Observable объект для отслеживания изменений требований
@available(iOS 14.0, macOS 11.0, tvOS 14.0, watchOS 7.0, *)
public final class RequirementObserver<Context: Sendable>: ObservableObject, @unchecked Sendable {
  @Published public private(set) var eligibility: RequirementEligibility
  
  private let requirement: Requirement<Context>
  private var context: Context
  
  public init(requirement: Requirement<Context>, context: Context) {
    self.requirement = requirement
    self.context = context
    self.eligibility = RequirementEligibility(evaluation: requirement.evaluate(context))
  }
  
  /// Обновляет контекст и пересчитывает требование
  @MainActor
  public func update(context: Context) {
    self.context = context
    reevaluate()
  }
  
  /// Принудительная переоценка требования
  @MainActor
  public func reevaluate() {
    let evaluation = requirement.evaluate(context)
    eligibility = RequirementEligibility(evaluation: evaluation)
  }
}

// MARK: - ObservedRequirement Property Wrapper

/// Property wrapper для наблюдаемых требований в SwiftUI
///
/// Автоматически обновляет View при изменении контекста
///
/// Использование:
/// ```swift
/// struct TradeView: View {
///   @ObservedRequirement(by: canTrade, context: userContext)
///   var eligibility
///
///   var body: some View {
///     Button("Trade") { trade() }
///       .disabled(!eligibility.isAllowed)
///   }
/// }
/// ```
@available(iOS 14.0, macOS 11.0, tvOS 14.0, watchOS 7.0, *)
@propertyWrapper
public struct ObservedRequirement<Context: Sendable>: DynamicProperty {
  @StateObject private var observer: RequirementObserver<Context>
  
  /// Результат проверки требования
  public var wrappedValue: RequirementEligibility {
    observer.eligibility
  }
  
  /// Доступ к observer для дополнительных операций
  public var projectedValue: RequirementObserver<Context> {
    observer
  }
  
  /// Инициализатор с синхронным требованием и статическим контекстом
  /// - Parameters:
  ///   - requirement: Требование для проверки
  ///   - context: Контекст (статический)
  public init(by requirement: Requirement<Context>, context: Context) {
    _observer = StateObject(wrappedValue: RequirementObserver(
      requirement: requirement,
      context: context
    ))
  }
}

#endif
