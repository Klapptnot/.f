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
