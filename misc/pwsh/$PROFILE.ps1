# Klapptnot's PowerShell profile file

function Wait-ForKeyPress {
  param (
    [string]$Message = "Press any key to continue..."
  )

  Write-Host $Message
  $null = $host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
}

function Get-UniqueHistory {
  param(
    [switch]$Write,
    [switch]$Dedup
  )

  $hsPath = (Get-PSReadLineOption).HistorySavePath
  $hsContent = Get-Content -Path $hsPath
  # [array]::Reverse($hsContent)
  $hsContent = ($hsContent[($hsContent.Length - 1)..0])
  if ($Dedup) {
    $hsLines = [System.Collections.Generic.HashSet[string]]::new()
  }
  else {
    $hsLines = [System.Collections.ArrayList]::new()
  }
  $hsContent | ForEach-Object {
    # Remove multiline, repeated characters lines,
    # any -* (Possible option with no command)
    # #!> ending (do not remember)
    if ($_ -match '(?:`$|(.)\1+$|^-|#!>$)') { return }
    # `.\folder\` isn't saved, only `.\executable` (if not executable, it opens the file)
    $item = $_ -replace '^(\.[^\s].*|[a-zA-Z]:.*)', '& "$1"'
    $hsLines.Add($item) | Out-Null
  }
  $hsLines = $hsLines -split '\n'
  $hsLines = ($hsLines[($hsLines.Length - 1)..0])
  if ($Write) {
    $hsLines | Set-Content -Path $hsPath
    return
  }
  $hsLines
}
# Clean history file
Get-UniqueHistory -Write -Dedup

function Add-ToPathFolder {
  [CmdletBinding()]
  param (
    [Parameter(Position = 0)]
    [string] $ItemPath,
    [Parameter(Position = 1)]
    [string] $Name = "",
    [Parameter(Position = 2)]
    [string] $ExecPath = "",
    [switch] $Update,
    [switch] $Cargo
  )

  if ([string]::IsNullOrEmpty($ItemPath) -and -not $Cargo) {
    Write-Error "An ItemPath must be given"
    return
  }
  elseif ($Cargo) {
    $ItemPath = (Get-Location).Path
    $ItemPath = Join-Path -Path $ItemPath -ChildPath "\target\release\$((Get-Item $ItemPath).BaseName).exe"
  }

  # Get home directory
  $homePath = Resolve-Path -Path $env:HOMEPATH

  # Create destination path in $HOME\bin (and create it if it doesn't exist)
  $destPath = Join-Path $homePath "bin"
  if (!(Test-Path $destPath)) {
    New-Item -ItemType Directory -Force -Path $destPath | Out-Null
  }

  # Get resolved path
  $ItemPath = Resolve-Path -Path $ItemPath -ErrorAction Stop

  # Check if path exists
  if (!(Test-Path $ItemPath)) {
    Write-Error "The path $ItemPath does not exist."
    return
  }

  # Now handle copying based on path type and ExecPath
  if (Test-Path -Path $ItemPath -PathType Leaf) {
    if ($Name -ne "") {
      $Name = "${Name}$((Get-Item -Path $ItemPath).Extension)"
    }
    else {
      $Name = "$((Get-Item -Path $ItemPath).Name)"
    }
    $destPath = Join-Path -Path $destPath -ChildPath $Name
    if (Test-Path -Path $destPath) {
      if (!($Update)) {
        Write-Error "File already exists, to overwrite use -Update flag"
        return
      }
      Remove-Item -Path $destPath
    }
    Copy-Item $ItemPath $destPath
  }
  elseif (Test-Path -Path $ItemPath -PathType Container) {
    if (Test-Path -Path $destPath) {
      Remove-Item -Path $destPath -Force -Confirm -ErrorAction Stop
    }
    Copy-Item $ItemPath $destPath -Recurse

    # If folder and -ExecPath provided, check for executable within path
    if ($null -ne $ExecPath) {
      $ExecPath = Resolve-Path -Path $ExecPath
      $ExecPath = Join-Path -Path $homePath -ChildPath $ExecPath.Path.Substring(((Get-Location).Path).Length)

      if ($null -ne $Name) {
        $ps1Path = Join-Path -Path $destPath -ChildPath "${Name}.ps1"
      }
      else {
        $ps1Path = Join-Path -Path $destPath -ChildPath "$((Get-Item -Path $ItemPath).BaseName).ps1"
      }

      if ($Update -and (Test-Path -Path $ps1Path)) {
        Remove-Item -Path $ps1Path
      }

      @"
# Get the current directory
`$scriptDir = Split-Path -Parent `$MyInvocation.MyCommand.Path

# Set the path to the path of main.exe
`$exePath = Join-Path -Path `$scriptDir -ChildPath "$ExecPath"

# Run main.exe with the provided arguments
& `$exePath `$args
"@ | Out-File $ps1Path
    }
  }
  else {
    Write-Error "The path $ItemPath is a folder, but no -ExecPath parameter was specified. It will not be copied."
  }
}


