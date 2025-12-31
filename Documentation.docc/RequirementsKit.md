# ``RequirementsKit``

Декларативное описание бизнес-требований и правил доступа в Swift-приложениях.

## Обзор

RequirementsKit — это современная Swift-библиотека, которая позволяет описывать сложную бизнес-логику в виде читаемых, переиспользуемых и композируемых правил без бесконечных цепочек `if/else`.

### Основные преимущества

- **Декларативный синтаксис**: макросы `#require`, `#all`, `#any` для читаемого кода
- **Мощная композиция**: ALL, ANY, NOT, XOR, WHEN/UNLESS, Fallback
- **KeyPath-операторы**: сравнения через KeyPath (`greaterThan:`, `equals:`, и т.д.)
- **Понятные причины отказа**: явное описание с помощью `.because()`
- **Асинхронность**: полная поддержка async/await и параллельных проверок
- **Отладка**: трассировка, профилирование, middleware для логирования
- **UI интеграция**: SwiftUI, Combine, Property Wrappers

### Быстрый пример

```swift
import RequirementsKit

struct TradingContext {
  let user: User
  let balance: Double
}

let canTrade = #all {
  #require(\.user.isLoggedIn)
    .because("Требуется авторизация")
  
  #any {
    #require(\.user.isAdmin)
    #require(\.balance, greaterThan: 100)
  }
}

let result = canTrade.evaluate(context)
```

## Темы

### Начало работы

- <doc:GettingStarted>
- <doc:ComposingRequirements>
- <doc:HandlingResults>

### Основные концепции

- ``Requirement``
- ``Evaluation``
- ``Reason``
- ``AsyncRequirement``

### Композиция

- <doc:LogicalComposition>
- <doc:ConditionalRequirements>
- <doc:FallbackPatterns>

### Производительность

- <doc:CachingAndPerformance>
- <doc:AsyncRequirements>

### Отладка и трассировка

- <doc:DebuggingAndTracing>
- <doc:MiddlewareAndLogging>

### Интеграция с UI

- <doc:SwiftUIIntegration>
- <doc:CombineIntegration>
- ``Eligible``
- ``Eligibility``

### Валидация данных

- <doc:DataValidation>

### Продвинутые паттерны

- <doc:AdvancedPatterns>
- <doc:BestPractices>

## Смотрите также

- [Репозиторий на GitHub](https://github.com/cacich0/requirements-kit)
- [Примеры использования](https://github.com/cacich0/requirements-kit/tree/main/Examples)

