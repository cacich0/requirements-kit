import SwiftCompilerPlugin
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

// MARK: - #require Макрос

/// Макрос для создания требований в DSL
/// Преобразует #require(\.keyPath) в Requirement.require(\.keyPath)
/// Поддерживает дополнительные аргументы: #require(\.value, greaterThan: 100)
public struct RequireMacro: ExpressionMacro {
  public static func expansion(
    of node: some FreestandingMacroExpansionSyntax,
    in context: some MacroExpansionContext
  ) -> ExprSyntax {
    // Получаем все аргументы макроса
    guard !node.arguments.isEmpty else {
      return "Requirement.always"
    }
    
    // Создаем вызов Requirement.require со всеми аргументами
    return ExprSyntax(
      FunctionCallExprSyntax(
        calledExpression: MemberAccessExprSyntax(
          base: DeclReferenceExprSyntax(baseName: "Requirement"),
          period: .periodToken(),
          declName: DeclReferenceExprSyntax(baseName: "require")
        ),
        leftParen: .leftParenToken(),
        arguments: node.arguments,
        rightParen: .rightParenToken()
      )
    )
  }
}

// MARK: - #all Макрос

/// Макрос для композиции требований (все должны быть выполнены)
/// Преобразует #all { ... } в Requirement.all { ... }
public struct AllMacro: ExpressionMacro {
  public static func expansion(
    of node: some FreestandingMacroExpansionSyntax,
    in context: some MacroExpansionContext
  ) -> ExprSyntax {
    guard let closure = node.trailingClosure else {
      return "Requirement.always"
    }
    
    return ExprSyntax(
      FunctionCallExprSyntax(
        calledExpression: MemberAccessExprSyntax(
          base: DeclReferenceExprSyntax(baseName: "Requirement"),
          period: .periodToken(),
          declName: DeclReferenceExprSyntax(baseName: "all")
        ),
        leftParen: nil,
        arguments: [],
        rightParen: nil,
        trailingClosure: closure
      )
    )
  }
}

// MARK: - #any Макрос

/// Макрос для композиции требований (хотя бы одно должно быть выполнено)
/// Преобразует #any { ... } в Requirement.any { ... }
public struct AnyMacro: ExpressionMacro {
  public static func expansion(
    of node: some FreestandingMacroExpansionSyntax,
    in context: some MacroExpansionContext
  ) -> ExprSyntax {
    guard let closure = node.trailingClosure else {
      return "Requirement.never"
    }
    
    return ExprSyntax(
      FunctionCallExprSyntax(
        calledExpression: MemberAccessExprSyntax(
          base: DeclReferenceExprSyntax(baseName: "Requirement"),
          period: .periodToken(),
          declName: DeclReferenceExprSyntax(baseName: "any")
        ),
        leftParen: nil,
        arguments: [],
        rightParen: nil,
        trailingClosure: closure
      )
    )
  }
}

// MARK: - #not Макрос

/// Макрос для инверсии требования
/// Преобразует #not(requirement) в Requirement.not(requirement)
public struct NotMacro: ExpressionMacro {
  public static func expansion(
    of node: some FreestandingMacroExpansionSyntax,
    in context: some MacroExpansionContext
  ) -> ExprSyntax {
    guard let argument = node.arguments.first?.expression else {
      return "Requirement.always"
    }
    
    return ExprSyntax(
      FunctionCallExprSyntax(
        calledExpression: MemberAccessExprSyntax(
          base: DeclReferenceExprSyntax(baseName: "Requirement"),
          period: .periodToken(),
          declName: DeclReferenceExprSyntax(baseName: "not")
        ),
        leftParen: .leftParenToken(),
        arguments: LabeledExprListSyntax([
          LabeledExprSyntax(expression: argument)
        ]),
        rightParen: .rightParenToken()
      )
    )
  }
}

// MARK: - #asyncRequire Макрос

/// Макрос для создания асинхронных требований
/// Преобразует #asyncRequire { context in ... } в AsyncRequirement { context in ... }
public struct AsyncRequireMacro: ExpressionMacro {
  public static func expansion(
    of node: some FreestandingMacroExpansionSyntax,
    in context: some MacroExpansionContext
  ) -> ExprSyntax {
    guard let closure = node.trailingClosure else {
      return "AsyncRequirement.always"
    }
    
    return ExprSyntax(
      FunctionCallExprSyntax(
        calledExpression: DeclReferenceExprSyntax(baseName: "AsyncRequirement"),
        leftParen: nil,
        arguments: [],
        rightParen: nil,
        trailingClosure: closure
      )
    )
  }
}

