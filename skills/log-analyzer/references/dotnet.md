# Referencia: .NET / C#

## Alcance

Runtimes: .NET 6/7/8/9, .NET Framework 4.x. Frameworks: ASP.NET Core (Web API, MVC, Minimal APIs), Worker Services, Console Apps, gRPC, SignalR, Blazor. Logging: `Microsoft.Extensions.Logging` (MEL), Serilog, NLog, log4net. Data: Entity Framework Core, Dapper, ADO.NET. Otros: MediatR, AutoMapper, Polly, Azure/AWS SDK, MassTransit/RabbitMQ.

Formatos:
- **MEL**: `info: Logger[EventId]` seguido de línea indentada con el mensaje; `fail:` para excepciones.
- **Serilog**: `[timestamp] [LVL] [RequestId: ...] mensaje`.
- **NLog**: `timestamp|LEVEL|logger|mensaje|contexto`.
- **log4net**: `timestamp [LEVEL] logger - mensaje`.
- JSON estructurado (Serilog/MEL JsonConsole) con campos `Timestamp`, `Level`, `SourceContext`, `RequestId`, `Exception`.

Niveles: Trace/VRB/TRACE/TRACE < Debug/DBG/DEBUG/DEBUG < Information/INF/INFO/INFO < Warning/WRN/WARN/WARN < Error/ERR/ERROR/ERROR < Critical/FTL/FATAL/FATAL (columnas: MEL/Serilog/NLog/log4net).

## Preguntar antes de interpretar

| Situación | Pregunta |
|---|---|
| Framework de logging no evidente | ¿Serilog, NLog, MEL nativo u otro? |
| Sin timestamps completos | ¿Tienes el log completo con timestamps? |
| Entorno no declarado | ¿DEV, QA, STAGING o PROD? |
| Stack trace truncado | ¿Puedes dar el stack trace completo con inner exceptions? |
| Log mezcla instancias/pods | ¿Es una sola instancia o está agregado de varias? |
| EF sin contexto de query | ¿Tienes la query EF o el modelo de datos involucrado? |
| Config externa mencionada | ¿Puedes compartir la sección relevante de appsettings.json (sin secretos)? |
| Versión de .NET no clara | ¿.NET 6/7/8, Framework 4.x? |

## Datos sensibles específicos

Connection strings (`Server=...;User Id=...;Password=...`); JWT/Bearer tokens; SQL queries con datos reales (`EnableSensitiveDataLogging()` activo); PII (nombres, emails, documentos, teléfonos); datos de negocio (tarjetas, cuentas, montos); IPs privadas, hostnames internos, connection strings de Azure Storage/Service Bus; cualquier valor junto a claves `Password`/`Secret`/`Key`/`Token`/`Credential`/`ConnectionString`.

Alerta especial: `EnableSensitiveDataLogging()` activo en QA/PROD expone valores de parámetros en las queries EF Core — señalarlo como riesgo de configuración.

## Patrones de error frecuentes

`System.NullReferenceException` → objeto no inicializado, revisar línea exacta en código propio. `InvalidOperationException: Unable to resolve service for type` → falta registro DI (`AddScoped/Transient/Singleton`). `Cannot consume scoped service from singleton` → captive dependency, revisar lifecycles. `DbUpdateException` (EF) → ver inner exception para el error SQL específico. `SqlException`/`NpgsqlException` → timeout, deadlock, sintaxis (ej. SQL Server 1205 = deadlock). `TimeoutException`/`TaskCanceledException` → timeout de HttpClient/DB/CancellationToken. `HttpRequestException` → fallo de cliente HTTP externo, revisar URL+status. `Polly.CircuitBreakerRejectedException` → circuit breaker abierto. `StackOverflowException` → recursión infinita. `OutOfMemoryException` → memory leak, heap usage, LOH, IDisposable no implementado. Rutas 404 → route template vs URL. `UnauthorizedAccessException`/401/403 → claims, políticas, token expirado. `An item with the same key has already been added` → duplicado en colección/diccionario.

## Señales adicionales

EF Core: `Executed DbCommand (NNNN ms)` >1000ms = query lenta; warning de connection pool bajo presión; N+1 con lazy loading.

ASP.NET Core: duración elevada en `Hosting.Diagnostics` = endpoint lento; errores de Kestrel = transporte/TLS; fallos de Authentication = token/claims; `OperationCanceledException` en middleware = cancelado por cliente o timeout.

## Guía de análisis

1. Identificar el primer `fail:`/ERROR/CRITICAL, no el cascade.
2. Trazar la cadena de excepciones (`---> Inner Exception`, `--- End of inner exception stack trace ---`).
3. Identificar el namespace/clase de código propio (no del framework) donde se originó.
4. Correlacionar por `RequestId`/`TraceId`.
5. Detectar patrones de repetición.

## Referencias

- .NET docs: https://learn.microsoft.com/en-us/dotnet/
- ASP.NET Core logging: https://learn.microsoft.com/en-us/aspnet/core/fundamentals/logging
- EF Core logging: https://learn.microsoft.com/en-us/ef/core/logging-events-diagnostics/
- Serilog: https://serilog.net/
- NLog: https://nlog-project.org/
- DI en .NET: https://learn.microsoft.com/en-us/dotnet/core/extensions/dependency-injection
- Diagnósticos: https://learn.microsoft.com/en-us/dotnet/core/diagnostics/
- SQL Server error codes: https://learn.microsoft.com/en-us/sql/relational-databases/errors-events/database-engine-events-and-errors
- Polly: https://github.com/App-vNext/Polly
- Health checks: https://learn.microsoft.com/en-us/aspnet/core/host-and-deploy/health-checks
