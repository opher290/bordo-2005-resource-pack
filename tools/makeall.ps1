# The "What would you like to make?" panel. In the 2005 pack the item buttons have no face of their own, so a button is just
# the chat parchment inside a thin frame, and the selected button is a flat grey-tan. This gives the buttons a face a shade darker
# than the parchment (the scheme's MakeAll.Face) and makes the selected item and quantity buttons brick red, like the selected
# tab stones. The frame sprites are not touched.
#
# The face is not flat: it takes the brightness variation of GNASH0R's own chat parchment (tools\assets\texture\parchment.png, the original
# chat background), turned up so it shows on a small button, and darkens a little towards its edges, so it reads as the same paper as the
# chat box.
#
# usage: makeall.ps1 -Pack <pack dir> -Scheme bordo [-Face d6c59c] [-Selected 8f3f2a]
param(
    [Parameter(Mandatory)] [string] $Pack,
    [string] $Scheme = 'bordo',
    [string] $Face = '',
    [string] $Selected = '8f3f2a',
    # the parchment the texture is taken from, the corner of the 88x60 area used, and how much its variation is turned up
    [string] $Texture = (Join-Path $PSScriptRoot 'assets\texture\parchment.png'),
    [int] $TextureX = 200,
    [int] $TextureY = 40,
    [double] $Gain = 1.8,
    # how much darker the face gets at its edge (0.05 = 5%), over the outer 8 pixels
    [double] $Vignette = 0.05
)
. (Join-Path $PSScriptRoot 'schemes.ps1')
if (-not $Face) { $Face = $Schemes[$Scheme].MakeAll.Face }
Add-Type -AssemblyName System.Drawing
$Pack = (Get-Item $Pack).FullName
$rgb = [System.Drawing.Color]::FromArgb(255, [Convert]::ToInt32($Face.Substring(0, 2), 16), [Convert]::ToInt32($Face.Substring(2, 2), 16), [Convert]::ToInt32($Face.Substring(4, 2), 16))

# the face: the 88x60 item button background under the frame
$path = Join-Path $Pack 'chatbox\make_all_background.png'
$tex = New-Object System.Drawing.Bitmap $Texture
$lum = @(); for ($y = 0; $y -lt 60; $y++) { for ($x = 0; $x -lt 88; $x++) { $c = $tex.GetPixel($TextureX + $x, $TextureY + $y); $lum += (0.299 * $c.R + 0.587 * $c.G + 0.114 * $c.B) } }
$tex.Dispose()
$mean = ($lum | Measure-Object -Average).Average
$bmp = New-Object System.Drawing.Bitmap 88, 60, ([System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
for ($y = 0; $y -lt 60; $y++) {
    for ($x = 0; $x -lt 88; $x++) {
        $k = 1 + ($lum[$y * 88 + $x] / $mean - 1) * $Gain
        $edge = [Math]::Min([Math]::Min($x, 87 - $x), [Math]::Min($y, 59 - $y))
        if ($edge -lt 8) { $k *= 1 - $Vignette * (8 - $edge) / 8 }
        $r = [int][Math]::Max(0, [Math]::Min(255, [Math]::Round($rgb.R * $k)))
        $gg = [int][Math]::Max(0, [Math]::Min(255, [Math]::Round($rgb.G * $k)))
        $bb = [int][Math]::Max(0, [Math]::Min(255, [Math]::Round($rgb.B * $k)))
        $bmp.SetPixel($x, $y, [System.Drawing.Color]::FromArgb(255, $r, $gg, $bb))
    }
}
$bmp.Save($path + '.tmp', [System.Drawing.Imaging.ImageFormat]::Png); $bmp.Dispose()
if (Test-Path $path) { Remove-Item $path -Force }
Move-Item ($path + '.tmp') $path
"chatbox\make_all_background.png: #$Face face with the chat parchment's texture"

# the selected colour: its own variable, so the report button hover that shares background_5 keeps its colour
$vars = Join-Path $Pack 'vars.toml'
$v = [IO.File]::ReadAllText($vars)
if ($v -notmatch 'make_all_selected') {
    $v = [regex]::Replace($v, '(?m)^(background_5=[^\r\n]*)(\r?\n)', "`$1`$2# make_all (selected item and quantity buttons)`n`nmake_all_selected=0x$Selected`n".Replace("`n`n", "`n"), 1)
}
[IO.File]::WriteAllText($vars, $v, (New-Object System.Text.UTF8Encoding $false))
$ov = Join-Path $Pack 'overrides.toml'
$o = [IO.File]::ReadAllText($ov)
$o = [regex]::Replace($o, '(\[make_all\.(?:background|quantity)\]\r?\ncolor=)"\$\{color\.[a-z_0-9]+\}"', '$1"${color.make_all_selected}"')
[IO.File]::WriteAllText($ov, $o, (New-Object System.Text.UTF8Encoding $false))
"overrides.toml: make_all background and quantity use #$Selected"
