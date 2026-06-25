#!/bin/bash
# install.sh — FreePBX Factory V1.9 CRA — Installateur on-VPS
#
# S'exécute DIRECTEMENT sur le VPS cible (Debian 12 neuf).
# Pas de machine de déploiement intermédiaire, pas de connexion SSH sortante.
#
# PRÉREQUIS :
#   - Debian 12 (Bookworm), neuf, connexion internet
#   - Accès root (sudo ou su)
#   - python3 disponible (présent par défaut sur Debian 12)
#
# UTILISATION :
#   sudo bash /tmp/freepbx-factory/install.sh
#
# ARCHITECTURE :
#   Le script démarre dans tmux si tmux n'est pas actif — la session
#   persiste même si la connexion SSH est coupée lors du durcissement SSH.
#   Reconnexion après hardening : ssh -p <PORT> debian@<IP> puis tmux attach
#
# PHASES :
#   00_cleanup → 00_hardening → 01_install → 02_asterisk →
#   03_firewall → 04_fail2ban → 06_post_restore →
#   09_apache_hardening → 10_mariadb_hardening → 11_services_hardening →
#   14_auditd → 12_sbom → 13_post_checks
#   (05_restore supprimé — V1.9 CRA — template non nécessaire)
#
# Fix E19 intégré : 00_hardening tourne comme processus local (pas via pipe SSH).
#   sshd restart coupe la connexion SSH cliente mais pas ce script (dans tmux).
# Fix E21 intégré : sed pattern unique dans 00_hardening.sh.

set -euo pipefail

# ── Arguments optionnels (passés par launch.py/launch.sh) ───────────────────
# --management-ip=X.X.X.0/24 : IP du poste déployeur (détectée par le lanceur)
# --kit-starter=oui|non       : pré-sélection wizard (ignore la question interactive)
MANAGEMENT_IP_ARG=""
KIT_STARTER_ARG=""   # vide = demander interactivement
for _arg in "$@"; do
    case "$_arg" in
        --management-ip=*)   MANAGEMENT_IP_ARG="${_arg#*=}";;
        --kit-starter=*)     KIT_STARTER_ARG="${_arg#*=}";;
        --trunk-enabled=*)   TRUNK_ENABLED_ARG="${_arg#*=}";;
        --trunk-registrar=*) TRUNK_REGISTRAR_ARG="${_arg#*=}";;
        --trunk-username=*)  TRUNK_USERNAME_ARG="${_arg#*=}";;
        --tls-domain=*)      TLS_DOMAIN_ARG="${_arg#*=}";;
    esac
done
TRUNK_ENABLED_ARG="${TRUNK_ENABLED_ARG:-}"
TRUNK_REGISTRAR_ARG="${TRUNK_REGISTRAR_ARG:-}"
TRUNK_USERNAME_ARG="${TRUNK_USERNAME_ARG:-}"
TLS_DOMAIN_ARG="${TLS_DOMAIN_ARG:-}"

# ── Validation des options CLI ───────────────────────────────────────────────
# kit-starter : valeur attendue parmi oui/non/yes/no/1/0
if [[ -n "$KIT_STARTER_ARG" ]]; then
    case "${KIT_STARTER_ARG,,}" in
        oui|non|yes|no|1|0) ;;
        *) echo -e "\033[0;31m[ERR]\033[0m --kit-starter='$KIT_STARTER_ARG' invalide. Valeurs acceptées : oui, non." >&2; exit 1;;
    esac
fi

# trunk-enabled=oui : registrar et username obligatoires
if [[ "${TRUNK_ENABLED_ARG,,}" =~ ^(oui|yes|1)$ ]]; then
    [[ -z "$TRUNK_REGISTRAR_ARG" ]] && { echo -e "\033[0;31m[ERR]\033[0m --trunk-enabled=oui requiert --trunk-registrar=<serveur-sip>" >&2; exit 1; }
    [[ -z "$TRUNK_USERNAME_ARG"  ]] && { echo -e "\033[0;31m[ERR]\033[0m --trunk-enabled=oui requiert --trunk-username=<login-sip>" >&2; exit 1; }
fi

# tls-domain : format FQDN minimal (lettres, chiffres, tirets, points ; au moins un point)
if [[ -n "$TLS_DOMAIN_ARG" ]]; then
    if ! [[ "$TLS_DOMAIN_ARG" =~ ^[a-zA-Z0-9]([a-zA-Z0-9\-]{0,61}[a-zA-Z0-9])?(\.[a-zA-Z0-9]([a-zA-Z0-9\-]{0,61}[a-zA-Z0-9])?)+$ ]]; then
        echo -e "\033[0;31m[ERR]\033[0m --tls-domain='$TLS_DOMAIN_ARG' invalide. Exemple attendu : pbx.mon-entreprise.fr" >&2
        exit 1
    fi
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# @@BUNDLE_INJECT_START@@
_PHASES_TMP="$(mktemp -d /tmp/fpbx-phases-XXXXXX)"
trap 'rm -rf "$_PHASES_TMP" 2>/dev/null' EXIT
trap 'stty sane 2>/dev/null; echo ""; echo "  Installation interrompue."; exit 130' INT TERM HUP

cat > "$_PHASES_TMP/00_cleanup.sh" <<'__FPBXPHASE_00_CLEANUP_SH__'
#!/bin/bash
# 00_cleanup.sh — Purge Node.js/npm et dépôts NodeSource (E1)
# Exécuté localement sur le VPS
set -euo pipefail
LOG=/var/log/freepbx-factory/deploy-phase-00-cleanup.log
touch "$LOG" && chmod 600 "$LOG"
exec > >(tee -a "$LOG") 2>&1

echo "[$(date '+%Y-%m-%d %H:%M:%S')] === PHASE 00_CLEANUP ==="

apt-get remove --purge nodejs npm -y 2>&1 | tail -3 || true
rm -rf /usr/lib/node_modules /etc/apt/sources.list.d/nodesource.list 2>/dev/null || true
apt-get autoremove -y 2>&1 | tail -2

echo "[$(date '+%Y-%m-%d %H:%M:%S')] CLEANUP_OK"
__FPBXPHASE_00_CLEANUP_SH__
chmod +x "$_PHASES_TMP/00_cleanup.sh"

cat > "$_PHASES_TMP/00_hardening.sh" <<'__FPBXPHASE_00_HARDENING_SH__'
#!/bin/bash
# 00_hardening.sh — UFW bootstrap + SSH hardening + sysctl
#
# FIX E19 : ce script s'exécute localement sur le VPS (uploadé via scp).
#   systemctl restart sshd ne coupe PAS ce script car il tourne en processus
#   local, pas dans un pipe SSH. La connexion SSH distante sera coupée lors du
#   restart sshd — c'est attendu et géré par le lanceur (reconnexion sur 2222).
#
# FIX E21 : le sed utilise le pattern ^#\?Port[[:space:]] qui remplace la ligne
#   entière, quel que soit le contenu initial (#Port 22, Port 22, Port 2222).
#   Il ne peut pas produire Port 222222.
#
# Usage : sudo bash /tmp/00_hardening.sh <management_ip> [ssh_port]
#   Ex :  sudo bash /tmp/00_hardening.sh A.B.C.0/24 2222

set -euo pipefail
LOG=/var/log/freepbx-factory/deploy-phase-00-hardening.log
touch "$LOG" && chmod 600 "$LOG"
exec > >(tee -a "$LOG") 2>&1

MANAGEMENT_IP="${1:?Argument 1 requis : management_ip (ex: A.B.C.0/24)}"
SSH_PORT="${2:-2222}"

echo "[$(date '+%Y-%m-%d %H:%M:%S')] === PHASE 00_HARDENING ==="
echo "  management_ip : $MANAGEMENT_IP"
echo "  ssh_port      : $SSH_PORT"

# --- UFW bootstrap (AVANT toute modification sshd) ---
echo "[$(date '+%Y-%m-%d %H:%M:%S')] UFW : installation..."
apt-get install -y ufw 2>&1 | tail -2

ufw --force reset 2>&1 | tail -1
ufw default deny incoming
ufw default allow outgoing

# Ouvrir le port courant (22) ET le port cible pour la transition
ufw allow from "$MANAGEMENT_IP" to any port 22 proto tcp
ufw allow from "$MANAGEMENT_IP" to any port "$SSH_PORT" proto tcp
ufw --force enable

echo "[$(date '+%Y-%m-%d %H:%M:%S')] UFW_BOOTSTRAP_OK"
ufw status

# --- sysctl hardening ---
echo "[$(date '+%Y-%m-%d %H:%M:%S')] sysctl : application..."
cat > /etc/sysctl.d/99-freepbx-factory.conf << 'EOF'
net.ipv4.tcp_syncookies = 1
net.ipv4.conf.all.rp_filter = 1
net.ipv4.conf.default.rp_filter = 1
net.ipv4.icmp_echo_ignore_broadcasts = 1
net.ipv4.icmp_ignore_bogus_error_responses = 1
net.ipv4.conf.all.accept_redirects = 0
net.ipv4.conf.default.accept_redirects = 0
net.ipv6.conf.all.accept_redirects = 0
net.ipv6.conf.default.accept_redirects = 0
net.ipv4.conf.all.send_redirects = 0
net.ipv4.conf.default.send_redirects = 0
net.ipv4.conf.all.accept_source_route = 0
net.ipv6.conf.all.accept_source_route = 0
EOF
sysctl -p /etc/sysctl.d/99-freepbx-factory.conf
echo "[$(date '+%Y-%m-%d %H:%M:%S')] SYSCTL_OK"

# --- unattended-upgrades ---
apt-get install -y unattended-upgrades apt-listchanges 2>&1 | tail -2
cat > /etc/apt/apt.conf.d/50unattended-upgrades << 'EOF'
Unattended-Upgrade::Allowed-Origins {
  "${distro_id}:${distro_codename}-security";
};
Unattended-Upgrade::AutoFixInterruptedDpkg "true";
Unattended-Upgrade::MinimalSteps "true";
Unattended-Upgrade::Remove-Unused-Dependencies "true";
Unattended-Upgrade::Automatic-Reboot "false";
EOF
cat > /etc/apt/apt.conf.d/20auto-upgrades << 'EOF'
APT::Periodic::Update-Package-Lists "1";
APT::Periodic::Unattended-Upgrade "1";
APT::Periodic::Download-Upgradeable-Packages "1";
APT::Periodic::AutocleanInterval "7";
EOF
echo "[$(date '+%Y-%m-%d %H:%M:%S')] UNATTENDED_UPGRADES_OK"

# --- SSH hardening ---
echo "[$(date '+%Y-%m-%d %H:%M:%S')] SSH : configuration..."
cp /etc/ssh/sshd_config /etc/ssh/sshd_config.bak

# FIX E21 : pattern unique, remplace la ligne entière — aucun risque de doublement
# Gère : "#Port 22", "Port 22", "Port 2222", ligne absente
sed -i "s/^#\?Port[[:space:]].*/Port ${SSH_PORT}/" /etc/ssh/sshd_config
grep -q "^Port " /etc/ssh/sshd_config || echo "Port ${SSH_PORT}" >> /etc/ssh/sshd_config

sed -i 's/^#\?PermitRootLogin.*/PermitRootLogin no/' /etc/ssh/sshd_config
grep -q "^PermitRootLogin" /etc/ssh/sshd_config || echo "PermitRootLogin no" >> /etc/ssh/sshd_config

sed -i 's/^#\?MaxAuthTries.*/MaxAuthTries 3/' /etc/ssh/sshd_config
grep -q "^MaxAuthTries" /etc/ssh/sshd_config || echo "MaxAuthTries 3" >> /etc/ssh/sshd_config

sed -i 's/^#\?MaxSessions.*/MaxSessions 4/' /etc/ssh/sshd_config
grep -q "^MaxSessions" /etc/ssh/sshd_config || echo "MaxSessions 4" >> /etc/ssh/sshd_config

sed -i 's/^#\?ClientAliveInterval.*/ClientAliveInterval 300/' /etc/ssh/sshd_config
grep -q "^ClientAliveInterval" /etc/ssh/sshd_config || echo "ClientAliveInterval 300" >> /etc/ssh/sshd_config

sed -i 's/^#\?ClientAliveCountMax.*/ClientAliveCountMax 2/' /etc/ssh/sshd_config
grep -q "^ClientAliveCountMax" /etc/ssh/sshd_config || echo "ClientAliveCountMax 2" >> /etc/ssh/sshd_config

sed -i 's/^#\?X11Forwarding.*/X11Forwarding no/' /etc/ssh/sshd_config
grep -q "^X11Forwarding" /etc/ssh/sshd_config || echo "X11Forwarding no" >> /etc/ssh/sshd_config

sed -i 's/^#\?AllowTcpForwarding.*/AllowTcpForwarding no/' /etc/ssh/sshd_config
grep -q "^AllowTcpForwarding" /etc/ssh/sshd_config || echo "AllowTcpForwarding no" >> /etc/ssh/sshd_config

sed -i 's/^#\?PasswordAuthentication.*/PasswordAuthentication no/' /etc/ssh/sshd_config
grep -q "^PasswordAuthentication" /etc/ssh/sshd_config || echo "PasswordAuthentication no" >> /etc/ssh/sshd_config

grep -q "^AllowUsers" /etc/ssh/sshd_config \
  && sed -i 's/^AllowUsers.*/AllowUsers debian/' /etc/ssh/sshd_config \
  || echo "AllowUsers debian" >> /etc/ssh/sshd_config

echo "[$(date '+%Y-%m-%d %H:%M:%S')] SSH_CONFIG_WRITTEN"
echo "  Contenu Port/Auth :"
grep -E "^Port|^PermitRootLogin|^MaxAuthTries|^PasswordAuthentication|^AllowUsers" /etc/ssh/sshd_config

# Validation AVANT restart (abort si config invalide)
echo "[$(date '+%Y-%m-%d %H:%M:%S')] sshd -t : validation..."
if ! sshd -t; then
    echo "[ERREUR] Config sshd invalide — restauration backup"
    cp /etc/ssh/sshd_config.bak /etc/ssh/sshd_config
    exit 1
fi
echo "[$(date '+%Y-%m-%d %H:%M:%S')] SSH_CONFIG_VALID"

# Restart sshd — la connexion SSH distante sera coupée ici (attendu)
# Ce script continue car il tourne localement, pas dans le pipe SSH
systemctl restart sshd
echo "[$(date '+%Y-%m-%d %H:%M:%S')] SSHD_RESTARTED_PORT_${SSH_PORT}"

# Supprimer la règle UFW temporaire port 22
ufw delete allow from "$MANAGEMENT_IP" to any port 22 proto tcp 2>/dev/null || true
echo "[$(date '+%Y-%m-%d %H:%M:%S')] UFW_PORT22_REMOVED"

echo "[$(date '+%Y-%m-%d %H:%M:%S')] === HARDENING_COMPLETE ==="
echo "  SSH actif sur port $SSH_PORT"
echo "  UFW : seul $SSH_PORT autorisé depuis $MANAGEMENT_IP"
__FPBXPHASE_00_HARDENING_SH__
chmod +x "$_PHASES_TMP/00_hardening.sh"

cat > "$_PHASES_TMP/01_install.sh" <<'__FPBXPHASE_01_INSTALL_SH__'
#!/bin/bash
# 01_install.sh — apt dist-upgrade (kernel inclus) + installation FreePBX 17
#
# Doit être lancé dans un tmux (ou screen) car dure 20-40 min et survit
# à la perte de connexion SSH.
#
# Usage : sudo bash /tmp/01_install.sh

set -euo pipefail
LOG=/var/log/freepbx-factory/deploy-phase-01-install.log
touch "$LOG" && chmod 600 "$LOG"
exec > >(tee -a "$LOG") 2>&1

echo "[$(date '+%Y-%m-%d %H:%M:%S')] === PHASE 01_INSTALL ==="

# apt upgrade — conserver la config OVHcloud sshd_config (E9)
echo "[$(date '+%Y-%m-%d %H:%M:%S')] apt update + dist-upgrade (correctifs noyau inclus)..."
DEBIAN_FRONTEND=noninteractive apt-get update -y
DEBIAN_FRONTEND=noninteractive apt-get dist-upgrade -y \
  -o Dpkg::Options::="--force-confold" \
  -o Dpkg::Options::="--force-confdef"
echo "[$(date '+%Y-%m-%d %H:%M:%S')] APT_UPGRADE_OK"

# Téléchargement script FreePBX
echo "[$(date '+%Y-%m-%d %H:%M:%S')] Téléchargement installateur FreePBX..."
wget -q -O /tmp/sng_freepbx_debian_install.sh \
  https://github.com/FreePBX/sng_freepbx_debian_install/raw/master/sng_freepbx_debian_install.sh

chmod +x /tmp/sng_freepbx_debian_install.sh
echo "[$(date '+%Y-%m-%d %H:%M:%S')] INSTALL_SCRIPT_DOWNLOADED"

