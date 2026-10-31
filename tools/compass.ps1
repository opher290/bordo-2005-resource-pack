# Recolours the 2005 compass dial (a red-and-orange sprite with only 11 colours). The original is a smooth gradient: a dark
# red rim fading through reds and oranges to a bright orange centre. Each pixel keeps its place on that gradient (its original
# brightness) and takes the colour the scheme's Compass.Stops give for it, so the dial keeps the original gradient style in the
# scheme's colours. Black lettering and transparency are untouched.
#
# Compass.Stops in schemes.ps1 is a list of 'brightness:hex' points, brightness being the original pixel's luminance
# (the dial runs from about 30 at the rim to 119 at the centre); colours between points are blended, and anything darker than
# the first point scales down towards black, which keeps the original shadows.
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
$stops = @($Schemes[$Scheme].Compass.Stops | ForEach-Object { $a = $_ -split ':'; [pscustomobject]@{ L = [double]$a[0]; C = (Rgb $a[1]) } })

function Dial-Colour([double]$lum) {
    if ($lum -le $stops[0].L) { return , @(0..2 | ForEach-Object { [int][Math]::Round($stops[0].C[$_] * $lum / $stops[0].L) }) }
    for ($i = 0; $i -lt $stops.Count - 1; $i++) {
        if ($lum -le $stops[$i + 1].L) {
            $t = ($lum - $stops[$i].L) / ($stops[$i + 1].L - $stops[$i].L)
            return , @(0..2 | ForEach-Object { [int][Math]::Round($stops[$i].C[$_] + ($stops[$i + 1].C[$_] - $stops[$i].C[$_]) * $t) })
        }
    }
    , @(0..2 | ForEach-Object { $stops[-1].C[$_] })
}

$in = [Drawing.Bitmap]::FromFile((Join-Path $Src 'other\compass.png'))
$bmp = New-Object Drawing.Bitmap($in.Width, $in.Height, [Drawing.Imaging.PixelFormat]::Format32bppArgb)
for ($y = 0; $y -lt $in.Height; $y++) {
    for ($x = 0; $x -lt $in.Width; $x++) {
        $p = $in.GetPixel($x, $y)
        if ($p.A -eq 0 -or ($p.R -eq 0 -and $p.G -eq 0 -and $p.B -eq 0)) { $bmp.SetPixel($x, $y, $p); continue }
        $rgb = Dial-Colour (0.299 * $p.R + 0.587 * $p.G + 0.114 * $p.B)
        $bmp.SetPixel($x, $y, [Drawing.Color]::FromArgb($p.A, $rgb[0], $rgb[1], $rgb[2]))
    }
}
$in.Dispose()
$dest = Join-Path $Out 'other\compass.png'
New-Item -ItemType Directory -Force (Split-Path $dest) | Out-Null
$bmp.Save($dest, [Drawing.Imaging.ImageFormat]::Png)
$bmp.Dispose()