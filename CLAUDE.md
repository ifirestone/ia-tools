# Convenciones de ia-tools

Este repo es una colección de **skills y agentes de contexto** pensada para instalarse en distintos harnesses de IA (Claude Code, Codex, cualquier agente compatible con el estándar abierto [Agent Skills](https://agentskills.io), y de forma manual en ChatGPT). Estas son las reglas para mantenerlo consistente.

## Idioma

Todo el contenido del repo va en español: `README.md`, este archivo, `docs/`, cada `SKILL.md` y sus referencias. No mezclar idiomas dentro de un mismo archivo.

## `skills/` vs `agents/`

- `skills/<skill>/SKILL.md`: instrucciones reusables para una tarea. Se invocan con `/nombre` o el modelo las carga solo cuando el `description` del frontmatter matchea la conversación. El contenido de referencia largo (guías por tecnología, checklists extensas) va en `skills/<skill>/references/`, no en el `SKILL.md` principal, para no cargarlo todo de una.
- `agents/<nombre>.md`: subagentes de Claude Code, roles independientes con su propio hilo, herramientas permitidas y modelo. Ver [`agents/README.md`](agents/README.md).

No dupliques contenido entre ambas carpetas: si algo es una guía de referencia, va en `skills/<skill>/references/`, aunque el nombre "agente" se use coloquialmente para describirla.

## Buckets dentro de `skills/`

Hoy `skills/` no tiene subcarpetas de categoría (`engineering/`, `operaciones/`, etc.): con un solo skill, esas carpetas estarían vacías por adelantado. Crea una carpeta de categoría recién cuando haya **varios** skills que compartan ese tipo de trabajo, y en ese momento:

- Mover los skills existentes que encajen a la carpeta nueva.
- Cada carpeta de categoría lleva su propio `README.md` listando sus skills.
- El `README.md` de la raíz sigue enlazando a cada skill individualmente.

## Frontmatter de `SKILL.md`

Preferí siempre el subconjunto portable del estándar Agent Skills: `name`, `description`, `license`, `compatibility`, `metadata`, `allowed-tools`. Ese subconjunto es el que funciona igual dentro y fuera de Claude Code (Codex, uploads directos a claude.ai, la Skills API). Si necesitas un campo exclusivo de Claude Code (`disable-model-invocation`, `context: fork`, `paths`, etc.), documenta en el propio `SKILL.md` que ese skill pierde portabilidad y por qué hace falta.

## Checklist al agregar un skill nuevo

1. `skills/<skill>/SKILL.md` con frontmatter mínimo `name` + `description`.
2. Si necesita contenido largo, `skills/<skill>/references/*.md`, cargado solo cuando aplique.
3. Entrada en el listado de skills de `README.md`, enlazando al `SKILL.md`.
4. Página en `docs/<skill>.md` con las cuatro secciones: Qué hace / Cuándo usarlo / Preguntas frecuentes / Cómo saber que funciona.
5. Si el skill declara herramientas o metadata específicas del plugin, revisar que `.claude-plugin/plugin.json` siga siendo válido.

## Después de tocar `.claude-plugin/`

Correr `claude plugin validate . --strict` desde la raíz antes de dar el cambio por terminado.
