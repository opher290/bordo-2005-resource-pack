# Puts the 2005 Overhaul pack's tab icons (by Demonseance) onto GNASH0R's canvas. The Overhaul icons are drawn on a 32x36 canvas for
# its own layout, GNASH0R's on 33x36 and moved around inside it (the corner stones' icons sit further in), so an Overhaul icon
# cannot just be copied over: it would land in the wrong place in the resizable layout GNASH0R built.
#
# For every icon, the Overhaul sprite is slid over GNASH0R's sprite in the pack and the offset that matches the most pixels is
# used, so the icon ends up exactly where GNASH0R put it, with Overhaul's drawing. If the two drawings differ too much for a fit
# (-MaxResidual pixels), the sprite is placed at 0,0 when the canvases are the same size and left as GNASH0R's otherwise.
# Sprites GNASH0R leaves blank are not handled here (build.ps1 copies those from tools\assets).
#
# usage: overhaul.ps1 -Pack <pack dir> [-Assets <dir of Overhaul tab icons>] [-Skip name,...] [-MaxResidual 120]
param(
    [Parameter(Mandatory)] [string] $Pack,
    [string] $Assets = (Join-Path $PSScriptRoot 'assets\overhaul\tab'),
    # sprites that are blank in GNASH0R's pack or already provided from tools\assets
    [string[]] $Skip = @('clan_channel', 'clan_chat', 'guest_clan_channel', 'regular_group_ironman', 'unranked_group_ironman', 'hardcore_group_ironman', 'quests_red_minigames', 'quests_brown_raiding_party'),
    [int] $MaxResidual = 120
)
Add-Type -ReferencedAssemblies System.Drawing -TypeDefinition @'
using System;
using System.Drawing;
using System.Drawing.Imaging;

public static class OverhaulPlace
{
    static int Key(Color c) { return c.A == 0 ? 0 : c.ToArgb(); }

    public static string Place(string artPath, string refPath)
    {
        string result;
        using (var a = new Bitmap(artPath))
        using (var r = new Bitmap(refPath))
        {
            int best = int.MaxValue, bdx = 0, bdy = 0;
            for (int dy = -8; dy <= 8; dy++)
                for (int dx = -8; dx <= 8; dx++)
                {
                    int diff = 0;
                    for (int y = 0; y < r.Height && diff < best; y++)
                        for (int x = 0; x < r.Width; x++)
                        {
                            int sx = x - dx, sy = y - dy;
                            int ca = (sx >= 0 && sy >= 0 && sx < a.Width && sy < a.Height) ? Key(a.GetPixel(sx, sy)) : 0;
                            if (ca != Key(r.GetPixel(x, y))) diff++;
                        }
                    if (diff < best) { best = diff; bdx = dx; bdy = dy; }
                }
            result = string.Format("{0},{1},{2}", bdx, bdy, best);
        }
        return result;
    }

    public static void Write(string artPath, string refPath, string outPath, int dx, int dy)
    {
        using (var a = new Bitmap(artPath))
        using (var r = new Bitmap(refPath))
        using (var o = new Bitmap(r.Width, r.Height, PixelFormat.Format32bppArgb))
        {
            for (int y = 0; y < a.Height; y++)
                for (int x = 0; x < a.Width; x++)
                {
                    int nx = x + dx, ny = y + dy;
                    var c = a.GetPixel(x, y);
                    if (c.A == 0) continue;
                    if (nx < 0 || ny < 0 || nx >= o.Width || ny >= o.Height) throw new Exception("icon would leave the sprite: " + artPath);
                    o.SetPixel(nx, ny, c);
                }
            r.Dispose();
            o.Save(outPath + ".tmp", ImageFormat.Png);
        }
        System.IO.File.Delete(outPath); System.IO.File.Move(outPath + ".tmp", outPath);
    }
}
'@

$Pack = (Get-Item $Pack).FullName
foreach ($f in Get-ChildItem $Assets -Filter *.png) {
    $n = $f.BaseName
    if ($Skip -contains $n) { continue }
    $dst = Join-Path $Pack "tab\$n.png"
    if (-not (Test-Path $dst)) { continue }
    $ref = [IO.Path]::GetTempFileName() + '.png'
    Copy-Item $dst $ref -Force
    $p = [OverhaulPlace]::Place($f.FullName, $ref) -split ','
    $dx = [int]$p[0]; $dy = [int]$p[1]; $res = [int]$p[2]
    $how = 'fitted'
    Add-Type -AssemblyName System.Drawing
    $a = New-Object System.Drawing.Bitmap $f.FullName; $r = New-Object System.Drawing.Bitmap $ref
    $same = ($a.Width -eq $r.Width -and $a.Height -eq $r.Height); $a.Dispose(); $r.Dispose()
    if ($res -gt $MaxResidual) {
        if ($same) { $dx = 0; $dy = 0; $how = 'drawings differ, placed at 0,0' } else { Remove-Item $ref; "tab\${n}.png: drawings differ and canvases differ, left as GNASH0R's"; continue }
    }
    [OverhaulPlace]::Write($f.FullName, $ref, $dst, $dx, $dy)
    Remove-Item $ref
    "tab\${n}.png: Overhaul icon placed at $dx,$dy ($how, $res pixels unmatched)"
}
