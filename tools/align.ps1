# Lines the stone tab icons up vertically. Each icon is moved up or down as a whole, with no change to its size or pixels,
# so that the centre of its outline (shadow included) sits within half a pixel of the row's common centre (row 19 of the
# 33x36 cell). Icons already within half a pixel are left alone. The Chat-channel icon keeps the position it was set to by eye.
#
# usage: align.ps1 -Pack <pack dir> [-Offsets @{ stats = 1; inventory = 1; equipment = 3; emotes = 1; account_management = -1 }]
param(
    [Parameter(Mandatory)] [string] $Pack,
    # rows to move each icon by, worked out from the icon positions after the shadows are set
    [hashtable] $Offsets = @{ stats = 1; inventory = 1; equipment = 3; emotes = 1; account_management = -1 }
)
Add-Type -ReferencedAssemblies System.Drawing -TypeDefinition @'
using System;
using System.Drawing;
using System.Drawing.Imaging;

public static class IconAlign
{
    public static string Shift(string path, int dy)
    {
        int y0 = 999, y1 = -1;
        using (var a = new Bitmap(path))
        using (var b = new Bitmap(a.Width, a.Height, PixelFormat.Format32bppArgb))
        {
            for (int y = 0; y < a.Height; y++)
                for (int x = 0; x < a.Width; x++)
                {
                    var c = a.GetPixel(x, y);
                    if (c.A == 0) continue;
                    int ny = y + dy;
                    if (ny < 0 || ny >= a.Height) throw new Exception("shift would clip " + path);
                    b.SetPixel(x, ny, c);
                    if (ny < y0) y0 = ny; if (ny > y1) y1 = ny;
                }
            b.Save(path + ".tmp", ImageFormat.Png);
        }
        System.IO.File.Delete(path); System.IO.File.Move(path + ".tmp", path);
        return y0 + "-" + y1;
    }
}
'@
$Pack = (Get-Item $Pack).FullName
foreach ($n in $Offsets.Keys) {
    $f = Join-Path $Pack "tab\$n.png"
    "tab\$n.png: moved $($Offsets[$n]) rows, now rows $([IconAlign]::Shift($f, [int]$Offsets[$n]))"
}
