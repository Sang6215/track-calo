# Track Calo logo

The approved identity uses a blue background, yellow leaf and calorie-tracking
ring, and white rice bowl. Artwork was created using the built-in image_gen tool.
`track-calo-icon.png` is the original generated production artwork.

The previous green artwork remains in `assets/icon-1024.png` for reference.

Android launcher exports are generated with:

```powershell
python tools/generate_launcher_icons.py
```

Adaptive foreground exports include extra safety padding for circular and
squircle masks. The same source artwork appears in the app's BuaLogo widget.

## Final generation prompt

Edit the generated Track Calo logo shown in the previous image. Retain its attractive core identity: a rice bowl beneath a leaf, encircled by an open calorie tracking ring with a round progress dot. Change the main palette to BLUE, YELLOW and WHITE, as explicitly requested by the user. Solid rich royal blue #1554C0 edge-to-edge square background, bright golden yellow #FFD447 leaf and tracking ring and dot, clean white #FFFFFF bowl and rice. Refine to completely flat vector-like colors, sharp smooth edges, no shading, no grain or textures, no gradients, no shadows. Improve Android adaptive icon safe-area: the entire foreground symbol INCLUDING outer ring must fit centered within the middle 60% of the square image, leaving 20% plain blue margin on each side. All the core shapes should remain clear and bold at small sizes. Deliver a single full square production-ready app icon, no rounded outer corners, no text, no mockup, no collage, no extra elements. A polished friendly Vietnamese nutrition tracker brand.
