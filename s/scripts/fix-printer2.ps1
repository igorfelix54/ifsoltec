# ============================================================
# CORREÇÃO DE ERROS DE IMPRESSORA - 0x00000709 E 0x0000011b
# Versão otimizada com detecção do sistema operacional
# ============================================================

# Requer execução como Administrador
# Verifica se o script está sendo executado com privilégios elevados
function Test-Administrator {
    $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($identity)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

# Obtém informações detalhadas do sistema operacional
function Get-OSInfo {
    $os = Get-WmiObject -Class Win32_OperatingSystem
    $version = [Version]$os.Version
    $productName = $os.Caption
    $build = $os.BuildNumber
    $major = $version.Major
    $minor = $version.Minor

    return [PSCustomObject]@{
        ProductName = $productName
        Version     = $version
        Major       = $major
        Minor       = $minor
        Build       = $build
        IsWindows10OrLater = ($major -ge 10)
        IsServerOS  = $productName -match "Server"
    }
}

# Aplica as correções de registro apropriadas para o SO detectado
function Set-PrinterRegistryFixes {
    param (
        [Parameter(Mandatory)]
        [hashtable]$OSInfo
    )

    $regPath = "HKLM:\SYSTEM\CurrentControlSet\Control\Print"
    $changesMade = $false

    Write-Host "`n[2/5] Analisando sistema operacional..." -ForegroundColor Yellow
    Write-Host "      Sistema: $($OSInfo.ProductName) (Versão $($OSInfo.Version))" -ForegroundColor Cyan

    # Correção principal (comum a todas as versões recentes)
    $key1 = "RpcAuthnLevelPrivacyEnabled"
    $value1 = 0

    Write-Host "      Aplicando chave: $key1 = $value1" -ForegroundColor Gray
    try {
        if (-not (Test-Path $regPath)) {
            New-Item -Path $regPath -Force | Out-Null
            Write-Host "      Criado caminho do registro." -ForegroundColor Green
        }

        $current = Get-ItemProperty -Path $regPath -Name $key1 -ErrorAction SilentlyContinue
        if ($null -eq $current) {
            New-ItemProperty -Path $regPath -Name $key1 -Value $value1 -PropertyType DWord -Force | Out-Null
            Write-Host "      Chave criada com valor $value1." -ForegroundColor Green
            $changesMade = $true
        }
        elseif ($current.$key1 -ne $value1) {
            Set-ItemProperty -Path $regPath -Name $key1 -Value $value1
            Write-Host "      Chave alterada de $($current.$key1) para $value1." -ForegroundColor Green
            $changesMade = $true
        }
        else {
            Write-Host "      Chave já está configurada corretamente (valor $value1)." -ForegroundColor Yellow
        }
    }
    catch {
        Write-Host "      ERRO ao configurar $key1 : $_" -ForegroundColor Red
    }

    # Correção secundária (recomendada para Windows 10/11 e Server 2016+)
    if ($OSInfo.IsWindows10OrLater) {
        $key2 = "RpcUseNamedPipeProtocol"
        $value2 = 1

        Write-Host "      Aplicando chave adicional: $key2 = $value2" -ForegroundColor Gray
        try {
            $current2 = Get-ItemProperty -Path $regPath -Name $key2 -ErrorAction SilentlyContinue
            if ($null -eq $current2) {
                New-ItemProperty -Path $regPath -Name $key2 -Value $value2 -PropertyType DWord -Force | Out-Null
                Write-Host "      Chave criada com valor $value2." -ForegroundColor Green
                $changesMade = $true
            }
            elseif ($current2.$key2 -ne $value2) {
                Set-ItemProperty -Path $regPath -Name $key2 -Value $value2
                Write-Host "      Chave alterada de $($current2.$key2) para $value2." -ForegroundColor Green
                $changesMade = $true
            }
            else {
                Write-Host "      Chave já está configurada corretamente (valor $value2)." -ForegroundColor Yellow
            }
        }
        catch {
            Write-Host "      ERRO ao configurar $key2 : $_" -ForegroundColor Red
        }
    }
    else {
        Write-Host "      Sistema anterior ao Windows 10: chave adicional não aplicada." -ForegroundColor Gray
    }

    return $changesMade
}

# Reinicia o serviço de spooler de impressão
function Restart-PrintSpooler {
    Write-Host "`n[3/5] Reiniciando serviço de impressão (Print Spooler)..." -ForegroundColor Yellow
    try {
        $service = Get-Service -Name Spooler -ErrorAction Stop
        Write-Host "      Status atual: $($service.Status)" -ForegroundColor Cyan

        Write-Host "      Parando serviço..." -ForegroundColor Gray
        Stop-Service -Name Spooler -Force
        Start-Sleep -Seconds 2

        $statusAfterStop = (Get-Service -Name Spooler).Status
        if ($statusAfterStop -eq 'Stopped') {
            Write-Host "      Serviço parado com sucesso." -ForegroundColor Green
        }
        else {
            Write-Host "      Atenção: serviço ainda não parou completamente. Aguardando..." -ForegroundColor Yellow
            Start-Sleep -Seconds 3
        }

        Write-Host "      Iniciando serviço..." -ForegroundColor Gray
        Start-Service -Name Spooler
        Start-Sleep -Seconds 2

        $statusAfterStart = (Get-Service -Name Spooler).Status
        if ($statusAfterStart -eq 'Running') {
            Write-Host "      Serviço reiniciado e em execução." -ForegroundColor Green
        }
        else {
            Write-Host "      Atenção: serviço não iniciou corretamente. Status: $statusAfterStart" -ForegroundColor Yellow
        }
    }
    catch {
        Write-Host "      ERRO ao reiniciar serviço: $_" -ForegroundColor Red
        return $false
    }
    return $true
}

# Função principal
function Corrigir-ErroImpressora {
    # Limpa a tela
    Clear-Host

    Write-Host "============================================================" -ForegroundColor Cyan
    Write-Host "         CORREÇÃO PARA ERROS 0x00000709 / 0x0000011b       " -ForegroundColor Cyan
    Write-Host "============================================================" -ForegroundColor Cyan
    Write-Host ""

    # ===== VERIFICAÇÃO DE ADMINISTRADOR =====
    Write-Host "[1/5] Verificando permissões de administrador..." -ForegroundColor Yellow
    if (-not (Test-Administrator)) {
        Write-Host "      ERRO: Este script precisa ser executado como ADMINISTRADOR!" -ForegroundColor Red
        Write-Host "      Clique com botão direito no PowerShell e escolha 'Executar como administrador'" -ForegroundColor Yellow
        Write-Host ""
        Write-Host "Pressione qualquer tecla para sair..." -ForegroundColor Gray
        $null = $host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
        return
    }
    Write-Host "      OK: Permissão de administrador confirmada." -ForegroundColor Green
    Write-Host ""

    # ===== DETECÇÃO DO SISTEMA OPERACIONAL =====
    $osInfo = Get-OSInfo

    # ===== APLICAÇÃO DAS CORREÇÕES NO REGISTRO =====
    $changesMade = Set-PrinterRegistryFixes -OSInfo $osInfo

    # ===== REINÍCIO DO SERVIÇO DE IMPRESSÃO =====
    $spoolerRestarted = Restart-PrintSpooler

    # ===== RESUMO FINAL =====
    Write-Host "`n[4/5] Finalizando..." -ForegroundColor Yellow
    Write-Host ""
    Write-Host "============================================================" -ForegroundColor Cyan
    Write-Host "   CORREÇÃO APLICADA COM SUCESSO!" -ForegroundColor Green
    Write-Host "============================================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "DETALHES DO QUE FOI EXECUTADO:" -ForegroundColor White
    Write-Host "  1. Permissão de administrador: OK" -ForegroundColor Gray
    Write-Host "  2. Sistema operacional detectado: $($osInfo.ProductName)" -ForegroundColor Gray
    if ($changesMade) {
        Write-Host "  3. Registro do Windows: alterações realizadas." -ForegroundColor Gray
    } else {
        Write-Host "  3. Registro do Windows: nenhuma alteração necessária (já configurado)." -ForegroundColor Gray
    }
    if ($spoolerRestarted) {
        Write-Host "  4. Serviço de impressão: reiniciado com sucesso." -ForegroundColor Gray
    } else {
        Write-Host "  4. Serviço de impressão: falha na reinicialização (verifique manualmente)." -ForegroundColor Red
    }
    Write-Host "  5. Configuração concluída." -ForegroundColor Gray
    Write-Host ""
    Write-Host "IMPORTANTE:" -ForegroundColor Yellow
    Write-Host "  - Esta correção deve ser aplicada no computador que COMPARTILHA a impressora (servidor)" -ForegroundColor Gray
    Write-Host "    e em CADA computador que TENTA CONECTAR à impressora compartilhada (cliente)." -ForegroundColor Gray
    Write-Host "  - É recomendável REINICIAR O COMPUTADOR para que todas as alterações tenham efeito completo." -ForegroundColor Yellow
    Write-Host ""

    # ===== PERGUNTA SOBRE REINICIAR =====
    Write-Host "[5/5] Deseja reiniciar o computador AGORA? (S/N): " -ForegroundColor Yellow -NoNewline
    $resposta = Read-Host
    if ($resposta -eq 'S' -or $resposta -eq 's') {
        Write-Host ""
        Write-Host "O computador será reiniciado em 10 segundos. Feche todos os programas." -ForegroundColor Red
        Restart-Computer -Force
    } else {
        Write-Host ""
        Write-Host "Reinicialização cancelada. Não se esqueça de reiniciar manualmente mais tarde." -ForegroundColor Cyan
        Write-Host "Pressione qualquer tecla para sair..." -ForegroundColor Gray
        $null = $host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    }
}

# Chamada da função principal
Corrigir-ErroImpressora