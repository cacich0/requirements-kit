import Foundation

// MARK: - Валидационные атрибуты для @RequirementModel
// Эти атрибуты используются как маркеры для @RequirementModel макроса

/// Атрибут для указания минимальной длины строки
///
/// Использование:
/// ```swift
/// @RequirementModel
/// struct User {
///   @MinLength(3)
///   var username: String
/// }
/// ```
@attached(peer)
public macro MinLength(_ minLength: Int) = #externalMacro(module: "RequirementsKitMacros", type: "ValidationAttributeMacro")

/// Атрибут для указания максимальной длины строки
///
/// Использование:
/// ```swift
/// @RequirementModel
/// struct User {
///   @MaxLength(20)
///   var username: String
/// }
/// ```
@attached(peer)
public macro MaxLength(_ maxLength: Int) = #externalMacro(module: "RequirementsKitMacros", type: "ValidationAttributeMacro")

/// Атрибут для валидации email
///
/// Использование:
/// ```swift
/// @RequirementModel
/// struct User {
///   @Email
///   var email: String
/// }
/// ```
@attached(peer)
public macro Email() = #externalMacro(module: "RequirementsKitMacros", type: "ValidationAttributeMacro")

/// Атрибут для валидации телефона
///
/// Использование:
/// ```swift
/// @RequirementModel
/// struct User {
///   @Phone
///   var phoneNumber: String
/// }
/// ```
@attached(peer)
public macro Phone() = #externalMacro(module: "RequirementsKitMacros", type: "ValidationAttributeMacro")

/// Атрибут для валидации URL
///
/// Использование:
/// ```swift
/// @RequirementModel
/// struct User {
///   @URL
///   var website: String
/// }
/// ```
@attached(peer)
public macro URL() = #externalMacro(module: "RequirementsKitMacros", type: "ValidationAttributeMacro")

/// Атрибут для указания, что коллекция не должна быть пустой
///
/// Использование:
/// ```swift
/// @RequirementModel
/// struct Order {
///   @NotEmpty
///   var items: [String]
/// }
/// ```
@attached(peer)
public macro NotEmpty() = #externalMacro(module: "RequirementsKitMacros", type: "ValidationAttributeMacro")

/// Атрибут для указания диапазона значений
///
/// Использование:
/// ```swift
/// @RequirementModel
/// struct User {
///   @InRange(18...120)
///   var age: Int
/// }
/// ```
@attached(peer)
public macro InRange<T: Comparable>(_ range: ClosedRange<T>) = #externalMacro(module: "RequirementsKitMacros", type: "ValidationAttributeMacro")

/// Атрибут для указания, что значение не должно быть nil
///
/// Использование:
/// ```swift
/// @RequirementModel
/// struct User {
///   @NonNil
///   var userId: String?
/// }
/// ```
@attached(peer)
public macro NonNil() = #externalMacro(module: "RequirementsKitMacros", type: "ValidationAttributeMacro")

/// Атрибут для валидации, что строка не пустая (после trim)
///
/// Использование:
/// ```swift
/// @RequirementModel
/// struct User {
///   @NotBlank
///   var name: String
/// }
/// ```
@attached(peer)
public macro NotBlank() = #externalMacro(module: "RequirementsKitMacros", type: "ValidationAttributeMacro")

/// Атрибут для кастомной валидации с regex паттерном
///
/// Использование:
/// ```swift
/// @RequirementModel
/// struct User {
///   @Matches(#"^[a-zA-Z0-9]+$"#)
///   var username: String
/// }
/// ```
@attached(peer)
public macro Matches(_ pattern: String) = #externalMacro(module: "RequirementsKitMacros", type: "ValidationAttributeMacro")

