import SwiftUI
import RequirementsKit

/// Демонстрация валидации строк, коллекций и форм
struct ValidationDemoView: View {
  @State private var formContext = FormContext.empty
  @State private var order = Order.empty
  @State private var selectedTab = 0
  
  var body: some View {
    NavigationStack {
      ScrollView {
        VStack(alignment: .leading, spacing: 24) {
          CategoryHeader(title: "Validation Requirements", systemImage: "checkmark.shield")
          
          // Tab selector
          Picker("Validation Type", selection: $selectedTab) {
            Text("Registration").tag(0)
            Text("Login").tag(1)
            Text("Order").tag(2)
          }
          .pickerStyle(.segmented)
          
          switch selectedTab {
          case 0:
            registrationFormSection
          case 1:
            loginFormSection
          case 2:
            orderValidationSection
          default:
            EmptyView()
          }
        }
        .padding()
      }
      .background(Color.gray.opacity(0.1))
      .navigationTitle("Validation Demo")
      #if os(iOS)
      .navigationBarTitleDisplayMode(.inline)
      #endif
    }
  }
  
  // MARK: - Registration Form
  
  private var registrationFormSection: some View {
    VStack(spacing: 24) {
      // Form Fields
      DemoSection(title: "Registration Form", description: "Complete form validation with multiple rules") {
        VStack(spacing: 16) {
          // Email
          validatedTextField(
            title: "Email",
            text: $formContext.email,
            placeholder: "user@example.com",
            requirement: ValidationRequirements.validEmail,
            isEmail: true
          )
          
          // Username
          validatedTextField(
            title: "Username",
            text: $formContext.username,
            placeholder: "john_doe",
            requirement: ValidationRequirements.validUsername
          )
          
          // Password
          validatedSecureField(
            title: "Password",
            text: $formContext.password,
            placeholder: "••••••••",
            requirement: ValidationRequirements.validPassword
          )
          
          // Password Strength
          passwordStrengthIndicator
          
          // Confirm Password
          validatedSecureField(
            title: "Confirm Password",
            text: $formContext.confirmPassword,
            placeholder: "••••••••",
            requirement: ValidationRequirements.passwordsMatch
          )
          
          // Phone
          validatedTextField(
            title: "Phone",
            text: $formContext.phone,
            placeholder: "+1234567890",
            requirement: ValidationRequirements.validPhone
          )
          
          // Age
          VStack(alignment: .leading, spacing: 4) {
            Text("Age: \(formContext.age)")
              .font(.subheadline)
            
            Stepper("", value: $formContext.age, in: 0...120)
              .labelsHidden()
            
            let ageResult = ValidationRequirements.isAdult.evaluate(formContext)
            if !ageResult.isConfirmed {
              Text(ageResult.reason?.message ?? "Invalid age")
                .font(.caption)
                .foregroundStyle(.red)
            }
          }
          
          // Terms
          Toggle("I accept the terms and conditions", isOn: $formContext.acceptedTerms)
            .font(.subheadline)
          
          let termsResult = ValidationRequirements.termsAccepted.evaluate(formContext)
          if !termsResult.isConfirmed {
            Text(termsResult.reason?.message ?? "")
              .font(.caption)
              .foregroundStyle(.red)
          }
        }
      }
      
      // Validation Results
      validationResultsSection(
        title: "Form Validation",
        requirement: ValidationRequirements.validRegistrationForm,
        context: formContext
      )
      
      // Code Example
      codeExampleSection
      
      // Quick Fill
      HStack {
        Button("Fill Valid") {
          formContext = .sample
        }
        .buttonStyle(.borderedProminent)
        
        Button("Clear") {
          formContext = .empty
        }
        .buttonStyle(.bordered)
        .tint(.red)
      }
    }
  }
  
  // MARK: - Login Form
  
  private var loginFormSection: some View {
    VStack(spacing: 24) {
      DemoSection(title: "Login Form", description: "Simple email + password validation") {
        VStack(spacing: 16) {
          validatedTextField(
            title: "Email",
            text: $formContext.email,
            placeholder: "user@example.com",
            requirement: ValidationRequirements.validEmail,
            isEmail: true
          )
          
          validatedSecureField(
            title: "Password",
            text: $formContext.password,
            placeholder: "••••••••",
            requirement: ValidationRequirements.passwordNotEmpty
          )
        }
      }
      
      validationResultsSection(
        title: "Login Validation",
        requirement: ValidationRequirements.validLoginForm,
        context: formContext
      )
    }
  }
  
  // MARK: - Order Validation
  
