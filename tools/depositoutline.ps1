# Gives the Deposit inventory bag (from the 2005 Overhaul pack) the black outline every other bank icon has. The Overhaul bag is
# drawn without one: it only has black along its right and bottom. Every empty pixel next to the bag (up, down, left or right) becomes
# opaque black; the green arrow and the pixels already drawn are never touched.
#
# usage: depositoutline.ps1 -Pack <pack dir>
param([Parameter(Mandatory)] [string] $Pack)
Add-Type -ReferencedAssemblies System.Drawing -TypeDefinition @'
using System;
using System.Drawing;
using System.Drawing.Imaging;

public static class DepositOutline
{
    static bool Bag(Color c) { return c.A > 0 && c.R + c.G + c.B > 30 && !(c.G > c.R && c.G > c.B); }

    public static int Apply(string path)
    {
        int added = 0;
        using (var src = new Bitmap(path))
        using (var bmp = new Bitmap(src.Width, src.Height, PixelFormat.Format32bppArgb))
        {
            for (int y = 0; y < src.Height; y++) for (int x = 0; x < src.Width; x++) bmp.SetPixel(x, y, src.GetPixel(x, y));
            for (int y = 0; y < src.Height; y++)
                for (int x = 0; x < src.Width; x++)
                {
                    if (!Bag(src.GetPixel(x, y))) continue;
                    foreach (var d in new[] { new Point(1, 0), new Point(-1, 0), new Point(0, 1), new Point(0, -1) })
                    {
                        int nx = x + d.X, ny = y + d.Y;
                        if (nx < 0 || ny < 0 || nx >= src.Width || ny >= src.Height) throw new Exception("outline would leave the sprite: " + path);
                        if (src.GetPixel(nx, ny).A == 0 && bmp.GetPixel(nx, ny).A == 0) { bmp.SetPixel(nx, ny, Color.FromArgb(255, 0, 0, 0)); added++; }
                    }
                }
            src.Dispose();
            bmp.Save(path + ".tmp", ImageFormat.Png);
        }
        System.IO.File.Delete(path); System.IO.File.Move(path + ".tmp", path);
        return added;
    }
}
'@

$f = Join-Path (Get-Item $Pack).FullName 'bank\deposit_inventory.png'
"bank\deposit_inventory.png: $([DepositOutline]::Apply($f)) outline pixels added"
