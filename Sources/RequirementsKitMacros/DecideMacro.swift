import SwiftCompilerPlugin
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

// MARK: - #decide Макрос

/// Макрос для создания решений в DSL
/// Преобразует #decide { ctx in ... } в Decision { ctx in ... }
public struct DecideMacro: ExpressionMacro {
  public static func expansion(
    of node: some FreestandingMacroExpansionSyntax,
    in context: some MacroExpansionContext
  ) -> ExprSyntax {
    guard let closure = node.trailingClosure else {
      return "Decision.never"
    }
    
    return ExprSyntax(
      FunctionCallExprSyntax(
        calledExpression: DeclReferenceExprSyntax(baseName: "Decision"),
        leftParen: .leftParenToken(),
        arguments: LabeledExprListSyntax([
          LabeledExprSyntax(
            label: "decider",
            colon: .colonToken(),
            expression: closure
          )
        ]),
        rightParen: .rightParenToken()
      )
    )
  }
}

// MARK: - #asyncDecide Макрос

/// Макрос для создания асинхронных решений
/// Преобразует #asyncDecide { ctx in ... } в AsyncDecision { ctx in ... }
public struct AsyncDecideMacro: ExpressionMacro {
  public static func expansion(
    of node: some FreestandingMacroExpansionSyntax,
    in context: some MacroExpansionContext
  ) -> ExprSyntax {
    guard let closure = node.trailingClosure else {
      return "AsyncDecision.never"
    }
    
    return ExprSyntax(
      FunctionCallExprSyntax(
        calledExpression: DeclReferenceExprSyntax(baseName: "AsyncDecision"),
        leftParen: .leftParenToken(),
        arguments: LabeledExprListSyntax([
          LabeledExprSyntax(
            label: "decider",
            colon: .colonToken(),
            expression: closure
          )
        ]),
        rightParen: .rightParenToken()
      )
    )
  }
}

// MARK: - @Decided Attached Macro

/// Attached macro для property wrapper, который автоматически принимает решение
/// @Decided(decision: myDecision, context: myContext)
/// var result: MyType
public struct DecidedMacro: AccessorMacro {
  public static func expansion(
    of node: AttributeSyntax,
    providingAccessorsOf declaration: some DeclSyntaxProtocol,
    in context: some MacroExpansionContext
  ) -> [AccessorDeclSyntax] {
    // Этот макрос будет использоваться с property wrapper
    // Сама логика находится в property wrapper Decided
    return []
  }
}

// MARK: - #whenDecision Макрос

/// Макрос для создания условных решений на основе KeyPath
/// Преобразует #whenDecision(\.keyPath, return: value) в Decision.when(...)
public struct WhenDecisionMacro: ExpressionMacro {
  public static func expansion(
    of node: some FreestandingMacroExpansionSyntax,
    in context: some MacroExpansionContext
  ) -> ExprSyntax {
    guard !node.arguments.isEmpty else {
      return "Decision.never"
    }
    
    let arguments = node.arguments
    
    // Проверяем, есть ли аргумент return
    if let returnArg = arguments.first(where: { $0.label?.text == "return" }) {
      let keyPath = arguments.first!.expression
      let returnValue = returnArg.expression
      
      // Проверяем наличие операторов сравнения
      if let equalsArg = arguments.first(where: { $0.label?.text == "equals" }) {
        let compareValue = equalsArg.expression
        return """
        Decision { context in
          context[keyPath: \(keyPath)] == \(compareValue) ? \(returnValue) : nil
        }
        """
      } else if let notEqualsArg = arguments.first(where: { $0.label?.text == "notEquals" }) {
        let compareValue = notEqualsArg.expression
        return """
        Decision { context in
          context[keyPath: \(keyPath)] != \(compareValue) ? \(returnValue) : nil
        }
        """
      } else if let greaterThanArg = arguments.first(where: { $0.label?.text == "greaterThan" }) {
        let threshold = greaterThanArg.expression
        return """
        Decision { context in
          context[keyPath: \(keyPath)] > \(threshold) ? \(returnValue) : nil
        }
        """
      } else if let greaterThanOrEqualArg = arguments.first(where: { $0.label?.text == "greaterThanOrEqual" }) {
        let threshold = greaterThanOrEqualArg.expression
        return """
        Decision { context in
          context[keyPath: \(keyPath)] >= \(threshold) ? \(returnValue) : nil
        }
        """
      } else if let lessThanArg = arguments.first(where: { $0.label?.text == "lessThan" }) {
        let threshold = lessThanArg.expression
        return """
        Decision { context in
          context[keyPath: \(keyPath)] < \(threshold) ? \(returnValue) : nil
        }
        """
      } else if let lessThanOrEqualArg = arguments.first(where: { $0.label?.text == "lessThanOrEqual" }) {
        let threshold = lessThanOrEqualArg.expression
        return """
        Decision { context in
          context[keyPath: \(keyPath)] <= \(threshold) ? \(returnValue) : nil
        }
        """
      } else {
        // Простой Bool KeyPath
        return """
        Decision { context in
          context[keyPath: \(keyPath)] ? \(returnValue) : nil
        }
        """
      }
    }
    
    // Если есть trailing closure
    if let closure = node.trailingClosure {
      let keyPath = arguments.first!.expression
      return """
      Decision { context in
        context[keyPath: \(keyPath)] ? \(closure)(context) : nil
      }
      """
    }
    
    return "Decision.never"
  }
}

