import Foundation

// MARK: - Product Model

/// Модель продукта для демонстрации e-commerce требований
struct Product: Sendable, Hashable, Identifiable {
  let id: UUID
  var name: String
  var price: Double
  var stockQuantity: Int
  var category: ProductCategory
  var isAvailable: Bool
  var requiresSubscription: Bool
  var minimumAge: Int?
  
  static var sample: Product {
    Product(
      id: UUID(),
      name: "Premium Widget",
      price: 99.99,
      stockQuantity: 50,
      category: .electronics,
      isAvailable: true,
      requiresSubscription: false,
      minimumAge: nil
    )
  }
  
  static var premiumProduct: Product {
    Product(
      id: UUID(),
      name: "Enterprise Solution",
      price: 999.99,
      stockQuantity: 10,
      category: .software,
      isAvailable: true,
      requiresSubscription: true,
      minimumAge: nil
    )
  }
  
  static var ageRestrictedProduct: Product {
    Product(
      id: UUID(),
      name: "Age-Restricted Item",
      price: 49.99,
      stockQuantity: 100,
      category: .other,
      isAvailable: true,
      requiresSubscription: false,
      minimumAge: 18
    )
  }
}

// MARK: - Product Category

enum ProductCategory: String, Sendable, Hashable, CaseIterable {
  case electronics = "Electronics"
  case software = "Software"
  case services = "Services"
  case other = "Other"
  
  var displayName: String { rawValue }
}

// MARK: - Computed Properties

extension Product {
  var isInStock: Bool {
    stockQuantity > 0
  }
  
  var hasAgeRestriction: Bool {
    minimumAge != nil
  }
}

