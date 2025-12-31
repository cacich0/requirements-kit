import SwiftUI
import RequirementsKit

/// Демонстрация AsyncRequirement, кэширования, профилирования и трассировки
struct SubscriptionDemoView: View {
  @State private var context = SubscriptionContext.sample
  @State private var selectedFeature: PremiumFeature = .advancedAnalytics
  
  // Async state
  @State private var isLoading = false
  @State private var asyncResults: [String: AsyncResultState] = [:]
  @State private var profilingMetrics: PerformanceMetrics?
  @State private var traceResult: RequirementTrace?
  
  enum AsyncResultState {
    case pending
    case loading
    case success
    case failure(String)
  }
  
  var body: some View {
    NavigationStack {
      ScrollView {
        VStack(alignment: .leading, spacing: 24) {
          CategoryHeader(title: "Subscription Requirements", systemImage: "crown")
          
          // Subscription Controls
          subscriptionControlsSection
          
          // Sync Requirements
          syncRequirementsSection
          
          // Async Requirements
          asyncRequirementsSection
          
          // Feature Access
          featureAccessSection
          
          // Caching Demo
          cachingSection
          
          // Profiling & Tracing
          profilingSection
        }
        .padding()
      }
      .background(Color.gray.opacity(0.1))
      .navigationTitle("Async & Performance")
      #if os(iOS)
      .navigationBarTitleDisplayMode(.inline)
      #endif
    }
  }
  
  // MARK: - Subscription Controls
  
  private var subscriptionControlsSection: some View {
    DemoSection(title: "Subscription Context", description: "Configure subscription settings") {
      VStack(spacing: 12) {
        Toggle("Logged In", isOn: $context.user.isLoggedIn)
        Toggle("Verified", isOn: $context.user.isVerified)
        Toggle("Beta Tester", isOn: $context.user.isBetaTester)
        
        Divider()
        
        Picker("Subscription Type", selection: $context.user.subscriptionType) {
          ForEach(SubscriptionType.allCases, id: \.self) { type in
            Text(type.displayName).tag(type)
          }
        }
        .pickerStyle(.segmented)
        
        if context.user.subscriptionType != .enterprise {
          VStack(alignment: .leading) {
            Text("Expires in days:")
              .font(.subheadline)
            
            let days = Calendar.current.dateComponents(
              [.day],
              from: context.currentDate,
              to: context.user.subscriptionExpiresAt ?? context.currentDate
            ).day ?? 0
            
            Slider(
              value: Binding(
                get: { Double(days) },
                set: { context.user.subscriptionExpiresAt = context.currentDate.addingTimeInterval($0 * 86400) }
              ),
              in: -30...365,
              step: 1
            )
            
            Text("\(days) days \(days < 0 ? "(expired)" : "")")
              .font(.caption)
              .foregroundStyle(days < 0 ? .red : .secondary)
          }
        }
        
        HStack {
          Button("Guest") { context.user = .guest }
            .buttonStyle(.bordered)
          Button("Regular") { context.user = .regularUser }
            .buttonStyle(.bordered)
          Button("Admin") { context.user = .adminUser }
            .buttonStyle(.bordered)
        }
      }
    }
  }
  
  // MARK: - Sync Requirements
  
  private var syncRequirementsSection: some View {
    DemoSection(
      title: "Sync Requirements",
      description: "Standard synchronous subscription checks"
    ) {
      VStack(alignment: .leading, spacing: 8) {
        let activeResult = SubscriptionRequirements.hasActiveSubscription.evaluate(context)
        RequirementResultView(
          title: "hasActiveSubscription",
          isConfirmed: activeResult.isConfirmed,
          reason: activeResult.reason?.message
        )
        
        let premiumResult = SubscriptionRequirements.hasPremium.evaluate(context)
        RequirementResultView(
          title: "hasPremium",
          isConfirmed: premiumResult.isConfirmed,
          reason: premiumResult.reason?.message
        )
        
        let enterpriseResult = SubscriptionRequirements.hasEnterprise.evaluate(context)
        RequirementResultView(
          title: "hasEnterprise",
          isConfirmed: enterpriseResult.isConfirmed,
          reason: enterpriseResult.reason?.message
        )
        
        let trialResult = SubscriptionRequirements.trialNotExpired.evaluate(context)
        RequirementResultView(
          title: "trialNotExpired",
          isConfirmed: trialResult.isConfirmed,
          reason: context.user.subscriptionType == .trial ? trialResult.reason?.message : "N/A (not trial)"
        )
      }
    }
  }
  
  // MARK: - Async Requirements
  
