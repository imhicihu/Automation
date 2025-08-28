#!/bin/bash

# =============================================================================
# Programador de Tareas Automatizadas para macOS
# Configura cron jobs y tareas automáticas
# =============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MAIN_SCRIPT="$SCRIPT_DIR/macos-npm-automation.sh"
CRON_FILE="/tmp/npm-automation-cron"

# Función para instalar tareas automáticas
install_scheduled_tasks() {
    echo "Configurando tareas automáticas..."
    
    # Crea archivo de cron temporal
    cat > "$CRON_FILE" << EOF
# Automatización npm/macOS - Actualización semanal (Domingo 02:00)
0 2 * * 0 $MAIN_SCRIPT update >> $HOME/.macos-npm-automation.log 2>&1

# Verificación de salud diaria (Lunes a Viernes 09:00)
0 9 * * 1-5 $MAIN_SCRIPT health >> $HOME/.macos-npm-automation.log 2>&1

# Copia de resguardo mensual (Primer día del mes 01:00)
0 1 1 * * $MAIN_SCRIPT backup >> $HOME/.macos-npm-automation.log 2>&1
EOF
    
    # Instala cron jobs
    crontab "$CRON_FILE"
    rm "$CRON_FILE"
    
    echo "Tareas automáticas configuradas:"
    echo "- Actualización semanal: Domingos 02:00"
    echo "- Verificación diaria: Lunes-Viernes 09:00"
    echo "- Copia de resguardo mensual: Primer día del mes 01:00"
}

# Función para crear LaunchAgent (alternativa a cron en macOS)
create_launch_agent() {
    local plist_dir="$HOME/Library/LaunchAgents"
    mkdir -p "$plist_dir"
    
    # LaunchAgent para actualizaciones semanales
    cat > "$plist_dir/com.npm.automation.update.plist" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.npm.automation.update</string>
    <key>ProgramArguments</key>
    <array>
        <string>$MAIN_SCRIPT</string>
        <string>update</string>
    </array>
    <key>StartCalendarInterval</key>
    <dict>
        <key>Weekday</key>
        <integer>0</integer>
        <key>Hour</key>
        <integer>2</integer>
        <key>Minute</key>
        <integer>0</integer>
    </dict>
    <key>StandardOutPath</key>
    <string>$HOME/.macos-npm-automation.log</string>
    <key>StandardErrorPath</key>
    <string>$HOME/.macos-npm-automation.log</string>
</dict>
</plist>
EOF
    
    # Carga LaunchAgent
    launchctl load "$plist_dir/com.npm.automation.update.plist"
    
    echo "LaunchAgent creado y cargado para actualizaciones automáticas"
}

# Muestra tareas programadas
show_scheduled_tasks() {
    echo "=== Tareas Cron Actuales ==="
    crontab -l 2>/dev/null || echo "No hay tareas cron configuradas"
    
    echo -e "\n=== LaunchAgents Activos ==="
    launchctl list | grep com.npm.automation || echo "No hay LaunchAgents de automatización activos"
}

# Quitando tareas automáticas
remove_scheduled_tasks() {
    echo "Removiendo tareas automáticas..."
    
    # Remueve cron jobs
    crontab -l 2>/dev/null | grep -v "macos-npm-automation" | crontab -
    
    # Remueve LaunchAgents
    local plist_file="$HOME/Library/LaunchAgents/com.npm.automation.update.plist"
    if [[ -f "$plist_file" ]]; then
        launchctl unload "$plist_file"
        rm "$plist_file"
    fi
    
    echo "Tareas automáticas removidas"
}

case "$1" in
    "install")
        install_scheduled_tasks
        create_launch_agent
        ;;
    "show")
        show_scheduled_tasks
        ;;
    "remove")
        remove_scheduled_tasks
        ;;
    *)
        echo "Uso: $0 [install|show|remove]"
        echo "  install - Instala tareas automáticas"
        echo "  show    - Muestra tareas programadas"
        echo "  remove  - Quita tareas automáticas"
        ;;
esac
