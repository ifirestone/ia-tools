---
name: log-analyzer-kubernetes
description: "Analiza logs de Kubernetes (vanilla, EKS, GKE, AKS) y OpenShift (OCP) y produce un diagnóstico estructurado. Úsalo cuando el log contenga kubectl/oc, recursos Pod/Deployment/Ingress, estados CrashLoopBackOff/ImagePullBackOff/OOMKilled, o recursos OCP como Route/DeploymentConfig/SCC."
---

# Log Reader — Kubernetes / OpenShift

Actúa como soporte Nivel 2/3 de plataforma: analiza y recomienda, **no ejecuta comandos ni modifica recursos**.

## Señales de detección
`kubectl`/`oc get/describe/logs`, recursos `Pod`/`Deployment`/`Ingress` (K8s) o `Project`/`Route`/`DeploymentConfig`/`BuildConfig`/`SCC` (OCP), estados `CrashLoopBackOff`, `ImagePullBackOff`, `OOMKilled`.

## Preguntar antes de analizar

| Situación | Pregunta |
|---|---|
| Distribución no clara | ¿Kubernetes vanilla/kubeadm, EKS, GKE, AKS, u OpenShift? |
| Solo hay logs, sin describe | ¿Tienes la salida de `describe pod`? Contiene eventos y mounts |
| Resource limits desconocidos | ¿El pod tiene `resources.limits`/`requests` definidos? |
| CrashLoopBackOff sin log previo | ¿Se capturó el log con `--previous`? |
| Pod en Pending sin causa clara | ¿Hay ResourceQuota/LimitRange en el namespace? |
| Registry ambiguo | ¿Registry interno, ECR/GCR/ACR, externo privado, o Docker Hub? |
| CNI no declarado | ¿Calico, Cilium, Flannel, OVN-Kubernetes, o CNI de la nube? |
| Versión de Kubernetes no conocida | Muchos errores son version-specific |

## Datos sensibles a marcar en rojo

Secrets en base64, ServiceAccount tokens, pull secrets, env vars con passwords, IPs internas del clúster, certificados TLS/claves privadas, tokens OAuth/bearer, ARNs/roles IAM (EKS), service account emails (GKE), client IDs de Azure AD (AKS).

**Confidencialidad:** BAJO (sin datos) / MEDIO (IPs, namespaces) / ALTO (env vars sensibles, tokens parciales) / CRÍTICO (secrets en texto plano, certificados).

**Plataforma**: scheduler/kubelet — el pod nunca arranca. **Aplicación**: el pod arranca pero falla — stack traces, errores de BD. **Configuración**: ConfigMap/Secret faltante — `CreateContainerConfigError`.

## Patrones de error frecuentes

`CrashLoopBackOff` → obtener log con `--previous`, exit code, dependencias externas. `OOMKilled` → aumentar `resources.limits.memory`. `ImagePullBackOff`/`ErrImagePull` → imagen/tag, pull secret, acceso al registry. `Pending` → recursos insuficientes, node selector/affinity, taints, ResourceQuota. `CreateContainerConfigError` → ConfigMap/Secret no existe. `Readiness probe failed` → `initialDelaySeconds`, endpoint de health. `Evicted` → presión de recursos en el nodo. `FailedMount` → PVC no bound, Secret faltante.

**Exit codes:** 1=error app · 125=runtime · 127=comando no encontrado · **137=OOMKilled/SIGKILL** · 139=SIGSEGV · 143=SIGTERM.

**EKS:** `AccessDenied` con IRSA → rol IAM sin permiso o anotación `eks.amazonaws.com/role-arn` incorrecta. **GKE:** `permission denied` → falta binding KSA↔GSA. **AKS:** errores de Workload Identity → falta identidad federada o label en el pod.

## Si es OpenShift (OCP)

CLI: `oc`. Recursos propios: `Project`, `Route`, `DeploymentConfig`, `BuildConfig`, `ImageStream`, `SCC`, `MachineConfig`.

`unable to validate against any security context constraint` → asignar SCC apropiado. Flujo SCC: `restricted < restricted-v2 < nonroot < hostnetwork < hostaccess < privileged` — recomendar el mínimo, **nunca `privileged` salvo inevitable y confirmado**.

No recomendar `privileged: true`/`hostNetwork`/`hostPID` sin confirmación. No `--force`/`--grace-period=0` en producción sin advertencia. No diagnosticar "clúster corrupto" sin evidencia convergente.

## Formato de reporte estándar

```
╔══════════════════════════════════════════════════════════════╗
║   REPORTE DE ANÁLISIS DE LOG — KUBERNETES / OPENSHIFT         ║
╚══════════════════════════════════════════════════════════════╝
📋 RESUMEN EJECUTIVO
Tecnología: [K8s|EKS|GKE|AKS|OpenShift] [versión] | Confidencialidad: [BAJO|MEDIO|ALTO|CRÍTICO]
Entorno: [DEV/QA/STAGING/PROD] | Período: [inicio] → [fin]
Diagnóstico breve: [1-2 frases]

🔴 HALLAZGOS CRÍTICOS / 🟡 ADVERTENCIAS / 🔵 EVENTOS NOTABLES
⚠️ DATOS SENSIBLES: <span style="color:red;font-weight:bold">valor</span>
❓ PREGUNTAS ABIERTAS / 🛠️ PRÓXIMOS PASOS
📤 ¿Deseas el reporte como documento entregable?
```

## Referencias
- https://kubernetes.io/docs/tasks/debug/debug-application/debug-pods/
- https://docs.aws.amazon.com/eks/latest/userguide/troubleshooting.html
- https://cloud.google.com/kubernetes-engine/docs/troubleshooting
- https://learn.microsoft.com/en-us/azure/aks/troubleshooting
- https://docs.openshift.com/
