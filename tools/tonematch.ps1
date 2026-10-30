# Nudges the recoloured 2005 shell sprites onto the exact average brightness of their counterparts in the main Gruvbox
# pack, so the two packs share one tone and only the shapes differ. Hue and alpha are untouched (a plain RGB gain).
# The deliberately different 2005 art (black steel dialog borders, make-all frames, the compass dial) is left alone.
#
# usage: tonematch.ps1 -Pack <this pack dir> -MainPack <main pack dir>
param(
    [Parameter(Mandatory)] [string] $Pack,
    [Parameter(Mandatory)] [string] $MainPack,
    # sprites to tone-match, relative to the pack root
    [string] $Include = '^(fixed_mode|resizeable_mode)\\|^other\\old_school_mode_side_panel|^chatbox\\(button\.|button_hovered|button_selected|sword_pointed)',
    # only nudge when the difference is a tone offset, not a different design
    [double] $MaxGap = 50,
    [double] $MinGain = 0.9,
    [double] $MaxGain = 1.7
)

Add-Type -ReferencedAssemblies System.Drawing -TypeDefinition @'
using System;
using System.Drawing;
using System.Drawing.Imaging;
using System.Runtime.InteropServices;

public static class ToneMatch
{
    public static double Mean(string path)
    {
        double sum = 0; int n = 0;
        using (var bmp = new Bitmap(path))
            for (int y = 0; y < bmp.Height; y++)
                for (int x = 0; x < bmp.Width; x++)
                {
                    Color c = bmp.GetPixel(x, y);
                    if (c.A == 0) continue;
                    sum += 0.299 * c.R + 0.587 * c.G + 0.114 * c.B; n++;
                }
        return n == 0 ? 0 : sum / n;
    }

    public static void Gain(string path, double gain)
    {
        using (var src = new Bitmap(path))
        using (var bmp = new Bitmap(src.Width, src.Height, PixelFormat.Format32bppArgb))
        {
            using (var g = Graphics.FromImage(bmp)) g.DrawImage(src, 0, 0, src.Width, src.Height);
            var data = bmp.LockBits(new Rectangle(0, 0, bmp.Width, bmp.Height), ImageLockMode.ReadWrite, PixelFormat.Format32bppArgb);
            int n = Math.Abs(data.Stride) * bmp.Height;
            byte[] px = new byte[n];
            Marshal.Copy(data.Scan0, px, 0, n);
            for (int i = 0; i < n; i += 4)
            {
                if (px[i + 3] == 0) continue;
                for (int k = 0; k < 3; k++) px[i + k] = (byte)Math.Min(255, Math.Round(px[i + k] * gain));
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
$MainPack = (Get-Item $MainPack).FullName
foreach ($png in Get-ChildItem $Pack -Recurse -File -Filter *.png | Where-Object { $_.FullName -notmatch '\\\.git\\' }) {
    $rel = $png.FullName.Substring($Pack.Length + 1)
    if ($rel -notmatch $Include) { continue }
    $ref = Join-Path $MainPack $rel
    if (-not (Test-Path $ref)) { continue }
    $mine = [ToneMatch]::Mean($png.FullName); $want = [ToneMatch]::Mean($ref)
    if ($mine -le 0 -or $want -le 0 -or [Math]::Abs($want - $mine) -gt $MaxGap) { continue }
    $gain = [Math]::Max($MinGain, [Math]::Min($MaxGain, $want / $mine))
    if ([Math]::Abs($gain - 1) -lt 0.01) { continue }
    [ToneMatch]::Gain($png.FullName, $gain)
    "{0,-60} {1,5:N0} -> {2,5:N0}  (target {3,5:N0}, gain {4:N2})" -f $rel, $mine, ($mine * $gain), $want, $gain
}
