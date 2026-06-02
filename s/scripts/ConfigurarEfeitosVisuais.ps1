<#
.SYNOPSIS
    Configura os efeitos visuais do Windows para ativar apenas a suavizacao de fontes (cantos arredondados)
    baseado nas configuracoes reais do sistema.
.NOTES
    Executar com o usuario logado. Nao requer admin, mas precisa de reinicializacao.
#>

# Funcao para mostrar versao do Windows
function Get-WindowsVersion {
    $os = Get-WmiObject Win32_OperatingSystem
    $version = $os.Version
    $product = $os.Caption
    Write-Host "Sistema detectado: $product ($version)" -ForegroundColor Cyan
    return $version
}

# Mostra versao do Windows
Get-WindowsVersion

# 1. Primeiro, vamos garantir que o modo esta como "Personalizado"
Write-Host "`nConfigurando modo Personalizado..." -ForegroundColor Yellow
$visualEffectsPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects"
if (-not (Test-Path $visualEffectsPath)) {
    New-Item -Path $visualEffectsPath -Force | Out-Null
}
Set-ItemProperty -Path $visualEffectsPath -Name "VisualFXSetting" -Value 0 -Type DWord -Force
Write-Host "  Modo Personalizado ativado (VisualFXSetting = 0)" -ForegroundColor Green

# 2. Lista completa de configuracoes baseada em sistemas Windows reais
Write-Host "`nDesativando todos os efeitos visuais (exceto suavizacao de fontes)..." -ForegroundColor Yellow

# Configuracoes no Control Panel\Desktop
$desktopPath = "HKCU:\Control Panel\Desktop"
$configs = @(
    @{Path=$desktopPath; Name="UserPreferencesMask"; Value=([byte[]]@(0x90,0x12,0x03,0x80,0x10,0x00,0x00,0x00)); Type="Binary"},
    @{Path=$desktopPath; Name="MenuShowDelay"; Value=400; Type="String"},
    @{Path=$desktopPath; Name="MinAnimate"; Value=0; Type="DWord"},
    @{Path=$desktopPath; Name="ComboBoxAnimation"; Value=0; Type="DWord"},
    @{Path=$desktopPath; Name="DragFullWindows"; Value=0; Type="DWord"},
    @{Path=$desktopPath; Name="FontSmoothing"; Value="2"; Type="String"},  # Esta eh a que queremos ATIVADA
    @{Path=$desktopPath; Name="ListviewAlphaSelect"; Value=0; Type="DWord"},
    @{Path=$desktopPath; Name="ListviewShadow"; Value=0; Type="DWord"},
    @{Path=$desktopPath; Name="TaskbarAnimations"; Value=0; Type="DWord"},
    @{Path="HKCU:\Control Panel\Desktop\WindowMetrics"; Name="MinAnimate"; Value=0; Type="DWord"}
)

foreach ($cfg in $configs) {
    try {
        if (-not (Test-Path $cfg.Path)) {
            New-Item -Path $cfg.Path -Force | Out-Null
        }
        
        if ($cfg.Type -eq "Binary") {
            Set-ItemProperty -Path $cfg.Path -Name $cfg.Name -Value $cfg.Value -Type Binary -Force
        } elseif ($cfg.Type -eq "DWord") {
            Set-ItemProperty -Path $cfg.Path -Name $cfg.Name -Value $cfg.Value -Type DWord -Force
        } else {
            Set-ItemProperty -Path $cfg.Path -Name $cfg.Name -Value $cfg.Value -Type String -Force
        }
        Write-Host "  OK: $($cfg.Path)\$($cfg.Name)" -ForegroundColor Gray
    } catch {
        Write-Warning "  Falha em $($cfg.Path)\$($cfg.Name): $_"
    }
}

