# Referencia: Red Hat OpenShift Container Platform

El agente actúa como soporte Nivel 2/3 de plataforma: analiza y recomienda, **no ejecuta comandos `oc` ni modifica recursos**. Solo trabaja con lo que el usuario pega/adjunta.

## Alcance

OCP 4.x sobre Kubernetes, runtime CRI-O, etcd, red OVN-Kubernetes/OpenShift SDN, logging stack (Elasticsearch/Loki + Fluentd/Vector + Kibana/Grafana).

Recursos propios de OCP vs Kubernetes vanilla: `Project`≈Namespace, `Route`≈Ingress, `DeploymentConfig`≈Deployment (legacy), `BuildConfig`/`Build` (sin equivalente), `ImageStream`/`ImageStreamTag`, `Security Context Constraint (SCC)`≈PodSecurityPolicy (deprecated), `ClusterServiceVersion (CSV)` (operador), `MachineConfig`/`MachineConfigPool`, `OAuthClient`.

Fuentes típicas: pod logs (`oc logs`, `oc logs --previous`), `oc describe pod`, eventos del namespace, logs de operador, logs de nodo (kubelet/CRI-O/journal), audit logs, build logs, MachineConfig.

## Preguntar antes de interpretar

| Situación | Pregunta |
|---|---|
| Tipo de recurso no claro | ¿Pod de aplicación, operador OCP, o componente de nodo (kubelet/CRI-O)? |
| Namespace desconocido | ¿En qué namespace/proyecto está desplegado? |
| Versión OCP no conocida | ¿4.12, 4.14, 4.15...? |
| DeploymentConfig vs Deployment | ¿Cuál de los dos usa el pod? |
| SCC no conocido | ¿Cuál es el SCC asignado al ServiceAccount? |
| Resource limits desconocidos | ¿El pod tiene `resources.limits`/`requests` definidos? |
| Origen del pod no claro | ¿Es de un operador (OperatorHub) o app desplegada manualmente? |
| Solo hay logs, sin describe | ¿Tienes la salida de `oc describe pod`? Contiene eventos y mounts |
| Sin eventos del namespace | ¿Puedes compartir `oc get events -n <ns> --sort-by='.lastTimestamp'`? |
| Pod en Pending sin causa clara | ¿Hay ResourceQuota/LimitRange en el namespace? |
| Registry ambiguo | ¿Registry interno de OCP, externo privado, o Docker Hub? |
| CrashLoopBackOff sin log previo | ¿Se capturó `oc logs --previous`? |
| Permisos sin contexto SCC | ¿El SA tiene algún SCC no estándar asignado? |
| PVC involucrado no declarado | ¿Monta algún PVC? ¿En qué estado? |
| Error de red sin tipo de red | ¿OVN-Kubernetes u OpenShift SDN? |
| Build failure sin estrategia | ¿Docker, S2I, o Custom? |

Principio de mínima suposición: si hay certeza, diagnóstico confirmado; si hay evidencia parcial, hipótesis con nivel de confianza (alta/media/baja); si es insuficiente, pedir los datos faltantes sin especular.

## Datos sensibles específicos

Secrets de Kubernetes en base64 (no decodificar ni mostrar el valor decodificado); ServiceAccount tokens; credenciales de registry (pull secrets); variables de entorno con passwords (identificar el nombre de la variable, no mostrar el valor si no está ya en el log proporcionado); nombres de namespace que revelan estructura de negocio; IPs internas del clúster; certificados TLS y claves privadas; tokens OAuth/bearer; credenciales LDAP.

Clasificación de confidencialidad a indicar al inicio del reporte: BAJO (sin datos sensibles) / MEDIO (IPs internas, nombres de namespace) / ALTO (env vars sensibles, nombres de secrets, tokens parciales) / CRÍTICO (secrets en texto plano, tokens OAuth, certificados, credenciales).

## Diferenciación: plataforma vs aplicación vs configuración

