# Middleware и логирование

Используйте middleware для логирования, аналитики и отладки требований.

## Обзор

``RequirementMiddleware`` позволяет перехватывать проверку требований и добавлять дополнительную логику до и после оценки. Это полезно для логирования, аналитики, метрик и отладки.

## Протокол RequirementMiddleware

Middleware реализует протокол ``RequirementMiddleware``:

```swift
public protocol RequirementMiddleware: Sendable {
  func beforeEvaluation<Context: Sendable>(
    context: Context,
    requirementName: String?
  )
  
  func afterEvaluation<Context: Sendable>(
    context: Context,
    requirementName: String?,
    result: Evaluation,
    duration: TimeInterval
  )
}
```

## Встроенные Middleware

### LoggingMiddleware

Логирует проверку требований в консоль:

```swift
let loggingMiddleware = LoggingMiddleware(
  level: .verbose,
  prefix: "[Requirement]"
)

let requirement = canTrade
  .with(middleware: loggingMiddleware)

let result = requirement.evaluate(context)
```

Вывод:

```
[Requirement] Evaluating: canTrade
[Requirement] ✅ canTrade (2.34ms)
```

#### Уровни логирования

```swift
public enum LogLevel {
  case verbose  // Всё: до и после проверки
  case info     // Только результаты
  case warning  // Только ошибки (warnings)
  case error    // Только критичные ошибки
}
```

Примеры:

```swift
// Verbose - всё
let verbose = LoggingMiddleware(level: .verbose)

// Info - только результаты
let info = LoggingMiddleware(level: .info)

// Warning - только при ошибках
let warning = LoggingMiddleware(level: .warning)
```

### AnalyticsMiddleware

Отправляет события в систему аналитики:

```swift
let analyticsMiddleware = AnalyticsMiddleware { eventName, properties in
  Analytics.shared.track(eventName, properties: properties)
}

let requirement = canTrade
  .with(middleware: analyticsMiddleware)

let result = requirement.evaluate(context)
```

События отправляются в формате:

```json
{
  "event": "requirement_evaluated",
  "properties": {
    "requirement_name": "canTrade",
    "result": "confirmed",
    "reason_code": "",
    "duration_ms": 2.34
  }
}
```

## Множественные Middleware

Применяйте несколько middleware одновременно:

```swift
let requirement = canTrade
  .with(middlewares: [
    LoggingMiddleware(level: .info, prefix: "[Trade]"),
    AnalyticsMiddleware { event, props in
      Analytics.track(event, properties: props)
    },
    CustomMonitoringMiddleware()
  ])
```

Middleware вызываются в порядке, в котором они переданы.

## Создание собственного Middleware

### Пример: Monitoring Middleware

```swift
struct MonitoringMiddleware: RequirementMiddleware {
  let metricsService: MetricsService
  
  func beforeEvaluation<Context: Sendable>(
    context: Context,
    requirementName: String?
  ) {
    // Инкрементируем счётчик проверок
    metricsService.increment("requirement.evaluations")
  }
  
  func afterEvaluation<Context: Sendable>(
    context: Context,
    requirementName: String?,
    result: Evaluation,
    duration: TimeInterval
  ) {
    // Отправляем метрику длительности
    metricsService.record("requirement.duration", value: duration)
    
    // Отправляем результат
    let status = result.isConfirmed ? "success" : "failure"
    metricsService.increment("requirement.result.\(status)")
    
    // Alert для медленных проверок
    if duration > 0.1 {
      metricsService.alert("Slow requirement: \(requirementName ?? "unknown")")
    }
  }
}
```

### Пример: Debug Middleware

```swift
struct DebugMiddleware: RequirementMiddleware {
  func beforeEvaluation<Context: Sendable>(
    context: Context,
    requirementName: String?
  ) {
    print("🔍 Проверка: \(requirementName ?? "unknown")")
    print("📊 Контекст: \(context)")
  }
  
  func afterEvaluation<Context: Sendable>(
    context: Context,
    requirementName: String?,
    result: Evaluation,
    duration: TimeInterval
  ) {
    let status = result.isConfirmed ? "✅ Успех" : "❌ Отказ"
    let durationMs = String(format: "%.2f", duration * 1000)
    
    print("\(status): \(requirementName ?? "unknown") (\(durationMs)ms)")
    
    if let reason = result.reason {
      print("   Код: \(reason.code)")
      print("   Причина: \(reason.message)")
    }
    print("---")
  }
}
```

### Пример: Rate Limiting Middleware

```swift
actor RateLimitMiddleware: RequirementMiddleware {
  private var evaluationCounts: [String: Int] = [:]
  private let limit: Int
  
  init(limit: Int = 100) {
    self.limit = limit
  }
  
  func beforeEvaluation<Context: Sendable>(
    context: Context,
    requirementName: String?
  ) {
    let name = requirementName ?? "unknown"
    let count = evaluationCounts[name, default: 0]
    
    if count >= limit {
      print("⚠️ Rate limit exceeded for \(name)")
    }
  }
  
  func afterEvaluation<Context: Sendable>(
    context: Context,
    requirementName: String?,
    result: Evaluation,
    duration: TimeInterval
  ) {
    let name = requirementName ?? "unknown"
    evaluationCounts[name, default: 0] += 1
  }
}
```

