# agents/

Esta carpeta contiene **subagentes de Claude Code**: roles autónomos y delegables, con su propio frontmatter (`name`, `description`, `tools`, `model`, etc.) y su propio hilo de ejecución. Se delegan mediante la herramienta `Agent`; no se invocan como skills con `/nombre`.

Es distinta de [`skills/`](../skills/), que contiene instrucciones que se cargan en el hilo principal (o en un subagente forkeado) para guiar una tarea concreta, invocables por `/nombre` o automáticamente por el modelo.

## Agentes actuales

- [`iron-comunications.md`](./iron-comunications.md): comunicaciones corporativas internas y externas.
- [`iron-meetings.md`](./iron-meetings.md): elaboración de minutas fieles a notas y transcripciones.
- [`iron-task-manager.md`](./iron-task-manager.md): decisiones, tareas, riesgos y minutas accionables.
- [`iron-translator.md`](./iron-translator.md): traducción, corrección, tono y aprendizaje de idiomas.

## Cómo elegir

- Una **guía reutilizable para una tarea concreta** va en `skills/<skill>/SKILL.md`; el material de referencia extenso va en `skills/<skill>/references/`.
- Un **rol autónomo que conviene delegar en un contexto independiente** va en `agents/<nombre>.md`.

## Formato

El frontmatter define la identidad y configuración del subagente. El cuerpo describe su rol, alcance, instrucciones y formato de respuesta. Si incluye solicitudes de ejemplo, se pueden agrupar con las etiquetas `<prompts>`, `<prompt nombre="...">` y `<solicitud>`.

```markdown
---
name: nombre-del-agente
description: Cuándo delegar en este agente (el modelo lo usa para decidir)
tools: []
model: inherit
---

Instrucciones del rol: qué hace, cuál es su alcance y qué debe devolver.

<prompts>
	<prompt nombre="Ejemplo">
		<solicitud>Solicitud de ejemplo.</solicitud>
	</prompt>
</prompts>
```

Ver la referencia completa de campos de frontmatter en la documentación de Claude Code: [Subagents](https://code.claude.com/docs/en/sub-agents).