# 3. Configuracoes no Explorer\Advanced
$explorerAdvancedPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced"
$advancedConfigs = @(
    @{Path=$explorerAdvancedPath; Name="EnableBalloonTips"; Value=0; Type="DWord"},
    @{Path=$explorerAdvancedPath; Name="EnableComboboxAnimation"; Value=0; Type="DWord"},
    @{Path=$explorerAdvancedPath; Name="EnableCursorShadow"; Value=0; Type="DWord"},
    @{Path=$explorerAdvancedPath; Name="EnableListViewAnimation"; Value=0; Type="DWord"},
    @{Path=$explorerAdvancedPath; Name="EnableMenuAnimation"; Value=0; Type="DWord"},
    @{Path=$explorerAdvancedPath; Name="EnableSelectionFade"; Value=0; Type="DWord"},
    @{Path=$explorerAdvancedPath; Name="EnableTooltipAnimation"; Value=0; Type="DWord"},
    @{Path=$explorerAdvancedPath; Name="TaskbarAnimations"; Value=0; Type="DWord"},
    @{Path=$explorerAdvancedPath; Name="ShowShadows"; Value=0; Type="DWord"}
)

foreach ($cfg in $advancedConfigs) {
    try {
        Set-ItemProperty -Path $cfg.Path -Name $cfg.Name -Value $cfg.Value -Type $cfg.Type -Force -ErrorAction SilentlyContinue
        Write-Host "  OK: $($cfg.Path)\$($cfg.Name)" -ForegroundColor Gray
    } catch {
        # Algumas chaves podem nao existir, ignoramos
    }
}

# 4. Configuracoes de transparencia
$themesPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize"
try {
    Set-ItemProperty -Path $themesPath -Name "EnableTransparency" -Value 0 -Type DWord -Force
    Write-Host "  OK: $themesPath\EnableTransparency" -ForegroundColor Gray
} catch {}

# 5. Confirmar que a suavizacao de fontes esta ATIVADA
Write-Host "`nAtivando suavizacao de fontes (cantos arredondados)..." -ForegroundColor Green
try {
    # FontSmoothing = 2 ativa suavizacao
    Set-ItemProperty -Path $desktopPath -Name "FontSmoothing" -Value "2" -Type String -Force
    
    # FontSmoothingType: 1 = Standard (cantos arredondados), 2 = ClearType
    Set-ItemProperty -Path $desktopPath -Name "FontSmoothingType" -Value 1 -Type DWord -Force
    
    Write-Host "  OK: Suavizacao de fontes ativada (tipo Standard)" -ForegroundColor Green
} catch {
    Write-Warning "Falha ao ativar suavizacao de fontes: $_"
}

# 6. Forcar atualizacao das configuracoes
Write-Host "`nForcando atualizacao do sistema..." -ForegroundColor Yellow
try {
    # Metodo 1: UpdatePerUserSystemParameters
    $null = rundll32.exe user32.dll, UpdatePerUserSystemParameters
    
    # Metodo 2: Reiniciar explorer (mais agressivo)
    # taskkill /f /im explorer.exe > $null 2>&1
    # start explorer.exe
    
    Write-Host "  Atualizacao solicitada" -ForegroundColor Green
} catch {
    Write-Warning "Nao foi possivel forcar atualizacao automatica"
}

# 7. Funcao para verificar o resultado
function Check-CurrentSettings {
    Write-Host "`n--- VERIFICACAO DAS CONFIGURACOES ATUAIS ---" -ForegroundColor Cyan
    
    $checkDesktop = Get-ItemProperty -Path $desktopPath -ErrorAction SilentlyContinue
    
    if ($checkDesktop.FontSmoothing -eq "2") {
        Write-Host "Suavizacao de fontes: ATIVADA" -ForegroundColor Green
    } else {
        Write-Host "Suavizacao de fontes: DESATIVADA (valor: $($checkDesktop.FontSmoothing))" -ForegroundColor Red
    }
    
    Write-Host "`nPara verificar manualmente:" -ForegroundColor Yellow
    Write-Host "1. Abra o Painel de Controle" -ForegroundColor White
    Write-Host "2. Sistema > Configuracoes avancadas do sistema" -ForegroundColor White
    Write-Host "3. Aba Avancado > Desempenho > Configuracoes" -ForegroundColor White
    Write-Host "4. Verifique se apenas 'Usar fontes de tela com cantos arredondados' esta marcado" -ForegroundColor White
}

Check-CurrentSettings

Write-Host "`nIMPORTANTE: " -ForegroundColor Red -NoNewline
Write-Host "Pode ser necessario reiniciar o computador ou fazer logoff/logon para que todas as alteracoes tenham efeito." -ForegroundColor Yellow
Write-Host "Apos reiniciar, execute novamente a verificacao para confirmar." -ForegroundColor Yellow