# Folio · PDF -> EPUB 一键部署 (Windows PowerShell)
# 用法: 右键"使用 PowerShell 运行", 或  powershell -ExecutionPolicy Bypass -File deploy.ps1
$ErrorActionPreference = "Stop"
Set-Location -LiteralPath $PSScriptRoot

function Write-Step($msg) { Write-Host "  [*] $msg" -ForegroundColor DarkYellow }
function Write-Ok($msg)   { Write-Host "  [OK] $msg" -ForegroundColor DarkGreen }
function Write-Err($msg)  { Write-Host "  [!!] $msg" -ForegroundColor Red }

Write-Host ""
Write-Host "  ┌─────────────────────────────────────┐"
Write-Host "  │   Folio · PDF -> EPUB 转换工坊      │"
Write-Host "  └─────────────────────────────────────┘"
Write-Host ""

# 1. 查找 Python
$py = $null
foreach ($cmd in @("python", "py", "python3")) {
    try {
        $ver = & $cmd --version 2>$null
        if ($LASTEXITCODE -eq 0 -and $ver -match "Python 3\.(\d+)") {
            $py = $cmd; break
        }
    } catch { }
}
if (-not $py) {
    Write-Err "未找到 Python 3。请先从 https://www.python.org 安装并勾选 Add to PATH。"
    Read-Host "按回车退出"; exit 1
}
Write-Ok "发现 $(& $py --version)"

# 2. 虚拟环境
if (-not (Test-Path ".venv")) {
    Write-Step "创建虚拟环境 .venv ..."
    & $py -m venv .venv
}
$venvPy = Join-Path $PSScriptRoot ".venv\Scripts\python.exe"
if (-not (Test-Path $venvPy)) {
    Write-Err "虚拟环境创建失败。"; Read-Host "按回车退出"; exit 1
}

# 3. 依赖(有变化才重装)
$reqHash = (Get-FileHash requirements.txt -Algorithm MD5).Hash
$stampFile = ".venv\.deps-$reqHash"
if (-not (Test-Path $stampFile)) {
    Write-Step "安装依赖 ..."
    & $venvPy -m pip install --quiet --upgrade pip
    & $venvPy -m pip install --quiet -r requirements.txt
    if ($LASTEXITCODE -ne 0) { Write-Err "依赖安装失败"; Read-Host "按回车退出"; exit 1 }
    New-Item -ItemType File -Path $stampFile -Force | Out-Null
    Write-Ok "依赖安装完成"
} else {
    Write-Ok "依赖已是最新"
}

# 4. 启动
$port = 5000
Write-Host ""
Write-Ok "启动服务于  http://127.0.0.1:$port"
Write-Host "        按 Ctrl+C 停止" -ForegroundColor DarkGray
Start-Process "http://127.0.0.1:$port"
& $venvPy server.py --host 127.0.0.1 --port $port
