# ia-tools

Una colección de **skills y agentes de contexto** para usar con distintos harnesses de IA: Claude Code, Codex u otros agentes compatibles con el estándar abierto [Agent Skills](https://agentskills.io), y de forma manual en ChatGPT (que no tiene un mecanismo nativo de carga de skills).

Cada skill vive en `skills/<nombre>/SKILL.md`: instrucciones que el modelo carga automáticamente cuando la conversación lo amerita, o que puedas invocar a mano con `/nombre`. El contenido de referencia largo por tema queda en `skills/<nombre>/references/`, para no cargarlo todo de una.

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

**Invocables por el modelo** (se activan solos cuando la conversación matchea su `description`, o los invocas con `/nombre`):

- **[log-reader](./skills/log-reader/SKILL.md)**: analiza logs pegados o adjuntos de once stacks técnicos distintos (Windows Event Log, servidores web, Spring Boot, Quarkus, .NET, bases de datos, Kafka, OpenShift, IBM API Connect, nube, SRE/monitorización), detecta la tecnología automáticamente, pregunta el contexto que no puede inferir, y produce un reporte de diagnóstico estandarizado sin ocultar datos sensibles. Doc para humanos: [docs/log-reader.md](./docs/log-reader.md).

## Agentes

`agents/` está reservado para subagentes de Claude Code (roles independientes con su propio hilo de ejecución), distintos de los skills de arriba. Hoy está vacío; ver [agents/README.md](./agents/README.md) para el formato esperado cuando se agregue el primero.

## Convenciones del repo

Ver [CLAUDE.md](./CLAUDE.md) (también accesible como `AGENTS.md`) para las reglas de organización: cuándo algo va en `skills/` vs `agents/`, cuándo introducir subcarpetas de categoría dentro de `skills/`, y el checklist para agregar un skill nuevo.

## Licencia

[MIT](./LICENSE)
