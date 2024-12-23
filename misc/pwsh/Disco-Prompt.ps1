# Disco prompt port with baterries
# Author: Brandon Piesch

function Set-DiscoOption {
  <#
  .SYNOPSIS

  Configures the Disco prompt with various customization options.

  .DESCRIPTION

  This function allows you to tailor the appearance and behavior of the Disco prompt to your preferences.
  You can adjust colors, component formatting, path shortening, and status persistence.

  .PARAMETER Default

  Resets all prompt configuration options to their default values.

  .PARAMETER UserColor

  Sets the color of the username component. Accepts HEX codes.

  .PARAMETER AtColor

  Sets the color of the "@" symbol preceding the hostname. Accepts HEX codes.

  .PARAMETER HostColor

  Sets the color of the hostname component. Accepts HEX codes.

  .PARAMETER CwdColor

  Sets the color of the current working directory (CWD) component. Ignored when CwdHashColor is $true. Accepts HEX codes.

  .PARAMETER NormalColor

  Sets the color of non-error text in the prompt. Accepts HEX codes.

  .PARAMETER ErrorColor

  Sets the color of error text in the prompt. Accepts HEX codes.

  .PARAMETER HostName

  Overrides the automatic detection of the hostname. Specify a custom hostname to display in the prompt.

  .PARAMETER UserName

  Overrides the automatic detection of the username. Specify a custom username to display in the prompt.

  .PARAMETER AtString

  Replaces the default " at " string with a custom string before the hostname.

  .PARAMETER Delimiter

  Sets the delimiter between components in the prompt. Defaults to a space.

  .PARAMETER DelimiterAdmin

  Sets a different delimiter to use when running as administrator.

  .PARAMETER CwdShorten

  Shortens the displayed CWD path for improved readability. (Example: /usr/etc/ssh -> /u/e/ssh)

  .PARAMETER CwdHashColor

  Generates a unique color for the CWD based on a hash of its path.

  .PARAMETER StickyStatus

  Shows the exit status/code of the previous command in the prompt even if it was successful.

  .EXAMPLE

  Set-DiscoConfig -UserColor '#00FF00' -CwdShorten $true -StickyStatus $true

  This sets the username color to green, enables CWD shortening, and enables sticky status.
  #>

  [CmdletBinding()]
  param (
    [switch]$Default,
    [string]$UserColor,
    [string]$AtColor,
    [string]$HostColor,
    [string]$CwdColor,
    [string]$NormalColor,
    [string]$ErrorColor,
    [ValidateScript(
      { $_.Count -le 1 } # Use name, color
    )]
    [string[]]$SetColor,
    [string]$HostName,
    [string]$UserName,
    [string]$AtString,
    [string]$Delimiter,
    [string]$DelimiterAdmin,
    [System.Nullable[bool]]$CwdShorten,
    [System.Nullable[bool]]$CwdHashColor,
    [System.Nullable[bool]]$StickyStatus
  )

  # Function to validate and update color hex string
  function Test-AndUpdateColor {
    param (
      [string]$Color,
      [string]$PropertyName
    )

    if (!$Color) { return }
    # Regex pattern for validating hex or Minecraft color string
    if ($Color -match '^(#[A-Fa-f0-9]{6}|&[0-9a-fl-or])$') {
      $Global:Disco.colors.$PropertyName = $Color
    }
    else {
      Write-Error "Invalid color string: $Color"
    }
  }

  # Initialize config if not already defined or set to default
  if (-not $Global:Disco -or $Default) {
    $Global:Disco = @{
      colors   = @{
        user   = "#eb6434"
        at     = "#e8e8e8"
        host   = "#fbdc5d"
        cwd    = "#e8e8e8"
        normal = "#e8e8e8"
        error  = "#de4b4b"
      }
      str      = @{
        host     = ${env:COMPUTERNAME}.ToLower()
        user     = ${env:USERNAME}
        at       = " at "
        delim    = "`u{25ba}" # ►
        delimAlt = "`u{26a1}" # ⚡
      }
      blocks   = @(
        { "#user#$($str.user)#r#" }
        { "#at#$($str.at)#r#" }
        { "#host#$($str.host)#r#" }
        { if ($str.duration) { ":`e[38;2;255;85;255m$($str.duration)`e[0m" } }
        { ":$($colors.cwd)$($str.cwd)$($colors.normal)" }
        { if ($str.status) { "$($str.status)" } }
        { "$($str.delim)$($colors.reset) " }
      )
      cwdShort = $true # Shorten CWD strings.
      cwdColor = $true # CWD color based on its hash.
      stickySt = $false # Always show last status
    }
    # Go back when only need to reset to defaults
    return
  }

  $configBefore = $Global:Disco | Select-Object -ExcludeProperty data | ConvertTo-Json -WarningAction Ignore # ignore 'depth serialization blah blah'

  # Validate and update color hex strings
  Test-AndUpdateColor -Color $UserColor -PropertyName "user"
  Test-AndUpdateColor -Color $AtColor -PropertyName "at"
  Test-AndUpdateColor -Color $HostColor -PropertyName "host"
  Test-AndUpdateColor -Color $CwdColor -PropertyName "cwd"
  Test-AndUpdateColor -Color $NormalColor -PropertyName "normal"
  Test-AndUpdateColor -Color $ErrorColor -PropertyName "error"
  # Do accept new colors
  if ($SetColor.Count -gt 0) {
    Test-AndUpdateColor -Color $SetColor[1] -PropertyName $SetColor[0]
  }

  # Update config with provided values
  if ($HostName) { $Global:Disco.str.host = $HostName }
  if ($UserName) { $Global:Disco.str.user = $UserName }
  if ($AtString) { $Global:Disco.str.at = $AtString }
  # May we check for utf-8 support (PSReadLine functions don't seem to support them)
  if ($Delimiter) { $Global:Disco.str.delim = $Delimiter }
  if ($DelimiterAdmin) { $Global:Disco.str.delimAlt = $DelimiterAdmin }
  if ($null -ne $CwdShorten) { $Global:Disco.cwdShort = $CwdShorten }
  if ($null -ne $CwdHashColor) { $Global:Disco.cwdColor = $CwdHashColor }
  if ($null -ne $StickyStatus) { $Global:Disco.stickySt = $StickyStatus }

  $configAfter = $Global:Disco | Select-Object -ExcludeProperty data | ConvertTo-Json -WarningAction Ignore # ignore 'depth serialization blah blah'
  # Only if prompt called at least one time ...
  if ($null -eq $Global:Disco.data) { return }
  # ... notify changes and make prompt aware
  if ($configBefore -ne $configAfter) {
    Write-Host "Config updated!"
    $Global:Disco.data.update = $true
  }
  else {
    Write-Output "No changes were made to the config."
  }
}

