<#
.SYNOPSIS
    Mostra configuracao de rede atual e permite alterar para DHCP ou IP fixo.
    As opcoes sao selecionadas apenas com as teclas numericas (sem Enter).
.NOTES
    Requer execucao como administrador.
#>

# Verifica se esta executando como administrador
if (-NOT ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Error "Este script precisa ser executado como Administrador."
    exit 1
}

# Funcao para converter mascara decimal (ex: 255.255.255.0) em prefixo CIDR
function Convert-MascaraParaPrefixo {
    param([string]$mascara)
    $binario = [convert]::ToString(([ipaddress]$mascara).Address, 2)
    return ($binario -replace '0', '').Length
}

# Funcao para exibir as configuracoes atuais
function Show-Config {
    param($adapter)
    $ifIndex = $adapter.ifIndex
    Write-Host "`n--- Configuracoes atuais do adaptador: $($adapter.Name) (ifIndex: $ifIndex) ---" -ForegroundColor Cyan

    # IPs IPv4
    $ips = Get-NetIPAddress -InterfaceIndex $ifIndex -AddressFamily IPv4 -ErrorAction SilentlyContinue
    if ($ips) {
        Write-Host "Enderecos IPv4:" -ForegroundColor Yellow
        foreach ($ip in $ips) {
            Write-Host "  $($ip.IPAddress)/$($ip.PrefixLength) (tipo: $($ip.Type))"
        }
    } else {
        Write-Host "Nenhum endereco IPv4 configurado." -ForegroundColor Gray
    }

    # Gateway padrao
    $gateways = Get-NetRoute -InterfaceIndex $ifIndex -DestinationPrefix "0.0.0.0/0" -ErrorAction SilentlyContinue
    if ($gateways) {
        Write-Host "Gateway padrao:" -ForegroundColor Yellow
        foreach ($gw in $gateways) {
            Write-Host "  $($gw.NextHop) (metrica: $($gw.RouteMetric))"
        }
    } else {
        Write-Host "Nenhum gateway padrao configurado." -ForegroundColor Gray
    }

    # DNS
    $dns = Get-DnsClientServerAddress -InterfaceIndex $ifIndex -AddressFamily IPv4 -ErrorAction SilentlyContinue
    if ($dns.ServerAddresses) {
        Write-Host "Servidores DNS:" -ForegroundColor Yellow
        Write-Host "  $($dns.ServerAddresses -join ', ')"
    } else {
        Write-Host "Nenhum servidor DNS configurado." -ForegroundColor Gray
    }
    Write-Host "----------------------------------------`n"
}

# Funcao para ler uma tecla numerica (1-9) e retornar o numero como string
function Read-NumericKey {
    Write-Host -NoNewline "Pressione a tecla numerica correspondente: "
    $key = $host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    $char = $key.Character.ToString()
    if ($char -match '[1-9]') {
        return $char
    } else {
        return $null
    }
}

# Listar adaptadores de rede (todos, incluindo desativados)
$adapters = Get-NetAdapter -ErrorAction SilentlyContinue
if (-not $adapters) {
    Write-Error "Nenhum adaptador de rede encontrado."
    exit 1
}

Write-Host "Adaptadores de rede disponiveis:" -ForegroundColor Green
for ($i = 0; $i -lt $adapters.Count; $i++) {
    $status = $adapters[$i].Status
    Write-Host "$($i+1) - $($adapters[$i].Name) (ifIndex: $($adapters[$i].ifIndex)) [Status: $status]"
}

# Selecionar adaptador com tecla numerica
$escolhaAdapter = $null
while ($escolhaAdapter -eq $null) {
    $key = Read-NumericKey
    if ($key -ne $null) {
        $num = [int]$key
        if ($num -ge 1 -and $num -le $adapters.Count) {
            $escolhaAdapter = $num
        } else {
            Write-Host "`nNumero fora do intervalo. Tente novamente." -ForegroundColor Red
        }
    } else {
        Write-Host "`nTecla invalida. Use apenas numeros de 1 a 9." -ForegroundColor Red
    }
}

$adapter = $adapters[$escolhaAdapter - 1]
$ifIndex = $adapter.ifIndex

# Mostra configuracao atual
Show-Config -adapter $adapter

# Menu de opcoes
Write-Host "O que deseja fazer?" -ForegroundColor Green
Write-Host "1 - Manter configuracao atual (sair)"
Write-Host "2 - Configurar para DHCP (IP dinamico)"
Write-Host "3 - Configurar IP estatico"

# Selecionar opcao com tecla numerica
$opcao = $null
while ($opcao -eq $null) {
    $key = Read-NumericKey
    if ($key -ne $null -and $key -match '[1-3]') {
        $opcao = $key
    } else {
        Write-Host "`nOpcao invalida. Use 1, 2 ou 3." -ForegroundColor Red
    }
}

if ($opcao -eq '1') {
    Write-Host "`nNenhuma alteracao foi feita. Saindo." -ForegroundColor Yellow
    exit 0
}

