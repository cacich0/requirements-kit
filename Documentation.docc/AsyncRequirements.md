# Асинхронные требования

Работайте с требованиями, которые включают асинхронные операции.

## Обзор

``AsyncRequirement`` позволяет создавать требования, которые включают асинхронные операции такие как API вызовы, запросы к базе данных или другие async операции.

## Создание асинхронного требования

### Базовое использование

```swift
let checkApiAccess = AsyncRequirement<UserContext> { context in
  // Асинхронный вызов
  let hasAccess = try await apiService.checkUserAccess(userId: context.user.id)
  
  return hasAccess 
    ? .confirmed 
    : .failed(reason: Reason(message: "Доступ к API запрещён"))
}
```

### Проверка асинхронного требования

```swift
let result = try await checkApiAccess.evaluate(context)

switch result {
case .confirmed:
  print("✅ Доступ разрешён")
case .failed(let reason):
  print("❌ \(reason.message)")
}
```

## Композиция асинхронных требований

### ALL — последовательная проверка

Проверяет требования по очереди:

```swift
let checkAllAccess = AsyncRequirement.all([
  checkApiAccess,
  checkDatabaseAccess,
  checkFileSystemAccess
])

let result = try await checkAllAccess.evaluate(context)
```

### ALL Concurrent — параллельная проверка

Проверяет все требования одновременно (быстрее):

```swift
let checkAllConcurrent = AsyncRequirement.allConcurrent([
  checkApiAccess,
  checkDatabaseAccess,
  checkFileSystemAccess
])

let result = try await checkAllConcurrent.evaluate(context)
```

### ANY — хотя бы одно требование

Проверяет по очереди, останавливается на первом успешном:

```swift
let checkAnyAccess = AsyncRequirement.any([
  checkAdminAccess,
  checkPremiumAccess,
  checkTrialAccess
])
```

### ANY Concurrent — параллельная проверка с ранним выходом

Запускает все проверки параллельно, останавливается при первом успехе:

```swift
let checkAnyConcurrent = AsyncRequirement.anyConcurrent([
  checkAdminAccess,
  checkPremiumAccess,
  checkTrialAccess
])
```

## Таймауты

Добавьте таймаут к асинхронному требованию:

```swift
@available(iOS 16.0, macOS 13.0, *)
let timedRequirement = AsyncRequirement.withTimeout(
  seconds: 5.0,
  checkApiAccess
)

let result = try await timedRequirement.evaluate(context)
```

Если проверка займёт больше 5 секунд, вернётся ошибка таймаута:

```swift
// .failed(reason: Reason(code: "timeout", message: "Requirement evaluation timed out"))
```

## Конверсия синхронных требований

Преобразуйте синхронное требование в асинхронное:

```swift
let syncRequirement = Requirement<UserContext>.require(\.user.isLoggedIn)

let asyncRequirement = AsyncRequirement.from(syncRequirement)

let result = try await asyncRequirement.evaluate(context)
```

## Причины отказа

Добавляйте понятные причины отказа:

```swift
let checkSubscription = AsyncRequirement<UserContext> { context in
  let isActive = try await subscriptionService.isActive(userId: context.user.id)
  return isActive ? .confirmed : .failed(reason: Reason(message: "Subscription expired"))
}
.because(code: "subscription_inactive", message: "Подписка неактивна")
```

## Обработка ошибок

AsyncRequirement автоматически обрабатывает исключения:

```swift
let checkWithErrorHandling = AsyncRequirement<UserContext> { context in
  do {
    let result = try await dangerousOperation()
    return .confirmed
  } catch {
    return .failed(reason: Reason(
      code: "operation_failed",
      message: "Операция завершилась с ошибкой: \(error.localizedDescription)"
    ))
  }
}
```

## Инверсия асинхронных требований

```swift
let notBanned = AsyncRequirement.not(checkIfBanned)

// Или через метод
let notBanned = checkIfBanned.not()
```

## Примеры из практики

### Проверка доступа к ресурсу

```swift
struct ResourceContext {
  let userId: String
  let resourceId: String
  let action: Action
}

let canAccessResource = AsyncRequirement<ResourceContext> { context in
  // Проверяем права доступа через API
  let permissions = try await permissionsAPI.get(
    userId: context.userId,
    resourceId: context.resourceId
  )
  
  guard permissions.contains(context.action) else {
    return .failed(reason: Reason(
      code: "insufficient_permissions",
      message: "У вас нет прав для действия \(context.action)"
    ))
  }
  
  return .confirmed
}
```

### Проверка rate limit

```swift
let checkRateLimit = AsyncRequirement<UserContext> { context in
  let remainingRequests = try await rateLimiter.getRemainingRequests(
    userId: context.user.id
  )
  
  guard remainingRequests > 0 else {
    return .failed(reason: Reason(
      code: "rate_limit_exceeded",
      message: "Превышен лимит запросов. Попробуйте позже."
    ))
  }
  
  return .confirmed
}
```

### Комплексная проверка

```swift
let completeCheck = AsyncRequirement.allConcurrent([
  checkApiAccess,
  checkRateLimit,
  checkSubscription,
  AsyncRequirement.from(hasValidToken)
])
.because("Не удалось пройти проверку доступа")

@available(iOS 16.0, *)
let timedCompleteCheck = AsyncRequirement.withTimeout(
  seconds: 10.0,
  completeCheck
)
```

## Performance Tips

### 1. Используйте параллельную проверку когда возможно

```swift
// ✅ Быстрее - параллельно
let fast = AsyncRequirement.allConcurrent([req1, req2, req3])

// ❌ Медленнее - последовательно
let slow = AsyncRequirement.all([req1, req2, req3])
```

### 2. Добавляйте таймауты для внешних сервисов

```swift
@available(iOS 16.0, *)
let externalCheck = AsyncRequirement.withTimeout(
  seconds: 5.0,
  checkExternalAPI
)
```

### 3. Кэшируйте результаты где возможно

Для часто вызываемых асинхронных проверок рассмотрите кэширование на уровне сервиса:

```swift
actor CachedPermissionChecker {
  private var cache: [String: Bool] = [:]
  
  func hasPermission(userId: String) async throws -> Bool {
    if let cached = cache[userId] {
      return cached
    }
    
    let result = try await apiService.checkPermission(userId: userId)
    cache[userId] = result
    return result
  }
}
```

## Смотрите также

- <doc:CachingAndPerformance>
- ``AsyncRequirement``
- ``Requirement``