// MARK: - #unlessDecision Макрос

/// Макрос для создания условных решений с отрицанием
/// Преобразует #unlessDecision(\.keyPath, return: value) в Decision.unless(...)
public struct UnlessDecisionMacro: ExpressionMacro {
  public static func expansion(
    of node: some FreestandingMacroExpansionSyntax,
    in context: some MacroExpansionContext
  ) -> ExprSyntax {
    guard !node.arguments.isEmpty else {
      return "Decision.never"
    }
    
    let keyPath = node.arguments.first!.expression
    
    if let returnArg = node.arguments.first(where: { $0.label?.text == "return" }) {
      let returnValue = returnArg.expression
      return """
      Decision { context in
        !context[keyPath: \(keyPath)] ? \(returnValue) : nil
      }
      """
    }
    
    return "Decision.never"
  }
}

// MARK: - #firstMatch Макрос

/// Макрос для создания композиции решений (первое совпадение)
/// Преобразует #firstMatch { ... } в Decision.firstMatch { ... }
public struct FirstMatchMacro: ExpressionMacro {
  public static func expansion(
    of node: some FreestandingMacroExpansionSyntax,
    in context: some MacroExpansionContext
  ) -> ExprSyntax {
    guard let closure = node.trailingClosure else {
      return "Decision.never"
    }
    
    return ExprSyntax(
      FunctionCallExprSyntax(
        calledExpression: MemberAccessExprSyntax(
          base: DeclReferenceExprSyntax(baseName: "Decision"),
          period: .periodToken(),
          declName: DeclReferenceExprSyntax(baseName: "firstMatch")
        ),
        leftParen: nil,
        arguments: [],
        rightParen: nil,
        trailingClosure: closure
      )
    )
  }
}

// MARK: - #matchDecision Макрос

/// Макрос для создания switch-подобных решений
/// Преобразует #matchDecision(\.keyPath) { ... } в Decision.match(keyPath: \.keyPath) { ... }
public struct MatchDecisionMacro: ExpressionMacro {
  public static func expansion(
    of node: some FreestandingMacroExpansionSyntax,
    in context: some MacroExpansionContext
  ) -> ExprSyntax {
    guard let keyPath = node.arguments.first?.expression,
          let closure = node.trailingClosure else {
      return "Decision.never"
    }
    
    return """
    Decision.match(keyPath: \(keyPath)) \(closure)
    """
  }
}

// MARK: - #orElse Макрос

