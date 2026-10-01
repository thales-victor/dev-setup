$ErrorActionPreference = 'Stop'

$workspaceRoot = (Resolve-Path -LiteralPath $PSScriptRoot).Path.TrimEnd('\')
$composeDirectory = Join-Path $workspaceRoot 'dev-setup'

if (-not (Test-Path -LiteralPath (Join-Path $composeDirectory 'docker-compose.yml'))) {
    Write-Host "Nao encontrei o arquivo docker-compose.yml em: $composeDirectory" -ForegroundColor Red
    Read-Host 'Pressione Enter para sair'
    exit 1
}

Set-Location -LiteralPath $composeDirectory
Write-Host 'Iniciando os servicos Docker...'
& docker compose up -d
if ($LASTEXITCODE -ne 0) {
    Write-Host 'Nao foi possivel iniciar o Docker Compose.' -ForegroundColor Red
    Read-Host 'Pressione Enter para sair'
    exit $LASTEXITCODE
}

function Show-ArrowMenu {
    param(
        [Parameter(Mandatory = $true)][string]$Title,
        [Parameter(Mandatory = $true)][string[]]$Items
    )

    if ($Items.Count -eq 0) { return -1 }

    $selected = 0
    $oldCursorVisible = [Console]::CursorVisible
    [Console]::CursorVisible = $false
    try {
        while ($true) {
            Clear-Host
            Write-Host $Title -ForegroundColor Cyan
            Write-Host 'Use as setas para navegar, Enter para selecionar, Esc para voltar ou seta esquerda para a pasta anterior.'
            Write-Host ''

            $visibleCount = [Math]::Max(1, [Console]::WindowHeight - 5)
            $start = [Math]::Max(0, [Math]::Min($selected - [int]($visibleCount / 2), $Items.Count - $visibleCount))
            $end = [Math]::Min($Items.Count - 1, $start + $visibleCount - 1)

            for ($i = $start; $i -le $end; $i++) {
                if ($i -eq $selected) {
                    Write-Host (" > {0}. {1}" -f ($i + 1), $Items[$i]) -ForegroundColor Yellow
                }
                else {
                    Write-Host ("   {0}. {1}" -f ($i + 1), $Items[$i])
                }
            }

            $key = [Console]::ReadKey($true)
            switch ($key.Key) {
                'UpArrow' { if ($selected -gt 0) { $selected-- } }
                'DownArrow' { if ($selected -lt ($Items.Count - 1)) { $selected++ } }
                'Enter' { return $selected }
                'Escape' { return -1 }
                'LeftArrow' { return -2 }
            }
        }
    }
    finally {
        [Console]::CursorVisible = $oldCursorVisible
    }
}

function Convert-ToContainerPath {
    param([Parameter(Mandatory = $true)][string]$HostPath)

    $relativePath = $HostPath.Substring($workspaceRoot.Length).TrimStart('\')
    if ([string]::IsNullOrEmpty($relativePath)) { return '/workspace' }
    return '/workspace/' + ($relativePath -replace '\\', '/')
}

function Invoke-Codex {
    param(
        [Parameter(Mandatory = $true)][string]$HostPath,
        [switch]$Bypass
    )

    $containerPath = Convert-ToContainerPath -HostPath $HostPath
    Write-Host "Abrindo Codex em $containerPath ..."
    if ($Bypass) {
        & docker compose exec --workdir $containerPath codex codex --dangerously-bypass-approvals-and-sandbox
    }
    else {
        & docker compose exec --workdir $containerPath codex codex
    }
    if ($LASTEXITCODE -ne 0) {
        Write-Host "O comando terminou com codigo $LASTEXITCODE." -ForegroundColor DarkYellow
        [void](Read-Host 'Pressione Enter para continuar')
    }
}

function Open-ContainerShell {
    param([Parameter(Mandatory = $true)][string]$HostPath)

    $containerPath = Convert-ToContainerPath -HostPath $HostPath
    Write-Host "Abrindo terminal em $containerPath ..."
    & docker compose exec --workdir $containerPath codex bash
    if ($LASTEXITCODE -ne 0) {
        Write-Host "O comando terminou com codigo $LASTEXITCODE." -ForegroundColor DarkYellow
        [void](Read-Host 'Pressione Enter para continuar')
    }
}

function Show-FolderActions {
    param([Parameter(Mandatory = $true)][string]$Path)

    while ($true) {
        $choice = Show-ArrowMenu -Title ("Pasta atual: {0}" -f $Path) -Items @(
            'Entrar na pasta',
            'Iniciar Codex',
            'Iniciar Codex + bypass'
        )

        switch ($choice) {
            0 { Open-ContainerShell -HostPath $Path; return }
            1 { Invoke-Codex -HostPath $Path; return }
            2 { Invoke-Codex -HostPath $Path -Bypass; return }
            default { return }
        }
    }
}

function Browse-Folders {
    param([Parameter(Mandatory = $true)][string]$StartPath)

    $currentPath = $StartPath
    while ($true) {
        $directories = @(Get-ChildItem -LiteralPath $currentPath -Directory | Sort-Object Name)
        $items = @('Pasta Atual') + @($directories | ForEach-Object { '[{0}]' -f $_.Name })
        $choice = Show-ArrowMenu -Title ("Abrir uma pasta: {0}" -f $currentPath) -Items $items

        if ($choice -eq -1 -or $choice -eq -2) {
            if ($currentPath -ne $workspaceRoot) {
                $currentPath = Split-Path -Parent $currentPath
            }
            else {
                return
            }
            continue
        }

        if ($choice -eq 0) {
            Show-FolderActions -Path $currentPath
            continue
        }

        $currentPath = $directories[$choice - 1].FullName
    }
}

Browse-Folders -StartPath $workspaceRoot
exit 0
