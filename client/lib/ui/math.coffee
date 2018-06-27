UI.registerHelper 'toFixed', (distance, size) -> Number(distance).toFixed(size) if distance?
UI.registerHelper 'getPercent', (a, b) -> a / b * 100