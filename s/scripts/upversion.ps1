# ============================================
# ALTERAR EDICAO DO WINDOWS - HOME/PRO/ENTERPRISE
# ============================================

Write-Host "=========================================" -ForegroundColor Cyan
Write-Host "      ALTERAR EDICAO DO WINDOWS         " -ForegroundColor Cyan
Write-Host "=========================================" -ForegroundColor Cyan
Write-Host ""

# Verifica se está sendo executado como Administrador
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    Write-Host "ATENCAO: Este script precisa de privilegios de Administrador." -ForegroundColor Red
    Write-Host "Execute o PowerShell como Administrador e tente novamente." -ForegroundColor Yellow
    Write-Host ""
    Read-Host "Pressione Enter para sair"
    Stop-Process -Id $PID -Force
}

# ========== DETECTA EDICAO ATUAL ==========
try {
    $edicaoAtual = (Get-WmiObject -Class Win32_OperatingSystem).Caption
    Write-Host "Edicao atual detectada: $edicaoAtual" -ForegroundColor Green
} catch {
    Write-Host "Nao foi possivel detectar a edicao atual." -ForegroundColor Yellow
}
Write-Host ""

# ========== CHAVES GENERICAS PARA UPGRADE ==========
# Fonte: Microsoft Docs e comunidade [citation:1][citation:2][citation:6]
$chaves = @{
    "Pro" = "VK7JG-NPHTM-C97JM-9MPGT-3V66T"
    "Pro Workstation" = "DXG7C-N36C4-C4HTG-X4T3X-2YV77"
    "Pro Education" = "8PTT6-RNW4C-6V7J2-C2D3X-MHBPB"
    "Education" = "YNMGQ-8RYV3-4PGQ3-C8XTP-7CFBY"
    "Enterprise" = "XGVPP-NMH47-7TTHJ-W3FW7-8HV2C"
    "Enterprise LTSC" = "M7XTQ-FN8P6-TTKYV-9D4CC-J462D"
}

# ========== MENU PRINCIPAL ==========
function Show-Menu {
    Write-Host "Escolha a edicao desejada:" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "  [1] Windows Pro (Profissional)" -ForegroundColor White
    Write-Host "  [2] Windows Pro Workstation" -ForegroundColor White
    Write-Host "  [3] Windows Pro Education" -ForegroundColor White
    Write-Host "  [4] Windows Education" -ForegroundColor White
    Write-Host "  [5] Windows Enterprise" -ForegroundColor White
    Write-Host "  [6] Windows Enterprise LTSC" -ForegroundColor White
    Write-Host "  [0] Sair" -ForegroundColor Red
    Write-Host ""
    Write-Host "Aperte o numero desejado (sem Enter)..." -ForegroundColor Gray
}

# ========== FUNCAO PARA TROCAR EDICAO ==========
function Set-WindowsEdition {
    param([string]$Edicao)

    $chave = $chaves[$Edicao]
    if (-not $chave) {
        Write-Host "Erro: Chave nao encontrada para edicao $Edicao" -ForegroundColor Red
        return
    }

    Write-Host ""
    Write-Host "Trocando para Windows $Edicao..." -ForegroundColor Cyan
    Write-Host "Usando chave: $chave" -ForegroundColor Gray
    Write-Host ""

    # Metodo 1: changepk.exe (recomendado pela Microsoft) [citation:1][citation:6]
    try {
        Write-Host "Iniciando upgrade via changepk.exe..." -ForegroundColor Yellow
        Start-Process -FilePath "changepk.exe" -ArgumentList "/ProductKey $chave" -Wait -NoNewWindow
        
        Write-Host ""
        Write-Host "Processo concluido!" -ForegroundColor Green
        Write-Host "O Windows pode solicitar uma reinicializacao para concluir a alteracao." -ForegroundColor Yellow
        Write-Host ""
        Write-Host "APOS REINICIAR:" -ForegroundColor Cyan
        Write-Host "1. O Windows estara na nova edicao, mas pode nao estar ativado" -ForegroundColor White
        Write-Host "2. Para ativar, voce precisa de uma chave de licenca valida" -ForegroundColor White
        Write-Host "3. Va em Configuracoes > Sistema > Ativacao e insira sua chave" -ForegroundColor White
        Write-Host ""
        Write-Host "NOTA: Esta chave e apenas para upgrade, nao para ativacao [citation:8]" -ForegroundColor Gray
    }
    catch {
        Write-Host "Erro ao executar changepk.exe: $($_.Exception.Message)" -ForegroundColor Red
        
        # Metodo alternativo: slmgr [citation:2][citation:10]
        Write-Host ""
        Write-Host "Tentando metodo alternativo via slmgr..." -ForegroundColor Yellow
        try {
            & "cscript.exe" "C:\Windows\System32\slmgr.vbs" "/ipk" $chave
            Write-Host "Chave instalada. Verifique a ativacao em Configuracoes." -ForegroundColor Green
        }
        catch {
            Write-Host "Ambos os metodos falharam." -ForegroundColor Red
        }
    }
}

# ========== LOOP PRINCIPAL ==========
do {
    Show-Menu
    $key = $host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    $opcao = $key.Character.ToString()

    switch ($opcao) {
        "1" { Set-WindowsEdition -Edicao "Pro" }
        "2" { Set-WindowsEdition -Edicao "Pro Workstation" }
        "3" { Set-WindowsEdition -Edicao "Pro Education" }
        "4" { Set-WindowsEdition -Edicao "Education" }
        "5" { Set-WindowsEdition -Edicao "Enterprise" }
        "6" { Set-WindowsEdition -Edicao "Enterprise LTSC" }
        "0" { 
            Write-Host "`nSaindo... Ate logo!" -ForegroundColor Magenta
            
            
        }
        default {
            Write-Host "`nOpcao invalida!" -ForegroundColor Red
            Start-Sleep -Seconds 1
        }
    }

    if ($opcao -ne "0") {
        Write-Host ""
        Read-Host "Pressione Enter para voltar ao menu"
    }

} while ($opcao -ne "0")
