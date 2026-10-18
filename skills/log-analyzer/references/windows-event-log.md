# Referencia: Windows Server Event Log

## Alcance

Canales: Application, System, Security, Setup, Forwarded Events, y canales custom (IIS, PowerShell, Windows Defender, SCOM).

Campos de un evento: Event ID, Source, Level (Critical/Error/Warning/Information/Verbose), Task Category, Keywords, User, Computer, Date and Time, Description/Message, XML Data.

**Regla fundamental: Event ID + Source son inseparables.** Un mismo Event ID significa cosas distintas según el Source. Siempre cita ambos al referenciar un evento, y nunca diagnostiques solo con el Event ID.

## Preguntar antes de interpretar

| Situación | Pregunta |
|---|---|
| Canal no indicado | ¿De qué canal proviene el evento? (Application, System, Security, u otro custom) |
| Rol del servidor no declarado | ¿El servidor tiene un rol específico? (Domain Controller, IIS, SQL Server, File Server, app custom) |
| Formato de exportación no claro | ¿Están exportados como .evtx, CSV, texto plano, o pegados del Event Viewer? |
| Versión de Windows Server no indicada | ¿2012 R2, 2016, 2019, 2022? |
| Source no visible | ¿Puedes incluir el campo Source/Proveedor? |
| Servicio no identificado | ¿Es un servicio estándar de Windows o custom? |
| Log fragmentado | ¿Tienes el Event Log completo o solo este fragmento? |
| Error de seguridad + dominio | ¿Pertenece a un dominio AD? ¿AD DS, Azure AD Join, Workgroup? |
| XML no incluido (canal Security) | El XML tiene campos adicionales críticos — ¿puedes incluirlo? |
| Entorno no declarado | ¿DEV, QA, STAGING o PROD? |

## Datos sensibles específicos

Credenciales en texto plano logueadas por servicios mal configurados; nombres de usuario/dominio (`DOMAIN\user`) en eventos de logon fallido (4625); SIDs (`S-1-5-21-...`); rutas de archivos internas; hostnames/FQDNs internos; connection strings en Application log; valores reales dentro de `<Data Name="...">` del XML del evento.

## Event IDs críticos

**System:** 41 (Kernel-Power, apagado inesperado) · 6008 (EventLog, apagado previo inesperado) · 1001 (WER, crash dump) · 7000/7023/7031/7034 (Service Control Manager, fallos de servicio) · 7036 (cambio de estado de servicio).

**Application:** 1000 (Application Error, crash) · 1001 (WER) · 1002 (Application Hang) · 1026 (.NET Runtime, excepción no controlada).

**Security:** 4625 (logon fallido) · 4648 (logon con credenciales explícitas) · 4720 (cuenta creada) · 4740 (cuenta bloqueada) · 4776 (validación de credenciales en DC).

**IIS:** 2268 (inicio W3SVC) · eventos W3SVC (errores de sitio/pool/bindings) · 1026 (.NET Runtime en IIS).

## Guía de interpretación

1. Identificar el primer evento Critical/Error de la cadena, no el cascade.
2. Verificar siempre Event ID + Source antes de diagnosticar.
3. Ordenar por timestamp para reconstruir la línea de tiempo.
4. Correlacionar entre canales (un 7034 en System suele originarse en un 1000/1026 de Application).
5. Leer el XML (`<EventData>`) para eventos de Seguridad — el texto visible suele ser insuficiente.
6. Detectar patrones de repetición (crash loops, intervalos regulares).

**Fallos de servicio (7000/7023/7031/7034):** ¿estándar o custom? ¿repite (crash loop)? ¿hay 1000/1026 contemporáneo en Application? ¿el código de error es un Win32 conocido (`0xC0000005` access violation, `0x0000006D` broken pipe, `1067` proceso terminó)?

**Eventos de Seguridad — campos XML clave:**
- 4625: `LogonType` (2=interactivo, 3=red, 7=desbloqueo, 10=RDP); `FailureReason`/`Status`/`SubStatus` (`0xC000006D` user/pass incorrectos, `0xC000006F` fuera de horario, `0xC0000234` cuenta bloqueada, `0xC0000072` cuenta deshabilitada); `IpAddress`/`WorkstationName`.
- 4740: `CallerComputerName` — correlacionar con los 4625 previos del mismo usuario/DC.

**Crashes .NET (1026):** tratar el Description como stack trace — identificar tipo de excepción, seguir `Inner exception:`/`--->` hacia adentro, identificar namespace/clase de código propio (no del runtime), correlacionar con el Event ID 1000 para confirmar el ejecutable.

## Referencias

- Windows Event Log: https://learn.microsoft.com/en-us/windows/win32/eventlog/event-logging
- Enciclopedia Event IDs (Security): https://www.ultimatewindowssecurity.com/securitylog/encyclopedia/
- Troubleshooting Windows Server: https://learn.microsoft.com/en-us/troubleshoot/windows-server/
- Service Control Manager: https://learn.microsoft.com/en-us/windows/win32/services/service-control-manager
- Kernel-Power Event 41: https://learn.microsoft.com/en-us/troubleshoot/windows-client/performance/stop-error-or-unexpected-restart
- Auditoría de seguridad: https://learn.microsoft.com/en-us/windows/security/threat-protection/auditing/
- Account Lockout: https://learn.microsoft.com/en-us/troubleshoot/windows-server/identity/account-lockout-event-logging
- IIS Event Log: https://learn.microsoft.com/en-us/iis/configuration/system.applicationhost/log/
- Windows Error Codes: https://learn.microsoft.com/en-us/windows/win32/debug/system-error-codes
