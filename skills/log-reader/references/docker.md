# Referencia: Docker

Cubre Docker Engine, CLI y Compose corriendo standalone (sin orquestador). Si el contenedor corre dentro de Kubernetes, usar `references/kubernetes.md` — ahí los problemas de arranque/imagen se ven como eventos del pod, no como salida directa de `docker`.

## Alcance

Docker Engine (`dockerd`), Docker CLI, Docker Compose v2 (`docker compose`), builds con Dockerfile/BuildKit, Docker Desktop (macOS/Windows, corre sobre una VM Linux). No cubre orquestación multi-nodo (Swarm queda fuera de alcance salvo mención explícita del usuario).

Formatos:
- `docker logs`: stdout/stderr crudo del proceso del contenedor — el formato depende enteramente de la app adentro, no de Docker.
- `docker compose logs`: cada línea prefijada con `<servicio>-<n>  |` (o `<servicio>_<n>  |` en v1).
- Logs del daemon (`dockerd`, vía journal/syslog en Linux) y de builds (`docker build`/BuildKit) sí tienen formato propio de Docker.

## Preguntar antes de interpretar

| Situación | Pregunta |
|---|---|
| Origen no claro | ¿Es log del contenedor (stdout de la app) o del daemon/CLI/build? |
| Versión no indicada | ¿Qué versión de Docker Engine y de Compose? |
| Docker Desktop vs Linux nativo | ¿Corre en Docker Desktop (Mac/Windows, con VM) o en un host Linux directo? Cambia dónde investigar límites de recursos |
| Driver de red no claro | ¿bridge (default), host, u overlay/custom? |
| Compose sin archivo | ¿Podés compartir el `docker-compose.yml`/`compose.yaml` relevante (sin secretos)? |
| Build fallando sin contexto | ¿Qué build context y qué línea del Dockerfile falló? |
| Contenedor reiniciando en loop | ¿Qué política de restart tiene (`restart: unless-stopped`, etc.)? |

## Datos sensibles específicos

Build args o secrets filtrados dentro de capas de imagen (`ARG DB_PASSWORD=...` queda en el historial de la imagen incluso si no se usa en runtime — señalarlo como riesgo de configuración, no solo dato puntual); credenciales de registry en `~/.docker/config.json` (están en base64, no cifradas — no es una protección real); variables de entorno sensibles visibles en `docker inspect`; secretos pegados directo en un `docker-compose.yml` en vez de usar `secrets:`/`.env` ignorado por git.

## Patrones de error frecuentes

`Cannot connect to the Docker daemon at unix:///var/run/docker.sock. Is the docker daemon running?` → el daemon no está corriendo, o el usuario no tiene permisos sobre el socket (grupo `docker`). `OCI runtime create failed` → problema al crear el contenedor a nivel runtime (imagen corrupta, comando de entrypoint inválido). `exec format error` → arquitectura de la imagen incompatible con el host (típico: imagen `amd64` corrida en Mac/host ARM sin `--platform`). `no space left on device` → disco lleno, revisar `docker system df` y considerar `docker system prune`. `Error response from daemon: Conflict. The container name "/x" is already in use` → nombre de contenedor duplicado, no se removió el anterior. `pull access denied for X, repository does not exist or may require 'docker login'` → imagen mal nombrada, privada sin autenticación, o typo en el tag. `port is already allocated` → otro proceso/contenedor ya usa ese puerto en el host. `network X not found` → red de Docker referenciada no existe (Compose no la creó, o se borró manualmente). Exit code 137 → igual que en Kubernetes, casi siempre OOM (`docker inspect` muestra `OOMKilled: true`) o un `kill -9`. Contenedor en restart loop (`Restarting (1) N seconds ago`) → revisar `docker logs` del intento anterior, el proceso principal está terminando solo.

Compose: `dependency failed to start: container X is unhealthy` → el healthcheck de un servicio dependiente falla, revisar sus logs y la definición de `healthcheck`. `ERROR: for X  Cannot start service`, seguido de uno de los patrones de arriba.

Build (BuildKit): `failed to solve: ...` → falla genérica de build, revisar el paso específico que reporta debajo. `COPY failed: file not found in build context` → ruta incorrecta o archivo excluido por `.dockerignore`. `failed to fetch anonymous token` / `toomanyrequests` al hacer pull de una imagen base → rate limit del registry (Docker Hub sin autenticación tiene límites bajos).

## Referencias

- Docker docs: https://docs.docker.com/
- Compose file reference: https://docs.docker.com/compose/compose-file/
- BuildKit: https://docs.docker.com/build/buildkit/
- Troubleshooting: https://docs.docker.com/engine/daemon/troubleshoot/
- Dockerfile best practices: https://docs.docker.com/build/building/best-practices/
