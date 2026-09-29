# Referencia: Apache Kafka

## Alcance

Broker, Controller, ZooKeeper (Kafka <3.0) o KRaft (3.x+), Connect, Streams, Schema Registry, Producer/Consumer. Versiones: Kafka 2.x/3.x, Confluent Platform, Red Hat AMQ Streams (Strimzi).

Formato: `[YYYY-MM-DD HH:mm:ss,SSS] LEVEL  mensaje (logger.name)`.

Loggers clave: `kafka.server.KafkaServer` (ciclo de vida) · `kafka.controller.KafkaController` (elecciones, ISR) · `kafka.log.LogManager` (segmentos, retención) · `kafka.cluster.Partition` (ISR shrink/expand) · `kafka.network.RequestChannel` · `kafka.coordinator.group.GroupCoordinator` (rebalanceos) · `org.apache.kafka.clients.producer`/`consumer` · `org.apache.kafka.connect` · `org.apache.kafka.streams`.

## Preguntar antes de interpretar

| Situación | Pregunta |
|---|---|
| Origen no claro | ¿Broker, producer/consumer de la app, Connect, o Streams? |
| Versión no indicada | ¿2.x (ZooKeeper) o 3.x (KRaft disponible)? |
| Modo de coordinación no claro | ¿ZooKeeper o KRaft? |
| N° de brokers no declarado | Afecta la interpretación de under-replicated partitions y quorum |
| Factor de replicación no claro | ¿`replication.factor` de los topics involucrados? |
| Entorno no declarado | ¿DEV, QA, STAGING o PROD? |
| Log truncado | Los errores de Kafka suelen ser precedidos por warnings minutos antes — ¿tienes el período completo? |
| Consumer group no identificado | ¿Nombre del consumer group afectado? |
| `broker-N` sin contexto | ¿Tienes la config del clúster (rol de cada broker)? |

## Datos sensibles específicos

Passwords en configuración JAAS/SASL, passwords de keystore/truststore; nombres de topics que revelan procesos de negocio; payloads de mensajes en DEBUG (`org.apache.kafka.clients` en DEBUG expone el contenido completo — señalarlo como riesgo si aparece en QA/PROD); endpoints internos (hostnames/puertos de brokers, IPs de ZooKeeper/KRaft, URLs de Schema Registry); tokens OAuth/OIDC en logs DEBUG de cliente; credenciales de conectores de Kafka Connect hacia sistemas destino/origen.

## Patrones de error y advertencia

`under-replicated partitions` → followers desincronizados, revisar disk I/O/GC del follower. `ISR for partition X shrunk from Y to Z` → follower salió del ISR, comparar `replica.lag.time.max.ms` vs latencia real. `Leader election initiated` → normal en despliegues, sospechoso si es recurrente. `OffsetOutOfRange` → consumer detrás de retención o adelante del latest, revisar `log.retention.*` y lag previo. `UNKNOWN_TOPIC_OR_PARTITION` → topic no existe o fue eliminado. `Consumer group X is rebalancing` → normal en despliegues, anómalo si frecuente — revisar `session.timeout.ms`/`max.poll.interval.ms`. `Offset commit failed`/`CommitFailedException` → puede causar reprocesamiento. `Connection to broker-N could not be established` → firewall/red/DNS/estado del broker. `Disk full`/`IOException` en segments → retención vs tamaño real de datos. `OutOfMemoryError` en broker → heap (`KAFKA_HEAP_OPTS`), GC logs. `ZooKeeper session expired` → latencia de red, `zookeeper.session.timeout.ms`. `KRaft: leader not found` (3.x) → estado de voter nodes. `SSL handshake failed` → certificados/CN/cipher suites. `SASL authentication failed` → credenciales, JAAS, mecanismo (PLAIN/SCRAM/GSSAPI). `Producer request timeout` → `request.timeout.ms`/`acks`, estado del líder. `Message too large`/`RecordTooLargeException` → `message.max.bytes` vs tamaño real. `Log segment corruption`/`InvalidOffsetException` → verificar con `kafka-log-dirs.sh`.

**No diagnostiques under-replicated partitions como crítico sin conocer el replication.factor** — con `replication.factor=1` no hay followers y es normal.

## Consumer lag — señal crítica

Aunque el log no tenga la métrica exacta, señala lag creciente si aparece: `Lag increasing` (Streams), `poll() interval exceeded` (rebalanceo forzado), `Heartbeat thread will stop due to timeout` (perdió conectividad).

## ZooKeeper vs KRaft

| Aspecto | ZooKeeper (<3.0) | KRaft (3.x) |
|---|---|---|
| Controller election | `ZooKeeper session timeout`, `ResignLeadership` | `KRaft leader election`, `quorum state` |
| Salud del clúster | Ensemble ZooKeeper | Voter nodes KRaft |
| Partición huérfana | `controller epoch mismatch` | `KRaft epoch mismatch` |

## Kafka Connect

`FAILED` en connector/task → detenido, necesita reinicio. `RetriableException` repetida → retry loop, ver causa raíz. `WorkerSinkTask offset commit timeout` → excedió `offset.flush.timeout.ms`. `SchemaRegistryException` → Schema Registry no disponible o schema incompatible.

## Referencias

- Apache Kafka docs: https://kafka.apache.org/documentation/
- Operations: https://kafka.apache.org/documentation/#operations
- Configuration: https://kafka.apache.org/documentation/#configuration
- Confluent docs: https://docs.confluent.io/
- Kafka Connect: https://kafka.apache.org/documentation/#connect
- Kafka Streams: https://kafka.apache.org/documentation/streams/
- KRaft: https://kafka.apache.org/documentation/#kraft
- Strimzi/AMQ Streams: https://strimzi.io/documentation/
