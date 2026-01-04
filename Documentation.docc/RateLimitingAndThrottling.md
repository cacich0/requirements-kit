# Rate Limiting, Throttling и Debounce

Контролируйте частоту выполнения требований с помощью Rate Limiting, Throttling и Debounce.

## Обзор

RequirementsKit предоставляет три механизма для контроля частоты вызовов требований:

- **Rate Limiting** - ограничивает количество вызовов за определенный период времени
- **Throttling** - гарантирует минимальный интервал между вызовами
- **Debounce** - откладывает выполнение до тех пор, пока не пройдет интервал без новых вызовов

Все механизмы поддерживают как синхронные (`Requirement`), так и асинхронные (`AsyncRequirement`) требования.

## Rate Limiting

Rate Limiting ограничивает количество вызовов требования за определенный период времени.

### Базовое использование

```swift
let apiRequirement = AsyncRequirement<User> { user in
    // Вызов API
    let response = try await api.fetchUserData(user.id)
    return response.isValid ? .confirmed : .failed(reason: Reason(message: "Invalid data"))
}
.rateLimit(
    maxCalls: 10,
    timeWindow: 60 // Максимум 10 вызовов в минуту
)

// Использование
do {
    let result = try await apiRequirement.evaluate(currentUser)
    print("Result:", result)
} catch {
    print("Error:", error)
}
```

### Скользящее окно (Sliding Window)

Rate limiting использует алгоритм скользящего окна. Это означает, что ограничение применяется к последним N секундам, а не к фиксированным временным интервалам.

```swift
// Пример: максимум 3 вызова за 5 секунд
let requirement = Requirement<String> { _ in .confirmed }
    .rateLimit(maxCalls: 3, timeWindow: 5.0)

// t=0s: вызов 1 ✅
// t=1s: вызов 2 ✅
// t=2s: вызов 3 ✅
// t=3s: вызов 4 ❌ (превышен лимит)
// t=6s: вызов 5 ✅ (вызов 1 уже за окном)
```

### Поведение при превышении лимита

Вы можете настроить, что происходит при превышении лимита:

```swift
// 1. Вернуть .failed (по умолчанию)
let requirement1 = apiRequirement.rateLimit(
    maxCalls: 10,
    timeWindow: 60,
    behavior: .returnFailed(Reason(
        code: "rate_limit_exceeded",
        message: "Too many requests. Try again later."
    ))
)

// 2. Вернуть закэшированный результат
let requirement2 = apiRequirement.rateLimit(
    maxCalls: 10,
    timeWindow: 60,
    behavior: .returnCached
)

// 3. Пропустить проверку и вернуть .confirmed
let requirement3 = apiRequirement.rateLimit(
    maxCalls: 10,
    timeWindow: 60,
    behavior: .skip
)
```

### Управление состоянием

```swift
let rateLimited = requirement.rateLimit(maxCalls: 5, timeWindow: 60)

// Проверить текущее количество вызовов
let count = rateLimited.currentCallCount
print("Calls in current window:", count)

// Сбросить счетчики
rateLimited.reset()
```

## Throttling

Throttling гарантирует минимальный интервал между вызовами требования.

### Базовое использование

```swift
let validationRequirement = Requirement<String> { text in
    // Дорогая валидация
    let isValid = expensiveValidation(text)
    return isValid ? .confirmed : .failed(reason: Reason(message: "Invalid"))
}
.throttle(
    interval: 0.5 // Не чаще раза в 0.5 секунд
)

// Использование
let result1 = validationRequirement.evaluate("text1") // ✅ Выполнится
let result2 = validationRequirement.evaluate("text2") // ❌ Слишком рано
```

### Отличие от Rate Limiting

- **Rate Limiting**: "Не более N вызовов за T секунд"
- **Throttling**: "Минимум T секунд между вызовами"

```swift
// Rate Limiting: 3 вызова за 10 секунд
// Можно вызвать 3 раза подряд, затем ждать 10 секунд
let rateLimited = requirement.rateLimit(maxCalls: 3, timeWindow: 10)

// Throttling: 1 вызов каждые 3 секунды
// Между каждым вызовом нужно ждать 3 секунды
let throttled = requirement.throttle(interval: 3)
```

### Поведение при throttling

