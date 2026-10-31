# Moves the red selected-tab stones onto a muted Gruvbox brick red. The sprites are not redrawn: every pixel keeps its
# own brightness relative to the sprite's highlight (so the shading, texture and outline are exactly as before) and only
# its colour is replaced, so the stone stays clearly red and clearly selected while sitting in Gruvbox's unsaturated
# palette.
#
# usage: stone.ps1 -Pack <pack dir> [-Red 8f3f2a]
param(
    [Parameter(Mandatory)] [string] $Pack,
    # the colour the sprite's highlight lands on: a brick red between Gruvbox red #cc241d and its warm greys
    [string] $Red = '8f3f2a',
    [string] $Include = '^tab\\stone_(middle|top_left|top_right|bottom_left|bottom_right)_selected\.png$|^resizeable_mode\\tab_stone_middle_selected\.png$'
)

Add-Type -ReferencedAssemblies System.Drawing -TypeDefinition @'
using System;
using System.Collections.Generic;
using System.Drawing;
using System.Drawing.Imaging;
using System.Runtime.InteropServices;

public static class StoneTint
{
    public static void Apply(string path, int[] rgb)
    {
        using (var src = new Bitmap(path))
        using (var bmp = new Bitmap(src.Width, src.Height, PixelFormat.Format32bppArgb))
        {
            using (var g = Graphics.FromImage(bmp)) g.DrawImage(src, 0, 0, src.Width, src.Height);
            var data = bmp.LockBits(new Rectangle(0, 0, bmp.Width, bmp.Height), ImageLockMode.ReadWrite, PixelFormat.Format32bppArgb);
            int n = Math.Abs(data.Stride) * bmp.Height;
            byte[] px = new byte[n];
            Marshal.Copy(data.Scan0, px, 0, n);
            // the sprite's highlight: the 97th percentile of its lit (non-outline) pixels
            var lums = new List<double>();
            for (int i = 0; i < n; i += 4)
                if (px[i + 3] > 128 && px[i] + px[i + 1] + px[i + 2] > 90)
                    lums.Add(0.299 * px[i + 2] + 0.587 * px[i + 1] + 0.114 * px[i]);
            lums.Sort();
            double hi = lums[(int)(lums.Count * 0.97)];
            for (int i = 0; i < n; i += 4)
            {
                if (px[i + 3] == 0) continue;
                double lum = 0.299 * px[i + 2] + 0.587 * px[i + 1] + 0.114 * px[i];
                double f = Math.Min(1.1, lum / hi);
                for (int c = 0; c < 3; c++)
                    px[i + 2 - c] = (byte)Math.Min(255, Math.Round(rgb[c] * f));
            }
            Marshal.Copy(px, 0, data.Scan0, n);
            bmp.UnlockBits(data);
            src.Dispose();
            bmp.Save(path + ".tmp", ImageFormat.Png);
        }
        System.IO.File.Delete(path);
        System.IO.File.Move(path + ".tmp", path);
    }
}
'@

$Pack = (Get-Item $Pack).FullName
$rgb = [int[]]@([Convert]::ToInt32($Red.Substring(0, 2), 16), [Convert]::ToInt32($Red.Substring(2, 2), 16), [Convert]::ToInt32($Red.Substring(4, 2), 16))
foreach ($png in Get-ChildItem $Pack -Recurse -File -Filter *.png | Where-Object { $_.FullName -notmatch '\\(\.git|tools|screenshots)\\' }) {
    $rel = $png.FullName.Substring($Pack.Length + 1)
    if ($rel -notmatch $Include) { continue }
    [StoneTint]::Apply($png.FullName, $rgb)
    $rel
}