function Limit-Output {
  param(
    [Parameter(ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true, Mandatory = $true)]
    $Output,
    [Parameter(Mandatory = $true, Position = 0)]
    [string]$Filter,
    [switch]$Raw
  )

  process {
    # Function to check if line matches filter
    function MatchesFilter($line) {
      # if (!$Raw) {
      #   # Sanitize escape characters if not -Raw
      #   # $line = $line -replace '\\([a-fA-F0-9]{2})', [char]::ConvertFromUInt32($matches[1], 16)
      #   # $line = $line -replace '\\([a-fA-F0-9]{2})', ""
      # }
      return -not ($line -match $Filter)
    }

    # Read lines from input (stdin by default)
    if ($line = $Output) {
      if (MatchesFilter($line)) {
        Write-Host $line
      }
    }
  }
}

function Move-CursorSmoothly {
  [CmdletBinding()]
  param(
    [Parameter(Mandatory = $true)]
    [int] $X,
    [Parameter(Mandatory = $true)]
    [int] $Y,
    [Parameter()]
    [int] $Steps = 10, # Number of steps for smoother movement
    [Parameter()]
    [int] $Randomness = 5, # Maximum random deviation per step (for Random mode)
    [int] $Ress = 1, # Speed variation
    [Parameter(Mandatory = $false)]
    [switch] $Ziging, # Mode switch for random zig-zag movement
    [Parameter(Mandatory = $false)]
    [switch] $Wave # Mode switch for wave movement
  )

  Add-Type -AssemblyName System.Windows.Forms

  $currentPoint = [System.Windows.Forms.Cursor]::Position
  $Xi = $currentPoint.X
  $Yi = $currentPoint.Y

  # Calculate distance for each step (common for all modes)
  $dx = ($X - $Xi) / $Steps
  $dy = ($Y - $Yi) / $Steps

  # Move the cursor based on the selected mode
  if ($Ziging) {
    # Random movement mode
    for ($i = 1; $i -le $Steps; $i++) {
      $randomX = Get-Random -Minimum -$Randomness -Maximum $Randomness
      $randomY = Get-Random -Minimum -$Randomness -Maximum $Randomness

      $currentX = $Xi + ($dx * $i) + $randomX
      $currentY = $Yi + ($dy * $i) + $randomY

      [System.Windows.Forms.Cursor]::Position = New-Object System.Drawing.Point($currentX, $currentY)
      Start-Sleep -Milliseconds (5 + (Get-Random -Minimum 0 -Maximum $Ress))  # Random speed with baseline pause
      # Start-Sleep -Milliseconds 5  # Adjust pause for desired speed
    }
  }
  elseif ($Wave) {
    # Wave movement mode
    $waveFactor = 3  # Adjust for wave amplitude
    for ($i = 1; $i -le $Steps; $i++) {
      $waveOffset = $waveFactor * [math]::Sin(($i / $Steps) * (2 * [math]::PI))
      $currentX = $Xi + ($dx * $i)
      $currentY = $Yi + ($dy * $i) + $waveOffset

      [System.Windows.Forms.Cursor]::Position = New-Object System.Drawing.Point($currentX, $currentY)
      Start-Sleep -Milliseconds (5 + (Get-Random -Minimum 0 -Maximum $Ress))  # Random speed with baseline pause
      # Start-Sleep -Milliseconds 5  # Adjust pause for desired speed
    }
  }
  else {
    # Default straight line movement
    for ($i = 1; $i -le $Steps; $i++) {
      $currentX = $Xi + ($dx * $i)
      $currentY = $Yi + ($dy * $i)
      [System.Windows.Forms.Cursor]::Position = New-Object System.Drawing.Point($currentX, $currentY)
      Start-Sleep -Milliseconds (5 + (Get-Random -Minimum 0 -Maximum $Ress))  # Random speed with baseline pause
      # Start-Sleep -Milliseconds 5  # Adjust pause for desired speed
    }
  }
}