  private var orderValidationSection: some View {
    VStack(spacing: 24) {
      DemoSection(title: "Order Validation", description: "Collection and address validation") {
        VStack(spacing: 16) {
          // Cart items
          VStack(alignment: .leading, spacing: 8) {
            Text("Cart Items: \(order.itemCount)")
              .font(.subheadline)
            
            HStack {
              Button("Add Item") {
                order.items.append(OrderItem(product: .sample, quantity: 1))
              }
              .buttonStyle(.bordered)
              
              Button("Remove Item") {
                if !order.items.isEmpty {
                  order.items.removeLast()
                }
              }
              .buttonStyle(.bordered)
              .disabled(order.items.isEmpty)
              
              Button("Clear Cart") {
                order.items.removeAll()
              }
              .buttonStyle(.bordered)
              .tint(.red)
            }
            
            Text("Total: $\(order.totalAmount, specifier: "%.2f")")
              .font(.caption)
              .foregroundStyle(.secondary)
          }
          
          Divider()
          
          // Shipping Address
          VStack(alignment: .leading, spacing: 4) {
            Text("Shipping Address")
              .font(.subheadline)
            
            TextField("123 Main St, City, Country", text: $order.shippingAddress)
              .textFieldStyle(.roundedBorder)
            
            let shippingResult = OrderValidation.hasShippingAddress.evaluate(order)
            if !shippingResult.isConfirmed {
              Text(shippingResult.reason?.message ?? "")
                .font(.caption)
                .foregroundStyle(.red)
            }
          }
          
          // Billing Address
          VStack(alignment: .leading, spacing: 4) {
            Text("Billing Address")
              .font(.subheadline)
            
            TextField("123 Main St, City, Country", text: $order.billingAddress)
              .textFieldStyle(.roundedBorder)
            
            Toggle("Same as shipping", isOn: Binding(
              get: { order.billingAddress == order.shippingAddress },
              set: { if $0 { order.billingAddress = order.shippingAddress } }
            ))
            .font(.caption)
          }
          
          // Payment Method
          Picker("Payment Method", selection: $order.paymentMethod) {
            ForEach(PaymentMethod.allCases, id: \.self) { method in
              Text(method.displayName).tag(method)
            }
          }
        }
      }
      
      // Order validation results
      DemoSection(title: "Order Validation Results", description: "Individual checks") {
        VStack(alignment: .leading, spacing: 8) {
          let cartResult = OrderValidation.cartNotEmpty.evaluate(order)
          RequirementResultView(
            title: "cartNotEmpty",
            isConfirmed: cartResult.isConfirmed,
            reason: cartResult.reason?.message
          )
          
          let shippingResult = OrderValidation.hasShippingAddress.evaluate(order)
          RequirementResultView(
            title: "hasShippingAddress",
            isConfirmed: shippingResult.isConfirmed,
            reason: shippingResult.reason?.message
          )
          
          let billingResult = OrderValidation.hasBillingAddress.evaluate(order)
          RequirementResultView(
            title: "hasBillingAddress",
            isConfirmed: billingResult.isConfirmed,
            reason: billingResult.reason?.message
          )
          
          let minAmountResult = OrderValidation.minimumOrderAmount(10).evaluate(order)
          RequirementResultView(
            title: "minimumOrderAmount($10)",
            isConfirmed: minAmountResult.isConfirmed,
            reason: minAmountResult.reason?.message
          )
          
          Divider()
          
          let validOrderResult = OrderValidation.validOrder.evaluate(order)
          RequirementResultView(
            title: "validOrder (complete)",
            isConfirmed: validOrderResult.isConfirmed,
            reason: validOrderResult.reason?.message
          )
        }
      }
      
      // Quick actions
      HStack {
        Button("Fill Valid Order") {
          order = .sample
        }
        .buttonStyle(.borderedProminent)
        
        Button("Clear Order") {
          order = .empty
        }
        .buttonStyle(.bordered)
        .tint(.red)
      }
    }
  }
  
  // MARK: - Helper Views
  
  private func validatedTextField(
    title: String,
    text: Binding<String>,
    placeholder: String,
    requirement: Requirement<FormContext>,
    isEmail: Bool = false
  ) -> some View {
    VStack(alignment: .leading, spacing: 4) {
      Text(title)
        .font(.subheadline)
      
      TextField(placeholder, text: text)
        .textFieldStyle(.roundedBorder)
        #if os(iOS)
        .keyboardType(isEmail ? .emailAddress : .default)
        .autocapitalization(.none)
        #endif
      
      let result = requirement.evaluate(formContext)
      if !text.wrappedValue.isEmpty && !result.isConfirmed {
        Text(result.reason?.message ?? "Invalid")
          .font(.caption)
          .foregroundStyle(.red)
      } else if !text.wrappedValue.isEmpty && result.isConfirmed {
        Text("✓ Valid")
          .font(.caption)
          .foregroundStyle(.green)
      }
    }
  }
  