if (-not $Global:Disco) {
  Set-DiscoConfig -Default
}

function Get-ElapsedTime {
  <#
    .Synopsis
      Get the time span elapsed during the execution of command (by default the previous command)
    .Description
      Calls Get-History to return a single command and returns the difference between the Start and End execution time
  #>
  [OutputType([string])]
  [CmdletBinding()]
  param(
    # The command ID to get the execution time for (defaults to the previous command)
    [Parameter()]
    [int]$Id,

    # A Timespan format pattern such as "{0:ss\.ffff}"
    [Parameter()]
    [string]$Format = "{0:d\d\ h\:mm\:ss\.ffff}",

    # If set trim leading zeros and separators off to make the string as short as possible
    [switch]$Trim
  )
  $null = $PSBoundParameters.Remove("Format")
  $null = $PSBoundParameters.Remove("Trim")
  $LastCommand = Get-History -Count 1 @PSBoundParameters
  if (!$LastCommand) { return "" }
  $Duration = $LastCommand.EndExecutionTime - $LastCommand.StartExecutionTime
  $Result = $Format -f $Duration
  if ($Trim) {
    $Short = $Result.Trim("0:d .")
    if ($Short.Length -lt 5) {
      $Short + "ms"
    }
    elseif ($Short.Length -lt 8) {
      $Short + "s"
    }
    else {
      $Short
    }
  }
  else {
    $Result
  }
}

function Get-ShortCwd {
  [OutputType([string])]
  [CmdletBinding()]
  param(
    [string]$Cwd
  )

  # Replace ${HOME} with ~
  $dirSep = [System.IO.Path]::DirectorySeparatorChar
  if (${Cwd}.StartsWith(${HOME})) {
    $Cwd = "~$(${Cwd}.Substring(${HOME}.Length))"
  }
  $dirRegex = '/(([^/]*$)|([^/]*))'
  if ($IsWindows) { $dirRegex = '\\(([^\\]*$)|([^\\]*))' }

  $Cwd -creplace $dirRegex, {
    $dir = $_.Groups[2].ToString()
    if ($dir -ne "") {
      "${dirSep}${dir}"
    }
    else {
      $dir = $_.Groups[1].ToString()
      if ($dir -like '.*') {
        "${dirSep}$(${dir}.Substring(0,2))"
      }
      else {
        "${dirSep}$(${dir}.Substring(0,1))"
      }
    }
  }
}

