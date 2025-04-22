Descrizione dello Script Samba per Ambiente Aziendale

Autore: Luca Sabato, System Admin Linux Senior @ Ministero Italiana
Licenza: GNU GPLv3 (modificabile a piacere con attribuzione)
🇮🇹 Spiegazione in Italiano
📌 Scopo dello Script

Questo script automatizza l'installazione e la configurazione di un server Samba per ambienti aziendali con struttura gerarchica avanzata.
È progettato per:

    Installare Samba su Rocky Linux/RHEL con configurazioni ottimizzate per sicurezza e performance.

    Creare gruppi e utenti con permessi differenziati (es: boss, manager, dipendenti).

    Configurare cartelle condivise con ACL (Access Control List) per limitare l'accesso ai soli gruppi autorizzati.

    Disabilitare cartelle personali per la maggior parte degli utenti (tranne dirigenti).

🔧 Campi Personalizzabili
Campo	Descrizione	Esempio
BASE_DIR	Directory principale delle condivisioni	/srv/datiserver
PASSWORD	Password predefinita per tutti gli utenti (da cambiare dopo il setup!)	Zz123456789!!
WORKGROUP	Nome del workgroup Samba (deve matchare la rete)	micronet
SAMBA_SHARE_NAME	Nome della condivisione visibile in rete	company_data
Gruppi	Nomi dei gruppi gerarchici	boss_admin_company
Utenti	Lista di utenti (nome.cognome) associati ai gruppi	luca.droi, mirko.talbo
🛡️ Sicurezza e Compliance

    SELinux integrato con contesti corretti per Samba.

    Firewall preconfigurato per permettere solo traffico Samba.

    Password complesse forzate via script (ma è fondamentale cambiarle dopo il deployment).

    Veto files per bloccare l'upload di file pericolosi (.exe, .bat, etc.).

🚀 Funzionalità Avanzate

    Ereditarietà permessi: Le nuove cartelle ereditano automaticamente i permessi del gruppo (grazie al bit setgid).

    Logging dettagliato: Tutte le operazioni sono loggate in /var/log/samba_setup.log.

    Compatibilità AD-DC: Struttura simile a un dominio Active Directory con gruppi nidificati.

👨‍💻 Perché usarlo?

Se lavori in un ambiente ministeriale o aziendale con:

    Necessità di isolare reparti (es: HR vs Finanza vs Logistica).

    Requisiti di audit e tracciamento degli accessi.

    Automazione di deployment per ridurre errori umani.








🇬🇧 English Explanation
📌 Script Purpose

This script automates the installation and configuration of a Samba server for enterprise environments with advanced hierarchical permissions.
It is designed to:

    Install Samba on Rocky Linux/RHEL with security and performance optimizations.

    Create groups and users with tiered permissions (e.g., bosses, managers, employees).

    Configure shared folders with ACLs to restrict access to authorized groups only.

    Disable home directories for most users (except executives).

🔧 Customizable Fields
Field	Description	Example
BASE_DIR	Main share directory	/srv/datiserver
PASSWORD	Default password for all users (change after setup!)	Zz123456789!!
WORKGROUP	Samba workgroup name (must match network)	micronet
SAMBA_SHARE_NAME	Network-visible share name	company_data
Groups	Hierarchical group names	boss_admin_company
Users	List of users (firstname.lastname) assigned to groups	luca.droi, mirko.talbo
🛡️ Security & Compliance

    SELinux integrated with correct contexts for Samba.

    Firewall preconfigured to allow only Samba traffic.

    Complex passwords enforced by script (but must be changed post-deployment).

    Veto files to block dangerous file uploads (.exe, .bat, etc.).

🚀 Advanced Features

    Permission inheritance: New folders inherit group permissions (via setgid bit).

    Detailed logging: All operations logged to /var/log/samba_setup.log.

    AD-DC-like structure: Nested group permissions similar to Active Directory.

👨‍💻 Why Use It?

Ideal for government or corporate environments needing:

    Department isolation (e.g., HR vs Finance vs Logistics).

    Audit and access tracking requirements.

    Deployment automation to reduce human error.

















# Samba Enterprise Setup Script  
**Author**: Luca Sabato | Senior Linux System Admin @ Italian Ministry  

## 📜 Features  
- One-click deployment of Samba with hierarchical permissions.  
- Ready for compliance with Italian PA security standards.  

## 🛠️ Customization  
Edit these variables in the script:  
```bash
BASE_DIR="/srv/datiserver"                  # Main share path  
WORKGROUP="micronet"                        # Match your network  
SAMBA_SHARE_NAME="company_data"             # Visible share name  





    
