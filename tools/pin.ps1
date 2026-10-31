# The bank PIN screen: its red marble buttons and tiles are tinted to brick red, and the olive-brown marble behind
# "Exit / I don't know it" moves onto the scheme's shell ramp. The pack does not otherwise ship these three sprites, so
# they are copied from the vanilla sample pack first.
#
# The red sprites are not redrawn: each fill pixel keeps its own brightness relative to the sprite's highlight and only its
# colour moves to brick, exactly like stone.ps1. The pale bevel along the button's top and left edge is blended towards a
# light brick instead, so the button keeps its raised look.
#
# usage: pin.ps1 -Pack <pack dir> -Vanilla <vanilla sample pack> -Scheme bordo [-Red 8f3f2a] [-Scale 0.85]
param(
    [Parameter(Mandatory)] [string] $Pack,
    [Parameter(Mandatory)] [string] $Vanilla,
    [string] $Scheme = 'bordo',
    # button colour and bevel light; blank picks the scheme's own (Gruvbox brick, Bordo wine)
    [string] $Red = '',
    [string] $Light = '',
    # brightness multiplier applied before the ramp lookup for the olive marble
    [double] $Scale = 0.85
)
. (Join-Path $PSScriptRoot 'schemes.ps1')
Add-Type -ReferencedAssemblies System.Drawing -TypeDefinition @'
using System;
using System.Collections.Generic;
using System.Drawing;
using System.Drawing.Imaging;
using System.Runtime.InteropServices;

public static class PinMarble
{
    static double Sat(int r, int g, int b) { int mx = Math.Max(r, Math.Max(g, b)), mn = Math.Min(r, Math.Min(g, b)); return mx == 0 ? 0 : (mx - mn) / (double)mx; }
    static double Lum(int r, int g, int b) { return 0.299 * r + 0.587 * g + 0.114 * b; }

    static void Edit(string path, Action<byte[], int, int, int> f)
    {
        using (var src = new Bitmap(path))
        using (var bmp = new Bitmap(src.Width, src.Height, PixelFormat.Format32bppArgb))
        {
            using (var g = Graphics.FromImage(bmp)) g.DrawImage(src, 0, 0, src.Width, src.Height);
            var data = bmp.LockBits(new Rectangle(0, 0, bmp.Width, bmp.Height), ImageLockMode.ReadWrite, PixelFormat.Format32bppArgb);
            int n = Math.Abs(data.Stride) * bmp.Height;
            byte[] px = new byte[n];
            Marshal.Copy(data.Scan0, px, 0, n);
            f(px, n, bmp.Width, bmp.Height);
            Marshal.Copy(px, 0, data.Scan0, n);
            bmp.UnlockBits(data);
            src.Dispose();
            bmp.Save(path + ".tmp", ImageFormat.Png);
        }
        System.IO.File.Delete(path);
        System.IO.File.Move(path + ".tmp", path);
    }

    // brick tint over a red sprite, with the pale bevel blended towards a light brick
    public static void Brick(string path, int[] brick, int[] light)
    {
        Edit(path, (px, n, w, h) =>
        {
            var fill = new List<double>();
            double maxLum = 0;
            for (int i = 0; i < n; i += 4)
            {
                if (px[i + 3] == 0) continue;
                double lum = Lum(px[i + 2], px[i + 1], px[i]);
                if (lum > maxLum) maxLum = lum;
                if (Sat(px[i + 2], px[i + 1], px[i]) > 0.45) fill.Add(lum);
            }
            fill.Sort();
            // the marble is a narrow band of brightness; reference a little above its brightest so the fill lands as dark as the selected-tab stones
            double hi = fill[(int)(fill.Count * 0.97)] * 1.45;
            for (int i = 0; i < n; i += 4)
            {
                if (px[i + 3] == 0) continue;
                double lum = Lum(px[i + 2], px[i + 1], px[i]);
                double f = lum / hi;
                if (Sat(px[i + 2], px[i + 1], px[i]) > 0.45) f = Math.Min(f, 1);
                for (int c = 0; c < 3; c++)
                {
                    double v;
                    if (f <= 1) v = brick[c] * f;
                    else
                    {
                        double t = Math.Min(1, (f - 1) / Math.Max(0.01, maxLum / hi - 1));
                        v = brick[c] + (light[c] - brick[c]) * t;
                    }
                    px[i + 2 - c] = (byte)Math.Min(255, Math.Round(v));
                }
            }
        });
    }

    // the whole sprite through the scheme's ramp, by brightness
    public static void Ramp(string path, double[] L, int[][] C, double scale)
    {
        Edit(path, (px, n, w, h) =>
        {
            for (int i = 0; i < n; i += 4)
            {
                if (px[i + 3] == 0) continue;
                double lum = Lum(px[i + 2], px[i + 1], px[i]) * scale;
                int k = 0;
                while (k < L.Length - 2 && lum > L[k + 1]) k++;
                double t = Math.Max(0, Math.Min(1, (lum - L[k]) / (L[k + 1] - L[k])));
                for (int c = 0; c < 3; c++)
                    px[i + 2 - c] = (byte)Math.Round(C[k][c] + (C[k + 1][c] - C[k][c]) * t);
            }
        });
    }
}
'@

function ConvertTo-Rgb([string]$hex) { [int[]]@([Convert]::ToInt32($hex.Substring(0, 2), 16), [Convert]::ToInt32($hex.Substring(2, 2), 16), [Convert]::ToInt32($hex.Substring(4, 2), 16)) }

$Pack = (Get-Item $Pack).FullName
$Vanilla = (Get-Item $Vanilla).FullName
$dir = Join-Path $Pack 'bank'
New-Item -ItemType Directory -Force $dir | Out-Null
foreach ($n in 'pin_marble_background', 'pin_marble_background_red', 'pin_marble_button_red') {
    Copy-Item (Join-Path $Vanilla "bank\$n.png") (Join-Path $dir "$n.png") -Force
}
$tints = @{ gruvbox = @('8f3f2a', 'd8b4a6'); bordo = @('8c2f45', 'd6b0bc') }
if (-not $Red) { $Red = $tints[$Scheme][0] }
if (-not $Light) { $Light = $tints[$Scheme][1] }
$brickRgb = ConvertTo-Rgb $Red; $lightRgb = ConvertTo-Rgb $Light
foreach ($n in 'pin_marble_background_red', 'pin_marble_button_red') { [PinMarble]::Brick((Join-Path $dir "$n.png"), $brickRgb, $lightRgb); "bank\$n.png: brick" }
$ramp = $Schemes[$Scheme]
$L = [double[]]$ramp.L
$C = [int[][]]@($ramp.C | ForEach-Object { , (ConvertTo-Rgb $_) })
[PinMarble]::Ramp((Join-Path $dir 'pin_marble_background.png'), $L, $C, $Scale); "bank\pin_marble_background.png: $Scheme ramp"