// MARK: - #when Макрос

/// Макрос для условной оценки требований
/// Преобразует #when(\.condition) { ... } в условную композицию
public struct WhenMacro: ExpressionMacro {
  public static func expansion(
    of node: some FreestandingMacroExpansionSyntax,
    in context: some MacroExpansionContext
  ) -> ExprSyntax {
    guard let condition = node.arguments.first?.expression,
          let closure = node.trailingClosure else {
      return "Requirement.always"
    }
    
    return "Requirement.when(\(condition)) \(closure)"
  }
}

// MARK: - #unless Макрос

/// Макрос для условной инверсии
/// Преобразует #unless(\.condition) { ... } в условную композицию с инверсией
public struct UnlessMacro: ExpressionMacro {
  public static func expansion(
    of node: some FreestandingMacroExpansionSyntax,
    in context: some MacroExpansionContext
  ) -> ExprSyntax {
    guard let condition = node.arguments.first?.expression,
          let closure = node.trailingClosure else {
      return "Requirement.always"
    }
    
    return "Requirement.unless(\(condition)) \(closure)"
  }
}

// MARK: - #xor Макрос

/// Макрос для XOR композиции (ровно одно условие должно быть выполнено)
public struct XorMacro: ExpressionMacro {
  public static func expansion(
    of node: some FreestandingMacroExpansionSyntax,
    in context: some MacroExpansionContext
  ) -> ExprSyntax {
    guard let closure = node.trailingClosure else {
      return "Requirement.never"
    }
    
    return ExprSyntax(
      FunctionCallExprSyntax(
        calledExpression: MemberAccessExprSyntax(
          base: DeclReferenceExprSyntax(baseName: "Requirement"),
          period: .periodToken(),
          declName: DeclReferenceExprSyntax(baseName: "xor")
        ),
        leftParen: nil,
        arguments: [],
        rightParen: nil,
        trailingClosure: closure
      )
    )
  }
}

// MARK: - #warn Макрос

/// Макрос для мягких требований (warnings, не блокируют)
public struct WarnMacro: ExpressionMacro {
  public static func expansion(
    of node: some FreestandingMacroExpansionSyntax,
    in context: some MacroExpansionContext
  ) -> ExprSyntax {
    guard !node.arguments.isEmpty else {
      return "Requirement.always"
    }
    
    return ExprSyntax(
      FunctionCallExprSyntax(
        calledExpression: MemberAccessExprSyntax(
          base: DeclReferenceExprSyntax(baseName: "Requirement"),
          period: .periodToken(),
          declName: DeclReferenceExprSyntax(baseName: "warn")
        ),
        leftParen: .leftParenToken(),
        arguments: node.arguments,
        rightParen: .rightParenToken()
      )
    )
  }
}

// MARK: - #requireOrElse Макрос (Fallback)

/// Макрос для fallback требований
/// Преобразует #requireOrElse(\.primary) { fallback } в Requirement с fallback
public struct RequireOrElseMacro: ExpressionMacro {
  public static func expansion(
    of node: some FreestandingMacroExpansionSyntax,
    in context: some MacroExpansionContext
  ) -> ExprSyntax {
    guard let primary = node.arguments.first?.expression,
          let closure = node.trailingClosure else {
      return "Requirement.always"
    }
    
    return "Requirement.require(\(primary)).fallback \(closure)"
  }
}

// MARK: - String Validation Macros

/// Макрос для проверки строки на соответствие регулярному выражению
/// Преобразует #requireMatches(\.email, pattern: "...") в Requirement.requireMatches(\.email, pattern: "...")
public struct RequireMatchesMacro: ExpressionMacro {
  public static func expansion(
    of node: some FreestandingMacroExpansionSyntax,
    in context: some MacroExpansionContext
  ) -> ExprSyntax {
    guard !node.arguments.isEmpty else {
      return "Requirement.always"
    }
    
    return ExprSyntax(
      FunctionCallExprSyntax(
        calledExpression: MemberAccessExprSyntax(
          base: DeclReferenceExprSyntax(baseName: "Requirement"),
          period: .periodToken(),
          declName: DeclReferenceExprSyntax(baseName: "requireMatches")
        ),
        leftParen: .leftParenToken(),
        arguments: node.arguments,
        rightParen: .rightParenToken()
      )
    )
  }
}

