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
