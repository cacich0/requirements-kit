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

// MARK: - Макросы валидации строк

/// Макрос для проверки строки на соответствие регулярному выражению
///
/// Использование:
/// ```swift
/// #requireMatches(\.email, pattern: ValidationPattern.email)
/// ```
@freestanding(expression)
public macro requireMatches<Context: Sendable>(
  _ keyPath: KeyPath<Context, String> & Sendable,
  pattern: String
) -> Requirement<Context> = #externalMacro(module: "RequirementsKitMacros", type: "RequireMatchesMacro")

/// Макрос для проверки минимальной длины строки
///
/// Использование:
/// ```swift
/// #requireMinLength(\.username, 3)
/// ```
@freestanding(expression)
public macro requireMinLength<Context: Sendable>(
  _ keyPath: KeyPath<Context, String> & Sendable,
  _ minLength: Int
) -> Requirement<Context> = #externalMacro(module: "RequirementsKitMacros", type: "RequireMinLengthMacro")

/// Макрос для проверки максимальной длины строки
///
/// Использование:
/// ```swift
/// #requireMaxLength(\.username, 20)
/// ```
@freestanding(expression)
public macro requireMaxLength<Context: Sendable>(
  _ keyPath: KeyPath<Context, String> & Sendable,
  _ maxLength: Int
) -> Requirement<Context> = #externalMacro(module: "RequirementsKitMacros", type: "RequireMaxLengthMacro")

/// Макрос для проверки длины строки в диапазоне
///
/// Использование:
/// ```swift
/// #requireLength(\.password, in: 8...128)
/// ```
@freestanding(expression)
public macro requireLength<Context: Sendable>(
  _ keyPath: KeyPath<Context, String> & Sendable,
  in range: ClosedRange<Int>
) -> Requirement<Context> = #externalMacro(module: "RequirementsKitMacros", type: "RequireLengthMacro")

/// Макрос для проверки, что строка не пустая (после trim)
///
/// Использование:
/// ```swift
/// #requireNotBlank(\.name)
/// ```
@freestanding(expression)
public macro requireNotBlank<Context: Sendable>(
  _ keyPath: KeyPath<Context, String> & Sendable
) -> Requirement<Context> = #externalMacro(module: "RequirementsKitMacros", type: "RequireNotBlankMacro")

/// Макрос для валидации email
///
/// Использование:
/// ```swift
/// #requireEmail(\.email)
/// ```
@freestanding(expression)
public macro requireEmail<Context: Sendable>(
  _ keyPath: KeyPath<Context, String> & Sendable
) -> Requirement<Context> = #externalMacro(module: "RequirementsKitMacros", type: "RequireEmailMacro")

/// Макрос для валидации URL
///
/// Использование:
/// ```swift
/// #requireURL(\.website)
/// ```
@freestanding(expression)
public macro requireURL<Context: Sendable>(
  _ keyPath: KeyPath<Context, String> & Sendable
) -> Requirement<Context> = #externalMacro(module: "RequirementsKitMacros", type: "RequireURLMacro")

/// Макрос для валидации телефона (международный формат)
///
/// Использование:
/// ```swift
/// #requirePhone(\.phoneNumber)
/// ```
@freestanding(expression)
public macro requirePhone<Context: Sendable>(
  _ keyPath: KeyPath<Context, String> & Sendable
) -> Requirement<Context> = #externalMacro(module: "RequirementsKitMacros", type: "RequirePhoneMacro")

// MARK: - Макросы валидации коллекций

/// Макрос для проверки количества элементов в коллекции
///
/// Использование:
/// ```swift
/// #requireCount(\.items, min: 1, max: 50)
/// ```
@freestanding(expression)
public macro requireCount<Context: Sendable, C: Collection & Sendable>(
  _ keyPath: KeyPath<Context, C> & Sendable,
  min: Int? = nil,
  max: Int? = nil
) -> Requirement<Context> = #externalMacro(module: "RequirementsKitMacros", type: "RequireCountMacro")

/// Макрос для проверки, что коллекция не пустая
///
/// Использование:
/// ```swift
/// #requireNotEmpty(\.cart)
/// ```
@freestanding(expression)
public macro requireNotEmpty<Context: Sendable, C: Collection & Sendable>(
  _ keyPath: KeyPath<Context, C> & Sendable
) -> Requirement<Context> = #externalMacro(module: "RequirementsKitMacros", type: "RequireNotEmptyMacro")

