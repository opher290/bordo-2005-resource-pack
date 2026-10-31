# Lifts the chat parchment onto Noctis Lux cream and softens its torn edge. The recoloured parchment is a muted tan, a lot
# darker than the Lux creams the pack is inspired by (tab.border #e6d7b2 up to editor.background #fef8ec).
#
# The fill is not repainted: every parchment pixel keeps its own brightness relative to the sprite's average parchment
# brightness, so the mottling survives, but the colour moves onto the Lux cream and the blotches are flattened a little
# (-Flatten) so the darker patches along the tears stop standing out. Where the sprite has a dark outline round the torn
# edge (the 2005 chat box), the outline is blended part of the way towards the cream (-Soften) instead of staying near black.
#
# usage: chatfill.ps1 -Out <pack dir> [-Cream e6d7b2] [-Flatten 0.25] [-Soften 0.85] [-Cutoff 120] [-FillMin 150] [-FillMax 215] [-Files chatbox\background.png,chatbox\make_all_background.png]
param(
    [Parameter(Mandatory)] [string] $Out,
    [string] $Cream = 'e6d7b2',
    # 1 keeps the parchment's blotches as they are, 0 removes them
    [double] $Flatten = 0.25,
    # 0 keeps the outline as it is, 1 turns it into the cream
    [double] $Soften = 0.85,
    # brightness below which a pixel is outline or frame
    [double] $Cutoff = 120,
    # brightness range of the parchment fill (the Gruvbox parchment is darker than Bordo's)
    [double] $FillMin = 150,
    [double] $FillMax = 215,
    # sprites to lift, relative to the pack folder; the Make-all panel sits in the chat area and must match
    [string[]] $Files = @('chatbox\background.png', 'chatbox\make_all_background.png')
)
Add-Type -ReferencedAssemblies System.Drawing -TypeDefinition @'
using System;
using System.Drawing;
using System.Drawing.Imaging;
using System.Runtime.InteropServices;

public static class ChatFill
{
    static double Lum(byte[] px, int i) { return 0.299 * px[i + 2] + 0.587 * px[i + 1] + 0.114 * px[i]; }

    public static string Apply(string path, int[] cream, double flatten, double soften, double cutoff, double fillMin, double fillMax)
    {
        int fill = 0, outline = 0;
        using (var src = new Bitmap(path))
        using (var bmp = new Bitmap(src.Width, src.Height, PixelFormat.Format32bppArgb))
        {
            using (var g = Graphics.FromImage(bmp)) g.DrawImage(src, 0, 0, src.Width, src.Height);
            var data = bmp.LockBits(new Rectangle(0, 0, bmp.Width, bmp.Height), ImageLockMode.ReadWrite, PixelFormat.Format32bppArgb);
            int n = Math.Abs(data.Stride) * bmp.Height;
            byte[] px = new byte[n];
            Marshal.Copy(data.Scan0, px, 0, n);

            // the parchment is the big warm-tan population; its mean brightness is the reference the blotches are measured against
            double sum = 0; long cnt = 0;
            for (int i = 0; i < n; i += 4)
            {
                if (px[i + 3] == 0) continue;
                double lum = Lum(px, i);
                if (lum >= fillMin && lum <= fillMax && px[i + 2] > px[i + 1] && px[i + 1] > px[i]) { sum += lum; cnt++; }
            }
            if (cnt == 0) return "no parchment in this sprite, left as it is";
            double refLum = sum / cnt;
            double creamLum = 0.299 * cream[0] + 0.587 * cream[1] + 0.114 * cream[2];

            for (int i = 0; i < n; i += 4)
            {
                if (px[i + 3] == 0) continue;
                double lum = Lum(px, i);
                bool tan = px[i + 2] > px[i + 1] && px[i + 1] > px[i];
                if (lum >= fillMin && lum <= fillMax && tan)
                {
                    double r = 1 + (lum / refLum - 1) * flatten;
                    for (int c = 0; c < 3; c++) px[i + 2 - c] = (byte)Math.Max(0, Math.Min(255, Math.Round(cream[c] * r)));
                    fill++;
                }
                else if (lum < cutoff && soften > 0)
                {
                    for (int c = 0; c < 3; c++) px[i + 2 - c] = (byte)Math.Round(px[i + 2 - c] + (cream[c] - px[i + 2 - c]) * soften);
                    outline++;
                }
            }
            Marshal.Copy(px, 0, data.Scan0, n);
            bmp.UnlockBits(data);
            src.Dispose();
            bmp.Save(path + ".tmp", ImageFormat.Png);
            System.IO.File.Delete(path);
            System.IO.File.Move(path + ".tmp", path);
            return string.Format("{0} parchment pixels moved onto the cream (reference brightness {1:F0}), {2} edge pixels softened", fill, refLum, outline);
        }
    }
}
'@

$Out = (Get-Item $Out).FullName
$rgb = [int[]]@([Convert]::ToInt32($Cream.Substring(0, 2), 16), [Convert]::ToInt32($Cream.Substring(2, 2), 16), [Convert]::ToInt32($Cream.Substring(4, 2), 16))
foreach ($f in $Files) { "${f}: " + [ChatFill]::Apply((Join-Path $Out $f), $rgb, $Flatten, $Soften, $Cutoff, $FillMin, $FillMax) }
