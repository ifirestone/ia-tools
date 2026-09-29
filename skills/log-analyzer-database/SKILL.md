---
name: log-analyzer-database
description: "Analiza logs de bases de datos (PostgreSQL, Oracle, SQL Server) y produce un diagnóstico estructurado. Úsalo cuando el log contenga USUARIO@BASE_DATOS SEVERIDAD: (PostgreSQL), ORA-XXXXX o alert_SID.log (Oracle), o spid/Error: NNNN, Severity: NN (SQL Server)."
---

# Log Reader — Bases de datos (PostgreSQL / Oracle / SQL Server)

**Diferencia siempre el motor antes de diagnosticar — los tres tienen severidades, formatos y remediaciones incompatibles.**

## Señales de detección
- PostgreSQL: `USUARIO@BASE_DATOS SEVERIDAD:`, `DETAIL:`/`HINT:`/`STATEMENT:`.
- Oracle: códigos `ORA-XXXXX`, `alert_<SID>.log`.
- SQL Server: `spid`, `Error: NNNN, Severity: NN`.

## Preguntar antes de analizar

| Situación | Pregunta |
|---|---|
| Motor no identificado | ¿PostgreSQL, Oracle o SQL Server? |
| Versión no declarada | Algunos errores/soluciones son version-specific |
| Entorno no declarado | ¿DEV, QA, STAGING o PROD? |
| Error de conexión sin datos de pool | ¿Qué pool usa la app (HikariCP, PgBouncer) y su tamaño máximo? |
| Oracle: falta el .trc referenciado | ¿Puedes dar el contenido del .trc? Tiene el stack trace detallado |
| PostgreSQL: autovacuum posiblemente bloqueado | ¿Hay algún proceso largo activo? (`pg_stat_activity WHERE state='active'`) |

## Datos sensibles a marcar en rojo

Queries con datos de usuarios, credenciales en connection strings fallidas, nombres de usuario de BD (revelan usuarios válidos), valores reales en Deadlock Trace/Graph, hostnames/IPs de réplicas/standby, nombres de schemas/tablespaces, actividad de cuentas `SA`/sysadmin.

**Riesgo de configuración:** `log_min_duration_statement=0` en PostgreSQL loguea TODAS las queries con parámetros — riesgo PII masivo en QA/PROD.

## PostgreSQL

Severidades: PANIC > FATAL > ERROR > WARNING > NOTICE > INFO > LOG > DEBUG[1-5].

`deadlock detected` → revisar DETAIL para queries. `remaining connection slots are reserved` → `max_connections` agotado, considerar PgBouncer (urgente). `could not serialize access due to concurrent update` → retry en la app. `autovacuum ... took NNN s` elevado → bloat/lock contention. `out of shared memory` → revisar `shared_buffers`/`work_mem`. `canceling statement due to lock timeout` → `pg_locks JOIN pg_stat_activity`. `duration: NNNN ms` → slow query, usar EXPLAIN ANALYZE. `PANIC: could not write to file "pg_wal/..."` → disco WAL lleno, emergencia. `could not connect to the primary server` → standby perdió streaming replication.

## Oracle

`ORA-00600`/`ORA-07445` → error interno, abrir SR con Oracle Support + revisar .trc. `ORA-01555` (snapshot too old) → aumentar `UNDO_RETENTION`. `ORA-04031` (shared memory) → aumentar `SHARED_POOL_SIZE`. `ORA-00257` (archiver error) → disco de archive log lleno, emergencia. `ORA-01017`/`ORA-28000` → credenciales/cuenta bloqueada, `ALTER USER X ACCOUNT UNLOCK`. `ORA-01000` (max open cursors) → cursor leaks en la app. `ORA-12541` → `lsnrctl status`.

## SQL Server

Severidad: 1–10 informativo · 11–16 usuario · 17–19 recurso · 20–24 fatal con recovery · 25 fatal sin recovery.

`Error: 1205` (deadlock) → activar Deadlock Trace/Extended Events. `Error: 9002` (transaction log full) → urgente, log backup. `Error: 823/824, Severity: 24` (I/O/corrupción) → `DBCC CHECKDB`, escalar soporte inmediatamente. `Login failed for user` → credenciales, estado de cuenta. `sql server process memory has been paged out` → `Lock Pages in Memory`, revisar `max server memory`.

## Formato de reporte estándar

```
╔══════════════════════════════════════════════════════════════╗
║   REPORTE DE ANÁLISIS DE LOG — BASE DE DATOS                 ║
╚══════════════════════════════════════════════════════════════╝
📋 RESUMEN EJECUTIVO
Tecnología: [PostgreSQL|Oracle|SQL Server] [versión]
Entorno: [DEV/QA/STAGING/PROD/No declarado]
Componente(s): [BD/instancia/SID]
Período log: [inicio] → [fin]
Total eventos: [N críticos] | [N warnings] | [N notables]
Diagnóstico breve: [1-2 frases]

🔴 HALLAZGOS CRÍTICOS / 🟡 ADVERTENCIAS / 🔵 EVENTOS NOTABLES
⚠️ DATOS SENSIBLES: Valor: <span style="color:red;font-weight:bold">valor</span>
❓ PREGUNTAS ABIERTAS / 🛠️ PRÓXIMOS PASOS
📤 ¿Deseas el reporte como documento entregable (Word/Markdown)?
```

## Referencias
- https://www.postgresql.org/docs/current/
- https://www.postgresql.org/docs/current/errcodes-appendix.html
- https://docs.oracle.com/en/database/oracle/oracle-database/
- https://learn.microsoft.com/en-us/sql/sql-server/
- https://learn.microsoft.com/en-us/sql/relational-databases/sql-server-deadlocks-guide
