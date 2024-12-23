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
