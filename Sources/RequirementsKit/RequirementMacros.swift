// MARK: - #require Макросы

/// Макрос для декларативного создания требований в DSL
///
/// Использование:
/// ```swift
/// let requirement = #all {
///   #require(\.user.isLoggedIn)
///   #require(\.user.balance, greaterThan: 100)
/// }
/// ```
@freestanding(expression)
public macro require<Context: Sendable, Value: Sendable>(_ keyPath: KeyPath<Context, Value> & Sendable) -> Requirement<Context> = #externalMacro(module: "RequirementsKitMacros", type: "RequireMacro")

@freestanding(expression)
public macro require<Context: Sendable, Value: Equatable & Sendable>(_ keyPath: KeyPath<Context, Value> & Sendable, equals value: Value) -> Requirement<Context> = #externalMacro(module: "RequirementsKitMacros", type: "RequireMacro")

@freestanding(expression)
public macro require<Context: Sendable, Value: Equatable & Sendable>(_ keyPath: KeyPath<Context, Value> & Sendable, notEquals value: Value) -> Requirement<Context> = #externalMacro(module: "RequirementsKitMacros", type: "RequireMacro")

@freestanding(expression)
public macro require<Context: Sendable, Value: Comparable & Sendable>(_ keyPath: KeyPath<Context, Value> & Sendable, greaterThan value: Value) -> Requirement<Context> = #externalMacro(module: "RequirementsKitMacros", type: "RequireMacro")

@freestanding(expression)
public macro require<Context: Sendable, Value: Comparable & Sendable>(_ keyPath: KeyPath<Context, Value> & Sendable, greaterThanOrEqual value: Value) -> Requirement<Context> = #externalMacro(module: "RequirementsKitMacros", type: "RequireMacro")

@freestanding(expression)
public macro require<Context: Sendable, Value: Comparable & Sendable>(_ keyPath: KeyPath<Context, Value> & Sendable, lessThan value: Value) -> Requirement<Context> = #externalMacro(module: "RequirementsKitMacros", type: "RequireMacro")

@freestanding(expression)
public macro require<Context: Sendable, Value: Comparable & Sendable>(_ keyPath: KeyPath<Context, Value> & Sendable, lessThanOrEqual value: Value) -> Requirement<Context> = #externalMacro(module: "RequirementsKitMacros", type: "RequireMacro")

// MARK: - Композиционные макросы

/// Макрос для композиции требований - все условия должны быть выполнены
///
/// Использование:
/// ```swift
/// let canTrade = #all {
///   #require(\.user.isLoggedIn)
///   #require(\.user.isVerified)
///   #require(\.user.balance, greaterThan: 100)
/// }
/// ```
@freestanding(expression)
public macro all<Context: Sendable>(
  @RequirementsBuilder<Context> _ builder: () -> [Requirement<Context>]
) -> Requirement<Context> = #externalMacro(module: "RequirementsKitMacros", type: "AllMacro")

/// Макрос для композиции требований - хотя бы одно условие должно быть выполнено
///
/// Использование:
/// ```swift
/// let hasAccess = #any {
///   #require(\.user.isAdmin)
///   #require(\.user.hasPremium)
///   #require(\.user.hasTrialAccess)
/// }
/// ```
@freestanding(expression)
public macro any<Context: Sendable>(
  @RequirementsBuilder<Context> _ builder: () -> [Requirement<Context>]
) -> Requirement<Context> = #externalMacro(module: "RequirementsKitMacros", type: "AnyMacro")

/// Макрос для инверсии требования
///
/// Использование:
/// ```swift
/// let notBanned = #not(#require(\.user.isBanned))
/// ```
@freestanding(expression)
public macro not<Context: Sendable>(
  _ requirement: Requirement<Context>
) -> Requirement<Context> = #externalMacro(module: "RequirementsKitMacros", type: "NotMacro")

// MARK: - Асинхронные макросы

/// Макрос для создания асинхронных требований
///
/// Использование:
/// ```swift
/// let hasValidSubscription = #asyncRequire { context in
///   let subscription = try await subscriptionService.check(context.user.id)
///   return subscription.isActive ? .confirmed : .failed(reason: ...)
/// }
/// ```
@freestanding(expression)
public macro asyncRequire<Context: Sendable>(
  _ evaluator: @escaping @Sendable (Context) async throws -> Evaluation
) -> AsyncRequirement<Context> = #externalMacro(module: "RequirementsKitMacros", type: "AsyncRequireMacro")

// MARK: - Условные макросы

/// Макрос для условной проверки требований
///
/// Использование:
/// ```swift
/// #when(\.featureFlags.betaEnabled) {
///   #require(\.user.isBetaTester)
/// }
/// ```
@freestanding(expression)
public macro when<Context: Sendable>(
  _ condition: KeyPath<Context, Bool> & Sendable,
  @RequirementsBuilder<Context> _ builder: () -> [Requirement<Context>]
) -> Requirement<Context> = #externalMacro(module: "RequirementsKitMacros", type: "WhenMacro")

/// Макрос для условной инверсии
///
/// Использование:
/// ```swift
/// #unless(\.user.isRestricted) {
///   #require(\.user.canTrade)
/// }
/// ```
@freestanding(expression)
public macro unless<Context: Sendable>(
  _ condition: KeyPath<Context, Bool> & Sendable,
  @RequirementsBuilder<Context> _ builder: () -> [Requirement<Context>]
) -> Requirement<Context> = #externalMacro(module: "RequirementsKitMacros", type: "UnlessMacro")

/// Макрос для XOR композиции (ровно одно условие должно быть выполнено)
///
/// Использование:
/// ```swift
/// #xor {
///   #require(\.user.hasPremium)
///   #require(\.user.hasTrialAccess)
/// }
/// ```
@freestanding(expression)
public macro xor<Context: Sendable>(
  @RequirementsBuilder<Context> _ builder: () -> [Requirement<Context>]
) -> Requirement<Context> = #externalMacro(module: "RequirementsKitMacros", type: "XorMacro")

/// Макрос для мягких требований (warnings, не блокируют)
///
/// Использование:
/// ```swift
/// #warn(\.user.emailVerified)
/// ```
@freestanding(expression)
public macro warn<Context: Sendable>(
  _ keyPath: KeyPath<Context, Bool> & Sendable
) -> Requirement<Context> = #externalMacro(module: "RequirementsKitMacros", type: "WarnMacro")

/// Макрос для fallback требований
///
/// Использование:
/// ```swift
/// #requireOrElse(\.primaryMethod) {
///   #require(\.fallbackMethod)
/// }
/// ```
@freestanding(expression)
public macro requireOrElse<Context: Sendable>(
  _ keyPath: KeyPath<Context, Bool> & Sendable,
  @RequirementsBuilder<Context> _ fallback: () -> [Requirement<Context>]
) -> Requirement<Context> = #externalMacro(module: "RequirementsKitMacros", type: "RequireOrElseMacro")

