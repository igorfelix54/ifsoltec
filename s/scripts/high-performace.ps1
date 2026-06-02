# ============================================
# ATIVAR MODO ALTO DESEMPENHO - WINDOWS
# ============================================

Write-Host "=========================================" -ForegroundColor Cyan
Write-Host "      MODO ALTO DESEMPENHO              " -ForegroundColor Cyan
Write-Host "=========================================" -ForegroundColor Cyan
Write-Host ""

# Verifica se esta sendo executado como Administrador
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    Write-Host "ATENCAO: Este script precisa de privilegios de Administrador." -ForegroundColor Red
    Write-Host "Execute o PowerShell como Administrador e tente novamente." -ForegroundColor Yellow
    Write-Host ""
    Read-Host "Pressione Enter para sair"
    exit
}

# GUID conhecido do plano Alto Desempenho
$highPerformanceGuid = "8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c"

Write-Host "Verificando planos de energia disponiveis..." -ForegroundColor Yellow
Write-Host ""

# Lista todos os planos
$allSchemes = powercfg /list
Write-Host $allSchemes -ForegroundColor Gray
Write-Host ""

# Verifica se o plano Alto Desempenho ja existe
$schemeExists = $allSchemes -match $highPerformanceGuid

if ($schemeExists) {
    Write-Host "Plano 'Alto Desempenho' ja existe no sistema." -ForegroundColor Green
    Write-Host "Ativando plano..." -ForegroundColor Yellow
    try {
        powercfg /setactive $highPerformanceGuid
        Write-Host "Plano 'Alto Desempenho' ativado com sucesso!" -ForegroundColor Green
    } catch {
        Write-Host "Erro ao ativar o plano." -ForegroundColor Red
    }
} else {
    Write-Host "Plano 'Alto Desempenho' nao encontrado. Criando uma copia..." -ForegroundColor Yellow
    try {
        # Duplica o plano balanceado (ou qualquer outro) para criar o Alto Desempenho
        $output = powercfg /duplicatescheme $highPerformanceGuid
        if ($LASTEXITCODE -eq 0) {
            Write-Host "Plano criado com sucesso." -ForegroundColor Green
            powercfg /setactive $highPerformanceGuid
            Write-Host "Plano 'Alto Desempenho' ativado!" -ForegroundColor Green
        } else {
            Write-Host "Falha ao criar o plano." -ForegroundColor Red
        }
    } catch {
        Write-Host "Erro durante a criacao do plano." -ForegroundColor Red
    }
}

Write-Host ""
Write-Host "Plano atual ativo:" -ForegroundColor Yellow
powercfg /getactivescheme
Write-Host ""

# Pergunta se deseja ajustar configuracoes para desempenho maximo (nunca suspender, nunca desligar video, disco sempre ligado)
$resp = Read-Host "Deseja ajustar configuracoes para desempenho maximo (nunca suspender, nunca desligar video, disco sempre ligado)? (S/N)"
if ($resp -eq "S" -or $resp -eq "s") {
    Write-Host "Ajustando configuracoes..." -ForegroundColor Yellow
    
    # Nunca suspender (tempo = 0)
    powercfg /change standby-timeout-ac 0
    powercfg /change standby-timeout-dc 0
    Write-Host "  Suspensao: nunca (desativada)" -ForegroundColor Green
    
    # Disco rígido sempre ligado (tempo = 0)
    powercfg /change disk-timeout-ac 0
    powercfg /change disk-timeout-dc 0
    Write-Host "  Disco rigido: sempre ligado (nunca desliga)" -ForegroundColor Green
    
    # Nunca desligar video (tempo = 0)
    powercfg /change monitor-timeout-ac 0
    powercfg /change monitor-timeout-dc 0
    Write-Host "  Video: nunca desliga" -ForegroundColor Green
    
    Write-Host ""
    Write-Host "Configuracoes ajustadas." -ForegroundColor Green
    Write-Host "Agora o sistema: nao suspende, nao desliga video e mantem disco sempre ligado." -ForegroundColor White
} else {
    Write-Host "Configuracoes adicionais nao foram alteradas." -ForegroundColor Gray
}

Write-Host ""
Write-Host "=========================================" -ForegroundColor Cyan
Write-Host "     OPERACAO CONCLUIDA                 " -ForegroundColor Cyan
Write-Host "=========================================" -ForegroundColor Cyan
Write-Host ""