---
name: log-analyzer-web-server
description: "Analiza logs de nginx, Apache httpd, Tomcat e IIS y produce un diagnóstico estructurado. Úsalo cuando el log contenga combined log format, [error] PID#TID:, códigos AH0XXXX, catalina.out, SEVERE [main], o formato W3C Extended con sc-substatus/sc-win32-status."
---

# Log Reader — Web Server (nginx / Apache httpd / Tomcat / IIS)

## Señales de detección
nginx/Apache: combined log (`$remote_addr ... "$request" $status`) o `[error] PID#TID: *conn_id`. Apache: `AH0XXXX`. Tomcat: `catalina.out`, `org.apache.catalina`, `SEVERE [main]`. IIS: W3C Extended con `sc-substatus`/`sc-win32-status`, `w3wp.exe`, `HTTP Error 5XX.YY`.

## Preguntar antes de analizar

| Situación | Pregunta |
|---|---|
| Servidor no identificado | ¿nginx, Apache httpd, Tomcat o IIS? |
| Solo access log | ¿Tienes el error log también? El access dice qué; el error dice por qué |
| Entorno no declarado | ¿DEV, QA, STAGING o PROD? |
| 502/504 sin logs de upstream | ¿Tienes logs del servicio upstream al que se proxea? |
| Tomcat truncado | ¿Puedes dar el stack trace completo de catalina.out con el `Caused by:`? |
| IIS: stack .NET no claro | ¿.NET Framework clásico, o .NET Core vía ANCM (in-process u out-of-process)? |
| IIS: solo hay HTTP Error en pantalla | ¿Está habilitado Failed Request Tracing (FREB)? |

## Datos sensibles a marcar en rojo

IPs de clientes (PII/GDPR en PROD), URLs con parámetros sensibles (`?password=`, `?token=`), tokens en query strings, headers logueados (`Authorization`, `Cookie`), IPs de upstreams internos, IIS: `cs-username` (usuario Windows/AD), `cs-uri-query` con tokens, rutas internas expuestas en 500.19.

## nginx — patrones de error

`upstream timed out` → revisar `proxy_read_timeout`/estado del backend. `upstream sent invalid header` → backend devolvió respuesta no-HTTP. `no live upstreams` → todos los backends down por `max_fails`. `connect() failed (111)` → backend no escucha en el puerto. `SSL_do_handshake() failed` → certificados/cipher suites/SNI. `too many open files` → aumentar `worker_rlimit_nofile`. `client intended to send too large body` → ajustar `client_max_body_size`. `limiting requests` → rate limiting activado.

## Apache httpd — patrones de error

`AH00957` (mod_proxy_http, backend no disponible) · `AH01071` (mod_fcgid, script no encontrado) · `AH00485` (scoreboard lleno — MaxRequestWorkers agotado) · `child pid exit signal Segmentation fault` (crash de worker).

## Tomcat — patrones de error

`SEVERE: One or more listeners failed to start` → ServletContextListener falló. `SEVERE: Exception starting filter` → filtro falló en init. `OutOfMemoryError: Java heap space` → aumentar `-Xmx`. `OutOfMemoryError: Metaspace` → aumentar `-XX:MaxMetaspaceSize`. `Context [/app] startup failed due to previous errors` → buscar el SEVERE anterior real.

## IIS — patrones de error

`HTTP Error 500.19` → `web.config` mal formado o sin permisos ACL. `502.3 Bad Gateway` (ANCM) → proceso backend no respondió, revisar stdout log de ANCM. `500.30 - ASP.NET Core app failed to start` → la app nunca levantó Kestrel. `503 Service Unavailable` → App Pool detenido por Rapid-Fail Protection. `sc-win32-status != 0` → error de Windows subyacente (`5`=acceso denegado, `64`=red no disponible).

## Formato de reporte estándar

```
╔══════════════════════════════════════════════════════════════╗
║   REPORTE DE ANÁLISIS DE LOG — WEB SERVER                     ║
╚══════════════════════════════════════════════════════════════╝
📋 RESUMEN EJECUTIVO
Tecnología: [nginx|Apache httpd|Tomcat|IIS] [versión]
Entorno: [DEV/QA/STAGING/PROD/No declarado]
Componente(s): [servidor/sitio/app pool]
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
- https://nginx.org/en/docs/
- https://httpd.apache.org/docs/current/
- https://tomcat.apache.org/tomcat-10.1-doc/logging.html
- https://learn.microsoft.com/en-us/iis/
- https://learn.microsoft.com/en-us/aspnet/core/test/troubleshoot-azure-iis