  private func validatedSecureField(
    title: String,
    text: Binding<String>,
    placeholder: String,
    requirement: Requirement<FormContext>
  ) -> some View {
    VStack(alignment: .leading, spacing: 4) {
      Text(title)
        .font(.subheadline)
      
      SecureField(placeholder, text: text)
        .textFieldStyle(.roundedBorder)
      
      let result = requirement.evaluate(formContext)
      if !text.wrappedValue.isEmpty && !result.isConfirmed {
        Text(result.reason?.message ?? "Invalid")
          .font(.caption)
          .foregroundStyle(.red)
      } else if !text.wrappedValue.isEmpty && result.isConfirmed {
        Text("✓ Valid")
          .font(.caption)
          .foregroundStyle(.green)
      }
    }
  }
  
  private var passwordStrengthIndicator: some View {
    VStack(alignment: .leading, spacing: 4) {
      let (score, level) = PasswordStrength.evaluate(formContext.password)
      
      Text("Password Strength: \(level.rawValue)")
        .font(.caption)
      
      GeometryReader { geometry in
        ZStack(alignment: .leading) {
          RoundedRectangle(cornerRadius: 4)
            .fill(Color.gray.opacity(0.2))
          
          RoundedRectangle(cornerRadius: 4)
            .fill(strengthColor(level))
            .frame(width: geometry.size.width * CGFloat(score) / 6.0)
        }
      }
      .frame(height: 8)
      
      HStack(spacing: 4) {
        strengthBadge("8+ chars", met: formContext.password.count >= 8)
        strengthBadge("A-Z", met: formContext.password.range(of: "[A-Z]", options: .regularExpression) != nil)
        strengthBadge("a-z", met: formContext.password.range(of: "[a-z]", options: .regularExpression) != nil)
        strengthBadge("0-9", met: formContext.password.range(of: "[0-9]", options: .regularExpression) != nil)
        strengthBadge("!@#", met: formContext.password.range(of: "[!@#$%^&*(),.?\":{}|<>]", options: .regularExpression) != nil)
      }
    }
  }
  
  private func strengthColor(_ level: PasswordStrength.Level) -> Color {
    switch level {
    case .weak: return .red
    case .medium: return .orange
    case .strong: return .green
    }
  }
  
  private func strengthBadge(_ label: String, met: Bool) -> some View {
    Text(label)
      .font(.system(size: 10))
      .padding(.horizontal, 6)
      .padding(.vertical, 2)
      .background {
        RoundedRectangle(cornerRadius: 4)
          .fill(met ? Color.green.opacity(0.2) : Color.gray.opacity(0.2))
      }
      .foregroundStyle(met ? .green : .secondary)
  }
  
  private func validationResultsSection<Context: Sendable & Hashable>(
    title: String,
    requirement: Requirement<Context>,
    context: Context
  ) -> some View {
    DemoSection(title: title, description: "Overall form status") {
      let result = requirement.evaluate(context)
      
      HStack {
        Image(systemName: result.isConfirmed ? "checkmark.circle.fill" : "xmark.circle.fill")
          .font(.largeTitle)
          .foregroundStyle(result.isConfirmed ? .green : .red)
        
        VStack(alignment: .leading) {
          Text(result.isConfirmed ? "Form is valid" : "Form has errors")
            .font(.headline)
          
          if let reason = result.reason {
            Text(reason.message)
              .font(.subheadline)
              .foregroundStyle(.secondary)
          }
        }
        
        Spacer()
        
        Button(result.isConfirmed ? "Submit" : "Fix Errors") {
          // Action
        }
        .buttonStyle(.borderedProminent)
        .disabled(!result.isConfirmed)
      }
    }
  }
  
  private var codeExampleSection: some View {
    DemoSection(title: "Code Examples", description: "String validation patterns") {
      VStack(alignment: .leading, spacing: 12) {
        CodeExampleCard(code: """
          // Email validation
          let validEmail = Requirement
            .requireNotBlank(\\.email)
            .and(Requirement.requireMatches(
              \\.email, 
              pattern: ValidationPattern.email
            ))
          
          // Password with multiple rules
          let validPassword = Requirement.all {
            requireMinLength(\\.password, minLength: 8)
            requireMatches(\\.password, pattern: ".*[0-9].*")
            requireMatches(\\.password, pattern: ".*[A-Z].*")
          }
          
          // Collection validation
          let cartNotEmpty = Requirement
            .requireNotEmpty(\\.items)
          
          // Range validation
          let validAge = Requirement
            .requireInRange(\\.age, range: 13...120)
          """)
      }
    }
  }
}

#Preview {
  ValidationDemoView()
}

