# Отладка и трассировка

Узнайте, как отлаживать и профилировать проверку требований.

## Обзор

RequirementsKit предоставляет мощные инструменты для отладки и анализа производительности ваших требований. Вы можете трассировать выполнение, профилировать производительность и использовать middleware для логирования.

## Трассировка требований

### Базовое использование

``TracedRequirement`` позволяет отследить, как и за какое время выполнялось требование:

```swift
let traced = requirement.traced(name: "Main Requirement")

let (evaluation, trace) = traced.evaluateWithTrace(context)

print("Результат: \(evaluation.isConfirmed)")
print("Длительность: \(trace.duration * 1000)ms")
print("Путь: \(trace.path.joined(separator: " → "))")
```

### Анализ результатов трассировки

``RequirementTrace`` содержит подробную информацию о проверке:

```swift
let (_, trace) = traced.evaluateWithTrace(context)

// Путь оценки
print("Путь: \(trace.path)")

// Результат
print("Выполнено: \(trace.evaluation.isConfirmed)")

// Производительность
print("Время выполнения: \(trace.duration)s")
print("Временная метка: \(trace.timestamp)")

// Вложенные трассировки
for child in trace.children {
  print("- \(child.path): \(child.duration)s")
}
```

### Вложенная трассировка

Для композитных требований трассировка включает информацию о вложенных проверках:

```swift
let complexRequirement = Requirement<UserContext>.all {
  Requirement<UserContext>
    .require(\.isLoggedIn)
    .named("Login Check")
  
  Requirement<UserContext>
    .require(\.isPremium)
    .named("Premium Check")
  
  Requirement<UserContext>
    .require(\.balance, greaterThan: 100)
    .named("Balance Check")
}
.traced(name: "Complete Access Check")

let (evaluation, trace) = complexRequirement.evaluateWithTrace(context)

// Анализ вложенных проверок
for (index, child) in trace.children.enumerated() {
  let status = child.evaluation.isConfirmed ? "✅" : "❌"
  print("\(status) Step \(index + 1): \(child.path) - \(child.duration * 1000)ms")
}
```

## Профилирование производительности

### ProfiledRequirement

``ProfiledRequirement`` собирает статистику о времени выполнения:

```swift
let profiled = requirement.profiled()

// Выполняем несколько раз
for i in 0..<100 {
  let (evaluation, metrics) = profiled.evaluateWithMetrics(context)
  
  print("Оценка #\(metrics.evaluationCount)")
  print("- Текущая длительность: \(metrics.duration)s")
  print("- Средняя: \(metrics.averageDuration)s")
  print("- Мин/Макс: \(metrics.minDuration)s / \(metrics.maxDuration)s")
}
```

### Анализ метрик

``PerformanceMetrics`` предоставляет детальную статистику:

```swift
if let metrics = profiled.metrics {
  print("""
    Статистика производительности:
    - Всего оценок: \(metrics.evaluationCount)
    - Средняя длительность: \(metrics.averageDuration * 1000)ms
    - Минимум: \(metrics.minDuration * 1000)ms
    - Максимум: \(metrics.maxDuration * 1000)ms
    """)
}
```

### Сброс статистики

```swift
profiled.reset()
```

## Именованные требования

Присваивайте имена требованиям для лучшей идентификации в логах:

```swift
let authCheck = Requirement.named("Authentication Check") {
  #require(\.user.isLoggedIn)
  #require(\.user.isVerified)
}

let premiumCheck = Requirement.named("Premium Check") {
  #require(\.user.isPremium)
  #require(\.subscription.isActive)
}

let fullCheck = Requirement.named("Full Access Check") {
  authCheck
  premiumCheck
}
```

## Метод .logged()

Добавьте логирование к конкретным требованиям:

```swift
let requirement = Requirement<UserContext>
  .require(\.user.isLoggedIn)
  .logged("Login Check")
  .and(\.user.isPremium)
  .logged("Premium Check")
  .and(\.balance, greaterThan: 100)
  .logged("Balance Check")

// При проверке будут выводиться логи
let result = requirement.evaluate(context)
```

