# Moves the grey-olive stone plates behind the 2005 emote labels onto the scheme's shell ramp, so they match the other
# buttons. The coloured label text (yellow, green) is left exactly as drawn: only low-saturation pixels, the plate and its
# bevel, are mapped through the ramp by their own brightness, nudged by -Scale so the plate sits at the same tone as the
# buttons. Alpha and pixel positions are untouched.
#
# usage: emote.ps1 -Pack <pack dir> -Scheme bordo [-Scale 0.8] [-MaxSat 0.45]
param(
    [Parameter(Mandatory)] [string] $Pack,
    [string] $Scheme = 'bordo',
    # brightness multiplier applied before the ramp lookup (the 2005 plate is lighter than our buttons)
    [double] $Scale = 0.8,
    # pixels more saturated than this are label text and stay as drawn
    [double] $MaxSat = 0.45,
    [string] $Folder = 'emote'
)
. (Join-Path $PSScriptRoot 'schemes.ps1')
Add-Type -ReferencedAssemblies System.Drawing -TypeDefinition @'
using System;
using System.Drawing;
using System.Drawing.Imaging;
using System.Runtime.InteropServices;

public static class EmotePlate
{
    public static int Apply(string path, double[] L, int[][] C, double scale, double maxSat)
    {
        int changed = 0;
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
                int r = px[i + 2], g2 = px[i + 1], b = px[i];
                int mx = Math.Max(r, Math.Max(g2, b)), mn = Math.Min(r, Math.Min(g2, b));
                double sat = mx == 0 ? 0 : (mx - mn) / (double)mx;
                if (sat > maxSat) continue;
                double lum = (0.299 * r + 0.587 * g2 + 0.114 * b) * scale;
                int k = 0;
                while (k < L.Length - 2 && lum > L[k + 1]) k++;
                double t = Math.Max(0, Math.Min(1, (lum - L[k]) / (L[k + 1] - L[k])));
                for (int c = 0; c < 3; c++)
                    px[i + 2 - c] = (byte)Math.Round(C[k][c] + (C[k + 1][c] - C[k][c]) * t);
                changed++;
            }
            Marshal.Copy(px, 0, data.Scan0, n);
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
$count = 0
foreach ($png in Get-ChildItem (Join-Path $Pack $Folder) -Filter *.png -File) {
    [void][EmotePlate]::Apply($png.FullName, $L, $C, $Scale, $MaxSat)
    $count++
}
"$Folder`: $count plates moved onto the $Scheme ramp"
