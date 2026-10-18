# Referencia: Java Quarkus

## Alcance

Runtime JVM y Native (GraalVM). Logging: JBoss Logging/SLF4J/Quarkus Logging Extension. Extensiones frecuentes: RESTEasy (Reactive), Hibernate ORM/Panache, SmallRye (MicroProfile), Vert.x, CDI (ArC), Kafka, JDBC, Flyway/Liquibase, OpenTelemetry, SmallRye Health.

Formato: `YYYY-MM-DD HH:mm:ss,SSS  LEVEL  [category.package] (thread-name) Mensaje`.

## Preguntar antes de interpretar

| Situación | Pregunta |
|---|---|
| Sin timestamps o incompletos | ¿Tienes la franja horaria o el log completo? |
| Nivel de log no visible | ¿Qué nivel está configurado? (DEBUG/INFO/WARN/ERROR) |
| Componente sin capa clara | ¿Es código propio o una extensión/librería de terceros? |
| Stack trace truncado (`...X more`) | ¿Puedes dar el stack trace completo? |
| Entorno no declarado | ¿DEV, QA, STAGING o PROD? |
| Config externa no visible | ¿Tienes acceso a application.properties/yml relevante? |
| Error sugiere estado de datos específico | ¿Puedes describir la acción/request que lo disparó? |

## Datos sensibles específicos

Credenciales, tokens (JWT/Bearer/API keys), hashes; connection strings con user/password; PII (nombres, emails, documentos, teléfonos); datos de negocio críticos (IDs de transacción, cuentas bancarias, tarjetas); IPs privadas, hostnames internos, nombres de BD de producción; variables de entorno con `SECRET`/`KEY`/`TOKEN`/`PASSWORD`/`CREDENTIAL`.

## Patrones de error frecuentes

`SRCFG00014`/`SRCFG00040` → propiedad faltante o inválida en application.properties. `UnsatisfiedResolutionException` → fallo CDI, bean no encontrado. `ArcUndeclaredThrowableException` → excepción no declarada en bean CDI, revisar `Caused by:`. `JDBCConnectionException` → conexión a BD, pool agotado o BD no disponible. `AnnotatedConnectException` (Netty) → fallo de conexión de red a servicio externo. `ProcessingException` (JAX-RS) → timeout o fallo de serialización en cliente REST. `QuarkusBindException` → puerto en uso. `OutOfMemoryError` → heap o metaspace agotado. `smallrye.health` DOWN → health check fallando, revisar dependencias. `Build step ...failed` (dev mode) → error de compilación en hot-reload.

## JVM vs Native (GraalVM)

JVM: stack traces verbosos y completos. Native: stack traces optimizados/comprimidos, líneas de código pueden no corresponder 1:1 — indícalo en el reporte si el log proviene de una imagen nativa.

## Guía de análisis

1. Identificar el punto de falla inicial (primer ERROR/WARN relevante, no el cascade).
2. Trazar la cadena de `Caused by:`.
3. Identificar el componente raíz (package/clase donde se originó).
4. Correlacionar por thread para saber si es aislado o sistémico.
5. Detectar patrones (repetición, correlación temporal).

## Referencias

- Quarkus guides: https://quarkus.io/guides/
- CDI/ArC: https://quarkus.io/guides/cdi
- Config: https://quarkus.io/guides/config
- Hibernate ORM + Panache: https://quarkus.io/guides/hibernate-orm-panache
- Health checks: https://quarkus.io/guides/smallrye-health
- Logging: https://quarkus.io/guides/logging
- Native builds: https://quarkus.io/guides/building-native-image
- SmallRye Config (SRCFG): https://github.com/smallrye/smallrye-config
- Quarkus GitHub Issues: https://github.com/quarkusio/quarkus/issues
