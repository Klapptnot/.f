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
