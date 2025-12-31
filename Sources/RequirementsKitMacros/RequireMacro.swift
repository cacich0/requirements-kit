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
    guard let argument = node.arguments.first?.expression else {
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
    RequireOrElseMacro.self
  ]
}