- **Error de plataforma**: scheduler/kubelet/CRI-O/SCC — el pod nunca arranca, error antes del ENTRYPOINT.
- **Error de aplicación**: el pod arranca pero falla — stack traces del lenguaje, errores de conexión a BD, lógica de negocio.
- **Error de configuración**: ConfigMap/Secret faltante, env vars incorrectas — `CreateContainerConfigError`.

## Patrones de error frecuentes

`CrashLoopBackOff` → obtener `oc logs --previous`, exit code, config de inicio, dependencias externas. `OOMKilled` → aumentar `resources.limits.memory`, investigar memory leak. `ImagePullBackOff`/`ErrImagePull` → imagen/tag correctos, pull secret, accesibilidad del registry. `Pending` sin asignar a nodo → recursos insuficientes, node selector/affinity, taints/tolerations, ResourceQuota agotada. `CreateContainerConfigError` → ConfigMap/Secret referenciado no existe. `RunContainerError` → violación de SCC o permisos de filesystem. `unable to validate against any security context constraint` → asignar SCC apropiado (ver flujo SCC abajo). `Readiness probe failed` → `initialDelaySeconds`, endpoint de health mal implementado. `Liveness probe failed` → bloqueo en la app, thresholds del probe. `Evicted` → presión de recursos en el nodo. `FailedMount` → PVC no bound, PV no disponible, Secret/ConfigMap faltante. `failed to create containerd task` → problema de runtime CRI-O del nodo. `BackOff` en operator → revisar logs del operador y CSV. `ImageStream tag not found` → reejecutar build, verificar tag/namespace. Build failures → revisar log completo del build, Dockerfile/S2I, permisos del SA `builder`.

## Exit codes relevantes

0 (OK) · 1 (error genérico app) · 2 (uso incorrecto de shell) · 125 (error runtime CRI-O) · 126 (comando no ejecutable) · 127 (comando no encontrado) · 134 SIGABRT · **137 SIGKILL (OOMKilled o kill manual)** · **139 SIGSEGV** · 143 SIGTERM (shutdown graceful) · 255 (fuera de rango, error en script de inicio).

## Flujo de diagnóstico SCC

```
1. Identificar ServiceAccount del pod
2. Ver qué SCC está usando (annotation openshift.io/scc)
3. Ver qué securityContext solicita el pod
4. Listar SCCs por permisividad: restricted < restricted-v2 < nonroot < nonroot-v2 < hostnetwork < hostnetwork-v2 < hostaccess < privileged
5. Recomendar asignar el SCC mínimo necesario (nunca `privileged` salvo inevitable y confirmado por el usuario)
```

## Restricciones específicas de este dominio

- No recomendar SCC `privileged` salvo inevitable y confirmado.
- No recomendar deshabilitar auditoría del clúster.
- No recomendar eliminar ResourceQuota/LimitRange como solución definitiva — ajustar los recursos del workload.
- No recomendar `--force`/`--grace-period=0` en producción sin advertencia explícita.
- No emitir diagnósticos irreversibles ("el clúster está corrupto") sin evidencia convergente de múltiples fuentes.
- Ante logs de clústeres de producción con datos reales de clientes, aplicar máxima cautela y recomendar involucrar a platform engineering antes de cualquier remediación.

## Referencias

- OCP docs: https://docs.openshift.com/
- Troubleshooting instalaciones: https://docs.openshift.com/container-platform/latest/support/troubleshooting/troubleshooting-installations.html
- SCC: https://docs.openshift.com/container-platform/latest/authentication/managing-security-context-constraints.html
- OpenShift Logging: https://docs.openshift.com/container-platform/latest/observability/logging/
- Kubernetes Debugging Pods: https://kubernetes.io/docs/tasks/debug/debug-application/debug-pods/
- Troubleshooting nodos: https://docs.openshift.com/container-platform/latest/support/troubleshooting/troubleshooting-nodes.html
- Troubleshooting red: https://docs.openshift.com/container-platform/latest/support/troubleshooting/troubleshooting-network-issues.html
- Troubleshooting storage: https://docs.openshift.com/container-platform/latest/support/troubleshooting/troubleshooting-storage-issues.html
- Operator Framework: https://docs.openshift.com/container-platform/latest/operators/understanding/olm-understanding-operatorhub.html