# Installation FreePBX (20-40 min)
# --nointeractive : pas de questions
# Note E15 : l'installateur supprime UFW — sera réinstallé par 03_firewall.sh
echo "[$(date '+%Y-%m-%d %H:%M:%S')] Lancement installation FreePBX (20-40 min)..."
DEBIAN_FRONTEND=noninteractive bash /tmp/sng_freepbx_debian_install.sh 2>&1
echo "[$(date '+%Y-%m-%d %H:%M:%S')] FREEPBX_INSTALL_DONE"

# Vérification post-install
echo "[$(date '+%Y-%m-%d %H:%M:%S')] Vérification post-install..."
fwconsole pm2 --list || true
echo "[$(date '+%Y-%m-%d %H:%M:%S')] === INSTALL_COMPLETE ==="
__FPBXPHASE_01_INSTALL_SH__
chmod +x "$_PHASES_TMP/01_install.sh"

cat > "$_PHASES_TMP/02_asterisk.sh" <<'__FPBXPHASE_02_ASTERISK_SH__'
#!/bin/bash
# 02_asterisk.sh — Activation Asterisk + désactivation modules legacy
#
# E2  : Asterisk SysV sur Debian 12 — is-active non fiable → validation PM2
# E11 : chan_ooh323.so charge le port 1720 H.323 legacy
# Surface d'attaque réduite : chan_iax2, chan_mgcp, chan_skinny, res_stun_monitor
#
# Usage : sudo bash /tmp/02_asterisk.sh

set -euo pipefail
LOG=/var/log/freepbx-factory/deploy-phase-02-asterisk.log
touch "$LOG" && chmod 600 "$LOG"
exec > >(tee -a "$LOG") 2>&1

echo "[$(date '+%Y-%m-%d %H:%M:%S')] === PHASE 02_ASTERISK ==="

# Activer et démarrer Asterisk
systemctl enable asterisk 2>/dev/null || true
systemctl start asterisk 2>/dev/null || true

# E2 : is-active non fiable en mode SysV — attente PM2
echo "[$(date '+%Y-%m-%d %H:%M:%S')] Attente démarrage Asterisk via PM2..."
RETRY=0
until fwconsole pm2 --list 2>/dev/null | grep -q 'online'; do
    RETRY=$((RETRY+1))
    if [[ $RETRY -ge 60 ]]; then
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] AVERTISSEMENT : PM2 online non atteint après 300s — Asterisk lent à démarrer"
        fwconsole pm2 --list 2>/dev/null || true
        echo "  → Vérifier après déploiement : sudo fwconsole pm2 --list"
        break
    fi
    if (( RETRY % 6 == 0 )); then
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] Attente Asterisk... $((RETRY * 5))s / 300s max"
    fi
    sleep 5
done
echo "[$(date '+%Y-%m-%d %H:%M:%S')] PM2_OK — services online"
fwconsole pm2 --list 2>/dev/null | grep -E 'online|offline|stopped' || true

# Désactivation modules legacy (réduction surface d'attaque)
echo "[$(date '+%Y-%m-%d %H:%M:%S')] Désactivation modules legacy..."
for module in chan_ooh323.so chan_mgcp.so chan_skinny.so chan_iax2.so res_stun_monitor.so; do
    asterisk -rx "module unload $module" 2>/dev/null \
        && echo "  [OK] $module déchargé" \
        || echo "  [--] $module non chargé (déjà absent)"
done

# Persister dans modules.conf
echo "[$(date '+%Y-%m-%d %H:%M:%S')] Persistance noload dans modules.conf..."
MODULES_CONF=/etc/asterisk/modules.conf
for module in chan_ooh323.so chan_mgcp.so chan_skinny.so chan_iax2.so res_stun_monitor.so; do
    grep -q "noload => $module" "$MODULES_CONF" 2>/dev/null \
        || echo "noload => $module" >> "$MODULES_CONF"
done

# Validation : port 1720 fermé
PORT_1720=$(ss -tlnp 2>/dev/null | grep ':1720' || echo "")
if [[ -n "$PORT_1720" ]]; then
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] ATTENTION port 1720 encore ouvert : $PORT_1720"
else
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] PORT_1720_OK — H.323 désactivé"
fi

# Validation : AMI 5038 uniquement sur 127.0.0.1
AMI_PUBLIC=$(ss -tlnp 2>/dev/null | grep ':5038' | grep -v '127.0.0.1' || echo "")
if [[ -n "$AMI_PUBLIC" ]]; then
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] ATTENTION AMI exposé publiquement : $AMI_PUBLIC"
else
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] AMI_OK — port 5038 localhost uniquement"
fi

echo "[$(date '+%Y-%m-%d %H:%M:%S')] === ASTERISK_PHASE_COMPLETE ==="
__FPBXPHASE_02_ASTERISK_SH__
chmod +x "$_PHASES_TMP/02_asterisk.sh"

cat > "$_PHASES_TMP/03_firewall.sh" <<'__FPBXPHASE_03_FIREWALL_SH__'
#!/bin/bash
# 03_firewall.sh — Réinstaller UFW + règles applicatives complètes
#
# E15 : l'installateur FreePBX supprime UFW. Ce script le réinstalle
# et applique toutes les règles (management SSH + applicatif FreePBX).
#
# Usage : sudo bash /tmp/03_firewall.sh <management_ip> [ssh_port]

set -euo pipefail
LOG=/var/log/freepbx-factory/deploy-phase-03-firewall.log
touch "$LOG" && chmod 600 "$LOG"
exec > >(tee -a "$LOG") 2>&1

MANAGEMENT_IP="${1:?Argument 1 requis : management_ip}"
SSH_PORT="${2:-2222}"

echo "[$(date '+%Y-%m-%d %H:%M:%S')] === PHASE 03_FIREWALL ==="

# Désactiver le firewall FreePBX (incompatible avec UFW)
fwconsole firewall --disable 2>/dev/null || true
echo "[$(date '+%Y-%m-%d %H:%M:%S')] FREEPBX_FW_DISABLED"

# Réinstaller UFW (supprimé par l'installateur — E15)
apt-get install -y ufw 2>&1 | tail -2

ufw --force reset 2>&1 | tail -1
ufw default deny incoming
ufw default allow outgoing

# SSH management uniquement
ufw allow from "$MANAGEMENT_IP" to any port "$SSH_PORT" proto tcp comment 'SSH management'

# Applicatif FreePBX
ufw allow 80/tcp comment 'FreePBX GUI HTTP'
ufw allow 443/tcp comment 'FreePBX GUI HTTPS'
ufw allow 5060/udp comment 'SIP'
ufw allow 5060/tcp comment 'SIP TCP'
ufw allow 5061/tcp comment 'SIP TLS'
ufw allow 10000:20000/udp comment 'RTP audio'

ufw --force enable
echo "[$(date '+%Y-%m-%d %H:%M:%S')] UFW_OK"
ufw status numbered

echo "[$(date '+%Y-%m-%d %H:%M:%S')] === FIREWALL_COMPLETE ==="
__FPBXPHASE_03_FIREWALL_SH__
chmod +x "$_PHASES_TMP/03_firewall.sh"

cat > "$_PHASES_TMP/04_fail2ban.sh" <<'__FPBXPHASE_04_FAIL2BAN_SH__'
#!/bin/bash
# 04_fail2ban.sh — Installation + configuration fail2ban
#
# E23 : action explicite par jail (fail2ban 1.x sans action = aucune règle iptables)
# E24 : systemctl restart (pas reload) pour créer les chaînes iptables
# M2  : findtime 3600 (pas 600)
# 7 jails : ssh-iptables, asterisk-iptables, pbx-gui, apache-tcpwrapper,
#           apache-badbots, apache-noscript, recidive
#
# Usage : sudo bash 04_fail2ban.sh <management_ip> <ssh_port> [extra_ignoreip]

set -euo pipefail
LOG=/var/log/freepbx-factory/deploy-phase-04-fail2ban.log
touch "$LOG" && chmod 600 "$LOG"
exec > >(tee -a "$LOG") 2>&1

MANAGEMENT_IP="${1:?Argument 1 requis : management_ip}"
SSH_PORT="${2:?Argument 2 requis : ssh_port}"
EXTRA_IGNOREIP="${3:-}"

echo "[$(date '+%Y-%m-%d %H:%M:%S')] === PHASE 04_FAIL2BAN (port SSH : $SSH_PORT) ==="
[[ -n "$EXTRA_IGNOREIP" ]] && echo "  extra_ignoreip : $EXTRA_IGNOREIP"

apt-get install -y fail2ban 2>&1 | tail -2

# Filtre pbx-gui — absent par défaut dans fail2ban, requis pour jail pbx-gui
# Bug E23 : filter = freepbx (ancien nom) → jail silencieusement ignoré
mkdir -p /etc/fail2ban/filter.d
cat > /etc/fail2ban/filter.d/pbx-gui.conf << 'EOF'
[INCLUDES]
before = common.conf

[Definition]
_daemon = freepbx_security
failregex = \[freepbx_security\.\w+\]:\s+Authentication failure for .+ from <HOST>
ignoreregex =
EOF

# jail.local baseline — jails built-in sans action désactivés (E23)
cat > /etc/fail2ban/jail.local << 'JAILEOF'
[DEFAULT]
bantime  = 86400
findtime = 3600
maxretry = 3
backend  = systemd

[apache-badbots]
enabled  = true
action   = iptables-allports[name=apache-badbots]

[apache-noscript]
enabled  = true
action   = iptables-allports[name=apache-noscript]

[recidive]
enabled  = true
bantime  = 604800
findtime = 86400
maxretry = 3
action   = iptables-allports[name=recidive]
JAILEOF

# Overlay hardening — 7 jails avec actions explicites (E23)
# Chargé après jail.local, survit aux regénérations FreePBX
mkdir -p /etc/fail2ban/jail.d

IGNOREIP_LINE="127.0.0.1/8 ::1 ${MANAGEMENT_IP}"
[[ -n "$EXTRA_IGNOREIP" ]] && IGNOREIP_LINE="${IGNOREIP_LINE} ${EXTRA_IGNOREIP}"

cat > /etc/fail2ban/jail.d/freepbx-factory-hardening.local << OVERLAYEOF
[DEFAULT]
ignoreip = ${IGNOREIP_LINE}
bantime  = 86400
findtime = 3600
maxretry = 3

# Désactivation jails built-in (doublons sans action — E23)
[sshd]
enabled = false

[asterisk]
enabled = false

[apache-auth]
enabled = false

[ssh-iptables]
enabled  = true
filter   = sshd
port     = ${SSH_PORT}
logpath  = /var/log/auth.log
maxretry = 3
bantime  = 86400
action   = iptables-allports[name=ssh-iptables]

[asterisk-iptables]
enabled  = true
filter   = asterisk
logpath  = /var/log/asterisk/fail2ban
maxretry = 5
bantime  = 86400
action   = iptables-allports[name=asterisk-iptables]

[pbx-gui]
enabled  = true
filter   = pbx-gui
logpath  = /var/log/asterisk/freepbx_security.log
maxretry = 3
bantime  = 86400
action   = iptables-allports[name=pbx-gui]

[apache-tcpwrapper]
enabled  = true
filter   = apache-common
logpath  = /var/log/apache2/error.log
maxretry = 3
bantime  = 86400
action   = iptables-allports[name=apache-tcpwrapper]

[apache-badbots]
enabled  = true
filter   = apache-badbots
logpath  = /var/log/apache2/access.log
maxretry = 1
bantime  = 86400
action   = iptables-allports[name=apache-badbots]

[apache-noscript]
enabled  = true
filter   = apache-noscript
logpath  = /var/log/apache2/error.log
maxretry = 3
bantime  = 86400
action   = iptables-allports[name=apache-noscript]

[recidive]
enabled  = true
bantime  = 604800
findtime = 86400
maxretry = 3
action   = iptables-allports[name=recidive]
OVERLAYEOF

systemctl enable fail2ban
# restart requis (pas reload) pour créer les chaînes iptables — E24
echo "[$(date '+%Y-%m-%d %H:%M:%S')] Démarrage fail2ban et création des chaînes iptables..."
systemctl restart fail2ban
sleep 5

# Validation actions iptables (E23)
ACTIONS=$(fail2ban-client get ssh-iptables actions 2>/dev/null || echo "")
if echo "$ACTIONS" | grep -q "No actions"; then
    echo "[AVERTISSEMENT E23] fail2ban ssh-iptables : aucune action iptables — vérifier l'overlay"
    echo "  → sudo fail2ban-client get ssh-iptables actions"
fi

fail2ban-client status
echo "[$(date '+%Y-%m-%d %H:%M:%S')] === FAIL2BAN_COMPLETE (7 jails) ==="
__FPBXPHASE_04_FAIL2BAN_SH__
chmod +x "$_PHASES_TMP/04_fail2ban.sh"

cat > "$_PHASES_TMP/06_post_restore.sh" <<'__FPBXPHASE_06_POST_RESTORE_SH__'
#!/bin/bash
# 06_post_restore.sh — Fix endpoint + admin + extensions + trunk post-restore
#
# E3  : fix endpoint systématique post-restore
# E6  : admin recréé par DELETE+INSERT (état déterministe)
# E10 : colonnes ampusers correctes (extension_low/high, pas tel)
# E16 : table userman_users (pas usermanager_users)
# E18 : hash SHA1 pour ampusers ET userman_users (checkCredentials accepte SHA1)
# E22 : trunk PJSIP FreePBX 17 (SQL tables trunks+pjsip)
# EXT : extensions INSERT depuis zéro (template V3 = 0 extension)
#       50 keywords PJSIP dans sip — identique à 06b_extensions.yml Ansible
#       mots de passe fournis par le wizard (args) ou auto-générés
#
# Usage : sudo bash /tmp/06_post_restore.sh \
#           <admin_username> <admin_sha1> <admin_sha512> \
#           [trunk_registrar] [trunk_username] [trunk_password] \
#           [trunk_name] [trunk_callerid] \
#           [ext1_number (auto-généré par deploy.sh)] [ext1_name] [ext1_pass] \
#           [ext2_number (auto-généré par deploy.sh)] [ext2_name] [ext2_pass] \
#           [ext3_number (auto-généré par deploy.sh)] [ext3_name] [ext3_pass]

set -euo pipefail
LOG=/var/log/freepbx-factory/deploy-phase-06-post-restore.log
touch "$LOG" && chmod 600 "$LOG"
exec > >(tee -a "$LOG") 2>&1

ADMIN_USERNAME="${1:?Argument 1 requis : admin_username}"
ADMIN_SHA1="${2:?Argument 2 requis : admin_password_sha1}"
ADMIN_SHA512="${3:?Argument 3 requis : admin_password_sha512}"
TRUNK_REGISTRAR="${4:-}"
TRUNK_USERNAME="${5:-}"
TRUNK_PASSWORD="${6:-}"
TRUNK_NAME="${7:-trunk-ovh}"
TRUNK_CALLERID="${8:-$TRUNK_USERNAME}"
EXT1_NUMBER="${9:-}"
EXT1_NAME="${10:-Poste 1}"
EXT1_PASS="${11:-}"
EXT2_NUMBER="${12:-}"
EXT2_NAME="${13:-Poste 2}"
EXT2_PASS="${14:-}"
EXT3_NUMBER="${15:-}"
EXT3_NAME="${16:-Poste 3}"
EXT3_PASS="${17:-}"

gen_pass() {
    head -c 512 /dev/urandom | tr -dc 'A-Za-z0-9!@#^*_-' | cut -c1-20
}

echo "[$(date '+%Y-%m-%d %H:%M:%S')] === PHASE 06_POST_RESTORE ==="

# ── Fix endpoint (E3) ────────────────────────────────────
echo "[$(date '+%Y-%m-%d %H:%M:%S')] Fix endpoint..."
fwconsole ma install endpoint -f 2>&1 | tail -3
fwconsole reload 2>&1 | tail -3 || true
echo "[$(date '+%Y-%m-%d %H:%M:%S')] ENDPOINT_OK"

# ── UFW garde post-reload (E15) ──────────────────────────
ufw --force enable 2>&1 | grep -E 'active|enabled|Firewall'

# ── Admin GUI — DELETE + INSERT (E6, E10, E16, E18) ──────
echo "[$(date '+%Y-%m-%d %H:%M:%S')] Recréation compte admin..."
mysql -u root asterisk << SQLEOF
DELETE FROM ampusers WHERE username='${ADMIN_USERNAME}';
INSERT INTO ampusers (username, password_sha1, sections, deptname, extension_low, extension_high)
  VALUES ('${ADMIN_USERNAME}', '${ADMIN_SHA1}', '*', '', '', '');
