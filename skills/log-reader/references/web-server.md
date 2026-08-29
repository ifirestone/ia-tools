# Referencia: Web Server (nginx / Apache httpd / Tomcat)

## Alcance y formatos

- **nginx access log** (combined): `$remote_addr - $remote_user [$time_local] "$request" $status $body_bytes_sent "$referer" "$user_agent"`. **error log**: `YYYY/MM/DD HH:mm:ss [level] PID#TID: *connection_id message, client: IP, server: HOST, request: "...", upstream: "URL"`.
- **Apache httpd access log** (combined) similar a nginx. **error log**: `[Day Mon DD HH:mm:ss.microseconds YYYY] [module:level] [pid PID:tid TID] message` — códigos `AH0XXXX`.
- **Tomcat**: `catalina.out`/`catalina.log` formato `DD-Mon-YYYY HH:mm:ss.SSS LEVEL [thread-name] org.apache.tomcat.Clase Mensaje`; `localhost_access_log` similar a Apache con `%D` = ms de procesamiento.

## Preguntar antes de interpretar

| Situación | Pregunta |
|---|---|
| Servidor no identificado | ¿nginx, Apache httpd o Tomcat? Los formatos y patrones son muy diferentes |
| Solo access log | ¿Tienes el error log también? El access dice qué pasó; el error dice por qué |
| Proxy con backend poco claro | ¿Es reverse proxy hacia un backend? ¿Tienes logs de ese backend? |
| Entorno no declarado | ¿DEV, QA, STAGING o PROD? |
| Versión no indicada | Puede ser version-specific |
| Tomcat truncado | ¿Puedes dar el stack trace completo de catalina.out con el `Caused by:`? |
| 502/504 recurrentes sin logs de upstream | ¿Tienes logs del servicio upstream al que se proxea? |
| Tiempos elevados sin correlación de error | ¿Tienes métricas de CPU/memoria/disco de ese período? |
| Tomcat menciona webapp sin identificar | ¿Cuál es la aplicación/context afectada? |

## Datos sensibles específicos

IPs de clientes (PII/GDPR en PROD); URLs con parámetros sensibles (`?password=`, `?token=`); tokens en query strings (mala práctica — quedan en logs y caché de proxies, señálalo como riesgo); headers logueados (`Authorization`, `Cookie`); IPs de upstreams internos (revelan arquitectura); stack traces de Tomcat con IDs de transacción o datos de usuario.

## nginx — patrones de error

`upstream timed out` → timeout de upstream, revisar `proxy_read_timeout`/estado del backend. `upstream sent invalid header` → backend devolvió respuesta no-HTTP válida. `no live upstreams` → todos los backends marcados down por `max_fails`. `connect() failed (111: Connection refused)` → backend no escucha en el puerto. `SSL_do_handshake() failed` → certificados/cipher suites/SNI. `too many open files` → aumentar `worker_rlimit_nofile`/`ulimit`. `client intended to send too large body` → ajustar `client_max_body_size`. `limiting requests` → rate limiting (`limit_req`) activado.

Access log: revisar distribución de status 4xx/5xx por endpoint, `$request_time`/`$upstream_response_time`, picos de tráfico, user agents sospechosos.

## Apache httpd — patrones de error

`AH00957` (mod_proxy_http, backend no disponible) · `AH01071` (mod_fcgid, script no encontrado) · `AH00558` (ServerName no configurado, solo warning) · `AH02396` (hostname no resuelve) · `AH00485` (scoreboard lleno — MaxRequestWorkers agotado) · `child pid exit signal Segmentation fault` (crash de worker, revisar módulo).

## Tomcat — patrones de error

`SEVERE: One or more listeners failed to start` → ServletContextListener falló en `contextInitialized`. `SEVERE: Exception starting filter` → filtro falló en `init`. `SEVERE: Servlet [X] threw exception`. `WARNING: Exception while dispatching for type [ASYNC]` → común con Spring Async/WebFlux. `OutOfMemoryError: Java heap space` → aumentar `-Xmx`, heap dump. `OutOfMemoryError: Metaspace` → aumentar `-XX:MaxMetaspaceSize`, revisar class loader leaks. `Socket accept failed` → `acceptCount` agotado. `Unable to complete the scan for annotations` → dependencia faltante o conflicto de versiones. `Context [/app] startup failed due to previous errors` → buscar el SEVERE anterior real.

Si hay GC logs: Full GC frecuente = presión de memoria; pause > 1s puede causar timeouts.

## Reglas de correlación

No diagnostiques un 502/504 solo con el access log — pide el error log del servidor y, si aplica, los logs del upstream.

## Referencias

- nginx docs: https://nginx.org/en/docs/
- nginx proxy module: https://nginx.org/en/docs/http/ngx_http_proxy_module.html
- Apache httpd docs: https://httpd.apache.org/docs/current/
- Apache log files: https://httpd.apache.org/docs/current/logs.html
- Tomcat docs: https://tomcat.apache.org/tomcat-10.1-doc/
- Tomcat logging: https://tomcat.apache.org/tomcat-10.1-doc/logging.html
- JVM troubleshooting: https://docs.oracle.com/en/java/javase/17/troubleshoot/
