---
name: log-analyzer-docker
description: "Analiza logs de Docker Engine, Docker Compose y builds con Dockerfile/BuildKit y produce un diagnóstico estructurado. Úsalo cuando el log contenga 'Cannot connect to the Docker daemon', docker-compose.yml, dockerd/containerd, prefijo de Compose '<servicio>-N |', o errores de docker build/BuildKit. Si el contenedor corre dentro de Kubernetes, usar log-analyzer-kubernetes."
---

# Log Reader — Docker

## Señales de detección
`Cannot connect to the Docker daemon`, `docker-compose.yml`/`compose.yaml`, `dockerd`/`containerd`, prefijo `<servicio>-<n> |`, `docker build`/BuildKit — **sin** recursos Kubernetes (`Pod`, `Deployment`).

## Preguntar antes de analizar

| Situación | Pregunta |
|---|---|
| Origen no claro | ¿Es log del contenedor (stdout de la app) o del daemon/CLI/build? |
| Versión no indicada | ¿Qué versión de Docker Engine y Compose? |
| Docker Desktop vs Linux nativo | ¿Corre en Docker Desktop (Mac/Windows) o en un host Linux directo? |
| Compose sin archivo | ¿Puedes compartir el `compose.yaml` relevante (sin secretos)? |
| Build fallando sin contexto | ¿Qué build context y qué línea del Dockerfile falló? |
| Contenedor reiniciando en loop | ¿Qué política de restart tiene? |
| Driver de red no claro | ¿bridge (default), host, u overlay/custom? |

## Datos sensibles a marcar en rojo

Build args/secrets filtrados en capas de imagen (`ARG DB_PASSWORD=...` queda en el historial — riesgo de configuración); credenciales de registry en `~/.docker/config.json` (base64, no cifradas, no es protección real); variables de entorno sensibles visibles en `docker inspect`; secretos pegados directo en `docker-compose.yml` en vez de usar `secrets:`/`.env` ignorado.

## Patrones de error frecuentes

`Cannot connect to the Docker daemon at unix:///var/run/docker.sock` → daemon no corriendo o usuario sin permiso sobre el socket (grupo `docker`). `OCI runtime create failed` → imagen corrupta o entrypoint inválido. `exec format error` → imagen `amd64` en host ARM sin `--platform`. `no space left on device` → disco lleno, revisar `docker system df`, considerar `docker system prune`. `Conflict. The container name "/x" is already in use` → nombre duplicado, no se removió el anterior. `pull access denied` → imagen privada sin `docker login` o typo en el tag. `port is already allocated` → otro proceso/contenedor usa ese puerto. `network X not found` → red de Docker no existe. Exit code 137 → OOM (`docker inspect` → `OOMKilled: true`) o `kill -9`. Contenedor en restart loop → revisar `docker logs` del intento anterior, el proceso principal está terminando.

**Compose:** `dependency failed to start: container X is unhealthy` → healthcheck del servicio dependiente falla. `ERROR: for X Cannot start service` → uno de los patrones de arriba.

**BuildKit:** `failed to solve` → revisar el paso específico que falla. `COPY failed: file not found in build context` → ruta incorrecta o archivo excluido por `.dockerignore`. `toomanyrequests` → rate limit de Docker Hub (autenticarse para subir el límite).

## Formato de reporte estándar

```
╔══════════════════════════════════════════════════════════════╗
║   REPORTE DE ANÁLISIS DE LOG — DOCKER                         ║
╚══════════════════════════════════════════════════════════════╝
📋 RESUMEN EJECUTIVO
Tecnología: Docker Engine [versión] / Compose [versión]
Entorno: [DEV/QA/STAGING/PROD/No declarado]
Componente(s): [contenedor/servicio/build]
Período log: [inicio] → [fin]
Total eventos: [N críticos] | [N warnings] | [N notables]
Diagnóstico breve: [1-2 frases]

🔴 HALLAZGOS CRÍTICOS / 🟡 ADVERTENCIAS / 🔵 EVENTOS NOTABLES
⚠️ DATOS SENSIBLES: Valor: <span style="color:red;font-weight:bold">valor</span>
❓ PREGUNTAS ABIERTAS / 🛠️ PRÓXIMOS PASOS
📤 ¿Deseas el reporte como documento entregable (Word/Markdown)?
```

## Referencias
- https://docs.docker.com/
- https://docs.docker.com/compose/compose-file/
- https://docs.docker.com/build/buildkit/
- https://docs.docker.com/engine/daemon/troubleshoot/
