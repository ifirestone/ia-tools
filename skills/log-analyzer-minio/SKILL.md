---
name: log-analyzer-minio
description: "Analiza logs de MinIO (standalone, distribuido, Kubernetes Operator/Tenant) y produce un diagnóstico estructurado. Úsalo cuando el log mencione minio, header X-Amz-Request-Id/X-Minio-*, códigos S3 como NoSuchBucket/AccessDenied/SignatureDoesNotMatch, o comandos mc admin."
---

# Log Reader — MinIO

## Señales de detección
Mención de `minio`, header `X-Amz-Request-Id`/`X-Minio-*`, códigos S3 (`NoSuchBucket`, `AccessDenied`, `SignatureDoesNotMatch`), comandos `mc admin`.

## Preguntar antes de analizar

| Situación | Pregunta |
|---|---|
| Modo no declarado | ¿Standalone (1 nodo) o distribuido (varios nodos/drives)? Cambia qué significa "quorum" |
| Nodos y drives no indicados | ¿Cuántos nodos y drives por nodo? El erasure coding necesita quorum para escribir/leer |
| Versión de MinIO no clara | ¿Qué versión del server? |
| Corre en Kubernetes | ¿Es un Tenant del MinIO Operator? ¿Tienes los eventos del pod? |
| Origen del error no claro | ¿El error viene del server o de un cliente SDK? |
| Error de firma sin contexto de reloj | ¿Los relojes del cliente y del server están sincronizados (NTP)? |
| Bucket/objeto no identificado | ¿Qué bucket y objeto están involucrados? |

## Datos sensibles a marcar en rojo

Access Key y Secret Key en comandos `mc alias set` o archivos de config; URLs presignadas (`X-Amz-Signature=...`) — tan sensibles como una credencial mientras no expiren; ARNs y JSON de políticas IAM con recursos internos; nombres de bucket que revelan estructura de negocio o de clientes.

## Patrones de error frecuentes

`Insufficient storage reached its minimum threshold` → clúster perdió quorum de drives/nodos para escribir, revisar cuántos drives están caídos. `Drive is not writable`/`faulty drive detected` → falla de disco físico o de montaje, requiere reemplazo/`mc admin heal`. `NoSuchBucket` → bucket no existe o nombre mal escrito (case-sensitive). `AccessDenied` → política IAM o bucket policy no otorga el permiso — revisar la policy exacta, no asumir. `SignatureDoesNotMatch` → casi siempre reloj desincronizado o Secret Key incorrecta/rotada sin actualizar en el cliente. `RequestTimeTooSkewed` → confirma directamente desfasaje de reloj (NTP). `unable to connect to a healthy peer` → nodos del clúster distribuido no se ven (red, firewall, DNS interno). `Server not initialized`/`XMinioServerNotInitialized` → server formateando/verificando drives al arrancar, normal brevemente, anómalo si persiste.

Healing en curso → drive reemplazado recientemente, dejar terminar antes de diagnosticar lentitud. Replication lag entre sitios → revisar `mc admin replicate status`, latencia de red entre sitios.

## Formato de reporte estándar

```
╔══════════════════════════════════════════════════════════════╗
║   REPORTE DE ANÁLISIS DE LOG — MINIO                          ║
╚══════════════════════════════════════════════════════════════╝
📋 RESUMEN EJECUTIVO
Tecnología: MinIO [versión] / [standalone|distribuido|Operator Tenant]
Entorno: [DEV/QA/STAGING/PROD/No declarado]
Componente(s): [nodo/bucket/tenant]
Período log: [inicio] → [fin]
Total eventos: [N críticos] | [N warnings] | [N notables]
Diagnóstico breve: [1-2 frases]

🔴 HALLAZGOS CRÍTICOS / 🟡 ADVERTENCIAS / 🔵 EVENTOS NOTABLES
⚠️ DATOS SENSIBLES: Valor: <span style="color:red;font-weight:bold">valor</span>
❓ PREGUNTAS ABIERTAS / 🛠️ PRÓXIMOS PASOS
📤 ¿Deseas el reporte como documento entregable (Word/Markdown)?
```

## Referencias
- https://min.io/docs/minio/linux/index.html
- https://min.io/docs/minio/linux/operations/troubleshooting.html
- https://min.io/docs/minio/linux/developers/s3-error-handling.html
- https://min.io/docs/minio/kubernetes/upstream/index.html
- https://min.io/docs/minio/linux/reference/minio-mc-admin.html
