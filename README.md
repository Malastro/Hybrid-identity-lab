# Despliegue de Identidad Híbrida: Windows Server 2022 AD DS & Microsoft Entra ID

## 1. Descripción del proyecto

Laboratorio personal de identidad híbrida que integra Windows Server 2022 Active Directory Domain Services (AD DS) con Microsoft Entra ID mediante Microsoft Entra Connect Sync.

El objetivo es practicar la creación y organización de identidades en un dominio local, automatizar el aprovisionamiento básico de usuarios y grupos con PowerShell y comprobar su sincronización con el entorno cloud.

El laboratorio utiliza una organización ficticia, *Mirador de Montepinar SL*, mítica serie donde ha ocurrido casi todo lo imaginable y que por primera vez, van a contar con una solución centralizada para aprovisionar y desaprovisionar usuarios. El objetivo tambien es documentar la configuración realizada, las decisiones técnicas y las comprobaciones efectuadas durante el despliegue.

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

![Grupos sincronizados en Entra ID](04-EntraGroupsSincronizados.png)

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
