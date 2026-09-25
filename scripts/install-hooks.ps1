$ErrorActionPreference = 'Stop'
# Activa el pre-commit (escaneo de secretos; en los sub-repos, además, las pruebas) en los tres repos.
$Root = Split-Path -Parent $PSScriptRoot
foreach ($repo in @('.', 'citas-api', 'citas-web')) {
  $path = Join-Path $Root $repo
  if (Test-Path (Join-Path $path '.githooks')) {
    git -C $path config core.hooksPath .githooks
    Write-Host "[OK] hooks activos en $repo" -ForegroundColor Green
  } else {
    Write-Host "[SKIP] $repo no tiene .githooks" -ForegroundColor Yellow
  }
}
