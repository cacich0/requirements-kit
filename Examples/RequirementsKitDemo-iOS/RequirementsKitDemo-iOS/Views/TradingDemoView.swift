import SwiftUI
import RequirementsKit

/// Демонстрация Fluent API и логических операторов
struct TradingDemoView: View {
  @State private var context = TradingContext.sample
  @State private var consoleOutput: [String] = []
  
  var body: some View {
    NavigationStack {
      ScrollView {
        VStack(alignment: .leading, spacing: 24) {
          CategoryHeader(title: "Trading Requirements", systemImage: "chart.line.uptrend.xyaxis")
          
          // Trading Controls
          tradingControlsSection
          
          // Fluent API Demo
          fluentAPISection
          
          // Operators Demo
          operatorsSection
          
          // Fallback Demo
          fallbackSection
          
          // Middleware Demo
          middlewareSection
          
          // Console Output
          if !consoleOutput.isEmpty {
            consoleSection
          }
        }
        .padding()
      }
      .background(Color.gray.opacity(0.1))
      .navigationTitle("Fluent API Demo")
      #if os(iOS)
      .navigationBarTitleDisplayMode(.inline)
      #endif
    }
  }
  
  // MARK: - Trading Controls
  
  private var tradingControlsSection: some View {
    DemoSection(title: "Trading Context", description: "Adjust trading parameters") {
      VStack(spacing: 16) {
        // User settings
        Group {
          Toggle("Logged In", isOn: $context.user.isLoggedIn)
          Toggle("Verified", isOn: $context.user.isVerified)
          Toggle("KYC Completed", isOn: $context.user.kycCompleted)
          Toggle("Banned", isOn: $context.user.isBanned)
        }
        
        Divider()
        
        // Subscription
        Picker("Subscription", selection: $context.user.subscriptionType) {
          ForEach(SubscriptionType.allCases, id: \.self) { type in
            Text(type.displayName).tag(type)
          }
        }
        .pickerStyle(.segmented)
        
        Divider()
        
        // Trade settings
        VStack(alignment: .leading, spacing: 8) {
          Text("Balance: $\(context.user.balance, specifier: "%.2f")")
            .font(.subheadline)
          Slider(value: $context.user.balance, in: 0...10000, step: 100)
          
          Text("Daily Limit: $\(context.user.dailyLimit, specifier: "%.2f") (Used: $\(context.user.usedDailyLimit, specifier: "%.2f"))")
            .font(.subheadline)
          Slider(value: $context.user.dailyLimit, in: 0...10000, step: 100)
          
          Text("Trade Amount: $\(context.tradeAmount, specifier: "%.2f")")
            .font(.subheadline)
          Slider(value: $context.tradeAmount, in: 0...5000, step: 50)
        }
        
        Divider()
        
        // Trade type
        Picker("Trade Type", selection: $context.tradeType) {
          ForEach(TradeType.allCases, id: \.self) { type in
            Text(type.displayName).tag(type)
          }
        }
        .pickerStyle(.segmented)
        
        Toggle("Use Margin", isOn: $context.useMargin)
      }
    }
  }
  
  // MARK: - Fluent API
  
  private var fluentAPISection: some View {
    DemoSection(
      title: "Fluent API",
      description: ".and(), .or(), .because(), .named()"
    ) {
      VStack(alignment: .leading, spacing: 8) {
        CodeExampleCard(code: """
          let canTrade = Requirement
            .require(\\.user.isLoggedIn)
            .and(\\.user.isVerified)
            .and(\\.user.kycCompleted)
            .because(code: "trading.not_eligible",
                     message: "User is not eligible")
          """)
        
        Divider()
        
        let canTradeResult = TradingRequirements.canTrade.evaluate(context)
        RequirementResultView(
          title: "canTrade (fluent chain)",
          isConfirmed: canTradeResult.isConfirmed,
          reason: canTradeResult.reason?.message
        )
        
        let notBannedResult = TradingRequirements.notBanned.evaluate(context)
        RequirementResultView(
          title: "notBanned (.predicate + .because)",
          isConfirmed: notBannedResult.isConfirmed,
          reason: notBannedResult.reason?.message
        )
        
        let balanceResult = TradingRequirements.hasEnoughBalance.evaluate(context)
        RequirementResultView(
          title: "hasEnoughBalance",
          isConfirmed: balanceResult.isConfirmed,
          reason: balanceResult.reason?.message
        )
        
        let limitResult = TradingRequirements.withinDailyLimit.evaluate(context)
        RequirementResultView(
          title: "withinDailyLimit",
          isConfirmed: limitResult.isConfirmed,
          reason: limitResult.reason?.message
        )
      }
    }
  }
  
  // MARK: - Operators
  
