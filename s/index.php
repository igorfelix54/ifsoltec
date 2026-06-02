# ============================================
# MENU SIMPLES - IFSOLTEC
# COM VERIFICACAO DE POLITICA DE EXECUCAO E STATUS DE ADMIN
# E VERIFICAÇÃO DE INTEGRIDADE POR HASH
# ============================================

# ===== VERIFICACAO DE ADMINISTRADOR =====
function Verificar-Admin {
    $isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
    return $isAdmin
}

# ===== VERIFICACAO DE POLITICA DE EXECUCAO =====
function Verificar-PoliticaExecucao {
    $politicaAtual = Get-ExecutionPolicy
    
    if ($politicaAtual -eq "Restricted") {
        Write-Host "=========================================" -ForegroundColor Red
        Write-Host "  EXECUCAO DE SCRIPTS DESABILITADA!    " -ForegroundColor Red
        Write-Host "=========================================" -ForegroundColor Red
        Write-Host ""
        Write-Host "O sistema esta bloqueando a execucao de scripts do PowerShell." -ForegroundColor Yellow
        Write-Host ""
        Write-Host "Escolha uma opcao:" -ForegroundColor Cyan
        Write-Host "  [1] Habilitar automaticamente (Recomendado)" -ForegroundColor Green
        Write-Host "  [2] Ver instrucoes para habilitar manualmente" -ForegroundColor Yellow
        Write-Host "  [3] Sair do programa" -ForegroundColor Red
        Write-Host ""
        
        do {
            $key = $host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
            $opcao = $key.Character.ToString()
            
            switch ($opcao) {
                "1" {
                    try {
                        Write-Host "`nTentando habilitar execucao de scripts..." -ForegroundColor Green
                        
                        # Tenta definir política para o usuário atual
                        Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy RemoteSigned -Force -ErrorAction Stop
                        
                        Write-Host "Politica alterada com sucesso!" -ForegroundColor Green
                        Write-Host "Continuando com o programa..." -ForegroundColor Cyan
                        Start-Sleep -Seconds 2
                        return $true
                    }
                    catch {
                        Write-Host "`nERRO: Nao foi possivel alterar a politica automaticamente." -ForegroundColor Red
                        Write-Host "Motivo: $($_.Exception.Message)" -ForegroundColor Red
                        Write-Host ""
                        Write-Host "Tente executar o PowerShell como Administrador e execute:" -ForegroundColor Yellow
                        Write-Host "Set-ExecutionPolicy RemoteSigned -Scope CurrentUser" -ForegroundColor White
                        Write-Host ""
                        Write-Host "Pressione qualquer tecla para sair..." -ForegroundColor Gray
                        $host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown") | Out-Null
                        exit
                    }
                }
                "2" {
                    Write-Host "`n=========================================" -ForegroundColor Yellow
                    Write-Host "         INSTRUCOES MANUAIS              " -ForegroundColor Yellow
                    Write-Host "=========================================" -ForegroundColor Yellow
                    Write-Host ""
                    Write-Host "Opcao 1 - Para usuario atual (Recomendado):" -ForegroundColor Cyan
                    Write-Host "  1. Abra o PowerShell como Administrador" -ForegroundColor White
                    Write-Host "  2. Digite: Set-ExecutionPolicy RemoteSigned -Scope CurrentUser" -ForegroundColor White
                    Write-Host "  3. Digite 'S' para confirmar" -ForegroundColor White
                    Write-Host ""
                    Write-Host "Opcao 2 - Para todos os usuarios:" -ForegroundColor Cyan
                    Write-Host "  1. Abra o PowerShell como Administrador" -ForegroundColor White
                    Write-Host "  2. Digite: Set-ExecutionPolicy RemoteSigned" -ForegroundColor White
                    Write-Host "  3. Digite 'S' para confirmar" -ForegroundColor White
                    Write-Host ""
                    Write-Host "Opcao 3 - Bypass temporario (so para este script):" -ForegroundColor Cyan
                    Write-Host "  Execute este comando para rodar o menu:" -ForegroundColor White
                    Write-Host "  powershell -ExecutionPolicy Bypass -File `"$($MyInvocation.MyCommand.Path)`"" -ForegroundColor White
                    Write-Host ""
                    Write-Host "Pressione qualquer tecla apos habilitar a execucao..." -ForegroundColor Gray
                    $host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown") | Out-Null
                    
                    # Verifica novamente se a politica foi alterada
                    if ((Get-ExecutionPolicy) -eq "Restricted") {
                        Write-Host "`nA politica ainda esta como Restricted." -ForegroundColor Red
                        Write-Host "Deseja tentar novamente? [S/N]" -ForegroundColor Yellow
                        $key = $host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
                        if ($key.Character.ToString().ToUpper() -eq "S") {
                            continue
                        } else {
                            exit
                        }
                    } else {
                        return $true
                    }
                }
                "3" {
                    Write-Host "`nSaindo do programa..." -ForegroundColor Magenta
                    exit
                }
                default {
                    Write-Host "Opcao invalida! Use 1, 2 ou 3" -ForegroundColor Red
                }
            }
        } while ($true)
    } else {
        Write-Host "Politica de execucao: $politicaAtual (OK)" -ForegroundColor Green
        Start-Sleep -Seconds 1
        return $true
    }
}

