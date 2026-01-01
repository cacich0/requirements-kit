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

