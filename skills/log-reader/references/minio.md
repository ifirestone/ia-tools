# Referencia: MinIO

## Alcance

MinIO server en modo standalone (un nodo) o distribuido (erasure coding entre varios nodos/drives), MinIO Client (`mc`), MinIO Console, y despliegues vía MinIO Operator/Tenant CRD en Kubernetes. API compatible con S3, así que los códigos de error y headers siguen la convención S3.

Formato: log del server en JSON estructurado, con campos típicos `time`, `level` (`INFO`/`ERROR`/`FATAL`), `errKind`, `message`, y un objeto `api` con `name`/`bucket`/`object`/`status`/`statusCode` cuando el evento viene de una request S3. `mc admin trace` muestra líneas de texto con método, ruta, y latencia por request.

## Preguntar antes de interpretar

| Situación | Pregunta |
|---|---|
| Modo no declarado | ¿Standalone (1 nodo) o distribuido (varios nodos/drives)? Cambia qué significa "quorum" |
| Nodos y drives no indicados | ¿Cuántos nodos y drives por nodo? El erasure coding necesita quorum para escribir/leer |
| Versión de MinIO no clara | ¿Qué versión del server? |
| Corre en Kubernetes | ¿Es un Tenant del MinIO Operator? ¿Tenés los eventos del pod además del log de MinIO? |
| Origen del error no claro | ¿El error viene del server (log de MinIO) o de un cliente SDK (aws-sdk, boto3, minio-js/py/go) hablándole a MinIO? |
| Error de firma sin contexto de reloj | ¿Los relojes del cliente y del server están sincronizados (NTP)? |
| Bucket/objeto no identificado | ¿Qué bucket y (si aplica) qué objeto está involucrado? |

## Datos sensibles específicos

Access Key y Secret Key si aparecen en comandos `mc alias set` o en archivos de config pegados; URLs presignadas (`X-Amz-Signature=...`) — son tan sensibles como una credencial mientras no expiren, dan acceso directo al objeto; ARNs y JSON de políticas IAM con nombres de recursos internos; nombres de bucket que revelan estructura de negocio o de clientes.

## Patrones de error frecuentes

`Insufficient storage reached its minimum threshold` → el clúster perdió quorum de drives/nodos para escribir con la redundancia configurada, revisar cuántos drives están caídos. `Drive is not writable` / `faulty drive detected` → falla de disco físico o de montaje, requiere reemplazo/`mc admin heal` según el caso. `NoSuchBucket` → el bucket no existe o el nombre está mal escrito (case-sensitive). `AccessDenied` → política IAM o bucket policy no otorga el permiso para esa acción/principal — revisar la policy exacta, no asumir. `SignatureDoesNotMatch` → casi siempre reloj desincronizado entre cliente y server, o Secret Key incorrecta/rotada sin actualizar en el cliente. `RequestTimeTooSkewed` → confirma directamente desfasaje de reloj (NTP). `unable to connect to a healthy peer` → nodos del clúster distribuido no se ven entre sí (red, firewall, DNS interno). `Server not initialized, please try again` / `XMinioServerNotInitialized` → el server todavía está formateando/verificando los drives al arrancar, normal brevemente tras un restart, anómalo si persiste. Healing en curso (`Healing` en logs o `mc admin heal` reportando objetos pendientes) → drive reemplazado recientemente, dejar terminar antes de diagnosticar lentitud. Replication lag entre sitios (bucket replication configurada) → revisar `mc admin replicate status`, latencia de red entre sitios.

## Referencias

- MinIO docs: https://min.io/docs/minio/linux/index.html
- Troubleshooting: https://min.io/docs/minio/linux/operations/troubleshooting.html
- Error codes (API S3): https://min.io/docs/minio/linux/developers/s3-error-handling.html
- MinIO Operator: https://min.io/docs/minio/kubernetes/upstream/index.html
- mc admin: https://min.io/docs/minio/linux/reference/minio-mc-admin.html
