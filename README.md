# 2005 Noctis Bordo

GNASH0R's [2005](https://github.com/melkypie/resource-packs/tree/pack-2005) interface, recoloured to the **Bordo** variant of the [Noctis](https://github.com/liviuschera/noctis) colour scheme for the RuneLite [Resource Packs](https://github.com/melkypie/resource-packs) plugin, with the chat parchment in Noctis **Lux** creams. Built for the Resizeable layout.

No sprite is redrawn. The 2005-specific art keeps its original shapes, shading and transparency and only the colours change, while the standard buttons and stones are the same recoloured vanilla sprites as the [Vanilla Noctis Bordo pack](https://github.com/opher290/bordo-resource-pack), so the two sit side by side seamlessly. The compass dial keeps its red-and-orange look in Bordo reds, and icons are left exactly as the original author drew them.

## Screenshots

![Bank and chatbox in Resizeable mode](screenshots/bank.webp)

## Installation

Install the **Resource packs** plugin from the Plugin Hub, then install this pack from its hub. To use the 2005 interface style correctly, follow GNASH0R's setup from the original 2005 packs:

1. Go to RuneLite's plugins, enable **Interface Styles**, open its settings and set `Gameframe` to `2005`.
2. Go to the **Resource packs** plugin settings and tick the experimental setting at the bottom, `Don't change Interface Styles`.
3. Disable and re-enable the Resource packs plugin, and you're done.

If you want to use other packs afterwards, make sure to disable the **Interface Styles** plugin and disable/re-enable Resource packs for them to work correctly, unless their creators specify otherwise.

As the original notes, 2005 can't match the original exactly in Resizeable mode because of the plugin's limits.

## What changes

| Area | Source |
| --- | --- |
| Buttons, tab stones, bank, scrollbars, checkboxes and sliders, GE, equipment slots, dialog panels | Taken as-is from the [Vanilla Noctis Bordo pack](https://github.com/opher290/bordo-resource-pack), so they match it exactly |
| Side panel, tab rows, minimap frame, window edges, the black steel dialog borders, chat buttons | The original 2005 art recoloured to the Bordo rose-greys (`#1a1516` through `#33292a` to `#a88a86`), darkened to the Vanilla Noctis Bordo pack's tone |
| Chat parchment | Lux creams, keeping the original shading and torn edges, with the burnt edge moved onto the Bordo rose-greys |
| Compass dial | Keeps its red-and-orange look, moved onto Bordo red `#8c2f45` to a brighter red `#b83a48` |
| Overlay, borders and separators | The Vanilla Noctis Bordo pack's `vars.toml` and `overrides.toml`, unchanged |
| Icons, emotes, prayer and quest art, selected tabs | Left exactly as the original author drew them |

## Related packs

- [Vanilla Noctis Bordo](https://github.com/opher290/bordo-resource-pack): the vanilla-interface version of this palette.
- [2005 Gruvbox Dark](https://github.com/opher290/gruvbox-2005-resource-pack): the same 2005 approach on a warm grey palette.

## Building it yourself

`tools/build.ps1` regenerates the pack from a checkout of the original (`pack-2005`):

- `recolor.ps1 -Scheme bordo` recolours the shell sprites onto the Bordo ramp (`schemes.ps1`). The 2005 stone is about twice as bright as vanilla's, so with `-RefSrc` (the vanilla sample pack, passed as `-Vanilla` to `build.ps1`) each sprite is darkened to its vanilla counterpart's tone. `-MainPack` is a checkout of the main Bordo pack: its buttons, stones, bank, scrollbars, options, GE, equipment and dialog sprites are used as-is, and it fills anything the original leaves out.
- `tonematch.ps1` nudges the recoloured frames onto the Vanilla Noctis Bordo pack's exact tone, `compass.ps1` recolours the compass dial, `chatedge.ps1` moves the chat parchment's burnt edge onto the Bordo ramp, and `icon.ps1` builds `icon.png`.

## Credits

- **GNASH0R** for the [2005 pack](https://github.com/melkypie/resource-packs/tree/pack-2005) this is based on: the interface art, layout and icons.
- [Noctis](https://github.com/liviuschera/noctis) by Liviu Schera for the Bordo and Lux colour schemes.
- [melkypie](https://github.com/melkypie/resource-packs) for the Resource Packs plugin.