# Se opcao 2 (DHCP)
if ($opcao -eq '2') {
    Write-Host "`nConfigurando para DHCP..." -ForegroundColor Cyan

    # Remove configuracao IP estatica e ativa DHCP
    try {
        # Remove IPs IPv4 existentes
        $ips = Get-NetIPAddress -InterfaceIndex $ifIndex -AddressFamily IPv4 -ErrorAction SilentlyContinue
        foreach ($ip in $ips) {
            Remove-NetIPAddress -InterfaceIndex $ifIndex -IPAddress $ip.IPAddress -Confirm:$false -ErrorAction Stop
        }

        # Remove gateways padrao
        $rotas = Get-NetRoute -InterfaceIndex $ifIndex -DestinationPrefix "0.0.0.0/0" -ErrorAction SilentlyContinue
        foreach ($rota in $rotas) {
            Remove-NetRoute -InterfaceIndex $ifIndex -DestinationPrefix $rota.DestinationPrefix -NextHop $rota.NextHop -Confirm:$false -ErrorAction Stop
        }

        # Habilita DHCP (nao ha um comando direto, basta nao ter IP fixo. Mas podemos garantir que o cliente DHCP esteja ativo)
        Set-NetIPInterface -InterfaceIndex $ifIndex -Dhcp Enabled
        # Libera e renova IP (opcional)
        ipconfig /release *$($adapter.Name)* | Out-Null
        ipconfig /renew *$($adapter.Name)* | Out-Null

        Write-Host "Configuracao DHCP aplicada." -ForegroundColor Green
    }
    catch {
        Write-Error "Falha ao configurar DHCP: $_"
        exit 1
    }

    # Mostra nova configuracao
    Show-Config -adapter $adapter
    exit 0
}

# Se opcao 3 (estatico)
if ($opcao -eq '3') {
    Write-Host "`nConfigurando IP estatico..." -ForegroundColor Cyan

    # Solicita IP (aqui ainda usamos Read-Host, pois precisa digitar)
    $ip = Read-Host "Digite o endereco IP (ex: 192.168.1.100)"
    if ($ip -notmatch '^\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}$') {
        Write-Error "Formato de IP invalido."
        exit 1
    }

    # Solicita mascara
    $mascara = Read-Host "Digite a mascara de sub-rede (ex: 255.255.255.0)"
    if ($mascara -notmatch '^\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}$') {
        Write-Error "Formato de mascara invalido."
        exit 1
    }
    try {
        $prefixo = Convert-MascaraParaPrefixo -mascara $mascara
    }
    catch {
        Write-Error "Mascara invalida."
        exit 1
    }

    # Solicita gateway (opcional)
    $gateway = Read-Host "Digite o gateway padrao (deixe em branco se nao houver)"
    if ($gateway -and $gateway -notmatch '^\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}$') {
        Write-Error "Formato de gateway invalido."
        exit 1
    }

    # Solicita DNS (opcional)
    $dnsInput = Read-Host "Digite os servidores DNS separados por espaco (opcional, ex: 8.8.8.8 8.8.4.4)"
    $dnsServers = @()
    if ($dnsInput) {
        $dnsServers = $dnsInput -split '\s+'
        foreach ($d in $dnsServers) {
            if ($d -notmatch '^\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}$') {
                Write-Error "DNS invalido: $d"
                exit 1
            }
        }
    }

    # Resumo
    Write-Host "`nResumo da nova configuracao:" -ForegroundColor Yellow
    Write-Host "  IP: $ip/$prefixo"
    if ($gateway) { Write-Host "  Gateway: $gateway" }
    if ($dnsServers) { Write-Host "  DNS: $($dnsServers -join ', ')" }

    # Confirmar com S/N usando tecla unica
    Write-Host -NoNewline "Deseja aplicar estas configuracoes? (S/N): "
    $confirma = $host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    $confChar = $confirma.Character.ToString().ToUpper()
    Write-Host "" # para quebrar linha
    if ($confChar -ne 'S') {
        Write-Host "Operacao cancelada." -ForegroundColor Red
        exit 0
    }

    # Aplica configuracoes
    try {
        $ips = Get-NetIPAddress -InterfaceIndex $ifIndex -AddressFamily IPv4 -ErrorAction SilentlyContinue
        foreach ($ipAtual in $ips) {
            Remove-NetIPAddress -InterfaceIndex $ifIndex -IPAddress $ipAtual.IPAddress -Confirm:$false -ErrorAction Stop
        }

        $rotas = Get-NetRoute -InterfaceIndex $ifIndex -DestinationPrefix "0.0.0.0/0" -ErrorAction SilentlyContinue
        foreach ($rota in $rotas) {
            Remove-NetRoute -InterfaceIndex $ifIndex -DestinationPrefix $rota.DestinationPrefix -NextHop $rota.NextHop -Confirm:$false -ErrorAction Stop
        }

        if ($gateway) {
            New-NetIPAddress -InterfaceIndex $ifIndex -IPAddress $ip -PrefixLength $prefixo -DefaultGateway $gateway -ErrorAction Stop
        } else {
            New-NetIPAddress -InterfaceIndex $ifIndex -IPAddress $ip -PrefixLength $prefixo -ErrorAction Stop
        }

        if ($dnsServers) {
            Set-DnsClientServerAddress -InterfaceIndex $ifIndex -ServerAddresses $dnsServers -ErrorAction Stop
        } else {
            Set-DnsClientServerAddress -InterfaceIndex $ifIndex -ServerAddresses @() -ErrorAction SilentlyContinue
        }

        Write-Host "Configuracao estatica aplicada com sucesso!" -ForegroundColor Green
    }
    catch {
        Write-Error "Falha ao aplicar configuracao: $_"
        exit 1
    }

    Show-Config -adapter $adapter
    exit 0
}