# ===== EXECUTAR VERIFICACOES =====
if (-not (Verificar-PoliticaExecucao)) {
    exit
}

$isAdmin = Verificar-Admin
$usuario = [Environment]::UserName
$computador = [Environment]::MachineName

# ===== MENU PRINCIPAL =====
$baseUrl = "https://ifsoltec.com/s/scripts"

# ===== DEFINICAO DAS CATEGORIAS E SCRIPTS COM HASH =====
# Gere os hashes SHA256 para cada script e substitua os valores abaixo
$categorias = @{
    "Backup" = @(
        @{ Nome = "Backup do Usuario"; Arquivo = "backup.ps1"; Hash = "D9CB8EB3A986A0D718D58A340ABCB8AAC65C04C7F72F243E77213175B7ED88AB" }
    )
    "Segurança" = @(
        @{ Nome = "Scanner de Virus"; Arquivo = "Scanner.ps1"; Hash = "6CCBD8975C60897CDE0308FCD3AC3FEAE8A1544D7AEFDC75F3D7A86D4AD71388" }
    )
    "Otimizacao" = @(
        @{ Nome = "Limpeza de Sistema"; Arquivo = "cls.ps1"; Hash = "4DF77E0A1C211340CDBAAE3500F5CFE19A07F68A28F6DD81BE25C5C353CDB511" },
        @{ Nome = "Desativar Efeitos Visuais"; Arquivo = "ConfigurarEfeitosVisuais.ps1"; Hash = "6354A4CF74D18529981B749BB1CA3B66F5C604A87B8C5E83860E14D18E078C2F" },
        @{ Nome = "Aplicativos de Inicializacao"; Arquivo = "Get-StartupPrograms.ps1"; Hash = "E8D3D4B2C2D5B34C6CD08E35BAEBF4885412224444B740C4702D4BDE63F09BC1" },
        @{ Nome = "Alta Desempenho"; Arquivo = "high-performace.ps1"; Hash = "CB48A7C1414192C00502ECF8038D214413D2C884426C4C960BF3EAB6C6D8CF2B" }
    )
    "Diagnostico" = @(
        @{ Nome = "Diagnostico do PC"; Arquivo = "info.ps1"; Hash = "E0629E8D149AB134F1B76899D516FDF929FBEF7B7ACC0A940872E9A5876D392F" },
        @{ Nome = "Diagnostico do Windows"; Arquivo = "WinSystemFirstAidKit.ps1"; Hash = "19207733C25D5F3087B3D07BAD21C1280509A506548D3F3EEE7A3A2413C93945" }
    )
    "Rede" = @(
        @{ Nome = "Otimizacao de Rede"; Arquivo = "rede.ps1"; Hash = "4550F49178DA7613B067CAED97E6949433F1D339558025A3211F85EC8A5DB18B" },
        @{ Nome = "Alterar Configuracoes de Rede"; Arquivo = "set-staticIP.ps1"; Hash = "587701185351CDBEA5719552AE20B074949D514C3AC467270F41C759D060A107" }
    )
    "Atualizacoes" = @(
        @{ Nome = "Windows Update"; Arquivo = "winup.ps1"; Hash = "BF88998F32E825BB7ADCEF2D6A5082B562F2B25465AF248496CA0D44C65EB944" },
        @{ Nome = "Mudar Versao do Windows"; Arquivo = "upversion.ps1"; Hash = "A58B6CD3D1D4D5C92B937A0C1CFA2094A58513F89FB058AF5AE0E07D4AF39A7D" }
    )
    "Correcoes" = @(
        @{ Nome = "Corrigir Erro de Impressora"; Arquivo = "fix-printer.ps1"; Hash = "941E54A4149FFBB6CCC74EFBE834367D447CCE389C8858E5726C523C79A91044" },
        @{ Nome = "CORREÇÃO DE ERROS DE IMPRESSORA"; Arquivo = "fix-printer2.ps1"; Hash = "5861310E8244B7AD9F318E7BCD36D4FB3B1B976B465CC0F668296D2F54324D52" }
    )
    "Ferramentas" = @(
        @{ Nome = "Ativador"; Arquivo = "active.ps1"; Hash = "F03F3164BBA6759F81A52E2B6211593F1AEC74668125D44B7DDA732568F325AA" }
    )
}

