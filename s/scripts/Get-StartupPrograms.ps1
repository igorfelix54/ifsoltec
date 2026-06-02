<#
.SINOPSE
    Lista todos os aplicativos configurados para iniciar com o Windows,
    incluindo os desativados, e exibe Nome, Comando e Status (Ativado/Desativado).

.DESCRIÇÃO
    O script consulta:
      - Chaves do registro: Run e RunOnce (HKLM e HKCU)
      - Pastas de inicialização do usuário atual e de todos os usuários
    Para cada item encontrado, verifica se ele foi desabilitado via Gerenciador de Tarefas
    consultando as chaves "StartupApproved" no registro do usuário.
    O resultado é exibido em formato de tabela com as colunas: Nome, Comando, Status.

.NOTAS
    Autor: [Seu nome]
    Requer: PowerShell com privilégios de administrador (para acessar pastas de todos os usuários)
#>

#requires -RunAsAdministrator

# Função para decodificar o status a partir do valor binário do StartupApproved
function Get-StartupApprovedStatus {
    param (
        [string]$ItemName,
        [string]$Source   # "Run" ou "StartupFolder" – usado internamente para localizar a chave correta
    )

    # Caminhos onde o Windows armazena o estado dos itens de inicialização
    $approvedPaths = @(
        "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\StartupApproved\Run",
        "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\StartupApproved\StartupFolder"
    )

    # Determina qual caminho verificar baseado na origem
    $checkPath = if ($Source -eq "StartupFolder") {
        $approvedPaths[1]  # StartupFolder
    } else {
        $approvedPaths[0]  # Run (registro)
    }

    if (Test-Path $checkPath) {
        $value = Get-ItemProperty -Path $checkPath -Name $ItemName -ErrorAction SilentlyContinue
        if ($value -and $value.$ItemName) {
            $bytes = $value.$ItemName
            # O primeiro byte indica o estado: 0x02 = habilitado, 0x03 = desabilitado
            if ($bytes[0] -eq 2) {
                return "Ativado"
            } elseif ($bytes[0] -eq 3) {
                return "Desativado"
            }
        }
    }
    # Se não houver entrada em StartupApproved, assume-se ativado (padrão)
    return "Ativado"
}

# Função para adicionar um item à lista de resultados (agora sem incluir a origem na saída)
function Add-StartupItem {
    param (
        [string]$Name,
        [string]$Command,
        [string]$Location,      # Usado apenas internamente para determinar o tipo de origem no status
        [string]$SourceType     # "Run" ou "StartupFolder" – usado na função de status
    )

    $status = Get-StartupApprovedStatus -ItemName $Name -Source $SourceType

    $global:results += [PSCustomObject]@{
        Nome    = $Name
        
        Status  = $status
    }
}

# Limpa resultados anteriores
$global:results = @()

Write-Host "Coletando aplicativos de inicializacao..." -ForegroundColor Cyan

# -----------------------------------------------------------------
# 1. Registro do computador local (HKLM) - para todos os usuários
# -----------------------------------------------------------------
$registryPaths = @(
    "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run",
    "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\RunOnce",
    "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Run",           # Para aplicativos 32 bits em sistemas 64 bits
    "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\RunOnce"
)

foreach ($path in $registryPaths) {
    if (Test-Path $path) {
        $items = Get-ItemProperty -Path $path
        $items.PSObject.Properties | Where-Object { $_.Name -notin @('PSPath','PSParentPath','PSChildName','PSDrive','PSProvider') } | ForEach-Object {
            Add-StartupItem -Name $_.Name -Command $_.Value -Location $path -SourceType "Run"
        }
    }
}

# -----------------------------------------------------------------
# 2. Registro do usuário atual (HKCU)
# -----------------------------------------------------------------
$userRegistryPaths = @(
    "HKCU:\Software\Microsoft\Windows\CurrentVersion\Run",
    "HKCU:\Software\Microsoft\Windows\CurrentVersion\RunOnce"
)

foreach ($path in $userRegistryPaths) {
    if (Test-Path $path) {
        $items = Get-ItemProperty -Path $path
        $items.PSObject.Properties | Where-Object { $_.Name -notin @('PSPath','PSParentPath','PSChildName','PSDrive','PSProvider') } | ForEach-Object {
            Add-StartupItem -Name $_.Name -Command $_.Value -Location $path -SourceType "Run"
        }
    }
}

# -----------------------------------------------------------------
# 3. Pasta de inicialização do usuário atual
# -----------------------------------------------------------------
$currentUserStartup = "$env:APPDATA\Microsoft\Windows\Start Menu\Programs\Startup"
if (Test-Path $currentUserStartup) {
    Get-ChildItem -Path $currentUserStartup -Filter *.lnk -File | ForEach-Object {
        # Para atalhos, obtemos o nome e o caminho do executável
        $shell = New-Object -ComObject WScript.Shell
        $shortcut = $shell.CreateShortcut($_.FullName)
        $target = $shortcut.TargetPath
        [System.Runtime.Interopservices.Marshal]::ReleaseComObject($shell) | Out-Null

        Add-StartupItem -Name $_.BaseName -Command $target -Location $currentUserStartup -SourceType "StartupFolder"
    }
}

# -----------------------------------------------------------------
# 4. Pasta de inicialização de todos os usuários (requer admin)
# -----------------------------------------------------------------
$allUsersStartup = "$env:ProgramData\Microsoft\Windows\Start Menu\Programs\StartUp"
if (Test-Path $allUsersStartup) {
    Get-ChildItem -Path $allUsersStartup -Filter *.lnk -File | ForEach-Object {
        $shell = New-Object -ComObject WScript.Shell
        $shortcut = $shell.CreateShortcut($_.FullName)
        $target = $shortcut.TargetPath
        [System.Runtime.Interopservices.Marshal]::ReleaseComObject($shell) | Out-Null

        Add-StartupItem -Name $_.BaseName -Command $target -Location $allUsersStartup -SourceType "StartupFolder"
    }
}

# -----------------------------------------------------------------
# Exibição dos resultados (apenas Nome, Comando e Status)
# -----------------------------------------------------------------
Write-Host "`nAplicativos de inicializacao encontrados:" -ForegroundColor Green
$results | Sort-Object Status, Nome | Format-Table -AutoSize

# Opcional: exportar para CSV
# $results | Export-Csv -Path "$env:USERPROFILE\Desktop\startup_apps.csv" -Encoding UTF8 -NoTypeInformation