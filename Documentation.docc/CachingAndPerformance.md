# Кэширование и производительность

Оптимизируйте производительность проверки требований с помощью кэширования и других техник.

## Обзор

RequirementsKit предоставляет несколько способов оптимизации производительности, включая кэширование результатов, профилирование и параллельную проверку асинхронных требований.

## Кэширование результатов

### CachedRequirement

``CachedRequirement`` кэширует результаты проверки для избежания повторных вычислений:

```swift
// Создание кэшированного требования
let cached = requirement.cached()

// Первая проверка — вычисляется
let result1 = cached.evaluate(context) // ~10ms

// Вторая проверка — из кэша
let result2 = cached.evaluate(context) // ~0.01ms
```

> Important: Контекст должен быть `Hashable` для использования кэширования.

### Кэширование с TTL

Установите время жизни кэша (Time To Live):

```swift
// Кэш действителен 60 секунд
let cached = requirement.cached(ttl: 60.0)

let result1 = cached.evaluate(context) // Вычисляется
Thread.sleep(forTimeInterval: 30)
let result2 = cached.evaluate(context) // Из кэша

Thread.sleep(forTimeInterval: 31)
let result3 = cached.evaluate(context) // Вычисляется заново (кэш истёк)
```

### Инвалидация кэша

```swift
let cached = requirement.cached()

// Инвалидировать для конкретного контекста
cached.invalidate(context)

// Очистить весь кэш
cached.invalidateAll()

// Проверить размер кэша
print("Записей в кэше: \(cached.cacheCount)")
```

### WeakCachedRequirement

Для контекстов-объектов используйте слабое кэширование:

```swift
class UserSession: Hashable {
  let id: String
  // ...
}

let weakCached = WeakCachedRequirement(requirement: requirement)

let session = UserSession(id: "123")
let result = weakCached.evaluate(session)

// Когда session будет освобождён из памяти,
// кэш автоматически очистится
```

## Стратегии кэширования

### CacheStrategy

```swift
public enum CacheStrategy {
  case none              // Без кэширования
  case forever           // Бессрочное кэширование
  case ttl(TimeInterval) // С временем жизни
  case untilInvalidated  // До ручной инвалидации
}
```

### Выбор стратегии

```swift
// Для статичных данных
let staticCheck = requirement.cached() // forever

// Для данных с умеренной изменяемостью
let moderateCheck = requirement.cached(ttl: 300.0) // 5 минут

// Для часто изменяемых данных
// Без кэширования - проверять каждый раз
```

## Профилирование производительности

### ProfiledRequirement

Собирайте метрики производительности:

```swift
let profiled = requirement.profiled()

// Выполняем проверки
for i in 0..<1000 {
  let (evaluation, metrics) = profiled.evaluateWithMetrics(context)
  
  if i % 100 == 0 {
    print("""
      Итерация \(i):
      - Текущая: \(metrics.duration * 1000)ms
      - Средняя: \(metrics.averageDuration * 1000)ms
      - Мин/Макс: \(metrics.minDuration * 1000)ms / \(metrics.maxDuration * 1000)ms
      """)
  }
}

// Финальные метрики
if let metrics = profiled.metrics {
  print("""
    Итого:
    - Проверок: \(metrics.evaluationCount)
    - Средняя длительность: \(metrics.averageDuration * 1000)ms
    - Диапазон: \(metrics.minDuration * 1000)ms - \(metrics.maxDuration * 1000)ms
    """)
}
```

### Анализ узких мест

```swift
let requirement1 = slowRequirement.profiled()
let requirement2 = fastRequirement.profiled()

let combined = (requirement1 && requirement2).profiled()

// Выполняем несколько раз
for _ in 0..<100 {
  _ = combined.evaluateWithMetrics(context)
}

// Сравниваем
print("Requirement1: \(requirement1.metrics?.averageDuration ?? 0)s")
print("Requirement2: \(requirement2.metrics?.averageDuration ?? 0)s")
print("Combined: \(combined.metrics?.averageDuration ?? 0)s")
```

## Оптимизация композиции

### Порядок проверок

Располагайте быстрые проверки в начале:

```swift
// ✅ Хорошо - быстрая проверка первой
let optimized = #all {
  #require(\.isLoggedIn)           // Быстро - O(1)
  #require(\.isPremium)            // Быстро - O(1)
  expensiveDatabaseCheck           // Медленно - I/O
  complexCalculationRequirement    // Медленно - CPU
}

// ❌ Плохо - медленные проверки в начале
let notOptimized = #all {
  complexCalculationRequirement    // Выполняется всегда
  expensiveDatabaseCheck           // Выполняется всегда
  #require(\.isLoggedIn)           // Может отсечь рано
}
```

### Short-circuit evaluation

`ALL` останавливается на первой ошибке:

```swift
// Если isLoggedIn == false, остальное не проверяется
let requirement = #all {
  #require(\.isLoggedIn)           // Проверка #1
  expensiveDatabaseCheck           // Пропускается если #1 failed
  veryExpensiveAPICall             // Пропускается если #1 failed
}
```

`ANY` останавливается на первом успехе:

```swift
// Если isAdmin == true, остальное не проверяется
let requirement = #any {
  #require(\.isAdmin)              // Проверка #1
  expensivePremiumCheck            // Пропускается если #1 success
  complexBalanceCalculation        // Пропускается если #1 success
}
```

## Параллельная проверка

### AsyncRequirement с параллелизмом

```swift
// Последовательно (медленно)
let sequential = AsyncRequirement.all([
  checkAPI1,    // 100ms
  checkAPI2,    // 100ms
  checkAPI3     // 100ms
])
// Общее время: ~300ms

// Параллельно (быстро)
let concurrent = AsyncRequirement.allConcurrent([
  checkAPI1,    // 100ms
  checkAPI2,    // 100ms
  checkAPI3     // 100ms
])
// Общее время: ~100ms
```

### Комбинирование стратегий

```swift
// Быстрые синхронные проверки сначала
let syncChecks = #all {
  #require(\.isLoggedIn)
  #require(\.isVerified)
}

// Медленные асинхронные проверки параллельно
let asyncChecks = AsyncRequirement.allConcurrent([
  checkAPI,
  checkDatabase,
  checkExternalService
])

// Проверка
guard syncChecks.evaluate(context).isConfirmed else {
  return .failed(reason: Reason(message: "Sync checks failed"))
}

let result = try await asyncChecks.evaluate(context)
```

## Memory Management

### Освобождение ресурсов

```swift
let profiled = requirement.profiled()

// Используем
for _ in 0..<1000 {
  _ = profiled.evaluateWithMetrics(context)
}

// Очищаем статистику
profiled.reset()
```

### Weak references в кэше

```swift
// Для больших объектов используйте WeakCachedRequirement
class HeavyContext: Hashable {
  let largeData: Data
  // ...
}

let weakCached = WeakCachedRequirement(requirement: requirement)
// Автоматически освобождает память когда контекст больше не нужен
```

## Benchmarking

### Сравнение производительности

```swift
import Foundation

func benchmark(name: String, iterations: Int = 1000, block: () -> Void) {
  let start = Date()
  
  for _ in 0..<iterations {
    block()
  }
  
  let duration = Date().timeIntervalSince(start)
  let average = duration / Double(iterations) * 1000
  
  print("\(name): \(average)ms per iteration")
}

// Сравниваем
benchmark(name: "Without cache") {
  _ = requirement.evaluate(context)
}

let cached = requirement.cached()
benchmark(name: "With cache") {
  _ = cached.evaluate(context)
}
```

Вывод:

```
Without cache: 0.52ms per iteration
With cache: 0.003ms per iteration
```

## Best Practices

### 1. Кэшируйте дорогие операции

```swift
// ✅ Хорошо - кэшируем медленную проверку
let expensiveCheck = Requirement<Context> { context in
  // Сложные вычисления
  Thread.sleep(forTimeInterval: 0.1)
  return .confirmed
}
.cached(ttl: 60.0)

// ❌ Не нужно - простая проверка
let simpleCheck = Requirement<Context>
  .require(\.isLoggedIn)
  .cached() // Избыточно
```

### 2. Выбирайте правильный TTL

```swift
// Пользовательские данные - средний TTL
let userCheck = requirement.cached(ttl: 300.0) // 5 минут

// Конфигурация - долгий TTL
let configCheck = requirement.cached(ttl: 3600.0) // 1 час

// Реалтайм данные - короткий TTL или без кэша
let realtimeCheck = requirement.cached(ttl: 5.0) // 5 секунд
```

### 3. Профилируйте в development

```swift
#if DEBUG
let requirement = baseRequirement.profiled()
#else
let requirement = baseRequirement.cached(ttl: 60.0)
#endif
```

### 4. Инвалидируйте при изменениях

```swift
let cached = requirement.cached()

func updateUser(_ user: User) {
  self.user = user
  
  // Очищаем кэш при изменении данных
  let newContext = createContext()
  cached.invalidate(newContext)
}
```

### 5. Используйте параллелизм для независимых проверок

```swift
// ✅ Хорошо - независимые проверки параллельно
let checks = AsyncRequirement.allConcurrent([
  checkAPI,
  checkDatabase,
  checkFiles
])

// ❌ Плохо - зависимые проверки параллельно
// (результат check2 зависит от check1)
let bad = AsyncRequirement.allConcurrent([
  check1,
  check2ThatNeedsResultOfCheck1 // Гонка!
])
```

## Monitoring производительности

```swift
struct PerformanceMonitor {
  static func monitor(requirement: Requirement<Context>, context: Context) {
    let profiled = requirement.profiled()
    
    Task {
      while true {
        try await Task.sleep(for: .seconds(60))
        
        if let metrics = profiled.metrics {
          if metrics.averageDuration > 0.1 {
            logger.warning("""
              Slow requirement detected:
              - Average: \(metrics.averageDuration * 1000)ms
              - Max: \(metrics.maxDuration * 1000)ms
              - Evaluations: \(metrics.evaluationCount)
              """)
          }
        }
      }
    }
  }
}
```

## Смотрите также

- <doc:AsyncRequirements>
- <doc:DebuggingAndTracing>
- ``CachedRequirement``
- ``ProfiledRequirement``
- ``WeakCachedRequirement``

