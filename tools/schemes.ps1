# Dark shell ramps per Noctis variant. L is vanilla luminance (0-255); C is the colour it maps to.
# Parchment surfaces stay on Lux creams in every variant, only the dark shell changes.
$Schemes = @{
    bordo = @{
        Name = 'Noctis Bordo'
        L = 0, 40, 51, 61, 70, 100, 140, 190, 255
        C = '1a1516', '251d1f', '2c2324', '33292a', '3b3031', '544242', '785e5c', 'a88a86', 'e6d2cf'
        # the 2005 compass dial: Bordo wine red, with a brighter red where the original was orange
        # the 2005 parchment is a little darker than vanilla's chat fill, so the Lux cream vector is lifted to land on Bordo's fill
        Tint = @{ V = 252, 231, 184; Floor = 172; Base = 140; Slope = 0.55 }
        Compass = @{ Red = '8c2f45'; Orange = 'b83a48'; Stops = '30:4a1a24', '56:76283a', '65:84303f', '78:a43c38', '92:c45e2e', '107:de892c', '119:f2b13e' }
        Accent = 'f18eb0'
        # the chat parchment is lifted onto this cream (Noctis Lux tab.border); the fill is the sprite's tan between these brightnesses
        ChatFill = @{ Cream = 'e6d7b2'; FillMin = 150; FillMax = 215; Cutoff = 120 }
        Overlay = '9c322a2d'
    }
    # Noctis (default): sideBar #041d20, editor #052529, tab #062e32, hover #0b515b
    noctis = @{
        Name = 'Noctis'
        L = 0, 40, 51, 61, 70, 100, 140, 190, 255
        C = '071113', '04181b', '041d20', '052529', '062e32', '0b4047', '3c6b72', '79a3a8', 'cfe6e6'
        Accent = 'df769b'
        Overlay = '9c041d20'
    }
    # Noctis Minimus: sideBar #17232b, editor #1b2932, tab #202e37
    minimus = @{
        Name = 'Noctis Minimus'
        L = 0, 40, 51, 61, 70, 100, 140, 190, 255
        C = '0d1519', '131c22', '17232b', '1b2932', '202e37', '30444f', '506577', '8da3b1', 'd6e2ea'
        Accent = '5998c0'
        Overlay = '9c17232b'
    }
    # Gruvbox dark: bg0_h #1d2021, bg0 #282828, bg0_s #32302f, bg2 #504945, bg4 #7c6f64, fg4 #a89984; parchment on the light cream set
    gruvbox = @{
        Name = 'Gruvbox'
        L = 0, 40, 51, 61, 70, 100, 140, 190, 255
        C = '141617', '1d2021', '232525', '282828', '32302f', '504945', '7c6f64', 'a89984', 'ebdbb2'
        # Gruvbox grey (#a89984 to #bdae93): a muted tan for the chatbox fill and compass, with a steep compass lift to keep its glow
        Tint = @{ V = 190, 173, 150; Floor = 172; Base = 138; Slope = 0.85 }
        P = 'd5c4a1', 'ebdbb2', 'f2e5bc', 'f6ecc0', 'fbf1c7'
        # the 2005 compass dial moves onto the palette's red and orange
        Compass = @{ Red = 'cc241d'; Orange = 'fe8019'; Stops = '30:6a1d18', '56:9d2a1a', '78:c2411a', '92:d65d0e', '107:e87414', '119:fe8019' }
        Accent = 'fe8019'
        # the chat parchment is lifted onto this cream (Gruvbox light bg1, to match the Gruvbox light theme); the fill is the sprite's tan between these brightnesses
        ChatFill = @{ Cream = 'ebdbb2'; FillMin = 100; FillMax = 190; Cutoff = 100 }
        Overlay = '9c1d2021'
    }
}
