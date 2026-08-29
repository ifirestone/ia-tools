# agents/

Esta carpeta es para **subagentes de Claude Code**: roles autónomos y delegables, con su propio frontmatter (`name`, `description`, `tools`, `model`, etc.) y su propio hilo de ejecución. Se invocan con la herramienta `Agent`/`@nombre-del-agente`, no con `/nombre`.

Es distinta de [`skills/`](../skills/), que contiene instrucciones que se cargan en el hilo principal (o en un subagente forkeado) para guiar una tarea concreta, invocables por `/nombre` o automáticamente por el modelo.

Regla práctica para decidir dónde va algo nuevo:

- Si es una **guía de referencia larga** para un tipo de tarea (cómo interpretar logs de Kafka, cómo hacer code review, etc.) → va dentro de `skills/<skill>/references/`, cargada solo cuando el skill la necesita.
- Si es un **rol independiente** que conviene correr en su propio contexto, con su propia lista de herramientas permitidas y posiblemente su propio modelo → va acá, como `agents/<nombre>.md`.

Hoy esta carpeta está vacía: los 11 documentos de análisis de logs que vivían acá (`agents/log-readers/`) eran en realidad guías de referencia, no roles independientes, así que se consolidaron en [`skills/log-reader/references/`](../skills/log-reader/references/) y el propio `agents/log-readers/` se borró por quedar duplicado.

## Formato esperado

```markdown
---
name: nombre-del-agente
description: Cuándo delegar en este agente (el modelo lo usa para decidir)
tools: Read, Grep, Glob
model: inherit
---

Instrucciones del rol: qué hace este agente, con qué alcance, y qué debe devolver.
```

Ver la referencia completa de campos de frontmatter en la documentación de Claude Code: [Subagents](https://code.claude.com/docs/en/sub-agents).