/// Макрос для проверки минимальной длины строки
/// Преобразует #requireMinLength(\.username, 3) в Requirement.requireMinLength(\.username, minLength: 3)
public struct RequireMinLengthMacro: ExpressionMacro {
  public static func expansion(
    of node: some FreestandingMacroExpansionSyntax,
    in context: some MacroExpansionContext
  ) -> ExprSyntax {
    guard node.arguments.count >= 2 else {
      return "Requirement.always"
    }
    
    let keyPath = node.arguments.first!.expression
    let minLength = node.arguments.dropFirst().first!.expression
    
    return "Requirement.requireMinLength(\(keyPath), minLength: \(minLength))"
  }
}

/// Макрос для проверки максимальной длины строки
/// Преобразует #requireMaxLength(\.username, 20) в Requirement.requireMaxLength(\.username, maxLength: 20)
public struct RequireMaxLengthMacro: ExpressionMacro {
  public static func expansion(
    of node: some FreestandingMacroExpansionSyntax,
    in context: some MacroExpansionContext
  ) -> ExprSyntax {
    guard node.arguments.count >= 2 else {
      return "Requirement.always"
    }
    
    let keyPath = node.arguments.first!.expression
    let maxLength = node.arguments.dropFirst().first!.expression
    
    return "Requirement.requireMaxLength(\(keyPath), maxLength: \(maxLength))"
  }
}

/// Макрос для проверки длины строки в диапазоне
/// Преобразует #requireLength(\.password, in: 8...128) в Requirement.requireLength(\.password, in: 8...128)
public struct RequireLengthMacro: ExpressionMacro {
  public static func expansion(
    of node: some FreestandingMacroExpansionSyntax,
    in context: some MacroExpansionContext
  ) -> ExprSyntax {
    guard !node.arguments.isEmpty else {
      return "Requirement.always"
    }
    
    return ExprSyntax(
      FunctionCallExprSyntax(
        calledExpression: MemberAccessExprSyntax(
          base: DeclReferenceExprSyntax(baseName: "Requirement"),
          period: .periodToken(),
          declName: DeclReferenceExprSyntax(baseName: "requireLength")
        ),
        leftParen: .leftParenToken(),
        arguments: node.arguments,
        rightParen: .rightParenToken()
      )
    )
  }
}

/// Макрос для проверки, что строка не пустая
/// Преобразует #requireNotBlank(\.name) в Requirement.requireNotBlank(\.name)
public struct RequireNotBlankMacro: ExpressionMacro {
  public static func expansion(
    of node: some FreestandingMacroExpansionSyntax,
    in context: some MacroExpansionContext
  ) -> ExprSyntax {
    guard let keyPath = node.arguments.first?.expression else {
      return "Requirement.always"
    }
    
    return ExprSyntax(
      FunctionCallExprSyntax(
        calledExpression: MemberAccessExprSyntax(
          base: DeclReferenceExprSyntax(baseName: "Requirement"),
          period: .periodToken(),
          declName: DeclReferenceExprSyntax(baseName: "requireNotBlank")
        ),
        leftParen: .leftParenToken(),
        arguments: [LabeledExprSyntax(expression: keyPath)],
        rightParen: .rightParenToken()
      )
    )
  }
}

/// Макрос для валидации email
/// Преобразует #requireEmail(\.email) в Requirement.requireMatches(\.email, pattern: ValidationPattern.email)
public struct RequireEmailMacro: ExpressionMacro {
  public static func expansion(
    of node: some FreestandingMacroExpansionSyntax,
    in context: some MacroExpansionContext
  ) -> ExprSyntax {
    guard let keyPath = node.arguments.first?.expression else {
      return "Requirement.always"
    }
    
    return "Requirement.requireMatches(\(keyPath), pattern: ValidationPattern.email)"
  }
}

/// Макрос для валидации URL
/// Преобразует #requireURL(\.website) в Requirement.requireMatches(\.website, pattern: ValidationPattern.url)
public struct RequireURLMacro: ExpressionMacro {
  public static func expansion(
    of node: some FreestandingMacroExpansionSyntax,
    in context: some MacroExpansionContext
  ) -> ExprSyntax {
    guard let keyPath = node.arguments.first?.expression else {
      return "Requirement.always"
    }
    
    return "Requirement.requireMatches(\(keyPath), pattern: ValidationPattern.url)"
  }
}

/// Макрос для валидации телефона
/// Преобразует #requirePhone(\.phoneNumber) в Requirement.requireMatches(\.phoneNumber, pattern: ValidationPattern.phoneInternational)
public struct RequirePhoneMacro: ExpressionMacro {
  public static func expansion(
    of node: some FreestandingMacroExpansionSyntax,
    in context: some MacroExpansionContext
  ) -> ExprSyntax {
    guard let keyPath = node.arguments.first?.expression else {
      return "Requirement.always"
    }
    
    return "Requirement.requireMatches(\(keyPath), pattern: ValidationPattern.phoneInternational)"
  }
}

