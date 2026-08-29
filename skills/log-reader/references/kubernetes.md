# Referencia: Kubernetes (vanilla / EKS / GKE / AKS / on-prem) y OpenShift

El agente actúa como soporte Nivel 2/3 de plataforma: analiza y recomienda, **no ejecuta comandos `kubectl`/`oc` ni modifica recursos**. Solo trabaja con lo que el usuario pega/adjunta.

## Alcance

Kubernetes 1.2x sobre cualquier distribución: vanilla/kubeadm, managed (EKS, GKE, AKS), y **OpenShift Container Platform (OCP)**, que es Kubernetes de Red Hat con capas propias encima. La mayoría de los patrones de error de pods son idénticos entre todas (son de Kubernetes core); lo que cambia es el CLI (`kubectl` vs `oc`), algunos recursos propios, y las integraciones de cada nube administrada.

Fuentes típicas: pod logs (`kubectl`/`oc logs`, `--previous`), `describe pod`, eventos del namespace, logs de operador/controller, logs de nodo (kubelet/containerd/CRI-O/journal), audit logs.

## Preguntar antes de interpretar

| Situación | Pregunta |
|---|---|
| Distribución no clara | ¿Kubernetes vanilla/kubeadm, EKS, GKE, AKS, u OpenShift? Cambia el CLI y algunos recursos |
| Tipo de recurso no claro | ¿Pod de aplicación, componente de sistema (controller/operador), o componente de nodo (kubelet/container runtime)? |
| Namespace desconocido | ¿En qué namespace/proyecto está desplegado? |
| Versión de Kubernetes no conocida | Muchos errores son version-specific |
| Resource limits desconocidos | ¿El pod tiene `resources.limits`/`requests` definidos? |
| Solo hay logs, sin describe | ¿Tienes la salida de `describe pod`? Contiene eventos y mounts |
| Sin eventos del namespace | ¿Puedes compartir `get events -n <ns> --sort-by='.lastTimestamp'`? |
| Pod en Pending sin causa clara | ¿Hay ResourceQuota/LimitRange en el namespace? |
| Registry ambiguo | ¿Registry interno, ECR/GCR/ACR, externo privado, o Docker Hub? |
| CrashLoopBackOff sin log previo | ¿Se capturó el log con `--previous`? |
| PVC involucrado no declarado | ¿Monta algún PVC? ¿En qué estado? ¿Qué StorageClass? |
| CNI no declarado | ¿Calico, Cilium, Flannel, OVN-Kubernetes, o el CNI propio de la nube (VPC CNI en EKS)? |
| En nube administrada sin aclarar el servicio | ¿EKS/GKE/AKS gestiona el control plane o es self-managed sobre esas VMs? |

Principio de mínima suposición: si hay certeza, diagnóstico confirmado; si hay evidencia parcial, hipótesis con nivel de confianza (alta/media/baja); si es insuficiente, pedir los datos faltantes sin especular.

## Datos sensibles específicos

Secrets de Kubernetes en base64 (no decodificar ni mostrar el valor decodificado); ServiceAccount tokens; credenciales de registry (pull secrets); variables de entorno con passwords (identificar el nombre de la variable, no mostrar el valor si no está ya en el log proporcionado); nombres de namespace que revelan estructura de negocio; IPs internas del clúster; certificados TLS y claves privadas; tokens OAuth/bearer; credenciales LDAP; ARNs/roles IAM (EKS), service account emails (GKE Workload Identity), client IDs de Azure AD (AKS).

Clasificación de confidencialidad a indicar al inicio del reporte: BAJO (sin datos sensibles) / MEDIO (IPs internas, nombres de namespace) / ALTO (env vars sensibles, nombres de secrets, tokens parciales) / CRÍTICO (secrets en texto plano, tokens OAuth, certificados, credenciales).

## Diferenciación: plataforma vs aplicación vs configuración

- **Error de plataforma**: scheduler/kubelet/container runtime — el pod nunca arranca, error antes del ENTRYPOINT.
- **Error de aplicación**: el pod arranca pero falla — stack traces del lenguaje, errores de conexión a BD, lógica de negocio.
- **Error de configuración**: ConfigMap/Secret faltante, env vars incorrectas — `CreateContainerConfigError`.

## Patrones de error frecuentes (Kubernetes core — aplican a cualquier distribución)

`CrashLoopBackOff` → obtener el log con `--previous`, exit code, config de inicio, dependencias externas. `OOMKilled` → aumentar `resources.limits.memory`, investigar memory leak. `ImagePullBackOff`/`ErrImagePull` → imagen/tag correctos, pull secret, accesibilidad del registry. `Pending` sin asignar a nodo → recursos insuficientes, node selector/affinity, taints/tolerations, ResourceQuota agotada, o autoscaler que todavía no sumó nodos. `CreateContainerConfigError` → ConfigMap/Secret referenciado no existe. `RunContainerError` → permisos de filesystem o violación de política de seguridad del pod. `Readiness probe failed` → `initialDelaySeconds`, endpoint de health mal implementado. `Liveness probe failed` → bloqueo en la app, thresholds del probe. `Evicted` → presión de recursos en el nodo. `FailedMount` → PVC no bound, PV no disponible, Secret/ConfigMap faltante. `failed to create containerd task`/`failed to create shim task` → problema de runtime del nodo. `BackOff` en un controller/operador → revisar sus logs.

## Patrones específicos de nube administrada

