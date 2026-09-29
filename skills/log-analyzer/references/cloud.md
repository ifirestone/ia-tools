# Referencia: Cloud (Azure / AWS / GCP)

Diferencia siempre el proveedor primero — terminología, servicios y formatos son incompatibles entre sí.

## Servicios cubiertos

**Azure**: Monitor/Log Analytics (KQL), Application Insights, Activity Log, Diagnostic Logs, Entra ID (sign-in/audit), App Service Logs.
**AWS**: CloudWatch Logs, CloudTrail, VPC Flow Logs, ECS/EKS Logs, Lambda Logs, ALB/NLB Access Logs, RDS Logs.
**GCP**: Cloud Logging (Stackdriver), Cloud Audit Logs, Cloud Run Logs, GKE Logs, Cloud SQL Logs, Cloud Armor Logs.

Formatos representativos:
- Azure App Insights (JSON): `severityLevel`, `type: "exceptions"`, `exceptions[].message`, `customDimensions`.
- AWS CloudWatch/Lambda: `START RequestId: ...` / `ERROR ...` / `END RequestId: ...` / `REPORT ... Duration: ... Billed Duration: ... Memory Size: ... Max Memory Used: ...`.
- GCP Cloud Logging (JSON): `severity`, `resource.type`/`resource.labels`, `jsonPayload`, `httpRequest`.

## Preguntar antes de interpretar

| Situación | Pregunta |
|---|---|
| Proveedor no identificado | ¿Azure, AWS o GCP? Servicios, formatos y terminología son distintos |
| Servicio específico no claro | ¿Qué servicio generó el log? (App Service, Lambda, Cloud Run, etc.) |
| Entorno no declarado | ¿DEV, QA, STAGING o PROD? |
| Log de auditoría (CloudTrail/Activity Log) sin contexto de cambio | ¿Qué operación/despliegue precedió estos eventos? |
| Error de IAM/permisos sin política conocida | ¿Tienes las políticas IAM/RBAC del servicio o usuario? |
| JSON sin servicio identificable | ¿De qué servicio proviene? Los campos clave varían |
| Error de cuotas/límites sin datos de uso | ¿Tienes métricas de uso del servicio? |
| Recursos por ID (ARN/Resource ID) sin nombre | ¿Puedes dar el nombre/alias del recurso? |

## Datos sensibles específicos

ARNs/Resource IDs (revelan cuentas, regiones, recursos); Access Key IDs (`AKIA...`) en CloudTrail; tokens de acceso (Azure/GCP service account tokens); connection strings en logs de diagnóstico; IPs privadas en VPC Flow Logs; PII en logs de aplicación; Tenant/Subscription IDs (Azure); Account IDs (AWS — usados en ataques de enumeración); Project IDs (GCP); Service Account emails (`...@project.iam.gserviceaccount.com`); Managed Identity client IDs (Azure); secrets de Key Vault/Secrets Manager que aparezcan por bug de logging.

Alerta especial: si aparece una Access Key de AWS expuesta en un log, señalar que debe verificarse si fue comprometida y considerar rotación inmediata.

## Azure — patrones frecuentes

`AuthorizationFailed`/403 en Activity Log → falta rol RBAC, revisar asignación de roles. `ANCM In-Process Handler Load Failure` → revisar App Insights, versión del runtime .NET. `Container didn't respond to HTTP pings on port X` → verificar `PORT` env var. `Cannot open database requested by login` (Azure SQL) → estado de la BD, permisos. `ForbiddenByPolicy`/`Forbidden` (Key Vault) → Access Policies/RBAC del vault. `AADSTS70011` (invalid scope) → API Permissions del App Registration. `AADSTS50058` (silent sign-in sin usuario) → flujo interactivo, config de sesión. `MessagingEntityNotFoundException` (Service Bus/Event Hubs) → nombre/namespace del recurso. AKS `Evicted`/`OOMKilled` → resource limits, node pool scaling.

KQL útiles: `traces | where severityLevel >= 3 | order by timestamp desc`; `AzureDiagnostics | where Category == "AppServiceAppLogs"`; `SigninLogs | where ResultType != 0`.

## AWS — patrones frecuentes

`AccessDenied`/`UnauthorizedOperation` → revisar políticas IAM. `Task timed out after N.XX seconds` (Lambda) → aumentar timeout (máx 15 min), optimizar. `Runtime exited with error: signal: killed` (Lambda) → OOM, aumentar memoria. `Init Duration` elevado → cold start, Provisioned Concurrency. `CannotPullContainerError` (ECS/Fargate) → credenciales ECR, task role, red. `max_connections reached` (RDS) → RDS Proxy, pool de la app. `AccessDenied` en bucket policy (S3) → bucket policy + IAM policy, bloqueos de acceso público. 503 en API Gateway → backend no respondió, integration timeout. `UPDATE_ROLLBACK_FAILED` (CloudFormation) → resolver bloqueo manual. `Status check failed` (EC2) → System status = hardware (migrar), Instance status = SO (SSH para diagnóstico).

CloudWatch Insights: `fields @timestamp, @message | filter @message like /ERROR/ | sort @timestamp desc`.

## GCP — patrones frecuentes

`PERMISSION_DENIED`/403 en audit logs → falta role IAM, `gcloud projects add-iam-policy-binding`. `Container failed to start and listen on the port` (Cloud Run) → verificar uso de `PORT` env var. `Request timeout` (deadline exceeded) → aumentar timeout del servicio. `SQLSTATE[08006]: Unable to connect` (Cloud SQL) → Auth Proxy, authorized networks, estado de instancia. `ImagePullBackOff` (GKE) → permisos del SA del nodo, autenticación al registry. `403 Forbidden` (Cloud Storage) → falta `roles/storage.objectViewer`. `RESOURCE_EXHAUSTED` (Pub/Sub) → cuota de mensajes/throughput. Cloud Functions timeout → aumentar timeout (máx 9 min gen1, 60 min gen2). Apigee `fault.name = "RaiseFault"` → política intencional, revisar el proxy.

## Escalamiento de seguridad

Si el log de CloudTrail/Activity Log/Audit Log indica acceso no autorizado a recursos sensibles o cambios de permisos inesperados, señálalo como **urgente** además del diagnóstico técnico — no lo trates solo como un hallazgo técnico más.

## Referencias

- Azure Monitor: https://learn.microsoft.com/en-us/azure/azure-monitor/
- Application Insights: https://learn.microsoft.com/en-us/azure/azure-monitor/app/app-insights-overview
- Azure AD error codes: https://learn.microsoft.com/en-us/azure/active-directory/develop/reference-aadsts-error-codes
- CloudWatch Logs Insights: https://docs.aws.amazon.com/AmazonCloudWatch/latest/logs/AnalyzingLogData.html
- CloudTrail: https://docs.aws.amazon.com/awscloudtrail/latest/userguide/
- Lambda troubleshooting: https://docs.aws.amazon.com/lambda/latest/dg/lambda-troubleshooting.html
- Cloud Logging: https://cloud.google.com/logging/docs
- Cloud Audit Logs: https://cloud.google.com/logging/docs/audit
- Cloud Run troubleshooting: https://cloud.google.com/run/docs/troubleshooting
