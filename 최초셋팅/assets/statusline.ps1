# Claude Code statusline — model / effort / context% / cost / git branch / rate limit
# stdin 으로 세션 JSON 을 받아 한 줄로 출력함. 매 턴 갱신됨.
$ErrorActionPreference = 'SilentlyContinue'
[Console]::OutputEncoding = [System.Text.UTF8Encoding]::new()

$raw = [Console]::In.ReadToEnd()
if (-not $raw) { return }
$d = $raw | ConvertFrom-Json

# ANSI 색상
$e = [char]27
$reset = "$e[0m"; $dim = "$e[2m"
$cyan = "$e[36m"; $mag = "$e[35m"
$green = "$e[32m"; $yellow = "$e[33m"; $red = "$e[31m"

$parts = @()

# 모델
$model = $d.model.display_name
if ($model) { $parts += "$cyan$model$reset" }

# effort (모델이 지원할 때만 존재)
$effort = $d.effort.level
if ($effort) { $parts += "${dim}effort$reset $effort" }

# 컨텍스트 사용률 + 진행바
$pct = $d.context_window.used_percentage
if ($null -ne $pct) {
  $p = [int]$pct
  $filled = [math]::Floor($p / 10)
  if ($filled -gt 10) { $filled = 10 }
  if ($filled -lt 0) { $filled = 0 }
  $bar = ([string][char]0x2593) * $filled + ([string][char]0x2591) * (10 - $filled)
  $c = if ($p -ge 80) { $red } elseif ($p -ge 50) { $yellow } else { $green }
  $parts += "${dim}ctx$reset $c$bar$reset $p%"
}

# 세션 비용
$cost = $d.cost.total_cost_usd
if ($cost) { $parts += ('$' + ('{0:N2}' -f $cost)) }

# git 브랜치 (현재 디렉토리가 git repo 일 때만)
$dir = $d.workspace.current_dir
if ($dir) {
  $branch = git -C $dir rev-parse --abbrev-ref HEAD 2>$null
  if ($branch) { $parts += "$mag$branch$reset" }
}

# 5시간 레이트리밋 (Pro/Max 구독자, 첫 응답 후에만 존재)
$fh = $d.rate_limits.five_hour.used_percentage
if ($null -ne $fh) { $parts += ("${dim}5h$reset {0:N0}%" -f [double]$fh) }

$sep = " $dim" + ([char]0x00B7) + "$reset "
[Console]::Out.Write(($parts -join $sep))
