# Lifts the chat parchment onto Noctis Lux cream and softens its torn edge. The recoloured parchment is a muted tan, a lot
# darker than the Lux creams the pack is inspired by (tab.border #e6d7b2 up to editor.background #fef8ec).
#
# The fill is not repainted: every parchment pixel keeps its own brightness relative to the sprite's average parchment
# brightness, so the mottling survives, but the colour moves onto the Lux cream and the blotches are flattened a little
# (-Flatten). Inside the parchment the texture is kept (-Flatten 1 is the original), but within -EdgeReach pixels of a tear or frame it is flattened to -EdgeFlatten, so the darker patches along the tears stop standing out while the middle keeps its grain. Where the sprite has a dark outline round the torn
# edge (the 2005 chat box), the outline is blended part of the way towards the cream (-Soften) instead of staying near black.
#
# usage: chatfill.ps1 -Out <pack dir> [-Cream e6d7b2] [-Flatten 1] [-EdgeFlatten 0.1] [-EdgeReach 22] [-Soften 0.85] [-Cutoff 120] [-FillMin 150] [-FillMax 215] [-Files chatbox\background.png,chatbox\make_all_background.png]
param(
    [Parameter(Mandatory)] [string] $Out,
    [string] $Cream = 'e6d7b2',
    # 1 keeps the parchment's blotches as they are, 0 removes them; the texture in the middle of the parchment
    [double] $Flatten = 1,
    # the same near a tear or frame (the 2005 edge is where the dark patches sit), reached gradually over -EdgeReach pixels
    [double] $EdgeFlatten = 0.1,
    [int] $EdgeReach = 22,
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

    public static string Apply(string path, int[] cream, double flatten, double edgeFlatten, int edgeReach, double soften, double cutoff, double fillMin, double fillMax)
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

            // distance (in pixels, 4-neighbour) of every pixel from the nearest empty or dark pixel, so the texture can be flattened near the edge only
            int w = bmp.Width, h = bmp.Height, stride = Math.Abs(data.Stride);
            int[] dist = new int[w * h];
            var q = new System.Collections.Generic.Queue<int>();
            for (int y = 0; y < h; y++)
                for (int x = 0; x < w; x++)
                {
                    int i = y * stride + x * 4;
                    bool edge = px[i + 3] == 0 || Lum(px, i) < cutoff;
                    dist[y * w + x] = edge ? 0 : int.MaxValue;
                    if (edge) q.Enqueue(y * w + x);
                }
            while (q.Count > 0)
            {
                int p = q.Dequeue(), x = p % w, y = p / w, nd = dist[p] + 1;
                if (x > 0 && dist[p - 1] > nd) { dist[p - 1] = nd; q.Enqueue(p - 1); }
                if (x < w - 1 && dist[p + 1] > nd) { dist[p + 1] = nd; q.Enqueue(p + 1); }
                if (y > 0 && dist[p - w] > nd) { dist[p - w] = nd; q.Enqueue(p - w); }
                if (y < h - 1 && dist[p + w] > nd) { dist[p + w] = nd; q.Enqueue(p + w); }
            }
            for (int i = 0; i < n; i += 4)
            {
                if (px[i + 3] == 0) continue;
                double lum = Lum(px, i);
                bool tan = px[i + 2] > px[i + 1] && px[i + 1] > px[i];
                if (lum >= fillMin && lum <= fillMax && tan)
                {
                    int pix = i / 4, px0 = (i % stride) / 4, py0 = i / stride;
                    double reach = Math.Min(1.0, dist[py0 * w + px0] / (double)Math.Max(1, edgeReach));
                    double fl = edgeFlatten + (flatten - edgeFlatten) * reach;
                    double r = 1 + (lum / refLum - 1) * fl;
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
foreach ($f in $Files) { "${f}: " + [ChatFill]::Apply((Join-Path $Out $f), $rgb, $Flatten, $EdgeFlatten, $EdgeReach, $Soften, $Cutoff, $FillMin, $FillMax) }
