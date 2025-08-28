#!/usr/bin/env node

/**
 * Monitor avanzado de paquetes npm y Homebrew para macOS
 * Configuración dinámica y reportes detallados
 */

const fs = require('fs');
const path = require('path');
const { execSync, spawn } = require('child_process');
const os = require('os');

class PackageMonitor {
    constructor() {
        this.configPath = path.join(os.homedir(), '.macos-npm-config.json');
        this.logPath = path.join(os.homedir(), '.macos-npm-automation.log');
        this.reportPath = path.join(os.homedir(), '.package-monitor-report.json');
        this.config = this.loadConfig();
    }

    loadConfig() {
        try {
            return JSON.parse(fs.readFileSync(this.configPath, 'utf8'));
        } catch (error) {
            console.error('Error loading config:', error.message);
            return this.getDefaultConfig();
        }
    }

    getDefaultConfig() {
        return {
            global_packages: [
                "@vue/cli", "@angular/cli", "create-react-app", "typescript",
                "nodemon", "pm2", "http-server", "live-server", "json-server",
                "eslint", "prettier", "webpack", "parcel-bundler", "yarn", "pnpm",
                "express-generator", "create-next-app", "@nestjs/cli"
            ],
            development_tools: [
                "git", "code", "docker", "docker-compose"
            ],
            homebrew_packages: [
                "git", "curl", "wget", "tree", "jq", "htop", "node", "python3",
                "mongodb-community", "redis", "postgresql"
            ],
            monitoring: {
                check_outdated: true,
                security_audit: true,
                disk_usage_threshold: 80,
                memory_usage_threshold: 85
            },
            auto_update: true,
            backup_before_update: true,
            notification_enabled: true
        };
    }

    async getInstalledPackages() {
        const report = {
            timestamp: new Date().toISOString(),
            npm_global: {},
            homebrew: {},
            system_info: {},
            outdated: {},
            security: {},
            errors: []
        };

        try {
            // NPM global packages
            const npmList = execSync('npm list -g --depth=0 --json', { encoding: 'utf8' });
            const npmData = JSON.parse(npmList);
            report.npm_global = npmData.dependencies || {};

            // Homebrew packages
            const brewList = execSync('brew list --versions', { encoding: 'utf8' });
            report.homebrew = this.parseBrewList(brewList);

            // System info
            report.system_info = {
                node_version: execSync('node --version', { encoding: 'utf8' }).trim(),
                npm_version: execSync('npm --version', { encoding: 'utf8' }).trim(),
                os_version: os.release(),
                memory_usage: this.getMemoryUsage(),
                disk_usage: this.getDiskUsage()
            };

            // Check for outdated packages
            if (this.config.monitoring.check_outdated) {
                report.outdated = await this.getOutdatedPackages();
            }

            // Security audit
            if (this.config.monitoring.security_audit) {
                report.security = await this.getSecurityAudit();
            }

        } catch (error) {
            report.errors.push(error.message);
        }

        return report;
    }

    parseBrewList(brewOutput) {
        const packages = {};
        brewOutput.split('\n').forEach(line => {
            if (line.trim()) {
                const parts = line.trim().split(' ');
                const name = parts[0];
                const version = parts.slice(1).join(' ');
                packages[name] = version;
            }
        });
        return packages;
    }

    getMemoryUsage() {
        const total = os.totalmem();
        const free = os.freemem();
        const used = total - free;
        return {
            total: Math.round(total / 1024 / 1024 / 1024 * 100) / 100, // GB
            used: Math.round(used / 1024 / 1024 / 1024 * 100) / 100,   // GB
            percentage: Math.round((used / total) * 100)
        };
    }

    getDiskUsage() {
        try {
            const output = execSync('df -h ~', { encoding: 'utf8' });
            const lines = output.split('\n');
            const homeLine = lines[1];
            const parts = homeLine.split(/\s+/);
            return {
                size: parts[1],
                used: parts[2],
                available: parts[3],
                percentage: parseInt(parts[4].replace('%', ''))
            };
        } catch (error) {
            return { error: error.message };
        }
    }

    async getOutdatedPackages() {
        try {
            // NPM outdated packages
            const npmOutdated = execSync('npm outdated -g --json', { encoding: 'utf8' });
            const npmOutdatedData = npmOutdated ? JSON.parse(npmOutdated) : {};

            // Homebrew outdated packages
            const brewOutdated = execSync('brew outdated --json', { encoding: 'utf8' });
            const brewOutdatedData = brewOutdated ? JSON.parse(brewOutdated) : [];

            return {
                npm: npmOutdatedData,
                homebrew: brewOutdatedData
            };
        } catch (error) {
            return { error: error.message };
        }
    }

