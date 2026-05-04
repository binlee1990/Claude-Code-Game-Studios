# Sprint 11 UI Engine Implementation Guide

> **Audience**: godot-gdscript-specialist, ui-programmer
> **Status**: Authoritative implementation reference
> **Created**: 2026-05-05
> **Engine**: Godot 4.6.2 (Forward+, D3D12, Jolt)
> **Source docs**: design/ux/visual-design-sprint-11.md, design/ux/*.md, ADR-0011, project.godot autoload list

---

## 1. Node Architecture: Shared Shell

### 1.1 Recommended hierarchy

```
Main (Node, main.tscn)
  GameWorld (Node)                          # 3D/2D gameplay if any
  UILayer (CanvasLayer, layer 0)            # Root UI canvas
    Shell (MarginContainer)                 # Full-window container
      theme = theme.tres                    # Theme inherits to all children
      TOP_STRIP (PanelContainer, 64px)      # Fixed top, full width minus nav margins
        ResourceScrollBar (HBoxContainer)   # 5 resource compact rows
        LevelRealmBadge (HBoxContainer)     # Lv.X + realm icon + name
        ZoneContextLabel (Label)            # Current zone name
        SettingsButton (Button)             # Gear icon, right-aligned
      HBoxContainer                         # Main horizontal split
        LEFT_NAV (PanelContainer, 192px)    # Fixed left, expanded
          NavTabList (VBoxContainer)        # 5 tab buttons
        CENTER_CONTENT (Control)            # Fills remaining space
          ScreenContainer (Control)         # Single child at a time (show/hide)
            [Screen scenes added here]      # cultivation, combat, resources, save, offline
        RIGHT_PANEL (PanelContainer, 320px) # Fixed right
          BattleLogArea (VBoxContainer)     # P-FBK-03 + warning chips
    ToastLayer (CanvasLayer, layer 1)       # Toast stack (P-FBK-01), Z above UILayer
    ModalOverlay (CanvasLayer, layer 2)     # Modal semi-transparent blocker + modal root
```

### 1.2 CanvasLayer usage

- **Layer 0 (UILayer)**: Shell and all screen content. One CanvasLayer for the entire shell.
- **Layer 1 (ToastLayer)**: P-FBK-01 Toast Stack. Renders above shell, below modals.
- **Layer 2 (ModalOverlay)**: P-NAV-03 modals + semi-transparent input blocker.

Reason: CanvasLayer always renders above the 3D/2D world and respects layer ordering. The existing hud.tscn already uses CanvasLayer -- this guide extends the pattern to a multi-layer UI stack.

### 1.3 Screen switching: show/hide, not add_child/remove_child

All 5 screens are children of `ScreenContainer`. Only one is visible at a time:

```gdscript
func open_screen(screen_id: String) -> void:
    # Hide current
    if current_screen_node:
        current_screen_node.hide()
        current_screen_node.process_mode = PROCESS_MODE_DISABLED
    # Show target
    var target := _ensure_screen_loaded(screen_id)
    target.show()
    target.process_mode = PROCESS_MODE_INHERIT
    current_screen_node = target
```

**Why show/hide over add/remove**: Instant switch (no scene instantiation delay), preserves internal state (scroll position, expanded rows, tab selection), aligns with ADR-0011 stack model. Use `PROCESS_MODE_DISABLED` on hidden screens to prevent `_process` / `_physics_process` from running on off-screen content.

**Screen scene loading**: Defer-load via `ResourceLoader.load_threaded_request()` on first access, cache the `PackedScene` in a dict. Only instantiate once, keep in tree.

### 1.4 LEFT NAV collapse/expand

The LEFT NAV has two states: expanded (192px) and collapsed (48px). Implement via `Tween` on `custom_minimum_size.x`:

```gdscript
func _toggle_nav() -> void:
    var target_width: int = 48 if _nav_expanded else 192
    tween.tween_property(left_nav, "custom_minimum_size:x", target_width, 0.15)
    _nav_expanded = not _nav_expanded
```

Collapsed state hides tab text labels, keeps icons centered. Use `visible = _nav_expanded` on Label children, not scale tricks. Adjust CENTER_CONTENT and TOP_STRIP margins to match.

### 1.5 Resolution scaling

Godot's `Window` stretch mode should be `canvas_items` with `expand` aspect. This ensures the 1080p baseline layout scales down to 720p and up to 4K proportionally. Do NOT use `viewport` stretch for a UI-only project -- it adds unnecessary complexity.

Set in Project Settings:
- `display/window/stretch/mode = canvas_items`
- `display/window/stretch/aspect = expand`
- Base window size: 1920x1080

---

## 2. Per-Screen Widget Mapping

### 2.1 Cultivation Screen

| UX Component | Godot Node | Notes |
|---|---|---|
| Background fill (main_base.png) | `TextureRect` | `stretch_mode = STRETCH_SCALE`, `expand_mode = IGNORE_SIZE` |
| Background dim | `ColorRect` atop TextureRect | `color = Color(0, 0, 0, 0.3)` |
| Hero Zone (portrait + idle) | `Control` (480x680) containing `TextureRect` + `AnimatedSprite2D` | AnimatedSprite2D reads `pipeline-meta.json` for fps (8fps default) |
| Level + Realm Label | `Label` | Bold, 24px, `text_primary` token |
| Resource Production Row (x4) | Custom `Control` (P-DAT-01-EXP) | **New component**. See 2.1a below. |
| Stance switch button | `Button` | Opens P-NAV-03 modal |
| Stance Selection Modal | `PopupPanel` | 4 `TextureButton`s in grid; 2 enabled + 2 disabled (locked) |
| Manual Cultivate button | `Button` + `ProgressBar` | Custom draw for breathing glow on new save (See 6.3) |
| Condense params (cost/rate) | `Label` x2 | Visible only when stance = condense |
| Lingqi shortage chip | `PanelContainer` + `Label` | `bottleneck_red` token, visible when `last_shortage = true` |
| Inspection Zone slider | `HSlider` | 5 snap points: `snap(5, [10, 30, 60, 300, 1800])` |
| Stance dropdown | `OptionButton` | 2 items: meditate, condense |
| Simulation result | `RichTextLabel` | `bbcode_enabled = true`, `autowrap_mode = AUTOWRAP_WORD_SMART` |
| Apply stance button | `Button` | Calls `CultivationSystem.set_stance(simulated)` |
| Ambient Hint (locked stances) | `TextureRect` x2 + `Tooltip` | Hover shows "Sprint 12+ unlock" |

#### 2.1a: Resource Production Row (P-DAT-01-EXP)

This is the most complex new widget. Recommendation: build as a custom `Control` (not a pre-built container) with manual `_draw()` for the expand/collapse animation:

```gdscript
class_name ResourceProductionRow extends Control
# Collapsed state: icon (24x24) + name (20px) + "+3.2/s" (24px) + expand arrow
# Expanded state: above + 5-8 breakdown rows
# Expand via tween on the Control's custom_minimum_size.y + content fade-in
```

Use `FoldableContainer` (4.5+) for the expand area -- but note: `FoldableContainer` is for accordion style. If you need custom expand behavior with staggered detail rows, use a `VBoxContainer` whose children fade in one by one via Tween.

**Expand animation**: Tween the child container's `modulate.a` (content fade) and the row's `custom_minimum_size.y` (height). 200ms ease-out per spec.

### 2.2 Combat Screen

| UX Component | Godot Node | Notes |
|---|---|---|
| Zone Selector tabs (x3) | `HBoxContainer` of `Button`s (mutually exclusive) | NOT `TabContainer` -- TabContainer has built-in tabs that don't match the design spec's visual style (single-side cut corners, gold top stripe for active) |
| Locked zone tooltip | P-INP-01 `PopupPanel` | Triggered by hover/focus on locked tab button |
| Combat status dot | `ColorRect` (8x8) | Square, no rounded corners. Color driven by combat state. |
| Zone background | `TextureRect` | Dynamically loaded by `zone_id`. `expand_mode = IGNORE_SIZE`. Dim 30% via ColorRect overlay. |
| Enemy portrait | `TextureRect` | Dynamically loaded by `enemy_id` |
| Enemy idle animation | `AnimatedSprite2D` | Fps from `pipeline-meta.json` |
| Enemy health bar | `ProgressBar` + `Label` overlay | Coalesced refresh (see 5.3). NO tween -- direct value jump. |
| Enemy name + level | `Label` | 24px Bold |
| Seeking indicator | `AnimatedSprite2D` (rotating ink dot) + `Label` ("Searching...") | 60fps rotation via `rotation += delta * speed` in `_process`; disable when enemy found |
| Player HP/ATK/Crit bars | `ProgressBar` + `Label` x3 | Coalesced refresh |
| Player sprite | `AnimatedSprite2D` | Switch `sprite_frames` based on combat state (idle/attack/hurt/death) |
| Encounter counter + win rate | `Label` x2 | Coalesced refresh |
| Win/Loss streak chip | P-FBK-02 `PanelContainer` + `Label` | `burst_gold` for streak, `bottleneck_red` for loss streak |
| Pause/Resume toggle | `Button` | Text swap: "Pause"/"Resume" |
| Cooldown timer | `Label` + `ProgressBar` | Only visible during post-defeat cooldown |
| Zone threat info | `Label` | 18px `text_secondary` |
| Victory overlay | `ColorRect` (`victory_burst_gold` texture, modulate.a tweened 0->0.4) | Fade in over 1s then fade out |
| Failure overlay | `ColorRect` (`failure_grey` texture, modulate.a tweened 0->0.6) | Fade in 300ms |
| Zone transition wipe | `AnimatedSprite2D` (4-frame sheet, 30ms/frame, 120ms total) | Plays forward then self-hides |

#### 2.2a: Zone tabs -- custom Button group, not TabContainer

Godot's `TabContainer` has fixed visual styling that conflicts with the spec (6px corner cuts, `burst_gold` top stripe, `panel_bg_elevated` background for active). Use 3 individual `Button`s in an `HBoxContainer` with mutual exclusion:

```gdscript
var _zone_buttons: Array[Button] = []
func _on_zone_button_pressed(zone_index: int) -> void:
    for i in _zone_buttons.size():
        _zone_buttons[i].button_pressed = (i == zone_index)
        _apply_zone_button_style(_zone_buttons[i], i == zone_index)
```

Use `theme_override_styles/normal` to set the active button's StyleBox to `panel_bg_elevated` + `burst_gold` top border.

### 2.3 Resources/Backpack Screen

| UX Component | Godot Node | Notes |
|---|---|---|
| Tab bar | `HBoxContainer` of 3 `Button`s | "Resources" / "Backpack" / "Index" (Index locked) |
| Resource row (x5) | `ResourceProductionRow` (same as cultivation) | **Different expand content**: here it's transaction history, not breakdown |
| Fill bar | `ColorRect` inside row | 4px height. Green normally, `bottleneck_red` at >= 85%. No rounded corners. |
| Cap warning "!" | `Label` | 18px `bottleneck_red` |
| Inventory grid | `GridContainer` inside `ScrollContainer` | 4 columns @ 1080p. See 5.1 for virtualization. |
| Item card (P-DAT-04) | `PanelContainer` (96x128) | Contains `TextureRect` (48x48 icon), `Label` (name, 14px), rarity frame (9-slice `TextureRect`), rarity text badge (12px), quantity label (14px) |
| Item card tooltip | P-INP-01 `PopupPanel` | 320x420 detail card |
| Empty inventory placeholder | `TextureRect` + `Label` | "No items -- go to combat to get loot" |
| Encyclopedia placeholder | `TextureRect` (lock icon) + `Label` | "Loot Filter -- Sprint 12+ available" |

#### 2.3a: Rarity frame rendering

8 rarity frames are 9-slice textures. Use `NinePatchRect` for each item card's border:

```gdscript
var frame := NinePatchRect.new()
frame.texture = _rarity_frame_cache[item.rarity]
frame.patch_margin_left = 8
frame.patch_margin_top = 8
frame.patch_margin_right = 8
frame.patch_margin_bottom = 8
```

The rarity text badge ("common"/"uncommon"/...) is a `Label` positioned at the top-right corner of the card via `set_anchors_and_offsets_preset(PRESET_TOP_RIGHT)`.

### 2.4 Save Screen

| UX Component | Godot Node | Notes |
|---|---|---|
| Auto-save indicator | `HBoxContainer` (centered) | `ColorRect` (8x8 status dot) + `Label` (timestamp text) |
| Save overdue warning | `Label` | `failure_red` token, visible when > 5min since last save |
| Slot card (x3) | `PanelContainer` (full width, 260px tall) | Contains: portrait `TextureRect` (96x96), level+realm `Label` + `TextureRect` (realm icon), play time `Label`, save timestamp `Label`, version `Label` |
| Current slot highlight | 2px `burst_gold` 4-sided border | Via `theme_override_styles/panel` StyleBoxFlat |
| Selected slot highlight | 4px `burst_gold` left stripe + `panel_bg_elevated` | Separate from current slot border -- both can coexist |
| Corrupted save chip | P-FBK-02 chip | `failure_red` border + "!" icon + "Save corrupted" text |
| Migration needed chip | P-FBK-02 chip | `burst_gold` color |
| Empty slot placeholder | `TextureRect` (empty circle icon) + `Label` ("No save created yet") | Replaces portrait area |
| Action bar buttons (x4) | `Button` | "Save", "Load", "Delete", "Return" |
| Confirm Overwrite modal | P-NAV-03 `PopupPanel` | Title + description + "Confirm Overwrite" / "Cancel" buttons |
| Confirm Delete modal | P-INP-02 `PopupPanel` | Red title + checklist + 2s countdown `ProgressBar` + "I understand" `CheckBox` + "Delete" button |
| Saving/Loading overlay | `ColorRect` (black 30% alpha) + `AnimatedSprite2D` (spinner) + `Label` | Blocks all input |

### 2.5 Offline Settlement Screen

| UX Component | Godot Node | Notes |
|---|---|---|
| Paper background | `NinePatchRect` | offline_paper.png with 48/48/48/64 margins. Stretches to fill content height. |
| Duration hero label | `Label` | 32px Bold. Dark color (approx #2A2A30) on warm_paper background. |
| Defer review button | `Button` | Top-right, 18px `text_secondary` |
| Total gross summary bar | `HBoxContainer` | 5 resource icons + BigNumber values. Horizontal arrangement. |
| Resource detail card (xN) | `PanelContainer` | Gross / Claimed / Lost 3-column layout. Lost column in `bottleneck_red` when > 0. Source breakdown sub-rows. |
| Lost reason tooltip | P-INP-01 `PopupPanel` | "Warehouse full (12/200)" |
| Loot gallery section | `VBoxContainer` | Title "Offline Loot" + item card grid (same P-DAT-04 component as resources screen) |
| Empty loot state | `Label` | Italic "No items obtained offline this session" |
| Continue cultivation button | `Button` | 24px Bold, `burst_gold` border (no fill). Fixed at bottom, outside scroll. |
| Warning banner (all full) | `PanelContainer` | `bottleneck_red` chip + text, only when `all_lost == all_gross` |

#### 2.5a: Count-up animation implementation

Do NOT use `_process` for count-up. Use a single `Tween`:

```gdscript
# For each BigNumber target, create a proxy float and tween it:
var proxy := 0.0
tween.tween_method(_on_countup_tick.bind(label, target_value), 0.0, 1.0, 1.5)
    .set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)

func _on_countup_tick(t: float, label: Label, target: BigNumber) -> void:
    var current := BigNumber.from_float(BigNumber.to_float(target) * t)
    label.text = NumberFormatter.format(current)
```

The ease-out cubic curve (`1 - (1-t)^3`) is built into Godot's `Tween.TRANS_CUBIC` + `Tween.EASE_OUT`. Total 1.5s per spec. Multiple resource cards stagger via `tween.set_delay(card_index * 0.1)`.

Count-up must NOT block interaction -- buttons remain clickable during animation.

#### 2.5b: ScrollContainer + fixed ACTION BAR

The middle section (RESOURCE BREAKDOWN + LOOT GALLERY) lives in a `ScrollContainer`. The `NinePatchRect` (offline_paper) is inside the scroll, so it stretches with content. The ACTION BAR is OUTSIDE the ScrollContainer, anchored to bottom:

```
PanelContainer (entire screen)
  DURATION_HERO (fixed top, 180px)
  ScrollContainer (fills remaining space minus 64px)
    VBoxContainer
      NinePatchRect (paper bg, expands with content)
      RESOURCE_BREAKDOWN
      LOOT_GALLERY
  ACTION_BAR (fixed bottom, 64px)
```

---

## 3. Godot 4.6 Gotchas

### 3.1 D3D12 default (LOW risk for UI)

Godot 4.6 defaults to D3D12 on Windows. For a UI-only project, this is transparent -- Control nodes go through the same rendering pipeline. However, verify that `theme.tres` StyleBoxFlat/Texture rendering looks identical between D3D12 and Vulkan during QA. The glow rework (4.6) and AgX tonemapper changes should not affect Control-based UI.

### 3.2 Dual-focus system (HIGH risk)

Godot 4.6 separates mouse/touch focus from keyboard/gamepad focus. This means:

- A `Button` can appear "focused" for keyboard input but NOT show focus highlight for mouse users
- Focus highlight (`focus` StyleBox) respects which input type currently has focus
- Gamepad navigation may behave differently than in 4.3

**Mitigation**: Do NOT rely on the default dual-focus visual behavior for the `burst_gold` 2px focus outline. Instead, implement a custom focus system:

```gdscript
# On each interactive Control:
func _make_focusable(control: Control) -> void:
    control.focus_mode = Control.FOCUS_ALL
    control.focus_entered.connect(_on_focus.bind(control))
    control.focus_exited.connect(_on_unfocus.bind(control))

func _on_focus(control: Control) -> void:
    # Apply burst_gold 2px outline via custom StyleBox
    control.add_theme_stylebox_override("focus", _focus_stylebox)

func _on_unfocus(control: Control) -> void:
    control.remove_theme_stylebox_override("focus")
```

The standard `focus` StyleBox override works regardless of dual-focus mode because it responds to `focus_entered`/`focus_exited` signals, not input-type detection.

### 3.3 CanvasLayer Z-order

CanvasLayer `layer` property controls rendering order. Layer 0 is the default. Higher numbers render on top. Godot 4.6 did not change CanvasLayer behavior, but the dual-focus system means focus can traverse across CanvasLayer boundaries:

- A Button on layer 0 and a Button on layer 1 can both be focusable simultaneously
- Modal overlay (layer 2) must block focus to lower layers. Use `Control.accept_event()` in the modal blocker's `_gui_input()` to prevent event propagation.

### 3.4 Theme propagation through nested Controls

Godot 4.6 did not change theme inheritance rules. Setting `theme` on a parent `Control` propagates to all children. Per-screen overrides use `theme_override_*` properties. However, `StyleBox` overrides on deeply nested controls may not inherit correctly if a child explicitly sets its own `theme_override_styles`. Test each nested widget.

### 3.5 Recursive Control disable (4.5+)

Godot 4.5+ supports recursive `process_mode` and `mouse_filter` propagation. Use this:

```gdscript
# Disable entire hidden screen:
screen_node.process_mode = PROCESS_MODE_DISABLED  # Stops _process, _physics_process, _input
```

This is preferred over manually iterating children. However, `PROCESS_MODE_DISABLED` stops `_ready()` calls -- ensure screens are initialized before hiding.

### 3.6 Accessibility / AccessKit (4.5+)

Godot 4.5+ integrates AccessKit for screen reader support. Control nodes automatically expose metadata to NVDA/Narrator. For Sprint 11, ensure:

- All `Label`s with meaningful text have descriptive names
- All `Button`s have clear text (not just icons)
- Interactive elements use proper `focus_mode`
- Do NOT override default accessibility metadata unless needed

This meets the accessibility-requirements.md Standard tier without extra implementation.

---

## 4. Theme Application

### 4.1 Single theme.tres, inherited by all

Set `theme = ExtResource("res://assets/ui/theme.tres")` on the `Shell` (MarginContainer root). All children inherit automatically. Do NOT set `theme` on individual screens -- they inherit from Shell.

The existing `theme.tres` covers:
- `panel_bg_primary` / `panel_bg_secondary` / `panel_bg_elevated` -- Panel and PopupPanel StyleBoxes
- `text_primary` / `text_secondary` -- Label and Button font colors
- `ink_stroke` -- Separator and border color
- Button normal state StyleBox (from button_states.png, region 0,0,96,96)

### 4.2 Missing theme entries to add (ui-scene-foundation S11-001)

Per the asset manifest, `theme.tres` must be extended with:

1. **Button hover/pressed/disabled states**: button_states.png is a 4-region sheet (96x96 each). Add StyleBoxTexture entries for regions (96,0,96,96), (192,0,96,96), (288,0,96,96).
2. **Focus StyleBox**: A 2px `burst_gold` (#F5C842) border StyleBoxFlat for focus indication.
3. **Rarity frame 9-slice margins**: 8 rarity frames need `patch_margin_*` = 8 for proper 9-slice rendering.
4. **Tab-specific StyleBox**: Active tab = `panel_bg_elevated` + top 2px `burst_gold`. Inactive tab = `panel_bg_primary`.
5. **Semantic color entries**: `burst_gold`, `bottleneck_red`, `failure_red`, `threat_purple`, `subplay_orange`, `victory_burst_gold` -- these are palette entries, not StyleBoxes, used as `theme_override_colors/font_color` on individual Labels.

### 4.3 Per-screen overrides

Use `theme_override_*` on specific nodes, not full theme replacement:

```gdscript
# Example: warm_paper text on offline settlement screen
duration_label.add_theme_color_override("font_color", Color(0.165, 0.165, 0.188))  # #2A2A30
```

Never create per-screen `.tres` theme files. This duplicates tokens and makes global palette changes error-prone. All overrides are code-driven or per-node `theme_override_*` in the .tscn.

### 4.4 Chinese font

The spec requires a Chinese font (Noto Sans SC or equivalent) at `assets/ui/fonts/`. Register it in `theme.tres`:

```gdscript
# In theme.tres:
[resource]
default_font = ExtResource("font_noto_sans_sc")
default_font_size = 16
```

Without this, Godot's default font produces illegible Chinese characters at sizes below 14px.

---

## 5. Performance: Virtualized Lists

### 5.1 Inventory grid virtualization (P-DAT-02)

Godot has no built-in UI virtualization. Implement a custom pattern:

```gdscript
class_name VirtualItemGrid extends ScrollContainer

const CARD_WIDTH := 96
const CARD_HEIGHT := 128
const CARD_GAP := 12
const COLUMNS := 4
const OVERSCAN_ROWS := 4

var _all_items: Array[ItemData] = []
var _active_cards: Array[ItemCard] = []
var _card_pool: Array[ItemCard] = []  # Object pool for recycling
var _first_visible_row := 0

func _ready() -> void:
    scroll_vertical = 0
    # Pre-instantiate pool: (visible rows + overscan) * columns
    var visible_rows := ceil(get_viewport().size.y / (CARD_HEIGHT + CARD_GAP)) as int
    var pool_size := (visible_rows + OVERSCAN_ROWS) * COLUMNS
    for i in pool_size:
        var card := _create_card()
        card.hide()
        _card_pool.append(card)
        add_child(card)

func set_items(items: Array[ItemData]) -> void:
    _all_items = items
    var total_rows := ceil(items.size() / float(COLUMNS)) as int
    var total_height := total_rows * (CARD_HEIGHT + CARD_GAP)
    # Update content height (use a dummy Control as scroll child)
    _content_control.custom_minimum_size.y = total_height
    _refresh_visible_cards()

func _refresh_visible_cards() -> void:
    var scroll_y := scroll_vertical
    var view_height := get_viewport().size.y
    var first_row := max(0, floor(scroll_y / (CARD_HEIGHT + CARD_GAP)) as int)
    var last_row := min(ceil((scroll_y + view_height) / (CARD_HEIGHT + CARD_GAP)) as int,
                        ceil(_all_items.size() / float(COLUMNS)) as int)
    # ... recycle cards outside range, assign items to visible cards
```

Key points:
- Object pool: pre-instantiate enough cards to fill visible area + overscan. Never `instantiate()` during scroll.
- Recycle: when a card scrolls off-screen, repurpose it for a newly visible position.
- Overscan: 4 rows of extra cards above and below the viewport so rapid scrolling doesn't show blanks.
- Column count: recalculate on window resize by reading viewport width, clamped to 3-6 per spec's responsive breakpoints.

### 5.2 Battle log scroll (P-FBK-03)

The battle log has simpler requirements: 200 lines max, 8 visible. Use a `RichTextLabel` with manual line limit:

```gdscript
const MAX_LINES := 200
var _log_lines: Array[Dictionary] = []  # [{text: "...", color: Color, timestamp: float}]

func append_log(text: String, color: Color) -> void:
    _log_lines.append({"text": text, "color": color, "timestamp": Time.get_ticks_msec()})
    if _log_lines.size() > MAX_LINES:
        _log_lines.pop_front()
    _rebuild_bbcode()

func _rebuild_bbcode() -> void:
    var bbcode := ""
    for line in _log_lines:
        var color_hex := "#%02x%02x%02x" % [line.color.r8, line.color.g8, line.color.b8]
        bbcode += "[color=%s]%s[/color]\n" % [color_hex, line.text]
    battle_log.text = bbcode
    if auto_scroll:
        battle_log.scroll_to_line(battle_log.get_line_count() - 1)
```

For the "brief/detailed" toggle, store two versions of each log line (brief and detailed text) and rebuild with the selected format. The 200-line limit is enforced by `pop_front()`. RichTextLabel handles scrolling natively.

Performance note: Rebuilding 200 lines of BBCode per new log entry is cheap (RichTextLabel parses BBCode efficiently). Do NOT use a VBoxContainer of individual Label nodes -- this creates 200+ nodes and defeats the purpose.

### 5.3 Coalesced HUD refresh

Per ADR-0011 and hud-system GDD, high-frequency resource updates must be coalesced:

```gdscript
var _dirty_resources: Array[String] = []
var _refresh_timer: float = 0.0
const REFRESH_INTERVAL := 0.1  # 10Hz

func _process(delta: float) -> void:
    _refresh_timer += delta
    if _refresh_timer >= REFRESH_INTERVAL and not _dirty_resources.is_empty():
        _apply_refresh()
        _refresh_timer = 0.0

func _on_resource_changed(resource_id: String) -> void:
    if resource_id not in _dirty_resources:
        _dirty_resources.append(resource_id)
```

10Hz is sufficient for readable number updates and keeps frame budget well under 16.6ms.

---

## 6. Input Routing

### 6.1 Keyboard + gamepad across nested Controls

Godot's `gui_input` system handles event propagation automatically through the focus system. Key rules for this project:

1. **Set `focus_mode` explicitly**: All interactive Controls must have `focus_mode = Control.FOCUS_ALL`. Non-interactive informational Controls (read-only Labels, TextureRects) should be `FOCUS_NONE`.

2. **Tab order**: Set via `focus_neighbor_left/right/top/bottom` on each focusable Control. The order is specified in each UX spec's "Tab Order" section. Example for Combat Screen:

```gdscript
zone_tab_1.focus_neighbor_right = zone_tab_2.get_path()
zone_tab_2.focus_neighbor_left = zone_tab_1.get_path()
zone_tab_2.focus_neighbor_right = zone_tab_3.get_path()
# ... etc
```

Or use `focus_next` / `focus_previous` for simple linear order.

3. **Modal input blocking**: When a PopupPanel modal is open, input to the background must be blocked. Use `PopupPanel`'s built-in modal behavior -- it automatically sets `exclusive` and blocks input to lower nodes. For the P-INP-02 confirm-critical modal, also disable external click-to-close:

```gdscript
popup.popup_exclusive = true
# P-INP-02: disable external close
popup.popup_window = false  # Can't close by clicking outside
```

4. **Escape key**: Per UX specs, ESC on screens closes the topmost open modal. If no modal is open, ESC opens the Settings modal. Implement in the Shell or UIManager:

```gdscript
func _unhandled_input(event: InputEvent) -> void:
    if event.is_action_pressed("ui_cancel"):
        if UIManager.has_open_modal():
            UIManager.close_modal()
        else:
            UIManager.open_modal("settings")
```

5. **Gamepad partial support**: Gamepad uses `ui_accept` (A button), `ui_cancel` (B button), `ui_left/right/up/down` (D-Pad), `ui_focus_next/prev` (LB/RB for screen switching). The existing Godot input map already has these actions defined. Add custom actions for gamepad-specific shortcuts:

```gdscript
# In Input Map:
# ui_left_nav_toggle    -> F key, Gamepad RT
# ui_screen_1..5        -> 1..5 keys
# ui_toggle_battle_log  -> Y key (gamepad)
# ui_confirm_critical   -> X key long press (gamepad, for delete save)
```

### 6.2 Dual-focus explicit handling

Since Godot 4.6 separates mouse and keyboard/gamepad focus, the `burst_gold` focus outline must appear regardless of input type. Override the default `focus_entered`/`focus_exited` signals (see 3.2 above) rather than relying on `focus` StyleBox which may only show for keyboard focus in dual-focus mode.

### 6.3 Custom input: manual cultivate button breathing glow

The new save breathing glow (scale 100<->105 + alpha 100<->70, 1.5s cycle) is a tween-based effect, not a shader:

```gdscript
func _start_breathing(button: Button) -> void:
    tween = create_tween().set_loops()
    tween.tween_property(button, "scale", Vector2(1.05, 1.05), 0.75).set_ease(Tween.EASE_IN_OUT)
    tween.tween_property(button, "scale", Vector2(1.0, 1.0), 0.75).set_ease(Tween.EASE_IN_OUT)

func _stop_breathing(button: Button) -> void:
    if tween:
        tween.kill()
    button.scale = Vector2.ONE
```

On first manual_cultivate click, stop the tween and remove the effect permanently.

---

## 7. ADR-0011 Alignment: UIManager Autoload

### 7.1 Current state

`UIManagerHostAutoload` is already registered as an autoload in `project.godot`. It is a Host/Service pattern following the project's existing architecture (same as `ResourceSystemHost`, `CultivationSystemHost`, etc.). The existing `hud.tscn` is bootstrapped as `HUDBootstrap` autoload, but this will be replaced by the UIManager-driven shell in Sprint 11.

### 7.2 UIManager screen registration

Per ADR-0011, UIManager must expose:

```gdscript
# UIManager (autoload singleton)
func register_screen(screen_id: String, scene_path: String, unlock_condition: Callable = _always_unlocked) -> void
func open_screen(screen_id: String) -> void
func close_screen(screen_id: String = "") -> void
func replace_screen(screen_id: String) -> void
func open_modal(screen_id: String, payload: Dictionary = {}) -> void
func close_modal() -> void
func is_screen_unlocked(screen_id: String) -> bool
```

Sprint 11 screen registrations:

```gdscript
# In UIManager._ready():
register_screen("cultivation",        "res://src/ui/screens/cultivation_screen.tscn")
register_screen("combat",             "res://src/ui/screens/combat_screen.tscn")
register_screen("resources",          "res://src/ui/screens/resources_screen.tscn")
register_screen("save",               "res://src/ui/screens/save_screen.tscn")
register_screen("offline_settlement", "res://src/ui/screens/offline_settlement_screen.tscn")
register_screen("settings",           "res://src/ui/screens/settings_modal.tscn")  # P-NAV-03
```

### 7.3 Screen lifecycle with show/hide

UIManager owns a `ScreenContainer` (the `Control` node under CENTER_CONTENT). Screen lifecycle:

1. `open_screen(id)`: If screen scene not yet loaded, `ResourceLoader.load_threaded_request()` the `.tscn`. Once loaded, `instantiate()` and `add_child()` to ScreenContainer. The previously active screen gets `hide()` + `PROCESS_MODE_DISABLED`. The new screen gets `show()` + `PROCESS_MODE_INHERIT`.

2. `close_screen(id)`: Hide the specified screen. If it was the last/only screen, show the default screen (cultivation).

3. `replace_screen(id)`: Same as `open_screen` but removes the previous screen from the tree entirely (freeing memory if it won't be returned to).

4. `open_modal(id, payload)`: Instantiate a PopupPanel. Set Z-index above all screen content. Store previous focus owner. Block input to background.

5. `close_modal()`: Hide and queue_free the modal. Restore focus to the previously focused element.

### 7.4 Screen base class

All 5 screen scenes should extend a common base class:

```gdscript
class_name BaseScreen extends Control

## Called by UIManager when this screen becomes active.
func on_activated() -> void:
    pass

## Called by UIManager when this screen becomes inactive (hidden).
func on_deactivated() -> void:
    pass

## Called by UIManager when this screen is about to be removed from the tree.
func on_removed() -> void:
    pass
```

Each screen's `on_activated()` subscribes to its EventBus events and sets up initial focus. `on_deactivated()` should unsubscribe from real-time EventBus events to prevent hidden screens from doing unnecessary layout work. Static read-only queries don't need unsubscription.

### 7.5 LEFT NAV integration

The LEFT NAV's 5 tab buttons call `UIManager.open_screen(screen_id)` on press. The currently active screen's tab gets the `panel_bg_elevated` + left 4px `burst_gold` stripe style. This is driven by `UIManager.current_screen_id` -- the LEFT NAV listens to a `screen_changed` signal from UIManager.

### 7.6 Global keyboard shortcuts

The LEFT NAV shortcut keys (1-5) and Ctrl+S/Ctrl+L should be handled by UIManager, not individual screens:

```gdscript
func _unhandled_input(event: InputEvent) -> void:
    if event.is_action_pressed("ui_screen_1"):  open_screen("cultivation")
    if event.is_action_pressed("ui_screen_2"):  open_screen("combat")
    if event.is_action_pressed("ui_screen_3"):  open_screen("resources")
    if event.is_action_pressed("ui_screen_4"):  open_screen("save")
    if event.is_action_pressed("ui_screen_5"):  open_screen("offline_settlement")
    if event.is_action_pressed("ui_toggle_nav"): _toggle_left_nav()
```

### 7.7 UI never writes game state

All screens follow the pattern established in `.claude/rules/ui-code.md`:

- **Read**: `ResourceSystem.get_value("lingqi")`, `CultivationSystem.get_hud_state()`, etc.
- **Command**: `CultivationSystem.manual_cultivate()`, `ZoneSystem.set_current_zone(id)`, `SaveManager.save_game(slot)`
- **Subscribe**: `EventBus.subscribe("resource.lingqi.changed", _on_resource_changed)`

No screen directly mutates ResourceSystem, AttributeSystem, or any core system state.

---

## 8. Quick Reference: Tween Patterns

All animations specified in visual-design-sprint-11.md use these Tween recipes:

| Animation | Recipe |
|---|---|
| cross-fade (120ms) | `tween.tween_property(control, "modulate:a", 1.0, 0.12).from(0.0)` |
| scale+fade in (200ms) | `tween.tween_property(modal, "scale", Vector2.ONE, 0.2).from(Vector2(0.95, 0.95)).set_ease(Tween.EASE_OUT)` parallel with modulate.a from 0 to 1 |
| height expand (200ms) | `tween.tween_property(row, "custom_minimum_size:y", expanded_height, 0.2).set_ease(Tween.EASE_OUT)` |
| count-up (1.5s) | `tween.tween_method(callback, 0.0, 1.0, 1.5).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)` |
| HP bar instant | `progress_bar.value = new_value` -- no tween |
| fade-in new log line (220ms) | `tween.tween_property(label, "modulate:a", 1.0, 0.22).from(0.0)` |
| victory overlay (1s) | `tween.tween_property(overlay, "modulate:a", 0.4, 1.0).from(0.0).set_ease(Tween.EASE_OUT)` |
| breathing glow (1.5s cycle) | `tween.set_loops().tween_property(button, "scale", Vector2(1.05, 1.05), 0.75)...` |

All `Tween` usage should check `SettingsSystem.reduce_motion`. When `true`, instant-jump to final state (duration=0 or call setter directly).

---

## 9. File Organization

```
src/ui/
  shell/
    shell.tscn                    # Root shell scene (contains all 4 zones)
    shell.gd                      # Shell logic (nav toggle, input dispatch)
    left_nav.tscn                 # LEFT NAV component
    left_nav.gd
    top_strip.tscn                # TOP STRIP component
    top_strip.gd
    right_panel.tscn              # RIGHT PANEL component (battle log + chips)
    right_panel.gd
  screens/
    base_screen.gd                # BaseScreen class
    cultivation_screen.tscn
    cultivation_screen.gd
    combat_screen.tscn
    combat_screen.gd
    resources_screen.tscn
    resources_screen.gd
    save_screen.tscn
    save_screen.gd
    offline_settlement_screen.tscn
    offline_settlement_screen.gd
  components/
    resource_production_row.tscn  # P-DAT-01-EXP reusable component
    resource_production_row.gd
    item_card.tscn                # P-DAT-04 reusable component
    item_card.gd
    status_chip.tscn              # P-FBK-02 reusable component
    status_chip.gd
    save_slot_card.tscn           # Save screen slot card
    save_slot_card.gd
    settlement_resource_card.tscn # Offline settlement resource detail card
    settlement_resource_card.gd
    virtual_item_grid.gd          # P-DAT-02 virtualized grid
    battle_log.gd                 # P-FBK-03 battle log wrapper
  modals/
    stance_select_modal.tscn      # Cultivation: stance picker
    stance_select_modal.gd
    confirm_overwrite_modal.tscn  # Save: overwrite confirmation
    confirm_overwrite_modal.gd
    confirm_load_modal.tscn       # Save: load confirmation
    confirm_load_modal.gd
    confirm_delete_modal.tscn     # Save: P-INP-02 delete confirmation
    confirm_delete_modal.gd
    settings_modal.tscn           # P-NAV-03 settings
    settings_modal.gd
  toast/
    toast_stack.tscn              # P-FBK-01
    toast_stack.gd
```

Existing `src/ui/hud/` (temporary skeleton) will be replaced by the shell. Keep it as reference, mark deprecated in CLAUDE.md.

---

## 10. Verification Checklist (Pre-Implementation)

- [ ] theme.tres has all 4 button states (normal/hover/pressed/disabled) from button_states.png
- [ ] theme.tres has focus StyleBox (2px `burst_gold` border)
- [ ] Chinese font (Noto Sans SC) loaded at `assets/ui/fonts/` and registered in theme.tres
- [ ] Input Map has actions: `ui_screen_1` through `ui_screen_5`, `ui_toggle_nav`, `ui_confirm_critical`
- [ ] Godot window stretch mode = `canvas_items` + `expand`
- [ ] `UIManagerHostAutoload` service implements `register_screen`, `open_screen`, `close_screen`, `open_modal`, `close_modal`
- [ ] All 5 screen .tscn files exist and extend `BaseScreen`
- [ ] All screen .gd scripts follow `.claude/rules/ui-code.md` (read-only queries, command writes, EventBus subscriptions)
- [ ] VirtualItemGrid object pool pattern implemented and benchmarked at 1000+ items
- [ ] Dual-focus tested: keyboard Tab + gamepad D-Pad + mouse click all show `burst_gold` focus outline
- [ ] Reduced-motion toggle: all Tweens check `SettingsSystem.reduce_motion` and fall back to instant
