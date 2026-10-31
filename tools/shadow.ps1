# Evens out the black drop shadow on a few 2005 tab icons. GNASH0R's icons carry a black shadow along their bottom and right
# edges, but the amount varies: the inventory bag has a thick one, the combat swords and the music harp have almost none.
#
#   -Reduce: thins the black shadow on the bottom and right of an icon (inventory), only where it is thick (-ReduceSpec), and shortens the long black runs of the settings wrench (-RunsSpec) on a share of them, so the thinned shadow stays uneven
#   -Trim:   caps the black edge on the left and right of an icon row by row (friends), to lighten the outline on the left while keeping most of the shadow on the right: -TrimLeft 1, -TrimRight 3 (keeps the right-hand shadow)`n#   -Runs:   shortens every horizontal run of black pixels by one, from its right end (emotes), for a 1px shadow like the prayer icon`n#   -Add:    draws a black shadow behind an icon as a copy of its silhouette moved down and right: the first pixel row fully, the second only on a share of its pixels (-AddSpec), so the edge is blotchy like the inventory and magic shadows
#            (combat, music, emotes, prayer); the icon itself is never touched
#
# usage: shadow.ps1 -Pack <pack dir> [-ReduceSpec @{ inventory = @(2,100) }] [-RunsSpec @{ options = @(3,70) }] [-Trim friends,ignores] [-TrimLeft 1] [-TrimRight 3] [-Runs <none by default>] [-AddSpec @{ combat = @(2,150,25); ... }]
param(
    [Parameter(Mandatory)] [string] $Pack,
    [hashtable] $ReduceSpec = @{ inventory = @(2, 100); prayer = @(1, 70); emotes = @(1, 65) },
    [int] $ReduceLayers = 1,
    # icon = @(depth in pixels, opacity 0-255, % of the second pixel row that is drawn, 1 = keep notches clear); the second row is what makes the edge blotchy
    [hashtable] $AddSpec = @{ combat = @(1, 150, 0, 1); music = @(2, 130, 8); emotes = @(1, 40, 0); prayer = @(1, 40, 0) },
    [string[]] $Trim = @('friends', 'ignores'),
    [int] $TrimLeft = 1,
    [int] $TrimRight = 3,
    # icon = @(minimum run length, % of runs to shorten); the settings wrench
    [hashtable] $RunsSpec = @{ options = @(3, 70) }
)
Add-Type -ReferencedAssemblies System.Drawing -TypeDefinition @'
using System;
using System.Drawing;
using System.Drawing.Imaging;

public static class IconShadow
{
    static bool Black(Color c) { return c.A > 0 && c.R + c.G + c.B <= 12; }

    static int H(int x, int y) { unchecked { uint h = (uint)(x * 73856093) ^ (uint)(y * 19349663); h ^= h >> 13; h *= 1274126177u; return (int)((h ^ (h >> 16)) % 100u); } }

