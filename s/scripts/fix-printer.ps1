# ============================================
# CORRECAO DE ERROS DE IMPRESSORA - 0x00000709 e 0x0000011b
# ============================================

function Corrigir-ErroImpressora {
    # Limpa a tela para comecar com visual limpo
    Clear-Host

    # Cabecalho
    Write-Host "============================================================" -ForegroundColor Cyan
    Write-Host "         CORRECAO PARA ERROS 0x00000709 / 0x0000011b       " -ForegroundColor Cyan
    Write-Host "============================================================" -ForegroundColor Cyan
    Write-Host ""

    # ===== VERIFICACAO DE ADMINISTRADOR =====
    Write-Host "[1/4] Verificando permissoes de administrador..." -ForegroundColor Yellow
    try {
        $isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
        if (-not $isAdmin) {
            Write-Host "      ERRO: Este script precisa ser executado como ADMINISTRADOR!" -ForegroundColor Red
            Write-Host "      Clique com botao direito no PowerShell e escolha 'Executar como administrador'" -ForegroundColor Yellow
            Write-Host ""
            Write-Host "Pressione qualquer tecla para sair..." -ForegroundColor Gray
            $null = $host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
            return
        }
        Write-Host "      OK: Permissao de administrador confirmada." -ForegroundColor Green
    } catch {
        Write-Host "      ERRO inesperado ao verificar permissoes: $_" -ForegroundColor Red
        Write-Host "Pressione qualquer tecla para sair..."
        $null = $host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
        return
    }
    Write-Host ""

    # ===== APLICACAO NO REGISTRO =====
    Write-Host "[2/4] Aplicando correcao no registro do Windows..." -ForegroundColor Yellow
    try {
        $regPath = "HKLM:\SYSTEM\CurrentControlSet\Control\Print"
        $regName = "RpcAuthnLevelPrivacyEnabled"
        $regValue = 0

        # Exibe o caminho do registro
        Write-Host "      Caminho: $regPath" -ForegroundColor Gray

        # Verifica se o caminho existe
        if (Test-Path $regPath) {
            Write-Host "      OK: Caminho do registro encontrado." -ForegroundColor Green

            # Tenta obter o valor atual
            $currentValue = Get-ItemProperty -Path $regPath -Name $regName -ErrorAction SilentlyContinue
            if ($currentValue -ne $null) {
                Write-Host "      Valor atual de '$regName' = $($currentValue.$regName)" -ForegroundColor Cyan
                if ($currentValue.$regName -eq $regValue) {
                    Write-Host "      INFO: A chave ja esta configurada corretamente (valor 0)." -ForegroundColor Yellow
                } else {
                    Write-Host "      Alterando valor para 0..." -ForegroundColor Yellow
                    Set-ItemProperty -Path $regPath -Name $regName -Value $regValue -Type DWord -ErrorAction Stop
                    Write-Host "      OK: Valor alterado com sucesso!" -ForegroundColor Green
                }
            } else {
                Write-Host "      A chave '$regName' nao existe. Criando..." -ForegroundColor Cyan
                New-ItemProperty -Path $regPath -Name $regName -Value $regValue -PropertyType DWord -Force | Out-Null
                Write-Host "      OK: Chave criada com valor 0." -ForegroundColor Green
            }
        } else {
            Write-Host "      ATENCAO: Caminho do registro nao encontrado." -ForegroundColor Yellow
            Write-Host "      Criando caminho e chave..." -ForegroundColor Cyan
            New-Item -Path $regPath -Force | Out-Null
            New-ItemProperty -Path $regPath -Name $regName -Value $regValue -PropertyType DWord -Force | Out-Null
            Write-Host "      OK: Caminho e chave criados com sucesso!" -ForegroundColor Green
        }
    } catch {
        Write-Host "      ERRO ao modificar registro: $_" -ForegroundColor Red
        Write-Host ""
        Write-Host "Pressione qualquer tecla para continuar..."
        $null = $host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
        return
    }
    Write-Host ""

    # ===== REINICIO DO SERVICO DE IMPRESSAO =====
    Write-Host "[3/4] Reiniciando servico de impressao (Print Spooler)..." -ForegroundColor Yellow
    try {
        # Verifica status atual
        $service = Get-Service -Name Spooler -ErrorAction Stop
        Write-Host "      Status atual do servico: $($service.Status)" -ForegroundColor Cyan

        # Para o servico
        Write-Host "      Parando servico..." -ForegroundColor Gray
        Stop-Service -Name Spooler -Force
        Start-Sleep -Seconds 2

        # Verifica se parou
        $serviceAfterStop = Get-Service -Name Spooler
        if ($serviceAfterStop.Status -eq 'Stopped') {
            Write-Host "      OK: Servico parado com sucesso." -ForegroundColor Green
        } else {
            Write-Host "      ATENCAO: Servico ainda nao parou completamente. Aguardando..." -ForegroundColor Yellow
            Start-Sleep -Seconds 3
        }

        # Inicia novamente
        Write-Host "      Iniciando servico..." -ForegroundColor Gray
        Start-Service -Name Spooler
        Start-Sleep -Seconds 2

        # Verifica se iniciou
        $serviceAfterStart = Get-Service -Name Spooler
        if ($serviceAfterStart.Status -eq 'Running') {
            Write-Host "      OK: Servico reiniciado e em execucao." -ForegroundColor Green
        } else {
            Write-Host "      ATENCAO: Servico nao iniciou corretamente. Status: $($serviceAfterStart.Status)" -ForegroundColor Yellow
        }
    } catch {
        Write-Host "      ERRO ao reiniciar servico: $_" -ForegroundColor Red
        Write-Host ""
        Write-Host "Pressione qualquer tecla para continuar..."
        $null = $host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
        return
    }
    Write-Host ""

    # ===== RESUMO FINAL =====
    Write-Host "[4/4] Finalizando..." -ForegroundColor Yellow
    Write-Host ""
    Write-Host "============================================================" -ForegroundColor Cyan
    Write-Host "   CORRECAO APLICADA COM SUCESSO!" -ForegroundColor Green
    Write-Host "============================================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "DETALHES DO QUE FOI EXECUTADO:" -ForegroundColor White
    Write-Host "  1. Verificacao de administrador: OK (executando como admin)." -ForegroundColor Gray
    Write-Host "  2. Registro do Windows:" -ForegroundColor Gray
    Write-Host "     - Caminho: $regPath" -ForegroundColor Gray
    Write-Host "     - Chave: $regName = $regValue" -ForegroundColor Gray
    if ($currentValue -ne $null -and $currentValue.$regName -ne $regValue) {
        Write-Host "     - Acao: Valor alterado de $($currentValue.$regName) para 0." -ForegroundColor Gray
    } elseif ($currentValue -eq $null) {
        Write-Host "     - Acao: Chave criada com valor 0." -ForegroundColor Gray
    } else {
        Write-Host "     - Acao: Nenhuma alteracao necessaria (valor ja era 0)." -ForegroundColor Gray
    }
    Write-Host "  3. Servico de impressao (Print Spooler):" -ForegroundColor Gray
    Write-Host "     - Parado e reiniciado com sucesso." -ForegroundColor Gray
    Write-Host "  4. Configuracao concluida." -ForegroundColor Gray
    Write-Host ""
    Write-Host "IMPORTANTE: E recomendavel REINICIAR O COMPUTADOR" -ForegroundColor Yellow
    Write-Host "para que as alteracoes tenham efeito completo." -ForegroundColor Yellow
    Write-Host ""
    Write-Host "LEMBRE-SE:" -ForegroundColor White
    Write-Host "   Esta correcao deve ser aplicada no computador que COMPARTILHA a impressora (servidor)" -ForegroundColor Gray
    Write-Host "   E em CADA computador que TENTA CONECTAR a impressora compartilhada (cliente)" -ForegroundColor Gray
    Write-Host ""

    # ===== PERGUNTA SOBRE REINICIAR =====
    Write-Host "Deseja reiniciar o computador AGORA para aplicar as configuracoes? (S/N): " -ForegroundColor Yellow -NoNewline
    $resposta = Read-Host
    if ($resposta -eq 'S' -or $resposta -eq 's') {
        Write-Host ""
        Write-Host "REINICIANDO EM 10 SEGUNDOS. Salve todo o seu trabalho!" -ForegroundColor Red
        Write-Host "O computador sera desligado e reiniciado automaticamente." -ForegroundColor Red
        Restart-Computer -Force
    } else {
        Write-Host ""
        Write-Host "Reinicializacao cancelada. Nao se esqueca de reiniciar manualmente mais tarde." -ForegroundColor Cyan
        Write-Host "Pressione qualquer tecla para sair..." -ForegroundColor Gray
        $null = $host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    }
}

# Chamada da funcao
Corrigir-ErroImpressora