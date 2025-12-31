import SwiftUI
import RequirementsKit

/// Демонстрация макросов и Core API
struct AuthDemoView: View {
  @State private var user = User.regularUser
  
  var body: some View {
    NavigationStack {
      ScrollView {
        VStack(alignment: .leading, spacing: 24) {
          CategoryHeader(title: "Auth Requirements", systemImage: "person.badge.key")
          
          // User Controls
          userControlsSection
          
          // Basic Macros Demo
          basicMacrosSection
          
          // Composition Demo
          compositionSection
          
          // Conditional Macros Demo
          conditionalMacrosSection
          
          // XOR Demo
          xorDemoSection
        }
        .padding()
      }
      .background(Color.gray.opacity(0.1))
      .navigationTitle("Macros Demo")
      #if os(iOS)
      .navigationBarTitleDisplayMode(.inline)
      #endif
    }
  }
  
  // MARK: - User Controls
  
  private var userControlsSection: some View {
    DemoSection(title: "User Settings", description: "Toggle user properties to see how requirements change") {
      VStack(spacing: 12) {
        Toggle("Logged In", isOn: $user.isLoggedIn)
        Toggle("Verified", isOn: $user.isVerified)
        Toggle("Admin", isOn: $user.isAdmin)
        Toggle("Banned", isOn: $user.isBanned)
        Toggle("2FA Enabled", isOn: $user.twoFactorEnabled)
        Toggle("KYC Completed", isOn: $user.kycCompleted)
        Toggle("Beta Tester", isOn: $user.isBetaTester)
        
        Divider()
        
        Picker("Subscription", selection: $user.subscriptionType) {
          ForEach(SubscriptionType.allCases, id: \.self) { type in
            Text(type.displayName).tag(type)
          }
        }
        .pickerStyle(.segmented)
        
        // Quick presets
        HStack {
          Button("Guest") { user = .guest }
            .buttonStyle(.bordered)
          Button("Regular") { user = .regularUser }
            .buttonStyle(.bordered)
          Button("Admin") { user = .adminUser }
            .buttonStyle(.bordered)
        }
      }
    }
  }
  
  // MARK: - Basic Macros
  
  private var basicMacrosSection: some View {
    DemoSection(
      title: "#require Macro",
      description: "Basic requirements using #require(\\.keyPath)"
    ) {
      VStack(alignment: .leading, spacing: 8) {
        CodeExampleCard(code: """
          let isLoggedIn = #require(\\.isLoggedIn)
          let isVerified = #require(\\.isVerified)
          let notBanned = #not(#require(\\.isBanned))
          """)
        
        Divider()
        
        let isLoggedInResult = AuthRequirements.isLoggedIn.evaluate(user)
        RequirementResultView(
          title: "#require(\\.isLoggedIn)",
          isConfirmed: isLoggedInResult.isConfirmed,
          reason: isLoggedInResult.reason?.message
        )
        
        let isVerifiedResult = AuthRequirements.isVerified.evaluate(user)
        RequirementResultView(
          title: "#require(\\.isVerified)",
          isConfirmed: isVerifiedResult.isConfirmed,
          reason: isVerifiedResult.reason?.message
        )
        
        let notBannedResult = AuthRequirements.notBanned.evaluate(user)
        RequirementResultView(
          title: "#not(#require(\\.isBanned))",
          isConfirmed: notBannedResult.isConfirmed,
          reason: notBannedResult.reason?.message
        )
        
        let isAdminResult = AuthRequirements.isAdmin.evaluate(user)
        RequirementResultView(
          title: "#require(\\.isAdmin)",
          isConfirmed: isAdminResult.isConfirmed,
          reason: isAdminResult.reason?.message
        )
      }
    }
  }
  
  // MARK: - Composition
  
