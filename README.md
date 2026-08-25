# IA Agents - Log Readers

Este repositorio reúne una colección de plantillas y guías operativas para agentes de análisis de logs en distintos stacks y entornos tecnológicos. Su propósito es ayudar a interpretar archivos de log, detectar patrones de error, identificar causas probables y generar reportes estructurados con foco en diagnóstico técnico y seguridad.

## Objetivo

El repositorio está pensado para apoyar procesos de:

- análisis de incidentes operativos
- diagnóstico de fallas en aplicaciones y plataformas
- revisión de logs de infraestructura y runtime
- identificación de errores recurrentes y anomalías
- generación de reportes accionables para soporte, QA o operaciones

Cada archivo dentro de `log-readers/` describe un agente especializado para un tipo de log concreto.

## Estructura del repositorio

```text
ia-agents/
├── README.md
├── log-readers/
│   ├── dotnet-log-reader-agent.md
│   ├── ejemplo-reporte-quarkus-log-reader.md
│   ├── ibm-apiconnect-log-reader-agent.md
│   ├── openshift-log-reader-agent.md
│   ├── quarkus-log-reader-agent.md
│   └── windows-server-eventlog-reader-agent.md
└── .gitignore
```

## Agentes incluidos

### .NET / C# Log Reader Agent
Archivo: `log-readers/dotnet-log-reader-agent.md`

- Recomendado para analizar logs de aplicaciones .NET / C#
- Cubre ASP.NET Core, Serilog, NLog, log4net, Entity Framework y errores de runtime
- Incluye reglas sobre manejo de datos sensibles y reportes estructurados

### Quarkus Log Reader Agent
Archivo: `log-readers/quarkus-log-reader-agent.md`

- Orientado a aplicaciones Java con Quarkus
- Analiza errores de configuración, CDI, acceso a BD, red y runtime JVM
- Define patrones frecuentes y buenas prácticas de diagnóstico

### IBM API Connect Log Reader Agent
Archivo: `log-readers/ibm-apiconnect-log-reader-agent.md`

- Especializado en logs de IBM API Connect y DataPower
- Analiza fallas en políticas, OAuth, JWT, timeouts, TLS y errores de backend
- Incluye referencias para API Gateway y API Manager

### OpenShift Log Reader Agent
Archivo: `log-readers/openshift-log-reader-agent.md`

- Diseñado para análisis de logs en Red Hat OpenShift
- Considera errores de pods, SCC, ImagePullBackOff, CrashLoopBackOff, eventos del namespace y scheduling
- Enfocado en diagnóstico operativo de infraestructura Kubernetes/OCP

### Windows Server Event Log Reader Agent
Archivo: `log-readers/windows-server-eventlog-reader-agent.md`

- Revisa eventos del Event Log de Windows Server
- Analiza System, Application, Security y fuentes de eventos de servicios
- Es útil para incidentes de sistema, servicios, seguridad y crashes de aplicaciones

### Ejemplo de reporte Quarkus
Archivo: `log-readers/ejemplo-reporte-quarkus-log-reader.md`

- Ejemplo realista de cómo se ve un análisis final de un log de Quarkus
- Sirve como referencia para el formato y nivel de detalle esperado en un reporte

## Principales características de estos agentes

Cada agente incluye:

- propósito y alcance tecnológico
- reglas para no asumir contexto sin evidencia
- clasificación de severidades y tipos de fallo
- manejo de datos sensibles y confidenciales
- guía de análisis técnica
- formato de reporte final
- preguntas para aclarar contexto faltante

## Uso recomendado

Estos documentos pueden utilizarse como:

1. base para construir agentes de IA o asistentes especializados
2. referencia operativa para analistas de soporte técnico
3. guía de diagnóstico para equipos de desarrollo, QA y operaciones
4. plantilla de reportes para incidentes de producción

## Convención de trabajo

Los artefactos del repositorio están orientados a:

- mantener análisis estructurado
- separar hipótesis de diagnóstico confirmado
- resaltar información sensible sin ocultarla
- aportar próximos pasos específicos para la resolución

## Nota importante

Los archivos del repositorio contienen ejemplos y reglas de interpretación reales para entornos empresariales. En caso de trabajar con logs de producción, se recomienda revisar cuidadosamente los datos sensibles antes de compartirlos fuera del entorno seguro correspondiente.

## Requisitos

No se requiere una aplicación ni un framework de ejecución para este repositorio, ya que es una biblioteca/documentación de plantillas de análisis. El uso principal es como base para agentes, prompts o guías de diagnóstico.

## Mantenimiento

Este repositorio puede ampliarse con nuevos perfiles de agentes, por ejemplo:

- logs de Kafka
- logs de PostgreSQL / Oracle / SQL Server
- logs de Spring Boot
- logs de nginx / Apache / Tomcat
- logs de Azure / AWS / GCP
- agentes para monitorización y SRE

---

Si quieres, también puedo dejarte una versión más formal de este README para GitHub, con badges, secciones de instalación, uso y referencias técnicas más profesionales.
