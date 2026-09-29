---
name: log-analyzer-laravel
description: "Analiza logs de Laravel (9/10/11) y produce un diagnóstico estructurado. Úsalo cuando el log contenga Illuminate\\, storage/logs/laravel.log, el formato [YYYY-MM-DD HH:MM:SS] entorno.NIVEL: mensaje, o menciones a Artisan/Eloquent/Horizon/Octane."
---

# Log Reader — Laravel

Si el log no muestra señales de Laravel (`Illuminate\`, `storage/logs/laravel.log`) pero sí errores de PHP puro, usar `log-analyzer-php`.

## Señales de detección
`Illuminate\`, ruta `storage/logs/laravel.log`, formato `[YYYY-MM-DD HH:MM:SS] entorno.NIVEL: mensaje`, menciones a Artisan/Eloquent/Horizon/Octane.

## Preguntar antes de analizar

| Situación | Pregunta |
|---|---|
| Entorno no declarado | ¿`APP_ENV` es local, staging o production? |
| Versión de Laravel no indicada | ¿9, 10, 11? Cambia comportamiento de algunos componentes |
| Error de queue sin driver | ¿Qué `QUEUE_CONNECTION` usa (`sync`/`database`/`redis`/`sqs`)? |
| Corre bajo Octane | ¿Usa Octane? Los memory leaks por estado estático son distintos a un leak normal de PHP-FPM |
| Excepción sin el objeto completo | ¿Tienes el JSON completo del campo `exception`, con el stacktrace? |
| Falla de auth sin guard claro | ¿Usa Sanctum, Passport, o el guard `web` por sesión? |

## Datos sensibles a marcar en rojo

Valores de `.env` filtrados dentro del `context` de una excepción (`DB_PASSWORD`, `APP_KEY`, `AWS_SECRET_ACCESS_KEY`), payloads de request con PII en `context`, tokens de Sanctum/Passport en headers `Authorization`.

**`APP_KEY` nunca debe aparecer en un reporte aunque esté en el log fuente.**

## Patrones de error frecuentes

`Illuminate\Database\QueryException: SQLSTATE[...]` → ver el SQLSTATE específico; puede ser timeout, sintaxis, o constraint violation (ver `log-analyzer-database` para el motor detrás). `Target class [X] does not exist` → binding no registrado en el Service Container. `Class "X" not found` → falta `use`, o `composer dump-autoload` pendiente tras un deploy. `CSRF token mismatch` (HTTP 419) → sesión expirada o el form no incluye `@csrf`. `Illuminate\Auth\AuthenticationException: Unauthenticated` (401) → guard/middleware `auth` sin sesión o token válido. `Illuminate\Auth\Access\AuthorizationException` (403) → policy/gate denegó la acción. `MethodNotAllowedHttpException` → verbo HTTP no definido para esa ruta. `Illuminate\Queue\MaxAttemptsExceededException` → el job superó `tries`, revisar si terminó en `failed_jobs`.

**Horizon:** alertas de "long-wait" → cola saturada, subir workers o revisar jobs lentos.
**Octane:** memoria creciendo request tras request → estado estático (propiedades `static`, singletons) no se resetea entre requests.

## Guía de análisis

1. Extraer el JSON del campo `exception` completo, no solo la primera línea del log.
2. Identificar la clase de excepción real (después de `[object] (`), no el wrapper de Laravel.
3. Ubicar el primer frame del stacktrace que pertenece al código de la app (`App\`), no a `vendor/`.
4. Si es de queue, correlacionar con `failed_jobs` y la tabla/driver de la cola.

## Formato de reporte estándar

```
╔══════════════════════════════════════════════════════════════╗
║   REPORTE DE ANÁLISIS DE LOG — LARAVEL                        ║
╚══════════════════════════════════════════════════════════════╝
📋 RESUMEN EJECUTIVO
Tecnología: Laravel [versión] / PHP [versión]
Entorno: [local|staging|production/No declarado]
Componente(s): [app/queue/Horizon/Octane]
Período log: [inicio] → [fin]
Total eventos: [N críticos] | [N warnings] | [N notables]
Diagnóstico breve: [1-2 frases]

🔴 HALLAZGOS CRÍTICOS / 🟡 ADVERTENCIAS / 🔵 EVENTOS NOTABLES
⚠️ DATOS SENSIBLES: Valor: <span style="color:red;font-weight:bold">valor</span>
❓ PREGUNTAS ABIERTAS / 🛠️ PRÓXIMOS PASOS
📤 ¿Deseas el reporte como documento entregable (Word/Markdown)?
```

## Referencias
- https://laravel.com/docs
- https://laravel.com/docs/logging
- https://laravel.com/docs/queues
- https://laravel.com/docs/horizon
- https://laravel.com/docs/octane
