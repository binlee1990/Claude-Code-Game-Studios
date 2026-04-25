# Credits

> Last updated: 2026-04-26
> Status: ACTIVE — required for any public-facing build (法律义务)

This file enumerates all third-party assets bundled with the game and the attribution strings that **must** appear in the in-game Credits screen and any distributed marketing/store materials. License obligations attach at the moment of distribution; do not ship a public build until every CC-BY/OFL line below is rendered visibly to end users.

---

## Music

### Kevin MacLeod (incompetech.com) — CC-BY 3.0

| Track | Used For | File |
|-------|----------|------|
| Cambodean Odyssey | Main menu BGM | `assets/audio/bgm/main_menu_bgm.ogg` |
| Rite of Passage | Battle BGM | `assets/audio/bgm/battle_bgm.ogg` |

**Required Credit String** (display verbatim in-game):

```
Music by Kevin MacLeod (incompetech.com)
Licensed under Creative Commons: By Attribution 3.0
http://creativecommons.org/licenses/by/3.0/
```

License source: https://creativecommons.org/licenses/by/3.0/legalcode
Asset audit trail: `assets/audio/bgm/LICENSE.md`

---

## Fonts

### ZCOOL XiaoWei — SIL Open Font License 1.1

| Use | File |
|-----|------|
| Title font (HD-2D 武侠中国风标题) | `assets/fonts/zcool_xiaowei.ttf` |

Designer: ZCOOL Studio. Distribution channel: Google Fonts.

OFL 1.1 does not require attribution in the running product, but the font may not be sold standalone. Asset audit trail: `assets/fonts/LICENSE.md`.

### Noto Serif SC — SIL Open Font License 1.1

| Use | File |
|-----|------|
| Body font (中文正文) | `assets/fonts/noto_serif_sc.otf` |

Designer: Adobe / Google. SubsetOTF Regular weight.

Same OFL 1.1 obligations as above.

---

## Display Format Recommendation

The in-game Credits screen (`design/ux/credits-screen.md` — TODO Sprint-003) should organize sections in the following order to maintain hierarchy:

1. Studio / development team
2. Music — Kevin MacLeod credit string verbatim
3. Fonts — list of fonts and licenses (compact)
4. Special Thanks / Playtesters
5. License References — link to project repository's `LICENSES/` directory if applicable

Minimum legibility: render in BODY_FONT at ≥ 14pt. Provide gamepad-friendly scrolling. Locked at game completion screen plus accessible from main menu.

---

## Changelog

| Date | Change |
|------|--------|
| 2026-04-26 | Initial creation. Sprint-002 added 2 BGM tracks (CC-BY 3.0) + 2 fonts (OFL 1.1). |