function Send-MouseClick {
  param(
    [System.Nullable[int]] $X,
    [System.Nullable[int]] $Y,
    [switch] $Right
  )


  [System.Reflection.Assembly]::LoadWithPartialName("user32.dll") | Out-Null
  Add-Type -MemberDefinition '[DllImport("user32.dll")] public static extern void mouse_event(int flags, int dx, int dy, int cButtons, int info);' -Name U32 -Namespace W

  $down, $up = 2, 4
  if ($Right) {
    $down, $up = 8, 16
  }

  # Move cursor to pos if given
  if ($null -ne $X -and $null -ne $Y) {
    # Load necessary assembly for mouse control
    Add-Type -AssemblyName System.Windows.Forms
    [System.Windows.Forms.Cursor]::Position = New-Object System.Drawing.Point($X, $Y)
  }

  # Simulate left-click down and up
  [W.U32]::mouse_event($down, 0, 0, 0, 0)
  [W.U32]::mouse_event($up, 0, 0, 0, 0)
}

function Set-Wallpaper {
  param (
    [Parameter(Mandatory = $true, Position = 0, ValueFromPipeline = $true)]
    [string]$ImagePath
  )
  Add-Type -TypeDefinition @'
using System;
using System.Runtime.InteropServices;

public class Wallpaper {
    [DllImport("user32.dll", CharSet = CharSet.Auto)]
    public static extern int SystemParametersInfo(int uAction, int uParam, string lpvParam, int fuWinIni);
}
'@

  $SPI_SETDESKWALLPAPER = 0x0014
  $SPIF_UPDATEINIFILE = 0x01
  $SPIF_SENDCHANGE = 0x02

  # Expand the image path to a full path
  $fullImagePath = Convert-Path $ImagePath

  # Check if the file exists
  if (-not (Test-Path -Path $fullImagePath -PathType Leaf)) {
    Write-Host "Image file not found: $fullImagePath"
    return
  }

  # Check if the file has a valid image extension
  $validExtensions = @(".jpg", ".jpeg", ".png", ".bmp", ".gif")
  $fileExtension = [System.IO.Path]::GetExtension($fullImagePath).ToLower()
  if ($validExtensions -notcontains $fileExtension) {
    Write-Host "Invalid image file format. Supported formats: $($validExtensions -join ', ')"
    return
  }

  # Set the wallpaper
  [Wallpaper]::SystemParametersInfo($SPI_SETDESKWALLPAPER, 0, $fullImagePath, $SPIF_UPDATEINIFILE -bor $SPIF_SENDCHANGE)
  Write-Host "Wallpaper set to: $fullImagePath"
}

