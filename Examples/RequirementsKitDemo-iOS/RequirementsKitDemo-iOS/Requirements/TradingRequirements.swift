import RequirementsKit

// MARK: - Trading Requirements
// Демонстрация: Fluent API (.and, .or), операторы (&&, ||, !),
// .because(), .logged(), .fallback(), .named()

/// Требования для торговых операций
enum TradingRequirements {
  
  // MARK: - Базовые требования с Fluent API
  
  /// Пользователь может торговать
  static let canTrade: Requirement<TradingContext> = Requirement
    .require(\.user.isLoggedIn)
    .and(\.user.isVerified)
    .and(\.user.kycCompleted)
    .because(code: "trading.not_eligible", message: "User is not eligible for trading")
  
  /// Пользователь не заблокирован
  static let notBanned: Requirement<TradingContext> = Requirement<TradingContext>
    .predicate { !$0.user.isBanned }
    .because("User account is banned from trading")
  
  // MARK: - Логические операторы
  
  /// Достаточный баланс для сделки
  static let hasEnoughBalance: Requirement<TradingContext> = Requirement<TradingContext> { context in
    context.user.balance >= context.tradeAmount
      ? .confirmed
      : .failed(reason: Reason(
          code: "trading.insufficient_balance",
          message: "Insufficient balance: need \(context.tradeAmount), have \(context.user.balance)"
        ))
  }
  
  /// Не превышен дневной лимит
  static let withinDailyLimit: Requirement<TradingContext> = Requirement<TradingContext> { context in
    context.tradeAmount <= context.remainingDailyLimit
      ? .confirmed
      : .failed(reason: Reason(
          code: "trading.daily_limit_exceeded",
          message: "Daily limit exceeded: max \(context.remainingDailyLimit)"
        ))
  }
  
  /// Комбинация с && оператором
  static let financialRequirements: Requirement<TradingContext> =
    hasEnoughBalance && withinDailyLimit
  
  // MARK: - OR с fallback
  
  /// Админ ИЛИ премиум пользователь
  static let premiumOrAdmin: Requirement<TradingContext> =
    Requirement<TradingContext>.require(\.user.isAdmin)
    || Requirement<TradingContext>.require(\.user.isPremium)
  
  /// Основное требование с fallback
  static let marginTradingAccess: Requirement<TradingContext> = Requirement<TradingContext>
    .require(\.user.isEnterprise)
    .fallback {
      Requirement<TradingContext>.require(\.user.isPremium)
      Requirement<TradingContext>.require(\.user.kycCompleted)
    }
    .because("Margin trading requires Enterprise or verified Premium account")
  
  // MARK: - Именованные требования с логированием
  
  /// Полная проверка для торговли
  static let fullTradeCheck: Requirement<TradingContext> = Requirement<TradingContext>
    .named("FullTradeCheck") {
      canTrade
        .logged("CanTrade")
      notBanned
        .logged("NotBanned")
      financialRequirements
        .logged("FinancialCheck")
    }
  
  // MARK: - Сложные композиции с NOT
  
  /// Не использует маржинальную торговлю ИЛИ имеет доступ к ней
  static let marginCheck: Requirement<TradingContext> =
    !Requirement<TradingContext>.require(\.useMargin) || marginTradingAccess
  
  // MARK: - Fluent chain
  
  /// Полная цепочка проверок
  static let completeTradeRequirement: Requirement<TradingContext> = Requirement<TradingContext>
    .require(\.user.isLoggedIn)
    .and(\.user.isVerified)
    .and(\.user.kycCompleted)
    .and(Requirement<TradingContext>.predicate { !$0.user.isBanned })
    .and(hasEnoughBalance)
    .and(withinDailyLimit)
    .and(marginCheck)
    .named("CompleteTradeRequirement")
    .logged("🔄 Trade Requirement")
  
  // MARK: - Специфичные требования для типов сделок
  
  /// Требования для покупки
  static func buyRequirement(minAmount: Double = 10) -> Requirement<TradingContext> {
    Requirement<TradingContext> { context in
      guard context.tradeType == .buy else {
        return .confirmed // Пропускаем для других типов
      }
      return context.tradeAmount >= minAmount
        ? .confirmed
        : .failed(reason: Reason(
            code: "trading.min_buy_amount",
            message: "Minimum buy amount is \(minAmount)"
          ))
    }
  }
  
  /// Требования для продажи
  static func sellRequirement(maxAmount: Double = 100000) -> Requirement<TradingContext> {
    Requirement<TradingContext> { context in
      guard context.tradeType == .sell else {
        return .confirmed
      }
      return context.tradeAmount <= maxAmount
        ? .confirmed
        : .failed(reason: Reason(
            code: "trading.max_sell_amount",
            message: "Maximum sell amount is \(maxAmount)"
          ))
    }
  }
  
  /// Требования для свопа
  static let swapRequirement: Requirement<TradingContext> = Requirement<TradingContext> { context in
    guard context.tradeType == .swap else {
      return .confirmed
    }
    return context.user.isPremium
      ? .confirmed
      : .failed(reason: Reason(
          code: "trading.swap_premium_only",
          message: "Swap is available for Premium users only"
        ))
  }
  
  // MARK: - Динамическое построение требований
  
  /// Создает требование на основе типа сделки
  static func requirementFor(tradeType: TradeType) -> Requirement<TradingContext> {
    switch tradeType {
    case .buy:
      return canTrade && financialRequirements && buyRequirement()
    case .sell:
      return canTrade && sellRequirement()
    case .swap:
      return canTrade && swapRequirement && financialRequirements
    }
  }
}

// MARK: - Middleware Examples

extension TradingRequirements {
  /// Требование с logging middleware
  static let loggedTradeCheck: Requirement<TradingContext> = completeTradeRequirement
    .with(middleware: LoggingMiddleware(level: .verbose, prefix: "[Trading]"))
  
  /// Требование с analytics middleware
  static func analyticsTradeCheck(
    handler: @escaping @Sendable (String, [String: Any]) -> Void
  ) -> Requirement<TradingContext> {
    completeTradeRequirement
      .with(middleware: AnalyticsMiddleware(handler: handler))
  }
}