# Função para calcular hash SHA256 de uma string
function Calcular-HashSHA256 {
    param([string]$conteudo)
    
    try {
        # Converte a string para bytes UTF-8 sem BOM
        $bytes = [System.Text.Encoding]::UTF8.GetBytes($conteudo)
        
        # Calcula o hash
        $sha256 = [System.Security.Cryptography.SHA256]::Create()
        $hashBytes = $sha256.ComputeHash($bytes)
        
        # Converte para string hexadecimal maiúscula
        $hashString = [System.BitConverter]::ToString($hashBytes).Replace("-", "").ToUpper()
        
        return $hashString
    }
    finally {
        if ($sha256) { $sha256.Dispose() }
    }
}

# Função para capturar tecla com suporte a ESC
function Get-KeyPress {
    $key = $host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    
    # Verifica se é ESC (VirtualKeyCode 27)
    if ($key.VirtualKeyCode -eq 27) {
        return "ESC"
    }
    
    # Retorna o caractere pressionado
    return $key.Character.ToString()
}

# Função para exibir o menu de categorias
function Show-MenuCategorias {
    Clear-Host
    Write-Host "╔══════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
    Write-Host "║                                                          ║" -ForegroundColor Cyan
    Write-Host "║                    ██╗ ███████╗                          ║" -ForegroundColor Green
    Write-Host "║                    ██║ ██╔════╝                          ║" -ForegroundColor Green
    Write-Host "║                    ██║ █████╗                            ║" -ForegroundColor Green
    Write-Host "║                    ██║ ██╔══╝                            ║" -ForegroundColor Green
    Write-Host "║                    ██║ ██║                               ║" -ForegroundColor Green
    Write-Host "║                    ╚═╝ ╚═╝                               ║" -ForegroundColor Green
    Write-Host "║                    ████████╗███████╗ ██████╗             ║" -ForegroundColor Yellow
    Write-Host "║                    ╚══██╔══╝██╔════╝██╔════╝             ║" -ForegroundColor Yellow
    Write-Host "║                       ██║   █████╗  ██║                  ║" -ForegroundColor Yellow
    Write-Host "║                       ██║   ██╔══╝  ██║                  ║" -ForegroundColor Yellow
    Write-Host "║                       ██║   ███████╗╚██████╗             ║" -ForegroundColor Yellow
    Write-Host "║                       ╚═╝   ╚══════╝ ╚═════╝             ║" -ForegroundColor Yellow
    Write-Host "║                                                          ║" -ForegroundColor Cyan
    Write-Host "║               Criado por: Igor Felix                     ║" -ForegroundColor Yellow
    Write-Host "║                   I F S O L T E C                        ║" -ForegroundColor White
    Write-Host "║              Solucoes em Tecnologia                      ║" -ForegroundColor Cyan
    Write-Host "║                        v2.0                              ║" -ForegroundColor Magenta
    Write-Host "╠══════════════════════════════════════════════════════════╣" -ForegroundColor Cyan
    
    # Informações do usuário e status de admin
    $modoTexto = if ($isAdmin) { "ADMINISTRADOR" } else { "USUARIO" }
    $modoCor = if ($isAdmin) { "Green" } else { "Yellow" }
    Write-Host "              Usuario: $usuario@$computador                 " -ForegroundColor Gray
    Write-Host "                   Modo: " -NoNewline -ForegroundColor Gray      
    Write-Host "$modoTexto                                    " -ForegroundColor $modoCor
    Write-Host "   (Alguns scripts podem exigir modo Administrador)       " -ForegroundColor Red
    Write-Host "╚══════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
    Write-Host ""
    
    Write-Host "╔══════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
    Write-Host "║                    CATEGORIAS DE SCRIPTS                 ║" -ForegroundColor Cyan
    Write-Host "╠══════════════════════════════════════════════════════════╣" -ForegroundColor Cyan
    
    $categoriaIndex = 1
    $categoriaKeys = $categorias.Keys | Sort-Object
    foreach ($cat in $categoriaKeys) {
        $espacos = " " * (40 - $cat.Length)
        Write-Host "║    [$categoriaIndex] $cat$espacos          ║" -ForegroundColor Yellow
        $categoriaIndex++
    }
    
    Write-Host "║                                                          ║" -ForegroundColor Cyan
    Write-Host "║    [ESC] Sair                                            ║" -ForegroundColor Red
    Write-Host "╚══════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "   Aperte o número desejado (ou ESC para sair): " -ForegroundColor Gray -NoNewline
}

