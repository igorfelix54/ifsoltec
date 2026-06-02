# Verifica se o modulo PSWindowsUpdate esta instalado
if (-not (Get-Module -ListAvailable -Name PSWindowsUpdate)) {
    Write-Host "Modulo PSWindowsUpdate nao encontrado. Instalando..." -ForegroundColor Yellow
    Install-PackageProvider -Name NuGet -Force -Scope CurrentUser
    Install-Module -Name PSWindowsUpdate -Force -Scope CurrentUser
}

# Importa o modulo
Import-Module PSWindowsUpdate

# Verifica e lista atualizacoes disponiveis
Write-Host "Procurando por atualizacoes..." -ForegroundColor Green
Get-WindowsUpdate

# Pausa para o usuario ver as informacoes
# Read-Host "Pressione Enter para sair"
# Stop-Process -Id $PID -Force