# Referencia: SRE / Monitorización (alertas, SLO, incidentes)

Este dominio es distinto a los demás: opera sobre **métricas y alertas**, no sobre logs de aplicación (aunque puede complementarse con ellos). El enfoque es el de un SRE: triage, mitigación primero, causa raíz después, y gestión de error budget.

## Alcance

Métricas/alertas: Prometheus, Grafana, AlertManager, Thanos, Mimir, VictoriaMetrics. Incidentes: PagerDuty, OpsGenie, Incident.io, FireHydrant. APM/trazas: Datadog, New Relic, Dynatrace, Elastic APM, Jaeger, Zipkin. Logging centralizado: ELK/OpenSearch, Loki, Splunk. Synthetic: Pingdom, Checkly. Kubernetes: kube-state-metrics, node-exporter, cAdvisor. SLO: Sloth, OpenSLO, Pyrra, Nobl9.

Formato regla Prometheus: `alert:`, `expr:`, `for:`, `labels: {severity, team}`, `annotations: {summary, description, runbook_url}`. Notificación PagerDuty/OpsGenie: `[ALERT FIRING] [P1] nombre — Service: X | Namespace: Y`, `Severity:`, `Duration:`, `Summary:`, `Runbook:`, `Starts At:`, `Labels:`.

## Preguntar antes de interpretar

| Situación | Pregunta |
|---|---|
| Stack no identificado | ¿Qué herramienta generó la alerta? (Prometheus/Grafana, Datadog, New Relic, Dynatrace...) |
| Entorno no declarado | ¿DEV, QA, STAGING o PROD? |
| Expresión PromQL no disponible | ¿Puedes compartir la regla completa? Los umbrales cambian la interpretación |
| Contexto de negocio no claro | ¿Cuál es la función del servicio afectado? ¿Está en el critical path? |
| Firing sin logs asociados | ¿Tienes logs del servicio para el mismo período? |
| SLO/SLI no definido | ¿Existe un SLO para este servicio? ¿Qué nivel está comprometido? |
| Alerta recurrente sin historial | ¿Es nueva o recurrente? ¿Con qué frecuencia? ¿Se resolvió o silenció antes? |
| On-call no claro | ¿Quién es el responsable? ¿Hay runbook vinculado? |
| Posible deployment reciente | ¿Hubo deployment/cambio de config/infra en los 30-60 min previos? |

## Datos sensibles específicos

Labels de métricas con PII (`user_id`, `email`, `customer_id`); URLs de runbooks internos; IDs de dashboards/organizaciones de Grafana; tokens de integración (PagerDuty Integration Keys, Slack Webhook URLs, OpsGenie API Keys); nombres de servicios que revelan arquitectura interna; endpoints de scrape targets con IPs/hosts internos; datos en spans de APM (IDs de transacción, datos de usuario, queries completas).

## Categorías de alertas e impacto

SLO/error budget burn (crítico — puede agotar budget en 1h) · Latency (p99 alto, puede no verse en error rate) · Error rate (impacto directo en usuarios) · Saturation (CPU/mem/disk cerca del límite) · Availability (health check down — impacto máximo) · Throughput drop (puede ser normal o síntoma de error upstream) · Infraestructura (Node NotReady, CrashLoopBackOff) · Business metrics (orders/min, payment failure rate).

## SLO / Error Budget

SLI = métrica que mide cumplimiento. SLO = target del SLI. Error Budget = 100%-SLO. Burn Rate = velocidad de consumo (fast burn 1h ≈14.4x, slow burn 6h ≈6x, ticket 3d ≈1x). Al analizar una alerta de error budget: calcula el tiempo restante hasta agotar el budget al ritmo actual, evalúa si se justifica escalar (pager) o es tolerable como ticket, y recomienda la acción mínima para bajar el burn rate.

## Patrones y causas

Error rate spike + deployment reciente → rollback primero, RCA después. Error rate spike sin deployment → dependencia externa caída, pico de tráfico, o saturación. Latencia p99 alta sin más errores → saturación CPU/mem, GC pauses, slow queries. Saturation sin degradación → spike normal o proceso de background. Health check down + CrashLoopBackOff → revisar `logs --previous`/logs de arranque. Disk >80% en nodos → logs sin rotar, datos sin limpiar. Múltiples servicios cayendo a la vez → dependencia compartida (BD, broker, auth). Throughput drop sin errores → upstream caído o problema de red.

## Framework de respuesta a incidentes

```
FASE 1 — Detección y triage (5 min): confirmar impacto real en SLO, estimar alcance,
         ver si hay deployment reciente, asignar severidad y escalar
FASE 2 — Mitigación (prioridad sobre diagnóstico): rollback si aplica, escalar
         capacidad si es saturación, failover si hay región/instancia caída
FASE 3 — Diagnóstico (mientras se estabiliza): correlacionar métricas/logs/trazas,
         identificar causa raíz real (no solo el síntoma)
FASE 4 — Resolución y seguimiento: confirmar recuperación del SLO, cerrar con
         causa raíz documentada, programar postmortem
```

**En un incidente activo, la primera recomendación siempre es cómo restaurar el servicio, no cómo encontrar la causa raíz.** No recomiendes rollback sin antes intentar verificar que hay un deployment reciente relacionado. No recomiendes silenciar (`mute`) alertas activas como solución — solo resolver la causa o actualizar el umbral intencionalmente. No desestimes alertas de warning — un slow burn puede agotar el error budget en días.

## Estructura del análisis SRE (aplícala en el reporte)

```
1. TRIAJE → impacto real para el usuario (¿SLO comprometido?)
2. CORRELACIÓN → otros síntomas (alertas, deployments, cambios)
3. HIPÓTESIS → causa más probable según métricas disponibles
4. EVIDENCIA → qué métrica/log/traza confirmaría la hipótesis
5. REMEDIACIÓN → acción más rápida para restaurar el servicio
6. SEGUIMIENTO → cambio permanente que previene la recurrencia
```

Cuando uses el formato de reporte estándar del skill, agrega bajo "Hallazgos críticos" el estado del SLO/error budget (SLI actual, budget consumido/restante, burn rate, recomendación) y, en "Próximos pasos", separa explícitamente en INMEDIATO / CORTO PLAZO / SEGUIMIENTO siguiendo las 4 fases de arriba.

## Referencias

- Google SRE Book: https://sre.google/sre-book/table-of-contents/
- Google SRE Workbook: https://sre.google/workbook/table-of-contents/
- Prometheus Alerting: https://prometheus.io/docs/alerting/latest/overview/
- AlertManager: https://prometheus.io/docs/alerting/latest/alertmanager/
- Grafana Alerting: https://grafana.com/docs/grafana/latest/alerting/
- Error Budget y SLOs: https://sre.google/workbook/alerting-on-slos/
- Sloth: https://sloth.dev/ · OpenSLO: https://openslo.com/
- Incident management: https://sre.google/workbook/incident-response/
- Postmortem templates: https://github.com/dastergon/postmortem-templates
