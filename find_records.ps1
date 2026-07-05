$ErrorActionPreference = 'SilentlyContinue'
try { [Console]::OutputEncoding = [System.Text.Encoding]::UTF8 } catch {}

$out = Join-Path ([Environment]::GetFolderPath('Desktop')) 'Python下载记录.txt'
$L = New-Object System.Collections.Generic.List[string]
function W($s){ $L.Add([string]$s); Write-Host $s }

W('================================================')
W(' Python 下载 / 安装记录汇总   ' + (Get-Date))
W(' (Python 没有单一历史文件, 下面是从各处痕迹拼出来的)')
W('================================================')
W('')

# ---------- 找出所有 Python 解释器 ----------
$pys = New-Object System.Collections.Generic.List[string]
try {
    $raw = & py -0p 2>$null
    if(-not $raw){ $raw = & py --list-paths 2>$null }
    foreach($line in $raw){
        $m = [regex]::Match([string]$line, '([A-Za-z]:\\[^\r\n]+?python\.exe)')
        if($m.Success){ $pys.Add($m.Groups[1].Value) }
    }
} catch {}
try { foreach($p in (& where.exe python 2>$null)){ if("$p" -match 'python\.exe$'){ $pys.Add([string]$p) } } } catch {}
$condaRoots = @("$env:USERPROFILE\miniforge3","$env:USERPROFILE\miniconda3","$env:USERPROFILE\anaconda3","$env:LOCALAPPDATA\miniforge3")
foreach($cr in $condaRoots){
    if(Test-Path "$cr\python.exe"){ $pys.Add("$cr\python.exe") }
    if(Test-Path "$cr\envs"){ Get-ChildItem "$cr\envs" -Directory | ForEach-Object { if(Test-Path "$($_.FullName)\python.exe"){ $pys.Add("$($_.FullName)\python.exe") } } }
}
$pys = @($pys | Where-Object { Test-Path $_ } | Select-Object -Unique)

W('==== [0] 检测到的 Python 解释器(你电脑上有这么多个 Python)====')
if($pys.Count -gt 0){ foreach($py in $pys){ W('  ' + $py) } } else { W('  没检测到 Python。') }
W('')

# ---------- 每个 Python 装了啥 + 何时装的 ----------
W('==== [1] 各 Python 装过的包 + 安装时间(按时间倒序, 这就是流水账)====')
foreach($py in $pys){
    W('---- ' + $py + ' ----')
    $dirs = & $py -c "import sysconfig,site;print(sysconfig.get_paths()['purelib']);print(site.getusersitepackages())" 2>$null
    $shown = 0
    foreach($sp in $dirs){
        $sp = ([string]$sp).Trim()
        if($sp -and (Test-Path $sp)){
            $infos = Get-ChildItem $sp -Directory -EA SilentlyContinue | Where-Object { $_.Name -match '\.(dist|egg)-info$' } | Sort-Object LastWriteTime -Descending
            foreach($r in $infos){
                if($shown -ge 120){ break }
                $name = $r.Name -replace '\.dist-info$','' -replace '\.egg-info$',''
                W(('    {0:yyyy-MM-dd HH:mm}   {1}' -f $r.LastWriteTime, $name))
                $shown++
            }
        }
    }
    if($shown -eq 0){ W('    (没定位到已装包)') }
    W('')
}

# ---------- pip 下载缓存(下过就留底) ----------
W('==== [2] pip 下载缓存里留存的安装包(卸了底还在)====')
$seenCache = @{}
$any = $false
foreach($py in $pys){
    $dir = (& $py -m pip cache dir 2>$null | Out-String).Trim()
    if($dir -and -not $seenCache.ContainsKey($dir)){
        $seenCache[$dir] = $true
        $cl = & $py -m pip cache list 2>$null
        W('  缓存目录: ' + $dir)
        $sz = (Get-ChildItem $dir -Recurse -File -EA SilentlyContinue | Measure-Object Length -Sum).Sum/1MB
        W(('  缓存总大小: {0:N0} MB' -f $sz))
        foreach($c in $cl){
            $c = ([string]$c).Trim()
            if($c -and $c -notmatch '^Cache contents' -and $c -notmatch 'No locally'){ W('    ' + $c); $any = $true }
        }
        W('')
    }
}
if(-not $any){ W('  (缓存里没列出具体安装包, 或缓存为空)'); W('') }

# ---------- conda 历史(真正的时间线日志) ----------
W('==== [3] conda 安装/卸载历史(逐条命令 + 时间, 最接近真账本)====')
$found = $false
foreach($cr in $condaRoots){
    if(-not (Test-Path $cr)){ continue }
    $targets = @{}
    $targets['base ('+$cr+')'] = Join-Path $cr 'conda-meta\history'
    if(Test-Path "$cr\envs"){
        Get-ChildItem "$cr\envs" -Directory | ForEach-Object { $targets['env: '+$_.Name] = Join-Path $_.FullName 'conda-meta\history' }
    }
    foreach($t in $targets.Keys){
        $h = $targets[$t]
        if(Test-Path $h){
            $found = $true
            W('---- ' + $t + ' ----')
            Get-Content $h | Where-Object { $_ -match '^==>' -or $_ -match '^# cmd:' } | ForEach-Object {
                $line = $_ -replace '^==>\s*','时间: ' -replace '\s*<==$','' -replace '^# cmd:\s*','  命令: '
                W('    ' + $line)
            }
            W('')
        }
    }
}
if(-not $found){ W('  (没找到 conda/Miniforge 的历史)'); W('') }

# ---------- 模型缓存(各模型下载时间 + 大小) ----------
W('==== [4] 模型缓存里各模型的下载时间 + 大小 ====')
$mc = [ordered]@{
 'HuggingFace' = "$env:USERPROFILE\.cache\huggingface\hub"
 'ModelScope'  = "$env:USERPROFILE\.cache\modelscope\hub"
 'PaddleOCR'   = "$env:USERPROFILE\.paddleocr"
 'EasyOCR'     = "$env:USERPROFILE\.EasyOCR"
}
$mfound = $false
foreach($k in $mc.Keys){
    $p = $mc[$k]
    if(Test-Path $p){
        $mfound = $true
        W('---- ' + $k + '  (' + $p + ') ----')
        Get-ChildItem $p -Directory -EA SilentlyContinue | Sort-Object LastWriteTime -Descending | ForEach-Object {
            $sz = (Get-ChildItem $_.FullName -Recurse -File -EA SilentlyContinue | Measure-Object Length -Sum).Sum/1MB
            W(('    {0:yyyy-MM-dd HH:mm}  {1,8:N0} MB  {2}' -f $_.LastWriteTime, $sz, $_.Name))
        }
        W('')
    }
}
if(-not $mfound){ W('  (这几个模型缓存目录都不存在)'); W('') }

W('================================================')
W(' 完成。清单已存到桌面: Python下载记录.txt')
W(' 贴回来给我, 我帮你读这条时间线: 啥时候下了啥、哪些是废的。')
W('================================================')

$L | Out-File -FilePath $out -Encoding UTF8
