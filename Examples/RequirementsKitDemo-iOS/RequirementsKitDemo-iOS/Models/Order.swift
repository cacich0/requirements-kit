import Foundation

// MARK: - Order Model

/// Модель заказа для демонстрации checkout требований
struct Order: Sendable, Hashable, Identifiable {
  let id: UUID
  var items: [OrderItem]
  var shippingAddress: String
  var billingAddress: String
  var promoCode: String?
  var paymentMethod: PaymentMethod
  
  static var sample: Order {
    Order(
      id: UUID(),
      items: [
        OrderItem(product: .sample, quantity: 2),
        OrderItem(product: .premiumProduct, quantity: 1)
      ],
      shippingAddress: "123 Main St, City, Country",
      billingAddress: "123 Main St, City, Country",
      promoCode: nil,
      paymentMethod: .creditCard
    )
  }
  
  static var empty: Order {
    Order(
      id: UUID(),
      items: [],
      shippingAddress: "",
      billingAddress: "",
      promoCode: nil,
      paymentMethod: .creditCard
    )
  }
}

// MARK: - Order Item

struct OrderItem: Sendable, Hashable, Identifiable {
  var id: UUID { product.id }
  let product: Product
  var quantity: Int
  
  var totalPrice: Double {
    product.price * Double(quantity)
  }
}

// MARK: - Payment Method

enum PaymentMethod: String, Sendable, Hashable, CaseIterable {
  case creditCard = "Credit Card"
  case debitCard = "Debit Card"
  case bankTransfer = "Bank Transfer"
  case crypto = "Cryptocurrency"
  case applePay = "Apple Pay"
  
  var displayName: String { rawValue }
  
  var requiresVerification: Bool {
    switch self {
    case .crypto, .bankTransfer:
      return true
    case .creditCard, .debitCard, .applePay:
      return false
    }
  }
}

// MARK: - Computed Properties

extension Order {
  var totalAmount: Double {
    items.reduce(0) { $0 + $1.totalPrice }
  }
  
  var itemCount: Int {
    items.reduce(0) { $0 + $1.quantity }
  }
  
  var isEmpty: Bool {
    items.isEmpty
  }
  
  var hasValidShippingAddress: Bool {
    !shippingAddress.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
  }
  
  var hasValidBillingAddress: Bool {
    !billingAddress.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
  }
  
  var hasPromoCode: Bool {
    promoCode != nil && !promoCode!.isEmpty
  }
  
  var requiresKYC: Bool {
    paymentMethod.requiresVerification || totalAmount > 10000
  }
}

// MARK: - Trading Context

/// Контекст для торговых операций
struct TradingContext: Sendable, Hashable {
  var user: User
  var tradeAmount: Double
  var tradeType: TradeType
  var asset: String
  var useMargin: Bool
  
  var remainingDailyLimit: Double {
    user.availableDailyLimit
  }
  
  var hasEnoughBalance: Bool {
    user.balance >= tradeAmount
  }
  
  var exceedsDailyLimit: Bool {
    tradeAmount > remainingDailyLimit
  }
  
  static var sample: TradingContext {
    TradingContext(
      user: .regularUser,
      tradeAmount: 500,
      tradeType: .buy,
      asset: "BTC",
      useMargin: false
    )
  }
}

enum TradeType: String, Sendable, Hashable, CaseIterable {
  case buy = "Buy"
  case sell = "Sell"
  case swap = "Swap"
  
  var displayName: String { rawValue }
}

// MARK: - Form Context

/// Контекст для валидации форм
struct FormContext: Sendable, Hashable {
  var email: String
  var username: String
  var password: String
  var confirmPassword: String
  var phone: String
  var age: Int
  var acceptedTerms: Bool
  
  static var empty: FormContext {
    FormContext(
      email: "",
      username: "",
      password: "",
      confirmPassword: "",
      phone: "",
      age: 0,
      acceptedTerms: false
    )
  }
  
  static var sample: FormContext {
    FormContext(
      email: "user@example.com",
      username: "john_doe",
      password: "SecurePass123!",
      confirmPassword: "SecurePass123!",
      phone: "+1234567890",
      age: 25,
      acceptedTerms: true
    )
  }
}