// MARK: - Collection Validation Macros

/// Макрос для проверки количества элементов
/// Преобразует #requireCount(\.items, min: 1, max: 50) в Requirement.requireCount(\.items, min: 1, max: 50)
public struct RequireCountMacro: ExpressionMacro {
  public static func expansion(
    of node: some FreestandingMacroExpansionSyntax,
    in context: some MacroExpansionContext
  ) -> ExprSyntax {
    guard !node.arguments.isEmpty else {
      return "Requirement.always"
    }
    
    return ExprSyntax(
      FunctionCallExprSyntax(
        calledExpression: MemberAccessExprSyntax(
          base: DeclReferenceExprSyntax(baseName: "Requirement"),
          period: .periodToken(),
          declName: DeclReferenceExprSyntax(baseName: "requireCount")
        ),
        leftParen: .leftParenToken(),
        arguments: node.arguments,
        rightParen: .rightParenToken()
      )
    )
  }
}

/// Макрос для проверки, что коллекция не пустая
/// Преобразует #requireNotEmpty(\.cart) в Requirement.requireNotEmpty(\.cart)
public struct RequireNotEmptyMacro: ExpressionMacro {
  public static func expansion(
    of node: some FreestandingMacroExpansionSyntax,
    in context: some MacroExpansionContext
  ) -> ExprSyntax {
    guard let keyPath = node.arguments.first?.expression else {
      return "Requirement.always"
    }
    
    return ExprSyntax(
      FunctionCallExprSyntax(
        calledExpression: MemberAccessExprSyntax(
          base: DeclReferenceExprSyntax(baseName: "Requirement"),
          period: .periodToken(),
          declName: DeclReferenceExprSyntax(baseName: "requireNotEmpty")
        ),
        leftParen: .leftParenToken(),
        arguments: [LabeledExprSyntax(expression: keyPath)],
        rightParen: .rightParenToken()
      )
    )
  }
}

/// Макрос для проверки, что коллекция пустая
/// Преобразует #requireEmpty(\.errors) в Requirement.requireEmpty(\.errors)
public struct RequireEmptyMacro: ExpressionMacro {
  public static func expansion(
    of node: some FreestandingMacroExpansionSyntax,
    in context: some MacroExpansionContext
  ) -> ExprSyntax {
    guard let keyPath = node.arguments.first?.expression else {
      return "Requirement.always"
    }
    
    return ExprSyntax(
      FunctionCallExprSyntax(
        calledExpression: MemberAccessExprSyntax(
          base: DeclReferenceExprSyntax(baseName: "Requirement"),
          period: .periodToken(),
          declName: DeclReferenceExprSyntax(baseName: "requireEmpty")
        ),
        leftParen: .leftParenToken(),
        arguments: [LabeledExprSyntax(expression: keyPath)],
        rightParen: .rightParenToken()
      )
    )
  }
}

// MARK: - Optional Validation Macros

/// Макрос для проверки, что Optional не nil
/// Преобразует #requireNonNil(\.userId) в соответствующее требование
public struct RequireNonNilMacro: ExpressionMacro {
  public static func expansion(
    of node: some FreestandingMacroExpansionSyntax,
    in context: some MacroExpansionContext
  ) -> ExprSyntax {
    guard let keyPath = node.arguments.first?.expression else {
      return "Requirement.always"
    }
    
    return """
    Requirement { context in
      context[keyPath: \(keyPath)] != nil
        ? .confirmed
        : .failed(reason: Reason(code: "optional.is_nil", message: "Value must not be nil"))
    }
    """
  }
}

/// Макрос для проверки, что Optional nil
/// Преобразует #requireNil(\.tempData) в соответствующее требование
public struct RequireNilMacro: ExpressionMacro {
  public static func expansion(
    of node: some FreestandingMacroExpansionSyntax,
    in context: some MacroExpansionContext
  ) -> ExprSyntax {
    guard let keyPath = node.arguments.first?.expression else {
      return "Requirement.always"
    }
    
    return """
    Requirement { context in
      context[keyPath: \(keyPath)] == nil
        ? .confirmed
        : .failed(reason: Reason(code: "optional.is_not_nil", message: "Value must be nil"))
    }
    """
  }
}

