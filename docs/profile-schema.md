# Comfort Cues Profile Schema

Profile 使用 TOML 文件描述，默认模板位于 `profiles/default.toml`。应用启动后会把模板复制到用户数据目录，用户修改通常发生在 `%APPDATA%\Comfort Cues\profiles\` 或应用当前配置目录中。

本文覆盖 `profiles/default.toml` 的现有字段，并说明非默认 profile 的继承和匹配规则。

## 基本规则

- 文件编码使用 UTF-8。
- 一个 profile 对应一个 `.toml` 文件。
- `default.toml` 是基线配置，不参与窗口自动匹配。
- 其他 profile 缺少字段时，会继承默认 profile 的对应值。
- `match_exe` 和 `match_title` 使用小写化后的“包含匹配”，不是正则表达式。
- 应用保存 profile 时会按固定字段顺序重新序列化。

## 示例

```toml
name = "Default"
description = "Generic comfort defaults used as a baseline for matched profiles and simulator preview."
match_exe = []
match_title = []
enable_mouse = true
enable_gamepad = true
yaw_gain = 1.000
pitch_gain = 0.850
deadzone = 0.080
max_opacity = 0.180
fade_in_ms = 120
fade_out_ms = 220
safe_mode = true
cue_pattern = "dynamic"
cue_visibility = "standard"
debug_opacity_multiplier = 1.800
last_bound_exe = ""
last_bound_title = ""
```

## 字段说明

| 字段 | 类型 | 默认值 | 说明 |
| --- | --- | --- | --- |
| `name` | string | `"Default"` | Profile 显示名称。保存新 profile 时也会用于生成文件名 slug。 |
| `description` | string | `""` | 给用户或维护者看的说明，不参与运行逻辑。 |
| `match_exe` | string array | `[]` | 进程名匹配片段，例如 `["cs2.exe"]`。应用会转为小写，并用“包含”判断目标 exe。 |
| `match_title` | string array | `[]` | 窗口标题匹配片段，例如 `["counter-strike"]`。应用会转为小写，并用“包含”判断窗口标题。 |
| `enable_mouse` | bool | `true` | 是否启用鼠标视角变化作为提示输入来源。 |
| `enable_gamepad` | bool | `true` | 是否启用手柄视角变化作为提示输入来源。 |
| `yaw_gain` | number | `1.000` | 横向视角变化增益。值越高，水平移动产生的提示越明显。 |
| `pitch_gain` | number | `0.850` | 纵向视角变化增益。值越高，垂直移动产生的提示越明显。 |
| `deadzone` | number | `0.080` | 输入死区。低于该强度的输入会被过滤，用于减少漂移和抖动。 |
| `max_opacity` | number | `0.180` | 常规模式下提示的最大不透明度。建议保持克制，避免遮挡游戏信息。 |
| `fade_in_ms` | number | `120` | 提示进入时的淡入时间，单位毫秒。 |
| `fade_out_ms` | number | `220` | 提示消退时的淡出时间，单位毫秒。 |
| `safe_mode` | bool | `true` | 保守运行模式开关。对外发布建议默认开启，用于表达非侵入式、低风险配置取向。 |
| `cue_pattern` | string | `"dynamic"` | 提示图案模式。当前有效值为 `"dynamic"`、`"regular"`；无效值会回退到 `"dynamic"`。 |
| `cue_visibility` | string | `"standard"` | 提示可见度预设。当前有效值为 `"standard"`、`"larger_dots"`、`"more_dots"`；无效值会回退到 `"standard"`。 |
| `debug_opacity_multiplier` | number | `1.800` | 调试/校准模式下的不透明度倍率，用于让提示更容易被看见。 |
| `last_bound_exe` | string | `""` | 最近一次手动绑定的进程名，小写保存。可用于 UI 回显或后续匹配辅助。 |
| `last_bound_title` | string | `""` | 最近一次手动绑定的窗口标题片段，小写保存。可用于 UI 回显或后续匹配辅助。 |

## 匹配规则

窗口自动匹配流程：

1. `default.toml` 只作为基线，不直接匹配任何窗口。
2. 应用按 profile 文件顺序检查非默认 profile。
3. 当前进程名转为小写后，只要包含 `match_exe` 中任一片段即匹配。
4. 当前窗口标题转为小写后，只要包含 `match_title` 中任一片段即匹配。
5. `match_exe` 和 `match_title` 任一命中即可匹配。

建议：

- `match_exe` 尽量使用稳定的可执行文件名，例如 `game.exe`。
- `match_title` 只放稳定、短且不含账号信息的片段。
- 不要把完整窗口标题、直播标题、用户名或本地路径写入模板 profile。

## 数值建议

以下范围不是硬性校验，只是发布和 profile 制作建议：

| 字段 | 建议范围 | 说明 |
| --- | --- | --- |
| `yaw_gain` | `0.50` 到 `1.50` | 过高可能使提示频繁闪动。 |
| `pitch_gain` | `0.40` 到 `1.20` | 垂直移动通常比水平移动更容易引起干扰，默认略低。 |
| `deadzone` | `0.03` 到 `0.12` | 手柄漂移明显时可提高；鼠标微动无响应时可降低。 |
| `max_opacity` | `0.10` 到 `0.40` | 日常使用建议低值；调试时用倍率提高可见性。 |
| `fade_in_ms` | `50` 到 `180` | 越低响应越快，越高越柔和。 |
| `fade_out_ms` | `120` 到 `400` | 越高残留越久，可能更稳定但更容易分散注意力。 |
| `debug_opacity_multiplier` | `1.50` 到 `3.00` | 仅用于确认覆盖层是否工作，不建议长期高亮使用。 |

## 安全与隐私注意事项

- `match_title` 和 `last_bound_title` 可能包含窗口标题信息。发布模板不要包含个人信息、账号名、服务器名或直播标题。
- profile 默认应作为本地配置处理，不应自动上传。
- 如果用户向支持团队提交 profile，应提醒其先检查窗口标题和路径信息。
- profile 不应用于绕过游戏限制、自动输入或竞技增强。

## 向后兼容

当前加载逻辑对未知字段采取忽略策略；缺失字段会从默认 profile 或内置默认值补齐。新增字段时建议：

1. 保持旧 profile 可加载。
2. 给 `default.toml` 添加明确默认值。
3. 更新本文字段表。
4. 更新 native 与 Python 两条实现的序列化/反序列化逻辑。
5. 增加配置加载和保存测试，确认字段不会在保存后丢失。