  private var asyncRequirementsSection: some View {
    DemoSection(
      title: "AsyncRequirement",
      description: "Asynchronous subscription verification"
    ) {
      VStack(alignment: .leading, spacing: 12) {
        CodeExampleCard(code: """
          let verifyAsync = AsyncRequirement { context in
            try await Task.sleep(for: .milliseconds(500))
            return context.user.hasActiveSubscription
              ? .confirmed
              : .failed(reason: ...)
          }
          
          // With timeout
          let withTimeout = AsyncRequirement
            .withTimeout(seconds: 2.0, verifyAsync)
          
          // Parallel execution
          let concurrent = AsyncRequirement
            .allConcurrent([verify, checkLimits])
          """)
        
        Divider()
        
        // Async check buttons
        VStack(spacing: 12) {
          asyncResultRow(
            title: "verifySubscriptionAsync",
            key: "verify",
            action: runVerifySubscription
          )
          
          asyncResultRow(
            title: "checkUsageLimits",
            key: "limits",
            action: runCheckLimits
          )
          
          asyncResultRow(
            title: "fullAsyncCheckConcurrent",
            key: "concurrent",
            action: runConcurrentCheck
          )
        }
        
        if isLoading {
          HStack {
            ProgressView()
              .scaleEffect(0.8)
            Text("Running async check...")
              .font(.caption)
              .foregroundStyle(.secondary)
          }
        }
      }
    }
  }
  
  private func asyncResultRow(title: String, key: String, action: @escaping () async -> Void) -> some View {
    HStack {
      VStack(alignment: .leading) {
        Text(title)
          .font(.subheadline)
        
        switch asyncResults[key] {
        case .none, .pending:
          Text("Not checked")
            .font(.caption)
            .foregroundStyle(.secondary)
        case .loading:
          Text("Checking...")
            .font(.caption)
            .foregroundStyle(.orange)
        case .success:
          Text("✅ Confirmed")
            .font(.caption)
            .foregroundStyle(.green)
        case .failure(let reason):
          Text("❌ \(reason)")
            .font(.caption)
            .foregroundStyle(.red)
        }
      }
      
      Spacer()
      
      Button("Run") {
        Task { await action() }
      }
      .buttonStyle(.bordered)
      .disabled(isLoading)
    }
  }
  
  // MARK: - Feature Access
  
  private var featureAccessSection: some View {
    DemoSection(
      title: "Feature Access",
      description: "Check access to specific premium features"
    ) {
      VStack(alignment: .leading, spacing: 12) {
        Picker("Feature", selection: $selectedFeature) {
          ForEach(PremiumFeature.allCases, id: \.self) { feature in
            Text(feature.displayName).tag(feature)
          }
        }
        
        Divider()
        
        let result = SubscriptionRequirements.canAccessFeature(selectedFeature).evaluate(context)
        
        RequirementResultView(
          title: "canAccessFeature(\(selectedFeature.displayName))",
          isConfirmed: result.isConfirmed,
          reason: result.reason?.message
        )
        
        Text("Required tier: \(selectedFeature.requiredTier.displayName)")
          .font(.caption)
          .foregroundStyle(.secondary)
        
        Text("Your tier: \(context.user.subscriptionType.displayName)")
          .font(.caption)
          .foregroundStyle(.secondary)
      }
    }
  }
  
  // MARK: - Caching
  
  private var cachingSection: some View {
    DemoSection(
      title: "Caching",
      description: ".cached(ttl:) for avoiding repeated evaluations"
    ) {
      VStack(alignment: .leading, spacing: 8) {
        CodeExampleCard(code: """
          // With TTL (60 seconds)
          let cached = requirement.cached(ttl: 60)
          
          // Permanent cache
          let permanent = requirement.cached()
          
          // Usage
          cached.evaluate(context) // First call - evaluates
          cached.evaluate(context) // Cached result
          cached.invalidate(context) // Clear cache
          """)
        
        Divider()
        
        let cacheCount = SubscriptionRequirements.cachedSubscriptionCheck.cacheCount
        
        HStack {
          Text("Cache entries: \(cacheCount)")
            .font(.subheadline)
          
          Spacer()
          
          Button("Evaluate") {
            _ = SubscriptionRequirements.cachedSubscriptionCheck.evaluate(context)
          }
          .buttonStyle(.bordered)
          
          Button("Invalidate") {
            SubscriptionRequirements.cachedSubscriptionCheck.invalidate(context)
          }
          .buttonStyle(.bordered)
          .tint(.orange)
          
          Button("Clear All") {
            SubscriptionRequirements.cachedSubscriptionCheck.invalidateAll()
          }
          .buttonStyle(.bordered)
          .tint(.red)
        }
      }
    }
  }
  
  // MARK: - Profiling & Tracing
  