  private var operatorsSection: some View {
    DemoSection(
      title: "Logical Operators",
      description: "&& (AND), || (OR), ! (NOT)"
    ) {
      VStack(alignment: .leading, spacing: 8) {
        CodeExampleCard(code: """
          // AND operator
          let financial = hasEnoughBalance && withinDailyLimit
          
          // OR operator
          let premiumOrAdmin = require(\\.isAdmin) || require(\\.isPremium)
          
          // NOT operator
          let marginCheck = !require(\\.useMargin) || marginAccess
          """)
        
        Divider()
        
        let financialResult = TradingRequirements.financialRequirements.evaluate(context)
        RequirementResultView(
          title: "financialRequirements (&&)",
          isConfirmed: financialResult.isConfirmed,
          reason: financialResult.reason?.message
        )
        
        let premiumOrAdminResult = TradingRequirements.premiumOrAdmin.evaluate(context)
        RequirementResultView(
          title: "premiumOrAdmin (||)",
          isConfirmed: premiumOrAdminResult.isConfirmed,
          reason: premiumOrAdminResult.reason?.message
        )
        
        let marginResult = TradingRequirements.marginCheck.evaluate(context)
        RequirementResultView(
          title: "marginCheck (!useMargin || access)",
          isConfirmed: marginResult.isConfirmed,
          reason: marginResult.reason?.message
        )
        
        Divider()
        
        // Trade type specific
        let tradeTypeResult = TradingRequirements.requirementFor(tradeType: context.tradeType).evaluate(context)
        RequirementResultView(
          title: "requirementFor(\(context.tradeType.displayName))",
          isConfirmed: tradeTypeResult.isConfirmed,
          reason: tradeTypeResult.reason?.message
        )
      }
    }
  }
  
  // MARK: - Fallback
  
  private var fallbackSection: some View {
    DemoSection(
      title: "Fallback Requirements",
      description: ".fallback { } and .orFallback(to:)"
    ) {
      VStack(alignment: .leading, spacing: 8) {
        CodeExampleCard(code: """
          let marginAccess = Requirement
            .require(\\.user.isEnterprise)
            .fallback {
              require(\\.user.isPremium)
              require(\\.user.kycCompleted)
            }
          """)
        
        Divider()
        
        let marginAccessResult = TradingRequirements.marginTradingAccess.evaluate(context)
        RequirementResultView(
          title: "marginTradingAccess (with fallback)",
          isConfirmed: marginAccessResult.isConfirmed,
          reason: marginAccessResult.reason?.message
        )
        
        Text("Enterprise passes directly, otherwise checks Premium + KYC")
          .font(.caption)
          .foregroundStyle(.secondary)
      }
    }
  }
  
  // MARK: - Middleware
  
  private var middlewareSection: some View {
    DemoSection(
      title: "Middleware",
      description: ".with(middleware:) for logging and analytics"
    ) {
      VStack(alignment: .leading, spacing: 8) {
        CodeExampleCard(code: """
          let loggedCheck = requirement
            .with(middleware: LoggingMiddleware(level: .verbose))
          
          let analyticsCheck = requirement
            .with(middleware: AnalyticsMiddleware { event, props in
              print("Event: \\(event), Props: \\(props)")
            })
          """)
        
        Divider()
        
        HStack {
          Button("Run with Logging") {
            runWithLogging()
          }
          .buttonStyle(.borderedProminent)
          
          Button("Run with Analytics") {
            runWithAnalytics()
          }
          .buttonStyle(.bordered)
          
          Button("Clear Console") {
            consoleOutput.removeAll()
          }
          .buttonStyle(.bordered)
          .tint(.red)
        }
        
        Text("Check console output below")
          .font(.caption)
          .foregroundStyle(.secondary)
      }
    }
  }
  
  // MARK: - Console
  
  private var consoleSection: some View {
    DemoSection(title: "Console Output", description: "Middleware logs") {
      VStack(alignment: .leading, spacing: 4) {
        ForEach(Array(consoleOutput.enumerated()), id: \.offset) { _, line in
          Text(line)
            .font(.system(.caption, design: .monospaced))
            .foregroundStyle(.secondary)
        }
      }
      .frame(maxWidth: .infinity, alignment: .leading)
      .padding(8)
      .background {
        RoundedRectangle(cornerRadius: 8)
          .fill(Color.gray.opacity(0.15))
      }
    }
  }
  
  // MARK: - Actions
  
  private func runWithLogging() {
    consoleOutput.append("--- Logging Middleware ---")
    
    // Симуляция вывода logging middleware
    let result = TradingRequirements.completeTradeRequirement.evaluate(context)
    
    if result.isConfirmed {
      consoleOutput.append("[Trading] ✅ CompleteTradeRequirement (0.12ms)")
    } else {
      consoleOutput.append("[Trading] ❌ CompleteTradeRequirement - \(result.reason?.message ?? "Failed")")
    }
  }
  
  private func runWithAnalytics() {
    consoleOutput.append("--- Analytics Middleware ---")
    
    let analyticsRequirement = TradingRequirements.analyticsTradeCheck { event, props in
      // Это вызывается внутри middleware
    }
    
    let result = analyticsRequirement.evaluate(context)
    
    consoleOutput.append("Event: requirement_evaluated")
    consoleOutput.append("  requirement_name: CompleteTradeRequirement")
    consoleOutput.append("  result: \(result.isConfirmed ? "confirmed" : "failed")")
    if let reason = result.reason {
      consoleOutput.append("  reason_code: \(reason.code)")
    }
  }
}

#Preview {
  TradingDemoView()
}

