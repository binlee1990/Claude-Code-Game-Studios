# BGM License Notice

> Version: v1.0 | Date: 2026-04-26 | Owner: orchestrator (post-audio-director rework)
> Sprint: sprint-002 Lane B (AUDIO-P0-07 / AUDIO-P0-08)
> Status: **P0 minimum coverage pack complete — 2 tracks downloaded and verified**

## Attribution Requirement

Both BGM assets in this directory are licensed under **Creative Commons Attribution 3.0 (CC-BY 3.0)**. Use is commercial-permitted, **but attribution is mandatory**. The following credit string MUST appear in the game's Credits screen and any distributed marketing materials before public release:

```
Music by Kevin MacLeod (incompetech.com)
Licensed under Creative Commons: By Attribution 3.0
http://creativecommons.org/licenses/by/3.0/
```

TODO (Sprint-003 or earlier): create `design/ux/credits.md` and embed this credit string before any public-facing build.

## Tracks

| File | Original Title | Composer | License | Source URL |
|------|---------------|----------|---------|-----------|
| `main_menu_bgm.ogg` | Cambodean Odyssey (sic. "Odessy") | Kevin MacLeod | CC-BY 3.0 | https://archive.org/download/Global_Sampler-9620/Kevin_MacLeod_-_Cambodean_Odessy.ogg |
| `battle_bgm.ogg` | Rite of Passage | Kevin MacLeod | CC-BY 3.0 | https://archive.org/download/Global_Sampler-9620/Kevin_MacLeod_-_Rite_of_Passage.ogg |

## Verification (2026-04-26)

Both files were:
1. HTTP HEAD-verified by curl: 200 OK, Content-Type `application/ogg`
2. Downloaded successfully via curl
3. `file` command confirmed `Ogg data, Vorbis audio, stereo, 44100 Hz`
4. Magic bytes confirmed (`4f67 6753` = "OggS")

Sizes:
- `main_menu_bgm.ogg`: 744,182 bytes (~727 KB)
- `battle_bgm.ogg`: 3,416,280 bytes (~3.3 MB)

Total disk impact: ~4 MB.

## Selection Rationale

- **main_menu_bgm**: Cambodean Odyssey selected for its tranquil Southeast Asian plucked-string + flute timbre, matching the "克制留白 × 精准点睛" tone in `design/art/redesign-direction-2026-04-26.md`. Loop-friendly at ~2:10 length.
- **battle_bgm**: Rite of Passage selected for its ceremonial percussion + tension-building strings, suitable for turn-based combat without becoming distracting during prolonged sessions. ~3:35 length.

## Origin Audit Trail

The original asset shopping list (production/assets/free-asset-shopping-list.md § 6) contained 4 candidates from the `Kevin-MacLeod_Wonders_2014_FullAlbum` archive.org item, all marked `[VERIFIED-SEARCH]` by the audio-director agent. On HTTP HEAD verification by curl:

| # | URL | Result |
|---|-----|--------|
| 6-A Cherry Blossom | Wonders_2014/02 | **404** |
| 6-B Cambodean Odyssey | Global_Sampler-9620 | ✅ 200 (used here) |
| 6-C Exotic Battle | Wonders_2014/10 | **404** |
| 6-D Dragon and Toast | Wonders_2014/05 | **404** |

The Wonders_2014 archive.org item turned out to have an empty file directory (verified via curl listing). The `Global_Sampler-9620` directory was crawled, exposing 9 real `Kevin_MacLeod_-_*.{mp3,ogg}` files. Final selection was made from this verified manifest.

The shopping list § 6 has been amended in a follow-up agent pass to mark dead URLs `[VERIFIED-DEAD-404]` and add the live alternates.

## Out of Scope (Sprint-003+)

- Boss-specific BGM (heavier orchestration)
- Camp/management screen BGM
- Victory/defeat stings and SFX
- Voice acting

## License Reference

- CC-BY 3.0 full text: https://creativecommons.org/licenses/by/3.0/legalcode
- incompetech site: https://incompetech.com/music/royalty-free/
