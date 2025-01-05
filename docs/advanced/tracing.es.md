# Rastreo

El rastreo (Tracing) es una herramienta poderosa para monitorear y depurar sistemas distribuidos. La API de rastreo (Tracing) de Vapor permite a los desarrolladores rastrear facilmente los ciclos de vida de las solicitudes, propagar metadatos e integrarse con backends populares como OpenTelemetry.

La API de rastreo (Tracing) de Vapor se basa en [swift-distributed-tracing](https://github.com/apple/swift-distributed-tracing), esto quiere decir que es compatible con todas las [implementaciones de backend ](https://github.com/apple/swift-distributed-tracing/blob/main/README.md#tracing-backends) de swift-distributed-tracing.

Si no estas familiarizado con tracing y spans en Swift, revise la [documentación de OpenTelemetry Trace](https://opentelemetry.io/docs/concepts/signals/traces/) y la [documentación de swift-distributed-tracing](https://swiftpackageindex.com/apple/swift-distributed-tracing/main/documentation/tracing).

## TracingMiddleware

Para crear automaticamente un span completamente anotado para cada solicitud, agrega el `TracingMiddleware` a tu aplicación.

```swift
app.middleware.use(TracingMiddleware())
```

Para obtener mediciones precisas de los spans y asegurarte de que los identificadores de rastreo se pasen correctamente a otros sercvicios, añade este middleware antes que otros middlewares.

## Añadiendo Spans

Cuando se añaden spans a los manejadores de rutas, es ideal que estén asociados con el span de solicitud de nivel superior. Esto se conoce como 'propagación de spans' y se puede manejar de dos maneras diferentes: automática o manual

### Propagación Automática

Vapor tiene soporte para propagar automáticamente spans entre middleware y callbacks de rutas. Para hacerlo, establece la propiedad `Application.traceAutoPropagation` en true durante la configuración.

```swift
app.traceAutoPropagation = true
```

!!! nota
     Habilitar la auto-propagación puede degradar el rendimiento en APIs de alto rendimiento con necesidades mínimas de rastreo, ya que los metadatos del span de solicitud deben restaurarse para cada manejador de rutas, independientemente de si se crean spans o no.


Entonces, los spans pueden crearse en el cierre de la ruta utilizando la sintaxis ordinaria de rastreo distribuido.

```swift
app.get("fetchAndProcess") { req in
    let result = try await fetch()
    return try await withSpan("getNameParameter") { _ in
        try await process(result)
    }
}
```

### Propagación Manual 

Para evitar las implicaciones de rendimiento de la propagación automática, puedes restaurar manualmente los metadatos del span donde sea necesario. `TracingMiddleware` establece automáticamente una propiedad `Request.serviceContext` que puede usarse directamente en el parámetro `context` de `withSpan`.

```swift
app.get("fetchAndProcess") { req in
    let result = try await fetch()
    return try await withSpan("getNameParameter", context: req.serviceContext) { _ in
        try await process(result)
    }
}
```

Para restaurar los metadatos del span sin crear un span, usa `ServiceContext.withValue`. Esto es valioso si sabes que las bibliotecas asíncronas posteriores emiten sus propios spans de rastreo, y estos deben estar anidados debajo del span de solicitud principal.


```swift
app.get("fetchAndProcess") { req in
    try await ServiceContext.withValue(req.serviceContext) {
        try await fetch()
        return try await process(result)
    }
}
```

## Consideraciones de NIO 

Debido a que `swift-distributed-tracing` usa [`propiedades TaskLocal`](https://developer.apple.com/documentation/swift/tasklocal) para propagar, debes restaurar manualmente el contexto cada vez que cruces los límites de `NIO EventLoopFuture` para asegurar que los spans estén vinculados correctamente. **Esto es necesario independientemente de si la propagación automática está habilitada**.

```swift
app.get("fetchAndProcessNIO") { req in
    withSpan("fetch", context: req.serviceContext) { span in
        fetchSomething().map { result in
            withSpan("process", context: span.context) { _ in
                process(result)
            }
        }
    }
}
```