  private var profilingSection: some View {
    DemoSection(
      title: "Profiling & Tracing",
      description: ".profiled() and .traced() for performance analysis"
    ) {
      VStack(alignment: .leading, spacing: 12) {
        CodeExampleCard(code: """
          // Profiling
          let profiled = requirement.profiled()
          let (result, metrics) = profiled.evaluateWithMetrics(context)
          print("Duration: \\(metrics.duration)s")
          print("Average: \\(metrics.averageDuration)s")
          
          // Tracing
          let traced = requirement.traced(name: "MyCheck")
          let (result, trace) = traced.evaluateWithTrace(context)
          print("Path: \\(trace.path)")
          print("Duration: \\(trace.duration)s")
          """)
        
        Divider()
        
        HStack {
          Button("Run Profiled") {
            runProfiling()
          }
          .buttonStyle(.borderedProminent)
          
          Button("Run Traced") {
            runTracing()
          }
          .buttonStyle(.bordered)
          
          Button("Reset") {
            SubscriptionRequirements.profiledSubscriptionCheck.reset()
            profilingMetrics = nil
            traceResult = nil
          }
          .buttonStyle(.bordered)
          .tint(.red)
        }
        
        if let metrics = profilingMetrics {
          VStack(alignment: .leading, spacing: 4) {
            Text("Profiling Results:")
              .font(.subheadline.bold())
            
            Text("Evaluations: \(metrics.evaluationCount)")
              .font(.caption.monospaced())
            Text("Last duration: \(String(format: "%.4f", metrics.duration * 1000))ms")
              .font(.caption.monospaced())
            Text("Average: \(String(format: "%.4f", metrics.averageDuration * 1000))ms")
              .font(.caption.monospaced())
            Text("Min: \(String(format: "%.4f", metrics.minDuration * 1000))ms")
              .font(.caption.monospaced())
            Text("Max: \(String(format: "%.4f", metrics.maxDuration * 1000))ms")
              .font(.caption.monospaced())
          }
          .padding(8)
          .background {
            RoundedRectangle(cornerRadius: 8)
              .fill(Color.gray.opacity(0.15))
          }
        }
        
        if let trace = traceResult {
          VStack(alignment: .leading, spacing: 4) {
            Text("Trace Results:")
              .font(.subheadline.bold())
            
            Text("Path: \(trace.path.joined(separator: " > "))")
              .font(.caption.monospaced())
            Text("Duration: \(String(format: "%.4f", trace.duration * 1000))ms")
              .font(.caption.monospaced())
            Text("Result: \(trace.evaluation.isConfirmed ? "✅ Confirmed" : "❌ Failed")")
              .font(.caption.monospaced())
          }
          .padding(8)
          .background {
            RoundedRectangle(cornerRadius: 8)
              .fill(Color.gray.opacity(0.15))
          }
        }
      }
    }
  }
  
  // MARK: - Actions
  
  private func runVerifySubscription() async {
    asyncResults["verify"] = .loading
    isLoading = true
    
    do {
      let result = try await SubscriptionRequirements.verifySubscriptionAsync.evaluate(context)
      asyncResults["verify"] = result.isConfirmed ? .success : .failure(result.reason?.message ?? "Failed")
    } catch {
      asyncResults["verify"] = .failure(error.localizedDescription)
    }
    
    isLoading = false
  }
  
  private func runCheckLimits() async {
    asyncResults["limits"] = .loading
    isLoading = true
    
    do {
      let result = try await SubscriptionRequirements.checkUsageLimits.evaluate(context)
      asyncResults["limits"] = result.isConfirmed ? .success : .failure(result.reason?.message ?? "Failed")
    } catch {
      asyncResults["limits"] = .failure(error.localizedDescription)
    }
    
    isLoading = false
  }
  
  private func runConcurrentCheck() async {
    asyncResults["concurrent"] = .loading
    isLoading = true
    
    do {
      let result = try await SubscriptionRequirements.fullAsyncCheckConcurrent.evaluate(context)
      asyncResults["concurrent"] = result.isConfirmed ? .success : .failure(result.reason?.message ?? "Failed")
    } catch {
      asyncResults["concurrent"] = .failure(error.localizedDescription)
    }
    
    isLoading = false
  }
  
  private func runProfiling() {
    let (_, metrics) = SubscriptionRequirements.profiledSubscriptionCheck.evaluateWithMetrics(context)
    profilingMetrics = metrics
  }
  
  private func runTracing() {
    let (_, trace) = SubscriptionRequirements.tracedSubscriptionCheck.evaluateWithTrace(context)
    traceResult = trace
  }
}

#Preview {
  SubscriptionDemoView()
}