/// Макрос для проверки, что коллекция пустая
///
/// Использование:
/// ```swift
/// #requireEmpty(\.errors)
/// ```
@freestanding(expression)
public macro requireEmpty<Context: Sendable, C: Collection & Sendable>(
  _ keyPath: KeyPath<Context, C> & Sendable
) -> Requirement<Context> = #externalMacro(module: "RequirementsKitMacros", type: "RequireEmptyMacro")

// MARK: - Макросы для Optional значений

/// Макрос для проверки, что Optional значение не nil
///
/// Использование:
/// ```swift
/// #requireNonNil(\.userId)
/// ```
@freestanding(expression)
public macro requireNonNil<Context: Sendable, Value: Sendable>(
  _ keyPath: KeyPath<Context, Value?> & Sendable
) -> Requirement<Context> = #externalMacro(module: "RequirementsKitMacros", type: "RequireNonNilMacro")

/// Макрос для проверки, что Optional значение nil
///
/// Использование:
/// ```swift
/// #requireNil(\.tempData)
/// ```
@freestanding(expression)
public macro requireNil<Context: Sendable, Value: Sendable>(
  _ keyPath: KeyPath<Context, Value?> & Sendable
) -> Requirement<Context> = #externalMacro(module: "RequirementsKitMacros", type: "RequireNilMacro")

/// Макрос для проверки, что Optional содержит значение, удовлетворяющее условию
///
/// Использование:
/// ```swift
/// #requireSome(\.age, where: { $0 >= 18 })
/// ```
@freestanding(expression)
public macro requireSome<Context: Sendable, Value: Sendable>(
  _ keyPath: KeyPath<Context, Value?> & Sendable,
  where predicate: @escaping @Sendable (Value) -> Bool
) -> Requirement<Context> = #externalMacro(module: "RequirementsKitMacros", type: "RequireSomeMacro")

// MARK: - Макросы для работы с диапазонами

/// Макрос для проверки, что значение находится в диапазоне
///
/// Использование:
/// ```swift
/// #requireInRange(\.age, 18...120)
/// ```
@freestanding(expression)
public macro requireInRange<Context: Sendable, Value: Comparable & Sendable>(
  _ keyPath: KeyPath<Context, Value> & Sendable,
  _ range: ClosedRange<Value>
) -> Requirement<Context> = #externalMacro(module: "RequirementsKitMacros", type: "RequireInRangeMacro")

/// Макрос для проверки, что значение находится между min и max
///
/// Использование:
/// ```swift
/// #requireBetween(\.amount, min: 10, max: 1000)
/// ```
@freestanding(expression)
public macro requireBetween<Context: Sendable, Value: Comparable & Sendable>(
  _ keyPath: KeyPath<Context, Value> & Sendable,
  min: Value,
  max: Value
) -> Requirement<Context> = #externalMacro(module: "RequirementsKitMacros", type: "RequireBetweenMacro")

// MARK: - Attached макрос @RequirementModel

/// Attached макрос для автоматической генерации метода validate() на основе валидационных атрибутов
///
/// Использование:
/// ```swift
/// @RequirementModel
/// struct User {
///   @MinLength(3) @MaxLength(20)
///   var username: String
///
///   @Email
///   var email: String
///
///   @InRange(18...120)
///   var age: Int
/// }
/// ```
///
/// Генерирует метод validate() -> Evaluation, который проверяет все поля с атрибутами
@attached(member, names: named(validate))
public macro RequirementModel() = #externalMacro(module: "RequirementsKitMacros", type: "RequirementModelMacro")

// MARK: - Decision макросы

/// Макрос для создания решений на основе контекста
///
/// Использование:
/// ```swift
/// let routeDecision = #decide { ctx in
///   if ctx.isAuthenticated { return .dashboard }
///   if ctx.hasSession { return .login }
///   return .welcome
/// }
/// ```
@freestanding(expression)
public macro decide<Context: Sendable, Result: Sendable>(
  _ decider: @escaping @Sendable (Context) -> Result?
) -> Decision<Context, Result> = #externalMacro(module: "RequirementsKitMacros", type: "DecideMacro")

