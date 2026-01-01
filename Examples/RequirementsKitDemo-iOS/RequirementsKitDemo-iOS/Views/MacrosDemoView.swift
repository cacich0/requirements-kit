import SwiftUI
import RequirementsKit

// MARK: - Macros Demo View

struct MacrosDemoView: View {
  @State private var selectedTab = 0
  
  var body: some View {
    NavigationView {
      TabView(selection: $selectedTab) {
        StringMacrosTab()
          .tabItem {
            Label("Строки", systemImage: "textformat")
          }
          .tag(0)
        
        CollectionMacrosTab()
          .tabItem {
            Label("Коллекции", systemImage: "list.bullet")
          }
          .tag(1)
        
        OptionalMacrosTab()
          .tabItem {
            Label("Optional", systemImage: "questionmark.circle")
          }
          .tag(2)
        
        RangeMacrosTab()
          .tabItem {
            Label("Диапазоны", systemImage: "slider.horizontal.3")
          }
          .tag(3)
        
        RequirementModelTab()
          .tabItem {
            Label("@RequirementModel", systemImage: "checkmark.seal")
          }
          .tag(4)
      }
      .navigationTitle("Демо макросов")
    }
  }
}

// MARK: - String Macros Tab

struct StringMacrosTab: View {
  @State private var email = ""
  @State private var username = ""
  @State private var password = ""
  @State private var phone = ""
  @State private var website = ""
  
  var body: some View {
    Form {
      Section("Email (#requireEmail)") {
        TextField("Email", text: $email)
          .textInputAutocapitalization(.never)
          .keyboardType(.emailAddress)
        
        ValidationRow(
          requirement: #requireEmail(\.email),
          context: StringValidationContext(
            email: email,
            username: username,
            password: password,
            phone: phone,
            website: website
          )
        )
      }
      
      Section("Username (#requireMinLength, #requireMaxLength)") {
        TextField("Username", text: $username)
          .textInputAutocapitalization(.never)
        
        ValidationRow(
          requirement: #all {
            #requireMinLength(\.username, 3)
            #requireMaxLength(\.username, 20)
          },
          context: StringValidationContext(
            email: email,
            username: username,
            password: password,
            phone: phone,
            website: website
          )
        )
      }
      
      Section("Password (#requireLength, #requireMatches)") {
        SecureField("Password", text: $password)
        
        ValidationRow(
          requirement: #all {
            #requireLength(\.password, in: 8...128)
            #requireMatches(\.password, pattern: ".*[0-9].*")
          },
          context: StringValidationContext(
            email: email,
            username: username,
            password: password,
            phone: phone,
            website: website
          )
        )
      }
      
      Section("Phone (#requirePhone)") {
        TextField("Phone (+1234567890)", text: $phone)
          .keyboardType(.phonePad)
        
        ValidationRow(
          requirement: #requirePhone(\.phone),
          context: StringValidationContext(
            email: email,
            username: username,
            password: password,
            phone: phone,
            website: website
          )
        )
      }
      
      Section("Website (#requireURL)") {
        TextField("Website URL", text: $website)
          .textInputAutocapitalization(.never)
          .keyboardType(.URL)
        
        ValidationRow(
          requirement: #requireURL(\.website),
          context: StringValidationContext(
            email: email,
            username: username,
            password: password,
            phone: phone,
            website: website
          )
        )
      }
    }
  }
}

struct StringValidationContext: Sendable {
  let email: String
  let username: String
  let password: String
  let phone: String
  let website: String
}

// MARK: - Collection Macros Tab

struct CollectionMacrosTab: View {
  @State private var items: [String] = []
  @State private var newItem = ""
  
