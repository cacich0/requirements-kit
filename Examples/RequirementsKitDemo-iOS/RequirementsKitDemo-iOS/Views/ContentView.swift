import SwiftUI

#if os(iOS)
import UIKit
#endif

/// Главный экран с навигацией между демонстрациями
struct ContentView: View {
  var body: some View {
    TabView {
      AuthDemoView()
        .tabItem {
          Label("Auth", systemImage: "person.badge.key")
        }
      
      TradingDemoView()
        .tabItem {
          Label("Trading", systemImage: "chart.line.uptrend.xyaxis")
        }
      
      SubscriptionDemoView()
        .tabItem {
          Label("Subscription", systemImage: "crown")
        }
      
      ValidationDemoView()
        .tabItem {
          Label("Validation", systemImage: "checkmark.shield")
        }
    }
    #if os(macOS)
    .frame(minWidth: 800, minHeight: 600)
    #endif
  }
}

// MARK: - Shared Components

/// Компонент для отображения результата требования
struct RequirementResultView: View {
  let title: String
  let isConfirmed: Bool
  let reason: String?
  
  var body: some View {
    HStack(spacing: 12) {
      Image(systemName: isConfirmed ? "checkmark.circle.fill" : "xmark.circle.fill")
        .foregroundStyle(isConfirmed ? .green : .red)
        .font(.title2)
      
      VStack(alignment: .leading, spacing: 2) {
        Text(title)
          .font(.headline)
        
        if let reason = reason {
          Text(reason)
            .font(.caption)
            .foregroundStyle(.secondary)
        }
      }
      
      Spacer()
    }
    .padding(.vertical, 4)
  }
}

/// Секция с заголовком для демо
struct DemoSection<Content: View>: View {
  let title: String
  let description: String
  @ViewBuilder let content: () -> Content
  
  var body: some View {
    VStack(alignment: .leading, spacing: 12) {
      VStack(alignment: .leading, spacing: 4) {
        Text(title)
          .font(.title2)
          .fontWeight(.semibold)
        
        Text(description)
          .font(.subheadline)
          .foregroundStyle(.secondary)
      }
      
      content()
    }
    .padding()
    .background {
      RoundedRectangle(cornerRadius: 12)
        .fill(.background)
        .shadow(color: .black.opacity(0.1), radius: 4, y: 2)
    }
  }
}

/// Заголовок категории
struct CategoryHeader: View {
  let title: String
  let systemImage: String
  
  var body: some View {
    HStack {
      Image(systemName: systemImage)
        .font(.title)
        .foregroundStyle(.blue)
      
      Text(title)
        .font(.largeTitle)
        .fontWeight(.bold)
      
      Spacer()
    }
    .padding(.bottom, 8)
  }
}

/// Карточка с информацией о коде
struct CodeExampleCard: View {
  let code: String
  
  var body: some View {
    VStack(alignment: .leading) {
      Text("Code Example")
        .font(.caption)
        .foregroundStyle(.secondary)
      
      ScrollView(.horizontal, showsIndicators: false) {
        Text(code)
          .font(.system(.caption, design: .monospaced))
          .padding(8)
      }
      .background {
        RoundedRectangle(cornerRadius: 8)
          .fill(Color.gray.opacity(0.15))
      }
    }
  }
}

#Preview {
  ContentView()
}

