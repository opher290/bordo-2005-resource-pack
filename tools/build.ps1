# Rebuilds the pack from GNASH0R's 2005 pack (Resizeable): https://github.com/melkypie/resource-packs/tree/pack-2005
#
# The 2005-specific shell art (chatbox and its buttons, the frames, minimap, black steel dialog borders) is recoloured
# to the scheme. Buttons, tab stones, bank, scrollbars, options, GE, equipment and dialog panels are taken as-is from the
# matching main pack rather than recreated, the compass dial keeps its look in the scheme's red and orange, and icons
# stay as the original author drew them.
#
# usage: build.ps1 -Src <checkout of pack-2005> -Out <pack dir> -Vanilla <vanilla sample pack> -MainPack <main pack> [-Scheme bordo|gruvbox]
param(
    [Parameter(Mandatory)] [string] $Src,
    [Parameter(Mandatory)] [string] $Out,
    # the vanilla sample pack: the 2005 stone is lighter than vanilla's, so same-named sprites are darkened to vanilla's tone
    [Parameter(Mandatory)] [string] $Vanilla,
    # the matching main pack (the same scheme recoloured from vanilla), e.g. the Bordo or Gruvbox pack
    [Parameter(Mandatory)] [string] $MainPack,
    [string] $Scheme = 'bordo'
)

$Src = (Get-Item $Src).FullName
$MainPack = (Get-Item $MainPack).FullName
$Out = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($Out)

# folders whose shell sprites come straight from the main pack (the 2005 black steel dialog borders stay 2005)
$FromMain = '^(button|bank|scrollbar|stats|ge|options|equipment|dialog|tab)\\(?!bottom_line_mode)'

# start from the untouched original so anything not recoloured (icons) ships as-is
Get-ChildItem $Src -Force | Where-Object { $_.Name -notin '.git', 'README.md', 'pack.properties', 'icon.png' } | Copy-Item -Destination $Out -Recurse -Force

# copy from the main pack: sprites the 2005 pack leaves out (they would fall back to RuneLite's unrecoloured
# defaults), and the same-named sprites in the folders above; vars.toml, overrides.toml and color.properties come along
# too, so the overlay, borders and separators follow the scheme
$have = @{}
Get-ChildItem $Src -Recurse -File | Where-Object { $_.FullName -notmatch '\\\.git\\' } | ForEach-Object { $have[$_.FullName.Substring($Src.Length + 1)] = $true }
Get-ChildItem $MainPack -Recurse -File | Where-Object { $_.FullName -notmatch '\\(\.git|tools|screenshots)\\' } | ForEach-Object {
    $rel = $_.FullName.Substring($MainPack.Length + 1)
    if ($rel -in 'README.md', 'pack.properties', 'icon.png') { return }
    if ($have.ContainsKey($rel) -and $rel -notmatch $FromMain -and $rel -ne 'overrides.toml') { return }
    $dest = Join-Path $Out $rel
    New-Item -ItemType Directory -Force (Split-Path $dest) | Out-Null
    Copy-Item $_.FullName $dest -Force
}

# recolour what stays 2005; the chat parchment and make-all fill are pure tints (Flat) so the burnt edges and texture are kept
& (Join-Path $PSScriptRoot 'recolor.ps1') -Src $Src -Out $Out -Scheme $Scheme -RefSrc $Vanilla `
    -Folders chatbox, fixed_mode, resizeable_mode, other, dialog `
    -ExtraExclude '^other\\compass\.|^dialog\\(?!bottom_line_mode)' `
    -Relaxed '^(fixed_mode|resizeable_mode|other|dialog)\\|^chatbox\\(button\.|button_hovered|button_selected|buttons_background_stones|report_button|sword_pointed)' `
    -Fill '^$' -Flat '^chatbox\\(background|make_all_background)\.'

# nudge the near-matches onto the main pack's exact tone so the two packs sit side by side seamlessly
& (Join-Path $PSScriptRoot 'tonematch.ps1') -Pack $Out -MainPack $MainPack

# the compass dial keeps its red-and-orange look, moved onto the scheme's red and orange
& (Join-Path $PSScriptRoot 'compass.ps1') -Src $Src -Out $Out -Scheme $Scheme

& (Join-Path $PSScriptRoot 'icon.ps1') -Pack $Out