DELETE FROM userman_users WHERE username='${ADMIN_USERNAME}';
-- auth = ID de la PBX Internal Directory (userman_directories default active)
-- DOIT être un entier (comparé a d.id dans getUserByUsername) : 'freepbx' (string) -> 0 != 1 -> echec login (E25)
SET @dir_id = (SELECT id FROM userman_directories WHERE \`default\`=1 AND active=1 ORDER BY \`order\` LIMIT 1);
SET @dir_id = IFNULL(@dir_id, 1);
-- userman_users : password = SHA1 (40 chars) — checkCredentials Freepbx.php accepte SHA1 + auto-upgrade bcrypt
-- userman_users.auth = integer dir_id (E25 : 'freepbx' string -> 0 != 1 -> getUserByUsername fail -> login refuse)
INSERT INTO userman_users (username, password, auth, description, primary_group, default_extension, email)
  VALUES ('${ADMIN_USERNAME}', '${ADMIN_SHA1}', @dir_id, 'Admin FreePBX Factory', 1, 'none', '');

-- Groupe Administrators (id=1) requis pour AUTHTYPE=usermanager (E25)
-- users = JSON array des uid membres ; pbx_login = acces admin ; pbx_admin + pbx_modules = menu complet
INSERT INTO userman_groups (id, auth, groupname, description, priority, local, users)
  VALUES (1, 'freepbx', 'Administrators', 'Default Administrators Group', 0, 0, '[1]')
  ON DUPLICATE KEY UPDATE users='[1]', groupname='Administrators';
REPLACE INTO userman_groups_settings (gid, module, \`key\`, val, type)
  VALUES (1, 'global', 'pbx_login', 1, NULL);
REPLACE INTO userman_groups_settings (gid, module, \`key\`, val, type)
  VALUES (1, 'global', 'pbx_admin', 1, NULL);
REPLACE INTO userman_groups_settings (gid, module, \`key\`, val, type)
  VALUES (1, 'global', 'pbx_modules', '["*"]', 'json-arr');
SQLEOF
echo "[$(date '+%Y-%m-%d %H:%M:%S')] ADMIN_OK : $ADMIN_USERNAME"

# ── Extensions kit starter — INSERT depuis zéro (template V3) ──
# La table sip est la source de vérité pour la config PJSIP des extensions.
# NE PAS insérer dans pjsip : FreePBX régénère depuis sip+devices+users.
insert_extension() {
    local num="$1" name="$2" pass="$3"
    [[ -z "$num" ]] && return
    [[ -z "$pass" ]] && pass=$(gen_pass)
    local safe_name="${name//\'/\'\'}"
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] Extension $num ($name)..."
    mysql -u root asterisk << EXTEOF
DELETE FROM devices WHERE id='${num}';
DELETE FROM users   WHERE extension='${num}';
DELETE FROM sip     WHERE id='${num}';
INSERT INTO devices (id, tech, dial, devicetype, user, description, emergency_cid, hint_override)
  VALUES ('${num}', 'pjsip', 'PJSIP/${num}', 'fixed', '${num}', '${safe_name}', '', NULL);
INSERT INTO users (extension, password, name, voicemail, ringtimer, noanswer, recording,
  outboundcid, sipname, noanswer_cid, busy_cid, chanunavail_cid,
  noanswer_dest, busy_dest, chanunavail_dest, mohclass)
  VALUES ('${num}', '', '${safe_name}', 'novm', 0, '', '', '', '', '', '', '', '', '', '', 'default');
INSERT INTO sip (id, keyword, data, flags) VALUES
  ('${num}','account',              '${num}',                       50),
  ('${num}','accountcode',          '',                             19),
  ('${num}','aggregate_mwi',        'yes',                          27),
  ('${num}','allow',                'opus,ulaw,alaw',               17),
  ('${num}','avpf',                 'no',                           11),
  ('${num}','bundle',               'no',                           28),
  ('${num}','callerid',             '${safe_name} <${num}>',        51),
  ('${num}','context',              'from-internal',                47),
  ('${num}','defaultuser',          '',                              4),
  ('${num}','device_state_busy_at', '0',                            38),
  ('${num}','dial',                 'PJSIP/${num}',                 18),
  ('${num}','direct_media',         'yes',                          34),
  ('${num}','disallow',             'all',                          16),
  ('${num}','dtmfmode',             'rfc4733',                       3),
  ('${num}','force_rport',          'yes',                          25),
  ('${num}','icesupport',           'no',                           12),
  ('${num}','match',                '',                             39),
  ('${num}','max_audio_streams',    '1',                            29),
  ('${num}','max_contacts',         '1',                            20),
  ('${num}','max_video_streams',    '1',                            30),
  ('${num}','maximum_expiration',   '7200',                         40),
  ('${num}','media_address',        '',                             35),
  ('${num}','media_encryption',     'no',                           31),
  ('${num}','media_encryption_optimistic', 'no',                    36),
  ('${num}','media_use_received_transport','no',                    22),
  ('${num}','message_context',      '',                             46),
  ('${num}','minimum_expiration',   '60',                           41),
  ('${num}','mwi_subscription',     'auto',                         26),
  ('${num}','namedcallgroup',       '',                             14),
  ('${num}','namedpickupgroup',     '',                             15),
  ('${num}','outbound_auth',        'yes',                          45),
  ('${num}','outbound_proxy',       '',                             44),
  ('${num}','qualifyfreq',          '60',                            9),
  ('${num}','refer_blind_progress', 'yes',                          37),
  ('${num}','remove_existing',      'yes',                          21),
  ('${num}','rewrite_contact',      'yes',                          24),
  ('${num}','rtcp_mux',             'no',                           13),
  ('${num}','rtp_symmetric',        'yes',                          23),
  ('${num}','rtp_timeout',          '0',                            42),
  ('${num}','rtp_timeout_hold',     '0',                            43),
  ('${num}','secret',               '${pass}',                       2),
  ('${num}','secret_origional',     '${pass}',                      48),
  ('${num}','send_connected_line',  'yes',                           6),
  ('${num}','sendrpid',             'pai',                           8),
  ('${num}','sipdriver',            'chan_pjsip',                   49),
  ('${num}','timers',               'yes',                          32),
  ('${num}','timers_min_se',        '90',                           33),
  ('${num}','transport',            '',                             10),
  ('${num}','trustrpid',            'yes',                           5),
  ('${num}','user_eq_phone',        'no',                            7);
EXTEOF
    echo "  [OK] Extension $num insérée (devices + users + sip — 50 keywords)"
    # Afficher le mot de passe pour livraison
    echo "  MOT DE PASSE EXT $num : ${pass}"
}

if [[ -n "$EXT1_NUMBER" ]]; then
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] Kit starter — INSERT extensions (template V3)..."
    insert_extension "$EXT1_NUMBER" "$EXT1_NAME" "$EXT1_PASS"
    insert_extension "$EXT2_NUMBER" "$EXT2_NAME" "$EXT2_PASS"
    insert_extension "$EXT3_NUMBER" "$EXT3_NAME" "$EXT3_PASS"
    fwconsole reload 2>&1 | tail -3 || true
    ufw --force enable 2>&1 | grep -E 'active|enabled|Firewall'
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] EXTENSIONS_OK"
else
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] Kit starter désactivé — aucune extension créée"
fi

# ── fwconsole reload final ────────────────────────────────
fwconsole reload 2>&1 | tail -3 || true
ufw --force enable 2>&1 | grep -E 'active|enabled|Firewall'

# ── Trunk SIP (optionnel, E22) ────────────────────────────
if [[ -n "$TRUNK_REGISTRAR" && -n "$TRUNK_USERNAME" && -n "$TRUNK_PASSWORD" ]]; then
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] Configuration trunk $TRUNK_NAME..."
    TRUNK_PROVIDER=$(echo "$TRUNK_REGISTRAR" | awk -F'.' '{print $(NF-1)}' | tr '[:lower:]' '[:upper:]')
    # Échappement apostrophes pour SQL — évite casse si credentials contiennent '
    _st_pass="${TRUNK_PASSWORD//\'/\'\'}"
    _st_user="${TRUNK_USERNAME//\'/\'\'}"
    _st_reg="${TRUNK_REGISTRAR//\'/\'\'}"
    _st_name="${TRUNK_NAME//\'/\'\'}"
    _st_cid="${TRUNK_CALLERID//\'/\'\'}"

    mysql -u root asterisk << TRUNKEOF
SET @existing_tid = (SELECT trunkid FROM trunks WHERE name='${_st_name}' LIMIT 1);
DELETE FROM pjsip WHERE id = @existing_tid AND @existing_tid IS NOT NULL;
DELETE FROM trunks WHERE name='${_st_name}';
SET @tid = (SELECT COALESCE(MAX(trunkid), 0) + 1 FROM trunks);
INSERT INTO trunks (trunkid, tech, channelid, name, outcid, keepcid, maxchans, failscript, dialoutprefix, usercontext, provider, disabled, \`continue\`, routedisplay)
VALUES (@tid, 'pjsip', '${_st_name}', '${_st_name}', '${_st_cid}', 'off', '', '', '', NULL, '${TRUNK_PROVIDER}', 'off', 'off', 'on');
INSERT INTO pjsip (id, keyword, data, flags) VALUES
  (@tid, 'trunk_name',               '${_st_name}',         0),
  (@tid, 'username',                 '${_st_user}',         0),
  (@tid, 'auth_username',            '${_st_user}',         0),
  (@tid, 'secret',                   '${_st_pass}',         0),
  (@tid, 'authentication',           'outbound',            0),
  (@tid, 'registration',             'send',                0),
  (@tid, 'sip_server',               '${_st_reg}',          0),
  (@tid, 'from_user',                '${_st_user}',         0),
  (@tid, 'from_domain',              '${_st_reg}',          0),
  (@tid, 'context',                  'from-pstn',           0),
  (@tid, 'transport',                '0.0.0.0-udp',         0),
  (@tid, 'codecs',                   'ulaw,alaw,gsm,g726,g722', 0),
  (@tid, 'expiration',               '3600',                0),
  (@tid, 'retry_interval',           '60',                  0),
  (@tid, 'fatal_retry_interval',     '60',                  0),
  (@tid, 'forbidden_retry_interval', '60',                  0),
  (@tid, 'qualify_frequency',        '60',                  0),
  (@tid, 'dtmfmode',                 'rfc4733',             0),
  (@tid, 'disabled',                 'off',                 0),
  (@tid, 'name',                     '${_st_name}',         0),
  (@tid, 'maxchans',                 '',                    0),
  (@tid, 'routedisplay',             'on',                  0);
TRUNKEOF
    fwconsole reload 2>&1 | tail -3 || true
    ufw --force enable 2>&1 | grep -E 'active|enabled|Firewall'
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] TRUNK_OK : $TRUNK_NAME ($TRUNK_REGISTRAR)"
else
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] Pas de trunk configuré"
fi

# ── chan_ooh323 + chan_iax2 : désactivation (E11) ─────────
asterisk -rx 'module unload chan_ooh323.so' 2>/dev/null || true
grep -q 'chan_ooh323.so' /etc/asterisk/modules.conf || \
    echo 'noload = chan_ooh323.so' >> /etc/asterisk/modules.conf
asterisk -rx 'module unload chan_iax2.so' 2>/dev/null || true
grep -q 'chan_iax2.so' /etc/asterisk/modules.conf || \
    echo 'noload = chan_iax2.so' >> /etc/asterisk/modules.conf

echo "[$(date '+%Y-%m-%d %H:%M:%S')] === POST_RESTORE_COMPLETE ==="
__FPBXPHASE_06_POST_RESTORE_SH__
chmod +x "$_PHASES_TMP/06_post_restore.sh"

cat > "$_PHASES_TMP/09_apache_hardening.sh" <<'__FPBXPHASE_09_APACHE_HARDENING_SH__'
#!/bin/bash
# 09_apache_hardening.sh — Durcissement Apache post-restore
#
# Masquage version, désactivation TRACE, security headers
# Équivalent de 09_apache_hardening.yml (playbook Ansible)

set -euo pipefail
LOG=/var/log/freepbx-factory/deploy-phase-09-apache-hardening.log
touch "$LOG" && chmod 600 "$LOG"
exec > >(tee -a "$LOG") 2>&1

echo "[$(date '+%Y-%m-%d %H:%M:%S')] === PHASE 09_APACHE_HARDENING ==="

SEC=/etc/apache2/conf-available/security.conf

sed -i 's/^#\?ServerTokens.*/ServerTokens Prod/'     "$SEC"
sed -i 's/^#\?ServerSignature.*/ServerSignature Off/' "$SEC"
sed -i 's/^#\?TraceEnable.*/TraceEnable Off/'         "$SEC"

a2enmod headers -q 2>/dev/null || true

cat > /etc/apache2/conf-available/freepbx-security-headers.conf << 'EOF'
<IfModule mod_headers.c>
  Header always set X-Frame-Options "SAMEORIGIN"
  Header always set X-Content-Type-Options "nosniff"
  Header always set X-XSS-Protection "1; mode=block"
  Header always set Referrer-Policy "strict-origin-when-cross-origin"
  Header always unset X-Powered-By
</IfModule>
EOF

a2enconf freepbx-security-headers -q 2>/dev/null || true

sed -i 's/Options Indexes FollowSymLinks/Options FollowSymLinks/' \
    /etc/apache2/apache2.conf 2>/dev/null || true

systemctl reload apache2 2>/dev/null || echo "[AVERTISSEMENT] Apache non actif au moment du reload — headers appliqués au prochain démarrage"

HEADERS=$(curl -sI http://localhost/admin/ 2>/dev/null)
echo "X-Frame-Options    : $(echo "$HEADERS" | grep -i 'X-Frame-Options' || echo 'ABSENT')"
echo "X-Content-Type     : $(echo "$HEADERS" | grep -i 'X-Content-Type-Options' || echo 'ABSENT')"
echo "ServerTokens check : $(curl -sI http://localhost/ 2>/dev/null | grep -i 'Server:' || echo 'OK masqué')"

echo "[$(date '+%Y-%m-%d %H:%M:%S')] === APACHE_HARDENING_COMPLETE ==="
__FPBXPHASE_09_APACHE_HARDENING_SH__
chmod +x "$_PHASES_TMP/09_apache_hardening.sh"

cat > "$_PHASES_TMP/10_mariadb_hardening.sh" <<'__FPBXPHASE_10_MARIADB_HARDENING_SH__'
#!/bin/bash
# 10_mariadb_hardening.sh — Durcissement MariaDB post-restore
#
# Équivalent de 10_mariadb_hardening.yml (playbook Ansible)
# Suppression comptes anonymes, base test, bind=127.0.0.1

set -euo pipefail
LOG=/var/log/freepbx-factory/deploy-phase-10-mariadb-hardening.log
touch "$LOG" && chmod 600 "$LOG"
exec > >(tee -a "$LOG") 2>&1

echo "[$(date '+%Y-%m-%d %H:%M:%S')] === PHASE 10_MARIADB_HARDENING ==="

mysql -u root << 'SQLEOF'
DELETE FROM mysql.user WHERE User='';
DROP DATABASE IF EXISTS test;
DELETE FROM mysql.db WHERE Db LIKE 'test%';
FLUSH PRIVILEGES;
SQLEOF

echo "[$(date '+%Y-%m-%d %H:%M:%S')] Anonymes et base test supprimés"

CNF=/etc/mysql/mariadb.conf.d/50-server.cnf
sed -i 's/^#\?bind-address.*/bind-address = 127.0.0.1/' "$CNF"

systemctl restart mariadb

PORT_CHECK=$(ss -tlnp | grep ':3306' || true)
if echo "$PORT_CHECK" | grep -qE '0\.0\.0\.0:3306|\*:3306'; then
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] ATTENTION : MariaDB écoute sur 0.0.0.0:3306"
else
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] bind-address : 127.0.0.1 OK"
fi

echo "[$(date '+%Y-%m-%d %H:%M:%S')] === MARIADB_HARDENING_COMPLETE ==="
__FPBXPHASE_10_MARIADB_HARDENING_SH__
chmod +x "$_PHASES_TMP/10_mariadb_hardening.sh"

cat > "$_PHASES_TMP/11_services_hardening.sh" <<'__FPBXPHASE_11_SERVICES_HARDENING_SH__'
#!/bin/bash
# 11_services_hardening.sh — Désactivation services inutiles post-FreePBX
#
# Découverts lors de l'audit sécurité 04/05/2026 :
#   tftpd-hpa     : TFTP non authentifié — inutile si PnP désactivé
#   avahi-daemon  : mDNS/DNS-SD — expose infos réseau sur 5353/UDP
#   asterisk shell: bash → nologin (réduction escalade si compromission)
#
# Usage : sudo bash /tmp/11_services_hardening.sh

set -euo pipefail
LOG=/var/log/freepbx-factory/deploy-phase-11-services-hardening.log
touch "$LOG" && chmod 600 "$LOG"
exec > >(tee -a "$LOG") 2>&1

echo "[$(date '+%Y-%m-%d %H:%M:%S')] === PHASE 11_SERVICES_HARDENING ==="

# tftpd-hpa (port 69/udp)
echo "[$(date '+%Y-%m-%d %H:%M:%S')] Désactivation tftpd-hpa..."
if systemctl is-enabled tftpd-hpa &>/dev/null || systemctl is-active tftpd-hpa &>/dev/null; then
    systemctl stop tftpd-hpa 2>/dev/null || true
    systemctl disable tftpd-hpa 2>/dev/null || true
    echo "  [OK] tftpd-hpa arrêté et désactivé"
else
    echo "  [--] tftpd-hpa absent ou déjà désactivé"
fi

# avahi-daemon (port 5353/udp mDNS)
echo "[$(date '+%Y-%m-%d %H:%M:%S')] Désactivation avahi-daemon..."
for svc in avahi-daemon avahi-daemon.socket; do
    if systemctl is-enabled "$svc" &>/dev/null || systemctl is-active "$svc" &>/dev/null; then
        systemctl stop "$svc" 2>/dev/null || true
        systemctl disable "$svc" 2>/dev/null || true
        echo "  [OK] $svc arrêté et désactivé"
    else
        echo "  [--] $svc absent ou déjà désactivé"
    fi
done

# sangoma-pnpd (PnP — inutile si pas de déploiement automatique de téléphones)
echo "[$(date '+%Y-%m-%d %H:%M:%S')] Désactivation sangoma-pnpd..."
for svc in sangoma-pnpd; do
    if systemctl is-enabled "$svc" &>/dev/null || systemctl is-active "$svc" &>/dev/null; then
        systemctl stop "$svc" 2>/dev/null || true
        systemctl disable "$svc" 2>/dev/null || true
        echo "  [OK] $svc arrêté et désactivé"
    else
        echo "  [--] $svc absent ou déjà désactivé"
    fi
done

# asterisk : shell bash → nologin (réduction surface escalade)
echo "[$(date '+%Y-%m-%d %H:%M:%S')] Shell asterisk → nologin..."
CURRENT_SHELL=$(getent passwd asterisk | cut -d: -f7)
if [[ "$CURRENT_SHELL" == "/usr/sbin/nologin" ]]; then
    echo "  [--] Shell asterisk déjà nologin"
else
    usermod -s /usr/sbin/nologin asterisk
    echo "  [OK] Shell asterisk : $CURRENT_SHELL → /usr/sbin/nologin"
fi

# asterisk : override systemd Restart=on-failure
# fwconsole reload peut déclencher un graceful restart qui se termine après le script
# → sans override, Asterisk reste arrêté jusqu'au prochain reboot ou relance manuelle
echo "[$(date '+%Y-%m-%d %H:%M:%S')] Override systemd asterisk (Restart=on-failure)..."
mkdir -p /etc/systemd/system/asterisk.service.d/
cat > /etc/systemd/system/asterisk.service.d/restart.conf << 'EOF'
[Service]
Restart=on-failure
RestartSec=10
EOF
systemctl daemon-reload
echo "  [OK] asterisk.service : Restart=on-failure, RestartSec=10"

# Validation ports UDP
echo "[$(date '+%Y-%m-%d %H:%M:%S')] Validation ports UDP..."
TFTP_PORT=$(ss -ulnp 2>/dev/null | grep ':69 ' || echo "")
AVAHI_PORT=$(ss -ulnp 2>/dev/null | grep ':5353 ' || echo "")

if [[ -n "$TFTP_PORT" ]]; then
    echo "  ATTENTION port 69 encore ouvert : $TFTP_PORT"
else
    echo "  [OK] Port 69/UDP (TFTP) fermé"
fi

if [[ -n "$AVAHI_PORT" ]]; then
    echo "  ATTENTION port 5353 encore ouvert : $AVAHI_PORT"
else
    echo "  [OK] Port 5353/UDP (mDNS) fermé"
fi

echo "[$(date '+%Y-%m-%d %H:%M:%S')] === SERVICES_HARDENING_COMPLETE ==="
__FPBXPHASE_11_SERVICES_HARDENING_SH__
chmod +x "$_PHASES_TMP/11_services_hardening.sh"

cat > "$_PHASES_TMP/12_sbom.sh" <<'__FPBXPHASE_12_SBOM_SH__'
#!/bin/bash
# 12_sbom.sh — SBOM CycloneDX 1.4 (CRA Annex II + NIS2 Art. 21)
#
# Génère /etc/freepbx-factory/sbom.json
# Composants : FreePBX, Asterisk, PHP, Apache2, MariaDB, Node.js, OS, kernel
#
# Usage : sudo bash 12_sbom.sh

set -euo pipefail
LOG=/var/log/freepbx-factory/deploy-phase-12-sbom.log
touch "$LOG" && chmod 600 "$LOG"
exec > >(tee -a "$LOG") 2>&1

echo "[$(date '+%Y-%m-%d %H:%M:%S')] === PHASE 12_SBOM (CRA Annex II) ==="

mkdir -p /etc/freepbx-factory
chmod 700 /etc/freepbx-factory

python3 << 'PYEOF'
import json, subprocess, datetime, os, socket

def run(cmd):
    try:
        return subprocess.check_output(cmd, shell=True, stderr=subprocess.DEVNULL, text=True).strip()
    except:
        return 'unknown'

sec_updates_raw = run("apt list --upgradable 2>/dev/null | grep -i security | wc -l")
try:
    sec_updates = int(sec_updates_raw)
except:
    sec_updates = 0

dpkg_raw = run("dpkg-query -l 2>/dev/null | grep -c '^ii'")
try:
    dpkg_count = int(dpkg_raw)
except:
    dpkg_count = 0

sbom = {
    "bomFormat": "CycloneDX",
    "specVersion": "1.4",
    "metadata": {
        "timestamp": datetime.datetime.utcnow().strftime('%Y-%m-%dT%H:%M:%SZ'),
        "component": {"name": "freepbx-factory", "version": "1.9", "supplier": "OVHcloud"}
    },
    "components": [
        {"type": "application", "name": "FreePBX",  "version": run("fwconsole --version 2>/dev/null | awk '{print $NF}'")},
        {"type": "application", "name": "Asterisk",  "version": run("asterisk -rx 'core show version' 2>/dev/null | awk '{print $2}'")},
        {"type": "library",     "name": "PHP",        "version": run("php --version 2>/dev/null | head -1 | awk '{print $2}'")},
        {"type": "application", "name": "Apache2",    "version": run("apache2 -v 2>/dev/null | head -1 | awk '{print $3}' | sed 's|Apache/||'")},
        {"type": "application", "name": "MariaDB",    "version": run("mysql --version 2>/dev/null | awk '{print $5}' | tr -d ','")},
        {"type": "library",     "name": "Node.js",    "version": run("node --version 2>/dev/null | tr -d v")},
    ],
    "vulnerabilities": {
        "pending_security_updates": sec_updates,
        "unattended_upgrades_active": run("systemctl is-active unattended-upgrades 2>/dev/null") == "active",
        "packages_total": dpkg_count
    },
    "environment": {
        "os":       run(". /etc/os-release && echo $PRETTY_NAME"),
        "kernel":   run("uname -r"),
        "hostname": socket.gethostname()
    }
}

with open('/etc/freepbx-factory/sbom.json', 'w') as f:
    json.dump(sbom, f, indent=2)

if sec_updates > 0:
    print(f"[WARN] {sec_updates} mise(s) à jour de sécurité en attente")
    print("  Application immédiate : sudo unattended-upgrade -d")
else:
    print("  Mises à jour sécurité : aucune en attente")

print(f"  Packages installés    : {dpkg_count}")
print("  SBOM écrit            : /etc/freepbx-factory/sbom.json")
PYEOF

echo "[$(date '+%Y-%m-%d %H:%M:%S')] === SBOM_COMPLETE ==="
__FPBXPHASE_12_SBOM_SH__
chmod +x "$_PHASES_TMP/12_sbom.sh"

cat > "$_PHASES_TMP/13_post_checks.sh" <<'__FPBXPHASE_13_POST_CHECKS_SH__'
#!/bin/bash
# 13_post_checks.sh — Contrôles conformité post-déploiement
#
# CRA UE 2024/2847 + NIS2 UE 2022/2555
# Génère /etc/freepbx-factory/compliance-report.json
# Affiche le score et les points en avertissement
#
# Usage : sudo bash 13_post_checks.sh <ssh_port>

set -euo pipefail
LOG=/var/log/freepbx-factory/deploy-phase-13-post-checks.log
touch "$LOG" && chmod 600 "$LOG"
exec > >(tee -a "$LOG") 2>&1

SSH_PORT="${1:?Argument 1 requis : ssh_port}"

echo "[$(date '+%Y-%m-%d %H:%M:%S')] === PHASE 13_POST_CHECKS (CRA + NIS2) ==="

mkdir -p /etc/freepbx-factory
chmod 700 /etc/freepbx-factory

python3 << PYEOF
import json, subprocess, datetime, os, re

def run(cmd):
    try:
        return subprocess.check_output(cmd, shell=True, stderr=subprocess.DEVNULL, text=True).strip()
    except:
        return ''

def check(name, ok, value, requirement):
    return {"name": name, "status": "ok" if ok else "warning", "value": value, "requirement": requirement}

ssh_port = "${SSH_PORT}"
checks = []

# Réseau
ufw_status = run("ufw status")
checks.append(check("UFW — Pare-feu actif", "Status: active" in ufw_status,
    "active" if "Status: active" in ufw_status else "inactive", "CRA Annex I + NIS2 Art.21"))

ufw_logging = run("ufw status verbose 2>/dev/null | grep 'Logging:'")
checks.append(check("UFW — Journalisation activée",
    any(x in ufw_logging for x in ["low","medium","high"]),
    ufw_logging.strip() or "désactivée", "NIS2 Art.21(b)"))

# fail2ban
f2b_jails = run("fail2ban-client status 2>/dev/null | grep 'Number of jail'")
m = re.search(r':\s*(\d+)', f2b_jails)
jail_count = int(m.group(1)) if m else 0
checks.append(check("fail2ban — 7 jails actifs", jail_count >= 7, f"{jail_count} jails", "NIS2 Art.21(b)"))

f2b_bantime = run("fail2ban-client get ssh-iptables bantime 2>/dev/null")
checks.append(check("fail2ban — Bantime 24h", f2b_bantime == "86400", f"{f2b_bantime}s", "NIS2 Art.21(b)"))

f2b_actions = run("fail2ban-client get ssh-iptables actions 2>/dev/null")
checks.append(check("fail2ban — Actions iptables actives", "No actions" not in f2b_actions,
    "actif" if "No actions" not in f2b_actions else "ABSENT", "E23 — CRA Annex I"))

# Ports dangereux
checks.append(check("Port H.323 (1720) fermé", run("ss -tlnp | grep ':1720'") == "",
    "fermé", "CRA Annex I"))
checks.append(check("Port IAX2 (4569) fermé", run("ss -ulnp | grep ':4569'") == "",
    "fermé", "CRA Annex I"))

# MariaDB
mariadb = run("ss -tlnp | grep '3306'")
mariadb_local = "127.0.0.1:3306" in mariadb
checks.append(check("MariaDB — localhost uniquement", mariadb_local,
    "127.0.0.1" if mariadb_local else "exposé", "CRA Annex I"))

# Services
pnpd = run("systemctl is-active sangoma-pnpd 2>/dev/null")
checks.append(check("sangoma-pnpd — désactivé", pnpd != "active", pnpd or "inactif", "CRA Annex I"))

auditd = run("systemctl is-active auditd 2>/dev/null")
checks.append(check("auditd — Journalisation active", auditd == "active", auditd or "inactif", "NIS2 Art.21(b)"))

# SSH
ssh_pass = run("sshd -T 2>/dev/null | grep passwordauthentication")
checks.append(check("SSH — Auth par clé uniquement", "no" in ssh_pass, ssh_pass or "inconnu", "CRA Art.13(6)"))

actual_port = run("sshd -T 2>/dev/null | grep '^port ' | awk '{print \$2}'")
checks.append(check("SSH — Port non standard", actual_port != "22",
    f"port {actual_port}" if actual_port else f"port {ssh_port}", "CRA Annex I"))

# Mises à jour
unattended = run("systemctl is-active unattended-upgrades 2>/dev/null")
checks.append(check("Mises à jour auto sécurité", unattended == "active", unattended, "CRA Art.13 + NIS2 Art.21(e)"))

# Asterisk
asterisk_shell = run("getent passwd asterisk | cut -d: -f7")
checks.append(check("asterisk — shell nologin", "nologin" in asterisk_shell, asterisk_shell, "CRA Annex I"))

# SBOM
sbom_ok = os.path.exists('/etc/freepbx-factory/sbom.json')
checks.append(check("SBOM — Fichier présent", sbom_ok,
    "/etc/freepbx-factory/sbom.json" if sbom_ok else "absent", "CRA Annex II"))

ok_count = sum(1 for c in checks if c["status"] == "ok")
total = len(checks)
score = int(ok_count * 100 / total)

report = {
    "schema": "freepbx-factory-compliance/1.0",
    "timestamp": datetime.datetime.utcnow().strftime('%Y-%m-%dT%H:%M:%SZ'),
    "score": {"ok": ok_count, "total": total, "percent": score},
    "frameworks": ["CRA UE 2024/2847", "NIS2 UE 2022/2555"],
    "checks": checks
}

with open('/etc/freepbx-factory/compliance-report.json', 'w') as f:
    json.dump(report, f, indent=2)

print(f"\n  Score conformité : {score}% ({ok_count}/{total} contrôles OK)")
warnings = [c for c in checks if c["status"] != "ok"]
if warnings:
    print(f"  Points en avertissement :")
    for w in warnings:
        print(f"    ⚠  {w['name']} : {w['value']} ({w['requirement']})")
else:
    print("  Tous les contrôles sont OK")
print(f"  Rapport : /etc/freepbx-factory/compliance-report.json")
PYEOF

echo "[$(date '+%Y-%m-%d %H:%M:%S')] === POST_CHECKS_COMPLETE ==="
__FPBXPHASE_13_POST_CHECKS_SH__
chmod +x "$_PHASES_TMP/13_post_checks.sh"

cat > "$_PHASES_TMP/14_auditd.sh" <<'__FPBXPHASE_14_AUDITD_SH__'
#!/bin/bash
# 14_auditd.sh — Journalisation actions privilégiées (NIS2 Art. 21b)
#
# Installe auditd + règles de surveillance FreePBX Factory :
#   /etc/passwd, /etc/shadow, /etc/group         — modifications identité
#   /etc/ssh/sshd_config                          — modifications SSH
#   /home/debian/.ssh/authorized_keys             — modifications clés SSH
#   /etc/sudoers, /etc/sudoers.d/                 — élévation de privilèges
#   /etc/freepbx-factory/                         — configuration factory
#   syscall execve (euid=0)                        — commandes root tracées
#
# Les journaux auditd sont dans /var/log/audit/audit.log

set -euo pipefail
LOG=/var/log/freepbx-factory/deploy-phase-14-auditd.log
touch "$LOG" && chmod 600 "$LOG"
exec > >(tee -a "$LOG") 2>&1

echo "[$(date '+%Y-%m-%d %H:%M:%S')] === PHASE 14_AUDITD (NIS2 Art. 21b) ==="

# ── Installation ─────────────────────────────────────────────────────────────
DEBIAN_FRONTEND=noninteractive apt-get install -y auditd audispd-plugins -q

# ── Règles FreePBX Factory ────────────────────────────────────────────────────
cat > /etc/audit/rules.d/freepbx-factory.rules << 'RULES'
# FreePBX Factory — surveillance auth et actions privilégiées
# NIS2 Art. 21(b) — Détection et gestion des incidents

# Identité système
-w /etc/passwd -p wa -k identity
-w /etc/shadow -p wa -k identity
-w /etc/group  -p wa -k identity

# SSH
-w /etc/ssh/sshd_config -p wa -k sshd_config
-w /home/debian/.ssh/authorized_keys -p wa -k ssh_keys

# Élévation de privilèges
-w /etc/sudoers    -p wa -k sudoers
-w /etc/sudoers.d/ -p wa -k sudoers

# Configuration FreePBX Factory
-w /etc/freepbx-factory/ -p rwxa -k factory_config

# Commandes root tracées (execve avec euid=0)
-a always,exit -F arch=b64 -S execve -F euid=0 -F auid>=1000 -k privileged_exec
RULES

chmod 0600 /etc/audit/rules.d/freepbx-factory.rules

# ── Activation + démarrage ────────────────────────────────────────────────────
systemctl enable auditd
systemctl restart auditd

# ── Vérification ─────────────────────────────────────────────────────────────
if systemctl is-active --quiet auditd; then
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] auditd actif — règles freepbx-factory.rules chargées"
    auditctl -l 2>/dev/null | grep -c "freepbx-factory\|identity\|sshd_config\|sudoers\|privileged" || true
else
    echo "[WARN] auditd démarré mais statut non confirmé — vérifier manuellement"
fi

echo "[$(date '+%Y-%m-%d %H:%M:%S')] === AUDITD_COMPLETE ==="
__FPBXPHASE_14_AUDITD_SH__
chmod +x "$_PHASES_TMP/14_auditd.sh"

cat > "$_PHASES_TMP/15_tls.sh" <<'__FPBXPHASE_15_TLS_SH__'
#!/bin/bash
# 15_tls.sh — Certificat Let's Encrypt + Apache HTTPS (NIS2 Art. 21d)
#
# Si TLS_DOMAIN est fourni  : installe certbot, obtient le certificat via
#   webroot (pas de plugin Apache — évite l'ambiguïté vhost FreePBX 17),
#   configure manuellement les VirtualHost HTTP (redirect) et HTTPS (LE cert),
#   garde Apache actif.
# Si TLS_DOMAIN est vide    : Apache est arrêté, GUI inaccessible jusqu'à
#   configuration TLS ultérieure.
#
# Correctif E_TLS : FreePBX 17 n'installe pas de <VirtualHost> dans freepbx.conf
#   (seulement des <Directory>) — certbot --apache voit plusieurs vhosts sans
#   ServerName correspondant → "vhost ambiguity" → échec installation cert.
#   Solution : certbot certonly --webroot + configuration manuelle des vhosts.
#
# Prérequis : Apache doit être démarré (phase 09 + validation GUI déjà faites)
# Argument  : $1 = FQDN (ex: pbx.mon-entreprise.fr)
RED='\033[0;31m'; YELLOW='\033[1;33m'; GREEN='\033[0;32m'; NC='\033[0m'

set -euo pipefail
LOG=/var/log/freepbx-factory/deploy-phase-15-tls.log
touch "$LOG" && chmod 600 "$LOG"
exec > >(tee -a "$LOG") 2>&1

TLS_DOMAIN="${TLS_DOMAIN:-${1:-}}"

if [[ -z "$TLS_DOMAIN" ]]; then
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] === PHASE 15_TLS — ignorée (TLS_DOMAIN vide) ==="
    echo "[INFO] Apache va être arrêté — GUI FreePBX inaccessible jusqu'à config TLS"
    systemctl stop apache2 2>/dev/null || true
    systemctl disable apache2 2>/dev/null || true
    echo "[INFO] Pour activer HTTPS ultérieurement, relancer avec TLS_DOMAIN=<domaine>"
    exit 0
fi

echo "[$(date '+%Y-%m-%d %H:%M:%S')] === PHASE 15_TLS — $TLS_DOMAIN ==="

# ── 1. Certbot ────────────────────────────────────────────────────────────────
DEBIAN_FRONTEND=noninteractive apt-get install -y certbot -q

# ── 2. Préparation vhost HTTP pour challenge ACME ─────────────────────────────
# FreePBX 17 : freepbx.conf contient uniquement des <Directory>, pas de
# <VirtualHost>. Le vhost réel est 000-default.conf (port 80).
# On ajoute ServerName pour que certbot puisse l'identifier, puis on
# utilise --webroot pour éviter tout parsing vhost par certbot.
a2enmod rewrite ssl -q 2>/dev/null || true

# ServerName dans le vhost HTTP par défaut (requis pour certbot --webroot)
if ! grep -q "ServerName" /etc/apache2/sites-available/000-default.conf 2>/dev/null; then
    sed -i "s|ServerAdmin webmaster@localhost|ServerName $TLS_DOMAIN\n\tServerAdmin webmaster@localhost|" \
        /etc/apache2/sites-available/000-default.conf
    echo "[INFO] ServerName $TLS_DOMAIN ajouté à 000-default.conf"
fi
systemctl reload apache2 || true

# ── 3. Certificat Let's Encrypt (webroot — pas de plugin Apache) ──────────────
# --webroot : certbot dépose /.well-known/acme-challenge/ dans /var/www/html
# Apache sert le challenge sur port 80 — aucune manipulation de vhost
if ! certbot certonly \
    --webroot -w /var/www/html \
    -d "$TLS_DOMAIN" \
    --non-interactive \
    --agree-tos \
    --register-unsafely-without-email; then
    echo -e "${YELLOW}╔══════════════════════════════════════════════════════════╗${NC}"
    echo -e "${YELLOW}║  AVERTISSEMENT — Certificat TLS non obtenu               ║${NC}"
    echo -e "${YELLOW}╠══════════════════════════════════════════════════════════╣${NC}"
    echo -e "${YELLOW}║  Domaine  : $TLS_DOMAIN${NC}"
    echo -e "${YELLOW}║  Causes   : DNS non propagé, rate limit LE, port 80 NAT  ║${NC}"
    echo -e "${YELLOW}║  Action   : Apache arrêté — GUI inaccessible              ║${NC}"
    echo -e "${YELLOW}║  Reprise  : sudo certbot certonly --webroot \\              ║${NC}"
    echo -e "${YELLOW}║             -w /var/www/html -d $TLS_DOMAIN${NC}"
    echo -e "${YELLOW}╚══════════════════════════════════════════════════════════╝${NC}"
    systemctl stop apache2 2>/dev/null || true
    systemctl disable apache2 2>/dev/null || true
    exit 0
fi

CERT_DIR="/etc/letsencrypt/live/$TLS_DOMAIN"
echo "[INFO] Certificat obtenu : $CERT_DIR/fullchain.pem"

# ── 4. VirtualHost HTTP : redirect → HTTPS ───────────────────────────────────
cat > /etc/apache2/sites-available/000-default.conf << VHOST_EOF
<VirtualHost *:80>
    ServerName $TLS_DOMAIN
    ServerAdmin webmaster@localhost
    DocumentRoot /var/www/html
    RewriteEngine On
    RewriteCond %{HTTPS} off
    RewriteRule ^ https://%{HTTP_HOST}%{REQUEST_URI} [L,R=301]
    ErrorLog \${APACHE_LOG_DIR}/error.log
    CustomLog \${APACHE_LOG_DIR}/access.log combined
</VirtualHost>
VHOST_EOF
echo "[INFO] VHost HTTP configuré (redirect 301 → HTTPS)"

# ── 5. VirtualHost HTTPS avec cert Let's Encrypt ────────────────────────────
# options-ssl-apache.conf est créé par certbot (protocoles, ciphers Mozilla)
SSL_OPTIONS=""
[[ -f /etc/letsencrypt/options-ssl-apache.conf ]] && \
    SSL_OPTIONS="    Include /etc/letsencrypt/options-ssl-apache.conf"

cat > /etc/apache2/sites-available/default-ssl.conf << SSL_EOF
<VirtualHost *:443>
    ServerName $TLS_DOMAIN
    ServerAdmin webmaster@localhost
    DocumentRoot /var/www/html
    SSLEngine on
    SSLCertificateFile     $CERT_DIR/fullchain.pem
    SSLCertificateKeyFile  $CERT_DIR/privkey.pem
$SSL_OPTIONS
    Header always set Strict-Transport-Security "max-age=31536000; includeSubDomains; preload"
    ErrorLog \${APACHE_LOG_DIR}/ssl_error.log
    CustomLog \${APACHE_LOG_DIR}/ssl_access.log combined
</VirtualHost>
SSL_EOF
echo "[INFO] VHost HTTPS configuré avec cert LE"

# ── 6. Activer modules + site SSL + reload ────────────────────────────────────
a2enmod headers -q 2>/dev/null || true
a2ensite default-ssl -q 2>/dev/null || true
apache2ctl configtest
systemctl reload apache2
systemctl enable apache2
echo "[INFO] Apache rechargé — HTTPS actif"

# ── 7. Vérification ───────────────────────────────────────────────────────────
echo "[$(date '+%Y-%m-%d %H:%M:%S')] Vérification HTTPS..."
sleep 3
HTTP_REDIR=$(curl -s --max-time 10 -o /dev/null -w "%{http_code}" \
    "http://$TLS_DOMAIN/admin/" 2>/dev/null || echo "000")
HTTPS_CODE=$(curl -sk --max-time 10 -o /dev/null -w "%{http_code}" \
    "https://$TLS_DOMAIN/admin/" 2>/dev/null || echo "000")

if [[ "$HTTP_REDIR" =~ ^(301|302)$ ]] && [[ "$HTTPS_CODE" =~ ^(200|302|301)$ ]]; then
    echo "[OK] HTTP→$HTTP_REDIR redirect + HTTPS→$HTTPS_CODE opérationnel"
    echo "[OK] https://$TLS_DOMAIN/admin/"
else
    echo "[WARN] HTTP→$HTTP_REDIR / HTTPS→$HTTPS_CODE — vérifier manuellement"
    echo "       Délai DNS possible si le domaine vient d'être créé."
fi

# Renouvellement auto certbot
echo "[INFO] Renouvellement automatique : $(systemctl is-active certbot.timer 2>/dev/null || cat /etc/cron.d/certbot 2>/dev/null | grep -v '^#' | head -1 || echo 'non détecté')"

echo "[$(date '+%Y-%m-%d %H:%M:%S')] === TLS_COMPLETE — $TLS_DOMAIN ==="
__FPBXPHASE_15_TLS_SH__
chmod +x "$_PHASES_TMP/15_tls.sh"

PHASES_DIR="$_PHASES_TMP"
# @@BUNDLE_INJECT_END@@
FILES_DIR="$SCRIPT_DIR/files"

# ── Version + Télémétrie ────────────────────────────────────────────────────
SCRIPT_VERSION="1.9"
TELEMETRY_URL=""   # À configurer — vide = télémétrie désactivée

# ── Couleurs + logging ──────────────────────────────────────────────────────
LOG_DIR="/var/log/freepbx-factory"
mkdir -p "$LOG_DIR"
SESSION_LOG="$LOG_DIR/install-$(date '+%Y%m%d-%H%M%S').log"

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; CYAN='\033[0;36m'; NC='\033[0m'
log()  { echo -e "[$(date '+%H:%M:%S')] $*" | tee -a "$SESSION_LOG"; }
ok()   { echo -e "${GREEN}[OK]${NC} $*" | tee -a "$SESSION_LOG"; }
err()  { echo -e "${RED}[ERR]${NC} $*" | tee -a "$SESSION_LOG"; exit 1; }
warn() { echo -e "${YELLOW}[WARN]${NC} $*" | tee -a "$SESSION_LOG"; }
info() { echo -e "${CYAN}$*${NC}"; }

run_phase() {
    local script="$1"; shift
    local phase_name
    phase_name=$(basename "$script" .sh | tr '_' '-')
    local phase_log="/var/log/freepbx-factory/deploy-phase-${phase_name}.log"
    if ! bash "$script" "$@"; then
        echo ""
        warn "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        warn "ÉCHEC : $(basename "$script")"
        if [[ -f "$phase_log" ]]; then
            warn "Dernières lignes du log :"
            echo "────────────────────────────────────────────────────"
            tail -n 10 "$phase_log"
            echo "────────────────────────────────────────────────────"
            warn "Log complet : $phase_log"
        fi
        warn "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        err "Installation interrompue. Corriger l'erreur ci-dessus et relancer."
    fi
}

# ── Répertoire de logs persistants ──────────────────────────────────────────
mkdir -p /var/log/freepbx-factory
chmod 700 /var/log/freepbx-factory

# ── Pré-checks ──────────────────────────────────────────────────────────────
[[ $EUID -eq 0 ]] || err "Doit être exécuté en root : sudo bash $0"
[[ -f /etc/debian_version ]] || err "Système non supporté — Debian 12 requis"
DEB_VER=$(cut -d. -f1 /etc/debian_version)
[[ "$DEB_VER" == "12" ]] || warn "Version Debian détectée : $DEB_VER (Debian 12 recommandée)"

# ── Bootstrap : dépendances minimales ───────────────────────────────────────
_MISSING=()
for _pkg in wget curl tmux ca-certificates; do
    command -v "$_pkg" &>/dev/null || _MISSING+=("$_pkg")
done
if [[ ${#_MISSING[@]} -gt 0 ]]; then
    echo "Préparation de l'environnement..."
    apt-get update -qq && apt-get install -y "${_MISSING[@]}" -qq \
        || warn "Certaines dépendances n'ont pas pu être installées — vérifier la connectivité réseau"
fi

[[ -f "$PHASES_DIR/00_cleanup.sh" ]] || err "Scripts de phase introuvables dans $PHASES_DIR"
command -v wget &>/dev/null || err "wget introuvable après installation — vérifier la connectivité réseau"
command -v fwconsole &>/dev/null && err "FreePBX déjà installé — ce script est à usage unique."

# ── tmux : démarrage en session persistante ─────────────────────────────────
# La session survit à la déconnexion SSH lors du hardening SSH (port change).
if [[ -z "${FACTORY_IN_TMUX:-}" ]]; then
    DEBIAN_FRONTEND=noninteractive apt-get install -y tmux -q 2>/dev/null
    tmux kill-session -t factory 2>/dev/null || true
    echo ""
    echo -e "${CYAN}╔══════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║  Installation démarrée en session tmux persistante.  ║${NC}"
    echo -e "${CYAN}║  NE FERMEZ PAS cette fenêtre pendant le déploiement. ║${NC}"
    echo -e "${CYAN}║  Le port SSH définitif s'affiche en jaune avant le   ║${NC}"
    echo -e "${CYAN}║  déploiement — notez-le.                             ║${NC}"
    echo -e "${CYAN}║  En cas de perte : /root/freepbx-factory-ssh-port.txt║${NC}"
    echo -e "${CYAN}║  (console KVM OVHcloud si SSH inaccessible)          ║${NC}"
    echo -e "${CYAN}╚══════════════════════════════════════════════════════╝${NC}"
    echo ""
    # Transmettre TOUS les arguments du wizard à la session tmux (sinon perdus)
    _FWD_ARGS="${MANAGEMENT_IP_ARG:+--management-ip=$MANAGEMENT_IP_ARG} ${KIT_STARTER_ARG:+--kit-starter=$KIT_STARTER_ARG} ${TRUNK_ENABLED_ARG:+--trunk-enabled=$TRUNK_ENABLED_ARG} ${TRUNK_REGISTRAR_ARG:+--trunk-registrar=$TRUNK_REGISTRAR_ARG} ${TRUNK_USERNAME_ARG:+--trunk-username=$TRUNK_USERNAME_ARG} ${TLS_DOMAIN_ARG:+--tls-domain=$TLS_DOMAIN_ARG}"
    _FWD_ENV="FACTORY_IN_TMUX=1${FACTORY_TEST_ADMIN:+ FACTORY_TEST_ADMIN='${FACTORY_TEST_ADMIN}'}${FACTORY_TEST_PASS:+ FACTORY_TEST_PASS='${FACTORY_TEST_PASS}'}"
    tmux new-session -d -s factory -x 220 -y 50 \
        "eval export $_FWD_ENV; bash $0 $_FWD_ARGS; echo ''; if [[ -f /tmp/fpbx_deploy_done ]]; then echo '-- Déploiement terminé — Appuyer sur Entrée --'; rm -f /tmp/fpbx_deploy_done; else echo '-- Session terminée (annulée ou interrompue) — Appuyer sur Entrée --'; fi; read"
    tmux attach-session -t factory
    exit 0
fi

# ── Identifiant anonyme de déploiement ──────────────────────────────────────
# Généré une seule fois à l'entrée dans tmux — non transmis sans accord explicite
DEPLOY_ID=$(cat /proc/sys/kernel/random/uuid 2>/dev/null | tr -d '-' | cut -c1-16 \
            || head -c 8 /dev/urandom | od -An -tx1 | tr -d ' \n' | cut -c1-16 \
            || printf '%016d' "$(date +%s%N 2>/dev/null || date +%s)")
_OS_ID=$(. /etc/os-release 2>/dev/null && echo "${ID:-linux} ${VERSION_ID:-}" || echo "linux")

# ── Fonction télémétrie (no-op si TELEMETRY_URL vide) ───────────────────────
_send_telem() {
    [[ -z "$TELEMETRY_URL" ]] && return 0
    curl -s -o /dev/null --max-time 5 --retry 1 \
        -H "Content-Type: application/json" \
        -d "$1" \
        "${TELEMETRY_URL}" 2>/dev/null || true
}

# ── Validation mot de passe ─────────────────────────────────────────────────
validate_password() {
    local pass="$1" label="${2:-Mot de passe}"
    [[ -z "$pass" ]] && { echo "  ✗ $label : ne peut pas être vide"; return 1; }
    [[ ${#pass} -lt 8 ]] && echo -e "  ${YELLOW}ℹ${NC} $label : moins de 8 caractères — FreePBX peut le refuser selon sa politique"
    echo "$pass" | grep -q '[A-Z]' || echo -e "  ${YELLOW}ℹ${NC} $label : sans majuscule — recommandé pour la résistance aux attaques"
    echo "$pass" | grep -q '[0-9]' || echo -e "  ${YELLOW}ℹ${NC} $label : sans chiffre — recommandé"
    echo "$pass" | grep -qP '[^A-Za-z0-9]' || echo -e "  ${YELLOW}ℹ${NC} $label : sans caractère spécial — recommandé"
    return 0
}

_read_star_input() {
    # Saisie masquée avec affichage d'étoiles — gère backspace
    # stty sane avant chaque appel : évite que le mode -s se bloque après un mauvais doublon
    local varname="$1" prompt="$2" password="" char
    stty sane 2>/dev/null || true
    printf "%s : " "$prompt"
    while IFS= read -r -s -n1 char; do
        case "$char" in
            ""|$'\n') break ;;
            $'\177'|$'\b')
                if [[ ${#password} -gt 0 ]]; then
                    password="${password%?}"; printf '\b \b'
                fi ;;
            *) password+="$char"; printf '*' ;;
        esac
    done
    printf '\n'
    printf -v "$varname" '%s' "$password"
}

read_password() {
    local varname="$1" label="$2" confirm="${3:-1}" pass pass2
    local _lbl="${label#"${label%%[! ]*}"}"  # label sans espaces de tête pour le prompt confirmation
    while true; do
        _read_star_input pass "$label"
        [[ -z "$pass" ]] && { echo "  Installation annulée."; exit 0; }
        [[ "$pass" == "q" ]] && return 2  # q = marche arrière (capté par l'appelant)
        validate_password "$pass" "$label"
        if [[ $confirm -eq 1 ]]; then
            _read_star_input pass2 "  Confirmer $_lbl"
            if [[ "$pass" != "$pass2" ]]; then
                echo "  ✗ Mots de passe différents — saisissez à nouveau"
                continue
            fi
        fi
        printf -v "$varname" '%s' "$pass"
        break
    done
}

read_ext_password() {
    local varname="$1" ext="$2" pass
    while true; do
        _read_star_input pass "  Mot de passe du poste $ext"
        if [[ -z "$pass" ]]; then
            # head -c 512 ferme stdin de tr proprement — évite SIGPIPE avec set -o pipefail
            pass=$(head -c 512 /dev/urandom | tr -dc 'A-Za-z0-9!@#%^&*-_' | cut -c1-20)
            echo "  → Généré : $pass"
            printf -v "$varname" '%s' "$pass"
            break
        fi
        validate_password "$pass" "Extension $ext" && printf -v "$varname" '%s' "$pass" && break
    done
}

# ════════════════════════════════════════════════════════════════════════════
# WIZARD — Saisie paramètres (V1.9 CRA)
# ════════════════════════════════════════════════════════════════════════════
while true; do
MANAGEMENT_IP=""
echo ""
echo "╔══════════════════════════════════════════╗"
echo "║  FreePBX Factory V1.9 CRA — Installateur ║"
echo "╚══════════════════════════════════════════╝"
echo ""

# Windows Terminal envoie une réponse ESC[>0;10;1c (Secondary Device Attributes)
# au démarrage de bash — elle atterrit dans stdin et pollue le premier read.
# On draine stdin avant d'entrer dans le wizard.
while IFS= read -r -t 0.1 -n 512 _da_discard 2>/dev/null; do :; done || true

info "  Navigation : q = recommencer depuis le début  |  Entrée vide = annuler"
echo ""

# ── Axe 1 : Compte admin GUI ─────────────────────────────────────────────────
info "▶ 1/4 — Compte administrateur FreePBX"
echo ""
info "  Ce compte permet d'accéder à l'interface de configuration FreePBX."
info "  Choisissez un identifiant et un mot de passe robustes : ils ne peuvent"
info "  pas être récupérés automatiquement après le déploiement."
info "  Laissez le champ vide et appuyez sur Entrée pour annuler l'installation."
info "  Saisissez q pour recommencer depuis le début du wizard."
echo ""
# FACTORY_TEST_ADMIN / FACTORY_TEST_PASS : bypass test-only (jamais en prod)
if [[ -n "${FACTORY_TEST_ADMIN:-}" && -n "${FACTORY_TEST_PASS:-}" ]]; then
    ADMIN_USERNAME="$FACTORY_TEST_ADMIN"
    ADMIN_PASSWORD="$FACTORY_TEST_PASS"
    echo "  ✓ Compte administrateur (mode test) : $ADMIN_USERNAME"
    echo ""
else
RESERVED_LOGINS="admin root administrator freepbx asterisk"
while true; do
    read -rp "  Identifiant de connexion FreePBX : " ADMIN_USERNAME
    [[ -z "$ADMIN_USERNAME" ]] && { echo "  Installation annulée."; exit 0; }
    [[ "${ADMIN_USERNAME,,}" == "q" ]] && { echo "  Retour au début du wizard."; continue 2; }
    case "$ADMIN_USERNAME" in
        *"'"*|*'"'*|*";"*|*"<"*|*">"*|*"&"*|*'`'*)
            echo "  ✗ Caractères interdits dans l'identifiant — saisissez à nouveau"; continue ;;
    esac
    ADMIN_LOWER="${ADMIN_USERNAME,,}"
    IS_RESERVED=0
    for r in $RESERVED_LOGINS; do [[ "$ADMIN_LOWER" == "$r" ]] && IS_RESERVED=1 && break; done
    [[ ${#ADMIN_USERNAME} -lt 5 ]] && echo -e "  ${YELLOW}ℹ${NC} Identifiant court — FreePBX requiert généralement au moins 5 caractères"
    [[ $IS_RESERVED -eq 1 ]] && echo -e "  ${YELLOW}ℹ${NC} '$ADMIN_USERNAME' est un identifiant réservé — FreePBX peut le refuser"
    echo "$ADMIN_USERNAME" | grep -qP '^[A-Za-z0-9._-]+$' || echo -e "  ${YELLOW}ℹ${NC} Identifiant avec caractères inhabituels — recommandé : lettres, chiffres, . - _"
    info "  (Pour changer l'identifiant : saisissez uniquement q puis Entrée au prompt suivant)"
    _rpret=0
    read_password ADMIN_PASSWORD "  Mot de passe FreePBX" || _rpret=$?
    [[ $_rpret -eq 2 ]] && { echo "  Retour à la saisie de l'identifiant."; echo ""; continue; }
    break
done
echo "  ✓ Compte administrateur validé"
echo ""
fi  # fin bypass test

SSH_ENABLED="oui"  # SSH actif — port aléatoire + clé OVHcloud choisie à la réinstallation
echo ""

# ── Axe 2 + 3 : Kit starter + Trunk SIP ─────────────────────────────────────
info "▶ 2/4 — Postes téléphoniques et ligne opérateur (optionnels)"
echo ""
info "  Les deux options ci-dessous sont désactivées par défaut."
info "  Elles peuvent aussi être configurées manuellement dans FreePBX après le déploiement."
echo ""
KIT_STARTER="non"
EXT1_NUMBER="" EXT1_NAME="Poste 1"  EXT1_PASS=""
EXT2_NUMBER="" EXT2_NAME="Poste 2"  EXT2_PASS=""
EXT3_NUMBER="" EXT3_NAME="Poste 3"  EXT3_PASS=""

if [[ -n "$KIT_STARTER_ARG" ]]; then
    # Pré-sélection wizard — pas de question interactive
    [[ "${KIT_STARTER_ARG,,}" == "oui" ]] && KIT_STARTER="oui"
    echo "  Kit starter : $KIT_STARTER (pré-sélectionné par le wizard)"
    KIT_RESP="${KIT_STARTER_ARG,,}"
    [[ "$KIT_STARTER" == "oui" ]] && KIT_RESP="o" || KIT_RESP="n"
else
    info "  Kit de démarrage : 3 postes SIP préconfigurés (Poste 1 / Poste 2 / Poste 3)"
    info "  avec des numéros à 5 chiffres attribués automatiquement."
    info "  [Entrée] = non (désactivé)"
    read -rp "  Créer 3 postes de démonstration ? [o/N/q] : " KIT_RESP
    if [[ "${KIT_RESP,,}" == "q" ]]; then echo "  Retour au début du wizard."; continue; fi
fi

if [[ "${KIT_RESP,,}" == "o" ]]; then
    KIT_STARTER="oui"
    echo ""
    EXT_BASE=$(shuf -i 20001-89997 -n 1)
    EXT1_NUMBER=$EXT_BASE
    EXT2_NUMBER=$(( EXT_BASE + 1 ))
    EXT3_NUMBER=$(( EXT_BASE + 2 ))
    echo "  Numéros attribués : $EXT1_NUMBER / $EXT2_NUMBER / $EXT3_NUMBER"
    echo ""
    for i in 1 2 3; do
        varname="EXT${i}_NAME"; varpass="EXT${i}_PASS"; extnum="EXT${i}_NUMBER"
        default_name="${!varname}"
        if [[ -n "${FACTORY_TEST_ADMIN:-}" ]]; then
            local_pass=$(head -c 512 /dev/urandom | tr -dc 'A-Za-z0-9!@#%^*-_' | cut -c1-20)
            printf -v "$varpass" '%s' "$local_pass"
            echo "  Poste $i : ${!varname} — mot de passe auto-généré (mode test)"
        else
            info "  [Entrée] = génération automatique sécurisée pour le mot de passe  |  q = recommencer"
            read -rp "  Nom du poste $i [${default_name}] : " name
            if [[ "${name,,}" == "q" ]]; then
                echo "  Retour au début du wizard."; continue 2
            elif [[ -n "$name" ]]; then
                printf -v "$varname" '%s' "$name"
            else
                echo "  → ${default_name}"
            fi
            read_ext_password "$varpass" "${!extnum}"
        fi
    done
    echo "  ✓ Postes configurés"
fi
echo ""

TRUNK_ENABLED="non"
TRUNK_REGISTRAR="" TRUNK_USERNAME="" TRUNK_PASSWORD=""
EXTRA_IGNOREIP=""

if [[ -n "$TRUNK_ENABLED_ARG" ]]; then
    # Pré-sélection wizard — pas de question interactive
    if [[ "${TRUNK_ENABLED_ARG,,}" == "oui" ]]; then
        TRUNK_ENABLED="oui"
        TRUNK_REGISTRAR="$TRUNK_REGISTRAR_ARG"
        TRUNK_USERNAME="$TRUNK_USERNAME_ARG"
        echo "  Ligne opérateur : oui (pré-sélectionné par le wizard)"
        [[ -n "$TRUNK_REGISTRAR" ]] && echo "  Serveur SIP : $TRUNK_REGISTRAR"
        [[ -n "$TRUNK_USERNAME"  ]] && echo "  Identifiant : $TRUNK_USERNAME"
        if [[ -n "${FACTORY_TEST_TRUNK_PASS:-}" ]]; then
            TRUNK_PASSWORD="$FACTORY_TEST_TRUNK_PASS"
            echo "  ✓ Mot de passe SIP (mode test)"
        else
            read_password TRUNK_PASSWORD "  Mot de passe SIP" 0
        fi
        echo "  ✓ Ligne opérateur configurée : $TRUNK_REGISTRAR"
        _trunk_ip=$(timeout 3 getent hosts "$TRUNK_REGISTRAR" 2>/dev/null | awk '{print $1}' | head -1)
        if [[ -n "$_trunk_ip" ]]; then
            EXTRA_IGNOREIP="$_trunk_ip"
            echo "  → IP opérateur résolue : $EXTRA_IGNOREIP (autorisée dans fail2ban)"
        else
            read -rp "  IP de l'opérateur SIP à autoriser (optionnel) : " EXTRA_IGNOREIP
            [[ -n "$EXTRA_IGNOREIP" ]] && echo "  → Autorisée : $EXTRA_IGNOREIP"
        fi
    else
        echo "  Ligne opérateur : non (pré-sélectionné par le wizard)"
    fi
else
    info "  Ligne opérateur SIP : connecte FreePBX à votre opérateur téléphonique pour"
    info "  passer et recevoir des appels. Préparez :"
    info "    - l'adresse du serveur SIP de votre opérateur (ex: siptrunk.ovh.net)"
    info "    - votre identifiant SIP (numéro ou login opérateur)"
    info "    - votre mot de passe SIP (différent du mot de passe espace client OVHcloud)"
    info "  [Entrée] = non (désactivé)"
    read -rp "  Connecter une ligne opérateur SIP ? [o/N/q] : " TRUNK_RESP
    if [[ "${TRUNK_RESP,,}" == "q" ]]; then echo "  Retour au début du wizard."; continue; fi
    if [[ "${TRUNK_RESP,,}" == "o" ]]; then
        TRUNK_ENABLED="oui"
        read -rp "  Serveur SIP opérateur (ex: siptrunk.ovh.net), vide pour ignorer (q = recommencer) : " TRUNK_REGISTRAR
        [[ "${TRUNK_REGISTRAR,,}" == "q" ]] && { echo "  Retour au début du wizard."; continue; }
        if [[ -z "$TRUNK_REGISTRAR" ]]; then
            TRUNK_ENABLED="non"; echo "  → Ligne opérateur ignorée"
        else
            [[ "$TRUNK_REGISTRAR" =~ \. ]] || echo -e "  ${YELLOW}ℹ${NC} Format inhabituel — vérifiez l'adresse du serveur SIP de votre opérateur"
            read -rp "  Identifiant SIP (numéro ou login opérateur) (q = recommencer) : " TRUNK_USERNAME
            [[ "${TRUNK_USERNAME,,}" == "q" ]] && { echo "  Retour au début du wizard."; continue; }
            [[ -z "$TRUNK_USERNAME" ]] && echo -e "  ${YELLOW}ℹ${NC} Identifiant vide — la registration SIP risque d'échouer"
            _rpret=0
            read_password TRUNK_PASSWORD "  Mot de passe SIP" 0 || _rpret=$?
            [[ $_rpret -eq 2 ]] && { echo "  Retour au début du wizard."; continue; }
            echo "  ✓ Ligne opérateur configurée : $TRUNK_REGISTRAR"
            _trunk_ip=$(timeout 3 getent hosts "$TRUNK_REGISTRAR" 2>/dev/null | awk '{print $1}' | head -1)
            if [[ -n "$_trunk_ip" ]]; then
                EXTRA_IGNOREIP="$_trunk_ip"
                echo "  → IP opérateur résolue : $EXTRA_IGNOREIP (autorisée dans fail2ban)"
            else
                read -rp "  IP de l'opérateur SIP à autoriser (optionnel, q = recommencer) : " EXTRA_IGNOREIP
                [[ "${EXTRA_IGNOREIP,,}" == "q" ]] && { EXTRA_IGNOREIP=""; echo "  Retour au début du wizard."; continue; }
                [[ -n "$EXTRA_IGNOREIP" ]] && echo "  → Autorisée : $EXTRA_IGNOREIP"
            fi
        fi
    else
        echo "  → Ligne opérateur désactivée"
    fi
fi
echo ""

# Détection anticipée de l'IP du VPS (nécessaire pour le wizard TLS)
VPS_IP=$(ip -4 route get 1.1.1.1 2>/dev/null | grep -oP 'src \K\S+' | head -1)
[[ -z "$VPS_IP" ]] && VPS_IP=$(hostname -I 2>/dev/null | awk '{print $1}')
[[ -z "$VPS_IP" ]] && VPS_IP="<IP_VPS>"

# ── TLS HTTPS ─────────────────────────────────────────────────────────────────
info "▶ 3/4 — Accès HTTPS à l'interface d'administration (optionnel)"
info ""
info "  Sans nom de domaine : l'interface FreePBX reste inaccessible à la fin de"
info "  l'installation (Apache arrêté par sécurité). Elle peut être démarrée"
info "  ponctuellement en HTTP si nécessaire, sous votre responsabilité."
info ""
info "  Avec un sous-domaine : le script configure automatiquement un certificat"
info "  HTTPS (Let's Encrypt). L'enregistrement DNS de type A doit pointer vers"
info "  l'adresse IP de ce serveur AVANT de lancer l'installation."
info ""
info "  IP de ce serveur     : $VPS_IP"
info "  Enregistrement requis : A  <votre-domaine>  →  $VPS_IP"
info "  Pour vérifier depuis votre poste : nslookup <votre-domaine>"
info ""
info "  [Entrée] = ignorer (interface web désactivée en fin d'installation)"
TLS_DOMAIN=""
if [[ -n "$TLS_DOMAIN_ARG" ]]; then
    TLS_DOMAIN="$TLS_DOMAIN_ARG"
    echo "  ✓ Sous-domaine : $TLS_DOMAIN (pré-sélectionné par le wizard)"
    echo "  ℹ  Enregistrement attendu : A  $TLS_DOMAIN  →  $VPS_IP"
else
    read -rp "  Sous-domaine HTTPS (ex: pbx.mon-entreprise.fr), Entrée pour ignorer, q pour recommencer : " TLS_DOMAIN
    if [[ "${TLS_DOMAIN,,}" == "q" ]]; then echo "  Retour au début du wizard."; continue; fi
    if [[ -n "$TLS_DOMAIN" ]]; then
        echo "  ✓ Sous-domaine : $TLS_DOMAIN"
        echo "  ℹ  Enregistrement attendu : A  $TLS_DOMAIN  →  $VPS_IP"
        echo "  ℹ  Pour vérifier depuis votre poste : nslookup $TLS_DOMAIN"
    else
        echo "  → Interface web désactivée en fin d'installation"
    fi
fi
echo ""

# ── Récapitulatif ─────────────────────────────────────────────────────────────
info "▶ 4/4 — Récapitulatif"
# Passage par variable d'environnement — évite la casse si le mot de passe contient '
ADMIN_SHA1=$(env _P="$ADMIN_PASSWORD" python3 -c "import hashlib,os; print(hashlib.sha1(os.environ['_P'].encode()).hexdigest())")
ADMIN_SHA512=$(env _P="$ADMIN_PASSWORD" python3 -c "import hashlib,os; print(hashlib.sha512(os.environ['_P'].encode()).hexdigest())")
# Management IP = IP du poste déployeur (détectée par launch.py/launch.sh)
if [[ -n "$MANAGEMENT_IP_ARG" ]]; then
    MANAGEMENT_IP="$MANAGEMENT_IP_ARG"
    info "  IP de gestion détectée par le lanceur : $MANAGEMENT_IP"
    read -rp "  Confirmer ? [O/n/q] : " _CONFIRM_MGT
    if [[ "${_CONFIRM_MGT,,}" == "q" ]]; then echo "  Retour au début du wizard."; continue; fi
    if [[ "${_CONFIRM_MGT,,}" == "n" ]]; then
        MANAGEMENT_IP=""
        MANAGEMENT_IP_ARG=""
    fi
fi
if [[ -z "$MANAGEMENT_IP" ]]; then
    # Détection automatique de l'IP source de la connexion SSH active
    _DETECTED_IP=""
    if [[ -n "${SSH_CLIENT:-}" ]]; then
        _DETECTED_IP="${SSH_CLIENT%% *}"
    elif [[ -n "${SSH_CONNECTION:-}" ]]; then
        _DETECTED_IP="${SSH_CONNECTION%% *}"
    fi
    if [[ -z "$_DETECTED_IP" ]]; then
        _DETECTED_IP=$(who am i 2>/dev/null | grep -oP '\(\K[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+' | head -1)
    fi
    if [[ -z "$_DETECTED_IP" ]]; then
        _DETECTED_IP=$(ss -tn state established 'sport = :22' 2>/dev/null \
            | awk 'NR>1 {split($5,a,":"); print a[1]}' | head -1)
    fi

    echo ""
    if [[ -n "$_DETECTED_IP" ]]; then
        info "  IP détectée : $_DETECTED_IP (adresse source de votre connexion SSH)"
        info "  Un sous-réseau /24 sera autorisé : ${_DETECTED_IP%.*}.0/24"
        info "  (absorbe les variations d'IP dynamique au sein de votre connexion)"
        read -rp "  Confirmer ? [O/n/q] : " _CONFIRM
        if [[ "${_CONFIRM,,}" == "q" ]]; then echo "  Retour au début du wizard."; continue; fi
        if [[ "${_CONFIRM,,}" != "n" ]]; then
            MANAGEMENT_IP="${_DETECTED_IP%.*}.0/24"
            echo "  → IP de gestion : $MANAGEMENT_IP"
        else
            _DETECTED_IP=""
        fi
    fi

    if [[ -z "$_DETECTED_IP" ]]; then
        info "  Saisissez l'IP publique de VOTRE connexion internet — celle vue par ce"
        info "  serveur quand vous initiez une connexion SSH. Pas l'IP du serveur."
        info "  Pour la connaître :"
        info "    Navigateur : https://ifconfig.ovh  ou  https://api.ipify.org"
        info "    Terminal   : curl ifconfig.me  (sur votre poste, pas ce serveur)"
        info "  Laisser vide = accès SSH non restreint (non recommandé)"
        while true; do
            read -rp "  Votre IP publique (ex: A.B.C.D) (q = recommencer) : " _MGMT_RAW
            [[ "${_MGMT_RAW,,}" == "q" ]] && { echo "  Retour au début du wizard."; continue 2; }
            if [[ -z "$_MGMT_RAW" ]]; then
                MANAGEMENT_IP="0.0.0.0/0"
                warn "  ⚠ Accès SSH non restreint"
                break
            elif echo "$_MGMT_RAW" | grep -qP '^\d+\.\d+\.\d+\.\d+$'; then
                MANAGEMENT_IP=$(echo "$_MGMT_RAW" | sed 's/\.[0-9]*$/.0\/24/')
                echo "  → Sous-réseau : $MANAGEMENT_IP"; break
            elif echo "$_MGMT_RAW" | grep -qP '^\d+\.\d+\.\d+\.\d+/\d+$'; then
                MANAGEMENT_IP="$_MGMT_RAW"; break
            else
                echo "  ✗ Format invalide — ex: A.B.C.D ou A.B.C.0/24"
            fi
        done
    fi
fi
TRUNK_NAME=""
[[ -n "$TRUNK_REGISTRAR" ]] && TRUNK_NAME="trunk-$(echo "$TRUNK_REGISTRAR" | awk -F'.' '{print $(NF-1)}')"
TRUNK_CALLERID="$TRUNK_USERNAME"
SSH_PORT=$(shuf -i 10000-49151 -n 1)
# Sauvegarde immédiate du port — accessible même si la session tmux se ferme
echo "$SSH_PORT" > /root/freepbx-factory-ssh-port.txt
chmod 600 /root/freepbx-factory-ssh-port.txt
# Titre tmux mis à jour immédiatement — visible même après déconnexion SSH
tmux rename-window "FreePBX Factory | SSH: ${SSH_PORT}" 2>/dev/null || true

echo "╔══════════════════════════════════════════╗"
echo "║   Récapitulatif avant déploiement        ║"
echo "╠══════════════════════════════════════════╣"
printf "║ Administrateur  : %-22s ║\n" "$ADMIN_USERNAME"
printf "║ IP de gestion   : %-22s ║\n" "$MANAGEMENT_IP"
printf "║ Accès SSH       : %-22s ║\n" "$SSH_ENABLED"
printf "║ Postes démo     : %-22s ║\n" "$KIT_STARTER"
[[ "$KIT_STARTER" == "oui" ]] && printf "║ Numéros         : %-22s ║\n" "$EXT1_NUMBER/$EXT2_NUMBER/$EXT3_NUMBER"
printf "║ Ligne opérateur : %-22s ║\n" "${TRUNK_REGISTRAR:-non}"
printf "║ HTTPS           : %-22s ║\n" "${TLS_DOMAIN:-non activé}"
echo "╚══════════════════════════════════════════╝"
echo ""
echo -e "${YELLOW}╔══════════════════════════════════════════╗${NC}"
echo -e "${YELLOW}║     NOTEZ CE PORT SSH MAINTENANT         ║${NC}"
echo -e "${YELLOW}╠══════════════════════════════════════════╣${NC}"
printf "${YELLOW}║     PORT SSH : %-26s${YELLOW}║${NC}\n" "$SSH_PORT"
echo -e "${YELLOW}║                                          ║${NC}"
printf "${YELLOW}║  ssh -p %-33s${YELLOW}║${NC}\n" "$SSH_PORT debian@<IP_DU_VPS>"
echo -e "${YELLOW}║  puis : sudo tmux attach -t factory      ║${NC}"
echo -e "${YELLOW}╚══════════════════════════════════════════╝${NC}"
echo ""

log "====== PARAMÈTRES V1.9 CRA ======"
log "admin_username  : $ADMIN_USERNAME"
log "management_ip   : $MANAGEMENT_IP"
log "ssh_port        : $SSH_PORT"
log "ssh_enabled     : $SSH_ENABLED"
log "kit_starter     : $KIT_STARTER"
[[ "$KIT_STARTER" == "oui" ]] && log "extensions      : $EXT1_NUMBER / $EXT2_NUMBER / $EXT3_NUMBER"
log "trunk_enabled   : $TRUNK_ENABLED"
[[ "$TRUNK_ENABLED" == "oui" ]] && log "trunk_registrar : $TRUNK_REGISTRAR" && log "trunk_username  : $TRUNK_USERNAME"
[[ -n "$EXTRA_IGNOREIP" ]] && log "extra_ignoreip  : $EXTRA_IGNOREIP"
log "tls_domain      : ${TLS_DOMAIN:-non activé}"
log "journal         : $SESSION_LOG"

echo ""
info "  L'installation va démarrer et durera entre 20 et 40 minutes."
info "  Votre connexion SSH sera coupée lors du changement de port (phase sécurité)."
info "  Le script continue automatiquement. Pour reprendre la session :"
info "    ssh -p $SSH_PORT debian@<ADRESSE_IP_SERVEUR>"
info "    sudo tmux attach -t factory"
info ""
info "  [Entrée]/O = lancer  |  n = annuler  |  r = recommencer depuis le début"
stty sane 2>/dev/null || true
read -rp "  Lancer le déploiement ? [O/n/r] : " CONFIRM
if [[ "${CONFIRM,,}" == "r" ]]; then
    echo ""; echo "  --- Retour au début du wizard ---"; echo ""; continue
elif [[ -n "${CONFIRM}" && "${CONFIRM,,}" != "o" ]]; then
    echo "  Annulé."; exit 0
fi
break
done  # fin wizard

INSTALL_START=$(date +%s)

# ── Ping démarrage anonyme (automatique, silencieux) ────────────────────────
_send_telem "{\"event\":\"deploy_start\",\"version\":\"${SCRIPT_VERSION}\",\"os\":\"${_OS_ID}\",\"id\":\"${DEPLOY_ID}\"}"

# ════════════════════════════════════════════════════════════════════════════
# PHASE 00 — Cleanup
# ════════════════════════════════════════════════════════════════════════════
log ""
log "=== PHASE 00 — Cleanup ==="
run_phase "$PHASES_DIR/00_cleanup.sh"
ok "00_cleanup"

# ════════════════════════════════════════════════════════════════════════════
# PHASE 00b — SSH hardening
# Note : sshd restart coupe la connexion SSH cliente — ce script continue
# car il tourne dans tmux (processus local, pas dans un pipe SSH).
# ════════════════════════════════════════════════════════════════════════════
log ""
log "=== PHASE 00b — Hardening SSH (port → $SSH_PORT) ==="
echo ""
echo -e "${YELLOW}══════════════════════════════════════════════════${NC}"
echo -e "${YELLOW}  VOTRE CONNEXION SSH VA ÊTRE COUPÉE              ${NC}"
echo -e "${YELLOW}  Le script continue automatiquement dans tmux.   ${NC}"
echo -e "${YELLOW}                                                   ${NC}"
echo -e "${YELLOW}  Nouveau port SSH : ${SSH_PORT}                  ${NC}"
echo -e "${YELLOW}  Reconnexion :                                    ${NC}"
echo -e "${YELLOW}    ssh -p ${SSH_PORT} debian@<IP_DU_VPS>         ${NC}"
echo -e "${YELLOW}    sudo tmux attach -t factory                     ${NC}"
echo -e "${YELLOW}══════════════════════════════════════════════════${NC}"
echo ""
read -rp "  Port $SSH_PORT noté ? Appuyez sur Entrée pour continuer... "
run_phase "$PHASES_DIR/00_hardening.sh" "$MANAGEMENT_IP" "$SSH_PORT"
ok "00_hardening — SSH actif sur port $SSH_PORT"

# ════════════════════════════════════════════════════════════════════════════
# PHASE 01 — Installation FreePBX (~20-40 min)
# ════════════════════════════════════════════════════════════════════════════
log ""
log "=== PHASE 01 — Installation FreePBX (20-40 min) ==="
echo ""
echo -e "${CYAN}  Cette phase peut prendre 20 à 40 minutes. Certains messages${NC}"
echo -e "${CYAN}  peuvent rester affichés plusieurs minutes sans évoluer, c'est normal.${NC}"
echo -e "${CYAN}  Ne fermez pas cette fenêtre et ne coupez pas la connexion SSH.${NC}"
echo ""
run_phase "$PHASES_DIR/01_install.sh"
ok "01_install"

# ════════════════════════════════════════════════════════════════════════════
# PHASE 02 — Asterisk
# ════════════════════════════════════════════════════════════════════════════
log ""
log "=== PHASE 02 — Asterisk + modules ==="
run_phase "$PHASES_DIR/02_asterisk.sh"
ok "02_asterisk"

# ════════════════════════════════════════════════════════════════════════════
# PHASE 03 — Firewall (réinstalle UFW après suppression par FreePBX — E15)
# ════════════════════════════════════════════════════════════════════════════
log ""
log "=== PHASE 03 — Firewall ==="
run_phase "$PHASES_DIR/03_firewall.sh" "$MANAGEMENT_IP" "$SSH_PORT"
ok "03_firewall"

# ════════════════════════════════════════════════════════════════════════════
# PHASE 04 — fail2ban
# ════════════════════════════════════════════════════════════════════════════
log ""
log "=== PHASE 04 — fail2ban ==="
run_phase "$PHASES_DIR/04_fail2ban.sh" "$MANAGEMENT_IP" "$SSH_PORT" "${EXTRA_IGNOREIP:-}"
ok "04_fail2ban"

# ════════════════════════════════════════════════════════════════════════════
# PHASE 06 — Configuration FreePBX (endpoint + admin + extensions + trunk)
# ════════════════════════════════════════════════════════════════════════════
log ""
log "=== PHASE 06 — Configuration FreePBX ==="
run_phase "$PHASES_DIR/06_post_restore.sh" \
    "$ADMIN_USERNAME" "$ADMIN_SHA1" "$ADMIN_SHA512" \
    "$TRUNK_REGISTRAR" "$TRUNK_USERNAME" "$TRUNK_PASSWORD" \
    "$TRUNK_NAME" "$TRUNK_CALLERID" \
    "$EXT1_NUMBER" "$EXT1_NAME" "$EXT1_PASS" \
    "$EXT2_NUMBER" "$EXT2_NAME" "$EXT2_PASS" \
    "$EXT3_NUMBER" "$EXT3_NAME" "$EXT3_PASS"
ok "06_post_restore"

# ════════════════════════════════════════════════════════════════════════════
# PHASE 09 — Apache hardening
# ════════════════════════════════════════════════════════════════════════════
log ""
log "=== PHASE 09 — Apache hardening ==="
run_phase "$PHASES_DIR/09_apache_hardening.sh"
ok "09_apache_hardening"

# ════════════════════════════════════════════════════════════════════════════
# PHASE 10 — MariaDB hardening
# ════════════════════════════════════════════════════════════════════════════
log ""
log "=== PHASE 10 — MariaDB hardening ==="
run_phase "$PHASES_DIR/10_mariadb_hardening.sh"
ok "10_mariadb_hardening"

# ════════════════════════════════════════════════════════════════════════════
# PHASE 11 — Services hardening
# ════════════════════════════════════════════════════════════════════════════
log ""
log "=== PHASE 11 — Services hardening ==="
run_phase "$PHASES_DIR/11_services_hardening.sh"
ok "11_services_hardening"

# ════════════════════════════════════════════════════════════════════════════
# PHASE 14 — auditd (NIS2 Art. 21b — journalisation actions privilégiées)
# ════════════════════════════════════════════════════════════════════════════
log ""
log "=== PHASE 14 — auditd ==="
run_phase "$PHASES_DIR/14_auditd.sh"
ok "14_auditd"

# ════════════════════════════════════════════════════════════════════════════
# PHASE 12 — SBOM CycloneDX 1.4 (CRA Annex II + NIS2 Art. 21)
# ════════════════════════════════════════════════════════════════════════════
log ""
log "=== PHASE 12 — SBOM CycloneDX ==="
run_phase "$PHASES_DIR/12_sbom.sh"
ok "12_sbom"

# ════════════════════════════════════════════════════════════════════════════
# PHASE 13 — Contrôles conformité post-déploiement (CRA + NIS2)
# ════════════════════════════════════════════════════════════════════════════
log ""
log "=== PHASE 13 — Contrôles conformité CRA + NIS2 ==="
run_phase "$PHASES_DIR/13_post_checks.sh" "$SSH_PORT"
ok "13_post_checks"

# ════════════════════════════════════════════════════════════════════════════
# Vérification locale de disponibilité GUI (Apache temporairement actif)
# ════════════════════════════════════════════════════════════════════════════
log ""
log "=== Vérification locale de disponibilité GUI ==="
systemctl start apache2 2>/dev/null || true
sleep 2
_GUI_CODE=$(curl -s -o /dev/null -w "%{http_code}" -X POST http://localhost/admin/index.php \
    --data-urlencode "username=$ADMIN_USERNAME" \
    --data-urlencode "password=$ADMIN_PASSWORD" 2>/dev/null || echo "000")
if [[ "$_GUI_CODE" =~ ^(200|302)$ ]]; then
    ok "Disponibilité GUI : Apache répond localement (HTTP $_GUI_CODE) — authentification à vérifier depuis votre navigateur"
else
    warn "Disponibilité GUI : Apache ne répond pas (HTTP $_GUI_CODE) — vérifier manuellement après activation TLS"
fi

# ════════════════════════════════════════════════════════════════════════════
# PHASE 15 — TLS/HTTPS (Let's Encrypt + Apache)
# Si TLS_DOMAIN fourni : certbot + Apache HTTPS actif
# Si vide             : Apache arrêté (GUI inaccessible jusqu'à config TLS)
# ════════════════════════════════════════════════════════════════════════════
log ""
log "=== PHASE 15 — TLS/HTTPS ==="

# ── Vérification DNS avant certbot ──────────────────────────────────────────
if [[ -n "$TLS_DOMAIN" ]]; then
    log "Vérification DNS : $TLS_DOMAIN"
    _DNS_IP=$(timeout 3 getent hosts "$TLS_DOMAIN" 2>/dev/null | awk '{print $1}' | head -1)
    if [[ -z "$_DNS_IP" ]]; then
        warn "DNS : $TLS_DOMAIN ne se résout pas."
        warn "  IP de ce serveur     : $VPS_IP"
        warn "  Enregistrement requis : A  $TLS_DOMAIN  →  $VPS_IP"
        warn "  Let's Encrypt va échouer si le DNS n'est pas propagé."
        if [[ -n "$TLS_DOMAIN_ARG" ]]; then
            warn "  Mode non interactif : l'installation continue malgré l'avertissement DNS."
        else
            read -t 60 -rp "  Continuer avec TLS ? Saisissez 'oui' pour confirmer (60s, Entrée = ignorer TLS) : " _DNS_CONFIRM || _DNS_CONFIRM="non"
            if [[ "${_DNS_CONFIRM,,}" != "oui" ]]; then
                warn "  TLS ignoré — l'installation continue sans HTTPS."
                TLS_DOMAIN=""
            fi
        fi
    elif [[ "$_DNS_IP" != "$VPS_IP" ]]; then
        warn "DNS : $TLS_DOMAIN pointe vers $_DNS_IP, ce serveur est $VPS_IP."
        warn "  Let's Encrypt échouera si le domaine ne pointe pas vers ce serveur."
        warn "  (Un CDN ou proxy peut légitimement différer — vérifiez si c'est votre cas.)"
        if [[ -n "$TLS_DOMAIN_ARG" ]]; then
            warn "  Mode non interactif : l'installation continue malgré l'avertissement DNS."
        else
            read -t 60 -rp "  Continuer avec TLS ? Saisissez 'oui' pour confirmer (60s, Entrée = ignorer TLS) : " _DNS_CONFIRM || _DNS_CONFIRM="non"
            if [[ "${_DNS_CONFIRM,,}" != "oui" ]]; then
                warn "  TLS ignoré — l'installation continue sans HTTPS."
                TLS_DOMAIN=""
            fi
        fi
    else
        ok "DNS : $TLS_DOMAIN → $_DNS_IP (correspond à l'IP de ce serveur)"
    fi
fi

export TLS_DOMAIN
run_phase "$PHASES_DIR/15_tls.sh" "$TLS_DOMAIN"
if [[ -n "$TLS_DOMAIN" ]] && systemctl is-active apache2 >/dev/null 2>&1; then
    ok "15_tls — HTTPS actif — https://$TLS_DOMAIN/admin/"
    GUI_URL="https://$TLS_DOMAIN/admin/"
else
    warn "15_tls — Apache arrêté — GUI inaccessible jusqu'à configuration TLS"
    GUI_URL="désactivée (Apache arrêté — HTTPS requis)"
fi

# ════════════════════════════════════════════════════════════════════════════
# POST-CHECK
# ════════════════════════════════════════════════════════════════════════════
log ""
log "=== POST-CHECK ==="
echo -e "${CYAN}--- Asterisk socket ---${NC}"
if [[ ! -e /var/run/asterisk/asterisk.ctl ]]; then
    warn "Socket Asterisk absent (graceful restart post-fwconsole reload) — relance..."
    systemctl restart asterisk
    sleep 8
    [[ -e /var/run/asterisk/asterisk.ctl ]] && ok "Asterisk redémarré" || warn "Socket Asterisk toujours absent — vérifier manuellement"
else
    ok "Asterisk opérationnel"
fi
echo -e "${CYAN}--- Services PM2 ---${NC}"
fwconsole pm2 --list 2>/dev/null || echo "PM2 check — voir fwconsole pm2 --list"
echo -e "${CYAN}--- GUI ---${NC}"
curl -s -o /dev/null -w 'HTTP GUI: %{http_code}\n' http://localhost/admin/ 2>/dev/null || true
echo -e "${CYAN}--- Ports sensibles TCP ---${NC}"
ss -tlnp | grep -E ':1720|:3306' && echo 'ATTENTION port exposé' || echo 'Ports 1720/3306 : fermés OK'
echo -e "${CYAN}--- Ports sensibles UDP ---${NC}"
ss -ulnp | grep -E ':69 |:5353 ' && echo 'ATTENTION port UDP exposé' || echo 'Ports 69/5353 : fermés OK'
echo -e "${CYAN}--- Shell asterisk ---${NC}"
getent passwd asterisk | cut -d: -f7
echo -e "${CYAN}--- fail2ban ---${NC}"
fail2ban-client get ssh-iptables bantime 2>/dev/null || echo "fail2ban : vérifier manuellement"
echo -e "${CYAN}--- UFW ---${NC}"
ufw status | head -10
echo -e "${CYAN}--- Conformité CRA+NIS2 ---${NC}"
if [[ -f /etc/freepbx-factory/compliance-report.json ]]; then
    python3 -c "
import json
with open('/etc/freepbx-factory/compliance-report.json') as f:
    r = json.load(f)
s = r['score']
print(f'  Score : {s[\"percent\"]}% ({s[\"ok\"]}/{s[\"total\"]} contrôles OK)')
warns = [c for c in r['checks'] if c['status'] != 'ok']
if warns:
    for w in warns: print(f'  ⚠  {w[\"name\"]} : {w[\"value\"]}')
else:
    print('  Tous les contrôles OK')
" 2>/dev/null || cat /etc/freepbx-factory/compliance-report.json
else
    warn "Rapport conformité absent — vérifier 13_post_checks.sh"
fi

# ════════════════════════════════════════════════════════════════════════════
# RAPPORT DE LIVRAISON — CRA EU 2024/2847 (traçabilité déploiement)
# ════════════════════════════════════════════════════════════════════════════
REPORT_FILE="/root/freepbx-factory-delivery-report.txt"
DEPLOY_DATE="$(date '+%Y-%m-%d %H:%M:%S')"
_ext_info="désactivé" ; [[ "$KIT_STARTER" == "oui" ]] && _ext_info="$EXT1_NUMBER / $EXT2_NUMBER / $EXT3_NUMBER"

cat > "$REPORT_FILE" << REPORTEOF
═══════════════════════════════════════════════════════════
  RAPPORT DE LIVRAISON — FreePBX Factory V1.9 CRA
  Date       : ${DEPLOY_DATE}
═══════════════════════════════════════════════════════════

ACCÈS
  Admin FreePBX : ${ADMIN_USERNAME}  (mot de passe défini au wizard)
  Port SSH   : ${SSH_PORT}  (clé ED25519 uniquement)
  IP autorisée SSH : ${MANAGEMENT_IP}
  IP VPS     : ${VPS_IP}
  GUI        : ${GUI_URL}
  Reconnexion: ssh -p ${SSH_PORT} debian@${VPS_IP}

OPTIONS DÉPLOYÉES
  Kit starter : ${KIT_STARTER}  (extensions : ${_ext_info})
  Trunk SIP   : ${TRUNK_REGISTRAR:-désactivé}
  HTTPS/TLS   : ${TLS_DOMAIN:-non activé}
  SSH activé  : ${SSH_ENABLED}

COUCHES DE SÉCURITÉ (7 actives)
  [1] Réseau    UFW actif — deny all entrant sauf ports projet
  [2] SSH       Port ${SSH_PORT} — clé uniquement — restreint à ${MANAGEMENT_IP}
  [3] IDS       fail2ban — 7 jails actifs — bantime 86400s
  [4] SIP/VoIP  Modules Asterisk legacy désactivés (ooh323/iax2/stun)
  [5] Web       Apache headers sécurité + ServerTokens Prod + TraceEnable Off
  [6] Base      MariaDB bind=127.0.0.1 — anonymes supprimés
  [7] Services  tftpd-hpa/avahi arrêtés — asterisk shell=nologin

JOURNAL D'INSTALLATION
  ${SESSION_LOG}

RAPPORTS DE CONFORMITÉ
  Rapport CRA+NIS2 : /etc/freepbx-factory/compliance-report.json
  SBOM CycloneDX   : /etc/freepbx-factory/sbom.json

CONFORMITÉ CRA EU 2024/2847
  Axe 1 — Credentials admin : choisis par le client au wizard (non stockés)
  Axe 2 — Kit starter       : ${KIT_STARTER} — extensions optionnelles (5+ chiffres)
  Axe 3 — Trunk SIP         : ${TRUNK_ENABLED} — indépendant du kit starter
  Axe 4 — SSH               : ${SSH_ENABLED} — accès par clé OVHcloud (réinstallation)

═══════════════════════════════════════════════════════════
REPORTEOF

if [[ "$KIT_STARTER" == "oui" ]]; then
    cat >> "$REPORT_FILE" << KIT_REPORT_EOF

KIT STARTER — CONFIGURATION SOFTPHONES
  Serveur SIP : ${VPS_IP}
  Port SIP    : 5060 (UDP / PJSIP)

  Extension ${EXT1_NUMBER} — ${EXT1_NAME}
    Compte SIP   : ${EXT1_NUMBER}
    Mot de passe : ${EXT1_PASS}

  Extension ${EXT2_NUMBER} — ${EXT2_NAME}
    Compte SIP   : ${EXT2_NUMBER}
    Mot de passe : ${EXT2_PASS}

  Extension ${EXT3_NUMBER} — ${EXT3_NAME}
    Compte SIP   : ${EXT3_NUMBER}
    Mot de passe : ${EXT3_PASS}

ACCÈS INTERFACE
  URL admin : ${GUI_URL}
$(if [[ -z "${TLS_DOMAIN}" ]]; then
echo "  Accès HTTP ponctuel (sous votre responsabilité) :"
echo "    Démarrer : sudo systemctl start apache2"
echo "    URL      : http://${VPS_IP}/admin/"
echo "    Arrêter  : sudo systemctl stop apache2"
echo "  Attention : HTTP non sécurisé — à utiliser uniquement pour configuration initiale."
fi)

═══════════════════════════════════════════════════════════
KIT_REPORT_EOF
fi
chmod 600 "$REPORT_FILE"
log "Rapport de livraison : $REPORT_FILE"

# ════════════════════════════════════════════════════════════════════════════
# RÉSUMÉ DÉPLOIEMENT — fichiers générés sur le VPS
# ════════════════════════════════════════════════════════════════════════════
_INSTALL_END=$(date +%s)
_DEPLOY_DUR=$(( (_INSTALL_END - INSTALL_START) / 60 ))
_FPBX_VER=$(fwconsole --version 2>/dev/null | grep -oP '\d+\.\d+\.\d+' | head -1 || echo "17.0.x")
_JAILS_N=$(fail2ban-client status 2>/dev/null | grep -oP 'Number of jails:\s*\K\d+' || echo "7")
_GUI_OK=0; [[ "${_GUI_CODE:-000}" =~ ^(200|302)$ ]] && _GUI_OK=1
_UFW_OK=0; ufw status 2>/dev/null | grep -q "Status: active" && _UFW_OK=1
_TRUNK_STATUS="${TRUNK_ENABLED:-non}"; _TLS_VAL="${TLS_DOMAIN:-}"
_AST_VER=$(asterisk -V 2>/dev/null | grep -oP '\d+\.\d+\.\d+' | head -1 || echo "")
_HOSTNAME=$(hostname 2>/dev/null || echo "")

echo ""
echo -e "${GREEN}══════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}  RÉSUMÉ DU DÉPLOIEMENT                                    ${NC}"
echo -e "${GREEN}══════════════════════════════════════════════════════════${NC}"
echo ""

# ── Accès et options déployées ───────────────────────────────────────────────
echo -e "${CYAN}  ── Accès et options déployées ─────────────────────────────${NC}"
if [[ -f "$REPORT_FILE" ]]; then
    grep -E '^\s+(Admin|IP VPS|Port SSH|Kit|Ligne|HTTPS|SSH activé)' "$REPORT_FILE" 2>/dev/null | head -8 || true
    echo ""
    echo "  → Fiche complète enregistrée : $REPORT_FILE"
else
    echo "  → $REPORT_FILE (généré)"
fi
echo ""

# ── Inventaire des composants installés ──────────────────────────────────────
echo -e "${CYAN}  ── Inventaire des composants installés ────────────────────${NC}"
if [[ -f /etc/freepbx-factory/sbom.json ]]; then
    _SBOM_N=$(python3 -c "import json; d=json.load(open('/etc/freepbx-factory/sbom.json')); print(len(d.get('components',[])))" 2>/dev/null || echo "?")
    echo "  → ${_SBOM_N} composants logiciels répertoriés"
    echo "  → Fichier : /etc/freepbx-factory/sbom.json"
else
    echo "  → /etc/freepbx-factory/sbom.json"
fi
echo ""

# ── Vérifications de sécurité ────────────────────────────────────────────────
echo -e "${CYAN}  ── Vérifications de sécurité ──────────────────────────────${NC}"
if [[ -f /etc/freepbx-factory/compliance-report.json ]]; then
    python3 -c "
import json
with open('/etc/freepbx-factory/compliance-report.json') as f:
    r = json.load(f)
s = r['score']
print(f'  Score : {s[\"percent\"]}% ({s[\"ok\"]}/{s[\"total\"]} contrôles OK)')
warns = [c for c in r['checks'] if c['status'] != 'ok']
for w in warns: print(f'  ⚠  {w[\"name\"]}')
if not warns: print('  Tous les contrôles OK')
" 2>/dev/null || echo "  → /etc/freepbx-factory/compliance-report.json"
else
    echo "  → /etc/freepbx-factory/compliance-report.json"
fi

echo ""
echo -e "${GREEN}══════════════════════════════════════════════════════════${NC}"
echo ""

# Titre tmux final — visible au retour de connexion
tmux rename-window "DÉPLOYÉ ✓ | SSH: ${SSH_PORT}" 2>/dev/null || true

# ════════════════════════════════════════════════════════════════════════════
# KIT STARTER — Vérification GUI + configuration softphones
# ════════════════════════════════════════════════════════════════════════════
if [[ "$KIT_STARTER" == "oui" ]]; then
    echo ""
    echo -e "${YELLOW}══════════════════════════════════════════════════════${NC}"
    echo -e "${YELLOW}   KIT STARTER — VÉRIFICATION & SOFTPHONES${NC}"
    echo -e "${YELLOW}══════════════════════════════════════════════════════${NC}"
    echo ""
    echo -e "  ${CYAN}── 1. ACCÉDER À L'INTERFACE FREEPBX ─────────────────${NC}"
    echo    "     URL   : ${GUI_URL}"
    echo    "     Login : ${ADMIN_USERNAME}"
    if [[ -z "$TLS_DOMAIN" ]]; then
        echo ""
        echo -e "  ${YELLOW}  Interface web désactivée (Apache arrêté par sécurité).${NC}"
        echo -e "  ${YELLOW}  Pour un accès ponctuel sous votre responsabilité :${NC}"
        echo    "     sudo systemctl start apache2"
        echo    "     URL HTTP : http://${VPS_IP}/admin/"
        echo    "     sudo systemctl stop apache2  (arrêter après vérification)"
    fi
    echo    "     Vérifier : Applications → Extensions"
    echo    "     Extensions attendues : ${EXT1_NUMBER} / ${EXT2_NUMBER} / ${EXT3_NUMBER}"
    echo ""
    echo -e "  ${CYAN}── 4. VÉRIFIER LES ENREGISTREMENTS ASTERISK ──────────${NC}"
    echo    "     sudo asterisk -rx 'pjsip show endpoints'"
    echo    "     (statut Avail = softphone enregistré)"
    echo ""
    echo -e "${GREEN}  ── CONFIGURATION SOFTPHONES ──────────────────────────${NC}"
    echo    "  Protocole  : PJSIP"
    echo    "  Serveur SIP: ${VPS_IP}"
    echo    "  Port SIP   : 5060 (UDP)"
    echo    "  Domaine    : ${VPS_IP}"
    echo ""
    echo -e "${GREEN}  Ext ${EXT1_NUMBER} — ${EXT1_NAME}${NC}"
    echo    "    Compte SIP   : ${EXT1_NUMBER}"
    echo    "    Mot de passe : ${EXT1_PASS}"
    echo ""
    echo -e "${GREEN}  Ext ${EXT2_NUMBER} — ${EXT2_NAME}${NC}"
    echo    "    Compte SIP   : ${EXT2_NUMBER}"
    echo    "    Mot de passe : ${EXT2_PASS}"
    echo ""
    echo -e "${GREEN}  Ext ${EXT3_NUMBER} — ${EXT3_NAME}${NC}"
    echo    "    Compte SIP   : ${EXT3_NUMBER}"
    echo    "    Mot de passe : ${EXT3_PASS}"
    echo ""
    echo -e "${YELLOW}══════════════════════════════════════════════════════${NC}"
    echo ""
fi

# ════════════════════════════════════════════════════════════════════════════
# RÉSULTAT FINAL
# ════════════════════════════════════════════════════════════════════════════
echo ""
echo ""
ok "╔══════════════════════════════════════════╗"
ok "║   FreePBX Factory V1.9 — DÉPLOYÉ ✓      ║"
ok "╠══════════════════════════════════════════╣"
ok "║ Admin    : $ADMIN_USERNAME"
ok "║ SSH port : $SSH_PORT — restreint à $MANAGEMENT_IP"
ok "║ URL GUI  : $GUI_URL"
ok "║ Rapport  : $REPORT_FILE"
ok "║ Journal  : $SESSION_LOG"
ok "╚══════════════════════════════════════════╝"
echo ""
warn "═══ INFORMATIONS À CONSERVER ═══════════════"
warn "Port SSH     : $SSH_PORT"
warn "Reconnexion  : ssh -p $SSH_PORT debian@${VPS_IP}"
warn "Admin FreePBX   : $ADMIN_USERNAME"
warn "URL GUI      : $GUI_URL"
warn "Rapport      : $REPORT_FILE"
warn "Journal      : $SESSION_LOG"
warn "══════════════════════════════════════════════"
touch /tmp/fpbx_deploy_done 2>/dev/null || true