/// Макрос для создания асинхронных решений на основе контекста
///
/// Использование:
/// ```swift
/// let routeDecision = #asyncDecide { ctx in
///   let user = try await userService.fetch(ctx.userId)
///   if user.isPremium { return .premiumDashboard }
///   return .standardDashboard
/// }
/// ```
@freestanding(expression)
public macro asyncDecide<Context: Sendable, Result: Sendable>(
  _ decider: @escaping @Sendable (Context) async throws -> Result?
) -> AsyncDecision<Context, Result> = #externalMacro(module: "RequirementsKitMacros", type: "AsyncDecideMacro")

/// Attached макрос для property wrapper, который автоматически принимает решение
///
/// Использование:
/// ```swift
/// @Decided(decision: routeDecision, context: requestContext)
/// var currentRoute: Route
/// ```
@attached(accessor)
public macro Decided<Context: Sendable, Result: Sendable>(
  decision: Decision<Context, Result>,
  context: Context
) = #externalMacro(module: "RequirementsKitMacros", type: "DecidedMacro")

// MARK: - Decision KeyPath макросы

/// Макрос для создания условного решения на основе Bool KeyPath
///
/// Использование:
/// ```swift
/// #whenDecision(\.user.isAdmin, return: .adminPanel)
/// ```
@freestanding(expression)
public macro whenDecision<Context: Sendable, Result: Sendable>(
  _ keyPath: KeyPath<Context, Bool> & Sendable,
  return value: Result
) -> Decision<Context, Result> = #externalMacro(module: "RequirementsKitMacros", type: "WhenDecisionMacro")

/// Макрос для создания условного решения на основе Bool KeyPath с замыканием
///
/// Использование:
/// ```swift
/// #whenDecision(\.user.isAdmin) { context in
///   return .adminPanel
/// }
/// ```
@freestanding(expression)
public macro whenDecision<Context: Sendable, Result: Sendable>(
  _ keyPath: KeyPath<Context, Bool> & Sendable,
  @DecisionsBuilder<Context, Result> _ valueBuilder: () -> Decision<Context, Result>
) -> Decision<Context, Result> = #externalMacro(module: "RequirementsKitMacros", type: "WhenDecisionMacro")

/// Макрос для создания условного решения с проверкой равенства
///
/// Использование:
/// ```swift
/// #whenDecision(\.user.role, equals: .admin, return: .adminPanel)
/// ```
@freestanding(expression)
public macro whenDecision<Context: Sendable, Value: Equatable & Sendable, Result: Sendable>(
  _ keyPath: KeyPath<Context, Value> & Sendable,
  equals expectedValue: Value,
  return value: Result
) -> Decision<Context, Result> = #externalMacro(module: "RequirementsKitMacros", type: "WhenDecisionMacro")

/// Макрос для создания условного решения с проверкой неравенства
///
/// Использование:
/// ```swift
/// #whenDecision(\.user.status, notEquals: .banned, return: .dashboard)
/// ```
@freestanding(expression)
public macro whenDecision<Context: Sendable, Value: Equatable & Sendable, Result: Sendable>(
  _ keyPath: KeyPath<Context, Value> & Sendable,
  notEquals expectedValue: Value,
  return value: Result
) -> Decision<Context, Result> = #externalMacro(module: "RequirementsKitMacros", type: "WhenDecisionMacro")

/// Макрос для создания условного решения с проверкой "больше чем"
///
/// Использование:
/// ```swift
/// #whenDecision(\.user.balance, greaterThan: 1000, return: .premiumFeature)
/// ```
@freestanding(expression)
public macro whenDecision<Context: Sendable, Value: Comparable & Sendable, Result: Sendable>(
  _ keyPath: KeyPath<Context, Value> & Sendable,
  greaterThan threshold: Value,
  return value: Result
) -> Decision<Context, Result> = #externalMacro(module: "RequirementsKitMacros", type: "WhenDecisionMacro")

/// Макрос для создания условного решения с проверкой "больше или равно"
///
/// Использование:
/// ```swift
/// #whenDecision(\.user.level, greaterThanOrEqual: 10, return: .advancedMode)
/// ```
@freestanding(expression)
public macro whenDecision<Context: Sendable, Value: Comparable & Sendable, Result: Sendable>(
  _ keyPath: KeyPath<Context, Value> & Sendable,
  greaterThanOrEqual threshold: Value,
  return value: Result
) -> Decision<Context, Result> = #externalMacro(module: "RequirementsKitMacros", type: "WhenDecisionMacro")