function Add-PathToEnvironmentVariable {
  <#
  .SYNOPSIS
  Adds one or more paths to the `PATH` environment variable.

  .DESCRIPTION
  This function adds one or more paths to the `PATH` environment variable.
  It offers flexibility with `-Prepend`, `-Silent`, and `-Perma` flags and handles path validation.

  .PARAMETER Prepend
  When specified, prepends the paths to the beginning of the `PATH` variable.
  Otherwise, appends by default. However, if multiple paths are provided,
  the function always appends regardless of the `-Prepend` flag.

  .PARAMETER Silent
  Suppresses the "PATH environment variable updated" message.

  .PARAMETER Perma
  When specified, modifies the user registry path for the `PATH` variable
  (requires administrator privileges).

  .PARAMETER Paths
  An array of paths to add to the `PATH` variable. Paths are also accepted
  from remaining arguments.

  .INPUTS
  Paths (string[])

  .OUTPUTS
  None

  .EXAMPLES
  Add-PathToEnvironmentVariable -Paths "C:\NewTools", "D:\Scripts"

  # Using remaining arguments
  Add-PathToEnvironmentVariable "C:\Python" "E:\Java"

  # Add to registry (requires administrator)
  Add-PathToEnvironmentVariable -Perma -Paths "C:\NewTools"

  .NOTES
  * The function validates the input type for `Paths`.
  * It checks if each path exists using `Test-Path`. If a path doesn't exist,
    a warning message is written, but the function continues processing other paths.
  * The updated `PATH` environment variable is set using `$env:Path` (for non-permanent)
    or registry modification (for permanent).
  #>

  param(
    [Parameter(Mandatory = $false)]
    [switch] $Prepend,
    [Parameter(Mandatory = $false)]
    [switch] $Silent,
    [Parameter(Mandatory = $false)]
    [switch] $Perma,

    [Parameter(ValueFromRemainingArguments = $true)]
    [string[]]$Paths
  )

  begin {
    # Validate input type
    if (!($Paths -is [string[]])) {
      throw "Invalid input type. Paths must be provided as an array of strings."
    }
    if ($Prepend) { $Prepend = $Paths.Count -eq 1 }
    if ($Perma -and !([Security.Principal.WindowsIdentity]::GetCurrent().Owner.IsWellKnown("BuiltInAdministratorsSid"))) {
      Write-Error "Modifying registry requires administrator privileges."
      return
    }
  }

  process {
    # Get current PATH environment variable
    if ($Perma) {
      $currentPath = Get-ItemProperty -Path HKCU:\Environment -Name Path
    }
    else {
      $currentPath = $env:Path
    }

    $newPath = $currentPath
    # Loop through each path
    foreach ($path in $Paths) {
      if (!(Test-Path -Path $path -Type Container)) {
        # Write a warning message for non-existent paths
        Write-Warning "Path '$path' does not exist and will be skipped."
        continue
      }
      $path = (Resolve-Path -Path $path ).Path

      $regexAddPath = [regex]::Escape($path)
      if (($currentPath -split ';' | Where-Object { $_ -match "^$regexAddPath\\?$" }).Count -gt 0) {
        Write-Warning "Path '$path' is already added."
      }
      else {
        if ($Prepend) {
          $newPath = $path + ';' + $newPath
        }
        else {
          $newPath += ';' + $path
        }
      }
    }
  }

  end {
    if ($newPath -ne $currentPath) {
      if ($Perma) {
        Set-ItemProperty -Path HKCU:\Environment -Name Path -Value $newPath
      }
      else {
        # Set the modified PATH environment variable
        $env:Path = $newPath
      }
      if (!($Silent)) {
        Write-Host "PATH environment variable updated."
      }
    }
  }
}


