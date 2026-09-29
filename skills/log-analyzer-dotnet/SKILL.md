---
name: log-analyzer-dotnet
description: "Analiza logs de .NET / C# (ASP.NET Core, Worker Services, EF Core, Serilog, NLog, MEL) y produce un diagnóstico estructurado. Úsalo cuando el log contenga System.*Exception, Microsoft.AspNetCore, formato info:/fail: de MEL, [ERR] de Serilog o |ERROR| de NLog."
---

# Log Reader — .NET / C#

## Señales de detección
`System.NullReferenceException` y demás `System.*Exception`, `Microsoft.AspNetCore`, formato `info:`/`warn:`/`fail:` (MEL), `[ERR]` (Serilog), `|ERROR|` (NLog), `log4net`.

## Preguntar antes de analizar

| Situación | Pregunta |
|---|---|
| Versión de .NET no clara | ¿.NET 6/7/8, Framework 4.x? |
| Framework de logging no evidente | ¿Serilog, NLog, MEL nativo u otro? |
| Entorno no declarado | ¿DEV, QA, STAGING o PROD? |
| Stack trace truncado | ¿Puedes dar el stack trace completo con inner exceptions? |
| EF sin contexto de query | ¿Tienes la query EF o el modelo de datos involucrado? |
| Config externa mencionada | ¿Puedes compartir la sección relevante de appsettings.json (sin secretos)? |

## Datos sensibles a marcar en rojo

Connection strings (`Server=...;User Id=...;Password=...`), JWT/Bearer tokens, SQL queries con datos reales (`EnableSensitiveDataLogging()` activo), PII (nombres, emails, documentos), datos de tarjetas/cuentas, IPs privadas/hostnames internos, cualquier valor junto a claves `Password`/`Secret`/`Key`/`Token`/`ConnectionString`.

**Riesgo de configuración:** `EnableSensitiveDataLogging()` activo en QA/PROD expone parámetros de queries EF Core.

## Patrones de error frecuentes

- `System.NullReferenceException` → objeto no inicializado, revisar línea en código propio.
- `InvalidOperationException: Unable to resolve service for type` → falta registro DI.
- `Cannot consume scoped service from singleton` → captive dependency, revisar lifecycles.
- `DbUpdateException` (EF) → ver inner exception para el error SQL específico.
- `SqlException`/`NpgsqlException` → timeout, deadlock, sintaxis (SQL Server 1205 = deadlock).
- `TimeoutException`/`TaskCanceledException` → timeout de HttpClient/DB/CancellationToken.
- `HttpRequestException` → fallo de cliente HTTP externo, revisar URL+status.
- `Polly.CircuitBreakerRejectedException` → circuit breaker abierto.
- `OutOfMemoryException` → memory leak, LOH, IDisposable no implementado.
- `UnauthorizedAccessException`/401/403 → claims, políticas, token expirado.

## Señales adicionales

- EF Core: `Executed DbCommand (NNNN ms)` >1000ms = query lenta; N+1 con lazy loading.
- ASP.NET Core: duración elevada en `Hosting.Diagnostics` = endpoint lento; `OperationCanceledException` en middleware = cancelado por cliente o timeout.

## Guía de análisis

1. Identificar el primer `fail:`/ERROR/CRITICAL, no el cascade.
2. Trazar la cadena de excepciones (`---> Inner Exception`, `--- End of inner exception stack trace ---`).
3. Identificar el namespace/clase de código propio (no del framework).
4. Correlacionar por `RequestId`/`TraceId`.
5. Detectar patrones de repetición.

## Formato de reporte estándar

```
╔══════════════════════════════════════════════════════════════╗
║   REPORTE DE ANÁLISIS DE LOG — .NET / C#                      ║
╚══════════════════════════════════════════════════════════════╝
📋 RESUMEN EJECUTIVO
Tecnología: .NET [versión] / [framework]
Entorno: [DEV/QA/STAGING/PROD/No declarado]
Componente(s): [servicio/módulo]
Período log: [inicio] → [fin]
Total eventos: [N críticos] | [N warnings] | [N notables]
Diagnóstico breve: [1-2 frases]

🔴 HALLAZGOS CRÍTICOS
  #N Severidad / Ubicación / Timestamp / Mensaje / Causa raíz / Impacto / Hipótesis (máx 3) / Acción sugerida / Referencia

🟡 ADVERTENCIAS / 🔵 EVENTOS NOTABLES
⚠️ DATOS SENSIBLES: Valor: <span style="color:red;font-weight:bold">valor</span>
❓ PREGUNTAS ABIERTAS / 🛠️ PRÓXIMOS PASOS
📤 ¿Deseas el reporte como documento entregable (Word/Markdown)?
```

## Referencias
- https://learn.microsoft.com/en-us/dotnet/
- https://learn.microsoft.com/en-us/aspnet/core/fundamentals/logging
- https://learn.microsoft.com/en-us/ef/core/logging-events-diagnostics/
- https://learn.microsoft.com/en-us/dotnet/core/diagnostics/
- https://github.com/App-vNext/Polly
