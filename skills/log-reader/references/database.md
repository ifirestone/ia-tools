# Referencia: Bases de datos (PostgreSQL / Oracle / SQL Server)

Diferencia siempre el motor antes de diagnosticar — los tres tienen severidades, formatos y remediaciones incompatibles entre sí.

## Formatos

**PostgreSQL**: `YYYY-MM-DD HH:mm:ss.SSS TZ [PID] USUARIO@BASE_DATOS SEVERIDAD: mensaje`, seguido opcionalmente de líneas `DETAIL:`/`HINT:`/`CONTEXT:`/`STATEMENT:`.

**Oracle — Alert Log**: fecha + `Errors in file /u01/.../trace/SID_ora_PID.trc:` + código `ORA-NNNNN: ...`. El detalle real está en el `.trc` referenciado.

**SQL Server — Error Log**: `YYYY-MM-DD HH:mm:ss.ss spidNN Error: NNNN, Severity: NN, State: NN.` seguido del mensaje.

## Preguntar antes de interpretar

| Situación | Pregunta |
|---|---|
| Motor no identificado | ¿PostgreSQL, Oracle o SQL Server? El diagnóstico cambia completamente |
| Versión no declarada | Algunos errores/soluciones son version-specific |
| Entorno no declarado | ¿DEV, QA, STAGING o PROD? |
| Tabla/query sin contexto de app | ¿Qué operación de la aplicación disparó esta query? |
| Log truncado sin eventos previos | ¿Tienes el log completo con los eventos previos al error? |
| Error de conexión sin datos de pool | ¿Qué pool usa la app (HikariCP, C3P0, DBCP, PgBouncer) y su tamaño máximo? |
| Oracle: falta el .trc referenciado | ¿Puedes dar el contenido del .trc? Tiene el stack trace detallado |
| SQL Server: `spid` sin contexto | ¿Tienes `sys.dm_exec_sessions` o Extended Events de ese período? |
| PostgreSQL: autovacuum posiblemente bloqueado | ¿Hay algún proceso largo activo? (`pg_stat_activity WHERE state='active'`) |

## Datos sensibles específicos

Queries con datos de usuarios (`log_min_duration_statement` bajo o Slow Query Log con parámetros PII); credenciales en connection strings de intentos de conexión fallidos; nombres de usuario de BD (revelan usuarios válidos, especialmente en auth fallida); valores reales en Deadlock Trace (Oracle) / Deadlock Graph (SQL Server); hostnames/IPs de réplicas/standby/listeners/Data Guard; nombres de bases/schemas/tablespaces; `ORA-28000`/`ORA-01017` (usuario y estado de cuenta); actividad de cuentas `SA`/sysadmin.

Alerta especial: `log_min_duration_statement=0` en PostgreSQL loguea TODAS las queries con sus parámetros — riesgo de PII masivo si está así en QA/PROD.

## PostgreSQL — severidades y patrones

Severidades: PANIC (detiene el servidor) > FATAL (termina la sesión) > ERROR (aborta la transacción) > WARNING > NOTICE > INFO > LOG > DEBUG[1-5].

`deadlock detected` → revisar DETAIL para las queries involucradas, orden de acceso a tablas. `could not serialize access due to concurrent update` → retry en la app, revisar nivel de aislamiento. `remaining connection slots are reserved`/`connection limit exceeded for non-superusers` → `max_connections` agotado, considerar PgBouncer (urgente en el segundo caso). `autovacuum ... took NNN.NNN s` elevado → revisar bloat/lock contention (`pg_stat_activity`). `out of shared memory` → revisar `shared_buffers`/`work_mem`/`max_locks_per_transaction`. `canceling statement due to lock timeout` → identificar quién sostiene el lock (`pg_locks JOIN pg_stat_activity`). `duration: NNNN ms statement:` → slow query, usar EXPLAIN ANALYZE. `PANIC: could not write to file "pg_wal/..."` → disco WAL lleno, emergencia. `could not connect to the primary server` → standby perdió streaming replication. Checkpoint con `distance=` elevado → I/O lento, revisar `checkpoint_completion_target`/`max_wal_size`.

## Oracle — códigos ORA críticos

`ORA-00600`/`ORA-07445` → error interno/core dump, siempre abrir SR con Oracle Support y revisar el .trc. `ORA-01555` (snapshot too old) → aumentar `UNDO_RETENTION`, revisar queries largas. `ORA-04031` (shared memory) → aumentar `SHARED_POOL_SIZE`/AMM/ASMM. `ORA-27102` (out of memory) → límites del SO. `ORA-01000` (max open cursors) → cursor leaks en la app. `ORA-00054` (resource busy NOWAIT) → puede ser normal o contención. `ORA-00257` (archiver error) → disco de archive log lleno, emergencia — no se pueden confirmar transacciones. `ORA-01017` (invalid username/password) / `ORA-28000` (cuenta bloqueada) → verificar credenciales y desbloquear (`ALTER USER X ACCOUNT UNLOCK`). `ORA-12541` (no listener) → `lsnrctl status`. `ORA-03113`/`ORA-03114` → conexión cortada abruptamente, posible crash del proceso servidor.

## SQL Server — severidades y errores

Severidad: 1–10 informativo · 11–16 error de usuario · 17–19 error de recurso · 20–24 fatal con recovery · 25 fatal sin recovery (corrupción).

`Error: 1205, Severity: 13` (deadlock) → activar Deadlock Trace/Extended Events, ajustar orden de acceso. `Error: 701, Severity: 17` (insufficient system memory) → revisar `max server memory`. `Error: 17890` (trimmed from working set) → `max server memory` demasiado alto. `Error: 9002, Severity: 17` (transaction log full) → urgente, log backup + revisar modelo de recuperación. `Error: 823/824, Severity: 24` (I/O error / logical consistency) → `DBCC CHECKDB`, revisar hardware — recomendar SR/soporte inmediatamente. `Login failed for user 'X'` → credenciales, estado de cuenta, restricciones IP. `A significant part of sql server process memory has been paged out` → `Lock Pages in Memory`, revisar `max server memory`.

## Referencias

- PostgreSQL docs: https://www.postgresql.org/docs/current/
- PostgreSQL error codes: https://www.postgresql.org/docs/current/errcodes-appendix.html
- Autovacuum tuning: https://www.postgresql.org/docs/current/runtime-config-autovacuum.html
- My Oracle Support: https://support.oracle.com/
- Oracle docs: https://docs.oracle.com/en/database/oracle/oracle-database/
- Undo retention: https://docs.oracle.com/en/database/oracle/oracle-database/19/admin/managing-undo.html
- SQL Server docs: https://learn.microsoft.com/en-us/sql/sql-server/
- SQL Server error codes: https://learn.microsoft.com/en-us/sql/relational-databases/errors-events/
- Deadlock troubleshooting: https://learn.microsoft.com/en-us/sql/relational-databases/sql-server-deadlocks-guide
