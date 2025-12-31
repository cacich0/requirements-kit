#if canImport(Combine)

import Combine
import Foundation

// MARK: - Combine Integration

@available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.0, *)
extension Requirement {
  /// Создает Publisher, который испускает результат оценки при изменении контекста
  /// - Parameter contextPublisher: Publisher контекста
  /// - Returns: Publisher с результатами оценки
  public func publisher<P: Publisher>(
    context contextPublisher: P
  ) -> AnyPublisher<Evaluation, Never> where P.Output == Context, P.Failure == Never {
    let requirement = self
    return contextPublisher
      .map { context in
        requirement.evaluate(context)
      }
      .eraseToAnyPublisher()
  }
  
  /// Создает Publisher, который испускает булевый результат
  /// - Parameter contextPublisher: Publisher контекста
  /// - Returns: Publisher с булевыми результатами
  public func isAllowedPublisher<P: Publisher>(
    context contextPublisher: P
  ) -> AnyPublisher<Bool, Never> where P.Output == Context, P.Failure == Never {
    publisher(context: contextPublisher)
      .map { $0.isConfirmed }
      .eraseToAnyPublisher()
  }
  
  /// Создает Publisher с причиной отказа
  /// - Parameter contextPublisher: Publisher контекста
  /// - Returns: Publisher с опциональной причиной
  public func reasonPublisher<P: Publisher>(
    context contextPublisher: P
  ) -> AnyPublisher<Reason?, Never> where P.Output == Context, P.Failure == Never {
    publisher(context: contextPublisher)
      .map { $0.reason }
      .eraseToAnyPublisher()
  }
}

// MARK: - ReactiveRequirement

/// Обертка для реактивных требований
@available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.0, *)
public final class ReactiveRequirement<Context: Sendable>: ObservableObject {
  @Published public private(set) var evaluation: Evaluation
  @Published public private(set) var isAllowed: Bool
  @Published public private(set) var reason: Reason?
  
  private let requirement: Requirement<Context>
  private var cancellables = Set<AnyCancellable>()
  
  public init(
    requirement: Requirement<Context>,
    initialContext: Context
  ) {
    self.requirement = requirement
    let initialEvaluation = requirement.evaluate(initialContext)
    self.evaluation = initialEvaluation
    self.isAllowed = initialEvaluation.isConfirmed
    self.reason = initialEvaluation.reason
  }
  
  /// Подписывается на изменения контекста
  public func subscribe<P: Publisher>(
    to contextPublisher: P
  ) where P.Output == Context, P.Failure == Never {
    contextPublisher
      .receive(on: DispatchQueue.main)
      .sink { [weak self] context in
        self?.update(with: context)
      }
      .store(in: &cancellables)
  }
  
  /// Обновляет оценку с новым контекстом
  public func update(with context: Context) {
    evaluation = requirement.evaluate(context)
    isAllowed = evaluation.isConfirmed
    reason = evaluation.reason
  }
}

// MARK: - @RequirementPublisher Property Wrapper

/// Property wrapper для Combine-based требований
@available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.0, *)
@propertyWrapper
public struct RequirementPublisher<Context: Sendable> {
  private let requirement: Requirement<Context>
  private let contextSubject: CurrentValueSubject<Context, Never>
  
  public var wrappedValue: AnyPublisher<Evaluation, Never> {
    requirement.publisher(context: contextSubject.eraseToAnyPublisher())
  }
  
  public var projectedValue: CurrentValueSubject<Context, Never> {
    contextSubject
  }
  
  public init(by requirement: Requirement<Context>, initialContext: Context) {
    self.requirement = requirement
    self.contextSubject = CurrentValueSubject(initialContext)
  }
}

#endif

