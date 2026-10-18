---
name: log-analyzer-ibm-api-connect
description: "Analiza logs de IBM API Connect (DataPower Gateway, API Manager, Developer Portal, Analytics) y produce un diagnóstico estructurado. Úsalo cuando el log contenga DataPower, códigos 0x00d3XXXX, headers X-IBM-Client-Id/X-IBM-Client-Secret, o menciones de assembly, catalog, gateway service."
---

# Log Reader — IBM API Connect

## Señales de detección
`DataPower`, códigos `0x00d3XXXX`, headers `X-IBM-Client-Id`/`X-IBM-Client-Secret`, mención de "assembly", "catalog", "gateway service".

## Preguntar antes de analizar

| Situación | Pregunta |
|---|---|
| Origen no claro | ¿Gateway (DataPower) o API Manager? Cambia completamente el diagnóstico |
| Versión no declarada | ¿v5 o v10? |
| Despliegue no claro | ¿Cloud-native (k8s/OpenShift) o on-premises? |
| Mecanismo de auth no declarado | ¿OAuth 2.0, API Key, Basic Auth, otro? |
| Sin transaction-id/correlation-id | Necesario para rastrear el flujo de punta a punta |
| Entorno no declarado | ¿DEV, QA, STAGING o PROD? |
| Assembly/política sin identificar | ¿Tienes la definición del assembly en API Manager? |
| Backend no visible | ¿Cuál es la URL del backend al que conecta el gateway? |

## Datos sensibles a marcar en rojo

`X-IBM-Client-Id`/`X-IBM-Client-Secret`, `client_id`/`client_secret`, `access_token`/`refresh_token`/`id_token`, JWTs (`eyJ...\.eyJ...\....`), `Authorization: Basic/Bearer`, credenciales de backend logueadas por `activity-log`, `<Password>`/`<APIKey>` en config DataPower, correlation IDs de PROD, PII en request/response si `activity-log` captura body completo.

**Riesgo de configuración:** política `activity-log` con `content: payload` o `content: all` captura headers y bodies completos — señalarlo fuera de DEV y recomendar `content: activity` en producción.

## Severidad DataPower

`emerg`/`alert`(FATAL) > `critic`(CRITICAL) > `error`(ERROR) > `warn`(WARNING) > `notice`(INFO+) > `info`(INFO) > `debug`(DEBUG).

## Patrones de error frecuentes

`0x00d30003` → fallo de ejecución de una política del assembly, identificar cuál (`validate`, `invoke`, `map`, etc.). `0x00d30004` → error de assembly completo, encadena con `0x00d30003`. OAuth (`token expired`/`invalid_token`/`insufficient_scope`) → TTL, configuración del provider, scopes del plan. `JWT validation failed` → política `jwt-validate`, clave pública/JWKS, claims. HTTP 502/503 desde gateway → backend no disponible, revisar `invoke` y health del backend. `connect timeout`/`read timeout` → timeout en `invoke`, latencia del backend. `TLS/SSL handshake failed` → certificados, cipher suites, TLS mínimo. `rate limit exceeded`/`quota exceeded` → plan asignado en API Manager. `parse-variable policy failure` → Content-Type vs payload esperado. `map policy failure` → variable de contexto null o tipo incorrecto. `CORS policy error` → origen no permitido o headers faltantes. `API not found`/404 desde gateway → base path, catálogo, estado de publicación.

**Operador Kubernetes v10:** `Reconciliation failed` → componente APIC no está en estado deseado. `DataPowerService not ready: N/M pods running` → réplicas degradadas. `Certificate expired` → renovar vía `apicops` o cert-manager.

## v5 vs v10

v5: logs de texto plano, errores de assembly fragmentados en múltiples líneas, sin operador Kubernetes. v10: JSON estructurado, logs del operador `ibm-apiconnect`; pods DataPower mantienen formato clásico.

## Formato de reporte estándar

```
╔══════════════════════════════════════════════════════════════╗
║   REPORTE DE ANÁLISIS DE LOG — IBM API CONNECT                ║
╚══════════════════════════════════════════════════════════════╝
📋 RESUMEN EJECUTIVO
Tecnología: IBM API Connect [v5|v10] / DataPower
Entorno: [DEV/QA/STAGING/PROD/No declarado]
Componente(s): [gateway/API manager/portal]
Período log: [inicio] → [fin]
Total eventos: [N críticos] | [N warnings] | [N notables]
Diagnóstico breve: [1-2 frases]

🔴 HALLAZGOS CRÍTICOS / 🟡 ADVERTENCIAS / 🔵 EVENTOS NOTABLES
⚠️ DATOS SENSIBLES: Valor: <span style="color:red;font-weight:bold">valor</span>
❓ PREGUNTAS ABIERTAS / 🛠️ PRÓXIMOS PASOS
📤 ¿Deseas el reporte como documento entregable?
```

## Referencias
- https://www.ibm.com/docs/en/api-connect
- https://www.ibm.com/docs/en/api-connect/10.0.x?topic=troubleshooting
- https://www.ibm.com/docs/en/datapower-gateway
- https://www.ibm.com/docs/en/api-connect/10.0.x?topic=policies
- https://github.com/ibm-apiconnect/apicops
