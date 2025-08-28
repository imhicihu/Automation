#!/bin/bash

# =============================================================================
# Sistema de Automatización para macOS con npm
# Instalación, actualización y configuración automatizada de aplicaciones
# =============================================================================

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Archivo de configuración
CONFIG_FILE="$HOME/.macos-npm-config.json"
LOG_FILE="$HOME/.macos-npm-automation.log"

# Función para registración
log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" >> "$LOG_FILE"
    echo -e "${GREEN}[$(date '+%H:%M:%S')]${NC} $1"
}

error() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - ERROR: $1" >> "$LOG_FILE"
    echo -e "${RED}[ERROR]${NC} $1"
}

warning() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - WARNING: $1" >> "$LOG_FILE"
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

# Verificar si estamos en un sistema macOS
check_macos() {
    if [[ "$OSTYPE" != "darwin"* ]]; then
        error "Este script está diseñado para macOS únicamente"
        exit 1
    fi
}

# Verificar e instalar Homebrew si no existe
install_homebrew() {
    if ! command -v brew &> /dev/null; then
        log "Instalando Homebrew..."
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
        
        # Añade Homebrew al PATH
        echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.zprofile
        eval "$(/opt/homebrew/bin/brew shellenv)"
    else
        log "Homebrew ya está instalado"
    fi
}

# Verifica e instala Node.js y npm
install_node_npm() {
    if ! command -v node &> /dev/null; then
        log "Instalando Node.js y npm..."
        brew install node
    else
        log "Node.js ya está instalado. Versión: $(node --version)"
    fi
    
    if ! command -v npm &> /dev/null; then
        error "npm no está disponible después de la instalación de Node.js"
        exit 1
    else
        log "npm está disponible. Versión: $(npm --version)"
    fi
}

# Crea configuración por defecto
create_default_config() {
    if [[ ! -f "$CONFIG_FILE" ]]; then
        log "Creando archivo de configuración por defecto..."
        cat > "$CONFIG_FILE" << 'EOF'
{
  "global_packages": [
    "@vue/cli",
    "@angular/cli",
    "create-react-app",
    "typescript",
    "nodemon",
    "pm2",
    "http-server",
    "live-server",
    "json-server",
    "eslint",
    "prettier",
    "webpack",
    "parcel-bundler",
    "yarn",
    "pnpm"
  ],
  "development_tools": [
    "git",
    "code",
    "docker",
    "docker-compose"
  ],
  "homebrew_packages": [
    "git",
    "curl",
    "wget",
    "tree",
    "jq",
    "htop"
  ],
  "auto_update": true,
  "backup_before_update": true,
  "notification_enabled": true
}
EOF
        log "Configuración por defecto creada en $CONFIG_FILE"
    fi
}

# Lee el archivo de configuración creado
read_config() {
    if [[ -f "$CONFIG_FILE" ]]; then
        cat "$CONFIG_FILE"
    else
        error "Archivo de configuración no encontrado"
        exit 1
    fi
}

# Instala paquetes globales de npm
install_global_packages() {
    log "Instalando paquetes globales de npm..."
    
    local packages=($(read_config | jq -r '.global_packages[]'))
    
    for package in "${packages[@]}"; do
        if npm list -g "$package" &> /dev/null; then
            log "✓ $package ya está instalado"
        else
            log "Instalando $package..."
            if npm install -g "$package"; then
                log "✓ $package instalado correctamente"
            else
                error "✗ Error instalando $package"
            fi
        fi
    done
}

# Instala paquetes de Homebrew
install_homebrew_packages() {
    log "Instalando paquetes de Homebrew..."
    
    local packages=($(read_config | jq -r '.homebrew_packages[]'))
    
    for package in "${packages[@]}"; do
        if brew list "$package" &> /dev/null; then
            log "✓ $package ya está instalado"
        else
            log "Instalando $package..."
            if brew install "$package"; then
                log "✓ $package instalado correctamente"
            else
                error "✗ Error instalando $package"
            fi
        fi
    done
}

# Actualizar todos los paquetes
update_all_packages() {
    log "Iniciando actualización de todos los paquetes..."
    
    # Backup si está habilitado
    if [[ $(read_config | jq -r '.backup_before_update') == "true" ]]; then
        backup_packages
    fi
    
    # Actualiza Homebrew
    log "Actualizando Homebrew..."
    brew update && brew upgrade
    
    # Actualiza npm
    log "Actualizando npm..."
    npm update -g
    
    # Actualiza paquetes globales específicos
    log "Actualizando paquetes globales de npm..."
    local packages=($(read_config | jq -r '.global_packages[]'))
    
    for package in "${packages[@]}"; do
        if npm list -g "$package" &> /dev/null; then
            log "Actualizando $package..."
            npm update -g "$package"
        fi
    done
    
    # Limpia la cache
    log "Limpiando cache..."
    npm cache clean --force
    brew cleanup
    
    log "Actualización completada"
}

