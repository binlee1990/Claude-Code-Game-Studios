# Release Manifest — 2026-04-25

## Channel

- Local Windows release package
- Export preset: `Windows Desktop`
- Artifact: `builds/windows/SRPG.exe`
- Artifact size: `105,033,016` bytes
- SHA-256: `42EA5D6E6903C04AC1D2A72CC6BA6EC768B8DF4823923BA67A1DA37B8B9CE9A4`
- Package script: `tools/package_windows_release.ps1`

## Included Production Systems

- Chapter 1 three-battle campaign path: tutorial pass, crossroads ambush, watchtower gate finale
- Post-battle settlement rewards with EXP, gold, materials, and equipment
- Default recommended camp growth before campaign advance
- Independent campaign readiness screen for rewards, camp, party, and equipment review
- Tactical terrain, height, weapon triangle, elemental reactions, AI target/position selection, and Boss phases
- SaveManager round-trip for battle, campaign, camp report, roster, equipment, inventory, UI, and camera state
- Lightweight generated audio cues and runtime localization catalog

## Verification Contract

Run from repo root:

```powershell
.\tools\package_windows_release.ps1
```

The script performs:

- Godot check-only
- full automated test runner
- Windows release export
- packaged scripted playthrough via `--srpg-playthrough-smoke`
- SHA-256 artifact hash
- process launch smoke

## Known Release Gaps

- Human subjective UI/UX sign-off is still required for final commercial release readiness.
- Art, music, voice, and full localization files are not final assets; current audio/localization are lightweight production scaffolds.
- Chapter 2 and broader campaign content remain future production scope.
