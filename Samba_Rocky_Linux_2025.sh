#!/bin/bash

# Unified Samba Installation and User Configuration Script
# Version: 2.2
# Author: Luca Sabato, SystemAdmin, defence ITA   
# Date: 22-04-2025
# Description: Installs Samba Server and configures users/groups with hierarchical permissions advanced

# Global Configuration
BASE_DIR="/srv/datiserver"
PASSWORD="Zz123456789!!"
WORKGROUP="micronet"
SAMBA_SHARE_NAME="company_data"
LOG_FILE="/var/log/samba_setup.log"

# Initialize log file
exec > >(tee -a "$LOG_FILE") 2>&1
echo "Samba Setup Script - $(date)"
echo "----------------------------------------"
echo

# Check if running as root
if [ "$(id -u)" -ne 0 ]; then
    echo "ERROR: This script must be run as root"
    exit 1
fi

# Function to log and execute commands
run_cmd() {
    echo "Executing: $@"
    "$@"
    local status=$?
    if [ $status -ne 0 ]; then
        echo "ERROR: Command failed with exit code $status: $@"
        exit $status
    fi
    return $status
}

# ==============================================
# PART 1: SAMBA SERVER INSTALLATION
# ==============================================

echo "===== INSTALLING SAMBA SERVER ====="

# Update system
run_cmd dnf update -y

# Install required packages
run_cmd dnf install -y samba samba-common samba-client \
    policycoreutils-python-utils setools-console \
    firewalld oddjob-mkhomedir authselect-compat \
    setools-console policycoreutils-python-utils

# Create base directory structure
run_cmd mkdir -p "$BASE_DIR"
run_cmd chmod 1777 "$BASE_DIR"
run_cmd chown nobody:nobody "$BASE_DIR"

# Enable and start services
run_cmd systemctl enable --now smb
run_cmd systemctl enable --now nmb
run_cmd systemctl enable --now firewalld

# Configure firewall
run_cmd firewall-cmd --permanent --add-service=samba
run_cmd firewall-cmd --reload

# Backup original config file
CONFIG_FILE="/etc/samba/smb.conf"
run_cmd cp "$CONFIG_FILE" "${CONFIG_FILE}.bak_$(date +%Y%m%d%H%M%S)"

# Create new Samba configuration
TMP_FILE=$(mktemp)
cat > "$TMP_FILE" << 'EOL'
[global]
        workgroup = WORKGROUP
        server string = Samba Server %v
        netbios name = micronet
        security = user
        passdb backend = tdbsam
        map to guest = Bad User
        log file = /var/log/samba/log.%m
        max log size = 50
        logging = file
        panic action = /usr/share/samba/panic-action %d
        server role = standalone server
        obey pam restrictions = yes
        unix password sync = yes
        passwd program = /usr/bin/passwd %u
        passwd chat = *Enter\snew\s*\spassword:* %n\n *Retype\snew\s*\spassword:* %n\n *password\supdated\ssuccessfully* .
        pam password change = yes
        map archive = no
        map hidden = no
        map read only = no
        map system = no
        store dos attributes = yes
        vfs objects = acl_xattr
        inherit acls = yes
        inherit permissions = yes
        ea support = yes
        disable spoolss = yes
        load printers = no
        printing = bsd
        printcap name = /dev/null
        disable netbios = no
        dns proxy = no
        socket options = TCP_NODELAY SO_RCVBUF=8192 SO_SNDBUF=8192
        strict locking = no
        use sendfile = yes
        min receivefile size = 16384
        aio read size = 16384
        aio write size = 16384
        write cache size = 524288
        getwd cache = yes
        large readwrite = yes
        smb2 leases = yes
        kernel oplocks = no

