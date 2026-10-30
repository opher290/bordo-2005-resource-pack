# Recolours the 2005 compass dial (a red-and-orange sprite with only 11 colours) onto the scheme's red and orange, keeping
# the original shading and shape: each pixel keeps its brightness and moves between the scheme's red and orange
# (see Compass in schemes.ps1) according to where its hue sits between the original red and orange.
#
# usage: compass.ps1 -Src <original 2005 pack> -Out <pack dir> [-Scheme gruvbox|bordo]
param(
    [Parameter(Mandatory)] [string] $Src,
    [Parameter(Mandatory)] [string] $Out,
    [string] $Scheme = 'gruvbox'
)
Add-Type -AssemblyName System.Drawing
$Src = (Get-Item $Src).FullName
$Out = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($Out)

. (Join-Path $PSScriptRoot 'schemes.ps1')
function Rgb($hex) { [Convert]::ToInt32($hex.Substring(0, 2), 16), [Convert]::ToInt32($hex.Substring(2, 2), 16), [Convert]::ToInt32($hex.Substring(4, 2), 16) }
$red = Rgb $Schemes[$Scheme].Compass.Red
$orange = Rgb $Schemes[$Scheme].Compass.Orange
function Lum($c) { 0.299 * $c[0] + 0.587 * $c[1] + 0.114 * $c[2] }
$redLum = Lum $red; $orangeLum = Lum $orange

$in = [Drawing.Bitmap]::FromFile((Join-Path $Src 'other\compass.png'))
$bmp = New-Object Drawing.Bitmap($in.Width, $in.Height, [Drawing.Imaging.PixelFormat]::Format32bppArgb)
for ($y = 0; $y -lt $in.Height; $y++) {
    for ($x = 0; $x -lt $in.Width; $x++) {
        $p = $in.GetPixel($x, $y)
        if ($p.A -eq 0 -or ($p.R -eq 0 -and $p.G -eq 0 -and $p.B -eq 0)) { $bmp.SetPixel($x, $y, $p); continue }
        $lum = 0.299 * $p.R + 0.587 * $p.G + 0.114 * $p.B
        # 0 = original red (hue <= 8), 1 = original orange (hue >= 24)
        $t = [Math]::Max(0, [Math]::Min(1, ($p.GetHue() - 8) / 16))
        $rgb = for ($k = 0; $k -lt 3; $k++) {
            # orange is scaled so the brightest original orange (lum ~119) lands on full Gruvbox orange
            $ro = $red[$k] * ($lum / $redLum); $or = $orange[$k] * ($lum / 119)
            [int][Math]::Min(255, [Math]::Round($ro + ($or - $ro) * $t))
        }
        $bmp.SetPixel($x, $y, [Drawing.Color]::FromArgb($p.A, $rgb[0], $rgb[1], $rgb[2]))
    }
}
$in.Dispose()
$dest = Join-Path $Out 'other\compass.png'
New-Item -ItemType Directory -Force (Split-Path $dest) | Out-Null
$bmp.Save($dest, [Drawing.Imaging.ImageFormat]::Png)
$bmp.Dispose()
