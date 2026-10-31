# The "What would you like to make?" panel. In the 2005 pack the item buttons have no face of their own, so a button is just
# the chat parchment inside a thin frame, and the selected button is a flat grey-tan. This gives the buttons a face a shade darker
# than the parchment (the scheme's MakeAll.Face) and makes the selected item and quantity buttons brick red, like the selected
# tab stones. The frame sprites are not touched.
#
# usage: makeall.ps1 -Pack <pack dir> -Scheme bordo [-Face d6c59c] [-Selected 8f3f2a]
param(
    [Parameter(Mandatory)] [string] $Pack,
    [string] $Scheme = 'bordo',
    [string] $Face = '',
    [string] $Selected = '8f3f2a'
)
. (Join-Path $PSScriptRoot 'schemes.ps1')
if (-not $Face) { $Face = $Schemes[$Scheme].MakeAll.Face }
Add-Type -AssemblyName System.Drawing
$Pack = (Get-Item $Pack).FullName
$rgb = [System.Drawing.Color]::FromArgb(255, [Convert]::ToInt32($Face.Substring(0, 2), 16), [Convert]::ToInt32($Face.Substring(2, 2), 16), [Convert]::ToInt32($Face.Substring(4, 2), 16))

# the face: the 88x60 item button background, one flat colour under the frame
$path = Join-Path $Pack 'chatbox\make_all_background.png'
$bmp = New-Object System.Drawing.Bitmap 88, 60, ([System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
for ($y = 0; $y -lt 60; $y++) { for ($x = 0; $x -lt 88; $x++) { $bmp.SetPixel($x, $y, $rgb) } }
$bmp.Save($path + '.tmp', [System.Drawing.Imaging.ImageFormat]::Png); $bmp.Dispose()
if (Test-Path $path) { Remove-Item $path -Force }
Move-Item ($path + '.tmp') $path
"chatbox\make_all_background.png: flat #$Face face"

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
