# Recolours the vanilla UI shell sprites to the Noctis Bordo palette.
# Only pixel colours change: size, alpha and pixel positions stay vanilla.
#
# usage: recolor.ps1 -Src <vanilla pack dir> -Out <output dir> [-Folders a,b,c] [-DryRun]
param(
    [Parameter(Mandatory)] [string] $Src,
    [Parameter(Mandatory)] [string] $Out,
    [string[]] $Folders = @('bank','button','chatbox','dialog','equipment','fixed_mode','ge','other','resizeable_mode','scrollbar','options','stats','tab'),
    # only UI-shell sprites are recoloured; icon art stays vanilla (matched against the path relative to the pack root)
    [string] $Exclude = '^tab\\(?!(large|medium|small|side_border|stone|stash|transparent))|^other\\(?!(window_frame|old_school_mode_side_panel|minimap_orb_frame|minimap_orb_empty|minimap_orb_xp|minimap_orb_world_map_frame|spectate_orb_frame|compass|world_switcher_filter|world_switcher_middle|mortimer_task_select|selector_arrow|reset_killcount|window_close_button\.|window_close_button_hovered|window_close_button_parchment))|^button\\(equipment_(call|guide|items|stats)|friends|ignores|music_|sort_by_|slayer_rewards)|^bank\\(pin_marble|gim_|noted_items|search|deposit_|send_|potion_storage|placeholders_lock|shuffle_items|swap_items|insert_items|worn_items|incinerator|tab_all_items|tab_add)|^options\\(?!(checkbox|round_check_box|round_square|square_bordered|square_check_box|slider_|zoom_slider|scrollbar_arrow|slayer_|disabled_option))|^ge\\(cancel_offer|collection_box|fast_|guide_price)',
    # light parchment surfaces that move onto Lux creams (tan_border frames stay on the Bordo ramp)
    [string] $Parchment = '^chatbox\\(background|make_all_background)\.|^dialog\\background|^other\\(window_close_button_parchment)',
    # the compass vignette goes fully onto Lux cream
    [string] $Compass = '^other\\compass\.',
    # make-all button fill: a pure tint, so it keeps the vanilla relationship of sitting a touch darker than the chat fill
    [string] $Flat = '^chatbox\\make_all_background\.',
    [string] $Fill = '^chatbox\\background\.',
    # chat tab buttons: the selected/hovered orange must recolour fully, not half
    [string] $Relaxed = '^chatbox\\(button\.|button_hovered|button_selected|buttons_background_stones)',
    # extra sprites to leave alone on top of -Exclude (e.g. coloured art that is not shell)
    [string] $ExtraExclude = '',
    # a pack whose sprite tones to match (the vanilla sample pack): same-named sprites are darkened to its average, never brightened
    [string] $RefSrc = '',
    [double] $MinScale = 0.5,
    [string] $Scheme = 'bordo',
    [switch] $DryRun
)

. (Join-Path $PSScriptRoot 'schemes.ps1')

Add-Type -ReferencedAssemblies System.Drawing -TypeDefinition @'
using System;
using System.Drawing;
using System.Drawing.Imaging;
using System.Runtime.InteropServices;

public static class Bordo
{
    // Luminance (0-255) -> Noctis Bordo ramp
    static double[] L = { 0, 40, 51, 61, 70, 100, 140, 190, 255 };
    static int[][] C = {
        new[]{0x1a,0x15,0x16}, // outline
        new[]{0x25,0x1d,0x1f},
        new[]{0x2c,0x23,0x24}, // sideBar, warmed towards wine
        new[]{0x33,0x29,0x2a}, // editor background
        new[]{0x3b,0x30,0x31}, // Bordo tab.inactiveBackground
        new[]{0x54,0x42,0x42},
        new[]{0x78,0x5e,0x5c},
        new[]{0xa8,0x8a,0x86}, // bevel highlight (rose)
        new[]{0xe6,0xd2,0xcf}
    };

    // Parchment surfaces (chatbox, dialogs) stay light so the vanilla dark text remains readable;
    // the tan fill moves onto Noctis Lux creams while the dark frame pixels stay Bordo
    // the fill starts early (lum 150) so the vanilla edge shading becomes cream, not muddy grey
    static double[] LP = { 0, 60, 100, 130, 150, 175, 200, 225, 255 };
    static int[][] CP = {
        new[]{0x1a,0x15,0x16}, // Bordo outline
        new[]{0x25,0x1d,0x1f},
        new[]{0x3b,0x30,0x31},
        new[]{0x54,0x42,0x42}, // Bordo frame highlight
        new[]{0xd9,0xc9,0xa3},
        new[]{0xe6,0xd7,0xb2}, // Lux tab.border
        new[]{0xf0,0xe9,0xd6}, // Lux tab.inactiveBackground
        new[]{0xf9,0xf1,0xe1}, // Lux sideBar.background
        new[]{0xfe,0xf8,0xec}  // Lux editor.background
    };