# Função para exibir os scripts de uma categoria
function Show-MenuScripts {
    param($categoriaNome, $scriptsList)
    
    do {
        Clear-Host
        Write-Host "╔══════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
        Write-Host "║                    CATEGORIA: $categoriaNome" -ForegroundColor Green
        Write-Host "╠══════════════════════════════════════════════════════════╣" -ForegroundColor Cyan
        
        for ($i = 0; $i -lt $scriptsList.Count; $i++) {
            $numero = $i + 1
            $espacos = " " * (35 - $scriptsList[$i].Nome.Length)
            Write-Host "║    [$numero] $($scriptsList[$i].Nome)$espacos               ║" -ForegroundColor Yellow
        }
        
        Write-Host "║                                                          ║" -ForegroundColor Cyan
        Write-Host "║    [ESC] Voltar ao menu principal                        ║" -ForegroundColor Red
        Write-Host "╚══════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
        Write-Host ""
        Write-Host "   Aperte o número desejado (ou ESC para voltar): " -ForegroundColor Gray -NoNewline

        try {
            $tecla = Get-KeyPress
            
            if ($tecla -eq "ESC") {
                return  # Volta ao menu principal
            }
            elseif ($tecla -match "^\d$") {
                $numero = [int]$tecla
                
                $indice = $numero - 1
                if ($indice -ge 0 -and $indice -lt $scriptsList.Count) {
                    $scriptInfo = $scriptsList[$indice]
                    $url = "$baseUrl/$($scriptInfo.Arquivo)"

                    Write-Host "`n"
                    Write-Host "╔══════════════════════════════════════════════════════════╗" -ForegroundColor Green
                    Write-Host "║              EXECUTANDO SCRIPT (COM VERIFICAÇÃO)         ║" -ForegroundColor Green
                    Write-Host "╚══════════════════════════════════════════════════════════╝" -ForegroundColor Green
                    Write-Host ""
                    Write-Host "   Script: $($scriptInfo.Nome)" -ForegroundColor Cyan
                    Write-Host ""

                    try {
                        # Baixa o conteudo do script
                        Write-Host "   📥 Baixando script..." -ForegroundColor Yellow
                        
                        # Usa WebClient para melhor controle de encoding
                        $webClient = New-Object System.Net.WebClient
                        $webClient.Encoding = [System.Text.Encoding]::UTF8
                        $conteudo = $webClient.DownloadString($url)
                        
                        # --- VERIFICAÇÃO DE INTEGRIDADE ---
                        Write-Host "   🔒 Verificando integridade..." -ForegroundColor Yellow
                        
                        # Calcula o hash do conteúdo baixado
                        $hashCalculado = Calcular-HashSHA256 -conteudo $conteudo
                        
                        $hashEsperado = $scriptInfo.Hash.ToUpper()
                        
                        # Compara os hashes (case insensitive)
                        if ($hashCalculado -ne $hashEsperado) {
                            Write-Host ""
                            Write-Host "   ⚠️  ERRO DE INTEGRIDADE!" -ForegroundColor Red
                            Write-Host "   O arquivo baixado NÃO corresponde ao esperado." -ForegroundColor Red
                            Write-Host "   Possível adulteração ou erro de transmissão." -ForegroundColor Red
                            Write-Host ""
                            Write-Host "   Hash calculado: $hashCalculado" -ForegroundColor Gray
                            Write-Host "   Hash esperado : $hashEsperado" -ForegroundColor Gray
                            Write-Host ""
                            Write-Host "   Pressione qualquer tecla para voltar..." -ForegroundColor Gray
                            $host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown") | Out-Null
                            return  # Volta ao menu de scripts
                        }
                        
                        Write-Host "   ✅ Integridade verificada! Hash OK." -ForegroundColor Green
                        # ---------------------------------

                        # Cria arquivo temporario com encoding UTF-8 sem BOM
                        $tempFile = [System.IO.Path]::GetTempFileName() + ".ps1"
                        
                        # Salva com UTF-8 sem BOM para evitar problemas
                        $utf8NoBom = New-Object System.Text.UTF8Encoding $false
                        [System.IO.File]::WriteAllText($tempFile, $conteudo, $utf8NoBom)

                        # ===== EXECUÇÃO NA MESMA JANELA =====
                        Write-Host ""
                        Write-Host "   ⚡ Executando script..." -ForegroundColor Yellow
                        Write-Host ""
                        Write-Host "════════════════════════════════════════════════════════════" -ForegroundColor DarkGray
                        
                        # Executa o script diretamente na mesma janela
                        & $tempFile
                        
                        # Aguarda o usuário pressionar qualquer tecla antes de voltar ao menu
                        Write-Host ""
                        Write-Host "════════════════════════════════════════════════════════════" -ForegroundColor DarkGray
                        Write-Host ""
                        Write-Host "   ✅ Script concluído! Pressione qualquer tecla para voltar ao menu..." -ForegroundColor Green
                        
                        # Remove o arquivo temporário após a execução
                        Remove-Item $tempFile -Force -ErrorAction SilentlyContinue
                        
                        $host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown") | Out-Null
                        
                    }
                    catch {
                        Write-Host "   ❌ Erro durante a execução: $($_.Exception.Message)" -ForegroundColor Red
                        Write-Host ""
                        Write-Host "   Pressione qualquer tecla para continuar..." -ForegroundColor Gray
                        $host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown") | Out-Null
                    }
                } else {
                    Write-Host "`n"
                    Write-Host "   ❌ Opcao invalida! Digite um numero entre 1 e $($scriptsList.Count)" -ForegroundColor Red
                    Start-Sleep -Seconds 2
                }
            }
        } catch {
            # Ignora erros de leitura
        }
    } while ($true)
}

