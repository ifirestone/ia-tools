# Referencia: Spring Boot / Spring Framework

> Si el log contiene `io.quarkus`, es el agente/referencia equivocado — usar `quarkus.md`. Si contiene `org.springframework`, esta es la referencia correcta.

## Alcance

Spring Boot 2.x/3.x, Spring Framework 5.x/6.x. Logging: SLF4J+Logback (default), Log4j2 si está configurado. Módulos frecuentes: Spring MVC/WebFlux, Security, Data JPA/JDBC/R2DBC, Cloud (Eureka, Config, Gateway, OpenFeign, Resilience4j), Batch, Integration, AMQP/Kafka. Servidores embebidos: Tomcat (default), Jetty, Undertow, Netty (WebFlux).

Formato: `YYYY-MM-DD HH:mm:ss.SSS  LEVEL  PID --- [thread-name] logger.class.FullName    : Mensaje`.

Loggers clave: `o.s.b.SpringApplication` (arranque) · `o.s.b.w.e.tomcat.TomcatWebServer` · `o.s.web.servlet.DispatcherServlet` (MVC) · `o.s.w.r.f.s.RouterFunctions` (WebFlux) · `o.s.security.*` · `o.s.d.jpa.*`/`o.h.*` (Hibernate) · `o.s.t.TransactionManager` · `o.s.c.openfeign.*` · `o.s.c.gateway.*` · `io.github.resilience4j.*` · `o.s.batch.*` · `o.s.kafka.*`/`o.s.a.rabbit.*`.

## Preguntar antes de interpretar

| Situación | Pregunta |
|---|---|
| Versión no declarada | ¿Spring Boot 2.x (Spring 5) o 3.x (Spring 6)? Difieren en paquetes y comportamiento |
| Entorno no declarado | ¿DEV, QA, STAGING o PROD? |
| Stack trace truncado | ¿Puedes dar el stack trace completo con las `Caused by:` anidadas? |
| Error de arranque sin config | ¿Puedes compartir la sección relevante de application.properties/yml? |
| Error de seguridad ambiguo | ¿Es al autenticar (login/token) o al acceder a un recurso (403)? |
| Clase sin identificar origen | ¿Es código propio del proyecto o una librería de terceros? |
| Feign/RestTemplate sin status/body | ¿Tienes logging DEBUG habilitado para el cliente HTTP? |
| Spring Batch sin job/step | ¿Qué Job y Step estaba ejecutando? |
| Microservicio sin trace ID | ¿Usa Sleuth/Micrometer Tracing? ¿Tienes el traceId del request? |

## Datos sensibles específicos

`spring.datasource.password`, `spring.security.oauth2.client.secret`, `spring.mail.password` expuestos al fallar resolución de placeholders; JWT/Bearer tokens en headers logueados; body de requests en DEBUG (`HandlerMethod`, Feign FULL); SQL con binding parameters reales (`hibernate.show_sql=true`); stack traces con IDs de usuario/transacción; output del endpoint Actuator `/env`; correlation/trace IDs (pueden rastrear actividad de usuarios en sistemas regulados).

Alertas de configuración de riesgo: Hibernate con `show_sql=true`+`format_sql=true` en QA/PROD; Feign en `Logger.Level.FULL` (loguea headers y body completos).

## Errores de arranque (ApplicationContext) — más críticos, la app no inicia

`APPLICATION FAILED TO START` + `UnsatisfiedDependencyException` → fallo de inyección, seguir `Caused by:` hasta el bean raíz. `NoSuchBeanDefinitionException` → falta `@Component`/`@Service`/`@Bean` o `@EnableXXX`. `NoUniqueBeanDefinitionException` → usar `@Primary`/`@Qualifier`. `BindException: Failed to bind properties` → tipo/nombre incorrecto en `@ConfigurationProperties`. `DataSourceInitializationException` → BD no disponible o credenciales incorrectas. `Port NNNN was already in use` → cambiar `server.port` o liberar el puerto. `LazyInitializationException` en arranque → acceso a proxy JPA fuera de sesión.

## Errores de runtime frecuentes

`HttpMessageNotReadableException` (JSON mal formado) · `MethodArgumentNotValidException` (`@Valid` rechazó el request) · `ResponseStatusException 403`/`AccessDeniedException` (roles, `HttpSecurity`, `@PreAuthorize`) · `JwtException`/`ExpiredJwtException` (TTL, firma, reloj) · `TransactionRequiredException` (falta `@Transactional`) · `LazyInitializationException` (usar `JOIN FETCH` o DTO projection) · `DataIntegrityViolationException` (constraint violado — ver inner SQL exception) · `OptimisticLockingFailureException` (`@Version`, concurrencia) · `CircuitBreakerOpenException`/`feign.FeignException`/`RetryableException` (Resilience4j/Feign) · `StepExecutionException` (Spring Batch — revisar skip-limit).

Spring Security: `AbstractSecurityInterceptor DENIED` (roles/config) · `UsernameNotFoundException` · `BadCredentialsException` · `AccountExpiredException`/`LockedException` · `CsrfException`.

Hibernate: query lenta con `logging.level.org.hibernate.SQL=DEBUG` · `HHH000104` (N+1 con paginación — usar CountQuery separada).

## Referencias

- Spring Boot: https://docs.spring.io/spring-boot/docs/current/reference/html/
- Spring Framework: https://docs.spring.io/spring-framework/docs/current/reference/html/
- Spring Security: https://docs.spring.io/spring-security/reference/
- Spring Data JPA: https://docs.spring.io/spring-data/jpa/docs/current/reference/html/
- Spring Cloud: https://docs.spring.io/spring-cloud/docs/current/reference/html/
- Resilience4j: https://resilience4j.readme.io/
- Spring Batch: https://docs.spring.io/spring-batch/docs/current/reference/html/
- Hibernate ORM: https://hibernate.org/orm/documentation/
- Baeldung: https://www.baeldung.com/spring-boot
