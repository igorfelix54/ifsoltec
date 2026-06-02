# ============================================
# DIAGNOSTICO DO PC - INFORMACOES DO SISTEMA
# ============================================

Write-Host "=========================================" -ForegroundColor Cyan
Write-Host "         DIAGNOSTICO DO PC              " -ForegroundColor Cyan
Write-Host "=========================================" -ForegroundColor Cyan
Write-Host ""

# ========== FUNCAO: OBTER VRAM REAL DO REGISTRO ==========
function Get-RealVRAM {
    param([string]$PNPDeviceID)
    
    try {
        # Extrai os primeiros identificadores do PNPDeviceID (ex: PCI\VEN_10DE&DEV_1C03)
        if ($PNPDeviceID -match '(PCI\\VEN_[0-9A-F]+&DEV_[0-9A-F]+)') {
            $devIdPrefix = $matches[1]
        } else {
            return $null
        }
        
        # Caminho do registro onde as informacoes reais da GPU estao
        $regPath = "HKLM:\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}"
        
        # Procura em todas as subpastas (0*, 1*, etc.) por MatchingDeviceId correspondente
        $gpuKeys = Get-ChildItem $regPath -ErrorAction SilentlyContinue | Where-Object { $_.PSChildName -match '^\d+' }
        
        foreach ($key in $gpuKeys) {
            $matchingId = (Get-ItemProperty -Path $key.PSPath -Name "MatchingDeviceId" -ErrorAction SilentlyContinue).MatchingDeviceId
            if ($matchingId -like "$devIdPrefix*") {
                # Encontrou a chave correta! Agora pega o tamanho real da memoria
                $vramBytes = (Get-ItemProperty -Path $key.PSPath -Name "HardwareInformation.qwMemorySize" -ErrorAction SilentlyContinue).'HardwareInformation.qwMemorySize'
                if ($vramBytes) {
                    return [math]::Round($vramBytes / 1GB, 2)
                }
            }
        }
    } catch {
        # Falhou, retorna nulo
    }
    return $null
}

# ----- SISTEMA OPERACIONAL -----
try {
    $os = Get-WmiObject Win32_OperatingSystem
    $osName = $os.Caption
    $osVersion = $os.Version
    $osBuild = $os.BuildNumber
    $osArch = $os.OSArchitecture
    Write-Host "SISTEMA OPERACIONAL:" -ForegroundColor Yellow
    Write-Host "  Nome..: $osName" -ForegroundColor White
    Write-Host "  Versao: $osVersion (Build $osBuild)" -ForegroundColor White
    Write-Host "  Arquitetura: $osArch" -ForegroundColor White
} catch {
    Write-Host "SISTEMA OPERACIONAL: Nao foi possivel obter informacoes" -ForegroundColor Red
}
Write-Host ""

# ----- COMPUTADOR E USUARIO -----
try {
    $computerSystem = Get-WmiObject Win32_ComputerSystem
    $computerName = $computerSystem.Name
    $userName = $env:USERNAME
    $domain = $computerSystem.Domain
    Write-Host "COMPUTADOR:" -ForegroundColor Yellow
    Write-Host "  Nome.: $computerName" -ForegroundColor White
    Write-Host "  Usuario: $userName" -ForegroundColor White
    Write-Host "  Dominio: $domain" -ForegroundColor White
} catch {
    Write-Host "COMPUTADOR: Nao foi possivel obter informacoes" -ForegroundColor Red
}
Write-Host ""

# ----- PROCESSADOR -----
try {
    $cpu = Get-WmiObject Win32_Processor | Select-Object -First 1
    $cpuName = $cpu.Name.Trim()
    $cores = $cpu.NumberOfCores
    $logical = $cpu.NumberOfLogicalProcessors
    $maxClock = [math]::Round($cpu.MaxClockSpeed / 1000, 2)
    Write-Host "PROCESSADOR:" -ForegroundColor Yellow
    Write-Host "  Modelo.: $cpuName" -ForegroundColor White
    Write-Host "  Nucleos.: $cores fisicos, $logical logicos" -ForegroundColor White
    Write-Host "  Clock Max: $maxClock GHz" -ForegroundColor White
} catch {
    Write-Host "PROCESSADOR: Nao foi possivel obter informacoes" -ForegroundColor Red
}
Write-Host ""

# ----- MEMORIA RAM -----
try {
    $memory = Get-WmiObject Win32_ComputerSystem
    $totalRAM = [math]::Round($memory.TotalPhysicalMemory / 1GB, 2)
    $availableRAM = [math]::Round((Get-WmiObject Win32_OperatingSystem).FreePhysicalMemory / 1MB, 2)
    $usedRAM = $totalRAM - $availableRAM
    $percentUsed = [math]::Round(($usedRAM / $totalRAM) * 100, 1)
    Write-Host "MEMORIA RAM:" -ForegroundColor Yellow
    Write-Host "  Total....: $totalRAM GB" -ForegroundColor White
    Write-Host "  Em uso...: $usedRAM GB" -ForegroundColor White
    Write-Host "  Disponivel: $availableRAM GB" -ForegroundColor White
    Write-Host "  Utilizacao: $percentUsed%" -ForegroundColor White
} catch {
    Write-Host "MEMORIA RAM: Nao foi possivel obter informacoes" -ForegroundColor Red
}
Write-Host ""

