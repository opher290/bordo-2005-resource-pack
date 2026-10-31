# Moves the grey-olive square behind a few icon buttons (equipment stats, prices, items lost on death, call follower) onto
# the scheme's shell ramp. The icon art is left exactly as drawn: the background is found by flood-filling inwards from the
# sprite's edge through dull, dark pixels, so the icon's own greys and browns are never touched. Alpha and pixel positions
# are untouched.
#
# usage: iconbg.ps1 -Pack <pack dir> -Scheme bordo [-Scale 0.9]
param(
    [Parameter(Mandatory)] [string] $Pack,
    [string] $Scheme = 'bordo',
    # brightness multiplier applied before the ramp lookup
    [double] $Scale = 0.9,
    # the flood only crosses pixels at most this saturated and this bright, which keeps it out of the icon
    [double] $MaxSat = 0.2,
    [double] $MaxLum = 105,
    [string] $Include = '^button\\equipment_(call_follower|guide_prices|items_lost_on_death|stats_icon)\.png$'
)
. (Join-Path $PSScriptRoot 'schemes.ps1')
Add-Type -ReferencedAssemblies System.Drawing -TypeDefinition @'
using System;
using System.Collections.Generic;
using System.Drawing;
using System.Drawing.Imaging;
using System.Runtime.InteropServices;

public static class IconBg
{
    public static int Apply(string path, double[] L, int[][] C, double scale, double maxSat, double maxLum)
    {
        int changed = 0;
        using (var src = new Bitmap(path))
        using (var bmp = new Bitmap(src.Width, src.Height, PixelFormat.Format32bppArgb))
        {
            using (var g = Graphics.FromImage(bmp)) g.DrawImage(src, 0, 0, src.Width, src.Height);
            int w = bmp.Width, h = bmp.Height;
            var data = bmp.LockBits(new Rectangle(0, 0, w, h), ImageLockMode.ReadWrite, PixelFormat.Format32bppArgb);
            int stride = Math.Abs(data.Stride);
            byte[] px = new byte[stride * h];
            Marshal.Copy(data.Scan0, px, 0, px.Length);
            Func<int, int, bool> dull = (x, y) =>
            {
                int i = y * stride + x * 4;
                if (px[i + 3] == 0) return false;
                int r = px[i + 2], g2 = px[i + 1], b = px[i];
                int mx = Math.Max(r, Math.Max(g2, b)), mn = Math.Min(r, Math.Min(g2, b));
                double sat = mx == 0 ? 0 : (mx - mn) / (double)mx;
                double lum = 0.299 * r + 0.587 * g2 + 0.114 * b;
                return sat <= maxSat && lum <= maxLum;
            };
            var seen = new bool[w * h];
            var q = new Queue<int>();
            for (int x = 0; x < w; x++) { q.Enqueue(x); q.Enqueue((h - 1) * w + x); }
            for (int y = 0; y < h; y++) { q.Enqueue(y * w); q.Enqueue(y * w + w - 1); }
            while (q.Count > 0)
            {
                int p = q.Dequeue();
                if (seen[p]) continue;
                int x = p % w, y = p / w;
                if (!dull(x, y)) continue;
                seen[p] = true;
                if (x > 0) q.Enqueue(p - 1);
                if (x < w - 1) q.Enqueue(p + 1);
                if (y > 0) q.Enqueue(p - w);
                if (y < h - 1) q.Enqueue(p + w);
            }
            for (int p = 0; p < w * h; p++)
            {
                if (!seen[p]) continue;
                int x = p % w, y = p / w, i = y * stride + x * 4;
                double lum = (0.299 * px[i + 2] + 0.587 * px[i + 1] + 0.114 * px[i]) * scale;
                int k = 0;
                while (k < L.Length - 2 && lum > L[k + 1]) k++;
                double t = Math.Max(0, Math.Min(1, (lum - L[k]) / (L[k + 1] - L[k])));
                for (int c = 0; c < 3; c++)
                    px[i + 2 - c] = (byte)Math.Round(C[k][c] + (C[k + 1][c] - C[k][c]) * t);
                changed++;
            }
            Marshal.Copy(px, 0, data.Scan0, px.Length);
            bmp.UnlockBits(data);
            src.Dispose();
            bmp.Save(path + ".tmp", ImageFormat.Png);
        }
        System.IO.File.Delete(path);
        System.IO.File.Move(path + ".tmp", path);
        return changed;
    }
}
'@

$Pack = (Get-Item $Pack).FullName
$ramp = $Schemes[$Scheme]
$L = [double[]]$ramp.L
$C = [int[][]]@($ramp.C | ForEach-Object { , [int[]]@([Convert]::ToInt32($_.Substring(0, 2), 16), [Convert]::ToInt32($_.Substring(2, 2), 16), [Convert]::ToInt32($_.Substring(4, 2), 16)) })
foreach ($png in Get-ChildItem $Pack -Recurse -File -Filter *.png | Where-Object { $_.FullName -notmatch '\\(\.git|tools|screenshots)\\' }) {
    $rel = $png.FullName.Substring($Pack.Length + 1)
    if ($rel -notmatch $Include) { continue }
    $n = [IconBg]::Apply($png.FullName, $L, $C, $Scale, $MaxSat, $MaxLum)
    "{0}: {1} background pixels moved onto the {2} ramp" -f $rel, $n, $Scheme
}