/// Макрос для fallback значения
/// Преобразует #orElse(value) в Decision.constant(value)
public struct OrElseMacro: ExpressionMacro {
  public static func expansion(
    of node: some FreestandingMacroExpansionSyntax,
    in context: some MacroExpansionContext
  ) -> ExprSyntax {
    guard let value = node.arguments.first?.expression else {
      return "Decision.never"
    }
    
    return ExprSyntax(
      FunctionCallExprSyntax(
        calledExpression: MemberAccessExprSyntax(
          base: DeclReferenceExprSyntax(baseName: "Decision"),
          period: .periodToken(),
          declName: DeclReferenceExprSyntax(baseName: "constant")
        ),
        leftParen: .leftParenToken(),
        arguments: LabeledExprListSyntax([
          LabeledExprSyntax(expression: value)
        ]),
        rightParen: .rightParenToken()
      )
    )
  }
}

// MARK: - #whenMet Макрос

/// Макрос для создания решений на основе требований
/// Преобразует #whenMet(requirement, return: value) в Decision.when(requirement, return: value)
public struct WhenMetMacro: ExpressionMacro {
  public static func expansion(
    of node: some FreestandingMacroExpansionSyntax,
    in context: some MacroExpansionContext
  ) -> ExprSyntax {
    guard !node.arguments.isEmpty else {
      return "Decision.never"
    }
    
    let requirement = node.arguments.first!.expression
    
    // Проверяем наличие return аргумента
    if let returnArg = node.arguments.first(where: { $0.label?.text == "return" }) {
      let returnValue = returnArg.expression
      return """
      Decision.when(\(requirement), return: \(returnValue))
      """
    }
    
    // Если есть trailing closure
    if let closure = node.trailingClosure {
      return """
      Decision.when(\(requirement), return: \(closure))
      """
    }
    
    return "Decision.never"
  }
}

// MARK: - Async макросы

/// Макрос для создания асинхронных условных решений на основе KeyPath
public struct AsyncWhenDecisionMacro: ExpressionMacro {
  public static func expansion(
    of node: some FreestandingMacroExpansionSyntax,
    in context: some MacroExpansionContext
  ) -> ExprSyntax {
    guard !node.arguments.isEmpty else {
      return "AsyncDecision.never"
    }
    
    let arguments = node.arguments
    
    if let returnArg = arguments.first(where: { $0.label?.text == "return" }) {
      let keyPath = arguments.first!.expression
      let returnValue = returnArg.expression
      
      // Проверяем наличие операторов сравнения
      if let equalsArg = arguments.first(where: { $0.label?.text == "equals" }) {
        let compareValue = equalsArg.expression
        return """
        AsyncDecision { context in
          context[keyPath: \(keyPath)] == \(compareValue) ? \(returnValue) : nil
        }
        """
      } else if let notEqualsArg = arguments.first(where: { $0.label?.text == "notEquals" }) {
        let compareValue = notEqualsArg.expression
        return """
        AsyncDecision { context in
          context[keyPath: \(keyPath)] != \(compareValue) ? \(returnValue) : nil
        }
        """
      } else if let greaterThanArg = arguments.first(where: { $0.label?.text == "greaterThan" }) {
        let threshold = greaterThanArg.expression
        return """
        AsyncDecision { context in
          context[keyPath: \(keyPath)] > \(threshold) ? \(returnValue) : nil
        }
        """
      } else if let greaterThanOrEqualArg = arguments.first(where: { $0.label?.text == "greaterThanOrEqual" }) {
        let threshold = greaterThanOrEqualArg.expression
        return """
        AsyncDecision { context in
          context[keyPath: \(keyPath)] >= \(threshold) ? \(returnValue) : nil
        }
        """
      } else if let lessThanArg = arguments.first(where: { $0.label?.text == "lessThan" }) {
        let threshold = lessThanArg.expression
        return """
        AsyncDecision { context in
          context[keyPath: \(keyPath)] < \(threshold) ? \(returnValue) : nil
        }
        """
      } else if let lessThanOrEqualArg = arguments.first(where: { $0.label?.text == "lessThanOrEqual" }) {
        let threshold = lessThanOrEqualArg.expression
        return """
        AsyncDecision { context in
          context[keyPath: \(keyPath)] <= \(threshold) ? \(returnValue) : nil
        }
        """
      } else {
        // Простой Bool KeyPath
        return """
        AsyncDecision { context in
          context[keyPath: \(keyPath)] ? \(returnValue) : nil
        }
        """
      }
    }
    
    return "AsyncDecision.never"
  }
}