/// Макрос для создания условного решения с проверкой "меньше чем"
///
/// Использование:
/// ```swift
/// #whenDecision(\.user.age, lessThan: 18, return: .restrictedMode)
/// ```
@freestanding(expression)
public macro whenDecision<Context: Sendable, Value: Comparable & Sendable, Result: Sendable>(
  _ keyPath: KeyPath<Context, Value> & Sendable,
  lessThan threshold: Value,
  return value: Result
) -> Decision<Context, Result> = #externalMacro(module: "RequirementsKitMacros", type: "WhenDecisionMacro")

/// Макрос для создания условного решения с проверкой "меньше или равно"
///
/// Использование:
/// ```swift
/// #whenDecision(\.stock.quantity, lessThanOrEqual: 0, return: .outOfStock)
/// ```
@freestanding(expression)
public macro whenDecision<Context: Sendable, Value: Comparable & Sendable, Result: Sendable>(
  _ keyPath: KeyPath<Context, Value> & Sendable,
  lessThanOrEqual threshold: Value,
  return value: Result
) -> Decision<Context, Result> = #externalMacro(module: "RequirementsKitMacros", type: "WhenDecisionMacro")

/// Макрос для создания условного решения с отрицанием (unless)
///
/// Использование:
/// ```swift
/// #unlessDecision(\.user.isBanned, return: .accessGranted)
/// ```
@freestanding(expression)
public macro unlessDecision<Context: Sendable, Result: Sendable>(
  _ keyPath: KeyPath<Context, Bool> & Sendable,
  return value: Result
) -> Decision<Context, Result> = #externalMacro(module: "RequirementsKitMacros", type: "UnlessDecisionMacro")

// MARK: - Decision композиционные макросы

/// Макрос для создания решения из нескольких вариантов (возвращает первое совпадение)
///
/// Использование:
/// ```swift
/// let route = #firstMatch {
///   #whenDecision(\.user.isAdmin, return: .adminPanel)
///   #whenDecision(\.user.isPremium, return: .premiumDashboard)
///   #whenDecision(\.user.isLoggedIn, return: .dashboard)
/// }
/// ```
@freestanding(expression)
public macro firstMatch<Context: Sendable, Result: Sendable>(
  @DecisionsBuilder<Context, Result> _ builder: () -> Decision<Context, Result>
) -> Decision<Context, Result> = #externalMacro(module: "RequirementsKitMacros", type: "FirstMatchMacro")

/// Макрос для создания switch-подобного решения на основе KeyPath
///
/// Использование:
/// ```swift
/// #matchDecision(\.user.role) {
///   (.admin, .adminPanel)
///   (.user, .userDashboard)
///   (.guest, .guestView)
/// }
/// ```
@freestanding(expression)
public macro matchDecision<Context: Sendable, Key: Equatable & Hashable & Sendable, Result: Sendable>(
  _ keyPath: KeyPath<Context, Key> & Sendable,
  @MatchCasesBuilder<Context, Key, Result> casesBuilder: () -> [(Key, Decision<Context, Result>)]
) -> Decision<Context, Result> = #externalMacro(module: "RequirementsKitMacros", type: "MatchDecisionMacro")

/// Макрос для fallback значения по умолчанию
///
/// Использование:
/// ```swift
/// let decision = someDecision.#orElse(.defaultValue)
/// // или в firstMatch:
/// #firstMatch {
///   #whenDecision(\.condition, return: .value)
///   #orElse(.defaultValue)
/// }
/// ```
@freestanding(expression)
public macro orElse<Context: Sendable, Result: Sendable>(
  _ defaultValue: Result
) -> Decision<Context, Result> = #externalMacro(module: "RequirementsKitMacros", type: "OrElseMacro")

// MARK: - Decision интеграция с Requirement

/// Макрос для создания решения на основе требования
///
/// Использование:
/// ```swift
/// #whenMet(#require(\.user.isVIP), return: 0.2)
/// ```
@freestanding(expression)
public macro whenMet<Context: Sendable, Result: Sendable>(
  _ requirement: Requirement<Context>,
  return value: Result
) -> Decision<Context, Result> = #externalMacro(module: "RequirementsKitMacros", type: "WhenMetMacro")

/// Макрос для создания решения на основе требования с замыканием
///
/// Использование:
/// ```swift
/// #whenMet(#require(\.user.isVIP)) { context in
///   return context.calculateVIPDiscount()
/// }
/// ```
@freestanding(expression)
public macro whenMet<Context: Sendable, Result: Sendable>(
  _ requirement: Requirement<Context>,
  _ valueBuilder: @escaping @Sendable (Context) -> Result
) -> Decision<Context, Result> = #externalMacro(module: "RequirementsKitMacros", type: "WhenMetMacro")

