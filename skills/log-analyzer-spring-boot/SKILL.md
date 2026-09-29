---
name: log-analyzer-spring-boot
description: "Analiza logs de Spring Boot / Spring Framework y produce un diagnóstico estructurado. Úsalo cuando el log contenga org.springframework, o.s.*, banners de arranque Spring Boot, o stack traces de Hibernate/JPA/Security."
---

# Log Reader — Spring Boot / Spring Framework

## Señales de detección
`org.springframework`, loggers `o.s.*`, `o.a.c.c.C.[.[.[/]`, formato `LEVEL PID --- [thread] logger : mensaje`.

## Preguntar antes de analizar

| Situación | Pregunta |
|---|---|
| Versión no declarada | ¿Spring Boot 2.x (Spring 5) o 3.x (Spring 6)? |
| Entorno no declarado | ¿DEV, QA, STAGING o PROD? |
| Stack trace truncado | ¿Puedes dar el stack trace completo con todas las `Caused by:`? |
| Error de arranque sin config | ¿Puedes compartir la sección relevante de application.properties/yml? |
| Feign/RestTemplate sin status | ¿Tienes logging DEBUG habilitado para el cliente HTTP? |
| Microservicio sin trace ID | ¿Usa Sleuth/Micrometer Tracing? ¿Tienes el traceId? |

## Datos sensibles a marcar en rojo

`spring.datasource.password`, `spring.security.oauth2.client.secret`, JWT/Bearer tokens en headers, body de requests en DEBUG (Feign FULL), SQL con binding parameters (`hibernate.show_sql=true`), output del endpoint Actuator `/env`, correlation/trace IDs.

**Riesgo de configuración:** Hibernate con `show_sql=true`+`format_sql=true` en QA/PROD; Feign en `Logger.Level.FULL`.

## Errores de arranque — la app no inicia

- `APPLICATION FAILED TO START` + `UnsatisfiedDependencyException` → seguir `Caused by:` hasta el bean raíz.
- `NoSuchBeanDefinitionException` → falta `@Component`/`@Service`/`@Bean` o `@EnableXXX`.
- `NoUniqueBeanDefinitionException` → usar `@Primary`/`@Qualifier`.
- `BindException: Failed to bind properties` → tipo/nombre incorrecto en `@ConfigurationProperties`.
- `DataSourceInitializationException` → BD no disponible o credenciales incorrectas.
- `Port NNNN was already in use` → cambiar `server.port` o liberar el puerto.

## Errores de runtime frecuentes

`HttpMessageNotReadableException` (JSON mal formado) · `MethodArgumentNotValidException` (`@Valid` rechazó el request) · `ResponseStatusException 403`/`AccessDeniedException` (roles, `HttpSecurity`, `@PreAuthorize`) · `JwtException`/`ExpiredJwtException` (TTL, firma, reloj) · `TransactionRequiredException` (falta `@Transactional`) · `LazyInitializationException` (usar `JOIN FETCH` o DTO projection) · `DataIntegrityViolationException` (constraint violado — ver inner SQL exception) · `OptimisticLockingFailureException` (`@Version`, concurrencia) · `CircuitBreakerOpenException`/`feign.FeignException` (Resilience4j/Feign) · `StepExecutionException` (Spring Batch).

Spring Security: `DENIED` (roles/config) · `UsernameNotFoundException` · `BadCredentialsException` · `AccountExpiredException`/`LockedException` · `CsrfException`.

Hibernate: query lenta con `logging.level.org.hibernate.SQL=DEBUG` · `HHH000104` (N+1 con paginación).

## Formato de reporte estándar

```
╔══════════════════════════════════════════════════════════════╗
║   REPORTE DE ANÁLISIS DE LOG — SPRING BOOT                    ║
╚══════════════════════════════════════════════════════════════╝
📋 RESUMEN EJECUTIVO
Tecnología: Spring Boot [versión] / Spring [versión]
Entorno: [DEV/QA/STAGING/PROD/No declarado]
Componente(s): [servicio/módulo]
Período log: [inicio] → [fin]
Total eventos: [N críticos] | [N warnings] | [N notables]
Diagnóstico breve: [1-2 frases con la causa más probable]

🔴 HALLAZGOS CRÍTICOS
  #N Severidad / Ubicación / Timestamp / Mensaje / Causa raíz / Impacto / Hipótesis (máx 3) / Acción sugerida / Referencia

🟡 ADVERTENCIAS RELEVANTES
[misma estructura]

🔵 EVENTOS INFORMATIVOS NOTABLES
[solo lo relevante para el incidente]

⚠️ DATOS SENSIBLES DETECTADOS
Tipo / Ubicación / Valor: <span style="color:red;font-weight:bold">valor</span> / Riesgo / Acción

❓ PREGUNTAS ABIERTAS / CONTEXTO FALTANTE

🛠️ PRÓXIMOS PASOS RECOMENDADOS
[ordenados por prioridad]

📤 ¿Deseas que genere este reporte como documento entregable (Word/Markdown)?
```

## Referencias
- https://docs.spring.io/spring-boot/docs/current/reference/html/
- https://docs.spring.io/spring-security/reference/
- https://docs.spring.io/spring-data/jpa/docs/current/reference/html/
- https://resilience4j.readme.io/
- https://hibernate.org/orm/documentation/