    public static int Reduce(string path, int layers, int minThick, int chance)
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
                        if (open) { int th = 0; int tx = x, ty = y; while (tx >= 0 && ty >= 0 && Black(bmp.GetPixel(tx, ty))) { th++; tx--; ty--; } if (th >= minThick && H(x, y) < chance) kill.Add(new Point(x, y)); }
                    }
                foreach (var p in kill) { bmp.SetPixel(p.X, p.Y, Color.FromArgb(0, 0, 0, 0)); removed++; }
            }
            src.Dispose();
            bmp.Save(path + ".tmp", ImageFormat.Png);
        }
        System.IO.File.Delete(path); System.IO.File.Move(path + ".tmp", path);
        return removed;
    }

    // caps how many black pixels sit on the outer left and right edge of each row that also has icon art in it
    public static int Trim(string path, int leftMax, int rightMax)
    {
        int removed = 0;
        using (var src = new Bitmap(path))
        using (var bmp = new Bitmap(src.Width, src.Height, PixelFormat.Format32bppArgb))
        {
            for (int y = 0; y < src.Height; y++) for (int x = 0; x < src.Width; x++) bmp.SetPixel(x, y, src.GetPixel(x, y));
            for (int y = 0; y < src.Height; y++)
            {
                int x0 = -1, x1 = -1, art = 0;
                for (int x = 0; x < src.Width; x++) { var c = src.GetPixel(x, y); if (c.A == 0) continue; if (x0 < 0) x0 = x; x1 = x; if (!Black(c)) art++; }
                if (art < 4) continue;
                int run = 0; for (int x = x0; x <= x1 && Black(src.GetPixel(x, y)); x++) run++;
                for (int i = 0; i < run - leftMax; i++) { bmp.SetPixel(x0 + i, y, Color.FromArgb(0, 0, 0, 0)); removed++; }
                run = 0; for (int x = x1; x >= x0 && Black(src.GetPixel(x, y)); x--) run++;
                for (int i = 0; i < run - rightMax; i++) { bmp.SetPixel(x1 - i, y, Color.FromArgb(0, 0, 0, 0)); removed++; }
            }
            src.Dispose();
            bmp.Save(path + ".tmp", ImageFormat.Png);
        }
        System.IO.File.Delete(path); System.IO.File.Move(path + ".tmp", path);
        return removed;
    }

    // shortens horizontal runs of black pixels (at least minLen long) by one, from the right end, on a share of them, which thins a shadow while keeping it uneven
    public static int ThinRuns(string path, int minLen, int chance)
    {
        int removed = 0;
        using (var src = new Bitmap(path))
        using (var bmp = new Bitmap(src.Width, src.Height, PixelFormat.Format32bppArgb))
        {
            for (int y = 0; y < src.Height; y++) for (int x = 0; x < src.Width; x++) bmp.SetPixel(x, y, src.GetPixel(x, y));
            for (int y = 0; y < src.Height; y++)
            {
                int x = 0;
                while (x < src.Width)
                {
                    if (!Black(src.GetPixel(x, y))) { x++; continue; }
                    int s = x; while (x < src.Width && Black(src.GetPixel(x, y))) x++;
                    if (x - s >= minLen && H(x, y) < chance) { bmp.SetPixel(x - 1, y, Color.FromArgb(0, 0, 0, 0)); removed++; }
                }
            }
            src.Dispose();
            bmp.Save(path + ".tmp", ImageFormat.Png);
        }
        System.IO.File.Delete(path); System.IO.File.Move(path + ".tmp", path);
        return removed;
    }

    public static int Add(string path, int depth, int alpha, int outerChance, bool skipEnclosed)
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
                        if (d > 1 && H(nx, ny) >= outerChance) continue;
                        // a notch between two parts of the icon (the swords' crossing) stays clear: skip a shadow pixel with icon art within 6 pixels to its right
                        if (skipEnclosed) { bool inside = false; for (int k = 1; k <= 6 && nx + k < src.Width; k++) if (src.GetPixel(nx + k, ny).A > 0) inside = true; if (inside) continue; }
                        if (bmp.GetPixel(nx, ny).A == 0) { bmp.SetPixel(nx, ny, Color.FromArgb(alpha, 0, 0, 0)); added++; }
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
foreach ($n in $ReduceSpec.Keys) { $f = Join-Path $Pack "tab\$n.png"; "tab\$n.png: $([IconShadow]::Reduce($f, $ReduceLayers, [int]$ReduceSpec[$n][0], [int]$ReduceSpec[$n][1])) shadow pixels removed" }
foreach ($n in $Trim) { $f = Join-Path $Pack "tab\$n.png"; "tab\$n.png: $([IconShadow]::Trim($f, $TrimLeft, $TrimRight)) edge pixels trimmed" }
foreach ($n in $RunsSpec.Keys) { $f = Join-Path $Pack "tab\$n.png"; "tab\$n.png: $([IconShadow]::ThinRuns($f, [int]$RunsSpec[$n][0], [int]$RunsSpec[$n][1])) shadow pixels removed from long runs" }
foreach ($n in $AddSpec.Keys) { $f = Join-Path $Pack "tab\$n.png"; "tab\$n.png: $([IconShadow]::Add($f, [int]$AddSpec[$n][0], [int]$AddSpec[$n][1], [int]$AddSpec[$n][2], ($AddSpec[$n].Count -gt 3 -and $AddSpec[$n][3] -eq 1))) shadow pixels added" }