**EKS**: `AccessDenied` con IRSA (IAM Roles for Service Accounts) → el rol IAM asociado al ServiceAccount no tiene el permiso, o la anotación `eks.amazonaws.com/role-arn` falta/está mal. `FailedScheduling` persistente → Cluster Autoscaler/Karpenter todavía no sumó nodos, revisar node group. Errores del AWS Load Balancer Controller (`ALB`) → target group unhealthy, subnets mal etiquetadas.

**GKE**: errores de Workload Identity (`permission denied` al usar credenciales de GCP) → falta el binding entre KSA y GSA. `FailedAttachVolume`/`FailedMount` con Persistent Disk → el disco sigue attached a otro nodo (multi-attach), o zona incorrecta.

**AKS**: errores de AAD Pod Identity / Workload Identity → falta la identidad federada o el label en el pod. Errores de montaje de Azure Disk/Azure Files → zona de disponibilidad incompatible con el nodo, o cuota de disco agotada.

## Exit codes relevantes

0 (OK) · 1 (error genérico app) · 2 (uso incorrecto de shell) · 125 (error del container runtime) · 126 (comando no ejecutable) · 127 (comando no encontrado) · 134 SIGABRT · **137 SIGKILL (OOMKilled o kill manual)** · **139 SIGSEGV** · 143 SIGTERM (shutdown graceful) · 255 (fuera de rango, error en script de inicio).

## Si es OpenShift (OCP)

OCP agrega runtime CRI-O, red OVN-Kubernetes/OpenShift SDN, logging stack (Elasticsearch/Loki + Fluentd/Vector + Kibana/Grafana), y recursos propios sobre Kubernetes vanilla: `Project`≈Namespace, `Route`≈Ingress, `DeploymentConfig`≈Deployment (legacy), `BuildConfig`/`Build` (sin equivalente), `ImageStream`/`ImageStreamTag`, `Security Context Constraint (SCC)`≈PodSecurityPolicy (deprecated), `ClusterServiceVersion (CSV)` (operador), `MachineConfig`/`MachineConfigPool`, `OAuthClient`. El CLI es `oc` (superset de `kubectl`).

### Preguntar además, si es OpenShift

| Situación | Pregunta |
|---|---|
| Versión OCP no conocida | ¿4.12, 4.14, 4.15...? |
| DeploymentConfig vs Deployment | ¿Cuál de los dos usa el pod? |
| SCC no conocido | ¿Cuál es el SCC asignado al ServiceAccount? |
| Origen del pod no claro | ¿Es de un operador (OperatorHub) o app desplegada manualmente? |
| Permisos sin contexto SCC | ¿El SA tiene algún SCC no estándar asignado? |
| Build failure sin estrategia | ¿Docker, S2I, o Custom? |

### Patrones de error específicos de OCP

`unable to validate against any security context constraint` → asignar SCC apropiado (ver flujo SCC abajo). `ImageStream tag not found` → reejecutar build, verificar tag/namespace. Build failures → revisar log completo del build, Dockerfile/S2I, permisos del SA `builder`.

### Flujo de diagnóstico SCC

```
1. Identificar ServiceAccount del pod
2. Ver qué SCC está usando (annotation openshift.io/scc)
3. Ver qué securityContext solicita el pod
4. Listar SCCs por permisividad: restricted < restricted-v2 < nonroot < nonroot-v2 < hostnetwork < hostnetwork-v2 < hostaccess < privileged
5. Recomendar asignar el SCC mínimo necesario (nunca `privileged` salvo inevitable y confirmado por el usuario)
```

## Restricciones específicas de este dominio

- No recomendar SCC `privileged` (OCP) ni `privileged: true`/`hostNetwork`/`hostPID` (K8s vanilla) salvo inevitable y confirmado.
- No recomendar deshabilitar auditoría del clúster.
- No recomendar eliminar ResourceQuota/LimitRange como solución definitiva — ajustar los recursos del workload.
- No recomendar `--force`/`--grace-period=0` en producción sin advertencia explícita.
- No emitir diagnósticos irreversibles ("el clúster está corrupto") sin evidencia convergente de múltiples fuentes.
- Ante logs de clústeres de producción con datos reales de clientes, aplicar máxima cautela y recomendar involucrar a platform engineering antes de cualquier remediación.

## Referencias

- Kubernetes Debugging Pods: https://kubernetes.io/docs/tasks/debug/debug-application/debug-pods/
- Kubernetes Troubleshooting Clusters: https://kubernetes.io/docs/tasks/debug/debug-cluster/
- EKS Troubleshooting: https://docs.aws.amazon.com/eks/latest/userguide/troubleshooting.html
- GKE Troubleshooting: https://cloud.google.com/kubernetes-engine/docs/troubleshooting
- AKS Troubleshooting: https://learn.microsoft.com/en-us/azure/aks/troubleshooting
- OCP docs: https://docs.openshift.com/
- Troubleshooting instalaciones OCP: https://docs.openshift.com/container-platform/latest/support/troubleshooting/troubleshooting-installations.html
- SCC: https://docs.openshift.com/container-platform/latest/authentication/managing-security-context-constraints.html
- OpenShift Logging: https://docs.openshift.com/container-platform/latest/observability/logging/
- Troubleshooting nodos OCP: https://docs.openshift.com/container-platform/latest/support/troubleshooting/troubleshooting-nodes.html
- Troubleshooting red OCP: https://docs.openshift.com/container-platform/latest/support/troubleshooting/troubleshooting-network-issues.html
- Troubleshooting storage OCP: https://docs.openshift.com/container-platform/latest/support/troubleshooting/troubleshooting-storage-issues.html
