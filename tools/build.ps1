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

# the 2005 interface has its own chamfered selected-tab stones: keep GNASH0R's shapes instead of the main pack's vanilla ones
Get-ChildItem (Join-Path $Src 'tab') -Filter 'stone_*_selected.png' | Copy-Item -Destination (Join-Path $Out 'tab') -Force

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

# the parchment's burnt edge is a dark olive-brown of its own: move it onto the scheme's shell ramp
& (Join-Path $PSScriptRoot 'chatedge.ps1') -Out $Out -Scheme $Scheme -Cutoff $(if ($Scheme -eq 'gruvbox') { 100 } else { 120 })

# the red selected-tab stones are tinted to brick red, keeping GNASH0R's shapes and shading
& (Join-Path $PSScriptRoot 'stone.ps1') -Pack $Out

# the grey-olive plates behind the emote labels and a few icon buttons move onto the shell ramp; the label text and icon art stay as drawn
# Bordo's chat parchment is Noctis Lux inspired: lift the fill onto the Lux cream and soften the dark outline round the torn edge
if ($Scheme -eq 'bordo') { & (Join-Path $PSScriptRoot 'chatfill.ps1') -Out $Out }
& (Join-Path $PSScriptRoot 'emote.ps1') -Pack $Out -Scheme $Scheme
& (Join-Path $PSScriptRoot 'iconbg.ps1') -Pack $Out -Scheme $Scheme

# the bank PIN screen's red marble buttons and tiles are tinted, and the olive marble behind Exit moves onto the shell ramp
& (Join-Path $PSScriptRoot 'pin.ps1') -Pack $Out -Vanilla $Vanilla -Scheme $Scheme

# GNASH0R's 2005 pack ships seven tab icons empty (chat channels, group ironman, red minigames); use the 2005 Overhaul pack's (by Demonseance), kept in tools\assets (as drawn, except clan_chat: moved 5px right and 2px down so it sits in the bottom-left corner stone, as GNASH0R shifts the other corner-stone icons)
foreach ($n in 'clan_chat', 'clan_channel', 'guest_clan_channel', 'regular_group_ironman', 'unranked_group_ironman', 'hardcore_group_ironman', 'quests_red_minigames') { Copy-Item (Join-Path $PSScriptRoot "assets\$n.png") (Join-Path $Out "tab\$n.png") -Force }

# the three Deposit buttons in the bank are the 2005 Overhaul pack's (by Demonseance), cleaner than the original; the Deposit inventory bag is drawn without the black outline every other icon has, so it gets one
foreach ($n in 'deposit_inventory', 'deposit_equipment', 'deposit_looting_bag') { Copy-Item (Join-Path $PSScriptRoot "assets\bank\$n.png") (Join-Path $Out "bank\$n.png") -Force }
& (Join-Path $PSScriptRoot 'depositoutline.ps1') -Pack $Out

# the black drop shadow on the tab icons varies: give stats, combat, equipment, prayer and emotes the same solid 2px down-right shadow as the Quests and Friends icons, thin it a little on the inventory bag and the friends and ignore smileys, and add a soft row to the music harp
& (Join-Path $PSScriptRoot 'shadow.ps1') -Pack $Out


& (Join-Path $PSScriptRoot 'icon.ps1') -Pack $Out