  private var compositionSection: some View {
    DemoSection(
      title: "#all & #any Macros",
      description: "Composing requirements with #all { } and #any { }"
    ) {
      VStack(alignment: .leading, spacing: 8) {
        CodeExampleCard(code: """
          // All must pass
          let hasFullAccess = #all {
            #require(\\.isLoggedIn)
            #require(\\.isVerified)
            #not(#require(\\.isBanned))
          }
          
          // Any one must pass
          let hasPremiumAccess = #any {
            #require(\\.isAdmin)
            #require(\\.isPremium)
            #require(\\.isEnterprise)
          }
          """)
        
        Divider()
        
        let fullAccessResult = AuthRequirements.hasFullAccess.evaluate(user)
        RequirementResultView(
          title: "hasFullAccess (#all)",
          isConfirmed: fullAccessResult.isConfirmed,
          reason: fullAccessResult.reason?.message
        )
        
        let premiumAccessResult = AuthRequirements.hasPremiumAccess.evaluate(user)
        RequirementResultView(
          title: "hasPremiumAccess (#any)",
          isConfirmed: premiumAccessResult.isConfirmed,
          reason: premiumAccessResult.reason?.message
        )
        
        let canManageResult = AuthRequirements.canManageAccount.evaluate(user)
        RequirementResultView(
          title: "canManageAccount",
          isConfirmed: canManageResult.isConfirmed,
          reason: canManageResult.reason?.message
        )
        
        let adminPanelResult = AuthRequirements.canAccessAdminPanel.evaluate(user)
        RequirementResultView(
          title: "canAccessAdminPanel",
          isConfirmed: adminPanelResult.isConfirmed,
          reason: adminPanelResult.reason?.message
        )
      }
    }
  }
  
  // MARK: - Conditional Macros
  
  private var conditionalMacrosSection: some View {
    DemoSection(
      title: "#when & #unless Macros",
      description: "Conditional requirements that apply only when condition is met"
    ) {
      VStack(alignment: .leading, spacing: 8) {
        CodeExampleCard(code: """
          // Only checked if user is beta tester
          let betaTesterReq = #when(\\.isBetaTester) {
            #require(\\.hasActiveSubscription)
          }
          
          // Only checked if user is NOT admin
          let nonAdminReq = #unless(\\.isAdmin) {
            #require(\\.isVerified)
            #require(\\.kycCompleted)
          }
          """)
        
        Divider()
        
        let betaTesterResult = AuthRequirements.betaTesterRequirement.evaluate(user)
        RequirementResultView(
          title: "#when(\\.isBetaTester) { ... }",
          isConfirmed: betaTesterResult.isConfirmed,
          reason: user.isBetaTester ? betaTesterResult.reason?.message : "Skipped (not beta tester)"
        )
        
        let nonAdminResult = AuthRequirements.nonAdminVerification.evaluate(user)
        RequirementResultView(
          title: "#unless(\\.isAdmin) { ... }",
          isConfirmed: nonAdminResult.isConfirmed,
          reason: user.isAdmin ? "Skipped (is admin)" : nonAdminResult.reason?.message
        )
      }
    }
  }
  
  // MARK: - XOR Demo
  
  private var xorDemoSection: some View {
    DemoSection(
      title: "#xor Macro",
      description: "Exactly one requirement must pass (exclusive or)"
    ) {
      VStack(alignment: .leading, spacing: 8) {
        CodeExampleCard(code: """
          // Exactly one must be true
          let exclusiveSubscription = #xor {
            Requirement { $0.subscriptionType == .trial }
            Requirement { $0.subscriptionType == .premium }
          }
          """)
        
        Divider()
        
        Text("Current subscription: \(user.subscriptionType.displayName)")
          .font(.subheadline)
          .foregroundStyle(.secondary)
        
        let xorResult = AuthRequirements.exclusiveSubscription.evaluate(user)
        RequirementResultView(
          title: "#xor (trial XOR premium)",
          isConfirmed: xorResult.isConfirmed,
          reason: xorResult.reason?.message
        )
        
        Text("XOR passes only if subscription is exactly Trial OR exactly Premium (not both, not neither)")
          .font(.caption)
          .foregroundStyle(.secondary)
          .padding(.top, 4)
      }
    }
  }
}

#Preview {
  AuthDemoView()
}