# ----- DISCO RIGIDO -----
try {
    Write-Host "DISCO RIGIDO:" -ForegroundColor Yellow
    $disks = Get-WmiObject Win32_LogicalDisk -Filter "DriveType=3"
    foreach ($disk in $disks) {
        $size = [math]::Round($disk.Size / 1GB, 2)
        $free = [math]::Round($disk.FreeSpace / 1GB, 2)
        $used = $size - $free
        $percentFree = [math]::Round(($free / $size) * 100, 1)
        Write-Host "  $($disk.DeviceID) - Total: $size GB, Livre: $free GB ($percentFree%)" -ForegroundColor White
    }
} catch {
    Write-Host "DISCO RIGIDO: Nao foi possivel obter informacoes" -ForegroundColor Red
}
Write-Host ""

# ----- UPTIME (tempo ligado) -----
try {
    $os = Get-WmiObject Win32_OperatingSystem
    $uptime = (Get-Date) - $os.ConvertToDateTime($os.LastBootUpTime)
    Write-Host "UPTIME:" -ForegroundColor Yellow
    Write-Host "  Ligado ha: $($uptime.Days) dias, $($uptime.Hours) horas, $($uptime.Minutes) minutos" -ForegroundColor White
} catch {
    Write-Host "UPTIME: Nao foi possivel obter informacoes" -ForegroundColor Red
}
Write-Host ""

# ----- REDE (IP) -----
try {
    $ip = (Get-NetIPAddress -AddressFamily IPv4 | Where-Object { $_.InterfaceAlias -notlike "*Loopback*" -and $_.PrefixOrigin -ne "WellKnown" } | Select-Object -First 1).IPAddress
    if (-not $ip) { $ip = "Nao identificado" }
    Write-Host "REDE:" -ForegroundColor Yellow
    Write-Host "  IP Local: $ip" -ForegroundColor White
} catch {
    Write-Host "REDE: Nao foi possivel obter o IP" -ForegroundColor Red
}
Write-Host ""

# ----- PLACA DE VIDEO COM VRAM CORRIGIDA -----
try {
    Write-Host "PLACA DE VIDEO:" -ForegroundColor Yellow
    $gpus = Get-WmiObject Win32_VideoController
    
    foreach ($gpu in $gpus) {
        $gpuName = $gpu.Name
        $pnpId = $gpu.PNPDeviceID
        $gpuRAM_WMI = [math]::Round($gpu.AdapterRAM / 1GB, 2)
        
        # Tenta obter o valor REAL do registro
        $gpuRAM_Real = Get-RealVRAM -PNPDeviceID $pnpId
        
        # Decide qual valor usar
        if ($gpuRAM_Real -and $gpuRAM_Real -gt $gpuRAM_WMI) {
            $vramExibida = $gpuRAM_Real
            $fonte = "Registro"
        } else {
            $vramExibida = $gpuRAM_WMI
            $fonte = "WMI"
        }
        
        $gpuType = if ($gpuName -match "NVIDIA|GeForce|RTX|GTX|Quadro|AMD|Radeon|RX|R9|R7") { 
            "Dedicada" 
        } else { 
            "Integrada" 
        }
        
        Write-Host "  Modelo.: $gpuName" -ForegroundColor White
        Write-Host "  Tipo...: $gpuType" -ForegroundColor White
        Write-Host "  Memoria: $vramExibida GB (fonte: $fonte)" -ForegroundColor White
        
        # Fallback para nvidia-smi (mais preciso para NVIDIA)
        if ($gpuName -match "NVIDIA|GeForce|RTX|GTX") {
            try {
                $nvidiaSmi = & nvidia-smi --query-gpu=memory.total --format=csv,noheader,nounits 2>$null
                if ($nvidiaSmi) {
                    Write-Host "  (nvidia-smi: $([math]::Round([double]$nvidiaSmi[0] / 1024, 2)) GB)" -ForegroundColor Gray
                }
            } catch {}
        }
        Write-Host ""
    }
} catch {
    Write-Host "PLACA DE VIDEO: Nao foi possivel obter informacoes" -ForegroundColor Red
}

# ----- BATERIA (se for notebook) -----
try {
    $battery = Get-WmiObject Win32_Battery
    if ($battery) {
        $batteryStatus = switch ($battery.BatteryStatus) {
            1 { "Carregando" }
            2 { "Conectado (com energia)" }
            3 { "Descarregando" }
            4 { "Carregando" }
            5 { "Baixo" }
            6 { "Critico" }
            7 { "Em falha" }
            8 { "Carregando" }
            default { "Desconhecido" }
        }
        $estimatedChargeRemaining = $battery.EstimatedChargeRemaining
        Write-Host "BATERIA:" -ForegroundColor Yellow
        Write-Host "  Status: $batteryStatus" -ForegroundColor White
        Write-Host "  Carga: $estimatedChargeRemaining%" -ForegroundColor White
    } else {
        Write-Host "BATERIA: Nao detectada (possivelmente desktop)" -ForegroundColor Gray
    }
} catch {
    Write-Host "BATERIA: Nao foi possivel obter informacoes" -ForegroundColor Red
}
Write-Host ""

Write-Host "=========================================" -ForegroundColor Cyan
Write-Host "     DIAGNOSTICO CONCLUIDO              " -ForegroundColor Cyan
Write-Host "=========================================" -ForegroundColor Cyan
Write-Host ""