    async getSecurityAudit() {
        try {
            const auditOutput = execSync('npm audit --json', { encoding: 'utf8' });
            return JSON.parse(auditOutput);
        } catch (error) {
            return { error: error.message };
        }
    }

    async generateReport() {
        console.log('🔍 Generando reporte de paquetes...');
        const report = await this.getInstalledPackages();
        
        // Guardar reporte
        fs.writeFileSync(this.reportPath, JSON.stringify(report, null, 2));
        
        // Mostrar resumen
        this.displaySummary(report);
        
        // Verificar alertas
        this.checkAlerts(report);
        
        return report;
    }

    displaySummary(report) {
        console.log('\n📊 RESUMEN DEL SISTEMA\n');
        console.log(`Node.js: ${report.system_info.node_version}`);
        console.log(`npm: ${report.system_info.npm_version}`);
        console.log(`Memoria: ${report.system_info.memory_usage.used}GB / ${report.system_info.memory_usage.total}GB (${report.system_info.memory_usage.percentage}%)`);
        console.log(`Disco: ${report.system_info.disk_usage.used} / ${report.system_info.disk_usage.size} (${report.system_info.disk_usage.percentage}%)`);
        
        console.log('\n📦 PAQUETES INSTALADOS\n');
        console.log(`NPM Global: ${Object.keys(report.npm_global).length} paquetes`);
        console.log(`Homebrew: ${Object.keys(report.homebrew).length} paquetes`);
        
        if (report.outdated && Object.keys(report.outdated).length > 0) {
            console.log('\n⏰ PAQUETES DESACTUALIZADOS\n');
            if (report.outdated.npm && Object.keys(report.outdated.npm).length > 0) {
                console.log(`NPM: ${Object.keys(report.outdated.npm).length} paquetes desactualizados`);
            }
            if (report.outdated.homebrew && report.outdated.homebrew.length > 0) {
                console.log(`Homebrew: ${report.outdated.homebrew.length} paquetes desactualizados`);
            }
        }
        
        if (report.security && report.security.vulnerabilities) {
            const vulns = report.security.vulnerabilities;
            const total = vulns.low + vulns.moderate + vulns.high + vulns.critical;
            if (total > 0) {
                console.log('\n🚨 VULNERABILIDADES DE SEGURIDAD\n');
                console.log(`Total: ${total} (Críticas: ${vulns.critical}, Altas: ${vulns.high}, Moderadas: ${vulns.moderate}, Bajas: ${vulns.low})`);
            }
        }
    }

    checkAlerts(report) {
        const alerts = [];
        
        // Verificar uso de memoria
        if (report.system_info.memory_usage.percentage > this.config.monitoring.memory_usage_threshold) {
            alerts.push(`⚠️  Uso alto de memoria: ${report.system_info.memory_usage.percentage}%`);
        }
        
        // Verificar uso de disco
        if (report.system_info.disk_usage.percentage > this.config.monitoring.disk_usage_threshold) {
            alerts.push(`⚠️  Uso alto de disco: ${report.system_info.disk_usage.percentage}%`);
        }
        
        // Verificar vulnerabilidades críticas
        if (report.security && report.security.vulnerabilities && report.security.vulnerabilities.critical > 0) {
            alerts.push(`🚨 Vulnerabilidades críticas encontradas: ${report.security.vulnerabilities.critical}`);
        }
        
        if (alerts.length > 0) {
            console.log('\n🚨 ALERTAS\n');
            alerts.forEach(alert => console.log(alert));
            
            // Enviar notificación en macOS
            if (this.config.notification_enabled) {
                this.sendNotification('Alertas del Sistema', `${alerts.length} alertas encontradas`);
            }
        }
    }

    sendNotification(title, message) {
        try {
            execSync(`osascript -e 'display notification "${message}" with title "${title}"'`);
        } catch (error) {
            console.error('Error enviando notificación:', error.message);
        }
    }

    async updateOutdatedPackages() {
        console.log('🔄 Actualizando paquetes desactualizados...');
        
        try {
            // Actualizar paquetes npm globales
            console.log('Actualizando paquetes npm globales...');
            execSync('npm update -g', { stdio: 'inherit' });
            
            // Actualizar paquetes homebrew
            console.log('Actualizando paquetes homebrew...');
            execSync('brew upgrade', { stdio: 'inherit' });
            
            console.log('✅ Actualización completada');
            
            if (this.config.notification_enabled) {
                this.sendNotification('Actualización completada', 'Todos los paquetes han sido actualizados');
            }
            
        } catch (error) {
            console.error('❌ Error durante la actualización:', error.message);
        }
    }

    async fixSecurity() {
        console.log('🔧 Solucionando vulnerabilidades de seguridad...');
        
        try {
            execSync('npm audit fix', { stdio: 'inherit' });
            console.log('✅ Vulnerabilidades solucionadas');
             }
    }
