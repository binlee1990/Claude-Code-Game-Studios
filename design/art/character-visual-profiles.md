# Character Visual Profiles

> Version: v0.1 | Date: 2026-04-23 | Status: Draft
> Art Direction: art-bible.md (Chapter 5 角色设计方向, Chapter 4 色彩系统)
> Narrative: worldbuilding-narrative.md (三路线角色体系)
> Class System: class-system.md (职业外观差异)

---

## Overview

本文档定义关键角色的视觉规格。由于角色姓名/性别尚未最终确定（worldbuilding OQ-2），当前按 **角色原型 (Archetype)** 组织，每个原型对应一个叙事功能和视觉方向。待角色设定确认后，将原型替换为具体角色。

---

## Profile Template

每个角色档案包含以下字段:

| 字段 | 说明 |
|------|------|
| Archetype | 叙事原型 |
| Faction | 阵营归属 |
| Role | 游戏内功能 |
| Silhouette | 轮廓关键词 |
| Primary Color | 主色调 (art-bible 五行色) |
| Accent Color | 辅助色 |
| Texture Spec | 纹理规格 (art-bible 8.2) |
| Animation Notes | 动画要点 |
| Class Affinity | 关联职业 |

---

## Key Characters

### C-01: 主角 (Protagonist)

| 字段 | 值 |
|------|-----|
| Archetype | 玩家化身——信念值驱动的决策者 |
| Faction | 中立（随信念值路线分流） |
| Role | 队伍领袖，可转职，信念值载体 |
| Silhouette | 匀称体型，中等身高，轮廓简洁不夸张 |
| Primary Color | 宣纸白 #F5F2EB（中性起点，不预设路线色） |
| Accent Color | 金铜色 #B8860B（领导感、成长感） |
| Texture Spec | 主角级: 128×128 RGBA PNG (32×32 像素×4x)，图集 512×512 (16帧) |
| Animation | 8方向×2姿态（战斗/待机），特写动画帧率 12 FPS |
| Class Affinity | 初始: 战士 → 可分支至所有进阶职业 |

**设计原则**: 主角外观必须不偏向任何路线色——视觉上保持"中立起点"感。随着路线确定，通过装备/光效叠加路线色。

**视觉成长路线**:

| 阶段 | 视觉变化 |
|------|----------|
| 初始 | 简朴装束，宣纸白底色 |
| 路线确定 | 装备叠加路线色（朱红/墨黑/青绿） |
| 进阶职业 | 武器/护甲视觉升级，职业图标出现在装备上 |
| 终局 | 完整路线色外装 + 专属武器光效 |

---

### C-02: 朱红路线代表 (Resolve Route Representative)

| 字段 | 值 |
|------|-----|
| Archetype | 果断路线导师/伙伴——推动玩家选择行动 |
| Faction | 叛军/改革阵营 |
| Role | 路线锁定后加入的核心队伍成员 |
| Silhouette | 锐利轮廓，宽肩，武器明显可见 |
| Primary Color | 朱红 #D4501A |
| Accent Color | 暗金 #8B6914 |
| Texture Spec | 重要角色: 128×128 RGBA PNG，图集 512×512 (16帧) |
| Animation | 8方向×2姿态，攻击动画偏"爆发式" |
| Class Affinity | 进阶职业倾向: 剑圣/狂战士类 |

**性格视觉线索**: 动作幅度大，待机时有轻微躁动（不安静站立），武器始终出鞘。

---

### C-03: 墨黑路线代表 (Patience Route Representative)

| 字段 | 值 |
|------|-----|
| Archetype | 隐忍路线导师/伙伴——推动玩家选择策略 |
| Faction | 朝廷/中央阵营 |
| Role | 路线锁定后加入的核心队伍成员 |
| Silhouette | 修长轮廓，窄肩，武器隐蔽或不可见 |
| Primary Color | 墨黑 #1E2A3A |
| Accent Color | 暗银 #A0A0B0 |
| Texture Spec | 重要角色: 128×128 RGBA PNG，图集 512×512 (16帧) |
| Animation | 8方向×2姿态，攻击动画偏"精准式" |
| Class Affinity | 进阶职业倾向: 暗影刺客/军师类 |

**性格视觉线索**: 动作幅度小，待机时完全静止（沉稳姿态），武器仅在攻击时显现。

---

### C-04: 青绿路线代表 (Curiosity Route Representative)

| 字段 | 值 |
|------|-----|
| Archetype | 探索路线导师/伙伴——推动玩家选择理解 |
| Faction | 隐世/中立阵营 |
| Role | 路线锁定后加入的核心队伍成员 |
| Silhouette | 圆润轮廓，中等体型，携带探索道具 |
| Primary Color | 青绿 #3D8B5F |
| Accent Color | 土黄 #C4A35A |
| Texture Spec | 重要角色: 128×128 RGBA PNG，图集 512×512 (16帧) |
| Animation | 8方向×2姿态，攻击动画偏"流畅式" |
| Class Affinity | 进阶职业倾向: 游侠/侦察兵类 |

