# log-reader

## Qué hace

`log-reader` es un skill de análisis de logs que reemplaza a un conjunto de agentes especializados (uno por tecnología) por un único flujo. Cuando se le pega o adjunta un log, stack trace, evento de Windows o alerta de monitorización:

1. Detecta automáticamente la tecnología a partir de patrones en el propio texto (Windows Event Log, nginx/Apache/Tomcat/IIS, Spring Boot, Quarkus, .NET/C#, PHP, Laravel, bases de datos, Kafka, Docker, Kubernetes/OpenShift, IBM API Connect, MinIO, Azure/AWS/GCP, o alertas SRE).
2. Si hay ambigüedad, pregunta antes de analizar en vez de adivinar.
3. Carga únicamente la guía de referencia de esa tecnología (`skills/log-reader/references/<tecnologia>.md`), no las 11 de una vez.
4. Pregunta el contexto que no se puede inferir del texto (entorno, versión, rol del componente, si el log está truncado).
5. Produce un reporte técnico estandarizado, con datos sensibles marcados en rojo en vez de ocultos.

Ver el flujo completo en [`skills/log-reader/SKILL.md`](../skills/log-reader/SKILL.md).

## Cuándo usarlo

Se activa solo, sin necesidad de invocarlo con `/log-reader`, cada vez que en la conversación aparece:

- Un log pegado o adjunto de cualquiera de las tecnologías cubiertas.
- Un stack trace o excepción.
- Un evento de Windows Event Log.
- Una alerta de Prometheus/AlertManager/Grafana/PagerDuty.
- Una pregunta del tipo "¿qué significa este error?", "¿por qué falla este servicio/pod/aplicación?", aunque no se mencione la tecnología explícitamente.

No hace falta decir de antemano de qué tecnología es el log: el propio skill lo detecta o pregunta si hay ambigüedad real.

## Preguntas frecuentes

**¿Por qué pregunta tanto antes de dar un diagnóstico?**
Porque la mayoría de estos logs son ambiguos sin saber el entorno (DEV/QA/PROD), la versión o el rol del servidor. Un mismo síntoma tiene remediaciones muy distintas según ese contexto, así que el skill se niega a asumirlo.

**¿Oculta contraseñas, tokens u otros datos sensibles del reporte?**
No los oculta ni los enmascara: los marca visualmente en rojo (`<span style="color:red; font-weight:bold">valor</span>`) porque son necesarios para depurar. Quien recibe el reporte decide si lo comparte fuera del equipo.

**¿Qué pasa si el log mezcla dos tecnologías (por ejemplo, Spring Boot corriendo dentro de OpenShift)?**
Analiza ambas capas usando ambas referencias y lo indica explícitamente en el resumen ejecutivo del reporte.

**¿Qué pasa si dos tecnologías podrían encajar con el fragmento pegado?**
No adivina: pregunta explícitamente, ofreciendo las tecnologías candidatas ordenadas por probabilidad más la opción "otra / no estoy seguro".

## Cómo saber que funciona

- Al pegar un log real de cualquiera de las tecnologías cubiertas, el skill identifica la tecnología (o pregunta si es ambigua) antes de analizar nada.
- El reporte final sigue siempre el mismo formato de secciones (resumen ejecutivo, hallazgos críticos, advertencias, eventos informativos, datos sensibles, preguntas abiertas, próximos pasos, pregunta de cierre), sin omitir ninguna aunque esté vacía.
- Si falta contexto obligatorio (entorno, versión, rol del componente), el skill pregunta antes de diagnosticar en vez de inventarlo.
- Cualquier credencial, token o dato sensible detectado aparece marcado en rojo en el reporte, nunca oculto.