## Применение Middleware

### К одному требованию

```swift
let requirement = canTrade
  .with(middleware: LoggingMiddleware())
```

### К группе требований

```swift
let middleware = LoggingMiddleware(level: .verbose)

let req1 = requirement1.with(middleware: middleware)
let req2 = requirement2.with(middleware: middleware)
let req3 = requirement3.with(middleware: middleware)
```

### Глобально через обёртку

```swift
struct RequirementFactory {
  static let defaultMiddlewares: [any RequirementMiddleware] = [
    LoggingMiddleware(level: .info),
    AnalyticsMiddleware { event, props in
      Analytics.track(event, properties: props)
    }
  ]
  
  static func create<Context>(
    _ builder: () -> Requirement<Context>
  ) -> Requirement<Context> {
    builder().with(middlewares: defaultMiddlewares)
  }
}

// Использование
let requirement = RequirementFactory.create {
  #all {
    #require(\.user.isLoggedIn)
    #require(\.user.isPremium)
  }
}
```

## Интеграция с os.log

```swift
import os.log

struct OSLogMiddleware: RequirementMiddleware {
  private let logger = Logger(
    subsystem: "com.yourapp.requirements",
    category: "requirements"
  )
  
  func beforeEvaluation<Context: Sendable>(
    context: Context,
    requirementName: String?
  ) {
    logger.debug("Evaluating: \(requirementName ?? "unknown")")
  }
  
  func afterEvaluation<Context: Sendable>(
    context: Context,
    requirementName: String?,
    result: Evaluation,
    duration: TimeInterval
  ) {
    let name = requirementName ?? "unknown"
    
    if result.isConfirmed {
      logger.info("✅ \(name) confirmed in \(duration * 1000, format: .fixed(precision: 2))ms")
    } else {
      logger.warning("❌ \(name) failed: \(result.reason?.message ?? "unknown")")
    }
  }
}
```

## Условное применение Middleware

### По окружению

```swift
let middleware: [any RequirementMiddleware]

#if DEBUG
middleware = [
  LoggingMiddleware(level: .verbose, prefix: "[Debug]"),
  DebugMiddleware()
]
#else
middleware = [
  AnalyticsMiddleware { event, props in
    Analytics.track(event, properties: props)
  }
]
#endif

let requirement = canTrade.with(middlewares: middleware)
```

### По конфигурации

```swift
struct Config {
  static var isLoggingEnabled = true
  static var isAnalyticsEnabled = true
}

var middlewares: [any RequirementMiddleware] = []

if Config.isLoggingEnabled {
  middlewares.append(LoggingMiddleware())
}

if Config.isAnalyticsEnabled {
  middlewares.append(AnalyticsMiddleware { event, props in
    Analytics.track(event, properties: props)
  })
}

let requirement = canTrade.with(middlewares: middlewares)
```

## Best Practices

### 1. Используйте middleware для наблюдаемости

```swift
// ✅ Хорошо - логирование критичных проверок
let paymentCheck = canProcessPayment
  .with(middlewares: [
    LoggingMiddleware(level: .info),
    MonitoringMiddleware(metricsService: metrics)
  ])
```

### 2. Избегайте тяжёлых операций в middleware

```swift
// ❌ Плохо - синхронная запись в БД
struct BadMiddleware: RequirementMiddleware {
  func afterEvaluation(...) {
    database.saveSync(result) // Блокирует выполнение
  }
}

// ✅ Хорошо - асинхронная операция
struct GoodMiddleware: RequirementMiddleware {
  func afterEvaluation(...) {
    Task {
      await database.save(result)
    }
  }
}
```

### 3. Используйте именованные требования с middleware

```swift
// ✅ Хорошо - middleware знает имя
let requirement = Requirement.named("Payment Authorization") {
  // ...
}
.with(middleware: LoggingMiddleware())

// ❌ Плохо - middleware видит "unnamed"
let requirement = #all {
  // ...
}
.with(middleware: LoggingMiddleware())
```

### 4. Группируйте middleware по назначению

```swift
struct ProductionMiddlewares {
  static let monitoring: [any RequirementMiddleware] = [
    MetricsMiddleware(),
    AnalyticsMiddleware { /*...*/ }
  ]
  
  static let debugging: [any RequirementMiddleware] = [
    LoggingMiddleware(level: .verbose),
    DebugMiddleware()
  ]
}
```

## Смотрите также

- <doc:DebuggingAndTracing>
- ``RequirementMiddleware``
- ``LoggingMiddleware``
- ``AnalyticsMiddleware``

