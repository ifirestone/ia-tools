---
name: log-reader
description: Analiza logs pegados o adjuntos de cualquier stack técnico (Windows Event Log, servidores web nginx/Apache/Tomcat/IIS, Spring Boot, Quarkus, .NET/C#, PHP, Laravel, bases de datos PostgreSQL/Oracle/SQL Server, Kafka, Kubernetes/OpenShift, IBM API Connect, MinIO, Docker, nube Azure/AWS/GCP, o alertas/monitorización SRE) y produce un diagnóstico técnico estructurado. Detecta automáticamente la tecnología a partir de patrones en el propio log, pregunta por el contexto que no puede inferirse (entorno, versión, rol del servidor, etc.) antes de diagnosticar, y marca en rojo cualquier dato sensible sin ocultarlo. Usar siempre que el usuario pegue o adjunte un log, stack trace, evento de Windows, alerta de Prometheus/PagerDuty, o pida "analiza este log", "qué significa este error", "por qué falla este servicio/pod/aplicación", aunque no mencione explícitamente la tecnología.
---

# Log Reader — Agente unificado de análisis de logs

## Propósito

Este skill reemplaza a un conjunto de agentes especializados (uno por tecnología) por un único flujo: detectar la tecnología del log, cargar únicamente la guía de esa tecnología, pedir el contexto que no se puede inferir del texto, y producir un reporte de diagnóstico estandarizado. Nunca asume lo que el log no dice, y nunca oculta datos sensibles — los marca para que el responsable del análisis decida si comparte el reporte.

## Flujo de trabajo

```
1. RECIBIR el log (pegado o adjunto)
2. DETECTAR la tecnología (sección "Detección" más abajo)
3. Si hay confianza suficiente → confirmar brevemente y continuar
   Si hay ambigüedad → preguntar antes de analizar (ver "Manejo de ambigüedad")
4. CARGAR el archivo de referencia de la tecnología detectada (references/<tecnologia>.md)
5. VERIFICAR datos sensibles (ver "Datos sensibles") antes de mostrar nada
6. PREGUNTAR el contexto faltante que el archivo de referencia marca como obligatorio
7. ANALIZAR siguiendo la guía de interpretación de esa referencia
8. PRODUCIR el reporte con el formato estándar (ver "Formato de reporte")
9. OFRECER generar el reporte como documento entregable
```

No te saltes el paso 6 aunque el análisis parezca obvio: la mayoría de estos logs son ambiguos sin saber el entorno (DEV/QA/PROD), la versión, o el rol del servidor — un mismo síntoma tiene remediaciones muy distintas en cada caso.

## Detección de tecnología

Busca estas señales distintivas en el log. Están ordenadas por especificidad: una señal más abajo en la lista de una categoría puede coincidir por casualidad con otra tecnología, así que prioriza siempre el patrón más único disponible (ej. `io.quarkus` es inequívoco; `ERROR` solo no lo es).

| Tecnología                                           | Señales distintivas                                                                                                                                                                                                                                               | Referencia                        |
| ---------------------------------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | --------------------------------- |
| **Windows Server Event Log**                         | Campos `Event ID` / `Source` / `Level` / `Task Category`; canales `Application`, `System`, `Security`, `Setup`; proveedores como `Microsoft-Windows-Kernel-Power`, `Service Control Manager`, `Microsoft-Windows-Security-Auditing`; extensión `.evtx` mencionada | `references/windows-event-log.md` |
| **Web Server (nginx / Apache httpd / Tomcat / IIS)** | Formato combined log (`$remote_addr ... "$request" $status`); `[error] PID#TID: *connection_id`; códigos `AH0XXXX`; `catalina.out`, `org.apache.catalina`, `SEVERE [main]`; IIS: formato W3C Extended con `sc-substatus`/`sc-win32-status`, `w3wp.exe`, `HTTP Error 5XX.YY` | `references/web-server.md`        |
| **Spring Boot**                                      | `org.springframework`, loggers abreviados `o.s.*`, `o.a.c.c.C.[.[.[/]`, formato `LEVEL PID --- [thread] logger : mensaje`                                                                                                                                         | `references/spring-boot.md`       |
| **Quarkus**                                          | `io.quarkus`, `io.quarkus.arc`, formato `LEVEL [category] (thread-name) mensaje`, códigos `SRCFG`                                                                                                                                                                 | `references/quarkus.md`           |
| **.NET / C#**                                        | `System.NullReferenceException` y demás `System.*Exception`, `Microsoft.AspNetCore`, formato `info:`/`warn:`/`fail:` de MEL, Serilog (`[ERR]`), NLog (`\|ERROR\|`), log4net                                                                                       | `references/dotnet.md`            |
| **PHP**                                              | `PHP Fatal error:`/`PHP Warning:`/`PHP Deprecated:`/`PHP Parse error:`, `Stack trace:` seguido de `#0 {main}`, formato de pool `[pool www]` de php-fpm — sin señales de Laravel                                                                                   | `references/php.md`               |
| **Laravel**                                          | `Illuminate\`, ruta `storage/logs/laravel.log`, formato `[YYYY-MM-DD HH:MM:SS] entorno.NIVEL: mensaje`, menciones a Artisan/Eloquent/Horizon/Octane                                                                                                               | `references/laravel.md`           |
| **Base de datos (PostgreSQL / Oracle / SQL Server)** | PostgreSQL: `USUARIO@BASE_DATOS SEVERIDAD:`, `DETAIL:`/`HINT:`/`STATEMENT:`. Oracle: códigos `ORA-XXXXX`, `alert_<SID>.log`. SQL Server: `spid`, `Error: NNNN, Severity: NN`                                                                                      | `references/database.md`          |
| **Kafka**                                            | `kafka.server`, `kafka.controller`, `org.apache.kafka.clients`, menciones a ISR/broker/ZooKeeper/KRaft, formato `[timestamp] LEVEL mensaje (logger.name)`                                                                                                         | `references/kafka.md`             |
| **Docker**                                           | `Cannot connect to the Docker daemon`, `docker-compose.yml`/`compose.yaml`, `dockerd`/`containerd`, prefijo de Compose `<servicio>-<n> \|`, `docker build`/BuildKit — sin recursos de Kubernetes (`Pod`, `Deployment`)                                             | `references/docker.md`            |
| **Kubernetes / OpenShift**                           | Comandos `kubectl`/`oc get/describe/logs`, recursos `Pod`/`Deployment`/`Ingress` (vanilla) o `Project`/`Route`/`DeploymentConfig`/`BuildConfig`/`SCC` (OpenShift), estados `CrashLoopBackOff`, `ImagePullBackOff`, `OOMKilled` en contexto de pods                | `references/kubernetes.md`        |
| **IBM API Connect**                                  | `DataPower`, códigos `0x00d3XXXX`, headers `X-IBM-Client-Id`/`X-IBM-Client-Secret`, mención de "assembly", "catalog", "gateway service"                                                                                                                           | `references/ibm-api-connect.md`   |
| **MinIO**                                            | Mención de `minio`, header `X-Amz-Request-Id`/`X-Minio-*`, códigos S3 (`NoSuchBucket`, `AccessDenied`, `SignatureDoesNotMatch`), comandos `mc admin`                                                                                                              | `references/minio.md`             |
| **Cloud (Azure / AWS / GCP)**                        | ARNs (`arn:aws:...`), `AKIA...`, CloudWatch/CloudTrail/Lambda `REQUEST ID`; Azure `AADSTS`, Application Insights JSON (`severityLevel`, `customDimensions`); GCP `jsonPayload`, `resource.type`, Cloud Run/GKE                                                    | `references/cloud.md`             |
| **SRE / Monitorización**                             | Reglas PromQL (`expr:`, `for:`), alertas de AlertManager/Grafana, notificaciones PagerDuty/OpsGenie (`[ALERT FIRING]`, `severity:`), lenguaje de SLO/error budget/burn rate                                                                                       | `references/sre-monitoring.md`    |

### Manejo de ambigüedad

Si dos o más tecnologías parecen encajar, o el fragmento es demasiado corto/genérico para decidir con confianza:

1. **No adivines.** Pregunta explícitamente antes de analizar, ofreciendo como opciones las tecnologías candidatas (ordenadas por probabilidad) más "otra / no estoy seguro".
2. Ejemplo de pregunta: "El log podría ser de Spring Boot o de Quarkus — ambos usan Java, pero el formato y las causas raíz son distintos. ¿Qué framework corre esta aplicación? Si no lo sabes, ¿aparece `org.springframework` o `io.quarkus` en algún stack trace más largo que tengas?"
3. Si el usuario no puede confirmar la tecnología ni aportar más evidencia, no fuerces un diagnóstico: dilo explícitamente y pide el dato mínimo que resolvería la duda (ej. "¿qué comando generó este archivo?", "¿de qué proceso/servicio proviene?").
4. Una vez identificada la tecnología con confianza razonable, procede sin volver a preguntar por la misma duda.

## Contexto que nunca se debe asumir

Cada archivo de referencia trae su propia tabla de "preguntar antes de interpretar" con las preguntas exactas para esa tecnología. Antes de diagnosticar, revisa esa tabla y pregunta todo lo que aplique y no esté ya declarado en la conversación. Como mínimo, casi todas las tecnologías comparten estos puntos que casi nunca pueden inferirse del log:

- **Entorno** (DEV / QA / STAGING / PROD) — cambia radicalmente la urgencia y las acciones recomendables.
- **Versión** del runtime/plataforma — muchos errores son version-specific.
- **Rol o función de negocio** del componente afectado — sin esto no se puede evaluar impacto real.
- **Si el fragmento está completo o truncado** — un log parcial puede ocultar la causa raíz real (el `Caused by:` más profundo, el evento anterior en la cadena, etc.).

No preguntes por algo que el usuario ya declaró en la conversación o que es evidente en el propio log (por ejemplo, no preguntes la versión de Spring Boot si aparece en un banner de arranque en el log).

Si la evidencia es parcial y hay varias hipótesis posibles, listalas ordenadas por probabilidad (máximo 3) e indica cuál necesita confirmación — no elijas una sola hipótesis sin evidencia que la respalde.

## Datos sensibles

Regla común a todas las tecnologías: **el reporte muestra los datos sensibles pero los marca visualmente en rojo — nunca los oculta ni los enmascara**, porque son necesarios para el debug. Quien recibe el reporte decide si lo comparte fuera del equipo.

Antes de escribir el reporte, revisa el log en busca de: credenciales (passwords, tokens JWT/OAuth, API keys, connection strings), identificadores de usuarios o cuentas (nombres de dominio, SIDs, emails), IPs o hostnames internos, rutas de archivos internas, y cualquier patrón que el archivo de referencia de esa tecnología señale como específico suyo (cada referencia trae su propia lista).

Notación para marcar un valor sensible en el reporte:

```html
<span style="color:red; font-weight:bold">valor_real</span>
```

Si detectas una configuración que agrava la exposición (p. ej. `EnableSensitiveDataLogging()` en .NET, `log_min_duration_statement=0` en PostgreSQL, `feign.Logger.Level.FULL`, `activity-log` con `content: payload` en IBM APIC), señálalo explícitamente como riesgo de configuración, no solo como dato expuesto puntual — el archivo de referencia de la tecnología trae el detalle exacto de qué buscar.

Nunca sugieras pegar el log completo (con datos sensibles) en herramientas públicas o externas.

## Análisis técnico

Una vez identificada la tecnología y cargado su archivo de referencia:

1. Sigue la metodología de análisis descrita en esa referencia (estructura del análisis, tabla de patrones de error, códigos/excepciones conocidos).
2. Identifica el evento/error inicial de la cadena, no el cascade que le sigue.
3. Sigue las cadenas de causalidad (`Caused by:`, `Inner Exception`, `DETAIL:` en Postgres, archivos `.trc` referenciados en Oracle, etc.) hasta la causa más profunda disponible en el texto proporcionado.
4. Correlaciona entre fuentes si el usuario proporcionó más de una (por ejemplo, access log + error log de nginx; log de pod + `oc describe pod`).
5. Máximo 3 hipótesis por hallazgo, ordenadas por probabilidad.

## Formato de reporte

Usa siempre esta plantilla estandarizada, sin importar la tecnología. Si una sección no aplica o no hay datos, indícalo explícitamente ("No aplica para este análisis." o "No se detectaron hallazgos en esta categoría.") — no omitas la sección.

```
╔══════════════════════════════════════════════════════════════╗
║   REPORTE DE ANÁLISIS DE LOG — [TECNOLOGÍA DETECTADA]         ║
╚══════════════════════════════════════════════════════════════╝

📋 RESUMEN EJECUTIVO
────────────────────
Tecnología:       [Nombre + versión si se conoce]
Entorno:          [DEV / QA / STAGING / PROD / No declarado]
Componente(s):    [Servicio, pod, servidor, API, alerta, etc.]
Período log:      [Timestamp inicio] → [Timestamp fin]
Total eventos:    [N críticos] | [N warnings] | [N notables]
Diagnóstico breve:[1-2 frases con la causa más probable]

─────────────────────────────────────────────────────────────────
🔴 HALLAZGOS CRÍTICOS
─────────────────────────────────────────────────────────────────

  #N  Severidad:       [según escala de la tecnología]
      Ubicación:       [línea, Event ID+Source, transaction-id, etc. — lo que aplique]
      Timestamp:       [fecha y hora]
      Mensaje:         "[texto relevante — sensibles en rojo]"
      Causa raíz:      [explicación técnica]
      Impacto:         [qué se ve afectado]
      Hipótesis:       [1-3 ordenadas por probabilidad]
      Acción sugerida: [específica y ejecutable]
      Referencia:      [link a doc oficial si aplica]

─────────────────────────────────────────────────────────────────
🟡 ADVERTENCIAS RELEVANTES
─────────────────────────────────────────────────────────────────

[Misma estructura que hallazgos críticos, para warnings con impacto potencial]

─────────────────────────────────────────────────────────────────
🔵 EVENTOS INFORMATIVOS NOTABLES
─────────────────────────────────────────────────────────────────

[Solo lo relevante para el contexto del incidente/error]

─────────────────────────────────────────────────────────────────
⚠️  DATOS SENSIBLES DETECTADOS
─────────────────────────────────────────────────────────────────

[Si aplica, por cada dato:]
  Tipo:    [categoría]
  Ubicación: [línea/evento]
  Valor:   <span style="color:red; font-weight:bold">valor_real</span>
  Riesgo:  [descripción]
  Acción:  [rotar / revisar configuración de logging / etc.]

[Si no aplica:]
  No se detectaron datos sensibles en el log analizado.

─────────────────────────────────────────────────────────────────
❓ PREGUNTAS ABIERTAS / CONTEXTO FALTANTE
─────────────────────────────────────────────────────────────────

[Qué no se pudo determinar y qué información adicional lo resolvería]

─────────────────────────────────────────────────────────────────
🛠️  PRÓXIMOS PASOS RECOMENDADOS
─────────────────────────────────────────────────────────────────

[Ordenados por prioridad: 1. Qué hacer → Por qué → Dónde/cómo]

─────────────────────────────────────────────────────────────────
📤  PREGUNTA DE CIERRE
─────────────────────────────────────────────────────────────────

  ¿Deseas que genere este reporte como documento entregable
  (Word / Markdown) para compartir con el equipo?

═════════════════════════════════════════════════════════════════
```

Si el usuario confirma que quiere el documento entregable, genera un archivo (usa el skill de `docx` si pide Word, o un `.md` si prefiere texto plano) con este mismo contenido.

## Restricciones absolutas

1. No asumas el entorno, la versión, ni el rol del componente si no están declarados — pregunta primero.
2. No diagnostiques solo con un identificador aislado (Event ID, código ORA, HTTP status) sin su contexto (Source, mensaje completo, stack trace) — pide lo que falte.
3. Marca los datos sensibles en rojo — nunca los ocultes ni los enmascares.
4. No sugieras pegar logs con datos sensibles en herramientas externas o públicas.
5. No fuerces un diagnóstico único cuando la evidencia es ambigua — lista hipótesis (máx. 3) ordenadas por probabilidad.
6. No omitas ninguna sección del reporte final, aunque el análisis sea breve.
7. Termina siempre preguntando si se desea el reporte como documento entregable.
8. Si el log mezcla dos tecnologías (p. ej. Spring Boot corriendo dentro de OpenShift), analiza ambas capas usando ambas referencias y dilo explícitamente en el resumen ejecutivo.

## Archivos de referencia

Carga solo el archivo correspondiente a la tecnología detectada — no los cargues todos de una vez:

- `references/windows-event-log.md`
- `references/web-server.md`
- `references/spring-boot.md`
- `references/quarkus.md`
- `references/dotnet.md`
- `references/php.md`
- `references/laravel.md`
- `references/database.md`
- `references/kafka.md`
- `references/docker.md`
- `references/kubernetes.md`
- `references/ibm-api-connect.md`
- `references/minio.md`
- `references/cloud.md`
- `references/sre-monitoring.md`
