# Moves the dark burnt edge of the 2005 chat parchment onto the scheme's shell ramp. The parchment itself is a pure
# tint, but its torn edge is a separate dark olive-brown, which reads as leftover vanilla colour against a rose-grey shell.
# Pixels darker than the cut-off (there is a clean gap in the histogram between the edge and the parchment) are mapped
# through the scheme's ramp by their own brightness; everything else, including alpha, is untouched.
#
# usage: chatedge.ps1 -Out <pack dir> -Scheme bordo
param(
    [Parameter(Mandatory)] [string] $Out,
    [string] $Scheme = 'bordo',
    [double] $Cutoff = 120
)
. (Join-Path $PSScriptRoot 'schemes.ps1')
Add-Type -ReferencedAssemblies System.Drawing -TypeDefinition @'
using System;
using System.Drawing;
using System.Drawing.Imaging;
using System.Runtime.InteropServices;

public static class ChatEdge
{
    public static int Apply(string path, double[] L, int[][] C, double cutoff)
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
                double lum = 0.299 * px[i + 2] + 0.587 * px[i + 1] + 0.114 * px[i];
                if (lum >= cutoff) continue;
                int k = 0;
                while (k < L.Length - 2 && lum > L[k + 1]) k++;
                double t = Math.Max(0, Math.Min(1, (lum - L[k]) / (L[k + 1] - L[k])));
                for (int c = 0; c < 3; c++)
                {
                    double v = C[k][c] + (C[k + 1][c] - C[k][c]) * t;
                    px[i + 2 - c] = (byte)Math.Round(v);
                }
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

$Out = (Get-Item $Out).FullName
$ramp = $Schemes[$Scheme]
$L = [double[]]$ramp.L
$C = [int[][]]@($ramp.C | ForEach-Object { , [int[]]@([Convert]::ToInt32($_.Substring(0, 2), 16), [Convert]::ToInt32($_.Substring(2, 2), 16), [Convert]::ToInt32($_.Substring(4, 2), 16)) })
$target = Join-Path $Out 'chatbox\background.png'
$n = [ChatEdge]::Apply($target, $L, $C, $Cutoff)
"chatbox\background.png: $n edge pixels moved onto the $Scheme ramp"