[SHARE_NAME]
        path = BASE_DIRECTORY
        browsable = yes
        writable = yes
        guest ok = no
        read only = no
        create mask = 0770
        directory mask = 0770
        force create mode = 0770
        force directory mode = 0770
        force security mode = 0770
        force directory security mode = 0770
        inherit owner = yes
        inherit acls = yes
        inherit permissions = yes
        valid users = @boss_admin_company, @vice_boss_admin_company, @manager_company, @empoyed_company, @magazinework_company, @deliverywork_company
        access based share enum = yes
        hide unreadable = yes
        veto files = /*.exe/*.com/*.dll/*.bat/*.vbs/*.tmp/
        delete veto files = yes
EOL

# Replace placeholders in config file
sed -i "s/WORKGROUP/$WORKGROUP/g" "$TMP_FILE"
sed -i "s/SHARE_NAME/$SAMBA_SHARE_NAME/g" "$TMP_FILE"
sed -i "s|BASE_DIRECTORY|$BASE_DIR|g" "$TMP_FILE"

# Install the new config file
run_cmd mv "$TMP_FILE" "$CONFIG_FILE"
run_cmd chmod 644 "$CONFIG_FILE"

# Configure SELinux for Samba
run_cmd setsebool -P samba_export_all_rw on
run_cmd setsebool -P samba_enable_home_dirs off
run_cmd semanage fcontext -a -t samba_share_t "$BASE_DIR(/.*)?"
run_cmd restorecon -Rv "$BASE_DIR"

# Verify Samba configuration
run_cmd testparm -s

# Restart services
run_cmd systemctl restart smb
run_cmd systemctl restart nmb

# ==============================================
# PART 2: USER AND GROUP CREATION WITH GROUP DIRECTORIES
# ==============================================

echo
echo "===== CREATING USERS AND GROUPS ====="

# Function to create group if it doesn't exist
create_group() {
    if ! getent group "$1" >/dev/null; then
        run_cmd groupadd "$1"
        echo "Created group: $1"
    fi
}

# Create groups
create_group "boss_admin_company"
create_group "vice_boss_admin_company"
create_group "manager_company"
create_group "empoyed_company"
create_group "magazinework_company"
create_group "deliverywork_company"

# Create group directories
run_cmd mkdir -p "$BASE_DIR/boss_admin_company"
run_cmd mkdir -p "$BASE_DIR/vice_boss_admin_company"
run_cmd mkdir -p "$BASE_DIR/manager_company"
run_cmd mkdir -p "$BASE_DIR/empoyed_company"
run_cmd mkdir -p "$BASE_DIR/magazinework_company"
run_cmd mkdir -p "$BASE_DIR/deliverywork_company"

# Set permissions for group directories
run_cmd chown nobody:"boss_admin_company" "$BASE_DIR/boss_admin_company"
run_cmd chmod 2770 "$BASE_DIR/boss_admin_company"
run_cmd chown nobody:"vice_boss_admin_company" "$BASE_DIR/vice_boss_admin_company"
run_cmd chmod 2770 "$BASE_DIR/vice_boss_admin_company"
run_cmd chown nobody:"manager_company" "$BASE_DIR/manager_company"
run_cmd chmod 2770 "$BASE_DIR/manager_company"
run_cmd chown nobody:"empoyed_company" "$BASE_DIR/empoyed_company"
run_cmd chmod 2770 "$BASE_DIR/empoyed_company"
run_cmd chown nobody:"magazinework_company" "$BASE_DIR/magazinework_company"
run_cmd chmod 2770 "$BASE_DIR/magazinework_company"
run_cmd chown nobody:"deliverywork_company" "$BASE_DIR/deliverywork_company"
run_cmd chmod 2770 "$BASE_DIR/deliverywork_company"

# Function to create user without personal directory
create_samba_user() {
    local username="$1"
    local group="$2"
    
    # Create system user without home directory
    if ! id "$username" &>/dev/null; then
        run_cmd useradd -M -s /sbin/nologin "$username"
        echo "User $username created successfully"
    fi
    
    # Add user to group
    run_cmd usermod -aG "$group" "$username"
    
    # Set Samba password
    (echo "$PASSWORD"; echo "$PASSWORD") | smbpasswd -a -s "$username"
    run_cmd smbpasswd -e "$username"  # Enable Samba account
    
    echo "Created Samba user: $username (group: $group)"
}

# Create management users (only boss and vice boss get personal directories)
create_samba_user "luca.droi" "boss_admin_company"
run_cmd mkdir -p "$BASE_DIR/boss_admin_company/luca.droi"
run_cmd chown luca.droi:"boss_admin_company" "$BASE_DIR/boss_admin_company/luca.droi"
run_cmd chmod 2770 "$BASE_DIR/boss_admin_company/luca.droi"

create_samba_user "mirko.talbo" "vice_boss_admin_company"
run_cmd mkdir -p "$BASE_DIR/vice_boss_admin_company/mirko.talbo"
run_cmd chown mirko.talbo:"vice_boss_admin_company" "$BASE_DIR/vice_boss_admin_company/mirko.talbo"
run_cmd chmod 2770 "$BASE_DIR/vice_boss_admin_company/mirko.talbo"

# Create other management users (no personal directories)
create_samba_user "fareb.aret" "manager_company"
create_samba_user "luke.skywlaker" "manager_company"
create_samba_user "andrew.cywlaker" "manager_company"

# Create 10 employed_company users (no personal directories)
employed_users=(
    "marco.rossi" "luca.bianchi" "paolo.verdi" "giovanni.neri" "andrea.romano" "matteo.colombo" "stefano.bruno" "francesco.ricci" "alessandro.marino" "davide.gallo" "alberta.ferrari" "enrica.russo" "federica.esposito" "gabriella.barbieri" "massima.fontana" "nicola.caruso" "vittoria.martini" "daniela.santoro" "emanuela.moretti" "giulia.ferri" "simona.palumbo" "cristina.sala" "daria.damico" "fabia.lombardi" "omara.sorrentino" "samuela.mancini" "elia.ferrara" "livia.piras" "renata.pugliesi" "valeria.rizzo" "armando.amato" "gino.valente" "umberto.gentile" "lorenzo.villa" "marino.sanna" "pietro.leone" "romano.gatti" "sergio.montanari" "tiziano.vitale" "alessio.serra" "claudio.marini" "egidio.pellegrini" "fausto.benedetti" "gildo.fabbri" "osvaldo.battaglia" "quirino.santini" "silvano.parisi" "terzo.bellini" "vasco.farina" "zeno.costa"
)
for user in "${employed_users[@]}"; do
    create_samba_user "$user" "empoyed_company"
done

# Create 10 magazinework_company users (no personal directories)
magazine_users=(
    "giorgio.conti" "massimo.esposito" "antonio.costa" "maurizio.martini" "enrico.ferrara" "roberto.riva" "fabio.barbieri" "daniele.moretti" "simone.fontana" "umberto.sala" "adriana.mazza" "battista.deangelis" "cirina.guerra" "doriana.bernardi" "elia.marchetti" "flavia.messina" "gerarda.rossini" "ilaria.basile" "leonarda.fumagalli" "mirka.bianco" "nazzarena.greco" "ottavia.ferretti" "pancrazia.conti" "quintina.pace" "raffaella.orlando" "sabina.angelini" "tullia.castelli" "ulissa.martino" "virginia.moro" "walter.dangelo" "adelma.testa" "benvenuta.longo" "carluccia.franco" "donata.giordano" "ettore.donati" "fiorella.ferraro" "gaetana.ruggiero" "herman.paganelli" "iva.sartori" "lida.volpe" "maura.nucci" "nina.dalessandro" "orfea.silvestri" "prima.barone" "rema.marini" "sesta.rossetti" "tranquilla.mancuso" "ugo.piazza" "vinicia.martinelli" "alda.buono" "bernardina.forte" "carla.marchetti" "dante.rizzi" "elisea.baldini" "fabrizia.savini" "gregoria.camposanto" "hugo.mattei" "lina.benedetto" "maria.ferraro" "nella.santucci"
)
for user in "${magazine_users[@]}"; do
    create_samba_user "$user" "magazinework_company"
done

# Create 10 deliverywork_company users (no personal directories)
delivery_users=(
    "pietro.gatti" "nicola.pellegrini" "giuseppe.lombardi" "salvatore.manfredi" "vincenzo.serra" "carlo.benedetti" "alfonso.marchetti" "oscar.battaglia" "ernesto.amato" "gino.valentini" "olinda.caputo" "pierluigi.poli" "quinta.mancini" "rolanda.ferri" "salvatrice.agostini" "teodora.bellucci" "umberta.vincenzi" "vincenza.pirrone" "artura.marini" "brizia.ferrari" "corrada.novelli" "dina.marconi" "ercola.barbieri" "fulvia.morelli" "giacinta.barbera" "ilia.damiani" "leona.carbone" "maura.rossi" "nerea.paoletti" "oscara.finocchiaro" "pietra.ricciardi" "renza.ferraro" "santa.romani" "tiziana.sanna" "valentina.zuccaro" "ambrogio.bartolini" "ciriaca.sorrentino" "domenica.lombardo" "elvia.palermo" "filippa.carnevale" "gaspare.manfredi" "ignazia.baldini" "ludovica.bonanni" "marcella.ferretti" "natala.ferrara" "ottone.cavalli" "pasquale.ventura" "riccarda.ferraro" "severina.marchese" "timotea.romano" "alfonsa.marini" "bortola.ferraro" "costantina.sanna" "damaso.fabbri" "eliana.marini" "fortunata.ferraro" "geremia.ferrari" "ippolita.ferraro" "loris.ferraro" "maura.ferrari"
)
for user in "${delivery_users[@]}"; do
    create_samba_user "$user" "deliverywork_company"
done

# ==============================================
# PART 3: PERMISSIONS CONFIGURATION
# ==============================================

echo
echo "===== CONFIGURING PERMISSIONS ====="

# Reset base directory permissions
run_cmd chmod 1777 "$BASE_DIR"
run_cmd chown nobody:nobody "$BASE_DIR"

# Set ACLs for group directories
# Boss has full access to everything
run_cmd setfacl -R -m g:boss_admin_company:rwx "$BASE_DIR"
run_cmd setfacl -R -d -m g:boss_admin_company:rwx "$BASE_DIR"

# Vice boss has full access except boss's directory
run_cmd setfacl -R -m g:vice_boss_admin_company:rwx "$BASE_DIR"
run_cmd setfacl -R -d -m g:vice_boss_admin_company:rwx "$BASE_DIR"
run_cmd setfacl -m g:vice_boss_admin_company:--- "$BASE_DIR/boss_admin_company"
run_cmd setfacl -d -m g:vice_boss_admin_company:--- "$BASE_DIR/boss_admin_company"

# Managers can access everything except boss and vice boss directories
run_cmd setfacl -R -m g:manager_company:rwx "$BASE_DIR"
run_cmd setfacl -R -d -m g:manager_company:rwx "$BASE_DIR"
run_cmd setfacl -m g:manager_company:--- "$BASE_DIR/boss_admin_company"
run_cmd setfacl -d -m g:manager_company:--- "$BASE_DIR/boss_admin_company"
run_cmd setfacl -m g:manager_company:--- "$BASE_DIR/vice_boss_admin_company"
run_cmd setfacl -d -m g:manager_company:--- "$BASE_DIR/vice_boss_admin_company"

# Employees can only access their own group directory
run_cmd setfacl -m g:empoyed_company:rwx "$BASE_DIR/empoyed_company"
run_cmd setfacl -d -m g:empoyed_company:rwx "$BASE_DIR/empoyed_company"
run_cmd setfacl -m g:empoyed_company:--- "$BASE_DIR/boss_admin_company"
run_cmd setfacl -d -m g:empoyed_company:--- "$BASE_DIR/boss_admin_company"
run_cmd setfacl -m g:empoyed_company:--- "$BASE_DIR/vice_boss_admin_company"
run_cmd setfacl -d -m g:empoyed_company:--- "$BASE_DIR/vice_boss_admin_company"
run_cmd setfacl -m g:empoyed_company:--- "$BASE_DIR/manager_company"
run_cmd setfacl -d -m g:empoyed_company:--- "$BASE_DIR/manager_company"
run_cmd setfacl -m g:empoyed_company:--- "$BASE_DIR/magazinework_company"
run_cmd setfacl -d -m g:empoyed_company:--- "$BASE_DIR/magazinework_company"
run_cmd setfacl -m g:empoyed_company:--- "$BASE_DIR/deliverywork_company"
run_cmd setfacl -d -m g:empoyed_company:--- "$BASE_DIR/deliverywork_company"

# Magazine workers can only access their own group directory
run_cmd setfacl -m g:magazinework_company:rwx "$BASE_DIR/magazinework_company"
run_cmd setfacl -d -m g:magazinework_company:rwx "$BASE_DIR/magazinework_company"
run_cmd setfacl -m g:magazinework_company:--- "$BASE_DIR/boss_admin_company"
run_cmd setfacl -d -m g:magazinework_company:--- "$BASE_DIR/boss_admin_company"
run_cmd setfacl -m g:magazinework_company:--- "$BASE_DIR/vice_boss_admin_company"
run_cmd setfacl -d -m g:magazinework_company:--- "$BASE_DIR/vice_boss_admin_company"
run_cmd setfacl -m g:magazinework_company:--- "$BASE_DIR/manager_company"
run_cmd setfacl -d -m g:magazinework_company:--- "$BASE_DIR/manager_company"
run_cmd setfacl -m g:magazinework_company:--- "$BASE_DIR/empoyed_company"
run_cmd setfacl -d -m g:magazinework_company:--- "$BASE_DIR/empoyed_company"
run_cmd setfacl -m g:magazinework_company:--- "$BASE_DIR/deliverywork_company"
run_cmd setfacl -d -m g:magazinework_company:--- "$BASE_DIR/deliverywork_company"

# Delivery workers can only access their own group directory
run_cmd setfacl -m g:deliverywork_company:rwx "$BASE_DIR/deliverywork_company"
run_cmd setfacl -d -m g:deliverywork_company:rwx "$BASE_DIR/deliverywork_company"
run_cmd setfacl -m g:deliverywork_company:--- "$BASE_DIR/boss_admin_company"
run_cmd setfacl -d -m g:deliverywork_company:--- "$BASE_DIR/boss_admin_company"
run_cmd setfacl -m g:deliverywork_company:--- "$BASE_DIR/vice_boss_admin_company"
run_cmd setfacl -d -m g:deliverywork_company:--- "$BASE_DIR/vice_boss_admin_company"
run_cmd setfacl -m g:deliverywork_company:--- "$BASE_DIR/manager_company"
run_cmd setfacl -d -m g:deliverywork_company:--- "$BASE_DIR/manager_company"
run_cmd setfacl -m g:deliverywork_company:--- "$BASE_DIR/empoyed_company"
run_cmd setfacl -d -m g:deliverywork_company:--- "$BASE_DIR/empoyed_company"
run_cmd setfacl -m g:deliverywork_company:--- "$BASE_DIR/magazinework_company"
run_cmd setfacl -d -m g:deliverywork_company:--- "$BASE_DIR/magazinework_company"

# Final service restart
run_cmd systemctl restart smb
run_cmd systemctl restart nmb

# Completion message
echo
echo "===== SETUP COMPLETED SUCCESSFULLY ====="
echo "Samba Server and user configuration finished"
echo "Log file: $LOG_FILE"
echo "Share path: $BASE_DIR"
echo "Access the share using: \\\\$(hostname -s)\\$SAMBA_SHARE_NAME"
echo
echo "User credentials:"
echo "Username format: nome.cognome"
echo "Password: $PASSWORD"
echo
echo "NOTE: For security reasons, consider changing passwords for sensitive accounts"

exit 0
