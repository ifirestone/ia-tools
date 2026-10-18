---
name: log-analyzer-php
description: "Analiza logs del runtime PHP (php-fpm, mod_php, CLI) y produce un diagnóstico estructurado. Úsalo cuando el log contenga PHP Fatal error:, PHP Warning:, PHP Deprecated:, PHP Parse error:, Stack trace: con frames #0 {main}, o eventos de pool [pool www] de php-fpm — sin señales de Laravel/Illuminate."
---

# Log Reader — PHP (runtime)

Si el log muestra `Illuminate\` o `storage/logs/laravel.log`, usar `log-analyzer-laravel` en su lugar.

## Señales de detección
`PHP Fatal error:`, `PHP Warning:`, `PHP Deprecated:`, `PHP Parse error:`, `Stack trace:` con `#0 {main}`, formato de pool `[pool www]` de php-fpm — **sin** señales de Laravel.

## Preguntar antes de analizar

| Situación | Pregunta |
|---|---|
| Versión de PHP no indicada | ¿7.4, 8.0, 8.1, 8.2, 8.3? Cambia comportamiento de tipos y deprecaciones |
| SAPI no clara | ¿php-fpm, mod_php, o CLI? |
| `display_errors` en el log de PROD | Si `display_errors=On` en PROD es riesgo de exposición — señalarlo |
| Solo un Warning/Notice sin contexto | ¿Hay un Fatal error asociado, o el Warning es el único síntoma? |
| php-fpm: pool no identificado | ¿Qué pool (`[pool X]`) generó el evento? |
| Log truncado | ¿Tienes el stack trace completo hasta `#N {main}`? |

## Datos sensibles a marcar en rojo

Connection strings en mensajes de PDO/mysqli (revela el usuario de BD), valores de superglobales (`$_GET`, `$_POST`, `$_SERVER`) volcados en stack traces o `var_dump`/`print_r` dejados en el código, session IDs (`PHPSESSID`), API keys hardcodeadas interpoladas en el mensaje de error.

## Patrones de error frecuentes

`PHP Fatal error: Uncaught Error: Call to undefined method X::y()` → método no existe o typo, revisar la clase real. `PHP Fatal error: Uncaught Error: Class "X" not found` → falta `require`/`use`, o problema de autoload de Composer (`composer dump-autoload`). `Allowed memory size of N bytes exhausted` → `memory_limit` insuficiente o memory leak (loop cargando datos sin liberar). `Maximum execution time of N seconds exceeded` → `max_execution_time`, operación lenta sin timeout propio. `PDOException: SQLSTATE[HY000] [2002] Connection refused` → BD no accesible desde este host/puerto. `PDOException: SQLSTATE[42S02]: Base table or view not found` → tabla no existe o migración no corrida. `PHP Warning: Undefined array key "X"` (PHP 8+) → acceso a índice inexistente, común tras cambios de API externa. `PHP Deprecated: Implicit conversion from float to int` → típico en upgrades 7.4→8.x. `Failed opening required '/ruta'` → ruta incorrecta o permisos de archivo.

**php-fpm:** `child exited on signal 11 (SIGSEGV)` → crash de extensión nativa, revisar extensiones actualizadas recientemente. `server reached max_children setting, consider raising it` → pool saturado, subir `pm.max_children` o investigar requests lentos.

## Formato de reporte estándar

```
╔══════════════════════════════════════════════════════════════╗
║   REPORTE DE ANÁLISIS DE LOG — PHP                            ║
╚══════════════════════════════════════════════════════════════╝
📋 RESUMEN EJECUTIVO
Tecnología: PHP [versión] / [php-fpm|mod_php|CLI]
Entorno: [DEV/QA/STAGING/PROD/No declarado]
Componente(s): [aplicación/pool]
Período log: [inicio] → [fin]
Total eventos: [N críticos] | [N warnings] | [N notables]
Diagnóstico breve: [1-2 frases]

🔴 HALLAZGOS CRÍTICOS / 🟡 ADVERTENCIAS / 🔵 EVENTOS NOTABLES
⚠️ DATOS SENSIBLES: Valor: <span style="color:red;font-weight:bold">valor</span>
❓ PREGUNTAS ABIERTAS / 🛠️ PRÓXIMOS PASOS
📤 ¿Deseas el reporte como documento entregable (Word/Markdown)?
```

## Referencias
- https://www.php.net/manual/es/
- https://www.php.net/manual/es/install.fpm.php
- https://www.php.net/manual/es/errorfunc.configuration.php
- https://getcomposer.org/doc/01-basic-usage.md#autoloading
- https://www.php.net/manual/es/migration80.php