# Crea copia de resguardo de paquetes instalados
backup_packages() {
    local backup_dir="$HOME/.npm-backups"
    local timestamp=$(date '+%Y%m%d_%H%M%S')
    
    mkdir -p "$backup_dir"
    
    log "Creando backup de paquetes..."
    
    # Copia de resguado de paquetes npm globales
    npm list -g --depth=0 --json > "$backup_dir/npm_global_$timestamp.json"
    
    # Copia de resguado de paquetes Homebrew
    brew list > "$backup_dir/homebrew_$timestamp.txt"
    
    log "Backup creado en $backup_dir"
}

# Configura entorno de desarrollo
setup_dev_environment() {
    log "Configurando entorno de desarrollo..."
    
    # Crea directorios comunes de acuerdo al entorno de desarrollo
    mkdir -p ~/Projects/{personal,work,experiments}
    mkdir -p ~/.npm-global
    
    # Configura npm para usar directorio global personalizado
    npm config set prefix '~/.npm-global'
    
    # Añade al PATH si no está ya configurado
    if ! grep -q "~/.npm-global/bin" ~/.zshrc; then
        echo 'export PATH=~/.npm-global/bin:$PATH' >> ~/.zshrc
    fi
    
    # Configura Git (si no está configurado)
    if [[ -z $(git config --global user.name) ]]; then
        read -p "Ingrese tu nombre para Git: " git_name
        git config --global user.name "$git_name"
    fi
    
    if [[ -z $(git config --global user.email) ]]; then
        read -p "Ingrese su correo electrónico para Git: " git_email
        git config --global user.email "$git_email"
    fi
    
    # Configurar aliases útiles
    npm config set init-author-name "$(git config --global user.name)"
    npm config set init-author-email "$(git config --global user.email)"
    
    log "Entorno de desarrollo configurado"
}

# Verifica salud del sistema
health_check() {
    log "Verificando salud del sistema..."
    
    # Verifica Node.js y npm
    node_version=$(node --version 2>/dev/null || echo "No instalado")
    npm_version=$(npm --version 2>/dev/null || echo "No instalado")
    
    info "Node.js: $node_version"
    info "npm: $npm_version"
    
    # Verifica Homebrew
    if command -v brew &> /dev/null; then
        brew_version=$(brew --version | head -n1)
        info "Homebrew: $brew_version"
    else
        warning "Homebrew no está instalado"
    fi
    
    # Verifica paquetes críticos
    log "Verificando paquetes críticos..."
    local critical_packages=("git" "curl" "wget")
    
    for package in "${critical_packages[@]}"; do
        if command -v "$package" &> /dev/null; then
            info "✓ $package está disponible"
        else
            warning "✗ $package no está disponible"
        fi
    done
    
    # Verifica espacio en disco
    local disk_usage=$(df -h ~ | tail -1 | awk '{print $5}' | sed 's/%//')
    if [[ $disk_usage -gt 80 ]]; then
        warning "Espacio en disco bajo: ${disk_usage}% usado"
    else
        info "Espacio en disco: ${disk_usage}% usado"
    fi
}

# Envia notificación al sistema (macOS)
send_notification() {
    local title="$1"
    local message="$2"
    
    if [[ $(read_config | jq -r '.notification_enabled') == "true" ]]; then
        osascript -e "display notification \"$message\" with title \"$title\""
    fi
}

# Menú principal
show_menu() {
    echo -e "\n${BLUE}=== Sistema de Automatización macOS + npm ===${NC}"
    echo "1. Instalación completa inicial"
    echo "2. Actualización de todos los paquetes"
    echo "3. Instala paquetes globales npm"
    echo "4. Instala paquetes Homebrew"
    echo "5. Configura entorno de desarrollo"
    echo "6. Verifica salud del sistema"
    echo "7. Crea archivos de resguardo"
    echo "8. Edita configuración"
    echo "9. Ver logs"
    echo "0. Salir"
    echo
}

# Instalación completa inicial
full_installation() {
    log "Iniciando instalación completa..."
    
    check_macos
    install_homebrew
    install_node_npm
    create_default_config
    install_homebrew_packages
    install_global_packages
    setup_dev_environment
    
    log "Instalación completa finalizada"
    send_notification "Automatización macOS" "Instalación completada exitosamente"
}

# Script principal
main() {
    case "$1" in
        "install")
            full_installation
            ;;
        "update")
            update_all_packages
            ;;
        "health")
            health_check
            ;;
        "backup")
            backup_packages
            ;;
        "setup")
            setup_dev_environment
            ;;
        *)
            if [[ $# -eq 0 ]]; then
                while true; do
                    show_menu
                    read -p "Selecciona una opción: " choice
                    
                    case $choice in
                        1) full_installation ;;
                        2) update_all_packages ;;
                        3) install_global_packages ;;
                        4) install_homebrew_packages ;;
                        5) setup_dev_environment ;;
                        6) health_check ;;
                        7) backup_packages ;;
                        8) open "$CONFIG_FILE" ;;
                        9) tail -n 50 "$LOG_FILE" ;;
                        0) exit 0 ;;
                        *) error "Opción inválida" ;;
                    esac
                    
                    echo -e "\n${YELLOW}Presiona Enter para continuar...${NC}"
                    read
                done
            else
                echo "Uso: $0 [install|update|health|backup|setup]"
                echo "O ejecuta sin parámetros para el menú interactivo"
            fi
            ;;
    esac
}

# Ejecutar script principal
main "$@"