```swift
// 1. Вернуть закэшированный результат (по умолчанию)
let requirement1 = validation.throttle(
    interval: 1.0,
    behavior: .returnCached
)

// 2. Вернуть .failed
let requirement2 = validation.throttle(
    interval: 1.0,
    behavior: .returnFailed(Reason(message: "Too frequent"))
)

// 3. Пропустить и вернуть .confirmed
let requirement3 = validation.throttle(
    interval: 1.0,
    behavior: .skip
)
```

### Проверка состояния

```swift
let throttled = requirement.throttle(interval: 2.0)

// Проверить время до следующего доступного вызова
let timeRemaining = throttled.timeUntilNextCall
print("Wait \(timeRemaining) seconds")

// Сбросить throttling
throttled.reset()
```

## Debounce

Debounce откладывает выполнение требования до тех пор, пока не пройдет указанный интервал без новых вызовов.

### Базовое использование для поиска

```swift
let searchRequirement = AsyncRequirement<SearchQuery> { query in
    // Поиск по API
    let results = try await api.search(query.text)
    return results.isEmpty ? .failed(reason: Reason(message: "No results")) : .confirmed
}
.debounce(delay: 0.3) // Подождать 300ms после последнего ввода

// Использование
@available(macOS 13.0, iOS 16.0, *)
func performSearch(_ query: String) async {
    do {
        let result = try await searchRequirement.evaluate(SearchQuery(text: query))
        print("Search result:", result)
    } catch {
        print("Search error:", error)
    }
}
```

### Синхронный Debounce

Для синхронных требований debounce работает асинхронно через callback:

```swift
let validation = Requirement<String> { text in
    expensiveValidation(text)
}
.debounce(delay: 0.5)

// Использование с callback
validation.evaluate("user input") { result in
    print("Validation result:", result)
}
```

### Поведение Debounce

```swift
// 1. Отменить предыдущий вызов (по умолчанию)
let debounced1 = search.debounce(
    delay: 0.3,
    behavior: .cancelPrevious
)

// 2. Игнорировать новые вызовы, если есть ожидающий
let debounced2 = search.debounce(
    delay: 0.3,
    behavior: .ignoreNew
)
```

### Управление Debounce

```swift
let debounced = requirement.debounce(delay: 0.5)

// Проверить, есть ли ожидающий вызов
if debounced.isPending {
    print("Debounce is pending")
}

// Отменить ожидающий вызов
debounced.cancel()
```

## Практические примеры

### Пример 1: API с Rate Limiting

```swift
struct User: Sendable {
    let id: String
    let name: String
}

let userValidation = AsyncRequirement<User> { user in
    // API с лимитом 100 запросов в минуту
    let isValid = try await validateUserWithAPI(user.id)
    return isValid ? .confirmed : .failed(reason: Reason(message: "Invalid user"))
}
.rateLimit(
    maxCalls: 100,
    timeWindow: 60,
    behavior: .returnFailed(Reason(
        code: "api_rate_limit",
        message: "API rate limit exceeded. Please wait."
    ))
)

// Использование
do {
    let result = try await userValidation.evaluate(currentUser)
    if result.isConfirmed {
        print("User is valid")
    }
} catch {
    print("Validation error:", error)
}
```

### Пример 2: Поиск в реальном времени с Debounce

```swift
@available(macOS 13.0, iOS 16.0, *)
class SearchViewModel: ObservableObject {
    @Published var searchText: String = ""
    @Published var results: [SearchResult] = []
    
    private let searchRequirement = AsyncRequirement<String> { query in
        let results = try await APIClient.search(query: query)
        return results.isEmpty ? .failed(reason: Reason(message: "No results")) : .confirmed
    }
    .debounce(delay: 0.3)
    
    func search(_ text: String) async {
        guard !text.isEmpty else {
            results = []
            return
        }
        
        do {
            let result = try await searchRequirement.evaluate(text)
            if result.isConfirmed {
                // Обновить результаты
            }
        } catch {
            print("Search error:", error)
        }
    }
}
```

### Пример 3: Валидация формы с Throttling

```swift
let formValidation = Requirement<FormData> { data in
    // Дорогая валидация (проверка в базе данных)
    let isUnique = checkUsernameUniqueness(data.username)
    return isUnique ? .confirmed : .failed(reason: Reason(message: "Username taken"))
}
.throttle(
    interval: 1.0,
    behavior: .returnCached
)

// Использование в SwiftUI
struct RegistrationForm: View {
    @State private var username: String = ""
    @State private var isValid: Bool = false
    
    var body: some View {
        TextField("Username", text: $username)
            .onChange(of: username) { newValue in
                let result = formValidation.evaluate(FormData(username: newValue))
                isValid = result.isConfirmed
            }
    }
}
```

