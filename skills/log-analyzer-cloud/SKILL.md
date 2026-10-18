---
name: log-analyzer-cloud
description: "Analiza logs de nube pública (Azure, AWS, GCP) y produce un diagnóstico estructurado. Úsalo cuando el log contenga ARNs (arn:aws:...), AKIA..., CloudWatch/CloudTrail/Lambda REQUEST ID, AADSTS (Azure), Application Insights JSON (severityLevel/customDimensions), o GCP jsonPayload/resource.type."
---

# Log Reader — Cloud (Azure / AWS / GCP)

**Diferencia siempre el proveedor primero — terminología, servicios y formatos son incompatibles entre sí.**

## Señales de detección
- AWS: ARNs (`arn:aws:...`), `AKIA...`, CloudWatch/CloudTrail/Lambda `REQUEST ID`.
- Azure: `AADSTS`, Application Insights JSON (`severityLevel`, `customDimensions`).
- GCP: `jsonPayload`, `resource.type`, Cloud Run/GKE.

## Preguntar antes de analizar

| Situación | Pregunta |
|---|---|
| Proveedor no identificado | ¿Azure, AWS o GCP? Servicios, formatos y terminología son distintos |
| Servicio específico no claro | ¿Qué servicio generó el log? (App Service, Lambda, Cloud Run, etc.) |
| Entorno no declarado | ¿DEV, QA, STAGING o PROD? |
| Log de auditoría sin contexto | ¿Qué operación/despliegue precedió estos eventos? |
| Error de IAM sin política | ¿Tienes las políticas IAM/RBAC del servicio o usuario? |
| Recursos por ID sin nombre | ¿Puedes dar el nombre/alias del recurso? |

## Datos sensibles a marcar en rojo

ARNs/Resource IDs (revelan cuentas, regiones, recursos), Access Key IDs (`AKIA...`) en CloudTrail, tokens de acceso Azure/GCP, connection strings en logs de diagnóstico, IPs privadas en VPC Flow Logs, PII en logs de aplicación, Tenant/Subscription IDs (Azure), Account IDs (AWS — usados en enumeración), Project IDs (GCP), Service Account emails GCP.

**Alerta especial:** si aparece una Access Key de AWS expuesta, señalar que debe verificarse si fue comprometida y considerar rotación inmediata.

## Azure — patrones frecuentes

`AuthorizationFailed`/403 → falta rol RBAC. `Container didn't respond to HTTP pings on port X` → verificar `PORT` env var. `ForbiddenByPolicy` (Key Vault) → Access Policies/RBAC. `AADSTS70011` (invalid scope) → API Permissions del App Registration. `AADSTS50058` (silent sign-in) → flujo interactivo. `MessagingEntityNotFoundException` (Service Bus) → nombre/namespace del recurso.

KQL: `traces | where severityLevel >= 3 | order by timestamp desc`; `SigninLogs | where ResultType != 0`.

## AWS — patrones frecuentes

`AccessDenied`/`UnauthorizedOperation` → revisar políticas IAM. `Task timed out` (Lambda) → aumentar timeout (máx 15 min). `Runtime exited: signal: killed` (Lambda) → OOM, aumentar memoria. `Init Duration` elevado → cold start, Provisioned Concurrency. `CannotPullContainerError` (ECS/Fargate) → credenciales ECR, task role. `max_connections reached` (RDS) → RDS Proxy. 503 en API Gateway → integration timeout.

CloudWatch Insights: `fields @timestamp, @message | filter @message like /ERROR/ | sort @timestamp desc`.

## GCP — patrones frecuentes

`PERMISSION_DENIED`/403 → falta role IAM. `Container failed to start` (Cloud Run) → verificar `PORT` env var. `SQLSTATE[08006]` (Cloud SQL) → Auth Proxy, authorized networks. `RESOURCE_EXHAUSTED` (Pub/Sub) → cuota de mensajes. Apigee `fault.name = "RaiseFault"` → política intencional, revisar el proxy.

Si CloudTrail/Activity Log/Audit Log indica acceso no autorizado o cambios de permisos inesperados → señalar como **urgente** además del diagnóstico técnico.

## Formato de reporte estándar

```
╔══════════════════════════════════════════════════════════════╗
║   REPORTE DE ANÁLISIS DE LOG — CLOUD                          ║
╚══════════════════════════════════════════════════════════════╝
📋 RESUMEN EJECUTIVO
Tecnología: [Azure|AWS|GCP] / Servicio: [...]
Entorno: [DEV/QA/STAGING/PROD/No declarado]
Período log: [inicio] → [fin] | Diagnóstico breve: [1-2 frases]

🔴 HALLAZGOS CRÍTICOS / 🟡 ADVERTENCIAS / 🔵 EVENTOS NOTABLES
⚠️ DATOS SENSIBLES: Valor: <span style="color:red;font-weight:bold">valor</span>
❓ PREGUNTAS ABIERTAS / 🛠️ PRÓXIMOS PASOS
📤 ¿Deseas el reporte como documento entregable?
```

## Referencias
- https://learn.microsoft.com/en-us/azure/azure-monitor/
- https://learn.microsoft.com/en-us/azure/active-directory/develop/reference-aadsts-error-codes
- https://docs.aws.amazon.com/AmazonCloudWatch/latest/logs/AnalyzingLogData.html
- https://docs.aws.amazon.com/lambda/latest/dg/lambda-troubleshooting.html
- https://cloud.google.com/logging/docs
- https://cloud.google.com/run/docs/troubleshooting
