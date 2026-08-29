# Referencia: IBM API Connect

## Alcance

Componentes: **API Gateway (DataPower Gateway)** (runtime, fuente principal de errores), **API Manager** (gestión/ciclo de vida de APIs, JSON en v10), **Developer Portal** (Drupal/PHP), **Analytics Service**. Versiones: **v10** (cloud native, Kubernetes/OpenShift, operador `ibm-apiconnect`, logs JSON) y **v5** (legacy on-prem, texto plano).

Formatos:
- DataPower transacción: `[timestamp] [category] [transaction-id] message`.
- DataPower syslog extendido: `<priority>version timestamp hostname datapower - - [transaction@... tid="..." status="..."] message`.
- API Manager JSON: `{"timestamp":...,"level":...,"component":"apimanager","message":...}`.
- Operador k8s (v10): `timestamp LEVEL apiconnect-operator mensaje {campos}`.
- Audit log JSON: `{"eventTime":...,"action":...,"resource":...,"outcome":...}`.

## Preguntar antes de interpretar

| Situación | Pregunta |
|---|---|
| Origen no claro | ¿Gateway (DataPower) o API Manager? Cambia completamente el diagnóstico |
| Versión no declarada | ¿v5 o v10? |
| Despliegue no claro | ¿Cloud-native (k8s/OpenShift) o on-premises? |
| Mecanismo de auth no declarado | ¿OAuth 2.0, API Key, Basic Auth, otro? |
| Sin transaction-id/correlation-id completo | Necesario para rastrear el flujo de punta a punta |
| Entorno no declarado | ¿DEV, QA, STAGING o PROD? |
| API no identificada | ¿Nombre y versión de la API (ej. orders:1.0.0)? |
| Mensaje truncado | ¿Puedes dar el log/mensaje de error completo? |
| Assembly/política sin identificar | ¿Tienes la definición del assembly en API Manager? |
| Backend no visible | ¿Cuál es la URL del backend al que conecta el gateway? |

## Datos sensibles específicos

`X-IBM-Client-Id`/`X-IBM-Client-Secret`, `client_id`/`client_secret`; `access_token`/`refresh_token`/`id_token`; JWTs (patrón `eyJ...\.eyJ...\....`); `Authorization: Basic/Bearer` y credenciales de backend logueadas por `activity-log`; configuración DataPower con `<Password>`/`<APIKey>`/claves de criptografía; correlation IDs de PROD (pueden rastrear transacciones reales); PII en request/response si `activity-log` captura body completo; hostnames/IPs internas de backend.

Alerta especial: la política `activity-log` con `content: payload` o `content: all` captura headers y bodies completos — señalarlo como riesgo de exposición si aparece fuera de DEV, y recomendar `content: activity` en producción.

## Categorías de severidad DataPower

`emerg`(FATAL) > `alert`(FATAL) > `critic`(CRITICAL) > `error`(ERROR) > `warn`(WARNING) > `notice`(INFO+) > `info`(INFO) > `debug`(DEBUG).

## Patrones de error frecuentes

`0x00d30003` → fallo de ejecución de una política del assembly, identificar cuál (`validate`, `invoke`, `map`, etc.). `0x00d30004` → error de assembly completo, encadena con `0x00d30003`. `assembly error` genérico (común en v5) → revisar la política anterior en el mismo transaction-id. OAuth (`token expired`/`invalid_token`/`insufficient_scope`) → TTL, configuración del provider, scopes del plan. `JWT validation failed` → política `jwt-validate`, clave pública/JWKS, claims. HTTP 502/503 desde el gateway → backend no disponible, revisar `invoke` y health del backend. `connect timeout`/`read timeout` → configuración de timeout en `invoke`, latencia del backend. `TLS/SSL handshake failed` → certificados, cipher suites, TLS mínimo. `rate limit exceeded`/`quota exceeded` → plan asignado en API Manager. `parse-variable policy failure` → Content-Type vs payload esperado. `map policy failure` → variable de contexto null o tipo incorrecto. `CORS policy error` → origen no permitido o headers faltantes. `API not found`/404 desde gateway → base path, catálogo, estado de publicación. `Catalog/Space publish error` → permisos, validación del OpenAPI, conflicto de versión.

Operador Kubernetes (v10): `Reconciliation failed` → componente del clúster APIC no está en estado deseado. `DataPowerService not ready: N/M pods running` → réplicas degradadas. `CRD validation error` → upgrade parcial del operador. `Certificate expired` en componentes internos → renovar vía `apicops` o cert-manager.

## v5 vs v10

v5: logs de texto plano, menos estructurados, errores de assembly fragmentados en múltiples líneas, sin operador Kubernetes. v10: JSON estructurado en la mayoría de componentes, más los logs del operador `ibm-apiconnect`; los pod logs de DataPower mantienen el formato clásico. Si no se puede determinar la versión, indícalo — afecta las instrucciones de diagnóstico.

## Referencias

- IBM API Connect docs: https://www.ibm.com/docs/en/api-connect
- Troubleshooting v10: https://www.ibm.com/docs/en/api-connect/10.0.x?topic=troubleshooting
- Troubleshooting v5: https://www.ibm.com/docs/en/api-connect/5.0.x?topic=troubleshooting
- DataPower Gateway: https://www.ibm.com/docs/en/datapower-gateway
- DataPower error reference: https://www.ibm.com/docs/en/datapower-gateway/10.5?topic=reference-error-message
- Políticas de assembly: https://www.ibm.com/docs/en/api-connect/10.0.x?topic=policies
- OAuth en API Connect: https://www.ibm.com/docs/en/api-connect/10.0.x?topic=security-oauth
- API Connect Operator: https://www.ibm.com/docs/en/api-connect/10.0.x?topic=operator
- apicops: https://github.com/ibm-apiconnect/apicops
- IBM Fix Central: https://www.ibm.com/support/fixcentral
