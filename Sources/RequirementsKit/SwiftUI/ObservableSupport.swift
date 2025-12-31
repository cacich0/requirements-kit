#if canImport(SwiftUI) && canImport(Observation)

import SwiftUI

// MARK: - iOS 17+ Observable Support

/// Поддержка @Observable для iOS 17+
@available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
@propertyWrapper
public struct ObservedRequirementObservable<Context: Sendable>: DynamicProperty {
  @State private var eligibility: RequirementEligibility
  
  private let requirement: Requirement<Context>
  private let contextProvider: () -> Context
  
  public var wrappedValue: RequirementEligibility {
    eligibility
  }
  
  /// Инициализатор с провайдером контекста
  /// - Parameters:
  ///   - requirement: Требование для проверки
  ///   - contextProvider: Замыкание, возвращающее текущий контекст
  public init(
    by requirement: Requirement<Context>,
    context contextProvider: @escaping @autoclosure () -> Context
  ) {
    self.requirement = requirement
    self.contextProvider = contextProvider
    self._eligibility = State(initialValue: RequirementEligibility(
      evaluation: requirement.evaluate(contextProvider())
    ))
  }
  
  public mutating func update() {
    let context = contextProvider()
    let newEligibility = RequirementEligibility(evaluation: requirement.evaluate(context))
    if eligibility != newEligibility {
      eligibility = newEligibility
    }
  }
}

// MARK: - Convenience View Extension

@available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
extension View {
  /// Применяет модификатор в зависимости от результата требования
  /// - Parameters:
  ///   - requirement: Требование для проверки
  ///   - context: Контекст для оценки
  ///   - transform: Трансформация View при выполненном требовании
  /// - Returns: Модифицированный View
  public func requirement<Context: Sendable, ModifiedContent: View>(
    _ requirement: Requirement<Context>,
    context: Context,
    @ViewBuilder transform: (Self) -> ModifiedContent
  ) -> some View {
    let evaluation = requirement.evaluate(context)
    if evaluation.isConfirmed {
      return AnyView(transform(self))
    } else {
      return AnyView(self)
    }
  }
}

#endif