### Пример 4: Комбинирование механизмов

```swift
let apiRequirement = AsyncRequirement<Request> { request in
    let response = try await api.execute(request)
    return response.success ? .confirmed : .failed(reason: Reason(message: "API error"))
}
.throttle(interval: 0.5)        // Минимум 0.5 сек между вызовами
.debounce(delay: 0.2)            // Отложить на 200мс
.rateLimit(                      // Максимум 50 запросов в минуту
    maxCalls: 50,
    timeWindow: 60,
    behavior: .returnCached
)
```

### Пример 5: Использование внутри композиции

**Новое:** Rate Limiting и Throttling можно применять к отдельным требованиям внутри композиции!

```swift
// Синхронный пример
let requirement = Requirement<User>.all {
    // Первое требование с rate limiting
    Requirement<User> { user in
        validateWithAPI(user.email)
    }
    .rateLimit(maxCalls: 10, timeWindow: 60)
    
    // Второе требование с throttling
    Requirement<User> { user in
        checkDatabaseAvailability(user.id)
    }
    .throttle(interval: 1.0, behavior: .returnCached)
    
    // Обычное требование без ограничений
    Requirement<User>.require(\.isActive)
}

// Асинхронный пример
let asyncRequirement = AsyncRequirement<User>.all {
    AsyncRequirement<User> { user in
        try await api.validateEmail(user.email)
    }
    .rateLimit(maxCalls: 5, timeWindow: 60)
    
    AsyncRequirement<User> { user in
        try await checkUserPermissions(user.id)
    }
    .throttle(interval: 2.0)
}

// С debounce (только для async, iOS 16+)
@available(macOS 13.0, iOS 16.0, *)
let searchRequirement = AsyncRequirement<SearchQuery>.all {
    AsyncRequirement<SearchQuery> { query in
        try await validateQuery(query.text)
    }
    .debounce(delay: 0.3)
    
    AsyncRequirement<SearchQuery> { query in
        try await checkQueryLength(query.text)
    }
}
```

**Важные замечания:**
- Rate limiting и throttling на **отдельных требованиях** применяются независимо
- Rate limiting и throttling **на результате композиции** применяется ко всей композиции
- Debounce для синхронных требований не поддерживается внутри композиции

## Диаграмма поведения

### Rate Limiting

```
Time:    0s    1s    2s    3s    4s    5s    6s
Calls:   ✅    ✅    ✅    ❌    ❌    ✅    ✅
         │     │     │                 │     │
         └─────┴─────┴─────────────────┘     │
         Window: 3 calls in 5s               │
                                             │
                                First call expired
```

### Throttling

```
Time:    0s    0.5s  1s    1.5s  2s    2.5s  3s
Calls:   ✅    ❌    ✅    ❌    ✅    ❌    ✅
         │           │           │           │
         └───────────┴───────────┴───────────┘
         Interval: 1s between calls
```

### Debounce

```
Input:   A     B     C     D          (delay: 0.5s)
Time:    0s    0.1s  0.2s  0.3s  0.8s
Action:  ─     ─     ─     ─     ✅ Execute D
         │     │     │     │
         cancelled   │     │
               cancelled   │
                     cancelled

Only last input is executed after 0.5s of inactivity
```

## Сравнение механизмов

| Механизм | Когда использовать | Пример |
|----------|-------------------|--------|
| **Rate Limiting** | Ограничение общего количества запросов | API с лимитом 1000 запросов/час |
| **Throttling** | Равномерное распределение нагрузки | Автосохранение каждые 5 секунд |
| **Debounce** | Ожидание завершения пользовательского ввода | Поиск при вводе в текстовое поле |

## Производительность и Memory Management

- **Rate Limiting** автоматически очищает устаревшие timestamps для экономии памяти
- **Throttling** хранит только время последнего вызова
- **Debounce** отменяет предыдущие задачи для предотвращения утечек памяти
- Все механизмы thread-safe и поддерживают Swift Concurrency

## См. также

- ``CachedRequirement`` - Кэширование результатов требований
- ``AsyncRequirement`` - Асинхронные требования
- ``RequirementMiddleware`` - Middleware для требований