    // Cream tint for the compass and chatbox fill: vector, fill floor, compass lift (base + slope). Defaults are Lux.
    static double[] V = { 236, 216, 172 };
    static double FillFloor = 172, CompassBase = 140, CompassSlope = 0.55;
    public static void SetTint(double[] v, double floor, double cBase, double cSlope) { V = v; FillFloor = floor; CompassBase = cBase; CompassSlope = cSlope; }

    // Swaps the dark shell ramp for another Noctis variant; the parchment frame follows it, the Lux creams stay
    public static void SetRamp(string[] hex, string[] parch)
    {
        for (int i = 0; i < hex.Length; i++)
            C[i] = new[] { Convert.ToInt32(hex[i].Substring(0, 2), 16), Convert.ToInt32(hex[i].Substring(2, 2), 16), Convert.ToInt32(hex[i].Substring(4, 2), 16) };
        CP[0] = C[0]; CP[1] = C[1]; CP[2] = C[4]; CP[3] = C[5];
        if (parch != null)
            for (int i = 0; i < parch.Length; i++)
                CP[4 + i] = new[] { Convert.ToInt32(parch[i].Substring(0, 2), 16), Convert.ToInt32(parch[i].Substring(2, 2), 16), Convert.ToInt32(parch[i].Substring(4, 2), 16) };
    }

    // Compass and chatbox fill are pure tints: vanilla luminance (and so its texture) is kept exactly and
    // only the hue moves to Lux cream (#e6d7b2). In the chatbox background the frame pixels
    // stay on the Bordo ramp, and the fill is floored at the vanilla fill level so the inner shadow cannot bleed into it.
    static void Map(double lum, int mode, out int r, out int g, out int b)
    {
        if (mode == 2 || mode == 4 || mode == 5)
        {
            if (mode == 2 && lum >= 50) lum = CompassBase + (lum - 50) * CompassSlope;   // compass: lift the vignette towards the chatbox tan, keep most of its texture and the dark N
            double s = Math.Min((mode == 4 ? Math.Max(lum, FillFloor) : lum) / 217.0, 255.0 / Math.Max(V[0], Math.Max(V[1], V[2])));
            double vr = V[0], vg = V[1], vb = V[2];
            r = (int)Math.Min(255, Math.Round(vr * s));
            g = (int)Math.Min(255, Math.Round(vg * s));
            b = (int)Math.Min(255, Math.Round(vb * s));
            return;
        }
        double[] l = mode == 1 ? LP : L;
        int[][] c = mode == 1 ? CP : C;
        int i = 0;
        while (i < l.Length - 2 && lum > l[i + 1]) i++;
        double t = Math.Max(0, Math.Min(1, (lum - l[i]) / (l[i + 1] - l[i])));
        r = (int)Math.Round(c[i][0] + (c[i + 1][0] - c[i][0]) * t);
        g = (int)Math.Round(c[i][1] + (c[i + 1][1] - c[i][1]) * t);
        b = (int)Math.Round(c[i][2] + (c[i + 1][2] - c[i][2]) * t);
    }

    // true for the vanilla brown/stone/grey shell pixels; coloured art is left alone
    static bool IsShell(int r, int g, int b, double lum, bool relaxed)
    {
        int max = Math.Max(r, Math.Max(g, b)), min = Math.Min(r, Math.Min(g, b));
        if (max < 20) return true;                       // black outlines
        double sat = (max - min) / (double)max;
        if (sat < 0.05) return lum < 150;                // neutral greys, not whites
        double h;
        double d = max - min;
        if (max == r) h = 60 * (((g - b) / d) % 6);
        else if (max == g) h = 60 * ((b - r) / d + 2);
        else h = 60 * ((r - g) / d + 4);
        if (h < 0) h += 360;
        if (h >= 15 && h <= 62) return relaxed || sat <= 0.42;   // relaxed: parchment edge shading is saturated brown
        return h > 62 && h <= 85 && (relaxed || sat <= 0.8);   // olive stone edges / marble
    }

    // mean luminance of the opaque pixels, used to match a sprite's tone to a reference sprite
    public static double MeanLum(string path)
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

    public static int[] Process(string inPath, string outPath, int mode) { return Process(inPath, outPath, mode, 1.0); }

