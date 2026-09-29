# ia-tools

Una colección de **skills y agentes de contexto** para usar con distintos harnesses de IA: Claude Code, Codex u otros agentes compatibles con el estándar abierto [Agent Skills](https://agentskills.io), y de forma manual en ChatGPT (que no tiene un mecanismo nativo de carga de skills).

Cada skill vive en `skills/<nombre>/SKILL.md`: instrucciones que el modelo carga automáticamente cuando la conversación coincide con su `description`, o que puedes invocar a mano con `/nombre`. El contenido de referencia largo por tema queda en `skills/<nombre>/references/`, para cargar solo lo necesario.

Los archivos de `agents/` son subagentes de Claude Code: roles independientes con instrucciones y configuración propias. No son skills y no los instala `scripts/link-skills.sh`.

## Instalación

### Claude Code

Como plugin, registrando este repo como su propio marketplace:

```bash
claude plugin marketplace add ifirestone/ia-tools
claude plugin install ia-tools
```

Para probarlo en local sin instalarlo, sin necesidad de un marketplace:

```bash
claude --plugin-dir /ruta/a/ia-tools
```

### Codex y otros harnesses compatibles con Agent Skills

Ejecuta el script incluido, que symlinkea cada skill del repo a `~/.agents/skills` (y de paso a `~/.claude/skills`):

```bash
./scripts/link-skills.sh
```

Como son symlinks hacia este repo, un `git pull` alcanza para tener las skills siempre al día. También puedes copiar a mano la carpeta `skills/<nombre>/` que te interese a donde tu harness espere sus skills.

### ChatGPT

ChatGPT no lee carpetas de skills. Para usar uno de estos skills ahí:

1. Abrí `skills/<nombre>/SKILL.md` y pega su contenido como instrucciones personalizadas de un Proyecto o de un GPT personalizado.
2. Si el skill tiene `references/`, subí esos archivos como archivos de conocimiento del mismo Proyecto/GPT (ChatGPT los busca cuando hacen falta, en vez de cargarlos todos de una).

## Skills

**Invocables por el modelo** (se activan automáticamente cuando la conversación coincide con su `description`, o los invocas con `/nombre`):

- **[log-analyzer](./skills/log-analyzer/SKILL.md)**: detecta la tecnología de un log, solicita el contexto faltante y produce un diagnóstico estandarizado. Usa las referencias específicas en `skills/log-analyzer/references/`. Documentación: [docs/log-analyzer.md](./docs/log-analyzer.md).
- **[log-analyzer-cloud](./skills/log-analyzer-cloud/SKILL.md)**: análisis de logs de Azure, AWS y GCP.
- **[log-analyzer-database](./skills/log-analyzer-database/SKILL.md)**: análisis de PostgreSQL, Oracle y SQL Server.
- **[log-analyzer-docker](./skills/log-analyzer-docker/SKILL.md)**: análisis de Docker Engine, Compose y builds.
- **[log-analyzer-dotnet](./skills/log-analyzer-dotnet/SKILL.md)**: análisis de .NET y C#.
- **[log-analyzer-ibm-api-connect](./skills/log-analyzer-ibm-api-connect/SKILL.md)**: análisis de IBM API Connect y DataPower.
- **[log-analyzer-kafka](./skills/log-analyzer-kafka/SKILL.md)**: análisis de Apache Kafka.
- **[log-analyzer-kubernetes](./skills/log-analyzer-kubernetes/SKILL.md)**: análisis de Kubernetes y OpenShift.
- **[log-analyzer-laravel](./skills/log-analyzer-laravel/SKILL.md)**: análisis de Laravel.
- **[log-analyzer-minio](./skills/log-analyzer-minio/SKILL.md)**: análisis de MinIO y errores compatibles con S3.
- **[log-analyzer-php](./skills/log-analyzer-php/SKILL.md)**: análisis del runtime PHP y php-fpm.
- **[log-analyzer-quarkus](./skills/log-analyzer-quarkus/SKILL.md)**: análisis de Quarkus.
- **[log-analyzer-spring-boot](./skills/log-analyzer-spring-boot/SKILL.md)**: análisis de Spring Boot y Spring Framework.
- **[log-analyzer-sre](./skills/log-analyzer-sre/SKILL.md)**: análisis de alertas y métricas de SRE y monitorización.
- **[log-analyzer-web-server](./skills/log-analyzer-web-server/SKILL.md)**: análisis de nginx, Apache httpd, Tomcat e IIS.
- **[log-analyzer-windows-event-log](./skills/log-analyzer-windows-event-log/SKILL.md)**: análisis de Windows Server Event Log.

## Agentes

Los cuatro archivos de `agents/` definen subagentes de Claude Code, distintos de los skills:

- **[iron-comunications](./agents/iron-comunications.md)**: redacción de comunicaciones corporativas.
- **[iron-meetings](./agents/iron-meetings.md)**: transformación de notas o transcripciones en minutas.
- **[iron-task-manager](./agents/iron-task-manager.md)**: extracción de decisiones, tareas, riesgos y minutas accionables.
- **[iron-translator](./agents/iron-translator.md)**: traducción, corrección, ajuste de tono y práctica de idiomas.

Consulta [agents/README.md](./agents/README.md) para conocer el formato y los criterios para agregar agentes.

## Convenciones del repo

Ver [CLAUDE.md](./CLAUDE.md) (también accesible como `AGENTS.md`) para las reglas de organización: cuándo algo va en `skills/` vs `agents/`, cuándo introducir subcarpetas de categoría dentro de `skills/`, y el checklist para agregar un skill nuevo.

## Licencia

[MIT](./LICENSE)
