# Art tools (read-only)

`iotex.py` pulls UI textures out of the game's IoStore paks (utoc/ucas, Oodle-compressed, not encrypted) and saves
PNG previews. Used 2026-11-10 to find menu art for v0.7 (results: TASKS.md §7, page
https://claude.ai/artifact/6mLfAbAs7k8NeCqvpU8yML).

```bash
# one-off: build the open-source Oodle decompressor (github.com/powzix/ooz) as tools/art/ooz/libooz.so
#   (needs a Linux stdafx.h shim and the Windows test main() cut off - see the 2026-11-10 session)
python3 -I tools/art/iotex.py OUTDIR UI/Library/Textures/Content/Arcade/ ...   # patterns match the asset path
```
Previews are approximate: some DXT5 textures with alpha (portraits, badges) and the planet masks don't decode
cleanly. The game draws them fine. Path list of every asset: `utocdir.py` (swgr-vehiclelooks/tools).
