import SwiftCompilerPlugin
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

/// Пустой peer макрос для валидационных атрибутов
/// Эти атрибуты используются только как маркеры для @RequirementModel
public struct ValidationAttributeMacro: PeerMacro {
  public static func expansion(
    of node: AttributeSyntax,
    providingPeersOf declaration: some DeclSyntaxProtocol,
    in context: some MacroExpansionContext
  ) throws -> [DeclSyntax] {
    // Атрибуты не генерируют дополнительный код, они только маркеры
    return []
  }
}

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
/// Генерирует:
/// ```swift
/// func validate() -> Evaluation {
///   let requirements: [Requirement<Self>] = [
///     Requirement.requireMinLength(\.username, minLength: 3),
///     Requirement.requireMaxLength(\.username, maxLength: 20),
///     Requirement.requireMatches(\.email, pattern: ValidationPattern.email),
///     Requirement.requireInRange(\.age, 18...120)
///   ]
///   return Requirement.all(requirements).evaluate(self)
/// }
/// ```
public struct RequirementModelMacro: MemberMacro {
  public static func expansion(
    of node: AttributeSyntax,
    providingMembersOf declaration: some DeclGroupSyntax,
    in context: some MacroExpansionContext
  ) throws -> [DeclSyntax] {
    
    // Проверяем, что это struct или class
    guard let structDecl = declaration.as(StructDeclSyntax.self) ??
                           declaration.as(ClassDeclSyntax.self).map({ $0 as? DeclGroupSyntax }) as? StructDeclSyntax
    else {
      return []
    }
    
    // Собираем все свойства с валидационными атрибутами
    var validationRequirements: [String] = []
    
    for member in structDecl.memberBlock.members {
      guard let variable = member.decl.as(VariableDeclSyntax.self),
            let binding = variable.bindings.first,
            let propertyName = binding.pattern.as(IdentifierPatternSyntax.self)?.identifier.text
      else {
        continue
      }
      
      // Проверяем атрибуты этого свойства
      for attribute in variable.attributes {
        guard let attr = attribute.as(AttributeSyntax.self),
              let attrName = attr.attributeName.as(IdentifierTypeSyntax.self)?.name.text
        else {
          continue
        }
        
        // Генерируем требования на основе атрибутов
        switch attrName {
        case "MinLength":
          if let args = attr.arguments?.as(LabeledExprListSyntax.self),
             let firstArg = args.first?.expression {
            validationRequirements.append(
              "Requirement.requireMinLength(\\.\(propertyName), minLength: \(firstArg))"
            )
          }
          
        case "MaxLength":
          if let args = attr.arguments?.as(LabeledExprListSyntax.self),
             let firstArg = args.first?.expression {
            validationRequirements.append(
              "Requirement.requireMaxLength(\\.\(propertyName), maxLength: \(firstArg))"
            )
          }
          
        case "Email":
          validationRequirements.append(
            "Requirement.requireMatches(\\.\(propertyName), pattern: ValidationPattern.email)"
          )
          
        case "Phone":
          validationRequirements.append(
            "Requirement.requireMatches(\\.\(propertyName), pattern: ValidationPattern.phoneInternational)"
          )
          
        case "URL":
          validationRequirements.append(
            "Requirement.requireMatches(\\.\(propertyName), pattern: ValidationPattern.url)"
          )
          
        case "NotEmpty":
          validationRequirements.append(
            "Requirement.requireNotEmpty(\\.\(propertyName))"
          )
          
        case "InRange":
          if let args = attr.arguments?.as(LabeledExprListSyntax.self),
             let firstArg = args.first?.expression {
            validationRequirements.append(
              "Requirement { context in " +
              "let value = context.\(propertyName); " +
              "let range = \(firstArg); " +
              "return range.contains(value) ? .confirmed : " +
              ".failed(reason: Reason(code: \"range.out_of_bounds\", message: \"Value must be in range\")) " +
              "}"
            )
          }
          
        case "NonNil":
          validationRequirements.append(
            "Requirement { context in " +
            "context.\(propertyName) != nil ? .confirmed : " +
            ".failed(reason: Reason(code: \"optional.is_nil\", message: \"Value must not be nil\")) " +
            "}"
          )
          
        case "NotBlank":
          validationRequirements.append(
            "Requirement.requireNotBlank(\\.\(propertyName))"
          )
          
        case "Matches":
          if let args = attr.arguments?.as(LabeledExprListSyntax.self),
             let firstArg = args.first?.expression {
            validationRequirements.append(
              "Requirement.requireMatches(\\.\(propertyName), pattern: \(firstArg))"
            )
          }
          
        default:
          break
        }
      }
    }
    
    // Если нет валидационных требований, не генерируем метод
    guard !validationRequirements.isEmpty else {
      return []
    }
    
    // Генерируем метод validate()
    let requirementsArray = validationRequirements.joined(separator: ",\n      ")
    
    let validateMethod = """
    
    /// Валидирует все поля модели с валидационными атрибутами
    /// - Returns: Результат валидации
    public func validate() -> Evaluation {
      let requirements: [Requirement<Self>] = [
        \(requirementsArray)
      ]
      return Requirement.all(requirements).evaluate(self)
    }
    """
    
    return [DeclSyntax(stringLiteral: validateMethod)]
  }
}