/// Макрос для создания асинхронных условных решений с отрицанием
public struct AsyncUnlessDecisionMacro: ExpressionMacro {
  public static func expansion(
    of node: some FreestandingMacroExpansionSyntax,
    in context: some MacroExpansionContext
  ) -> ExprSyntax {
    guard !node.arguments.isEmpty else {
      return "AsyncDecision.never"
    }
    
    let keyPath = node.arguments.first!.expression
    
    if let returnArg = node.arguments.first(where: { $0.label?.text == "return" }) {
      let returnValue = returnArg.expression
      return """
      AsyncDecision { context in
        !context[keyPath: \(keyPath)] ? \(returnValue) : nil
      }
      """
    }
    
    return "AsyncDecision.never"
  }
}

/// Макрос для создания асинхронной композиции решений (первое совпадение)
public struct AsyncFirstMatchMacro: ExpressionMacro {
  public static func expansion(
    of node: some FreestandingMacroExpansionSyntax,
    in context: some MacroExpansionContext
  ) -> ExprSyntax {
    guard let closure = node.trailingClosure else {
      return "AsyncDecision.never"
    }
    
    return ExprSyntax(
      FunctionCallExprSyntax(
        calledExpression: MemberAccessExprSyntax(
          base: DeclReferenceExprSyntax(baseName: "AsyncDecision"),
          period: .periodToken(),
          declName: DeclReferenceExprSyntax(baseName: "firstMatch")
        ),
        leftParen: nil,
        arguments: [],
        rightParen: nil,
        trailingClosure: closure
      )
    )
  }
}

/// Макрос для создания асинхронных switch-подобных решений
public struct AsyncMatchDecisionMacro: ExpressionMacro {
  public static func expansion(
    of node: some FreestandingMacroExpansionSyntax,
    in context: some MacroExpansionContext
  ) -> ExprSyntax {
    guard let keyPath = node.arguments.first?.expression,
          let closure = node.trailingClosure else {
      return "AsyncDecision.never"
    }
    
    return """
    AsyncDecision.match(keyPath: \(keyPath)) \(closure)
    """
  }
}

/// Макрос для асинхронного fallback значения
public struct AsyncOrElseMacro: ExpressionMacro {
  public static func expansion(
    of node: some FreestandingMacroExpansionSyntax,
    in context: some MacroExpansionContext
  ) -> ExprSyntax {
    guard let value = node.arguments.first?.expression else {
      return "AsyncDecision.never"
    }
    
    return ExprSyntax(
      FunctionCallExprSyntax(
        calledExpression: MemberAccessExprSyntax(
          base: DeclReferenceExprSyntax(baseName: "AsyncDecision"),
          period: .periodToken(),
          declName: DeclReferenceExprSyntax(baseName: "constant")
        ),
        leftParen: .leftParenToken(),
        arguments: LabeledExprListSyntax([
          LabeledExprSyntax(expression: value)
        ]),
        rightParen: .rightParenToken()
      )
    )
  }
}

/// Макрос для создания асинхронных решений на основе требований
public struct AsyncWhenMetMacro: ExpressionMacro {
  public static func expansion(
    of node: some FreestandingMacroExpansionSyntax,
    in context: some MacroExpansionContext
  ) -> ExprSyntax {
    guard !node.arguments.isEmpty else {
      return "AsyncDecision.never"
    }
    
    let requirement = node.arguments.first!.expression
    
    // Проверяем наличие return аргумента
    if let returnArg = node.arguments.first(where: { $0.label?.text == "return" }) {
      let returnValue = returnArg.expression
      return """
      AsyncDecision { context in
        switch \(requirement).evaluate(context) {
        case .confirmed:
          return \(returnValue)
        case .failed:
          return nil
        }
      }
      """
    }
    
    // Если есть trailing closure
    if let closure = node.trailingClosure {
      return """
      AsyncDecision { context in
        switch \(requirement).evaluate(context) {
        case .confirmed:
          return await \(closure)(context)
        case .failed:
          return nil
        }
      }
      """
    }
    
    return "AsyncDecision.never"
  }
}