    // returns { changed, total } pixel counts; scale darkens the luminance before it goes through the ramp (tints are unaffected)
    public static int[] Process(string inPath, string outPath, int mode, double scale)
    {
        int changed = 0, total = 0;
        using (var src = new Bitmap(inPath))
        using (var bmp = new Bitmap(src.Width, src.Height, PixelFormat.Format32bppArgb))
        {
            using (var g = Graphics.FromImage(bmp)) g.DrawImage(src, 0, 0, src.Width, src.Height);
            var rect = new Rectangle(0, 0, bmp.Width, bmp.Height);
            var data = bmp.LockBits(rect, ImageLockMode.ReadWrite, PixelFormat.Format32bppArgb);
            int n = Math.Abs(data.Stride) * bmp.Height;
            byte[] px = new byte[n];
            Marshal.Copy(data.Scan0, px, 0, n);
            for (int y = 0; y < bmp.Height; y++)
                for (int x = 0; x < bmp.Width; x++)
                {
                    int o = y * data.Stride + x * 4;
                    if (px[o + 3] == 0) continue;
                    total++;
                    int b = px[o], gg = px[o + 1], r = px[o + 2];
                    double lum = 0.299 * r + 0.587 * gg + 0.114 * b;
                    if (!IsShell(r, gg, b, lum, mode != 0)) continue;
                    int nr, ng, nb;
                    // chatbox background: the 7px frame (6px right/bottom) is Bordo, the inside is the tinted fill
                    bool frame = mode == 4 && (x < 7 || y < 7 || x >= bmp.Width - 6 || y >= bmp.Height - 6);
                    int m = frame ? 1 : mode;
                    Map((m == 2 || m == 4 || m == 5) ? lum : lum * scale, m, out nr, out ng, out nb);
                    px[o] = (byte)nb; px[o + 1] = (byte)ng; px[o + 2] = (byte)nr;
                    changed++;
                }
            Marshal.Copy(px, 0, data.Scan0, n);
            bmp.UnlockBits(data);
            if (changed > 0 && !string.IsNullOrEmpty(outPath)) bmp.Save(outPath, ImageFormat.Png);
        }
        return new[] { changed, total };
    }
}
'@

[Bordo]::SetRamp([string[]]$Schemes[$Scheme].C, [string[]]$Schemes[$Scheme].P)
if ($Schemes[$Scheme].Tint) { $tn = $Schemes[$Scheme].Tint; [Bordo]::SetTint([double[]]$tn.V, $tn.Floor, $tn.Base, $tn.Slope) }
$Out = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($Out)   # System.Drawing resolves relative paths against the process dir, not the shell's
$Src = (Get-Item $Src).FullName
if ($RefSrc) { $RefSrc = (Get-Item $RefSrc).FullName }
$report = foreach ($f in $Folders) {
    foreach ($png in Get-ChildItem (Join-Path $Src $f) -Filter *.png -File -Recurse) {
        $rel = $png.FullName.Substring($Src.Length).TrimStart('\')
        if ($rel -match $Exclude -or ($ExtraExclude -and $rel -match $ExtraExclude)) { continue }
        $dest = $null
        if (-not $DryRun) {
            $dest = Join-Path $Out $rel
            New-Item -ItemType Directory -Force (Split-Path $dest) | Out-Null
        }
        # sprites that also exist in the reference pack are darkened to its average tone, never brightened
        $scale = 1.0
        if ($RefSrc -and (Test-Path (Join-Path $RefSrc $rel))) {
            $mine = [Bordo]::MeanLum($png.FullName); $ref = [Bordo]::MeanLum((Join-Path $RefSrc $rel))
            if ($mine -gt 0 -and $ref -gt 0) { $scale = [Math]::Max($MinScale, [Math]::Min(1.0, $ref / $mine)) }
        }
        $res = [Bordo]::Process($png.FullName, $dest, $(if ($rel -match $Fill) { 4 } elseif ($rel -match $Compass) { 2 } elseif ($rel -match $Flat) { 5 } elseif ($rel -match $Parchment) { 1 } elseif ($rel -match $Relaxed) { 3 } else { 0 }), $scale)
        $changed = $res[0]; $total = $res[1]
        [pscustomobject]@{ File = $rel; Total = $total; Changed = $changed; Pct = if ($total) { [math]::Round(100 * $changed / $total) } else { 0 } }
    }
}
$report | Export-Csv (Join-Path (Split-Path $PSScriptRoot) 'tools\last-run.csv') -NoTypeInformation
$report | Group-Object { $_.File.Split('\')[0] } | ForEach-Object {
    "{0,-16} files {1,4}  recoloured {2,4}" -f $_.Name, $_.Count, ($_.Group | Where-Object Changed -gt 0).Count
}