## Debug-режим

Условная компиляция для детального логирования:

```swift
#if DEBUG
let requirement = Requirement<UserContext>
  .require(\.isLoggedIn)
  .logged("Auth")
  .with(middleware: LoggingMiddleware(level: .verbose))
#else
let requirement = Requirement<UserContext>
  .require(\.isLoggedIn)
#endif
```

## Визуализация выполнения

### Простая визуализация

```swift
func printTrace(_ trace: RequirementTrace, indent: String = "") {
  let status = trace.evaluation.isConfirmed ? "✅" : "❌"
  let duration = String(format: "%.2f", trace.duration * 1000)
  print("\(indent)\(status) \(trace.path.last ?? "Unknown") (\(duration)ms)")
  
  if let reason = trace.evaluation.reason {
    print("\(indent)   Причина: \(reason.message)")
  }
  
  for child in trace.children {
    printTrace(child, indent: indent + "  ")
  }
}

let (_, trace) = requirement.traced(name: "Main").evaluateWithTrace(context)
printTrace(trace)
```

Вывод:

```
✅ Main (15.23ms)
  ✅ Login Check (0.05ms)
  ❌ Premium Check (0.03ms)
     Причина: Premium subscription required
  ✅ Balance Check (0.02ms)
```

## Детальный анализ ошибок

### Получение всех причин отказа

```swift
let result = requirement.evaluate(context)

if case .failed = result {
  let failures = result.allFailures
  
  print("Найдено \(failures.count) ошибок:")
  for (index, failure) in failures.enumerated() {
    print("\(index + 1). [\(failure.code)] \(failure.message)")
  }
}
```

### Анализ конкретной причины

```swift
if case .failed(let reason) = result {
  print("Код ошибки: \(reason.code)")
  print("Сообщение: \(reason.message)")
  
  // Логирование для аналитики
  analytics.track("requirement_failed", properties: [
    "code": reason.code,
    "message": reason.message,
    "context": String(describing: context)
  ])
}
```

## Best Practices

### 1. Используйте именованные требования в production

```swift
// ✅ Хорошо
let requirement = Requirement.named("Trading Access") {
  // ...
}
.traced(name: "Trading")

// ❌ Плохо
let requirement = #all {
  // ... без имени
}
```

### 2. Профилируйте критичные требования

```swift
// Для часто вызываемых требований
let criticalCheck = requirement.profiled()

// Периодически проверяйте метрики
Task {
  try await Task.sleep(for: .seconds(60))
  if let metrics = criticalCheck.metrics {
    if metrics.averageDuration > 0.1 {
      logger.warning("Slow requirement: \(metrics.averageDuration)s")
    }
  }
}
```

### 3. Используйте условную компиляцию

```swift
#if DEBUG
let requirement = baseRequirement
  .logged("Debug Check")
  .with(middleware: LoggingMiddleware(level: .verbose))
#else
let requirement = baseRequirement
#endif
```

### 4. Структурируйте трассировку

```swift
let requirement = Requirement.named("Main Flow") {
  Requirement.named("Auth") {
    // auth checks
  }
  
  Requirement.named("Permissions") {
    // permission checks
  }
  
  Requirement.named("Resources") {
    // resource checks
  }
}
```

## Интеграция с системой логирования

```swift
import os.log

extension RequirementTrace {
  func log(logger: Logger = Logger()) {
    let status = evaluation.isConfirmed ? "✅" : "❌"
    let duration = String(format: "%.2f", self.duration * 1000)
    
    logger.info("\(status) \(self.path.joined(separator: " → ")) (\(duration)ms)")
    
    if let reason = evaluation.reason {
      logger.warning("Reason: \(reason.message)")
    }
    
    for child in children {
      child.log(logger: logger)
    }
  }
}

// Использование
let (_, trace) = requirement.traced(name: "Check").evaluateWithTrace(context)
trace.log()
```

## Смотрите также

- <doc:MiddlewareAndLogging>
- ``RequirementTrace``
- ``ProfiledRequirement``
- ``TracedRequirement``
- ``PerformanceMetrics``