function Get-Phone {
  param (
    [Parameter(
      ValueFromPipelineByPropertyName = $true,
      ValueFromPipeline = $true, Position = 0
    )]
    [string]$Api,
    [switch]$Notifications,
    [Parameter(ValueFromRemainingArguments = $true)]
    [string[]]$ArgsStream
  )
  if ($Notifications) {
    ssh 192.168.1.128 -p 8022 lsnot
    return
  }
  # Define the regular expression pattern for short and long GNU arguments
  $argPattern = '^(-[a-zA-Z0-9]|--[a-zA-Z0-9-]+)$'

  # Define the regular expression pattern for ${varname} with restrictions and functions
  # $anyBashVarPattern = '\$(?:(?<redirOrLen>[!#])?(?<var>(?:[a-zA-Z][a-zA-Z0-9_]*|[0-9]{2,}|[!\?_$$#0-9]))|\{(?:\{[^\{\}]*\}|[^\{\}])*\})'
  # $bashSubShellPattern = '\$\((\([^\(\)]*\)|[^\(\)])*\)'
  # $bashBasicVarPattern = '\$(?<redirOrLen>[!#])?(?<var>(?:[a-zA-Z][a-zA-Z0-9_]*|[0-9]{2,}|[!\?_$$#0-9]))'
  $anyBashVarPattern = '\$(([!#])?([a-zA-Z][a-zA-Z0-9_]*|[!\?_$$#0-9])|\{(?:\{[^\{\}]*\}|[^\{\}])*\})'
  $bashPowerVarPattern = '\$\{(?<redirOrLen>[!#])?(?<var>(?:[a-zA-Z][a-zA-Z0-9_]*|[\?_\$]))(?:\[(?<key>(?:\{[^\{\}]*\}|[^\[\{\}])+)\])?(?:(?<rplOpr>\/[\/#%]?)(?<rplPatt>(?:\{[^\{\}]*\}|[^\[\/\{\}])*)(?:[\/](?<rplWith>(?:\{[^\{\}]*\}|[^\[\{\}])*))\}|(?<tformOpr>[\^,]{1,2})(?<fFormChars>(?:\{[^\{\}]*\}|[^\[\{\}])*)\}|:(?<colonOpr>[\-=\?+])(?<colonArg>(?:\{[^\{\}]*\}|[^\[\{\}])*)\}|:\s*(?<subStart>(?:\{[^\{\}]*\}|[^:\[\{\}])*)(?::\s*(?<subLen>(?:\{[^\{\}]*\}|[^:\[\{\}]))?)?\}|(?<getOpr>[#%]{1,2})(?<getPatt>(?:\{[^\{\}]*\}|[^\\{\}])*)\}|@(?<varOpr>[UulQEPAKak])\}|\})'

  # Loop through each item in ArgsStream
  for ($i = 0; $i -lt $ArgsStream.Count; $i++) {
    $item = $ArgsStream[$i] -replace '([^@]|^)api::([^\s]*)', '${1}termux-${2}'
    # Escape quotes as the string will always be expanded
    $item = $item -replace '"', '\"'
    $item = $item -replace "'", "'\''"
    # Check if the item matches the regex pattern for short or long GNU argument
    if ($item -match $argPattern) {
      # Continue if it matches, no quotation needed
      continue
    }

    # Check if the item contains bash variables
    $matchObj = ($item | Select-String -Pattern $anyBashVarPattern -AllMatches).Matches
    # Check if the item is a valid valiable
    for ($j = 0; $j -lt $matchObj.Count; $j++) {
      # Basic variables are ok
      $isPowerVar = $matchObj[$j].Groups[0].Value.StartsWith('${')
      $isValid = $matchObj[$j].Groups[0].Value -match $bashPowerVarPattern
      if ($isPowerVar -and -not $isValid) {
        Write-Error "Invalid syntax in variable named: $($matchObj[$j].Groups[0].Value). Exiting..."
        return
      }
    }
    # If has no items to expand, wrap it with single quotes
    # Check if the item is already wrapped with quotes
    if ($item -notmatch "^('.*'|`".*`")$") {
      $ArgsStream[$i] = "'$item'"
    }
    else {
      $ArgsStream[$i] = $item
    }
  }
  # api expands the Bash variables, which are send as/inside 'literal strings'
  # to avoid $SHELL to expand them (I use fish btw)
  ssh 192.168.1.128 -p 8022 api --expand $Api @ArgsStream
}

function Convert-MinecraftColorsToANSI {
  param (
    [string]$InputString,
    [switch]$Palette
  )

  # Define color mappings
  $formatMap = @{
    "0" = "38;2;0;0;0" # Black
    "1" = "38;2;0;0;170" # Dark Blue
    "2" = "38;2;0;170;0" # Dark Green
    "3" = "38;2;0;170;170" # Dark Aqua
    "4" = "38;2;170;0;0" # Dark Red
    "5" = "38;2;170;0;170" # Dark Purple
    "6" = "38;2;170;170;0" # Gold
    "7" = "38;2;170;170;170" # Gray
    "8" = "38;2;85;85;85" # Dark Gray
    "9" = "38;2;85;85;255" # Blue
    "a" = "38;2;85;255;85" # Green
    "b" = "38;2;85;255;255" # Aqua
    "c" = "38;2;255;85;85" # Red
    "d" = "38;2;255;85;255" # Light Purple
    "e" = "38;2;255;255;85" # Yellow
    "f" = "38;2;255;255;255" # White
    # Define format mappings
    "l" = "1"; # Bold
    "m" = "9"; # Strikethrough
    "n" = "4"; # Underline
    "o" = "3"; # Italic
    "r" = "0"; # Reset
  }

  # Add § support
  # Replace Minecraft color codes with ANSI escape codes
  $InputString -creplace "&(?<key>[0-9a-fl-or])", {
    $colorCode = $_.Groups[1].ToString()
    if ($formatMap.ContainsKey($colorCode)) {
      "`e[$($formatMap[$colorCode])m"
    }
  }
}

function Convert-IconToUnicode {
  param (
    [string]$InputString
  )

  # Define icon mappings
  $iconMap = @{
    "heart" = [char]0x2764 # Heart
    "star"  = [char]0x2605 # Star
    # Add more mappings as needed
  }

  # Replace icon placeholders with Unicode symbols
  $InputString -creplace "&(?<name>[a-zA-Z]+);", {
    $iconName = $_.Groups[1].ToString()
    if ($iconMap.ContainsKey($iconName)) {
      $iconMap[$iconName]
    }
    else {
      # no icon, unwrap and normalize:
      # camelCase -> camel case, PascalCase -> Pascal case
      $iconName -creplace '([^^])([A-Z])', {
        "$($_.Groups[1].ToString()) $($_.Groups[2].ToString().ToLower())"
      }
    }
  }
}

function Limit-Object {
  [CmdletBinding(DefaultParameterSetName = 'Property')]
  param (
    [Parameter(Position = 0, ParameterSetName = 'Property', Mandatory = $true)]
    [Object[]]$Property,

    [Parameter(ParameterSetName = 'InputObject', ValueFromPipeline = $true, Mandatory = $true)]
    [psobject]$InputObject,

    [string[]]$ExcludeProperty,
    [string]$ExpandProperty,
    [switch]$Unique,
    [switch]$CaseInsensitive,
    [int]$Last,
    [int]$First,
    [int]$Skip,
    [int]$SkipLast,
    [int[]]$Index,
    [int[]]$SkipIndex,
    [switch]$Wait
  )

  begin {
    $selectArgs = @{
      Property        = $Property
      InputObject     = $InputObject
      ExcludeProperty = $ExcludeProperty
      ExpandProperty  = $ExpandProperty
      Unique          = $Unique
      CaseInsensitive = $CaseInsensitive
      Last            = $Last
      First           = $First
      Skip            = $Skip
      SkipLast        = $SkipLast
      Index           = $Index
      SkipIndex       = $SkipIndex
      Wait            = $Wait
    }
  }

  process {
    $inputObject | ForEach-Object {
      $object = $_
      if ($selectArgs.Property -notcontains $object.PSObject.Properties.Name) {
        $object
      }
    }
  }
}

function Remove-GeminiChats ([int]$N = 5) {
  Start-Sleep 3
  1..$N | ForEach-Object {
    0..2 | ForEach-Object {
      $X = @(255; 350; 1200)
      $Y = @(305; 390; 650)
      Move-CursorSmoothly -X $X[$_] -Y $Y[$_] -Steps (Get-Random -Maximum 30 -Minimum 15)
      Send-MouseClick -X $X[$_] -Y $Y[$_]
      Start-Sleep (Get-Random -Maximum 1.5 -Minimum 0.5)
    }
  }
}

Set-PSReadLineOption -AddToHistoryHandler {
  Param (
    [string]$line
  )

  # Check if the command starts with spaces
  if (-not $line.TrimStart().Equals($line)) {
    return $false
  }

  # Ignore certain commands
  $IgnoreCommands = @(
    'git\s+clone\s+("[^"]*"|[^"\s]+)' # Ignore git clone <url>
  )

  for ($i = 0; $i -lt $IgnoreCommands.Length; $i++) {
    if ($line -match $IgnoreCommands[$i]) {
      return $false
    }
  }

  # Check if the command line is already in history as last constraint
  # $isInHistory = Select-String -Path $hsPath -Pattern $line -Quiet -SimpleMatch
  # return -not $isInHistory
  return $true
}

Set-PSReadlineOption -BellStyle None
Set-PSReadLineKeyHandler -Chord 'Ctrl+d' -Function ViExit
Set-PSReadLineKeyHandler -Chord 'Ctrl+l' -ScriptBlock {
  Clear-Host
  [Microsoft.PowerShell.PSConsoleReadLine]::ClearScreen()
}

Set-Alias pmc portablemc

# Disco prompt
. (Join-Path -Path (Split-Path -Parent $MyInvocation.MyCommand.Path) -ChildPath "disco.ps1")
Set-DiscoConfig -UserColor "#bd93f9"

# Set up Catppuccin theme
Import-Module Catppuccin
$Flavor = $Catppuccin['Mocha']

$Colors = @{
  # Largely based on the Code Editor style guide
  # Emphasis, ListPrediction and ListPredictionSelected are inspired by the Catppuccin fzf theme

  # Powershell colours
  ContinuationPrompt     = $Flavor.Teal.Foreground()
  Emphasis               = $Flavor.Red.Foreground()
  Selection              = $Flavor.Surface0.Background()

  # PSReadLine prediction colours
  InlinePrediction       = $Flavor.Overlay0.Foreground()
  ListPrediction         = $Flavor.Mauve.Foreground()
  ListPredictionSelected = $Flavor.Surface0.Background()

  # Syntax highlighting
  Command                = $Flavor.Blue.Foreground()
  Comment                = $Flavor.Overlay0.Foreground()
  Default                = $Flavor.Text.Foreground()
  Error                  = $Flavor.Red.Foreground()
  Keyword                = $Flavor.Mauve.Foreground()
  Member                 = $Flavor.Rosewater.Foreground()
  Number                 = $Flavor.Peach.Foreground()
  Operator               = $Flavor.Sky.Foreground()
  Parameter              = $Flavor.Pink.Foreground()
  String                 = $Flavor.Green.Foreground()
  Type                   = $Flavor.Yellow.Foreground()
  Variable               = $Flavor.Lavender.Foreground()
}

# Set the colours
Set-PSReadLineOption -Colors $Colors

# The following colors are used by PowerShell's formatting
# Again PS 7.2+ only
$PSStyle.Formatting.Debug = $Flavor.Sky.Foreground()
$PSStyle.Formatting.Error = $Flavor.Red.Foreground()
$PSStyle.Formatting.ErrorAccent = $Flavor.Blue.Foreground()
$PSStyle.Formatting.FormatAccent = $Flavor.Teal.Foreground()
$PSStyle.Formatting.TableHeader = $Flavor.Rosewater.Foreground()
$PSStyle.Formatting.Verbose = $Flavor.Yellow.Foreground()
$PSStyle.Formatting.Warning = $Flavor.Peach.Foreground()


#f45873b3-b655-43a6-b217-97c00aa0db58 PowerToys CommandNotFound module

Import-Module -Name Microsoft.WinGet.CommandNotFound
#f45873b3-b655-43a6-b217-97c00aa0db58

