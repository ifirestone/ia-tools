---
name: log-analyzer-quarkus
description: "Analiza logs de Quarkus (JVM o Native/GraalVM) y produce un diagnóstico estructurado. Úsalo cuando el log contenga io.quarkus, io.quarkus.arc, códigos SRCFG, o el formato LEVEL [category] (thread-name) mensaje."
---

# Log Reader — Quarkus

## Señales de detección
`io.quarkus`, `io.quarkus.arc`, formato `LEVEL [category.package] (thread-name) Mensaje`, códigos `SRCFG`.

## Preguntar antes de analizar

| Situación | Pregunta |
|---|---|
| Entorno no declarado | ¿DEV, QA, STAGING o PROD? |
| Stack trace truncado (`...X more`) | ¿Puedes dar el stack trace completo? |
| Componente sin capa clara | ¿Es código propio o una extensión/librería de terceros? |
| Config externa no visible | ¿Tienes acceso a application.properties/yml relevante? |
| Error sugiere estado de datos | ¿Puedes describir la acción/request que lo disparó? |
| Nivel de log no visible | ¿Qué nivel está configurado? (DEBUG/INFO/WARN/ERROR) |

## Datos sensibles a marcar en rojo

Credenciales, tokens (JWT/Bearer/API keys), connection strings con user/password, PII (nombres, emails, documentos), IDs de transacción/cuentas, IPs privadas, hostnames internos, variables de entorno con `SECRET`/`KEY`/`TOKEN`/`PASSWORD`.

## Patrones de error frecuentes

- `SRCFG00014`/`SRCFG00040` → propiedad faltante o inválida en application.properties.
- `UnsatisfiedResolutionException` → fallo CDI, bean no encontrado.
- `ArcUndeclaredThrowableException` → excepción no declarada en bean CDI, revisar `Caused by:`.
- `JDBCConnectionException` → conexión a BD, pool agotado o BD no disponible.
- `AnnotatedConnectException` (Netty) → fallo de conexión de red a servicio externo.
- `ProcessingException` (JAX-RS) → timeout o fallo de serialización en cliente REST.
- `QuarkusBindException` → puerto en uso.
- `OutOfMemoryError` → heap o metaspace agotado.
- `smallrye.health DOWN` → health check fallando, revisar dependencias.
- `Build step ...failed` (dev mode) → error de compilación en hot-reload.

## JVM vs Native (GraalVM)

JVM: stack traces verbosos y completos. Native: stack traces comprimidos, líneas pueden no corresponder 1:1 — indicarlo en el reporte si proviene de imagen nativa.

## Guía de análisis

1. Identificar el primer ERROR/WARN relevante, no el cascade.
2. Trazar la cadena de `Caused by:`.
3. Identificar el componente raíz (package/clase donde se originó).
4. Correlacionar por thread para saber si es aislado o sistémico.
5. Detectar patrones de repetición o correlación temporal.

## Formato de reporte estándar

```
╔══════════════════════════════════════════════════════════════╗
║   REPORTE DE ANÁLISIS DE LOG — QUARKUS                        ║
╚══════════════════════════════════════════════════════════════╝
📋 RESUMEN EJECUTIVO
Tecnología: Quarkus [versión] / [JVM|Native]
Entorno: [DEV/QA/STAGING/PROD/No declarado]
Componente(s): [servicio/módulo]
Período log: [inicio] → [fin]
Total eventos: [N críticos] | [N warnings] | [N notables]
Diagnóstico breve: [1-2 frases con la causa más probable]

🔴 HALLAZGOS CRÍTICOS
  #N Severidad / Ubicación / Timestamp / Mensaje / Causa raíz / Impacto / Hipótesis (máx 3) / Acción sugerida / Referencia

🟡 ADVERTENCIAS RELEVANTES / 🔵 EVENTOS NOTABLES
⚠️ DATOS SENSIBLES: Tipo / Ubicación / Valor: <span style="color:red;font-weight:bold">valor</span> / Riesgo / Acción
❓ PREGUNTAS ABIERTAS / 🛠️ PRÓXIMOS PASOS (por prioridad)
📤 ¿Deseas el reporte como documento entregable (Word/Markdown)?
```

## Referencias
- https://quarkus.io/guides/
- https://quarkus.io/guides/cdi
- https://quarkus.io/guides/config
- https://quarkus.io/guides/logging
- https://github.com/smallrye/smallrye-config
