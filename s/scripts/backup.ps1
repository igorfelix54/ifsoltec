<#
.SYNOPSIS
    Script de backup para pastas do usuário (Documentos, Downloads, Imagens, etc.)
.DESCRIPTION
    Utiliza robocopy para cópia incremental. Permite escolher o destino interativamente.
.NOTES
    Autor: (adaptado)
    Data: 2025-03-18
#>

# ============================================
# CONFIGURAÇÕES (altere conforme necessário)
# ============================================

# Diretório de origem (normalmente o perfil do usuário)
$ORIGEM = $env:USERPROFILE

# Pastas a serem incluídas no backup (nomes exatos como aparecem no diretório de origem)
$PASTAS = @(
    "Documentos"
    "Downloads"
    "Imagens"
    "Vídeos"
    "Música"
    "Área de Trabalho"
    # Adicione ou remova pastas conforme desejar
)

# Destino padrão (usado se o usuário não digitar nada)
$DESTINO_PADRAO = "D:\Backup_Usuario"   # <-- ALTERE PARA O DESTINO PADRÃO DESEJADO

# Opções adicionais do robocopy (padrão seguro)
$OPCOES_ROBOCOPY = @(
    "/COPYALL"        # Copia todos os atributos (dados, permissões, etc.)
    "/DCOPY:T"        # Copia timestamps das pastas
    "/R:3"            # Número de tentativas em caso de falha
    "/W:10"           # Tempo de espera entre tentativas (segundos)
    "/NP"             # Sem progresso (reduz verbosidade no log)
    "/NDL"            # Sem lista de diretórios no log
    "/NFL"            # Sem lista de arquivos no log
    "/LOG+:$LOG_FILE" # Anexa a saída ao arquivo de log (definido depois)
)

# Se quiser simular o backup sem copiar nada (teste), mude para $true
$SIMULAR = $false

# Se quiser apagar arquivos no destino que não existem mais na origem (cuidado!)
$DELETAR = $true

# ============================================
# Não edite abaixo a menos que saiba o que faz
# ============================================

# Gera nome do arquivo de log com timestamp (será sobrescrito depois com caminho completo)
$LOG_FILE = "$env:TEMP\backup_$(Get-Date -Format 'yyyyMMdd_HHmmss').log"

# Cores para mensagens no console
$COR_VERDE = "Green"
$COR_VERMELHA = "Red"
$COR_AMARELA = "Yellow"
$COR_AZUL = "Cyan"

# Funções para exibir mensagens e registrar no log
function Escrever-Mensagem {
    param([string]$Texto, [string]$Cor = "White")
    $linha = "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')] $Texto"
    Write-Host $linha -ForegroundColor $Cor
    Add-Content -Path $LOG_FILE -Value $linha
}

function Escrever-Sucesso  { Escrever-Mensagem -Texto $args[0] -Cor $COR_VERDE }
function Escrever-Erro     { Escrever-Mensagem -Texto $args[0] -Cor $COR_VERMELHA }
function Escrever-Aviso    { Escrever-Mensagem -Texto $args[0] -Cor $COR_AMARELA }
function Escrever-Info     { Escrever-Mensagem -Texto $args[0] -Cor $COR_AZUL }

# Verifica se o robocopy está disponível
if (-not (Get-Command robocopy -ErrorAction SilentlyContinue)) {
    Write-Host "[ERRO] Robocopy não encontrado. Este script requer o Windows 7 ou superior." -ForegroundColor Red
    exit 1
}

# Função para escolher o destino interativamente
function Escolher-Destino {
    Write-Host ""
    Write-Host "Escolha o destino do backup:" -ForegroundColor Cyan
    Write-Host "1 - Usar destino padrão: $DESTINO_PADRAO" -ForegroundColor Yellow
    Write-Host "2 - Digitar outro caminho (ex: E:\Backup, \\servidor\pasta)" -ForegroundColor Yellow
    Write-Host "3 - Sair" -ForegroundColor Red
    Write-Host ""

    $opcao = Read-Host "Digite o número da opção desejada"

    switch ($opcao) {
        "1" {
            $destino = $DESTINO_PADRAO
            Write-Host "Destino selecionado: $destino" -ForegroundColor Green
            break
        }
        "2" {
            do {
                $destino = Read-Host "Digite o caminho completo do destino"
                if ([string]::IsNullOrWhiteSpace($destino)) {
                    Write-Host "Caminho inválido. Tente novamente." -ForegroundColor Red
                } else {
                    # Verifica se o caminho parece válido (unidade ou caminho UNC)
                    if ($destino -match '^[a-zA-Z]:\\' -or $destino -match '^\\\\') {
                        # OK
                    } else {
                        Write-Host "Caminho deve ser absoluto (ex: D:\Backup ou \\servidor\pasta)" -ForegroundColor Red
                        $destino = $null
                    }
                }
            } while ([string]::IsNullOrWhiteSpace($destino))
            Write-Host "Destino selecionado: $destino" -ForegroundColor Green
            break
        }
        "3" {
            Write-Host "Backup cancelado pelo usuário." -ForegroundColor Red
            exit 0
        }
        default {
            Write-Host "Opção inválida. Usando destino padrão: $DESTINO_PADRAO" -ForegroundColor Yellow
            $destino = $DESTINO_PADRAO
        }
    }

    return $destino
}