// MARK: - Async Decision KeyPath макросы

/// Макрос для создания асинхронного условного решения на основе Bool KeyPath
///
/// Использование:
/// ```swift
/// #asyncWhenDecision(\.user.isAdmin, return: .adminPanel)
/// ```
@freestanding(expression)
public macro asyncWhenDecision<Context: Sendable, Result: Sendable>(
  _ keyPath: KeyPath<Context, Bool> & Sendable,
  return value: Result
) -> AsyncDecision<Context, Result> = #externalMacro(module: "RequirementsKitMacros", type: "AsyncWhenDecisionMacro")

/// Макрос для создания асинхронного условного решения с проверкой равенства
///
/// Использование:
/// ```swift
/// #asyncWhenDecision(\.user.role, equals: .admin, return: .adminPanel)
/// ```
@freestanding(expression)
public macro asyncWhenDecision<Context: Sendable, Value: Equatable & Sendable, Result: Sendable>(
  _ keyPath: KeyPath<Context, Value> & Sendable,
  equals expectedValue: Value,
  return value: Result
) -> AsyncDecision<Context, Result> = #externalMacro(module: "RequirementsKitMacros", type: "AsyncWhenDecisionMacro")

/// Макрос для создания асинхронного условного решения с проверкой неравенства
///
/// Использование:
/// ```swift
/// #asyncWhenDecision(\.user.status, notEquals: .banned, return: .dashboard)
/// ```
@freestanding(expression)
public macro asyncWhenDecision<Context: Sendable, Value: Equatable & Sendable, Result: Sendable>(
  _ keyPath: KeyPath<Context, Value> & Sendable,
  notEquals expectedValue: Value,
  return value: Result
) -> AsyncDecision<Context, Result> = #externalMacro(module: "RequirementsKitMacros", type: "AsyncWhenDecisionMacro")

/// Макрос для создания асинхронного условного решения с проверкой "больше чем"
///
/// Использование:
/// ```swift
/// #asyncWhenDecision(\.user.balance, greaterThan: 1000, return: .premiumFeature)
/// ```
@freestanding(expression)
public macro asyncWhenDecision<Context: Sendable, Value: Comparable & Sendable, Result: Sendable>(
  _ keyPath: KeyPath<Context, Value> & Sendable,
  greaterThan threshold: Value,
  return value: Result
) -> AsyncDecision<Context, Result> = #externalMacro(module: "RequirementsKitMacros", type: "AsyncWhenDecisionMacro")

/// Макрос для создания асинхронного условного решения с проверкой "больше или равно"
///
/// Использование:
/// ```swift
/// #asyncWhenDecision(\.user.level, greaterThanOrEqual: 10, return: .advancedMode)
/// ```
@freestanding(expression)
public macro asyncWhenDecision<Context: Sendable, Value: Comparable & Sendable, Result: Sendable>(
  _ keyPath: KeyPath<Context, Value> & Sendable,
  greaterThanOrEqual threshold: Value,
  return value: Result
) -> AsyncDecision<Context, Result> = #externalMacro(module: "RequirementsKitMacros", type: "AsyncWhenDecisionMacro")

/// Макрос для создания асинхронного условного решения с проверкой "меньше чем"
///
/// Использование:
/// ```swift
/// #asyncWhenDecision(\.user.age, lessThan: 18, return: .restrictedMode)
/// ```
@freestanding(expression)
public macro asyncWhenDecision<Context: Sendable, Value: Comparable & Sendable, Result: Sendable>(
  _ keyPath: KeyPath<Context, Value> & Sendable,
  lessThan threshold: Value,
  return value: Result
) -> AsyncDecision<Context, Result> = #externalMacro(module: "RequirementsKitMacros", type: "AsyncWhenDecisionMacro")

/// Макрос для создания асинхронного условного решения с проверкой "меньше или равно"
///
/// Использование:
/// ```swift
/// #asyncWhenDecision(\.stock.quantity, lessThanOrEqual: 0, return: .outOfStock)
/// ```
@freestanding(expression)
public macro asyncWhenDecision<Context: Sendable, Value: Comparable & Sendable, Result: Sendable>(
  _ keyPath: KeyPath<Context, Value> & Sendable,
  lessThanOrEqual threshold: Value,
  return value: Result
) -> AsyncDecision<Context, Result> = #externalMacro(module: "RequirementsKitMacros", type: "AsyncWhenDecisionMacro")

