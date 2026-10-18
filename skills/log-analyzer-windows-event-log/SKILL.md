---
name: log-analyzer-windows-event-log
description: "Analiza Windows Server Event Log (canales Application, System, Security, Setup y custom) y produce un diagnóstico estructurado. Úsalo cuando el log contenga campos Event ID/Source/Level/Task Category, canales Windows, o proveedores como Microsoft-Windows-Kernel-Power, Service Control Manager, Microsoft-Windows-Security-Auditing."
---

# Log Reader — Windows Server Event Log

**Regla fundamental: Event ID + Source son inseparables.** Un mismo Event ID significa cosas distintas según el Source. Siempre cita ambos, y nunca diagnostiques solo con el Event ID.

## Señales de detección
Campos `Event ID`/`Source`/`Level`/`Task Category`, canales `Application`, `System`, `Security`, `Setup`, proveedores `Microsoft-Windows-Kernel-Power`, `Service Control Manager`, `Microsoft-Windows-Security-Auditing`, extensión `.evtx` mencionada.

## Preguntar antes de analizar

| Situación | Pregunta |
|---|---|
| Canal no indicado | ¿De qué canal proviene el evento? (Application, System, Security, u otro custom) |
| Rol del servidor no declarado | ¿Tiene un rol específico? (Domain Controller, IIS, SQL Server, File Server, app custom) |
| Versión de Windows Server no indicada | ¿2012 R2, 2016, 2019, 2022? |
| Source no visible | ¿Puedes incluir el campo Source/Proveedor? |
| Entorno no declarado | ¿DEV, QA, STAGING o PROD? |
| Error de seguridad + dominio | ¿Pertenece a un dominio AD? |
| XML no incluido (canal Security) | El XML tiene campos adicionales críticos — ¿puedes incluirlo? |

## Datos sensibles a marcar en rojo

Credenciales en texto plano logueadas por servicios mal configurados, nombres de usuario/dominio (`DOMAIN\user`) en eventos de logon fallido (4625), SIDs (`S-1-5-21-...`), rutas de archivos internas, hostnames/FQDNs internos, connection strings en Application log, valores reales dentro de `<Data Name="...">` del XML.

## Event IDs críticos

**System:** 41 (Kernel-Power, apagado inesperado) · 6008 (EventLog, apagado previo inesperado) · 1001 (WER, crash dump) · 7000/7023/7031/7034 (SCM, fallos de servicio) · 7036 (cambio de estado de servicio).

**Application:** 1000 (Application Error, crash) · 1001 (WER) · 1002 (Application Hang) · 1026 (.NET Runtime, excepción no controlada).

**Security:** 4625 (logon fallido) · 4648 (logon con credenciales explícitas) · 4720 (cuenta creada) · 4740 (cuenta bloqueada) · 4776 (validación de credenciales en DC).

**IIS:** 2268 (inicio W3SVC) · errores de sitio/pool/bindings · 1026 (.NET Runtime en IIS).

## Guía de interpretación

1. Identificar el primer evento Critical/Error, no el cascade.
2. Verificar siempre Event ID + Source antes de diagnosticar.
3. Ordenar por timestamp para reconstruir la línea de tiempo.
4. Correlacionar entre canales (7034 en System suele originarse en 1000/1026 de Application).
5. Leer el XML (`<EventData>`) para eventos de Seguridad.
6. Detectar patrones de repetición (crash loops, intervalos regulares).

**Fallos de servicio (7000/7023/7031/7034):** ¿repite? ¿hay 1000/1026 contemporáneo? ¿código Win32 conocido (`0xC0000005` access violation, `1067` proceso terminó)?

**Seguridad — 4625 XML clave:** `LogonType` (2=interactivo, 3=red, 10=RDP), `SubStatus` (`0xC000006D` user/pass incorrectos, `0xC0000234` cuenta bloqueada, `0xC0000072` deshabilitada), `IpAddress`/`WorkstationName`. Para 4740: `CallerComputerName` — correlacionar con los 4625 previos.

**Crashes .NET (1026):** tratar el Description como stack trace, seguir `Inner exception:`/`--->`, identificar namespace/clase de código propio.

## Formato de reporte estándar

```
╔══════════════════════════════════════════════════════════════╗
║   REPORTE DE ANÁLISIS DE LOG — WINDOWS EVENT LOG              ║
╚══════════════════════════════════════════════════════════════╝
📋 RESUMEN EJECUTIVO
Tecnología: Windows Server [versión] / Canal: [Application|System|Security|...]
Entorno: [DEV/QA/STAGING/PROD/No declarado] | Período: [inicio] → [fin]
Diagnóstico breve: [1-2 frases]

🔴 HALLAZGOS CRÍTICOS
  #N Event ID + Source / Timestamp / Mensaje / Causa raíz / Hipótesis / Acción

🟡 ADVERTENCIAS / 🔵 EVENTOS NOTABLES
⚠️ DATOS SENSIBLES: <span style="color:red;font-weight:bold">valor</span>
❓ PREGUNTAS ABIERTAS / 🛠️ PRÓXIMOS PASOS
📤 ¿Deseas el reporte como documento entregable?
```

## Referencias
- https://learn.microsoft.com/en-us/windows/win32/eventlog/event-logging
- https://www.ultimatewindowssecurity.com/securitylog/encyclopedia/
- https://learn.microsoft.com/en-us/troubleshoot/windows-server/
- https://learn.microsoft.com/en-us/troubleshoot/windows-server/identity/account-lockout-event-logging