/// Макрос для проверки Optional с условием
/// Преобразует #requireSome(\.age, where: { $0 >= 18 }) в Requirement.requireSome(\.age, where: { $0 >= 18 })
public struct RequireSomeMacro: ExpressionMacro {
  public static func expansion(
    of node: some FreestandingMacroExpansionSyntax,
    in context: some MacroExpansionContext
  ) -> ExprSyntax {
    guard !node.arguments.isEmpty else {
      return "Requirement.always"
    }
    
    // Создаем вызов Requirement.requireSome со всеми аргументами
    return ExprSyntax(
      FunctionCallExprSyntax(
        calledExpression: MemberAccessExprSyntax(
          base: DeclReferenceExprSyntax(baseName: "Requirement"),
          period: .periodToken(),
          declName: DeclReferenceExprSyntax(baseName: "requireSome")
        ),
        leftParen: .leftParenToken(),
        arguments: node.arguments,
        rightParen: .rightParenToken()
      )
    )
  }
}

// MARK: - Range Validation Macros

/// Макрос для проверки значения в диапазоне
/// Преобразует #requireInRange(\.age, 18...120) в соответствующее требование
public struct RequireInRangeMacro: ExpressionMacro {
  public static func expansion(
    of node: some FreestandingMacroExpansionSyntax,
    in context: some MacroExpansionContext
  ) -> ExprSyntax {
    guard node.arguments.count >= 2 else {
      return "Requirement.always"
    }
    
    let keyPath = node.arguments.first!.expression
    let range = node.arguments.dropFirst().first!.expression
    
    return """
    Requirement { context in
      let value = context[keyPath: \(keyPath)]
      let range = \(range)
      return range.contains(value)
        ? .confirmed
        : .failed(reason: Reason(
            code: "range.out_of_bounds",
            message: "Value must be in range \\(range)"
          ))
    }
    """
  }
}

/// Макрос для проверки значения между min и max
/// Преобразует #requireBetween(\.amount, min: 10, max: 1000) в соответствующее требование
public struct RequireBetweenMacro: ExpressionMacro {
  public static func expansion(
    of node: some FreestandingMacroExpansionSyntax,
    in context: some MacroExpansionContext
  ) -> ExprSyntax {
    guard node.arguments.count >= 3 else {
      return "Requirement.always"
    }
    
    let keyPath = node.arguments.first!.expression
    
    let minArg = node.arguments.first(where: { $0.label?.text == "min" })?.expression
    let maxArg = node.arguments.first(where: { $0.label?.text == "max" })?.expression
    
    guard let min = minArg, let max = maxArg else {
      return "Requirement.always"
    }
    
    return """
    Requirement { context in
      let value = context[keyPath: \(keyPath)]
      let min = \(min)
      let max = \(max)
      return (value >= min && value <= max)
        ? .confirmed
        : .failed(reason: Reason(
            code: "range.out_of_bounds",
            message: "Value must be between \\(min) and \\(max)"
          ))
    }
    """
  }
}

@main
struct RequirementsKitMacroPlugin: CompilerPlugin {
  let providingMacros: [Macro.Type] = [
    RequireMacro.self,
    AllMacro.self,
    AnyMacro.self,
    NotMacro.self,
    AsyncRequireMacro.self,
    WhenMacro.self,
    UnlessMacro.self,
    XorMacro.self,
    WarnMacro.self,
    RequireOrElseMacro.self,
    // String validation macros
    RequireMatchesMacro.self,
    RequireMinLengthMacro.self,
    RequireMaxLengthMacro.self,
    RequireLengthMacro.self,
    RequireNotBlankMacro.self,
    RequireEmailMacro.self,
    RequireURLMacro.self,
    RequirePhoneMacro.self,
    // Collection validation macros
    RequireCountMacro.self,
    RequireNotEmptyMacro.self,
    RequireEmptyMacro.self,
    // Optional validation macros
    RequireNonNilMacro.self,
    RequireNilMacro.self,
    RequireSomeMacro.self,
    // Range validation macros
    RequireInRangeMacro.self,
    RequireBetweenMacro.self,
    // Decision macros
    DecideMacro.self,
    AsyncDecideMacro.self,
    DecidedMacro.self,
    // Decision KeyPath macros
    WhenDecisionMacro.self,
    UnlessDecisionMacro.self,
    // Decision composition macros
    FirstMatchMacro.self,
    MatchDecisionMacro.self,
    OrElseMacro.self,
    // Decision integration macros
    WhenMetMacro.self,
    // Async Decision macros
    AsyncWhenDecisionMacro.self,
    AsyncUnlessDecisionMacro.self,
    AsyncFirstMatchMacro.self,
    AsyncMatchDecisionMacro.self,
    AsyncOrElseMacro.self,
    AsyncWhenMetMacro.self,
    // Attached macros
    RequirementModelMacro.self,
    ValidationAttributeMacro.self
  ]
}

