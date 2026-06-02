# ============================================
# OTIMIZACAO DE REDE - WINDOWS
# ============================================

Write-Host "=========================================" -ForegroundColor Cyan
Write-Host "         OTIMIZACAO DE REDE             " -ForegroundColor Cyan
Write-Host "=========================================" -ForegroundColor Cyan
Write-Host ""

# Verifica se esta sendo executado como Administrador
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    Write-Host "ATENCAO: Alguns comandos precisam de privilegios de Administrador." -ForegroundColor Yellow
    Write-Host "Execute o PowerShell como Administrador e tente novamente." -ForegroundColor Yellow
    Write-Host ""
    Read-Host "Pressione Enter para sair"
    exit
}

Write-Host "Iniciando otimizacao de rede..." -ForegroundColor Green
Write-Host ""

# ----- 1. LIMPAR CACHE DNS -----
Write-Host "1. Limpando cache DNS..." -ForegroundColor Yellow
try {
    ipconfig /flushdns
    Write-Host "   Cache DNS limpo com sucesso." -ForegroundColor Green
} catch {
    Write-Host "   Erro ao limpar cache DNS." -ForegroundColor Red
}
Write-Host ""

# ----- 2. RENOVAR CONFIGURACAO DE IP -----
Write-Host "2. Renovando configuracao de IP (libera e renova)..." -ForegroundColor Yellow
Write-Host "   (Sua conexao pode ser interrompida momentaneamente)" -ForegroundColor Gray
try {
    ipconfig /release
    ipconfig /renew
    Write-Host "   IP renovado com sucesso." -ForegroundColor Green
} catch {
    Write-Host "   Erro ao renovar IP." -ForegroundColor Red
}
Write-Host ""

# ----- 3. RESETAR WINSOCK -----
Write-Host "3. Resetando Winsock..." -ForegroundColor Yellow
try {
    netsh winsock reset
    Write-Host "   Winsock resetado com sucesso." -ForegroundColor Green
} catch {
    Write-Host "   Erro ao resetar Winsock." -ForegroundColor Red
}
Write-Host ""

# ----- 4. RESETAR PILHA TCP/IP -----
Write-Host "4. Resetando pilha TCP/IP..." -ForegroundColor Yellow
try {
    netsh int ip reset
    Write-Host "   Pilha TCP/IP resetada com sucesso." -ForegroundColor Green
} catch {
    Write-Host "   Erro ao resetar pilha TCP/IP." -ForegroundColor Red
}
Write-Host ""

# ----- 5. RESETAR FIREWALL (COM AVISO) -----
Write-Host "5. Resetando firewall do Windows (recomendado)..." -ForegroundColor Yellow
$resp = Read-Host "   Deseja resetar o firewall? (S/N)"
if ($resp -eq "S" -or $resp -eq "s") {
    try {
        netsh advfirewall reset
        Write-Host "   Firewall resetado com sucesso." -ForegroundColor Green
    } catch {
        Write-Host "   Erro ao resetar firewall." -ForegroundColor Red
    }
} else {
    Write-Host "   Firewall nao foi alterado." -ForegroundColor Gray
}
Write-Host ""

# ----- 6. AJUSTES DE TCP AUTO-TUNING (OPCIONAL) -----
Write-Host "6. Ajustando TCP Auto-Tuning (recomendado: normal)..." -ForegroundColor Yellow
try {
    netsh int tcp set global autotuninglevel=normal
    Write-Host "   TCP Auto-Tuning configurado como 'normal'." -ForegroundColor Green
} catch {
    Write-Host "   Erro ao ajustar TCP Auto-Tuning." -ForegroundColor Red
}
Write-Host ""

# ----- 7. MOSTRAR CONFIGURACAO ATUAL -----
Write-Host "7. Configuracao atual de rede:" -ForegroundColor Yellow
try {
    ipconfig | Select-String -Pattern "Adaptador|IPv4|DNS"
} catch {
    Write-Host "   Nao foi possivel obter configuracao." -ForegroundColor Red
}
Write-Host ""

Write-Host "=========================================" -ForegroundColor Cyan
Write-Host "     OTIMIZACAO CONCLUIDA               " -ForegroundColor Cyan
Write-Host "=========================================" -ForegroundColor Cyan
Write-Host ""

Write-Host "Recomenda-se reiniciar o computador para aplicar todas as alteracoes." -ForegroundColor Yellow