  var body: some View {
    Form {
      Section("Items (#requireNotEmpty, #requireCount)") {
        HStack {
          TextField("New item", text: $newItem)
          Button("Add") {
            if !newItem.isEmpty {
              items.append(newItem)
              newItem = ""
            }
          }
        }
        
        ForEach(items, id: \.self) { item in
          Text(item)
        }
        .onDelete { indexSet in
          items.remove(atOffsets: indexSet)
        }
        
        Text("Items: \(items.count)")
          .foregroundStyle(.secondary)
      }
      
      Section("Validation Results") {
        ValidationRow(
          requirement: #requireNotEmpty(\.items),
          context: CollectionValidationContext(items: items),
          label: "Not Empty"
        )
        
        ValidationRow(
          requirement: #requireCount(\.items, min: 1, max: 10),
          context: CollectionValidationContext(items: items),
          label: "Count (1-10)"
        )
        
        ValidationRow(
          requirement: #requireEmpty(\.errors),
          context: CollectionValidationContext(items: items, errors: []),
          label: "Errors Empty"
        )
      }
    }
  }
}

struct CollectionValidationContext: Sendable {
  let items: [String]
  var errors: [String] = []
}

// MARK: - Optional Macros Tab

struct OptionalMacrosTab: View {
  @State private var userId: String? = nil
  @State private var age: Int? = nil
  @State private var tempData: String? = nil
  @State private var userIdInput = ""
  @State private var ageInput = ""
  
  var body: some View {
    Form {
      Section("User ID (#requireNonNil)") {
        HStack {
          TextField("User ID", text: $userIdInput)
          Button("Set") {
            userId = userIdInput.isEmpty ? nil : userIdInput
          }
          Button("Clear") {
            userId = nil
            userIdInput = ""
          }
        }
        
        Text("Value: \(userId ?? "nil")")
          .foregroundStyle(.secondary)
        
        ValidationRow(
          requirement: #requireNonNil(\.userId),
          context: OptionalValidationContext(
            userId: userId,
            age: age,
            tempData: tempData
          )
        )
      }
      
      Section("Age (#requireSome with predicate)") {
        HStack {
          TextField("Age", text: $ageInput)
            .keyboardType(.numberPad)
          Button("Set") {
            age = Int(ageInput)
          }
          Button("Clear") {
            age = nil
            ageInput = ""
          }
        }
        
        Text("Value: \(age.map(String.init) ?? "nil")")
          .foregroundStyle(.secondary)
        
        ValidationRow(
          requirement: #requireSome(\.age, where: { $0 >= 18 }),
          context: OptionalValidationContext(
            userId: userId,
            age: age,
            tempData: tempData
          ),
          label: "Age >= 18"
        )
      }
      
      Section("Temp Data (#requireNil)") {
        HStack {
          TextField("Temp Data", text: Binding(
            get: { tempData ?? "" },
            set: { tempData = $0.isEmpty ? nil : $0 }
          ))
          Button("Clear") {
            tempData = nil
          }
        }
        
        Text("Value: \(tempData ?? "nil")")
          .foregroundStyle(.secondary)
        
        ValidationRow(
          requirement: #requireNil(\.tempData),
          context: OptionalValidationContext(
            userId: userId,
            age: age,
            tempData: tempData
          ),
          label: "Should be nil"
        )
      }
    }
  }
}

struct OptionalValidationContext: Sendable {
  let userId: String?
  let age: Int?
  let tempData: String?
}

// MARK: - Range Macros Tab

struct RangeMacrosTab: View {
  @State private var age = 25
  @State private var temperature = 20.0
  @State private var score = 50
  
  var body: some View {
    Form {
      Section("Age (#requireInRange)") {
        Stepper("Age: \(age)", value: $age, in: 0...150)
        
        ValidationRow(
          requirement: #requireInRange(\.age, 18...120),
          context: RangeValidationContext(
            age: age,
            temperature: temperature,
            score: score
          ),
          label: "Age in 18-120"
        )
      }
      
      Section("Temperature (#requireInRange)") {
        Slider(value: $temperature, in: -50...50)
        Text("Temperature: \(temperature, specifier: "%.1f")°C")
          .foregroundStyle(.secondary)
        
        ValidationRow(
          requirement: #requireInRange(\.temperature, -40.0...50.0),
          context: RangeValidationContext(
            age: age,
            temperature: temperature,
            score: score
          ),
          label: "Temp in -40 to +50"
        )
      }
      
      Section("Score (#requireBetween)") {
        Slider(value: Binding(
          get: { Double(score) },
          set: { score = Int($0) }
        ), in: 0...100)
        Text("Score: \(score)")
          .foregroundStyle(.secondary)
        
        ValidationRow(
          requirement: #requireBetween(\.score, min: 0, max: 100),
          context: RangeValidationContext(
            age: age,
            temperature: temperature,
            score: score
          ),
          label: "Score 0-100"
        )
      }
      
      Section("Combined Validation") {
        ValidationRow(
          requirement: #all {
            #requireInRange(\.age, 18...120)
            #requireInRange(\.temperature, -40.0...50.0)
            #requireBetween(\.score, min: 0, max: 100)
          },
          context: RangeValidationContext(
            age: age,
            temperature: temperature,
            score: score
          ),
          label: "All valid"
        )
      }
    }
  }
}

