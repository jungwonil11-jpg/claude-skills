# Claude Code 알림 hook — Stop(작업 종료) / Notification(입력·의사결정 대기)
# 토스트(폴더명 표시) + 소리 + "알람 띄운 그 PowerShell 창" 자동 앞으로/깜빡임.
param([string]$EventType = 'Stop')
$ErrorActionPreference = 'SilentlyContinue'

# --- 1) hook payload 읽기: cwd(어느 프로젝트인지), message ---
$raw = [Console]::In.ReadToEnd()
$cwd = $null; $msg = $null
if ($raw) { try { $j = $raw | ConvertFrom-Json; $cwd = $j.cwd; $msg = $j.message } catch {} }
$proj = if ($cwd) { Split-Path $cwd -Leaf } else { 'Claude Code' }

# --- 2) 이 hook 을 띄운 호스트 터미널 창(HWND) 찾기: 부모 프로세스 체인 추적 ---
# 트리: powershell(창) -> node(claude) -> bash -> pwsh(notify.ps1=$PID)
$hwnd = [IntPtr]::Zero
try {
  $procs = @{}
  Get-CimInstance Win32_Process | ForEach-Object { $procs[[int]$_.ProcessId] = $_ }
  $cur = $PID
  for ($i = 0; $i -lt 12; $i++) {
    $p = $procs[$cur]; if (-not $p) { break }
    $ppid = [int]$p.ParentProcessId; if (-not $ppid) { break }
    $par = Get-Process -Id $ppid -ErrorAction SilentlyContinue
    if ($par -and ($par.ProcessName -in @('powershell','pwsh','WindowsTerminal')) -and $par.MainWindowHandle -ne 0) {
      $hwnd = $par.MainWindowHandle; break
    }
    $cur = $ppid
  }
} catch {}

# --- 3) 이벤트별 소리 + 토스트 문구 ---
if ($EventType -eq 'Notification') {
  $detail = if ($msg) { $msg } else { '의사결정 / 권한 승인 필요' }
  $title  = "$([char]0x26A0) $proj"          # ⚠ 폴더명
  $body   = "입력 대기 — $detail"
  [System.Media.SystemSounds]::Question.Play()
} else {
  $title  = "$([char]0x2705) $proj"          # ✓ 폴더명
  $body   = '작업 완료 — 응답이 끝났음'
  [System.Media.SystemSounds]::Asterisk.Play()
}

# --- 4) 그 창을 앞으로 + 작업표시줄 깜빡임 ---
if ($hwnd -ne [IntPtr]::Zero) {
  try {
    Add-Type -ErrorAction SilentlyContinue @"
using System;
using System.Runtime.InteropServices;
public class WinFocus {
  [StructLayout(LayoutKind.Sequential)] public struct FLASHWINFO { public uint cbSize; public IntPtr hwnd; public uint dwFlags; public uint uCount; public uint dwTimeout; }
  [DllImport("user32.dll")] public static extern bool FlashWindowEx(ref FLASHWINFO p);
  [DllImport("user32.dll")] public static extern bool SetForegroundWindow(IntPtr h);
  [DllImport("user32.dll")] public static extern bool ShowWindow(IntPtr h, int n);
}
"@
    [WinFocus]::ShowWindow($hwnd, 9) | Out-Null        # 9 = SW_RESTORE (최소화돼 있으면 복원)
    [WinFocus]::SetForegroundWindow($hwnd) | Out-Null  # 앞으로 (포그라운드 잠금 시 깜빡임으로 대체됨)
    $fi = New-Object WinFocus+FLASHWINFO
    $fi.cbSize   = [System.Runtime.InteropServices.Marshal]::SizeOf($fi)
    $fi.hwnd     = $hwnd
    $fi.dwFlags  = 3      # FLASHW_ALL (제목표시줄+작업표시줄)
    $fi.uCount   = 5
    $fi.dwTimeout = 0
    [WinFocus]::FlashWindowEx([ref]$fi) | Out-Null
  } catch {}
}

# --- 5) 토스트 ---
try { Import-Module BurntToast -ErrorAction Stop; New-BurntToastNotification -Text $title, $body } catch {}

# --- 진단 로그 (창 못 찾을 때 추적용) ---
try { "$(Get-Date -Format 'HH:mm:ss') $EventType proj=$proj hwnd=$hwnd" | Out-File "$HOME\.claude\hooks\notify-debug.log" -Append -Encoding utf8 } catch {}