# Chama a função para obter o destino
$DESTINO = Escolher-Destino

# Agora que temos o destino, atualiza o caminho do log para incluir o destino (opcional)
# Mantém o log na temp, mas pode-se alterar para salvar no destino também, se desejar.
# Por simplicidade, manteremos na temp.

# Verifica se o destino existe, senão tenta criar
if (-not (Test-Path $DESTINO)) {
    Escrever-Aviso "Diretório de destino não existe. Tentando criar: $DESTINO"
    try {
        New-Item -ItemType Directory -Path $DESTINO -Force | Out-Null
    }
    catch {
        Escrever-Erro "Falha ao criar diretório de destino: $DESTINO"
        exit 1
    }
}

# Verifica permissão de escrita no destino
try {
    $arquivoTeste = Join-Path $DESTINO "teste_permissao.tmp"
    [System.IO.File]::WriteAllText($arquivoTeste, "teste")
    Remove-Item $arquivoTeste -Force
}
catch {
    Escrever-Erro "Sem permissão de escrita no diretório de destino: $DESTINO"
    exit 1
}

# Define as opções finais do robocopy
$ROBO_OPTS = $OPCOES_ROBOCOPY.Clone()

# Adiciona opção de simulação (listagem apenas) se necessário
if ($SIMULAR) {
    $ROBO_OPTS += "/L"
    Escrever-Aviso "Modo simulação ativado (somente listagem, nenhuma alteração será feita)."
}

# Define a ação de deleção: /MIR espelha (copia e deleta), /E copia subpastas sem deletar
if ($DELETAR) {
    $ROBO_OPTS += "/MIR"
    Escrever-Aviso "Opção de deleção ativada (arquivos no destino sem correspondência na origem serão removidos)."
} else {
    $ROBO_OPTS += "/E"
}

# Ajusta o caminho do log (substitui a entrada temporária pela definitiva com caminho completo)
$ROBO_OPTS = $ROBO_OPTS -replace "\/LOG\+:.*", "/LOG+:$LOG_FILE"

Escrever-Info "Iniciando backup do usuário $env:USERNAME"
Escrever-Info "Origem: $ORIGEM"
Escrever-Info "Destino: $DESTINO"
Escrever-Info "Log: $LOG_FILE"
Escrever-Info "Opções do robocopy: $($ROBO_OPTS -join ' ')"

# Loop sobre cada pasta
foreach ($PASTA in $PASTAS) {
    $CAMINHO_ORIGEM = Join-Path $ORIGEM $PASTA
    $CAMINHO_DESTINO = Join-Path $DESTINO $PASTA

    if (-not (Test-Path $CAMINHO_ORIGEM)) {
        Escrever-Aviso "Pasta de origem não encontrada: $CAMINHO_ORIGEM. Ignorando."
        continue
    }

    Escrever-Info "Copiando $PASTA..."

    # Executa o robocopy
    $argumentos = @($CAMINHO_ORIGEM, $CAMINHO_DESTINO) + $ROBO_OPTS
    & robocopy @argumentos

    $exitCode = $LASTEXITCODE

    # Códigos de saída do robocopy: 0-7 sucesso, 8+ erro
    if ($exitCode -ge 8) {
        Escrever-Erro "Falha no backup de $PASTA. Código de saída: $exitCode. Verifique o log."
        exit $exitCode
    }
    else {
        Escrever-Sucesso "Backup de $PASTA concluído (código $exitCode)."
    }
}

Escrever-Sucesso "Backup finalizado com sucesso!"
Escrever-Info "Log salvo em: $LOG_FILE"