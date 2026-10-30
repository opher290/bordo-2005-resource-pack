# Builds the 224x147 Hub icon from the pack's own sprites.
# usage: icon.ps1 -Pack <pack dir>
param([Parameter(Mandatory)] [string] $Pack)
Add-Type -AssemblyName System.Drawing
$Pack = (Get-Item $Pack).FullName

$bmp = New-Object Drawing.Bitmap(224, 147)
$g = [Drawing.Graphics]::FromImage($bmp)
$g.InterpolationMode = 'NearestNeighbor'; $g.PixelOffsetMode = 'Half'
$g.Clear([Drawing.ColorTranslator]::FromHtml('#282828'))

# crops the top-left of a sprite into the icon (clamped to the sprite's size)
function Crop($rel, $w, $h, $dx, $dy) {
    $i = [Drawing.Bitmap]::FromFile((Join-Path $Pack $rel))
    $w = [Math]::Min($w, $i.Width); $h = [Math]::Min($h, $i.Height)
    $g.DrawImage($i, (New-Object Drawing.Rectangle($dx, $dy, $w, $h)), 0, 0, $w, $h, 'Pixel')
    $i.Dispose()
}

Crop 'chatbox\background.png' 224 60 0 0                      # parchment with its burnt edge
Crop 'fixed_mode\tabs_top_row.png' 224 37 0 63                # stone tab row
Crop 'fixed_mode\side_panel_background.png' 190 43 17 104     # panel stone

$bmp.Save((Join-Path $Pack 'icon.png'), [Drawing.Imaging.ImageFormat]::Png)
$g.Dispose(); $bmp.Dispose()