function Get-StringHash {
  [OutputType([string])]
  [CmdletBinding()]
  param(
    [Parameter(Position = 0, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true, Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string]$String,
    [ValidateSet('SHA1', 'SHA256', 'SHA384', 'SHA512', 'MD5')]
    [string]$Algorithm = "SHA256"
  )
  $memStream = [IO.MemoryStream]::new([byte[]][char[]]$String)
  $hash = Get-FileHash -InputStream $memStream -Algorithm $Algorithm
  return $hash.Hash
}

function Get-TermColorFromHex {
  [OutputType([string])]
  [CmdletBinding()]
  param (
    [Parameter(Mandatory = $true, Position = 0)]
    [ValidateScript({
        # Use #RRGGBB format
        $_ -match '#[a-fA-F0-9]{6}'
      })]
    [string]$Hex,
    [switch]$Background
  )
  $c = [int[]](($Hex -replace '#(..)(..)(..)', '0x${1},0x${2},0x${3}') -split ',')
  if ($Background) {
    return "`e[48;2;{0};{1};{2}m" -f $c[0], $c[1], $c[2]
  }
  "`e[38;2;{0};{1};{2}m" -f $c[0], $c[1], $c[2]
}

function Get-TermColorFromRgb {
  [OutputType([string])]
  [CmdletBinding()]
  param (
    [Parameter(Mandatory = $true, Position = 0)]
    [int[]]$Rgb,
    [switch]$Background
  )
  if ($Background) {
    return "`e[48;2;{0};{1};{2}m" -f $Rgb[0], $Rgb[1], $Rgb[2]
  }
  "`e[38;2;{0};{1};{2}m" -f $Rgb[0], $Rgb[1], $Rgb[2]
}

# Credits: powerline
function Test-Elevation {
  if (-not ($IsLinux -or $IsMacOS)) {
    [Security.Principal.WindowsIdentity]::GetCurrent().Owner.IsWellKnown("BuiltInAdministratorsSid")
  }
  else {
    0 -eq (id -u)
  }
}

function Update-PromptData {
  [CmdletBinding()]
  # Get last exit status
  $lastStatus = $?
  $lastExit = $LASTEXITCODE

  $str = @{
    user  = $Global:Disco.str.user
    at    = $Global:Disco.str.at
    host  = $Global:Disco.str.host
    cwd   = (Get-Location).Path
    delim = & {
      # Check if user is admin/root to set $delim
      if (Test-Elevation) { $Global:Disco.str.delimAlt }
      else { $Global:Disco.str.delim }
    }
    jobs  = @(Get-Job | Where-Object { $_.State -eq 'Running' }).Count
  }
  $cwdHash = Get-StringHash $str.cwd

  # Booleans to not rebuild prompt/opts every run
  $firstCall = $null -eq $Global:Disco.data
  $dirChanged = !($cwdHash -eq $Global:Disco.data.cwdhash)
  $build = $firstCall -or $Global:Disco.data.update

  # Convert the color codes to term codes
  if ($build) {
    $colors = @{
      bg = @{}
    }
    foreach ($color in $Global:Disco.colors.Keys) {
      if ($Global:Disco.colors[$color] -match '&[0-9a-fl-or]') {
        $colors[$color] = Convert-MinecraftColorsToANSI $Global:Disco.colors[$color]
        $colors.bg[$color] = Convert-MinecraftColorsToANSI $Global:Disco.colors[$color] -Background
      }
      else {
        $colors[$color] = Get-TermColorFromHex $Global:Disco.colors[$color]
        $colors.bg[$color] = Get-TermColorFromHex $Global:Disco.colors[$color] -Background
      }
    }
    $colors.reset = "`e[0m"
  }
  else { $colors = $Global:Disco.data.colors }

  # If dir didn't change, use same (color and short cwd) as before
  if (!$dirChanged) {
    $str.cwd = $Global:Disco.data.str.cwd
    $colors.cwd = $Global:Disco.data.colors.cwd
  }

  # Generate dir color/string on-dir-change
  if ($dirChanged -or $firstCall) {
    # Get color from current work dir string hash
    if ($Global:Disco.cwdColor) {
      $shas = [System.Int64](($cwdHash -creplace '[a-zA-Z]', { [byte][char]$_.toString() }).Substring(0, 10))
      $shas = $shas.ToString("X").PadRight(6, "0") -split '(?<=\G..)'
      $col = [int[]]@(
        ("0x" + $shas[0])
        ("0x" + $shas[1])
        ("0x" + $shas[2])
      )
      # If the luminance is below 120 (out of 255), add some more.
      # this runs at most twice because we add 60
      # May we check the background color to add or remove...
      while ($col[0] -lt 120 -or $col[1] -lt 120 -or $col[2] -lt 120) {
        $col[0] = [math]::Min(255, $col[0] + 60)
        $col[1] = [math]::Min(255, $col[1] + 60)
        $col[2] = [math]::Min(255, $col[2] + 60)
      }
      # Override color
      $colors.cwd = Get-TermColorFromRgb $col
    }
    # Shorten current work dir string
    if ($Global:Disco.cwdShort) {
      $str.cwd = Get-ShortCwd $str.cwd
    }
  }

  # Prompt status only if it's not 0
  $str.status = ""
  # &b From starship
  if ($lastCmd = Get-History -Count 1) {
    # In case we have a False, we know there's an error.
    if (-not $lastStatus) {
      # We retrieve the InvocationInfo from the most recent error using $Global:Error[0]
      $lastCmdletError = try { $Global:Error[0] | Where-Object { $_ -ne $null } | Select-Object -ExpandProperty InvocationInfo } catch { $null }
      # We check if the last command executed matches the line that caused the last error, in which case we know
      # it was an internal Powershell command, otherwise, there MUST be an error code.
      $lastExit = if ($null -ne $lastCmdletError -and $lastCmd.CommandLine -eq $lastCmdletError.Line) { $lastStatus } else { '#' }
      # &b until here
      $str.status = "$($colors.error)[${lastExit}]$($colors.reset)"
    }
    # Here, there is no error but sticky status shows success too
    elseif ($Global:Disco.stickySt) {
      $str.status = "$($colors.error)[True]$($colors.reset)"
    }
    $str.duration = Get-ElapsedTime -Trim
  }

  # Get the size of the terminal window
  # $width = $Host.UI.RawUI.WindowSize.Width
  # $height = $Host.UI.RawUI.WindowSize.Height

  # Build prompt
  # if ($build) ...
  foreach ($block in $Global:Disco.blocks) {
    $prompt += (& $block) -creplace '(?<=^|[^#%])(#|%)(\w+)#', {
      $tp = $_.Groups[1].ToString()
      $cl = $_.Groups[2].ToString()
      if ($cl -eq "r") { return $colors.reset }
      if ($null -eq $colors[$cl]) { return "" }
      if ($tp -eq "#") { return $colors[$cl] }
      if ($tp -eq "%") { return $colors.bg[$cl] }
    }
  }

  # Save info to not run all everytime
  $Global:Disco.data = @{
    prompt  = $prompt
    str     = $str
    cwdhash = $cwdHash
    colors  = $colors
    status  = $lastStatus
    rootmod = $elevatedUser
    update  = $false
  }
}

function Prompt {
  [OutputType([string])]
  [CmdletBinding()]
  Param()
  # We need to check unicode characters errors
  Update-PromptData # Update prompt string
  return $Global:Disco.data.prompt
}

Set-PSReadLineKeyHandler -Chord 'Ctrl+l' -ScriptBlock {
  # > Content of Clear-Host function
  $RawUI = $Host.UI.RawUI
  $RawUI.SetBufferContents(
    @{ Top = -1; Bottom = -1; Right = -1; Left = -1 },
    @{ Character = ' '; ForegroundColor = $RawUI.ForegroundColor; BackgroundColor = $RawUI.BackgroundColor }
  )
  $RawUI.CursorPosition = @{ X = 0; Y = 0 }
  # <

  [Microsoft.PowerShell.PSConsoleReadLine]::ClearScreen()
}

# Important step, otherwise utf-8 characters are just **ignored**
[Console]::OutputEncoding = [Text.Encoding]::UTF8
