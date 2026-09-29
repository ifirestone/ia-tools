# Referencia: Laravel

Framework PHP. Si el log no muestra nada de Laravel (`Illuminate\`, `storage/logs/laravel.log`) pero sí errores de PHP puro, usar `references/php.md` en su lugar.

## Alcance

Laravel 9/10/11. Componentes: Eloquent ORM, Queue (drivers `sync`/`database`/`redis`/`sqs`/`beanstalkd`), Horizon (dashboard de colas Redis), Octane (servidor persistente sobre Swoole/RoadRunner), Sanctum/Passport (auth API), Artisan (CLI), Service Container/Facades, Events/Listeners, Broadcasting.

Formato de log (canal `stack`/`daily`/`single`, driver Monolog, niveles PSR-3): `[YYYY-MM-DD HH:MM:SS] entorno.NIVEL: mensaje {"exception":"[object] (Clase(code: N): mensaje at /ruta:línea)\n[stacktrace]\n#0 ..."}`. Niveles: debug < info < notice < warning < error < critical < alert < emergency.

## Preguntar antes de interpretar

| Situación | Pregunta |
|---|---|
| Entorno no declarado | ¿`APP_ENV` es local, staging o production? |
| Canal de log no claro | ¿`stack`, `daily`, `single`, o envía a `slack`/servicio externo? |
| Error de queue sin driver | ¿Qué `QUEUE_CONNECTION` usa (`sync`/`database`/`redis`/`sqs`)? |
| Corre bajo Octane | ¿Usa Octane? Los memory leaks entre requests por estado estático mal reseteado son distintos a un leak normal de PHP-FPM |
| Versión de Laravel no indicada | ¿9, 10, 11? Cambia comportamiento de algunos componentes |
| Excepción sin el objeto completo | ¿Tenés el JSON completo del campo `exception`, con el stacktrace? |
| Falla de auth sin guard claro | ¿Usa Sanctum, Passport, o el guard `web` por sesión? |

## Datos sensibles específicos

Valores de `.env` filtrados dentro del `context` de una excepción (`DB_PASSWORD`, `APP_KEY`, `AWS_SECRET_ACCESS_KEY`) cuando algo los interpola en un mensaje de error; payloads de request logueados con `context` que incluyen PII (nombre, email, documento); tokens de Sanctum/Passport en headers `Authorization` si el log incluye la request completa; `APP_KEY` nunca debe aparecer en un reporte aunque esté en el log fuente.

## Patrones de error frecuentes

`Illuminate\Database\QueryException: SQLSTATE[...]` → ver el SQLSTATE específico (igual que `references/database.md` para el motor detrás); revisar si es timeout de conexión, sintaxis, o constraint violation. `Target class [X] does not exist` → binding no registrado en el Service Container, o typo en la clase inyectada. `Class "X" not found` → falta `use`, o `composer dump-autoload` pendiente tras un deploy. `CSRF token mismatch` (HTTP 419) → sesión expirada, o el form no incluye `@csrf`. `Illuminate\Session\TokenMismatchException` → mismo origen que el 419 anterior. `Illuminate\Auth\AuthenticationException: Unauthenticated` (401) → guard/middleware `auth` sin sesión o token válido. `Illuminate\Auth\Access\AuthorizationException` (403) → policy/gate denegó la acción, revisar la policy involucrada. `Symfony\Component\HttpKernel\Exception\MethodNotAllowedHttpException` → verbo HTTP no definido para esa ruta. `Illuminate\Queue\MaxAttemptsExceededException` → el job superó `tries`, revisar por qué falla reiteradamente y si terminó en `failed_jobs`. Horizon: alertas de "long-wait" → cola saturada, subir workers o revisar jobs lentos. Octane: memoria creciendo request tras request sin bajar → estado estático (propiedades `static`, singletons mal alcanzados) no se resetea entre requests.

## Guía de análisis

1. Extraer el JSON del campo `exception` completo, no solo la primera línea del log.
2. Identificar la clase de excepción real (después de `[object] (`), no el wrapper de Laravel.
3. Ubicar el primer frame del stacktrace que pertenece al código de la app (`App\`), no a `vendor/`.
4. Si es de queue, correlacionar con `failed_jobs` y la tabla/driver de la cola.

## Referencias

- Laravel docs: https://laravel.com/docs
- Logging: https://laravel.com/docs/logging
- Queues: https://laravel.com/docs/queues
- Horizon: https://laravel.com/docs/horizon
- Octane: https://laravel.com/docs/octane
- Sanctum: https://laravel.com/docs/sanctum
- Error handling: https://laravel.com/docs/errors