# ===== LOOP PRINCIPAL =====
do {
    Show-MenuCategorias
    
    try {
        $tecla = Get-KeyPress
        
        if ($tecla -eq "ESC") {
            # Sair do programa
            Write-Host "`n"
            Write-Host "╔══════════════════════════════════════════════════════════╗" -ForegroundColor Magenta
            Write-Host "║                                                          ║" -ForegroundColor Magenta
            Write-Host "║                 Obrigado por usar o                      ║" -ForegroundColor Yellow
            Write-Host "║                   I F S O L T E C                        ║" -ForegroundColor Green
            Write-Host "║                                                          ║" -ForegroundColor Magenta
            Write-Host "║                    Ate logo!                             ║" -ForegroundColor White
            Write-Host "║                                                          ║" -ForegroundColor Magenta
            Write-Host "╚══════════════════════════════════════════════════════════╝" -ForegroundColor Magenta
            Start-Sleep -Seconds 2
            exit
        }
        elseif ($tecla -match "^\d$") {
            $numero = [int]$tecla
            
            $categoriaKeys = $categorias.Keys | Sort-Object
            $categoriaIndex = $numero - 1
            if ($categoriaIndex -ge 0 -and $categoriaIndex -lt $categoriaKeys.Count) {
                $categoriaNome = $categoriaKeys[$categoriaIndex]
                $scripts = $categorias[$categoriaNome]
                Show-MenuScripts -categoriaNome $categoriaNome -scriptsList $scripts
            } else {
                Write-Host "`n"
                Write-Host "   ❌ Categoria invalida! Escolha um numero entre 1 e $($categoriaKeys.Count)" -ForegroundColor Red
                Start-Sleep -Seconds 2
            }
        }
    } catch {
        # Ignora erros
    }
} while ($true)