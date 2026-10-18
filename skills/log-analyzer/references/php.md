# Referencia: PHP (runtime)

Cubre el runtime y SAPIs de PHP. Si el log muestra claramente un framework encima (Laravel, Symfony, etc.), preferir esa referencia si existe — esta cubre errores de PHP puro, extensiones y PHP-FPM.

## Alcance

PHP 7.4/8.0-8.3. SAPIs: `php-fpm` (detrás de nginx/Apache), `mod_php` (embebido en Apache), CLI. Extensiones comunes: PDO/mysqli/pgsql, cURL, OPcache, Xdebug. Gestores de dependencias: Composer (autoload PSR-4).

Formatos:
- **Errores de PHP** (a `error_log`, stdout, o archivo configurado en `php.ini`): `PHP Fatal error:  mensaje in /ruta/archivo.php on line N`, `PHP Warning:`, `PHP Notice:`/`PHP Deprecated:`, seguido opcionalmente de `Stack trace:` con frames `#0 /ruta(N): funcion()` terminando en `#N {main}`.
- **php-fpm** (log del master/pool, no del error de PHP): `[DD-Mon-YYYY HH:mm:ss] NOTICE/WARNING/ERROR: mensaje`, eventos de pool (`[pool www] child N started`, `child N said into stderr: ...`, `child N exited on signal ...`).

## Preguntar antes de interpretar

| Situación | Pregunta |
|---|---|
| Versión de PHP no indicada | ¿7.4, 8.0, 8.1, 8.2, 8.3? Cambia comportamiento de tipos y deprecaciones |
| SAPI no clara | ¿php-fpm, mod_php, o CLI? Afecta dónde buscar configuración y logs |
| `display_errors` en el log | ¿Este log es de PROD? Si `display_errors=On` en PROD es un riesgo de exposición, señalarlo |
| Extensión de terceros involucrada | ¿Qué extensión/paquete Composer está en el stack trace? ¿Versión? |
| Solo un Warning/Notice sin contexto | ¿Hay un Fatal error asociado, o el Warning es el único síntoma reportado? |
| php-fpm: pool no identificado | ¿Qué pool (`[pool X]`) generó el evento? Puede haber varios pools con distinta config |
| Log truncado | ¿Tenés el stack trace completo hasta `#N {main}`? |

## Datos sensibles específicos

Connection strings en mensajes de PDO/mysqli (`mysqli_connect(): (HY000/1045): Access denied for user 'X'@'host' (using password: YES)` revela el usuario); valores de superglobales (`$_GET`, `$_POST`, `$_SERVER`) volcados en stack traces o `var_dump`/`print_r` dejados en el código; session IDs (`PHPSESSID`); API keys hardcodeadas visibles en el mensaje de error si el código las interpola directo en la excepción.

## Patrones de error frecuentes

`PHP Fatal error: Uncaught Error: Call to undefined method X::y()` → método no existe o typo, revisar la clase real. `PHP Fatal error: Uncaught Error: Class "X" not found` → falta `require`/`use`, o problema de autoload de Composer (`composer dump-autoload`). `Allowed memory size of N bytes exhausted` → `memory_limit` insuficiente o memory leak (loop cargando datos sin liberar). `Maximum execution time of N seconds exceeded` → `max_execution_time`, operación lenta (query, API externa) sin timeout propio. `PDOException: SQLSTATE[HY000] [2002] Connection refused` → BD no accesible desde este host/puerto. `PDOException: SQLSTATE[42S02]: Base table or view not found` → tabla no existe o migración no corrida. `PHP Warning: Undefined array key "X"` (PHP 8+, antes era Notice) → acceso a índice inexistente, común tras cambios de API externa. `PHP Deprecated: Implicit conversion from float to int loses precision` → típico en upgrades 7.4→8.x. `Failed opening required '/ruta' (include_path='...')` → ruta incorrecta o permisos de archivo. php-fpm: `child exited on signal 11 (SIGSEGV)` → crash de una extensión nativa (revisar extensiones recientemente actualizadas), `server reached max_children setting, consider raising it` → pool saturado, subir `pm.max_children` o investigar requests lentos que agotan los workers.

## Referencias

- PHP Manual: https://www.php.net/manual/es/
- PHP-FPM: https://www.php.net/manual/es/install.fpm.php
- Error reporting: https://www.php.net/manual/es/errorfunc.configuration.php
- Composer autoload: https://getcomposer.org/doc/01-basic-usage.md#autoloading
- PDO error handling: https://www.php.net/manual/es/pdo.error-handling.php
- Migración PHP 8: https://www.php.net/manual/es/migration80.php