**性格视觉线索**: 动作流畅自然，待机时环顾四周（好奇姿态），随身携带地图/卷轴道具。

---

### C-05: 宿敌 (Rival/Antagonist)

| 字段 | 值 |
|------|-----|
| Archetype | 玩家对立面——信念值路线的镜像 |
| Faction | 与玩家路线相反的阵营 |
| Role | Boss 战对手 + 叙事对立面 |
| Silhouette | 与主角对称但更尖锐/更有压迫感 |
| Primary Color | 深紫 #4A1A6A（非三路线色——代表"异端"） |
| Accent Color | 暗红 #8B1A1A |
| Texture Spec | Boss 级: 128×128 RGBA PNG，图集 512×512 (16帧) |
| Animation | 8方向×2姿态，Boss 专属攻击动画 3-5 套 |
| Class Affinity | 与主角相同职业系的镜像（如主角剑圣→宿敌暗剑圣） |

**设计原则**: 宿敌视觉上必须与主角形成"镜面对照"——相似但有明确差异。体型相似但配色对立。

---

## Class Visual Language

职业系统的视觉差异通过以下维度表达:

### 基础职业 (6类)

| 职业 | 武器轮廓 | 装甲特征 | 主色倾向 | 图标 |
|------|----------|----------|----------|------|
| 战士 | 宽刃剑/斧 | 中甲，肩甲明显 | 暖灰/棕 | 剑形 |
| 侦察兵 | 弓/匕首 | 轻甲，斗篷 | 暗绿 | 弓形 |
| 骑士 | 长枪/盾 | 重甲，全身覆盖 | 银灰 | 盾形 |
| 法师 | 法杖 | 法袍，无甲 | 深蓝 | 星形 |
| 僧侣 | 拳套/珠 | 轻甲，围巾 | 素白 | 莲形 |
| 弓手 | 长弓 | 轻甲，护臂 | 棕绿 | 箭形 |

### 进阶职业视觉升级

| 升级维度 | 表现方式 |
|----------|----------|
| 武器 | 轮廓更大/更复杂，加光效 |
| 装甲 | 细节增加（纹饰、肩饰、披风） |
| 光效 | 职业元素光环绕（火→红光，水→蓝光） |
| 姿态 | 待机动画更自信/更有气场 |

---

## Enemy Visual Language

### 敌方单位分类

| 类型 | 纹理规格 | 轮廓特征 | 颜色倾向 |
|------|----------|----------|----------|
| 普通士兵 | 64×64 RGBA PNG | 小型，简笔画式 | 灰褐色系 |
| 精英单位 | 64×64 RGBA PNG | 中型，武器更明显 | 阵营色（淡） |
| Boss | 128×128 RGBA PNG | 大型，轮廓夸张 | 深色+路线色光效 |
| 召唤物 | 32×32 RGBA PNG | 抽象/非人形 | 元素属性色 |

### Boss 阶段视觉变化

| Boss 阶段 | 视觉变化 | 参考 |
|-----------|----------|------|
| 阶段 1 (>70% HP) | 正常外观 | boss-system.md |
| 阶段 2 (50-70% HP) | 光效增强，武器变色 | — |
| 阶段 3 (<50% HP) | 轮廓变暗/变亮，粒子环绕 | — |

---

## Color-Shape Mapping (Accessibility)

所有角色元素遵循 art-bible 7.6.2 色彩+形状备份:

| 元素属性 | 颜色 | 形状 |
|----------|------|------|
| 火属性角色/装备 | 红/橙 | 火焰形 |
| 水属性角色/装备 | 蓝/青 | 水滴形 |
| 风属性角色/装备 | 浅绿/白 | 风向形 |
| 土属性角色/装备 | 棕/黄 | 三角形 |
| 金属性（叙事） | 金/白 | 五边形 |

---

## Open Items

| ID | 待定项 | 阻塞于 | 影响范围 |
|----|--------|--------|----------|
| CV-OQ-1 | 主角姓名/性别/背景 | worldbuilding-narrative OQ-2 | 主角档案全部字段 |
| CV-OQ-2 | 路线代表角色具体设定 | 叙事细化 | C-02/03/04 档案 |
| CV-OQ-3 | 宿敌具体设定 | 叙事细化 | C-05 档案 |
| CV-OQ-4 | 每个基础职业的像素精灵参考帧 | 美术制作 | Class Visual Language |

---

## Related Documents

- `design/art/art-bible.md` Ch.5 — 角色设计方向
- `design/art/art-bible.md` Ch.4 — 色彩系统
- `design/art/art-bible.md` Ch.8 — 资产标准（纹理规格）
- `design/gdd/worldbuilding-narrative.md` — 三路线角色体系
- `design/gdd/class-system.md` — 职业外观差异
- `design/gdd/boss-system.md` — Boss 阶段设计
