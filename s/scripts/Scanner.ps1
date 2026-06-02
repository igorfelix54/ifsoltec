#Requires -Version 5.1

<#
.SYNOPSIS
    Executa o Microsoft Safety Scanner, coleta os resultados e opcionalmente salva em um arquivo.
.DESCRIPTION
    Este script baixa a versão mais recente do Microsoft Safety Scanner, executa uma varredura
    (rápida ou completa) e exibe os resultados. Requer privilégios de administrador.
.EXAMPLE
    .\Script-SafetyScanner.ps1 -ScanType "Quick" -Timeout 30
.NOTES
    Autor: Adaptado de NinjaOne Script Hub
    Fonte original: https://www.ninjaone.com/script-hub/automate-microsoft-safety-scanner/
#>

[CmdletBinding()]
param (
    [Parameter()]
    [ValidateSet("Quick", "Full")]
    [String]$ScanType = "Quick",  # Tipo de varredura: Rápida ou Completa

    [Parameter()]
    [Int]$Timeout = 30,  # Tempo máximo em minutos (entre 1 e 119)

    [Parameter()]
    [String]$DownloadURL = "https://go.microsoft.com/fwlink/?LinkId=212732"  # URL oficial do Safety Scanner
)

begin {
    # Validação do timeout
    if ($Timeout -lt 1 -or $Timeout -ge 120) {
        Write-Host "[Erro] O tempo limite deve ser entre 1 e 119 minutos."
        exit 1
    }

    # Verifica se é administrador
    function Test-IsElevated {
        $id = [System.Security.Principal.WindowsIdentity]::GetCurrent()
        $p = New-Object System.Security.Principal.WindowsPrincipal($id)
        return $p.IsInRole([System.Security.Principal.WindowsBuiltInRole]::Administrator)
    }

    if (-not (Test-IsElevated)) {
        Write-Host "[Erro] Este script precisa ser executado como Administrador." -ForegroundColor Red
        exit 1
    }

    # Define caminhos temporários
    $TempDir = [System.IO.Path]::GetTempPath()
    $ScannerName = "MSERT.exe"
    $ScannerPath = Join-Path $TempDir $ScannerName
    $LogDir = Join-Path $env:TEMP "SafetyScannerLogs"
    $OutputFile = Join-Path $LogDir "ScanResult_$(Get-Date -Format 'yyyyMMdd_HHmmss').txt"

    # Cria diretório de logs se não existir
    if (-not (Test-Path $LogDir)) {
        New-Item -ItemType Directory -Path $LogDir -Force | Out-Null
    }
}

process {
    try {
        # 1. Download do Safety Scanner
        Write-Host "Baixando Microsoft Safety Scanner de:" -ForegroundColor Cyan
        Write-Host $DownloadURL
        Write-Host "Aguardando alguns segundos para iniciar o download..."

        Start-Sleep -Seconds 3

        # Configura TLS para download seguro
        [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol::Tls12 -bor [System.Net.ServicePointManager]::SecurityProtocol::Tls13

        Write-Host "Fazendo download... (pode levar alguns minutos)" -ForegroundColor Yellow
        $ProgressPreference = 'SilentlyContinue'  # Acelera o download
        Invoke-WebRequest -Uri $DownloadURL -OutFile $ScannerPath -UseBasicParsing
        $ProgressPreference = 'Continue'

        if (Test-Path $ScannerPath) {
            Write-Host "Download concluído com sucesso!" -ForegroundColor Green
        } else {
            throw "Falha no download do arquivo."
        }

        # 2. Executar varredura
        Write-Host "`nIniciando varredura $ScanType..." -ForegroundColor Cyan
        Write-Host "Isso pode levar vários minutos. A janela do scanner será oculta."
        Write-Host "Resultados serão salvos em: $OutputFile`n"

        # Prepara argumentos: /Q = modo silencioso (sem interface), /F:Y = forçar encerramento de processos se necessário
        $Arguments = @(
            "/Q",                       # Quiet mode (sem interface gráfica)
            "/F:Y",                     # Força desligamento de processos
            "/$ScanType",                # Tipo de varredura
            "/log:`"$OutputFile`""       # Arquivo de log
        )

        # Executa o scanner com limite de tempo
        $Process = Start-Process -FilePath $ScannerPath -ArgumentList $Arguments -Wait -PassThru -NoNewWindow

        # 3. Exibir resultados
        Write-Host "`nVarredura concluída. Código de saída: $($Process.ExitCode)" -ForegroundColor Green

        # Interpreta o código de saída
        switch ($Process.ExitCode) {
            0 { Write-Host "Nenhuma infecção encontrada." -ForegroundColor Green }
            2 { Write-Host "Infecções encontradas e removidas com sucesso." -ForegroundColor Yellow }
            3 { Write-Host "Infecções encontradas, algumas pendentes de ação (reinicialização necessária)." -ForegroundColor Yellow }
            5 { Write-Host "Infecções encontradas, algumas NÃO removidas." -ForegroundColor Red }
            7 { Write-Host "Infecções encontradas, algumas removidas, outras pendentes." -ForegroundColor Red }
            8 { Write-Host "Falha na varredura." -ForegroundColor Red }
            default { Write-Host "Código desconhecido. Consulte o log para detalhes." }
        }

        # Exibe o caminho do log
        Write-Host "`nLog detalhado disponível em: $OutputFile"

        # Se houver resultados, exibe as primeiras linhas
        if (Test-Path $OutputFile) {
            Write-Host "`nPrimeiras linhas do resultado:" -ForegroundColor Cyan
            Get-Content $OutputFile -TotalCount 15
        }

    } catch {
        Write-Host "[Erro] Ocorreu um problema durante a execução:" -ForegroundColor Red
        Write-Host $_.Exception.Message -ForegroundColor Red
        exit 1
    } finally {
        # Limpeza opcional: remover o scanner após uso (comentado por segurança)
        # if (Test-Path $ScannerPath) {
        #     Remove-Item $ScannerPath -Force -ErrorAction SilentlyContinue
        # }
    }
}

end {
    Write-Host "`nScript finalizado." -ForegroundColor Cyan
}