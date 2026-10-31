# Evens out the black drop shadow on a few 2005 tab icons. GNASH0R's icons carry a black shadow along their bottom and right
# edges, but the amount varies: the inventory bag has a thick one, the combat swords and the music harp have almost none.
#
#   -Reduce: strips the outermost layer(s) of the black shadow from the bottom and right of an icon (inventory)
#   -Add:    draws a black shadow behind an icon, as a copy of its silhouette moved 1 and 2 pixels down and right
#            (combat, music); the icon itself is never touched
#
# usage: shadow.ps1 -Pack <pack dir> [-Reduce inventory] [-ReduceLayers 1] [-Add combat,music] [-AddDepth 2]
param(
    [Parameter(Mandatory)] [string] $Pack,
    [string[]] $Reduce = @('inventory'),
    [int] $ReduceLayers = 1,
    [string[]] $Add = @('combat', 'music'),
    [int] $AddDepth = 2
)
Add-Type -ReferencedAssemblies System.Drawing -TypeDefinition @'
using System;
using System.Drawing;
using System.Drawing.Imaging;

public static class IconShadow
{
    static bool Black(Color c) { return c.A > 0 && c.R + c.G + c.B <= 12; }

    public static int Reduce(string path, int layers)
    {
        int removed = 0;
        using (var src = new Bitmap(path))
        using (var bmp = new Bitmap(src.Width, src.Height, PixelFormat.Format32bppArgb))
        {
            for (int y = 0; y < src.Height; y++) for (int x = 0; x < src.Width; x++) bmp.SetPixel(x, y, src.GetPixel(x, y));
            for (int l = 0; l < layers; l++)
            {
                var kill = new System.Collections.Generic.List<Point>();
                for (int y = 0; y < bmp.Height; y++)
                    for (int x = 0; x < bmp.Width; x++)
                    {
                        if (!Black(bmp.GetPixel(x, y))) continue;
                        bool open = false;
                        foreach (var d in new[] { new Point(1, 0), new Point(0, 1), new Point(1, 1) })
                        {
                            int nx = x + d.X, ny = y + d.Y;
                            if (nx >= bmp.Width || ny >= bmp.Height || bmp.GetPixel(nx, ny).A == 0) { open = true; break; }
                        }
                        if (open) kill.Add(new Point(x, y));
                    }
                foreach (var p in kill) { bmp.SetPixel(p.X, p.Y, Color.FromArgb(0, 0, 0, 0)); removed++; }
            }
            src.Dispose();
            bmp.Save(path + ".tmp", ImageFormat.Png);
        }
        System.IO.File.Delete(path); System.IO.File.Move(path + ".tmp", path);
        return removed;
    }

    public static int Add(string path, int depth)
    {
        int added = 0;
        using (var src = new Bitmap(path))
        using (var bmp = new Bitmap(src.Width, src.Height, PixelFormat.Format32bppArgb))
        {
            for (int y = 0; y < src.Height; y++) for (int x = 0; x < src.Width; x++) bmp.SetPixel(x, y, src.GetPixel(x, y));
            for (int d = depth; d >= 1; d--)
                for (int y = 0; y < src.Height; y++)
                    for (int x = 0; x < src.Width; x++)
                    {
                        if (src.GetPixel(x, y).A == 0) continue;
                        int nx = x + d, ny = y + d;
                        if (nx >= src.Width || ny >= src.Height) throw new Exception("shadow would leave the sprite: " + path);
                        if (bmp.GetPixel(nx, ny).A == 0) { bmp.SetPixel(nx, ny, Color.FromArgb(255, 0, 0, 0)); added++; }
                    }
            src.Dispose();
            bmp.Save(path + ".tmp", ImageFormat.Png);
        }
        System.IO.File.Delete(path); System.IO.File.Move(path + ".tmp", path);
        return added;
    }
}
'@

$Pack = (Get-Item $Pack).FullName
foreach ($n in $Reduce) { $f = Join-Path $Pack "tab\$n.png"; "tab\$n.png: $([IconShadow]::Reduce($f, $ReduceLayers)) shadow pixels removed" }
foreach ($n in $Add) { $f = Join-Path $Pack "tab\$n.png"; "tab\$n.png: $([IconShadow]::Add($f, $AddDepth)) shadow pixels added" }
