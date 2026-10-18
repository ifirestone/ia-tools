# Política de seguridad

## Alcance

Este repo contiene instrucciones en Markdown (skills y agentes), un script de shell ([`scripts/link-skills.sh`](./scripts/link-skills.sh)) y la configuración del plugin de Claude Code (`.claude-plugin/`). No incluye servicios, dependencias de runtime ni credenciales.

Se considera un problema de seguridad, por ejemplo:

- Un skill o agente con instrucciones que induzcan al modelo a exfiltrar datos, ejecutar comandos peligrosos sin confirmación o saltarse los permisos del harness.
- Un fallo en `scripts/link-skills.sh` que pueda borrar o sobrescribir archivos fuera de `~/.claude/skills` y `~/.agents/skills`.
- Credenciales, datos personales o información interna de terceros publicados por error en el repo.

## Cómo reportar una vulnerabilidad

No abras un issue público. Usa el reporte privado de GitHub: pestaña **Security** → **Report a vulnerability** en [ifirestone/ia-tools](https://github.com/ifirestone/ia-tools/security/advisories/new).

Incluye qué archivo está afectado, cómo reproducirlo y el impacto que ves. Es un proyecto personal mantenido sin SLA formal, pero se intenta responder en pocos días y publicar la corrección antes de divulgar el detalle.

Solo se da soporte a la última versión de la rama `master`.

## Uso seguro de los skills

- **Revisa antes de instalar.** Un skill o agente son instrucciones que el modelo sigue con los permisos de tu harness. Lee el `SKILL.md` (y `references/`) de cualquier skill de terceros antes de activarlo, incluidos los de este repo.
- **Los logs son datos sensibles.** `log-analyzer` y sus variantes no ocultan ni enmascaran credenciales, tokens ni PII: los marcan en rojo en el reporte para que se vean y se puedan rotar. Esto implica que:
  - El reporte puede contener esos valores en claro; no lo compartas fuera del equipo sin revisarlo.
  - Si un secreto aparece en un log, trátalo como comprometido y rótalo.
  - Antes de pegar un log de producción en una herramienta de IA externa (por ejemplo, ChatGPT), comprueba que tu organización lo permita y considera sanitizarlo.
- **El script de instalación** crea symlinks en `~/.claude/skills` y `~/.agents/skills`, y reemplaza cualquier carpeta existente con el mismo nombre de skill. Revísalo antes de ejecutarlo si ya tienes skills propios con esos nombres.

## Contribuciones

No incluyas en issues, PRs ni ejemplos credenciales, logs reales de producción, nombres de personas o información interna de una empresa. Usa datos ficticios.
