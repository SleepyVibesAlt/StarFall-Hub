# 🌟 StarFall Hub — Smooth UI Library

A lightweight, modern Roblox UI library with smooth animations, collapsible sections, and a clean dark theme. Built for script hubs, exploit GUIs, and in-game menus.

![Roblox](https://img.shields.io/badge/Roblox-Lua-00A2FF?style=flat-square&logo=roblox)
![License](https://img.shields.io/badge/License-MIT-green?style=flat-square)
![Version](https://img.shields.io/badge/Version-1.0.0-blue?style=flat-square)

---

## ✨ Features

| Feature | Description |
|---------|-------------|
| **🎨 Modern Dark Theme** | Purple accent, subtle borders, consistent spacing |
| **📱 Collapsible Sections** | Click section headers to expand/collapse with smooth arrow animation |
| **🖱️ Draggable Window** | Click & drag topbar to reposition |
| **⌨️ Keybind Toggle** | Press `RightShift` to show/hide the UI |
| **🔔 Toast Notifications** | Auto-dismissing notifications with countdown timers |
| **🎯 Smooth Animations** | Quart easing on all transitions (toggles, sliders, sections, notifications) |
| **📦 Zero Dependencies** | Single file, no external requires |
| **📋 Dropdown Selector** | Inline single/multi-select dropdowns that push elements down |
| **⌨️ Keybind Picker** | Click to bind keys/mouse buttons, fires callback on press |
| **🏷️ Label Element** | Rich text labels with customizable styling, colors, alignment |
| **💬 Prompt Dialog** | Modal confirmations with custom buttons, full-screen backdrop |
| **⌨️ Input Prompt** | Modal text input with placeholder, validation, mobile-optimized |

---

## 📦 Installation

### Option 1: Loadstring (Recommended)
```lua
local SmoothUI = loadstring(game:HttpGet("https://raw.githubusercontent.com/SleepyVibesAlt/StarFall-Hub/main/guis/library.lua"))()
```

### Option 2: Local File
```lua
local SmoothUI = loadstring(readfile("guis/library.lua"))()
```

### Option 3: Direct Require (Roblox Studio)
```lua
local SmoothUI = require(game.ReplicatedStorage.SmoothUI)
```

---

## 🚀 Quick Start

```lua
-- 1. Initialize the library
local Library = SmoothUI.new()

-- 2. Create a window
local Window = Library:CreateWindow({
    Title = "My Script Hub"
})

-- 3. Create tabs
local MainTab = Window:CreateTab("Main")
local CombatTab = Window:CreateTab("Combat")

-- 4. Create sections (collapsible!)
local PlayerSection = MainTab:CreateSection("Player")
local AimbotSection = CombatTab:CreateSection("Aimbot")

-- 5. Add elements to sections
PlayerSection:CreateSlider({
    Name = "WalkSpeed",
    Range = {16, 200},
    CurrentValue = 16,
    Callback = function(value)
        game.Players.LocalPlayer.Character.Humanoid.WalkSpeed = value
    end
})

AimbotSection:CreateToggle({
    Name = "Enabled",
    CurrentValue = false,
    Callback = function(state)
        _G.AimbotEnabled = state
    end
})

-- 6. Show a notification
Library:Notify("Welcome", "Script loaded successfully!", 4)
```

**Result:** A draggable window with tabs, collapsible sections, and working controls.

---

## 📚 API Reference

### `SmoothUI.new()`
Creates a new library instance (ScreenGui).
```lua
local Library = SmoothUI.new()
```
> **Note:** Destroys any existing `SmoothUILibrary` ScreenGui to prevent duplicates.

---

### `Library:CreateWindow(config)`
Creates the main draggable window.

```lua
local Window = Library:CreateWindow({
    Title = "Script Hub"  -- string (optional, default: "Smooth UI")
})
```

**Returns:** `Window` table

---

### `Window:CreateTab(name)`
Creates a new tab in the sidebar.

```lua
local Tab = Window:CreateTab("Main")
```

**Returns:** `Tab` table

---

### `Tab:CreateSection(name)`
Creates a **collapsible section** inside the tab. Elements are added to the section, not the tab.

```lua
local Section = Tab:CreateSection("Player Settings")
```

**Returns:** `Section` table with element methods

> **Key Change:** In v1.0, elements (Button, Toggle, Slider, Textbox) are created on the **Section**, not the Tab.

---

### `Section:CreateButton(config)`
Adds a clickable button.

```lua
Section:CreateButton({
    Name = "Rejoin Server",
    Callback = function()
        game:GetService("TeleportService"):Teleport(game.PlaceId)
    end
})
```

| Property | Type | Required | Description |
|----------|------|----------|-------------|
| `Name` | string | ✅ | Button label |
| `Callback` | function | ✅ | Called on click |

---

### `Section:CreateToggle(config)`
Adds an on/off toggle switch.

```lua
local MyToggle = Section:CreateToggle({
    Name = "Noclip",
    CurrentValue = false,  -- optional, default: false
    Callback = function(enabled)
        _G.Noclip = enabled
    end
})
```

**Returns:** `{ Set = function(bool), Get = function() : bool }`

| Property | Type | Required | Description |
|----------|------|----------|-------------|
| `Name` | string | ✅ | Toggle label |
| `CurrentValue` | boolean | ❌ | Initial state (default: `false`) |
| `Callback` | function | ✅ | Called with `enabled` (boolean) |

**Programmatic Control:**
```lua
MyToggle:Set(true)   -- Enable
MyToggle:Set(false)  -- Disable
print(MyToggle:Get()) -- true/false
```

---

### `Section:CreateSlider(config)`
Adds a draggable slider.

```lua
local SpeedSlider = Section:CreateSlider({
    Name = "WalkSpeed",
    Range = {16, 200},      -- {min, max}
    CurrentValue = 16,      -- optional, default: min
    Callback = function(value)
        game.Players.LocalPlayer.Character.Humanoid.WalkSpeed = value
    end
})
```

**Returns:** `{ Set = function(number), Get = function() : number }`

| Property | Type | Required | Description |
|----------|------|----------|-------------|
| `Name` | string | ✅ | Slider label |
| `Range` | {number, number} | ✅ | `{min, max}` |
| `CurrentValue` | number | ❌ | Initial value (default: `min`) |
| `Callback` | function | ✅ | Called with `value` (number) |

**Programmatic Control:**
```lua
SpeedSlider:Set(100)
print(SpeedSlider:Get()) -- 100
```

---

### `Section:CreateTextbox(config)`
Adds a text input field.

```lua
Section:CreateTextbox({
    Name = "Player Name",
    PlaceholderText = "Enter username...",
    Callback = function(text)
        print("Searching for:", text)
    end
})
```

| Property | Type | Required | Description |
|----------|------|----------|-------------|
| `Name` | string | ✅ | Label above input |
| `PlaceholderText` | string | ❌ | Placeholder (default: "Enter text...") |
| `Callback` | function | ✅ | Called with `text` (string) on focus lost |

**Returns:** `TextBox` instance (for advanced use)

---

### `Section:CreateDropdown(config)`
Adds an inline dropdown selector (single or multi-select) that expands within the section layout, pushing other elements down.

```lua
local MyDropdown = Section:CreateDropdown({
    Name = "Target Part",
    Options = {"Head", "Torso", "Random"},  -- or {Name="Head", Value="head"}, ...
    CurrentOption = "Head",                  -- default: first option
    MultiSelect = false,                     -- optional, default: false
    Callback = function(selected)
        print("Selected:", selected)
    end
})
```

| Property | Type | Required | Description |
|----------|------|----------|-------------|
| `Name` | string | ✅ | Label above dropdown |
| `Options` | table | ✅ | Array of strings or `{Name, Value}` tables |
| `CurrentOption` | any | ❌ | Initial selection (default: first option) |
| `MultiSelect` | boolean | ❌ | Enable multi-select (default: `false`) |
| `Callback` | function | ✅ | Called with selected value(s) |

**Returns:** `{ Set = function(val), Get = function() : val, Refresh = function(newOptions), SetExpanded = function(bool), IsExpanded = function() : bool, Destroy = function() }`

**Programmatic Control:**
```lua
MyDropdown:Set("Torso")              -- Set selection
MyDropdown:Get()                     -- Get current selection
MyDropdown.Refresh({"New", "Opts"})  -- Update options list
MyDropdown.SetExpanded(true)         -- Expand dropdown
MyDropdown.IsExpanded()              -- Check if expanded
MyDropdown.Destroy()                 -- Clean up and remove dropdown
```

**Features:**
- Inline expansion — pushes other section elements down via UIListLayout
- Smooth height animation on expand/collapse
- Single or multi-select modes
- Click outside to close (single select)
- Automatic option highlighting
- **Selection highlight feedback** — Single-select briefly highlights the chosen option (0.3s) before auto-closing, matching multi-select visual behavior

---

### `Section:CreateKeybind(config)`
Adds a keybind picker — click the button, press a key/mouse button to bind it. Fires callback when the bound key is pressed.

```lua
local MyKeybind = Section:CreateKeybind({
    Name = "Toggle UI",
    Key = Enum.KeyCode.RightShift,  -- optional, default: RightShift
    Callback = function(key)
        print("Pressed:", key.Name)
        Window:Toggle()
    end
})
```

**Returns:** `{ Set = function(key, fireCallback?), Get = function() : EnumItem, WaitingForInput = function() : bool }`

| Property | Type | Required | Description |
|----------|------|----------|-------------|
| `Name` | string | ✅ | Label next to keybind button |
| `Key` | EnumItem | ❌ | Initial key (default: `Enum.KeyCode.RightShift`) |
| `Callback` | function | ✅ | Called with `key` (EnumItem) when pressed |

**Programmatic Control:**
```lua
MyKeybind:Set(Enum.KeyCode.F1)           -- Change key (callback NOT fired)
MyKeybind:Set(Enum.KeyCode.F1, true)     -- Change key AND fire callback
print(MyKeybind:Get().Name)              -- "F1"
print(MyKeybind:WaitingForInput())       -- true/false (is user binding?)
```

**Features:**
- Supports keyboard keys (`Enum.KeyCode`) and mouse buttons (`Enum.UserInputType`)
- Visual feedback when waiting for input (shows "..." in accent color)
- Callback only fires on actual key press, not on programmatic `Set()`
- Optional `fireCallback` parameter on `Set()` to trigger callback manually

---

### `Section:CreateLabel(config)`
Adds a customizable text label with rich text support, colors, alignment, and optional background.

```lua
local MyLabel = Section:CreateLabel({
    Text = "Hello World",              -- or use Name as fallback
    TextColor3 = ThemeColor.Text,      -- optional
    TextSize = 13,                     -- optional
    Font = Enum.Font.GothamMedium,     -- optional
    TextXAlignment = Enum.TextXAlignment.Left,  -- optional
    RichText = false,                  -- optional, enable rich text markup
    Height = 25,                       -- optional
    Padding = 12,                      -- optional, text padding from left
    BackgroundColor3 = nil,            -- optional, adds background + rounded corners
    CornerRadius = 6,                  -- optional, used with BackgroundColor3
})
```

**Returns:** `{ Set = function(text), Get = function() : string, SetColor = function(color3), SetSize = function(number), SetAlignment = function(xAlign?, yAlign?), Destroy = function() }`

| Property | Type | Required | Description |
|----------|------|----------|-------------|
| `Text` / `Name` | string | ✅ | Label text (Name used if Text not provided) |
| `TextColor3` | Color3 | ❌ | Text color (default: `ThemeColor.Text`) |
| `TextSize` | number | ❌ | Font size (default: `13`) |
| `Font` | Enum.Font | ❌ | Font face (default: `GothamMedium`) |
| `TextXAlignment` | Enum.TextXAlignment | ❌ | Horizontal alignment (default: `Left`) |
| `TextWrapped` | boolean | ❌ | Wrap long text (default: `false`) |
| `RichText` | boolean | ❌ | Enable `<font>`, `<b>`, `<i>` markup (default: `false`) |
| `Height` | number | ❌ | Element height (default: `25`) |
| `Padding` | number | ❌ | Left padding (default: `12`) |
| `BackgroundColor3` | Color3 | ❌ | If set, adds colored background with rounded corners |
| `CornerRadius` | number | ❌ | Corner radius for background (default: `6`) |

**Usage Examples:**
```lua
-- Simple label
local Label = Section:CreateLabel({Text = "Hello World"})

-- Rich text with colors & bold
local StyledLabel = Section:CreateLabel({
    Text = "<font color='#825aff'>Colored</font> <b>Rich Text</b>",
    RichText = true,
    TextSize = 14,
    TextColor3 = ThemeColor.Accent,
    TextXAlignment = Enum.TextXAlignment.Center,
    Height = 30
})

-- Label with background box
local BoxedLabel = Section:CreateLabel({
    Text = "Status: Active",
    BackgroundColor3 = ThemeColor.Element,
    TextColor3 = ThemeColor.Text,
    Height = 28,
    Padding = 8
})

-- Update programmatically
Label.Set("New text")
StyledLabel.SetColor(ThemeColor.Muted)
StyledLabel.SetSize(16)
StyledLabel.SetAlignment(Enum.TextXAlignment.Center)
BoxedLabel.Destroy()
```

---

### Section Methods

```lua
Section:SetExpanded(false)  -- Collapse
Section:SetExpanded(true)   -- Expand
Section:IsExpanded()        -- Returns true/false
```

---

### `Library:Notify(title, message, duration)`
Shows a toast notification (bottom-right, auto-dismisses).

```lua
Library:Notify("Success", "Config saved!", 3)
Library:Notify("Error", "Failed to load", 5)
```

| Parameter | Type | Required | Default |
|-----------|------|----------|---------|
| `title` | string | ✅ | — |
| `message` | string | ✅ | — |
| `duration` | number | ❌ | `3` seconds |

**Features:**
- Click to dismiss early
- Countdown timer in top-right
- Smooth slide in/out animation
- Multiple notifications stack vertically

---

### Window Methods

```lua
Window:Toggle()    -- Show/hide window
Window:Destroy()   -- Clean up & remove UI
```

---

### `Library:Prompt(config)`
Shows a modal confirmation dialog with customizable buttons.

```lua
Library:Prompt({
    Title = "Confirm Reset",
    Message = "This will reset your character. Continue?",
    Buttons = {
        {Text = "Cancel"},
        {Text = "Reset", Primary = true, Callback = function() 
            game.Players.LocalPlayer:LoadCharacter() 
        end}
    }
})
```

**Config Options:**

| Property | Type | Required | Default | Description |
|----------|------|----------|---------|-------------|
| `Title` | string | ❌ | `"Prompt"` | Dialog title |
| `Message` | string | ❌ | `""` | Dialog message (supports wrapping) |
| `Buttons` | table | ❌ | `{OK}` | Array of `{Text, Callback, Primary?}` |
| `CloseOnOverlayClick` | boolean | ❌ | `true` | Click backdrop to dismiss |

**Button Properties:**

| Property | Type | Required | Description |
|----------|------|----------|-------------|
| `Text` | string | ✅ | Button label |
| `Callback` | function | ❌ | Called on click |
| `Primary` | boolean | ❌ | Highlights button (accent color); auto-applied to last button if none set |

**Returns:** `{ Close = function() }` — call `Close()` to dismiss programmatically.

**Features:**
- Full-screen backdrop with `IgnoreGuiInset` (covers top/bottom bars)
- Smooth fade-in/fade-out animation (no slide)
- Primary button highlighted in accent color
- Click backdrop to dismiss (configurable)

---

### `Library:InputPrompt(config)`
Shows a modal dialog with a text input field for collecting user input.

```lua
Library:InputPrompt({
    Title = "Create Preset",
    Message = "Enter a name for your new preset:",
    Placeholder = "My Preset",
    DefaultText = "Preset 1",
    Buttons = {
        {Text = "Cancel"},
        {Text = "Create", Primary = true, Callback = function(name)
            print("Creating preset:", name)
        end}
    }
})
```

**Config Options:**

| Property | Type | Required | Default | Description |
|----------|------|----------|---------|-------------|
| `Title` | string | ❌ | `"Input"` | Dialog title |
| `Message` | string | ❌ | `""` | Dialog message |
| `Placeholder` | string | ❌ | `"Enter text..."` | TextBox placeholder |
| `DefaultText` | string | ❌ | `""` | Pre-filled text |
| `AutoFocus` | boolean | ❌ | `true` | Auto-focus textbox on open (set `false` for mobile) |
| `SubmitOnEnter` | boolean | ❌ | `false` | Press Enter to submit (set `true` for desktop) |
| `Buttons` | table | ❌ | Cancel/Confirm | Same as `Prompt` |
| `CloseOnOverlayClick` | boolean | ❌ | `true` | Click backdrop to dismiss |

**Returns:** `{ Close = function(), GetText = function() : string }`

**Features:**
- Real `TextBox` with placeholder, default text, padding
- Mobile-friendly: `AutoFocus=false` prevents keyboard popup
- `SubmitOnEnter=false` by default — no accidental submits on mobile
- Enter key submits only when `SubmitOnEnter=true` (opt-in)
- Smoother animation: defers one frame before fade-in to prevent stiffness
- Returns `GetText()` for reading value before callback

---

### Complete Example (Prompt Usage)

```lua
-- Simple confirmation
Library:Prompt({
    Title = "Delete Config?",
    Message = "This action cannot be undone.",
    Buttons = {
        {Text = "Keep It"},
        {Text = "Delete", Primary = true, Callback = function() 
            print("Deleted!") 
        end}
    }
})

-- Input with validation
Library:InputPrompt({
    Title = "Set WalkSpeed",
    Message = "Enter a value between 16 and 500:",
    Placeholder = "16",
    DefaultText = "16",
    Buttons = {
        {Text = "Cancel"},
        {Text = "Apply", Primary = true, Callback = function(text)
            local val = tonumber(text)
            if val and val >= 16 and val <= 500 then
                local hum = game.Players.LocalPlayer.Character:FindFirstChild("Humanoid")
                if hum then hum.WalkSpeed = val end
                Library:Notify("Applied", "WalkSpeed set to " .. val, 2)
            else
                Library:Notify("Invalid", "Please enter a number 16-500", 3)
            end
        end}
    }
})

-- Mobile-optimized input (no auto-focus, no enter submit)
Library:InputPrompt({
    Title = "Rename Preset",
    Message = "Enter new name:",
    Placeholder = "Preset Name",
    AutoFocus = false,
    SubmitOnEnter = false,
    Buttons = {
        {Text = "Cancel"},
        {Text = "Save", Primary = true, Callback = function(name) ... end}
    }
})
```

## 🎮 Complete Example

```lua
local Library = SmoothUI.new()

local Window = Library:CreateWindow({
    Title = "StarFall Hub v1.0"
})

-- ============ MAIN TAB ============
local MainTab = Window:CreateTab("Main")

local General = MainTab:CreateSection("General")
General:CreateButton({
    Name = "Rejoin",
    Callback = function()
        game:GetService("TeleportService"):Teleport(game.PlaceId)
    end
})

General:CreateButton({
    Name = "Copy Discord",
    Callback = function()
        setclipboard("https://discord.gg/yourserver")
        Library:Notify("Copied!", "Discord link in clipboard", 2)
    end
})

local Player = MainTab:CreateSection("Player")
local WS = Player:CreateSlider({
    Name = "WalkSpeed",
    Range = {16, 200},
    CurrentValue = 16,
    Callback = function(v)
        local hum = game.Players.LocalPlayer.Character:FindFirstChild("Humanoid")
        if hum then hum.WalkSpeed = v end
    end
})

local JP = Player:CreateSlider({
    Name = "JumpPower",
    Range = {50, 300},
    CurrentValue = 50,
    Callback = function(v)
        local hum = game.Players.LocalPlayer.Character:FindFirstChild("Humanoid")
        if hum then hum.JumpPower = v end
    end
})

Player:CreateButton({
    Name = "Reset Character",
    Callback = function()
        game.Players.LocalPlayer:LoadCharacter()
    end
})

local Noclip = Player:CreateToggle({
    Name = "Noclip",
    CurrentValue = false,
    Callback = function(v) _G.Noclip = v end
})

-- Dropdown example (single select)
local TargetPart = Player:CreateDropdown({
    Name = "Target Part",
    Options = {"Head", "Torso", "HumanoidRootPart", "Left Arm", "Right Arm", "Left Leg", "Right Leg"},
    CurrentOption = "Head",
    MultiSelect = false,
    Callback = function(selected)
        _G.TargetPart = selected
        Library:Notify("Target Changed", "Now targeting: " .. selected, 2)
    end
})

-- Dropdown example (multi select)
local MultiSelect = Player:CreateDropdown({
    Name = "Multi Select",
    Options = {"Option A", "Option B", "Option C", "Option D"},
    CurrentOption = {},
    MultiSelect = true,
    Callback = function(selected)
        local names = {}
        for k, v in pairs(selected) do
            if v then table.insert(names, k) end
        end
        Library:Notify("Multi-Select", "Selected: " .. table.concat(names, ", "), 2)
    end
})

-- Dropdown example with Name/Value tables
local CustomDropdown = Player:CreateDropdown({
    Name = "Custom Values",
    Options = {
        {Name = "Head", Value = "HeadPart"},
        {Name = "Torso", Value = "TorsoPart"},
        {Name = "HumanoidRootPart", Value = "HRP"},
    },
    CurrentOption = "HeadPart",  -- Set by Value
    MultiSelect = false,
    Callback = function(selected)
        _G.CustomValue = selected
        print("Custom dropdown selected:", selected)
    end
})

-- ============ COMBAT TAB ============
local CombatTab = Window:CreateTab("Combat")

local Aimbot = CombatTab:CreateSection("Aimbot")
Aimbot:CreateToggle({Name = "Enabled", CurrentValue = false, Callback = function(v) _G.Aimbot = v end})
Aimbot:CreateToggle({Name = "Team Check", CurrentValue = true, Callback = function(v) _G.TeamCheck = v end})
Aimbot:CreateToggle({Name = "Wall Check", CurrentValue = true, Callback = function(v) _G.WallCheck = v end})

Aimbot:CreateSlider({Name = "FOV", Range = {10, 360}, CurrentValue = 90, Callback = function(v) _G.FOV = v end})
Aimbot:CreateSlider({Name = "Smoothness", Range = {1, 20}, CurrentValue = 5, Callback = function(v) _G.Smooth = v end})

local Trigger = CombatTab:CreateSection("Triggerbot")
Trigger:CreateToggle({Name = "Enabled", CurrentValue = false, Callback = function(v) _G.Trigger = v end})
Trigger:CreateSlider({Name = "Delay (ms)", Range = {0, 500}, CurrentValue = 50, Callback = function(v) _G.TriggerDelay = v end})

-- ============ VISUALS TAB ============
local VisualsTab = Window:CreateTab("Visuals")

local ESP = VisualsTab:CreateSection("ESP")
ESP:CreateToggle({Name = "Box", CurrentValue = false, Callback = function(v) _G.BoxESP = v end})
ESP:CreateToggle({Name = "Names", CurrentValue = false, Callback = function(v) _G.NameESP = v end})
ESP:CreateToggle({Name = "Health", CurrentValue = false, Callback = function(v) _G.HealthESP = v end})
ESP:CreateToggle({Name = "Distance", CurrentValue = false, Callback = function(v) _G.DistESP = v end})
ESP:CreateSlider({Name = "Max Distance", Range = {100, 5000}, CurrentValue = 1000, Callback = function(v) _G.MaxDist = v end})

-- ============ STARTUP ============
Library:Notify("StarFall Hub", "Loaded! Press RightShift to toggle.", 4)

-- Keybind example (toggle UI with custom key)
local Keybind = Player:CreateKeybind({
    Name = "Toggle UI",
    Key = Enum.KeyCode.RightShift,
    Callback = function(key)
        print("Pressed:", key.Name)
        Window:Toggle()
    end
})

-- Label examples
local Label = Player:CreateLabel({Text = "Simple Label"})

local StyledLabel = Player:CreateLabel({
    Text = "<font color='#825aff'>Colored</font> <b>Rich Text</b>",
    RichText = true,
    TextSize = 14,
    TextColor3 = ThemeColor.Accent,
    TextXAlignment = Enum.TextXAlignment.Center,
    Height = 30
})

local BoxedLabel = Player:CreateLabel({
    Text = "Status: Active",
    BackgroundColor3 = ThemeColor.Element,
    TextColor3 = ThemeColor.Text,
    Height = 28,
    Padding = 8
})

-- Auto-collapse sections after 10 seconds
task.delay(10, function()
    General:SetExpanded(false)
    Player:SetExpanded(false)
    Aimbot:SetExpanded(false)
    ESP:SetExpanded(false)
end)
```

---

## 🎨 Theme Colors

The library uses a consistent color palette. To customize, modify the `Theme` table at the top of `library.lua`:

```lua
local Theme = {
    Background = Color3.fromRGB(18, 18, 24),    -- Window background
    Secondary  = Color3.fromRGB(26, 26, 34),    -- Topbar, sidebar, element backgrounds
    Element    = Color3.fromRGB(34, 34, 44),    -- Button hover, slider track
    Accent     = Color3.fromRGB(130, 90, 255),  -- Purple accent (selection, slider fill)
    Text       = Color3.fromRGB(240, 240, 245), -- Primary text
    Muted      = Color3.fromRGB(145, 145, 160), -- Secondary text, placeholders
    Border     = Color3.fromRGB(48, 48, 60),     -- Strokes, borders
    PureWhite = Color3.fromRGB(255, 255, 255)
}
```

### Pre-made Themes

| Theme | Accent Color |
|-------|--------------|
| **Midnight** (Default) | `130, 90, 255` (Purple) |
| **Blood** | `255, 45, 85` (Red) |
| **Emerald** | `45, 200, 120` (Green) |
| **Ocean** | `45, 140, 255` (Blue) |
| **Gold** | `255, 180, 45` (Yellow) |

---

## ⌨️ Default Keybinds

| Key | Action |
|-----|--------|
| `RightShift` | Toggle UI visibility |
| `Mouse Drag` (Topbar) | Move window |
| `Click Section Header` | Collapse/expand section |
| `Click Notification` | Dismiss notification |

---

## 🛠️ Extending the Library

> **Note:** `CreateKeybind` and `CreateLabel` are now built-in! See API reference above.

---

## 📁 File Structure

```
StarFall-Hub/
├── guis/
│   └── library.lua      # Main UI library (single file)
├── README.md            # This file
└── LICENSE              # MIT License
```

---

## ⚠️ Important Notes

1. **Elements go on Sections, not Tabs** — `Tab:CreateButton()` doesn't exist. Use `Section:CreateButton()`.

2. **Sections are collapsible** — Click the header (or call `SetExpanded()`) to toggle.

3. **Automatic layout** — `UIListLayout` handles positioning. Don't manually set `Position` on elements.

4. **Callbacks are async** — `task.spawn()` wraps callbacks to prevent UI freezing.

5. **RightShift toggles UI** — Built-in, no setup needed.

6. **ScreenGui cleanup** — `SmoothUI.new()` destroys previous instance automatically.

---

## 🐛 Troubleshooting

| Issue | Solution |
|-------|----------|
| **Elements not visible** | Ensure you're adding to a Section (`MainSection:CreateButton`), not the Tab |
| **UI not opening** | Check `RightShift` keybind isn't overridden; verify `ScreenGui` parented to `PlayerGui` |
| **Sections not collapsing** | Check `ElementsContainer` has `AutomaticSize = Enum.AutomaticSize.Y` |
| **Notifications not showing** | Verify `Library:Notify` is called after `SmoothUI.new()` |
| **Slider not dragging** | Ensure `UserInputService` events aren't consumed by other scripts |

---

## 📄 License

MIT License — Feel free to use, modify, and distribute.

```
Copyright (c) 2024 StarFall Hub

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction...
```

---

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit changes (`git commit -m 'Add amazing feature'`)
4. Push to branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

---

## 🙏 Credits

- **Roblox** — Platform & API
- **TweenService** — Smooth animations
- **Community** — Feedback & testing

---

<div align="center">

**Made with ❤️ for the Roblox scripting community**

[⭐ Star this repo](https://github.com/YourUsername/StarFall-Hub) • [🐛 Report Bug](https://github.com/YourUsername/StarFall-Hub/issues) • [💡 Request Feature](https://github.com/YourUsername/StarFall-Hub/issues)

</div>