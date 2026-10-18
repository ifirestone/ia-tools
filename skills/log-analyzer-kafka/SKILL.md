---
name: log-analyzer-kafka
description: "Analiza logs de Apache Kafka (broker, controller, Connect, Streams, producer/consumer) y produce un diagnóstico estructurado. Úsalo cuando el log contenga kafka.server, kafka.controller, org.apache.kafka.clients, menciones a ISR/broker/ZooKeeper/KRaft, o el formato [timestamp] LEVEL mensaje (logger.name)."
---

# Log Reader — Apache Kafka

## Señales de detección
`kafka.server`, `kafka.controller`, `org.apache.kafka.clients`, menciones a ISR/broker/ZooKeeper/KRaft, formato `[timestamp] LEVEL mensaje (logger.name)`.

## Preguntar antes de analizar

| Situación | Pregunta |
|---|---|
| Origen no claro | ¿Broker, producer/consumer de la app, Connect, o Streams? |
| Versión no indicada | ¿2.x (ZooKeeper) o 3.x (KRaft disponible)? |
| Modo de coordinación no claro | ¿ZooKeeper o KRaft? |
| N° de brokers no declarado | Afecta la interpretación de under-replicated partitions y quorum |
| Factor de replicación no claro | ¿`replication.factor` de los topics involucrados? |
| Entorno no declarado | ¿DEV, QA, STAGING o PROD? |
| Consumer group no identificado | ¿Nombre del consumer group afectado? |

## Datos sensibles a marcar en rojo

Passwords en configuración JAAS/SASL, passwords de keystore/truststore, nombres de topics que revelan procesos de negocio, payloads en DEBUG (`org.apache.kafka.clients` en DEBUG expone contenido — riesgo si aparece en QA/PROD), endpoints internos (hostnames/puertos), tokens OAuth/OIDC en logs DEBUG, credenciales de conectores Connect.

## Patrones de error y advertencia

`under-replicated partitions` → followers desincronizados, revisar disk I/O/GC del follower. ⚠️ **No diagnosticar como crítico sin conocer el `replication.factor`** — con `replication.factor=1` es normal. `ISR for partition X shrunk from Y to Z` → follower salió del ISR. `OffsetOutOfRange` → consumer detrás de retención, revisar `log.retention.*`. `UNKNOWN_TOPIC_OR_PARTITION` → topic no existe o fue eliminado. `Consumer group X is rebalancing` → normal en despliegues, anómalo si frecuente — revisar `session.timeout.ms`/`max.poll.interval.ms`. `CommitFailedException` → puede causar reprocesamiento. `Connection to broker-N could not be established` → firewall/red/DNS. `Disk full`/`IOException` → retención vs tamaño real. `OutOfMemoryError` → heap (`KAFKA_HEAP_OPTS`). `SASL authentication failed` → credenciales, JAAS, mecanismo. `Producer request timeout` → `request.timeout.ms`/`acks`. `Message too large`/`RecordTooLargeException` → `message.max.bytes`. `SSL handshake failed` → certificados/cipher suites.

## Consumer lag — señal crítica

`Lag increasing` (Streams), `poll() interval exceeded` (rebalanceo forzado), `Heartbeat thread will stop due to timeout` → señalar lag creciente aunque no haya métrica exacta.

## ZooKeeper vs KRaft

| Aspecto | ZooKeeper (<3.0) | KRaft (3.x) |
|---|---|---|
| Controller election | `ZooKeeper session timeout` | `KRaft leader election` |
| Salud del clúster | Ensemble ZooKeeper | Voter nodes KRaft |
| Partición huérfana | `controller epoch mismatch` | `KRaft epoch mismatch` |

## Kafka Connect

`FAILED` en connector/task → detenido, necesita reinicio. `RetriableException` repetida → retry loop, ver causa raíz. `WorkerSinkTask offset commit timeout` → excedió `offset.flush.timeout.ms`. `SchemaRegistryException` → Schema Registry no disponible o schema incompatible.

## Formato de reporte estándar

```
╔══════════════════════════════════════════════════════════════╗
║   REPORTE DE ANÁLISIS DE LOG — APACHE KAFKA                   ║
╚══════════════════════════════════════════════════════════════╝
📋 RESUMEN EJECUTIVO
Tecnología: Apache Kafka [versión] / [ZooKeeper|KRaft]
Entorno: [DEV/QA/STAGING/PROD/No declarado]
Componente(s): [broker/consumer group/connector]
Período log: [inicio] → [fin]
Total eventos: [N críticos] | [N warnings] | [N notables]
Diagnóstico breve: [1-2 frases]

🔴 HALLAZGOS CRÍTICOS / 🟡 ADVERTENCIAS / 🔵 EVENTOS NOTABLES
⚠️ DATOS SENSIBLES: Valor: <span style="color:red;font-weight:bold">valor</span>
❓ PREGUNTAS ABIERTAS / 🛠️ PRÓXIMOS PASOS
📤 ¿Deseas el reporte como documento entregable?
```

## Referencias
- https://kafka.apache.org/documentation/
- https://kafka.apache.org/documentation/#operations
- https://kafka.apache.org/documentation/#kraft
- https://docs.confluent.io/
- https://strimzi.io/documentation/