struct RangeValidationContext: Sendable {
  let age: Int
  let temperature: Double
  let score: Int
}

// MARK: - @RequirementModel Tab

struct RequirementModelTab: View {
  @State private var username = "john"
  @State private var email = "john@example.com"
  @State private var age = 25
  @State private var phone = "+1234567890"
  
  var currentUser: ValidatedUser {
    ValidatedUser(
      username: username,
      email: email,
      age: age,
      phoneNumber: phone,
      userId: "user123",
      createdAt: Date()
    )
  }
  
  var body: some View {
    Form {
      Section("User Data") {
        TextField("Username", text: $username)
        TextField("Email", text: $email)
          .textInputAutocapitalization(.never)
          .keyboardType(.emailAddress)
        Stepper("Age: \(age)", value: $age, in: 0...150)
        TextField("Phone", text: $phone)
          .keyboardType(.phonePad)
      }
      
      Section("Validation Results") {
        let validation = currentUser.validate()
        
        HStack {
          Text("Overall")
          Spacer()
          if validation.isConfirmed {
            Image(systemName: "checkmark.circle.fill")
              .foregroundStyle(.green)
          } else {
            Image(systemName: "xmark.circle.fill")
              .foregroundStyle(.red)
          }
        }
        
        if !validation.isConfirmed {
          ForEach(validation.allFailures, id: \.message) { failure in
            HStack {
              Image(systemName: "exclamationmark.triangle")
                .foregroundStyle(.orange)
              Text(failure.message)
                .font(.caption)
            }
          }
        }
      }
      
      Section("Sample Data") {
        Button("Load Valid User") {
          let sample = ValidatedUser.sample
          username = sample.username
          email = sample.email
          age = sample.age
          phone = sample.phoneNumber
        }
        
        Button("Load Invalid Username") {
          let sample = ValidatedUser.invalidUsername
          username = sample.username
          email = sample.email
          age = sample.age
          phone = sample.phoneNumber
        }
        
        Button("Load Invalid Email") {
          let sample = ValidatedUser.invalidEmail
          username = sample.username
          email = sample.email
          age = sample.age
          phone = sample.phoneNumber
        }
        
        Button("Load Invalid Age") {
          let sample = ValidatedUser.invalidAge
          username = sample.username
          email = sample.email
          age = sample.age
          phone = sample.phoneNumber
        }
      }
      
      Section("About @RequirementModel") {
        Text("""
        @RequirementModel автоматически генерирует метод validate() \
        на основе валидационных атрибутов (@MinLength, @Email, @InRange, и др.)
        """)
        .font(.caption)
        .foregroundStyle(.secondary)
      }
    }
  }
}

// MARK: - Helper Views

struct ValidationRow<Context: Sendable>: View {
  let requirement: Requirement<Context>
  let context: Context
  var label: String? = nil
  
  var body: some View {
    let result = requirement.evaluate(context)
    
    HStack {
      if let label = label {
        Text(label)
      } else {
        Text("Validation")
      }
      Spacer()
      if result.isConfirmed {
        Image(systemName: "checkmark.circle.fill")
          .foregroundStyle(.green)
      } else {
        Image(systemName: "xmark.circle.fill")
          .foregroundStyle(.red)
      }
    }
    
    if result.isFailed, let reason = result.reason {
      Text(reason.message)
        .font(.caption)
        .foregroundStyle(.orange)
    }
  }
}

// MARK: - Preview

#Preview {
  MacrosDemoView()
}

