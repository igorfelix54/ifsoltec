# ============================================
# LIMPEZA DE ARQUIVOS TEMPORARIOS - WINDOWS
# ============================================

Write-Host "=========================================" -ForegroundColor Cyan
Write-Host "         LIMPEZA DO SISTEMA             " -ForegroundColor Cyan
Write-Host "=========================================" -ForegroundColor Cyan
Write-Host ""

# Verifica se tem permissão de administrador (necessário para Prefetch)
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    Write-Host "ATENCAO: Para limpar a pasta Prefetch e necessario executar como Administrador." -ForegroundColor Yellow
    Write-Host "Algumas pastas serao limpas, mas o Prefetch sera ignorado." -ForegroundColor Yellow
    Write-Host ""
    $continue = Read-Host "Deseja continuar mesmo assim? (S/N)"
    if ($continue -ne "S" -and $continue -ne "s") {
        Write-Host "Operacao cancelada." -ForegroundColor Red
        Read-Host "Pressione Enter para sair"
        Stop-Process -Id $PID -Force
    }
}

Write-Host "Iniciando limpeza..." -ForegroundColor Green
Write-Host ""

# ----- 1. LIMPAR PASTA TEMP DO USUARIO (%TEMP%) -----
try {
    Write-Host "1. Limpando pasta TEMP do usuario..." -ForegroundColor Yellow
    $tempPath = [System.IO.Path]::GetTempPath()
    Write-Host "   Local: $tempPath" -ForegroundColor Gray
    
    # Conta arquivos antes
    $before = (Get-ChildItem $tempPath -Recurse -ErrorAction SilentlyContinue | Measure-Object).Count
    Write-Host "   Arquivos encontrados: $before" -ForegroundColor Gray
    
    # Remove arquivos e pastas
    Get-ChildItem $tempPath -Recurse -ErrorAction SilentlyContinue | Remove-Item -Recurse -Force -ErrorAction SilentlyContinue
    
    Write-Host "   Limpeza concluida." -ForegroundColor Green
} catch {
    Write-Host "   Erro ao limpar TEMP: $($_.Exception.Message)" -ForegroundColor Red
}
Write-Host ""

# ----- 2. LIMPAR PASTA TEMP DO WINDOWS (C:\Windows\Temp) -----
try {
    Write-Host "2. Limpando pasta TEMP do Windows..." -ForegroundColor Yellow
    $winTempPath = "$env:SystemRoot\Temp"
    Write-Host "   Local: $winTempPath" -ForegroundColor Gray
    
    if (Test-Path $winTempPath) {
        # Conta arquivos antes
        $before = (Get-ChildItem $winTempPath -Recurse -ErrorAction SilentlyContinue | Measure-Object).Count
        Write-Host "   Arquivos encontrados: $before" -ForegroundColor Gray
        
        # Remove arquivos e pastas
        Get-ChildItem $winTempPath -Recurse -ErrorAction SilentlyContinue | Remove-Item -Recurse -Force -ErrorAction SilentlyContinue
        
        Write-Host "   Limpeza concluida." -ForegroundColor Green
    } else {
        Write-Host "   Pasta nao encontrada." -ForegroundColor Yellow
    }
} catch {
    Write-Host "   Erro ao limpar Windows Temp: $($_.Exception.Message)" -ForegroundColor Red
}
Write-Host ""

# ----- 3. LIMPAR PREFETCH (se administrador) -----
if ($isAdmin) {
    try {
        Write-Host "3. Limpando pasta Prefetch..." -ForegroundColor Yellow
        $prefetchPath = "$env:SystemRoot\Prefetch"
        Write-Host "   Local: $prefetchPath" -ForegroundColor Gray
        
        if (Test-Path $prefetchPath) {
            # Conta arquivos antes
            $before = (Get-ChildItem $prefetchPath -File -ErrorAction SilentlyContinue | Measure-Object).Count
            Write-Host "   Arquivos .pf encontrados: $before" -ForegroundColor Gray
            
            # Remove apenas arquivos .pf (deixa a pasta intacta)
            Get-ChildItem $prefetchPath -Filter "*.pf" -ErrorAction SilentlyContinue | Remove-Item -Force -ErrorAction SilentlyContinue
            
            Write-Host "   Limpeza concluida." -ForegroundColor Green
        } else {
            Write-Host "   Pasta nao encontrada." -ForegroundColor Yellow
        }
    } catch {
        Write-Host "   Erro ao limpar Prefetch: $($_.Exception.Message)" -ForegroundColor Red
    }
} else {
    Write-Host "3. Pasta Prefetch ignorada (necessario administrador)." -ForegroundColor Gray
}
Write-Host ""

# ----- 4. LIMPAR CACHE DE MINIATURAS (thumbcache) -----
try {
    Write-Host "4. Limpando cache de miniaturas..." -ForegroundColor Yellow
    # Para cada usuario, limpa a pasta de thumbcache
    $users = Get-ChildItem "C:\Users" -Directory -ErrorAction SilentlyContinue
    foreach ($user in $users) {
        $thumbPath = "$($user.FullName)\AppData\Local\Microsoft\Windows\Explorer"
        if (Test-Path $thumbPath) {
            Get-ChildItem $thumbPath -Filter "thumbcache_*.db" -ErrorAction SilentlyContinue | Remove-Item -Force -ErrorAction SilentlyContinue
        }
    }
    Write-Host "   Cache de miniaturas limpo." -ForegroundColor Green
} catch {
    Write-Host "   Erro ao limpar thumbcache." -ForegroundColor Red
}
Write-Host ""

# ----- 5. LIMPAR PASTA RECENT (atalhos de documentos recentes) -----
try {
    Write-Host "5. Limpando lista de documentos recentes..." -ForegroundColor Yellow
    $recentPath = "$env:APPDATA\Microsoft\Windows\Recent"
    if (Test-Path $recentPath) {
        Get-ChildItem $recentPath -Recurse -ErrorAction SilentlyContinue | Remove-Item -Recurse -Force -ErrorAction SilentlyContinue
        Write-Host "   Documentos recentes limpos." -ForegroundColor Green
    } else {
        Write-Host "   Pasta nao encontrada." -ForegroundColor Yellow
    }
} catch {
    Write-Host "   Erro ao limpar Recent." -ForegroundColor Red
}
Write-Host ""

Write-Host "=========================================" -ForegroundColor Cyan
Write-Host "         LIMPEZA CONCLUIDA              " -ForegroundColor Cyan
Write-Host "=========================================" -ForegroundColor Cyan
Write-Host ""