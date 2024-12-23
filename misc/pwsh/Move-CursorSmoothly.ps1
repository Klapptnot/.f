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
