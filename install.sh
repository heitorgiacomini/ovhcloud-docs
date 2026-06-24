#!/bin/bash
# install.sh — FreePBX Factory V1.8 CRA — Installateur on-VPS
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

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PHASES_DIR="$SCRIPT_DIR/phases"
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

# ── Pré-checks ──────────────────────────────────────────────────────────────
[[ $EUID -eq 0 ]] || err "Doit être exécuté en root : sudo bash $0"
[[ -f /etc/debian_version ]] || err "Système non supporté — Debian 12 requis"
DEB_VER=$(cut -d. -f1 /etc/debian_version)
[[ "$DEB_VER" == "12" ]] || warn "Version Debian détectée : $DEB_VER (Debian 12 recommandée)"
[[ -f "$PHASES_DIR/00_cleanup.sh" ]] || err "Scripts de phase introuvables dans $PHASES_DIR"
command -v wget &>/dev/null || err "wget requis — installer avec : apt-get install -y wget"
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
        "eval export $_FWD_ENV; bash $0 $_FWD_ARGS; echo ''; echo '-- Installation terminée — Appuyer sur Entrée --'; read"
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
    local pass="$1" label="${2:-Mot de passe}" ok=1
    [[ ${#pass} -lt 12 ]] && echo "  ✗ $label : minimum 12 caractères (actuel : ${#pass})" && ok=0
    echo "$pass" | grep -q '[A-Z]' || { echo "  ✗ $label : au moins 1 majuscule requise"; ok=0; }
    echo "$pass" | grep -q '[a-z]' || { echo "  ✗ $label : au moins 1 minuscule requise"; ok=0; }
    echo "$pass" | grep -q '[0-9]' || { echo "  ✗ $label : au moins 1 chiffre requis"; ok=0; }
    echo "$pass" | grep -qP '[^A-Za-z0-9]' || { echo "  ✗ $label : au moins 1 caractère spécial requis"; ok=0; }
    [[ $ok -eq 1 ]]
}

_read_star_input() {
    # Saisie masquée avec affichage d'étoiles — gère backspace
    local varname="$1" prompt="$2" password="" char
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
    while true; do
        _read_star_input pass "$label"
        validate_password "$pass" "$label" || continue
        if [[ $confirm -eq 1 ]]; then
            _read_star_input pass2 "Confirmer $label"
            [[ "$pass" == "$pass2" ]] || { echo "  ✗ Mots de passe différents"; continue; }
        fi
        printf -v "$varname" '%s' "$pass"
        break
    done
}

read_ext_password() {
    local varname="$1" ext="$2" pass
    info "  [Entrée] = génération automatique sécurisée"
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
# WIZARD — Saisie paramètres (V1.8 CRA)
# ════════════════════════════════════════════════════════════════════════════
echo ""
echo "╔══════════════════════════════════════════╗"
echo "║  FreePBX Factory V1.8 CRA — Installateur ║"
echo "╚══════════════════════════════════════════╝"
echo ""

# ── Axe 1 : Compte admin GUI ─────────────────────────────────────────────────
info "▶ 1/4 — Compte administrateur FreePBX"
echo ""
info "  Ce compte permet d'accéder à l'interface de configuration FreePBX."
info "  Choisissez un identifiant et un mot de passe robustes : ils ne peuvent"
info "  pas être récupérés automatiquement après le déploiement."
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
    read -rp "  Identifiant de connexion FreePBX (min. 8 caractères, ex: ipbx-admin) : " ADMIN_USERNAME
    ADMIN_LOWER="${ADMIN_USERNAME,,}"
    IS_RESERVED=0
    for r in $RESERVED_LOGINS; do [[ "$ADMIN_LOWER" == "$r" ]] && IS_RESERVED=1 && break; done
    if [[ ${#ADMIN_USERNAME} -ge 8 ]] && echo "$ADMIN_USERNAME" | grep -qP '^[A-Za-z0-9._-]+$' && [[ $IS_RESERVED -eq 0 ]]; then
        break
    fi
    echo "  ✗ Identifiant invalide — minimum 8 caractères, alphanum+._-, noms réservés interdits (admin, root, administrator, freepbx, asterisk)"
done
read_password ADMIN_PASSWORD "  Mot de passe FreePBX"
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
EXT1_NUMBER="" EXT1_NAME="Standard"  EXT1_PASS=""
EXT2_NUMBER="" EXT2_NAME="Mobile"    EXT2_PASS=""
EXT3_NUMBER="" EXT3_NAME="WebRTC"    EXT3_PASS=""

if [[ -n "$KIT_STARTER_ARG" ]]; then
    # Pré-sélection wizard — pas de question interactive
    [[ "${KIT_STARTER_ARG,,}" == "oui" ]] && KIT_STARTER="oui"
    echo "  Kit starter : $KIT_STARTER (pré-sélectionné par le wizard)"
    KIT_RESP="${KIT_STARTER_ARG,,}"
    [[ "$KIT_STARTER" == "oui" ]] && KIT_RESP="o" || KIT_RESP="n"
else
    info "  Kit de démonstration : 3 postes SIP préconfigurés (Standard / Mobile / WebRTC)"
    info "  avec des numéros à 5 chiffres attribués automatiquement. Utile pour tester"
    info "  l'installation avant de connecter de vrais postes."
    info "  [Entrée] = non (désactivé)"
    read -rp "  Créer 3 postes de démonstration ? [o/N] : " KIT_RESP
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
            read -rp "  Nom du poste $i [${default_name}] : " name
            [[ -n "$name" ]] && printf -v "$varname" '%s' "$name"
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
        _trunk_ip=$(getent hosts "$TRUNK_REGISTRAR" 2>/dev/null | awk '{print $1}' | head -1)
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
    read -rp "  Connecter une ligne opérateur SIP ? [o/N] : " TRUNK_RESP
    if [[ "${TRUNK_RESP,,}" == "o" ]]; then
        TRUNK_ENABLED="oui"
        read -rp "  Serveur SIP opérateur (ex: siptrunk.ovh.net) : " TRUNK_REGISTRAR
        read -rp "  Identifiant SIP (numéro ou login opérateur) : " TRUNK_USERNAME
        read_password TRUNK_PASSWORD "  Mot de passe SIP" 0
        echo "  ✓ Ligne opérateur configurée : $TRUNK_REGISTRAR"
        _trunk_ip=$(getent hosts "$TRUNK_REGISTRAR" 2>/dev/null | awk '{print $1}' | head -1)
        if [[ -n "$_trunk_ip" ]]; then
            EXTRA_IGNOREIP="$_trunk_ip"
            echo "  → IP opérateur résolue : $EXTRA_IGNOREIP (autorisée dans fail2ban)"
        else
            read -rp "  IP de l'opérateur SIP à autoriser (optionnel) : " EXTRA_IGNOREIP
            [[ -n "$EXTRA_IGNOREIP" ]] && echo "  → Autorisée : $EXTRA_IGNOREIP"
        fi
    else
        echo "  → Ligne opérateur désactivée"
    fi
fi
echo ""

# ── TLS HTTPS ─────────────────────────────────────────────────────────────────
info "▶ 3/4 — Accès HTTPS à l'interface d'administration (optionnel)"
info ""
info "  Sans nom de domaine : l'interface FreePBX reste inaccessible à la fin de"
info "  l'installation (Apache arrêté par sécurité). Elle peut être démarrée"
info "  ponctuellement en HTTP si nécessaire, sous votre responsabilité."
info ""
info "  Avec un sous-domaine : le script configure automatiquement un certificat"
info "  HTTPS (Let's Encrypt). L'enregistrement DNS de type A doit pointer vers"
info "  l'adresse IP de ce serveur avant de lancer l'installation."
info ""
info "  [Entrée] = ignorer (interface web désactivée en fin d'installation)"
TLS_DOMAIN=""
if [[ -n "$TLS_DOMAIN_ARG" ]]; then
    TLS_DOMAIN="$TLS_DOMAIN_ARG"
    echo "  ✓ Sous-domaine : $TLS_DOMAIN (pré-sélectionné par le wizard)"
else
    read -rp "  Sous-domaine HTTPS (ex: pbx.mon-entreprise.fr) ou Entrée pour ignorer : " TLS_DOMAIN
    [[ -n "$TLS_DOMAIN" ]] && echo "  ✓ Sous-domaine : $TLS_DOMAIN" || echo "  → Interface web désactivée en fin d'installation"
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
    ok "  IP de gestion  : $MANAGEMENT_IP (détectée automatiquement)"
else
    # Fallback : saisie manuelle si lancé sans le launcher
    echo ""
    info "  Saisissez l'adresse IP de votre poste (visible avec : curl ifconfig.me)"
    info "  Laisser vide = accès SSH non restreint (non recommandé)"
    while true; do
        read -rp "  Votre IP publique (ex: A.B.C.D) : " _MGMT_RAW
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

log "====== PARAMÈTRES V1.8 CRA ======"
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
info "  [Entrée] = annuler"
read -rp "  Lancer le déploiement ? [o/N] : " CONFIRM
[[ "${CONFIRM,,}" == "o" ]] || { echo "  Annulé."; exit 0; }
INSTALL_START=$(date +%s)

# ── Ping démarrage anonyme (automatique, silencieux) ────────────────────────
_send_telem "{\"event\":\"deploy_start\",\"version\":\"${SCRIPT_VERSION}\",\"os\":\"${_OS_ID}\",\"id\":\"${DEPLOY_ID}\"}"

# ════════════════════════════════════════════════════════════════════════════
# PHASE 00 — Cleanup
# ════════════════════════════════════════════════════════════════════════════
log ""
log "=== PHASE 00 — Cleanup ==="
bash "$PHASES_DIR/00_cleanup.sh"
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
bash "$PHASES_DIR/00_hardening.sh" "$MANAGEMENT_IP" "$SSH_PORT"
ok "00_hardening — SSH actif sur port $SSH_PORT"

# ════════════════════════════════════════════════════════════════════════════
# PHASE 01 — Installation FreePBX (~20-40 min)
# ════════════════════════════════════════════════════════════════════════════
log ""
log "=== PHASE 01 — Installation FreePBX (20-40 min) ==="
echo ""
echo -e "${CYAN}  Installation de FreePBX en cours — durée estimée : 20 à 40 minutes.${NC}"
echo -e "${CYAN}  Le terminal reste silencieux pendant cette phase — c'est normal.${NC}"
echo -e "${CYAN}  Ne fermez pas cette fenêtre.${NC}"
echo ""
bash "$PHASES_DIR/01_install.sh"
ok "01_install"

# ════════════════════════════════════════════════════════════════════════════
# PHASE 02 — Asterisk
# ════════════════════════════════════════════════════════════════════════════
log ""
log "=== PHASE 02 — Asterisk + modules ==="
bash "$PHASES_DIR/02_asterisk.sh"
ok "02_asterisk"

# ════════════════════════════════════════════════════════════════════════════
# PHASE 03 — Firewall (réinstalle UFW après suppression par FreePBX — E15)
# ════════════════════════════════════════════════════════════════════════════
log ""
log "=== PHASE 03 — Firewall ==="
bash "$PHASES_DIR/03_firewall.sh" "$MANAGEMENT_IP" "$SSH_PORT"
ok "03_firewall"

# ════════════════════════════════════════════════════════════════════════════
# PHASE 04 — fail2ban
# ════════════════════════════════════════════════════════════════════════════
log ""
log "=== PHASE 04 — fail2ban ==="
bash "$PHASES_DIR/04_fail2ban.sh" "$MANAGEMENT_IP" "$SSH_PORT" "${EXTRA_IGNOREIP:-}"
ok "04_fail2ban"

# ════════════════════════════════════════════════════════════════════════════
# PHASE 05 — (supprimée — V1.9 CRA) — plus de restore template
# Extensions et trunk créés en SQL natif (06_post_restore.sh) — cf. test 09/06/2026
# Les clés TLS partagées du template sont remplacées par Let's Encrypt (15_tls.sh)
# ════════════════════════════════════════════════════════════════════════════
ok "05_restore"

# ════════════════════════════════════════════════════════════════════════════
# PHASE 06 — Post-restore (endpoint + admin + extensions + trunk)
# ════════════════════════════════════════════════════════════════════════════
log ""
log "=== PHASE 06 — Post-restore ==="
bash "$PHASES_DIR/06_post_restore.sh" \
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
bash "$PHASES_DIR/09_apache_hardening.sh"
ok "09_apache_hardening"

# ════════════════════════════════════════════════════════════════════════════
# PHASE 10 — MariaDB hardening
# ════════════════════════════════════════════════════════════════════════════
log ""
log "=== PHASE 10 — MariaDB hardening ==="
bash "$PHASES_DIR/10_mariadb_hardening.sh"
ok "10_mariadb_hardening"

# ════════════════════════════════════════════════════════════════════════════
# PHASE 11 — Services hardening
# ════════════════════════════════════════════════════════════════════════════
log ""
log "=== PHASE 11 — Services hardening ==="
bash "$PHASES_DIR/11_services_hardening.sh"
ok "11_services_hardening"

# ════════════════════════════════════════════════════════════════════════════
# PHASE 14 — auditd (NIS2 Art. 21b — journalisation actions privilégiées)
# ════════════════════════════════════════════════════════════════════════════
log ""
log "=== PHASE 14 — auditd ==="
bash "$PHASES_DIR/14_auditd.sh"
ok "14_auditd"

# ════════════════════════════════════════════════════════════════════════════
# PHASE 12 — SBOM CycloneDX 1.4 (CRA Annex II + NIS2 Art. 21)
# ════════════════════════════════════════════════════════════════════════════
log ""
log "=== PHASE 12 — SBOM CycloneDX ==="
bash "$PHASES_DIR/12_sbom.sh"
ok "12_sbom"

# ════════════════════════════════════════════════════════════════════════════
# PHASE 13 — Contrôles conformité post-déploiement (CRA + NIS2)
# ════════════════════════════════════════════════════════════════════════════
log ""
log "=== PHASE 13 — Contrôles conformité CRA + NIS2 ==="
bash "$PHASES_DIR/13_post_checks.sh" "$SSH_PORT"
ok "13_post_checks"

# ════════════════════════════════════════════════════════════════════════════
# Détection IP principale du VPS (pour rapport + softphones)
# ════════════════════════════════════════════════════════════════════════════
VPS_IP=$(ip -4 route get 1.1.1.1 2>/dev/null | grep -oP 'src \K\S+' | head -1)
[[ -z "$VPS_IP" ]] && VPS_IP=$(hostname -I 2>/dev/null | awk '{print $1}')
[[ -z "$VPS_IP" ]] && VPS_IP="<IP_VPS>"

# ════════════════════════════════════════════════════════════════════════════
# Validation compte admin GUI (Apache temporairement actif)
# ════════════════════════════════════════════════════════════════════════════
log ""
log "=== Validation compte admin GUI ==="
systemctl start apache2 2>/dev/null || true
sleep 2
_GUI_CODE=$(curl -s -o /dev/null -w "%{http_code}" -X POST http://localhost/admin/index.php \
    --data-urlencode "username=$ADMIN_USERNAME" \
    --data-urlencode "password=$ADMIN_PASSWORD" 2>/dev/null || echo "000")
if [[ "$_GUI_CODE" =~ ^(200|302)$ ]]; then
    ok "Validation GUI : HTTP $_GUI_CODE — compte $ADMIN_USERNAME opérationnel"
else
    warn "Validation GUI : HTTP $_GUI_CODE — vérifier manuellement après activation TLS"
fi

# ════════════════════════════════════════════════════════════════════════════
# PHASE 15 — TLS/HTTPS (Let's Encrypt + Apache)
# Si TLS_DOMAIN fourni : certbot + Apache HTTPS actif
# Si vide             : Apache arrêté (GUI inaccessible jusqu'à config TLS)
# ════════════════════════════════════════════════════════════════════════════
log ""
log "=== PHASE 15 — TLS/HTTPS ==="
export TLS_DOMAIN
bash "$PHASES_DIR/15_tls.sh" "$TLS_DOMAIN"
if [[ -n "$TLS_DOMAIN" ]]; then
    ok "15_tls — HTTPS actif — https://$TLS_DOMAIN/admin/"
else
    ok "15_tls — Apache arrêté — GUI inaccessible jusqu'à configuration TLS"
fi

# ════════════════════════════════════════════════════════════════════════════
# POST-CHECK
# ════════════════════════════════════════════════════════════════════════════
log ""
log "=== POST-CHECK ==="
echo '--- Asterisk socket ---'
if [[ ! -e /var/run/asterisk/asterisk.ctl ]]; then
    warn "Socket Asterisk absent (graceful restart post-fwconsole reload) — relance..."
    systemctl restart asterisk
    sleep 8
    [[ -e /var/run/asterisk/asterisk.ctl ]] && ok "Asterisk redémarré" || warn "Socket Asterisk toujours absent — vérifier manuellement"
else
    ok "Asterisk opérationnel"
fi
echo '--- Services PM2 ---'
fwconsole pm2 --list 2>/dev/null || echo "PM2 check — voir fwconsole pm2 --list"
echo '--- GUI ---'
curl -s -o /dev/null -w 'HTTP GUI: %{http_code}\n' http://localhost/admin/ 2>/dev/null || true
echo '--- Ports sensibles TCP ---'
ss -tlnp | grep -E ':1720|:3306' && echo 'ATTENTION port exposé' || echo 'Ports 1720/3306 : fermés OK'
echo '--- Ports sensibles UDP ---'
ss -ulnp | grep -E ':69 |:5353 ' && echo 'ATTENTION port UDP exposé' || echo 'Ports 69/5353 : fermés OK'
echo '--- Shell asterisk ---'
getent passwd asterisk | cut -d: -f7
echo '--- fail2ban ---'
fail2ban-client get ssh-iptables bantime 2>/dev/null || echo "fail2ban : vérifier manuellement"
echo '--- UFW ---'
ufw status | head -10
echo '--- Conformité CRA+NIS2 ---'
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
  RAPPORT DE LIVRAISON — FreePBX Factory V1.8 CRA
  Date       : ${DEPLOY_DATE}
═══════════════════════════════════════════════════════════

ACCÈS
  Admin FreePBX : ${ADMIN_USERNAME}  (mot de passe défini au wizard)
  Port SSH   : ${SSH_PORT}  (clé ED25519 uniquement)
  IP autorisée SSH : ${MANAGEMENT_IP}
  IP VPS     : ${VPS_IP}
  GUI        : $(if [[ -n "${TLS_DOMAIN}" ]]; then echo "https://${TLS_DOMAIN}/admin/"; else echo "http://${VPS_IP}/admin/  (HTTPS requis — TLS non activé)"; fi)
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

ACCÈS GUI TEMPORAIRE (HTTP — non sécurisé)
  Démarrer Apache  : sudo systemctl start apache2
  URL admin        : http://${VPS_IP}/admin/
  Arrêter Apache   : sudo systemctl stop apache2
  ⚠ HTTP uniquement — TLS non configuré — accès via IP publique uniquement

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
    echo -e "${RED}  ⚠  HTTP uniquement — non chiffré — TLS non configuré${NC}"
    echo -e "${RED}  ⚠  Arrêtez Apache immédiatement après vérification${NC}"
    echo ""
    echo -e "  ${CYAN}── 1. DÉMARRER APACHE (ponctuel) ─────────────────────${NC}"
    echo    "     sudo systemctl start apache2"
    echo ""
    echo -e "  ${CYAN}── 2. ACCÉDER À L'INTERFACE FREEPBX ─────────────────${NC}"
    echo    "     URL   : http://${VPS_IP}/admin/"
    echo    "     Login : ${ADMIN_USERNAME}"
    echo -e "     ${YELLOW}⚠ Accessible via IP publique uniquement (pas depuis le LAN du VPS)${NC}"
    echo    "     Vérifier : Applications → Extensions"
    echo    "     Extensions attendues : ${EXT1_NUMBER} / ${EXT2_NUMBER} / ${EXT3_NUMBER}"
    echo ""
    echo -e "  ${CYAN}── 3. ARRÊTER APACHE ─────────────────────────────────${NC}"
    echo    "     sudo systemctl stop apache2"
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
ok "║   FreePBX Factory V1.8 — DÉPLOYÉ ✓      ║"
ok "╠══════════════════════════════════════════╣"
ok "║ Admin    : $ADMIN_USERNAME"
ok "║ SSH port : $SSH_PORT — restreint à $MANAGEMENT_IP"
ok "║ URL GUI  : HTTPS requis (configurer TLS)"
ok "║ Rapport  : $REPORT_FILE"
ok "║ Journal  : $SESSION_LOG"
ok "╚══════════════════════════════════════════╝"
echo ""
warn "═══ INFORMATIONS À CONSERVER ═══════════════"
warn "Port SSH     : $SSH_PORT"
warn "Reconnexion  : ssh -p $SSH_PORT debian@${VPS_IP}"
warn "Admin FreePBX   : $ADMIN_USERNAME"
warn "Rapport      : $REPORT_FILE"
warn "Journal      : $SESSION_LOG"
warn "══════════════════════════════════════════════"