/// Макрос для создания асинхронного условного решения с отрицанием (unless)
///
/// Использование:
/// ```swift
/// #asyncUnlessDecision(\.user.isBanned, return: .accessGranted)
/// ```
@freestanding(expression)
public macro asyncUnlessDecision<Context: Sendable, Result: Sendable>(
  _ keyPath: KeyPath<Context, Bool> & Sendable,
  return value: Result
) -> AsyncDecision<Context, Result> = #externalMacro(module: "RequirementsKitMacros", type: "AsyncUnlessDecisionMacro")

// MARK: - Async Decision композиционные макросы

/// Макрос для создания асинхронного решения из нескольких вариантов (возвращает первое совпадение)
///
/// Использование:
/// ```swift
/// let route = #asyncFirstMatch {
///   #asyncWhenDecision(\.user.isAdmin, return: .adminPanel)
///   #asyncWhenDecision(\.user.isPremium, return: .premiumDashboard)
/// }
/// ```
@freestanding(expression)
public macro asyncFirstMatch<Context: Sendable, Result: Sendable>(
  @AsyncDecisionsBuilder<Context, Result> _ builder: () -> AsyncDecision<Context, Result>
) -> AsyncDecision<Context, Result> = #externalMacro(module: "RequirementsKitMacros", type: "AsyncFirstMatchMacro")

/// Макрос для создания асинхронного switch-подобного решения на основе KeyPath
///
/// Использование:
/// ```swift
/// #asyncMatchDecision(\.user.role) {
///   (.admin, .adminPanel)
///   (.user, .userDashboard)
/// }
/// ```
@freestanding(expression)
public macro asyncMatchDecision<Context: Sendable, Key: Equatable & Hashable & Sendable, Result: Sendable>(
  _ keyPath: KeyPath<Context, Key> & Sendable,
  @AsyncMatchCasesBuilder<Context, Key, Result> casesBuilder: () -> [(Key, AsyncDecision<Context, Result>)]
) -> AsyncDecision<Context, Result> = #externalMacro(module: "RequirementsKitMacros", type: "AsyncMatchDecisionMacro")

/// Макрос для асинхронного fallback значения по умолчанию
///
/// Использование:
/// ```swift
/// #asyncOrElse(.defaultValue)
/// ```
@freestanding(expression)
public macro asyncOrElse<Context: Sendable, Result: Sendable>(
  _ defaultValue: Result
) -> AsyncDecision<Context, Result> = #externalMacro(module: "RequirementsKitMacros", type: "AsyncOrElseMacro")

// MARK: - Async Decision интеграция с Requirement

/// Макрос для создания асинхронного решения на основе требования
///
/// Использование:
/// ```swift
/// #asyncWhenMet(#require(\.user.isVIP), return: 0.2)
/// ```
@freestanding(expression)
public macro asyncWhenMet<Context: Sendable, Result: Sendable>(
  _ requirement: Requirement<Context>,
  return value: Result
) -> AsyncDecision<Context, Result> = #externalMacro(module: "RequirementsKitMacros", type: "AsyncWhenMetMacro")

/// Макрос для создания асинхронного решения на основе требования с замыканием
///
/// Использование:
/// ```swift
/// #asyncWhenMet(#require(\.user.isVIP)) { context in
///   return await context.calculateVIPDiscount()
/// }
/// ```
@freestanding(expression)
public macro asyncWhenMet<Context: Sendable, Result: Sendable>(
  _ requirement: Requirement<Context>,
  _ valueBuilder: @escaping @Sendable (Context) async -> Result
) -> AsyncDecision<Context, Result> = #externalMacro(module: "RequirementsKitMacros", type: "AsyncWhenMetMacro")

/// Макрос для создания асинхронного решения на основе асинхронного требования
///
/// Использование:
/// ```swift
/// #asyncWhenMet(#asyncRequire { ctx in ... }, return: .value)
/// ```
@freestanding(expression)
public macro asyncWhenMet<Context: Sendable, Result: Sendable>(
  _ requirement: AsyncRequirement<Context>,
  return value: Result
) -> AsyncDecision<Context, Result> = #externalMacro(module: "RequirementsKitMacros", type: "AsyncWhenMetMacro")

