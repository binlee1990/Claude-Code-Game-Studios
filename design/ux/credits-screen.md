# Credits Screen UX Spec

> Last updated: 2026-04-27
> Status: ACTIVE
> Sprint: 005 / REL-001

## Purpose

The Credits screen makes all third-party attribution obligations visible inside the running game before any public-facing build. It is accessible from the main menu and does not depend on campaign completion.

## Entry Points

| Entry | Behavior |
|---|---|
| Main menu `CreditsButton` | Opens the Credits overlay immediately |
| Credits overlay close button | Hides the overlay and returns focus to the main menu |

Future entry points may include Settings and chapter-completion flow, but the main-menu route is the Sprint-005 compliance gate.

## Layout

The screen is a modal overlay above the main menu:

1. Title: localized `credits.title`
2. Studio / development team
3. Music section
4. Fonts section
5. Special Thanks
6. Close button

Text uses the project UI theme, smart wrapping, and a scroll container so required credit strings remain readable on smaller viewports.

## Required Attribution Text

The music credit must render verbatim:

```text
Music by Kevin MacLeod (incompetech.com)
Licensed under Creative Commons: By Attribution 3.0
http://creativecommons.org/licenses/by/3.0/
```

Font notices must include:

- ZCOOL XiaoWei - SIL Open Font License 1.1
- Noto Serif SC - SIL Open Font License 1.1

## Localization

Static section labels use `SRPGLocalization` keys:

- `credits.title`
- `credits.close`
- `credits.studio`
- `credits.music_heading`
- `credits.font_heading`
- `credits.required_music`
- `credits.fonts`
- `credits.special_thanks`

The Kevin MacLeod legal credit string is identical in both supported locales.

## Verification

- `tests/integration/ui/main_menu_localization_credits_test.gd` opens the route from `CreditsButton`.
- The test verifies the overlay becomes visible.
- The test verifies the required Kevin MacLeod CC-BY 3.0 text and OFL references are present.
