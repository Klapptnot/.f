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

# Set up Catppuccin theme
Import-Module Catppuccin
$Flavor = $Catppuccin['Mocha']

$PowershellColors = @{
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

# The following colors are used by PowerShell's formatting
# Again PS 7.2+ only
$PSStyle.Formatting.Debug = $Flavor.Sky.Foreground()
$PSStyle.Formatting.Error = $Flavor.Red.Foreground()
$PSStyle.Formatting.ErrorAccent = $Flavor.Blue.Foreground()
$PSStyle.Formatting.FormatAccent = $Flavor.Teal.Foreground()
$PSStyle.Formatting.TableHeader = $Flavor.Rosewater.Foreground()
$PSStyle.Formatting.Verbose = $Flavor.Yellow.Foreground()
$PSStyle.Formatting.Warning = $Flavor.Peach.Foreground()


$FilesToSource = @(
  "Add-PathToEnvironmentVariable.ps1",
  "Disco-Prompt.ps1"
)

foreach ($File in $FilesToSource) {
  . (Join-Path -Path (Split-Path -Parent $MyInvocation.MyCommand.Path) -ChildPath $File)
}

Set-PSReadLineOption -Colors $PowershellColors
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

Get-UniqueHistory -Write -Dedup

Set-DiscoOption -UserColor "#bd93f9"
Set-DiscoOption -PromptColor "#9b5ced"

