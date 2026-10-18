---
name: log-analyzer-sre
description: "Analiza alertas y métricas de SRE/monitorización (Prometheus, Grafana, AlertManager, PagerDuty, OpsGenie, Datadog, New Relic, SLO/error budget) y produce un diagnóstico estructurado. Úsalo cuando el texto contenga reglas PromQL (expr:, for:), alertas de AlertManager/Grafana, notificaciones PagerDuty/OpsGenie ([ALERT FIRING], severity:), o lenguaje de SLO/error budget/burn rate."
---

# Log Reader — SRE / Monitorización

Este dominio opera sobre **métricas y alertas**, no sobre logs de aplicación. El enfoque es el de un SRE: triage, mitigación primero, causa raíz después, gestión de error budget.

## Señales de detección
Reglas PromQL (`expr:`, `for:`), alertas de AlertManager/Grafana, notificaciones PagerDuty/OpsGenie (`[ALERT FIRING]`, `severity:`), lenguaje de SLO/error budget/burn rate.

## Preguntar antes de analizar

| Situación | Pregunta |
|---|---|
| Stack no identificado | ¿Qué herramienta generó la alerta? (Prometheus/Grafana, Datadog, New Relic, Dynatrace...) |
| Entorno no declarado | ¿DEV, QA, STAGING o PROD? |
| Expresión PromQL no disponible | ¿Puedes compartir la regla completa? Los umbrales cambian la interpretación |
| Contexto de negocio no claro | ¿Cuál es la función del servicio? ¿Está en el critical path? |
| SLO/SLI no definido | ¿Existe un SLO para este servicio? ¿Qué nivel está comprometido? |
| Alerta recurrente sin historial | ¿Es nueva o recurrente? ¿Se resolvió o silenció antes? |
| Posible deployment reciente | ¿Hubo deployment/cambio de config en los 30-60 min previos? |

## Datos sensibles a marcar en rojo

Labels de métricas con PII (`user_id`, `email`, `customer_id`), URLs de runbooks internos, tokens de integración (PagerDuty Integration Keys, Slack Webhook URLs, OpsGenie API Keys), nombres de servicios que revelan arquitectura interna, endpoints de scrape targets con IPs/hosts internos.

## SLO / Error Budget

SLI = métrica de cumplimiento. SLO = target. Error Budget = 100%–SLO. Burn Rate: fast burn 1h ≈14.4x, slow burn 6h ≈6x, ticket 3d ≈1x. Calcula el tiempo restante hasta agotar el budget al ritmo actual; evalúa si justifica escalar (pager) o es tolerable como ticket.

## Patrones y causas

Error rate spike + deployment reciente → rollback primero. Sin deployment → dependencia caída, pico de tráfico, o saturación. Latencia p99 alta sin errores → GC pauses, slow queries, saturación. Saturation sin degradación → proceso de background. Health check down + CrashLoopBackOff → revisar `logs --previous`. Múltiples servicios cayendo → dependencia compartida (BD, broker, auth). Throughput drop sin errores → upstream caído.

## Framework de respuesta a incidentes

FASE 1 — Triage (5 min): confirmar impacto en SLO, ver si hay deployment reciente, escalar.
FASE 2 — Mitigación (primero): rollback si aplica, escalar capacidad si saturación, failover.
FASE 3 — Diagnóstico (mientras se estabiliza): correlacionar métricas/logs/trazas.
FASE 4 — Resolución: confirmar recuperación del SLO, programar postmortem.

**En un incidente activo, la primera recomendación siempre es cómo restaurar el servicio.** No recomendar silenciar (`mute`) alertas activas — solo resolver la causa o actualizar el umbral.

## Estructura del análisis SRE

1. TRIAJE → ¿SLO comprometido? 2. CORRELACIÓN → alertas/deployments. 3. HIPÓTESIS → causa probable. 4. EVIDENCIA → métrica/log/traza confirmatoria. 5. REMEDIACIÓN → restaurar el servicio. 6. SEGUIMIENTO → prevenir la recurrencia.

## Formato de reporte estándar

```
╔══════════════════════════════════════════════════════════════╗
║   REPORTE DE ANÁLISIS — SRE / MONITORIZACIÓN                  ║
╚══════════════════════════════════════════════════════════════╝
📋 RESUMEN EJECUTIVO
Stack: [Prometheus|Grafana|Datadog|...] | Entorno: [DEV/QA/STAGING/PROD]
Servicio: [nombre + función] | Período: [inicio] → [fin]
SLO/SLI: [valor] / [target] — Budget consumido: [X%] — Burn rate: [Nx]
Diagnóstico breve: [1-2 frases]

🔴 HALLAZGOS CRÍTICOS (estado SLO/error budget, burn rate, recomendación)
🟡 ADVERTENCIAS / 🔵 EVENTOS NOTABLES
⚠️ DATOS SENSIBLES: <span style="color:red;font-weight:bold">valor</span>
❓ PREGUNTAS ABIERTAS

🛠️ PRÓXIMOS PASOS
  INMEDIATO: [restaurar] | CORTO PLAZO: [mitigar] | SEGUIMIENTO: [postmortem]

📤 ¿Deseas el reporte como documento entregable?
```

## Referencias
- https://sre.google/sre-book/table-of-contents/
- https://sre.google/workbook/alerting-on-slos/
- https://prometheus.io/docs/alerting/latest/overview/
- https://grafana.com/docs/grafana/latest/alerting/
- https://sre.google/workbook/incident-response/
