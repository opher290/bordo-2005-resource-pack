# Moves a tab icon a few pixels inside its sprite, without touching a single pixel of the drawing: every pixel keeps its colour
# and alpha and only its position changes. Used to sit an icon a little better in its stone.
#
# usage: nudge.ps1 -Pack <pack dir> [-Spec @{ music = @(2, -1) }]     (icon = @(pixels right, pixels down))
param(
    [Parameter(Mandatory)] [string] $Pack,
    [hashtable] $Spec = @{ music = @(2, -1) }
)
Add-Type -ReferencedAssemblies System.Drawing -TypeDefinition @'
using System;
using System.Drawing;
using System.Drawing.Imaging;

public static class Nudge
{
    public static void Move(string path, int dx, int dy)
    {
        using (var src = new Bitmap(path))
        using (var bmp = new Bitmap(src.Width, src.Height, PixelFormat.Format32bppArgb))
        {
            for (int y = 0; y < src.Height; y++)
                for (int x = 0; x < src.Width; x++)
                {
                    var c = src.GetPixel(x, y);
                    if (c.A == 0) continue;
                    int nx = x + dx, ny = y + dy;
                    if (nx < 0 || ny < 0 || nx >= bmp.Width || ny >= bmp.Height) throw new Exception("icon would leave the sprite: " + path);
                    bmp.SetPixel(nx, ny, c);
                }
            src.Dispose();
            bmp.Save(path + ".tmp", ImageFormat.Png);
        }
        System.IO.File.Delete(path); System.IO.File.Move(path + ".tmp", path);
    }
}
'@

$Pack = (Get-Item $Pack).FullName
foreach ($n in $Spec.Keys) {
    [Nudge]::Move((Join-Path $Pack "tab\$n.png"), [int]$Spec[$n][0], [int]$Spec[$n][1])
    "tab\${n}.png: moved $($Spec[$n][0]),$($Spec[$n][1])"
}
