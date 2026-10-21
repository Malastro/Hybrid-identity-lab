# Despliegue de Identidad Híbrida: Windows Server 2022 AD DS & Microsoft Entra ID

## 1. Descripción del Proyecto
Implementación y securización de una arquitectura de identidad híbrida para la organización ficticia *Mirador de Montepinar S.L.* Mítica serie en donde ha ocurrido todo lo imaginable, sin embargo, aunque alguna vez hayan actuado como una gran empresa, nunca han tenido su propio tenant. El objetivo es centralizar la gestión de identidades corporativas en un Directorio Activo on-premises y sincronizarlas de forma controlada y selectiva hacia Microsoft Entra ID mediante el agente **Microsoft Entra Connect Sync**.

---

## 2. Topología y Componentes

| Entorno | Componente | Especificaciones | Rol / Función |
| :--- | :--- | :--- | :--- |
| **On-Premises** | `MONTEPINAR` | Windows Server 2022 Datacenter | Domain Controller (`montepinar.local`) |
| **On-Premises** | Script PowerShell | Automatización de aprovisionamiento | Creación de OUs, usuarios y grupos |
| **Híbrido** | Entra Connect | v2.x (Password Hash Sync) | Motor de sincronización local -> cloud |
| **Cloud** | Microsoft Entra ID | Tenant corporativo (`malastro.onmicrosoft.com`) | Directorio y proveedor de identidad cloud |

---

## 3. Fases de Implementación

### Fase 1: Estructura Local de Active Directory y Aprovisionamiento
Se diseñó un árbol jerárquico de Unidades Organizativas (OUs) aislando la infraestructura corporativa bajo `OU=Montepinar`, dividida en `OU=Usuarios` y `OU=Grupos`. 

El aprovisionamiento de las identidades (*Antonio Recio*, *Enrique Pastor*) y del grupo de seguridad (*Directiva-Montepinar*) se ejecutó mediante PowerShell, alineando el atributo `userPrincipalName` con el espacio de nombres verificado en la nube para permitir el inicio de sesión unificado.

![Estructura Local AD](01-AD-Estructura.png)
![Grupo Local en AD](01.5-Grupo.png)

---

### Fase 2: Configuración de Microsoft Entra Connect
Se optó por el modelo **Connect Sync** con **Password Hash Synchronization (PHS)** para garantizar resiliencia ante caídas del enlace local y soporte para evaluación continua de riesgos.

* **Source Anchor:** Delegado a Azure (`mS-DS-ConsistencyGuid`), asegurando la persistencia de los objetos sincronizados independientemente de modificaciones en el nombre o traslados de OU.
* **Filtrado granular por OU:** Para aplicar el principio de mínimo privilegio y reducir la superficie de exposición, se desmarcó el bosque completo y se restringió la sincronización únicamente a la `OU=Montepinar`. Cuentas del sistema, equipos locales y cuentas administrativas Tier 0 quedaron expresamente fuera de la nube.

![Filtrado selectivo por OU](02-EntraConnect.png)

---

### Fase 3: Verificación y Replicación Cloud
Tras el ciclo inicial de sincronización, se verificó en el portal de Microsoft Entra la correcta ingesta de las identidades híbridas:

* Cuentas de usuario aprovisionadas con el atributo `On-premises sync enabled = Yes`.
* Grupo de seguridad instanciado con origen `Windows Server AD` preservando sus miembros de forma íntegra.

![Usuarios sincronizados en Entra ID](03-EntraUserSincronizados.png)

![Grupos sincronizados en Entra ID](04-EntraGruposSincronizados.png)

---

## 4. Consideraciones de Seguridad y Arquitectura

* **Aislamiento de Servidores Tier 0:** Siguiendo las directrices del modelo de acceso empresarial de Microsoft, en un entorno de producción los Controladores de Dominio tienen la navegación web deshabilitada para prevenir exploits de navegador y robo de credenciales. La administración se delega a PAWs (*Privileged Access Workstations*).
* **Gestión de Sesiones Administrativas:** Para las credenciales de Administrador Global utilizadas durante el despliegue se configuraron tokens no persistentes (*Stay signed in = No*) para mitigar riesgos de secuestro de tokens de sesión (*Session Hijacking*).
* **Filtrado defensivo:** Sincronizar únicamente Unidades Organizativas específicas previene la exposición accidental de cuentas con privilegios locales en entornos cloud donde podrían no contar con controles MFA o políticas de acceso condicional iniciales.

---

## 5. Validación mediante CLI
Comandos ejecutados en el servidor para supervisión del agente:

```powershell
# Comprobar estado del programador de sincronización
Get-ADSyncScheduler

# Forzar ciclo de replicación diferencial (Delta Sync)
Start-ADSyncSyncCycle -PolicyType Delta
