local SmoothUI = {}
SmoothUI.__index = SmoothUI

local logoAsset = getcustomasset("Starfall_Hub/assets/right_logo.png")

-- Convert any value to a readable string (handles tables, nil, etc.)
local function toString(value)
	if value == nil then return "" end
	local t = type(value)
	if t == "string" then return value end
	if t == "number" or t == "boolean" then return tostring(value) end
	if t == "table" then
		-- Try to find a "Name", "name", "Text", or "text" field
		if value.Name then return toString(value.Name) end
		if value.name then return toString(value.name) end
		if value.Text then return toString(value.Text) end
		if value.text then return toString(value.text) end
		-- Fallback: show table contents (first few entries)
		local parts = {}
		for k, v in pairs(value) do
			table.insert(parts, toString(k) .. "=" .. toString(v))
			if #parts >= 5 then break end
		end
		return "{" .. table.concat(parts, ", ") .. (#parts > 5 and ", ..." or "") .. "}"
	end
	return tostring(value)
end

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local Player = Players.LocalPlayer
local PlayerGui = Player:WaitForChild("PlayerGui")

local ThemeColor = {
	Background = Color3.fromRGB(18, 18, 24),
	Secondary = Color3.fromRGB(26, 26, 34),
	Element = Color3.fromRGB(34, 34, 44),
	Accent = Color3.fromRGB(130, 90, 255),
	Text = Color3.fromRGB(240, 240, 245),
	Muted = Color3.fromRGB(145, 145, 160),
	Border = Color3.fromRGB(48, 48, 60),
	PureWhite = Color3.fromRGB(255, 255, 255)
}

local function Create(class, properties, parent)
	local object = Instance.new(class)

	for property, value in pairs(properties or {}) do
		object[property] = value
	end

	object.Parent = parent
	return object
end

local function Corner(parent, radius)
	Create("UICorner", {
		CornerRadius = UDim.new(0, radius or 8)
	}, parent)
end

local function Stroke(parent, color, transparency, Border)
	Create("UIStroke", {
		Color = color or ThemeColor.Border,
		Transparency = transparency or 0,
		Thickness = 1,
		ApplyStrokeMode = Border or Enum.ApplyStrokeMode.Border
	}, parent)
end

local function Tween(object, properties, duration)
	local tween = TweenService:Create(
		object,
		TweenInfo.new(duration or 0.2, Enum.EasingStyle.Quart, Enum.EasingDirection.Out),
		properties
	)

	tween:Play()
	return tween
end

function SmoothUI:Notify(title, message, duration)
	duration = duration or 3

	local notification = Create("TextButton", {
		Name = "Notification",
		Size = UDim2.fromOffset(280, 50),
		Position = UDim2.new(1, 300, 1, -30),
		AnchorPoint = Vector2.new(1, 1),
		BackgroundColor3 = ThemeColor.Secondary,
		BorderSizePixel = 0,
		Text = "",
		AutoButtonColor = false
	}, self.ScreenGui)

	Corner(notification, 8)
	Stroke(notification, ThemeColor.Border, 0)

	-- Title
	Create("TextLabel", {
		Name = "TitleLabel",
		Position = UDim2.fromOffset(12, 4),
		Size = UDim2.new(1, -24, 0, 20),
		BackgroundTransparency = 1,
		Text = toString(title),
		TextColor3 = ThemeColor.Text,
		TextSize = 14,
		Font = Enum.Font.GothamBold,
		TextXAlignment = Enum.TextXAlignment.Left
	}, notification)

	-- Message
	Create("TextLabel", {
		Name = "MessageLabel",
		Position = UDim2.fromOffset(12, 24),
		Size = UDim2.new(1, -24, 0, 20),
		BackgroundTransparency = 1,
		Text = toString(message),
		TextColor3 = ThemeColor.Muted,
		TextSize = 11,
		Font = Enum.Font.Gotham,
		TextWrapped = true,
		TextXAlignment = Enum.TextXAlignment.Left
	}, notification)

	-- Countdown text in top-right corner
	local countdownLabel = Create("TextLabel", {
		Name = "CountdownLabel",
		Size = UDim2.fromOffset(35, 14),
		Position = UDim2.new(1, -40, 0, 2),
		BackgroundTransparency = 1,
		Text = tostring(duration) .. "s",
		TextColor3 = ThemeColor.Muted,
		TextSize = 9,
		Font = Enum.Font.GothamMedium,
		TextXAlignment = Enum.TextXAlignment.Right
	}, notification)

	local dismissed = false

	local function dismiss()
		if dismissed then return end
		dismissed = true

		-- Slide out horizontally
		Tween(notification, {
			Position = UDim2.new(1, 300, 1, -30)
		}, 0.25)

		task.wait(0.3)
		notification:Destroy()
	end

	-- Click to dismiss
	notification.MouseButton1Click:Connect(dismiss)

	-- Slide in horizontally
	Tween(notification, {
		Position = UDim2.new(1, -20, 1, -30)
	}, 0.3)

	-- Update countdown timer
	task.spawn(function()
		local startTime = tick()
		local endTime = startTime + duration

		while not dismissed and tick() < endTime do
			local remaining = math.ceil(endTime - tick())
			countdownLabel.Text = remaining .. "s"
			task.wait(0.1)
		end

		if not dismissed then
			dismiss()
		end
	end)
end

function SmoothUI:CreateWindow(config)
	config = config or {}

	local Window = {}
	Window.Tabs = {}
	Window.Library = self  -- Store reference to Library for notifications

	local Main = Create("Frame", {
		Name = "MainWindow",
		Size = UDim2.fromOffset(650, 320),
		Position = UDim2.fromScale(0.5, 0.5),
		AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundColor3 = ThemeColor.Background,
		BorderSizePixel = 0,
		Visible = false
	}, self.ScreenGui)

	Corner(Main, 12)
	Stroke(Main)

	local Topbar = Create("Frame", {
		Name = "Topbar",
		Size = UDim2.new(1, 0, 0, 45),
		BackgroundColor3 = ThemeColor.Secondary,
		BorderSizePixel = 0
	}, Main)

	Corner(Topbar, 12)

	Create("TextLabel", {
		Name = "WindowTitle",
		Position = UDim2.fromOffset(16, 0),
		Size = UDim2.new(1, -32, 1, 0),
		BackgroundTransparency = 1,
		Text = toString(config.Title or "Smooth UI"),
		TextColor3 = ThemeColor.Text,
		TextSize = 16,
		Font = Enum.Font.GothamBold,
		TextXAlignment = Enum.TextXAlignment.Left
	}, Topbar)

	Create("Frame", {
		Name = "WindowTitleBackground",
		Position = UDim2.new(0, 0, 0, 16),
		Size = UDim2.new(1.05, -32, 0.639999986, 0),
		BackgroundColor3 = ThemeColor.Secondary,
		BorderSizePixel = 0,
		ZIndex = 0
	}, Topbar)

	-- Logo in Topbar (created once per window) - acts as toggle button
	local LogoButton = Create("ImageButton", {
		Name = "LogoButton",
		Size = UDim2.fromOffset(45, 45),
		Position = UDim2.fromScale(0.924595296, 0),
		BackgroundTransparency = 1,
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		BorderColor3 = Color3.fromRGB(0, 0, 0),
		BorderSizePixel = 0,
		Image = logoAsset,
		ZIndex = 1,
		AutoButtonColor = false
	}, Topbar)

	-- Standalone floating logo (always visible, acts as toggle button)
	local StandaloneLogo = Create("ImageButton", {
		Name = "StandaloneLogo",
		Size = UDim2.fromOffset(45, 45),
		Position = UDim2.new(0, 25, 0, 65),
		BackgroundTransparency = 0,
		BackgroundColor3 = Color3.fromRGB(0, 0, 0),
		BorderColor3 = Color3.fromRGB(0, 0, 0),
		BorderSizePixel = 0,
		Image = logoAsset,
		ZIndex = 1,
		AutoButtonColor = false
	}, self.ScreenGui)

	Corner(StandaloneLogo, 8)

	-- Standalone logo dragging
	local standaloneDragging = false
	local standaloneDragStart, standaloneStartPos

	StandaloneLogo.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch then
			standaloneDragging = true
			standaloneDragStart = input.Position
			standaloneStartPos = StandaloneLogo.Position
		end
	end)

	UserInputService.InputChanged:Connect(function(input)
		if standaloneDragging and (
			input.UserInputType == Enum.UserInputType.MouseMovement
				or input.UserInputType == Enum.UserInputType.Touch
			) then
			local delta = input.Position - standaloneDragStart
			StandaloneLogo.Position = UDim2.new(
				standaloneStartPos.X.Scale,
				standaloneStartPos.X.Offset + delta.X,
				standaloneStartPos.Y.Scale,
				standaloneStartPos.Y.Offset + delta.Y
			)
		end
	end)

	UserInputService.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch then
			standaloneDragging = false
		end
	end)

	-- SetVisible method for the window (handles show/hide with animation)
	local function SetVisible(visible)
		if visible then
			Main.Visible = true
			-- Scale animation from 0.92 to 1
			local windowScale = Main:FindFirstChild("UIScale")
			if not windowScale then
				windowScale = Create("UIScale", {Scale = 0.92}, Main)
			end
			windowScale.Scale = 0.92
			Tween(windowScale, {Scale = 1}, 0.32)
		else
			local windowScale = Main:FindFirstChild("UIScale")
			if not windowScale then
				windowScale = Create("UIScale", {Scale = 1}, Main)
			end
			Tween(windowScale, {Scale = 0.92}, 0.22)
			task.delay(0.22, function()
				if windowScale.Scale <= 0.93 then
					Main.Visible = false
				end
			end)
		end
	end

	-- Toggle function that handles both logo and standalone mode
	local function ToggleUI()
		local isVisible = Main.Visible
		local newVisible = not isVisible
		SetVisible(newVisible)

		-- Standalone logo stays visible at all times (user drags it to reposition)
		StandaloneLogo.Visible = true
	end

	-- Click handlers
	LogoButton.MouseButton1Click:Connect(ToggleUI)
	StandaloneLogo.MouseButton1Click:Connect(ToggleUI)

	-- Store references for external access
	Window.LogoButton = LogoButton
	Window.StandaloneLogo = StandaloneLogo
	Window.ToggleUI = ToggleUI
	Window.SetVisible = SetVisible

	-- Dragging
	local dragging = false
	local dragStart, startPosition

	Topbar.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			dragStart = input.Position
			startPosition = Main.Position

			input.Changed:Connect(function()
				if input.UserInputState == Enum.UserInputState.End then
					dragging = false
				end
			end)
		end
	end)

	UserInputService.InputChanged:Connect(function(input)
		if dragging and (
			input.UserInputType == Enum.UserInputType.MouseMovement
				or input.UserInputType == Enum.UserInputType.Touch
			) then
			local delta = input.Position - dragStart

			Main.Position = UDim2.new(
				startPosition.X.Scale,
				startPosition.X.Offset + delta.X,
				startPosition.Y.Scale,
				startPosition.Y.Offset + delta.Y
			)
		end
	end)

	local Sidebar = Create("Frame", {
		Name = "Sidebar",
		Position = UDim2.fromOffset(10, 55),
		Size = UDim2.new(-0.0400066003, 135, 1, -65),
		BackgroundColor3 = ThemeColor.Secondary,
		BorderSizePixel = 0
	}, Main)

	Corner(Sidebar, 9)

	local TabContainer = Create("Frame", {
		Name = "TabContainer",
		Size = UDim2.new(1, -10, 1, -10),
		Position = UDim2.fromOffset(5, 5),
		BackgroundTransparency = 1
	}, Sidebar)

	Create("UIListLayout", {
		Name = "TabListLayout",
		Padding = UDim.new(0, 6),
		SortOrder = Enum.SortOrder.LayoutOrder
	}, TabContainer)

	local Content = Create("Frame", {
		Name = "Content",
		Position = UDim2.fromOffset(133, 55),
		Size = UDim2.new(1.05228758, -165, 1, -65),
		BackgroundTransparency = 1
	}, Main)

	local function CreateTab(_, TabName)
		local Tab = {}

		local TabButton = Create("TextButton", {
			Name = "TabButton_" .. toString(TabName),
			Size = UDim2.new(0.993142382, 0, -0.027777778, 35),
			BackgroundColor3 = ThemeColor.Element,
			BackgroundTransparency = 1,
			Text = toString(TabName or "Tab"),
			TextColor3 = ThemeColor.PureWhite,
			TextSize = 14,
			Font = Enum.Font.GothamMedium,
			AutoButtonColor = false,
			TextWrapped = true
		}, TabContainer)

		Corner(TabButton, 7)

		Create("UITextSizeConstraint", {
			Name = "TabButtonTextConstraint",
			MinTextSize = 11,
			MaxTextSize = 14
		}, TabButton)

		local Page = Create("ScrollingFrame", {
			Name = "TabPage_" .. toString(TabName),
			Size = UDim2.fromScale(1, 1),
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			ScrollBarThickness = 2,
			ScrollBarImageColor3 = ThemeColor.Accent,
			CanvasSize = UDim2.new(),
			AutomaticCanvasSize = Enum.AutomaticSize.Y,
			Visible = false
		}, Content)

		Create("UIListLayout", {
			Name = "PageListLayout",
			Padding = UDim.new(0, 8),
			SortOrder = Enum.SortOrder.LayoutOrder,
			HorizontalAlignment = Enum.HorizontalAlignment.Center
		}, Page)

		Create("UIPadding", {
			Name = "PagePadding",
			PaddingTop = UDim.new(0, 3),
			PaddingRight = UDim.new(0, 10),
			PaddingBottom = UDim.new(1, 0),
			PaddingLeft = UDim.new(0, 5)
		}, Page)

	function Tab:Select()
			for _, other in pairs(Window.Tabs) do
				other.Page.Visible = false
				Tween(other.Button, {
					BackgroundTransparency = 1,
					TextColor3 = ThemeColor.PureWhite
				})
			end

			Page.Visible = true

			Tween(TabButton, {
				BackgroundTransparency = 0,
				BackgroundColor3 = ThemeColor.Accent,
				TextColor3 = ThemeColor.Text
			})
		end

		local function CreateSection(name, parentContainer)
			local Section = Create("Frame", {
				Name = "Section_" .. toString(name),
				Size = UDim2.new(1, -5, 0, 30),
				BackgroundTransparency = 1
			}, parentContainer)

			-- Arrow indicator (points down when expanded, right when collapsed)
			local Arrow = Create("TextLabel", {
				Name = "SectionArrow",
				Size = UDim2.fromOffset(20, 20),
				Position = UDim2.fromOffset(2, 5),
				BackgroundTransparency = 1,
				Text = "▼",
				TextColor3 = ThemeColor.Accent,
				TextSize = 12,
				Font = Enum.Font.GothamBold,
				TextXAlignment = Enum.TextXAlignment.Center,
				Rotation = 0
			}, Section)

			-- Section title (offset to make room for arrow)
			local Title = Create("TextLabel", {
				Name = "SectionLabel",
				Size = UDim2.new(1, -28, 1, 0),
				Position = UDim2.fromOffset(24, 0),
				BackgroundTransparency = 1,
				Text = toString(name),
				TextColor3 = ThemeColor.Accent,
				TextSize = 13,
				Font = Enum.Font.GothamBold,
				TextXAlignment = Enum.TextXAlignment.Left
			}, Section)

			-- Container for all elements in this section
			local ElementsContainer = Create("Frame", {
				Name = "SectionElements",
				Size = UDim2.new(1, -5, 0, 0),
				Position = UDim2.fromOffset(0, 30),
				BackgroundTransparency = 1,
				Visible = true,
				ClipsDescendants = true,
				AutomaticSize = Enum.AutomaticSize.Y
			}, parentContainer)

			Create("UIListLayout", {
				Name = "SectionElementsLayout",
				Padding = UDim.new(0, 8),
				SortOrder = Enum.SortOrder.LayoutOrder,
				HorizontalAlignment = Enum.HorizontalAlignment.Center
			}, ElementsContainer)

			local expanded = true

			local function SetExpanded(state)
				expanded = state
				ElementsContainer.Visible = state
				-- Also collapse size to 0 for layout reliability
				if state then
					ElementsContainer.Size = UDim2.new(1, -5, 0, 0) -- Will grow via AutomaticSize
				else
					ElementsContainer.Size = UDim2.new(1, -5, 0, 0)
				end
				-- Force layout update on the parent (Page) UIListLayout
				if ElementsContainer.Parent then
					ElementsContainer.Parent.UIListLayout:ApplyLayout()
				end
				Tween(Arrow, {Rotation = state and 0 or -90}, 0.2)
			end

			-- Make section header clickable
			local ClickArea = Create("TextButton", {
				Name = "SectionClickArea",
				Size = UDim2.fromScale(1, 1),
				BackgroundTransparency = 1,
				Text = ""
			}, Section)

			ClickArea.MouseButton1Click:Connect(function()
				SetExpanded(not expanded)
			end)

			-- Return section API with element creators
			local sectionAPI = {
				SetExpanded = SetExpanded,
				IsExpanded = function() return expanded end,
				CreateElement = function(height, elementName)
					return Create("Frame", {
						Name = elementName or "Element",
						Size = UDim2.new(1, -11, 0, height),
						BackgroundColor3 = ThemeColor.Secondary,
						BorderSizePixel = 0
					}, ElementsContainer)
				end,
				Container = ElementsContainer,
				Arrow = Arrow,
				Title = Title
			}

			-- Element creation methods
			function sectionAPI:CreateButton(config)
				local Button = self.CreateElement(40, "Button_" .. toString(config.Name or "Button"))
				Corner(Button, 8)

				local Text = Create("TextButton", {
					Name = "ButtonLabel",
					Size = UDim2.fromScale(1, 1),
					BackgroundTransparency = 1,
					Text = toString(config.Name or "Button"),
					TextColor3 = ThemeColor.Text,
					TextSize = 13,
					Font = Enum.Font.GothamMedium,
					AutoButtonColor = false
				}, Button)

				Text.MouseEnter:Connect(function()
					Tween(Button, {BackgroundColor3 = ThemeColor.Element})
				end)

				Text.MouseLeave:Connect(function()
					Tween(Button, {BackgroundColor3 = ThemeColor.Secondary})
				end)

				Text.MouseButton1Click:Connect(function()
					if config.Callback then
						task.spawn(config.Callback)
					end
				end)
			end

            function sectionAPI:CreateKeybind(config)
                local Keybind = self.CreateElement(40, "Keybind_" .. toString(config.Name or "Keybind"))
                Corner(Keybind, 8)

                local CurrentKey = config.Key or Enum.KeyCode.RightShift
                local WaitingForInput = false

                local Label = Create("TextLabel", {
                    Name = "KeybindLabel",
                    Position = UDim2.fromOffset(12, 0),
                    Size = UDim2.new(1, -100, 1, 0),
                    BackgroundTransparency = 1,
                    Text = toString(config.Name or "Keybind"),
                    TextColor3 = ThemeColor.Text,
                    TextSize = 13,
                    Font = Enum.Font.GothamMedium,
                    TextXAlignment = Enum.TextXAlignment.Left
                }, Keybind)

                local KeyButton = Create("TextButton", {
                    Name = "KeybindButton",
                    Size = UDim2.fromOffset(80, 24),
                    Position = UDim2.new(1, -92, 0.5, 0),
                    AnchorPoint = Vector2.new(0, 0.5),
                    BackgroundColor3 = ThemeColor.Element,
                    Text = CurrentKey.Name,
                    TextColor3 = ThemeColor.Text,
                    TextSize = 11,
                    Font = Enum.Font.GothamMedium,
                    AutoButtonColor = false,
                    TextTruncate = Enum.TextTruncate.AtEnd
                }, Keybind)

                Corner(KeyButton, 6)
                Stroke(KeyButton, ThemeColor.Border, 0.5)

                local function UpdateDisplay()
                    KeyButton.Text = CurrentKey.Name
                end

                local function Set(key, fireCallback)
                    CurrentKey = key
                    UpdateDisplay()
                    if fireCallback and config.Callback then
                        config.Callback(CurrentKey)
                    end
                end

                KeyButton.MouseButton1Click:Connect(function()
                    WaitingForInput = true
                    KeyButton.Text = "..."
                    KeyButton.TextColor3 = ThemeColor.Accent
                    Stroke(KeyButton, ThemeColor.Accent, 0)
                end)

                UserInputService.InputBegan:Connect(function(input, processed)
                    if WaitingForInput and not processed then
                        if input.UserInputType == Enum.UserInputType.Keyboard then
                            WaitingForInput = false
                            Set(input.KeyCode)
                            KeyButton.TextColor3 = ThemeColor.Text
                            Stroke(KeyButton, ThemeColor.Border, 0.5)
                        elseif input.UserInputType == Enum.UserInputType.MouseButton1
                            or input.UserInputType == Enum.UserInputType.MouseButton2
                            or input.UserInputType == Enum.UserInputType.MouseButton3 then
                            WaitingForInput = false
                            Set(input.UserInputType)
                            KeyButton.TextColor3 = ThemeColor.Text
                            Stroke(KeyButton, ThemeColor.Border, 0.5)
                        end
                    elseif not WaitingForInput and not processed then
                        if input.KeyCode == CurrentKey or input.UserInputType == CurrentKey then
                            if config.Callback then
                                task.spawn(config.Callback, CurrentKey)
                            end
                        end
                    end
                end)

                local keybindAPI = {
                    Set = Set,
                    Get = function() return CurrentKey end,
                    WaitingForInput = function() return WaitingForInput end
                }

                return keybindAPI
            end

			function sectionAPI:CreateToggle(config)
				local Toggle = self.CreateElement(40, "Toggle_" .. toString(config.Name or "Toggle"))
				Corner(Toggle, 8)

				local Enabled = config.CurrentValue or false

				local Label = Create("TextLabel", {
					Name = "ToggleLabel",
					Position = UDim2.fromOffset(12, 0),
					Size = UDim2.new(1, -65, 1, 0),
					BackgroundTransparency = 1,
					Text = toString(config.Name or "Toggle"),
					TextColor3 = ThemeColor.Text,
					TextSize = 13,
					Font = Enum.Font.GothamMedium,
					TextXAlignment = Enum.TextXAlignment.Left
				}, Toggle)

				local Switch = Create("Frame", {
					Name = "ToggleSwitch",
					Size = UDim2.fromOffset(36, 19),
					Position = UDim2.new(1, -48, 0.5, 0),
					AnchorPoint = Vector2.new(0, 0.5),
					BackgroundColor3 = Enabled and ThemeColor.Accent or ThemeColor.Element
				}, Toggle)

				Corner(Switch, 20)
				Stroke(Switch, ThemeColor.Border, 0.5)

				local Knob = Create("Frame", {
					Name = "ToggleKnob",
					Size = UDim2.fromOffset(13, 13),
					Position = Enabled and UDim2.new(1, -16, 0.5, 0)
						or UDim2.new(0, 3, 0.5, 0),
					AnchorPoint = Vector2.new(0, 0.5),
					BackgroundColor3 = Color3.new(1, 1, 1)
				}, Switch)

				Corner(Knob, 20)
				Stroke(Knob, ThemeColor.Border, 0.3)

				local function Set(value)
					Enabled = value

					Tween(Switch, {
						BackgroundColor3 = Enabled and ThemeColor.Accent or ThemeColor.Element
					})

					-- Both states use Y scale 0.5 with AnchorPoint (0, 0.5) for perfect vertical centering
					Tween(Knob, {
						Position = Enabled and UDim2.new(1, -16, 0.5, 0)
							or UDim2.new(0, 3, 0.5, 0)
					})

					if config.Callback then
						config.Callback(Enabled)
					end
				end

				local Click = Create("TextButton", {
					Name = "ToggleClickArea",
					Size = UDim2.fromScale(1, 1),
					BackgroundTransparency = 1,
					Text = ""
				}, Toggle)

				Click.MouseButton1Click:Connect(function()
					Set(not Enabled)
				end)

				local toggleAPI = {
					Set = Set,
					Get = function() return Enabled end
				}

				return toggleAPI
			end

			function sectionAPI:CreateSlider(config)
				local Frame = self.CreateElement(65, "Slider_" .. toString(config.Name or "Slider"))
				Corner(Frame, 8)

				local Min = config.Range and config.Range[1] or 0
				local Max = config.Range and config.Range[2] or 100
				local Value = math.clamp(config.CurrentValue or Min, Min, Max)

				local Label = Create("TextLabel", {
					Position = UDim2.fromOffset(12, 5),
					Size = UDim2.new(1, -24, 0, 20),
					BackgroundTransparency = 1,
					Text = toString(config.Name or "Slider") .. ": " .. toString(Value),
					TextColor3 = ThemeColor.Text,
					TextSize = 13,
					Font = Enum.Font.GothamMedium,
					TextXAlignment = Enum.TextXAlignment.Left
				}, Frame)

				local Bar = Create("Frame", {
					Name = "SliderBar",
					Position = UDim2.fromOffset(12, 29),
					Size = UDim2.new(1, -24, 0, 5),
					BackgroundColor3 = ThemeColor.Element
				}, Frame)

				Corner(Bar, 10)
				Stroke(Bar, ThemeColor.Border, 0.5)

				local Fill = Create("Frame", {
					Name = "SliderFill",
					Size = UDim2.new((Value - Min) / (Max - Min), 0, 1, 0),
					BackgroundColor3 = ThemeColor.Accent
				}, Bar)

				Corner(Fill, 10)
				Stroke(Fill, ThemeColor.Accent, 0.3)

				local function Set(value)
					Value = math.clamp(value, Min, Max)

					local Percent = (Value - Min) / (Max - Min)

					Tween(Fill, {
						Size = UDim2.new(Percent, 0, 1, 0)
					})

					Label.Text = toString(config.Name or "Slider") .. ": " .. toString(Value)

					if config.Callback then
						config.Callback(Value)
					end
				end

				local function Update(input)
					local Percent = math.clamp(
						(input.Position.X - Bar.AbsolutePosition.X) / Bar.AbsoluteSize.X,
						0, 1
					)

					Set(math.floor(Min + (Max - Min) * Percent))
				end

				local Dragging = false

				Bar.InputBegan:Connect(function(input)
					if input.UserInputType == Enum.UserInputType.MouseButton1
						or input.UserInputType == Enum.UserInputType.Touch then
						Dragging = true
						Update(input)
					end
				end)

				UserInputService.InputChanged:Connect(function(input)
					if Dragging and (
						input.UserInputType == Enum.UserInputType.MouseMovement
							or input.UserInputType == Enum.UserInputType.Touch
						) then
						Update(input)
					end
				end)

				UserInputService.InputEnded:Connect(function(input)
					if input.UserInputType == Enum.UserInputType.MouseButton1
						or input.UserInputType == Enum.UserInputType.Touch then
						Dragging = false
					end
				end)

				local sliderAPI = {
					Set = Set,
					Get = function() return Value end
				}

				return sliderAPI
			end

			function sectionAPI:CreateTextbox(config)
				local Frame = self.CreateElement(65, "Textbox_" .. toString(config.Name or "Textbox"))
				Corner(Frame, 8)

				Create("TextLabel", {
					Name = "TextboxLabel",
					Position = UDim2.fromOffset(12, 4),
					Size = UDim2.new(1, -24, 0, 20),
					BackgroundTransparency = 1,
					Text = toString(config.Name or "Textbox"),
					TextColor3 = ThemeColor.Text,
					TextSize = 13,
					Font = Enum.Font.GothamMedium,
					TextXAlignment = Enum.TextXAlignment.Left
				}, Frame)

				local Input = Create("TextBox", {
					Name = "TextboxInput",
					Position = UDim2.fromOffset(10, 29),
					Size = UDim2.new(1, -20, 0, 28),
					BackgroundColor3 = ThemeColor.Element,
					Text = "",
					PlaceholderText = config.PlaceholderText or "Enter text...",
					TextColor3 = ThemeColor.Text,
					PlaceholderColor3 = ThemeColor.Muted,
					TextSize = 12,
					Font = Enum.Font.Gotham,
					ClearTextOnFocus = false
				}, Frame)

				Corner(Input, 6)
				Stroke(Input, ThemeColor.Border, 0.5)

				Input.FocusLost:Connect(function()
					if config.Callback then
						config.Callback(Input.Text)
					end
				end)

				return Input
			end

			function SmoothUI:Prompt(config)
				config = config or {}
				local Title = toString(config.Title or "Prompt")
				local Message = toString(config.Message or "")
				local Buttons = config.Buttons or {{Text = "OK", Callback = function() end}}
				
				local Overlay = Create("TextButton", {
					Name = "PromptOverlay",
					Size = UDim2.fromScale(1, 1),
					Position = UDim2.fromScale(0, 0),
					BackgroundColor3 = Color3.fromRGB(0, 0, 0),
					BackgroundTransparency = 1,  -- start invisible for fade-in
					Text = "",
					AutoButtonColor = false,
					ZIndex = 100,
				}, self.ScreenGui)

				-- Dialog frame
				local Dialog = Create("Frame", {
					Name = "PromptDialog",
					Size = UDim2.fromOffset(360, 170),
					Position = UDim2.fromScale(0.5, 0.5),
					AnchorPoint = Vector2.new(0.5, 0.5),
					BackgroundColor3 = ThemeColor.Background,
					BorderSizePixel = 0,
					BackgroundTransparency = 1,  -- start invisible for fade-in
					ZIndex = 101
				}, Overlay)

				Corner(Dialog, 12)
				Stroke(Dialog, ThemeColor.Accent, 0.2)

				-- Title
				Create("TextLabel", {
					Name = "PromptTitle",
					Position = UDim2.fromOffset(20, 16),
					Size = UDim2.new(1, -40, 0, 28),
					BackgroundTransparency = 1,
					Text = Title,
					TextColor3 = ThemeColor.Text,
					TextSize = 16,
					Font = Enum.Font.GothamBold,
					TextXAlignment = Enum.TextXAlignment.Left,
					ZIndex = 102
				}, Dialog)

				-- Message
				Create("TextLabel", {
					Name = "PromptMessage",
					Position = UDim2.fromOffset(20, 50),
					Size = UDim2.new(1, -40, 0, 60),
					BackgroundTransparency = 1,
					Text = Message,
					TextColor3 = ThemeColor.Muted,
					TextSize = 13,
					Font = Enum.Font.Gotham,
					TextWrapped = true,
					TextXAlignment = Enum.TextXAlignment.Left,
					TextYAlignment = Enum.TextYAlignment.Top,
					ZIndex = 102
				}, Dialog)

				-- Button container (bottom-right)
				local ButtonContainer = Create("Frame", {
					Name = "ButtonContainer",
					Position = UDim2.new(1, -20, 1, -16),
					AnchorPoint = Vector2.new(1, 1),
					Size = UDim2.new(1, -40, 0, 36),
					BackgroundTransparency = 1,
					ZIndex = 102
				}, Dialog)

				Create("UIListLayout", {
					FillDirection = Enum.FillDirection.Horizontal,
					HorizontalAlignment = Enum.HorizontalAlignment.Right,
					Padding = UDim.new(0, 8),
					SortOrder = Enum.SortOrder.LayoutOrder
				}, ButtonContainer)

				local dismissed = false

				local function Close()
					if dismissed then return end
					dismissed = true
					
					-- Fade out only (no position shift)
					Tween(Overlay, {BackgroundTransparency = 1}, 0.15)
					Tween(Dialog, {BackgroundTransparency = 1}, 0.15)
					
					task.wait(0.2)
					Overlay:Destroy()
				end

				-- Create buttons (reverse order for right-to-left layout)
				for i = #Buttons, 1, -1 do
					local btnConfig = Buttons[i]
					local isPrimary = btnConfig.Primary or (i == #Buttons and #Buttons == 1)
					
					local Btn = Create("TextButton", {
						Name = "PromptButton_" .. toString(btnConfig.Text or "Btn"),
						Size = UDim2.fromOffset(88, 36),
						BackgroundColor3 = isPrimary and ThemeColor.Accent or ThemeColor.Element,
						Text = toString(btnConfig.Text or "Button"),
						TextColor3 = ThemeColor.Text,
						TextSize = 13,
						Font = Enum.Font.GothamMedium,
						AutoButtonColor = false,
						LayoutOrder = i,
						ZIndex = 102
					}, ButtonContainer)

					Corner(Btn, 8)
					Stroke(Btn, isPrimary and ThemeColor.Accent or ThemeColor.Border, isPrimary and 0.3 or 0.5)

					Btn.MouseEnter:Connect(function()
						Tween(Btn, {BackgroundColor3 = isPrimary 
							and ThemeColor.Accent:Lerp(Color3.new(1,1,1), 0.15) 
							or ThemeColor.Secondary})
					end)
					Btn.MouseLeave:Connect(function()
						Tween(Btn, {BackgroundColor3 = isPrimary and ThemeColor.Accent or ThemeColor.Element})
					end)

					Btn.MouseButton1Click:Connect(function()
						if btnConfig.Callback then
							task.spawn(btnConfig.Callback)
						end
						Close()
					end)
				end

				-- Fade in animation
				Tween(Overlay, {BackgroundTransparency = 0.4}, 0.15)
				Tween(Dialog, {BackgroundTransparency = 0}, 0.2)

				-- Optional: close on overlay click
				Overlay.MouseButton1Click:Connect(function()
					if config.CloseOnOverlayClick ~= false then
						Close()
					end
				end)

				return {Close = Close}
			end

			function SmoothUI:InputPrompt(config)
				config = config or {}
				local Title = toString(config.Title or "Input")
				local Message = toString(config.Message or "")
				local Placeholder = toString(config.Placeholder or "Enter text...")
				local DefaultText = toString(config.DefaultText or "")
				local Buttons = config.Buttons or {
					{Text = "Cancel"},
					{Text = "Confirm", Primary = true}
				}
				local SubmitOnEnter = config.SubmitOnEnter == true  -- default FALSE, opt-in
				
				local Overlay = Create("TextButton", {
					Name = "InputPromptOverlay",
					Size = UDim2.fromScale(1, 1),
					Position = UDim2.fromScale(0, 0),
					BackgroundColor3 = Color3.fromRGB(0, 0, 0),
					BackgroundTransparency = 1,
					Text = "",
					AutoButtonColor = false,
					ZIndex = 100,
				}, self.ScreenGui)

				local Dialog = Create("Frame", {
					Name = "InputPromptDialog",
					Size = UDim2.fromOffset(360, 200),
					Position = UDim2.fromScale(0.5, 0.5),
					AnchorPoint = Vector2.new(0.5, 0.5),
					BackgroundColor3 = ThemeColor.Background,
					BorderSizePixel = 0,
					BackgroundTransparency = 1,
					ZIndex = 101
				}, Overlay)

				Corner(Dialog, 12)
				Stroke(Dialog, ThemeColor.Accent, 0.2)

				Create("TextLabel", {
					Position = UDim2.fromOffset(20, 16),
					Size = UDim2.new(1, -40, 0, 28),
					BackgroundTransparency = 1,
					Text = Title,
					TextColor3 = ThemeColor.Text,
					TextSize = 16,
					Font = Enum.Font.GothamBold,
					TextXAlignment = Enum.TextXAlignment.Left,
					ZIndex = 102
				}, Dialog)

				Create("TextLabel", {
					Position = UDim2.fromOffset(20, 50),
					Size = UDim2.new(1, -40, 0, 40),
					BackgroundTransparency = 1,
					Text = Message,
					TextColor3 = ThemeColor.Muted,
					TextSize = 13,
					Font = Enum.Font.Gotham,
					TextWrapped = true,
					TextXAlignment = Enum.TextXAlignment.Left,
					TextYAlignment = Enum.TextYAlignment.Top,
					ZIndex = 102
				}, Dialog)

				local Input = Create("TextBox", {
					Name = "InputPromptBox",
					Position = UDim2.fromOffset(20, 100),
					Size = UDim2.new(1, -40, 0, 40),
					BackgroundColor3 = ThemeColor.Element,
					Text = DefaultText,
					PlaceholderText = Placeholder,
					PlaceholderColor3 = ThemeColor.Muted,
					TextColor3 = ThemeColor.Text,
					TextSize = 13,
					Font = Enum.Font.Gotham,
					ClearTextOnFocus = false,
					TextXAlignment = Enum.TextXAlignment.Left,
					ZIndex = 102
				}, Dialog)

				Corner(Input, 8)
				Stroke(Input, ThemeColor.Border, 0.5)
				Create("UIPadding", {PaddingLeft = UDim.new(0, 12), PaddingRight = UDim.new(0, 12)}, Input)

				local ButtonContainer = Create("Frame", {
					Name = "ButtonContainer",
					Position = UDim2.new(1, -20, 1, -16),
					AnchorPoint = Vector2.new(1, 1),
					Size = UDim2.new(1, -40, 0, 36),
					BackgroundTransparency = 1,
					ZIndex = 102
				}, Dialog)

				Create("UIListLayout", {
					FillDirection = Enum.FillDirection.Horizontal,
					HorizontalAlignment = Enum.HorizontalAlignment.Right,
					Padding = UDim.new(0, 8),
					SortOrder = Enum.SortOrder.LayoutOrder
				}, ButtonContainer)

				local dismissed = false

				local function Close()
					if dismissed then return end
					dismissed = true
					
					-- Fade out smoothly (slightly longer for less jank)
					Tween(Overlay, {BackgroundTransparency = 1}, 0.2)
					Tween(Dialog, {BackgroundTransparency = 1}, 0.2)
					
					task.wait(0.25)
					Overlay:Destroy()
				end

				-- Create buttons (reverse for right-to-left)
				for i = #Buttons, 1, -1 do
					local btnConfig = Buttons[i]
					local isPrimary = btnConfig.Primary or (i == #Buttons and #Buttons == 1)
					
					local Btn = Create("TextButton", {
						Name = "InputPromptButton_" .. toString(btnConfig.Text or "Btn"),
						Size = UDim2.fromOffset(88, 36),
						BackgroundColor3 = isPrimary and ThemeColor.Accent or ThemeColor.Element,
						Text = toString(btnConfig.Text or "Button"),
						TextColor3 = ThemeColor.Text,
						TextSize = 13,
						Font = Enum.Font.GothamMedium,
						AutoButtonColor = false,
						LayoutOrder = i,
						ZIndex = 102
					}, ButtonContainer)

					Corner(Btn, 8)
					Stroke(Btn, isPrimary and ThemeColor.Accent or ThemeColor.Border, isPrimary and 0.3 or 0.5)

					Btn.MouseEnter:Connect(function()
						Tween(Btn, {BackgroundColor3 = isPrimary 
							and ThemeColor.Accent:Lerp(Color3.new(1,1,1), 0.12) 
							or ThemeColor.Secondary})
					end)
					Btn.MouseLeave:Connect(function()
						Tween(Btn, {BackgroundColor3 = isPrimary and ThemeColor.Accent or ThemeColor.Element})
					end)

					Btn.MouseButton1Click:Connect(function()
						if btnConfig.Callback then
							task.spawn(btnConfig.Callback, Input.Text)
						end
						Close()
					end)
				end

				-- Enter key submits ONLY if explicitly enabled (default: false)
				if SubmitOnEnter then
					Input.FocusLost:Connect(function(enterPressed)
						if enterPressed and not dismissed then
							local primaryBtn = Buttons[#Buttons]
							if primaryBtn and primaryBtn.Callback then
								task.spawn(primaryBtn.Callback, Input.Text)
							end
							Close()
						end
					end)
				end

				-- SMOOTHER ANIMATION: render one frame first, THEN animate
				-- This prevents the "freeze" on first frame
				task.defer(function()
					if dismissed then return end
					-- Fade in with slightly longer duration + Quart easing (default)
					Tween(Overlay, {BackgroundTransparency = 0.35}, 0.22)
					Tween(Dialog, {BackgroundTransparency = 0}, 0.22)
				end)

				Overlay.MouseButton1Click:Connect(function()
					if config.CloseOnOverlayClick ~= false then
						Close()
					end
				end)

				return {Close = Close, GetText = function() return Input.Text end}
			end

            function sectionAPI:CreateLabel(config)
                config = config or {}
                local Label = self.CreateElement(config.Height or 25, "Label_" .. toString(config.Name or "Label"))
                Label.BackgroundTransparency = 1  -- Transparent background by default

                local Text = Create("TextLabel", {
                    Name = "LabelText",
                    Size = UDim2.fromScale(1, 1),
                    Position = UDim2.fromOffset(config.Padding or 12, 0),
                    BackgroundTransparency = 1,
                    Text = toString(config.Text or config.Name or "Label"),
                    TextColor3 = config.TextColor3 or ThemeColor.Text,
                    TextSize = config.TextSize or 13,
                    Font = config.Font or Enum.Font.GothamMedium,
                    TextXAlignment = config.TextXAlignment or Enum.TextXAlignment.Left,
                    TextYAlignment = Enum.TextYAlignment.Center,
                    TextWrapped = config.TextWrapped or false,
                    RichText = config.RichText or false,
                    TextTruncate = config.TextTruncate or Enum.TextTruncate.None
                }, Label)

                local labelAPI = {
                    Set = function(text)
                        Text.Text = toString(text)
                    end,
                    Get = function()
                        return Text.Text
                    end,
                    SetColor = function(color)
                        Text.TextColor3 = color
                    end,
                    SetSize = function(size)
                        Text.TextSize = size
                    end,
                    SetAlignment = function(xAlign, yAlign)
                        Text.TextXAlignment = xAlign or Text.TextXAlignment
                        Text.TextYAlignment = yAlign or Text.TextYAlignment
                    end,
                    Destroy = function()
                        Label:Destroy()
                    end
                }

                -- Optional: background color if specified
                if config.BackgroundColor3 then
                    Label.BackgroundTransparency = 0
                    Label.BackgroundColor3 = config.BackgroundColor3
                    Corner(Label, config.CornerRadius or 6)
                end

                return labelAPI
            end

			function sectionAPI:CreateDivider(config)
				config = config or {}
				local height = config.Height or 1
				local color = config.Color or ThemeColor.Border
				local transparency = config.Transparency or 0.5
				local padding = config.Padding or 8

				local Divider = self.CreateElement(height + (padding * 2), "Divider")
				Divider.BackgroundTransparency = 1

				local Line = Create("Frame", {
					Name = "DividerLine",
					Size = UDim2.new(1, -padding * 2, 0, height),
					Position = UDim2.fromOffset(padding, padding),
					BackgroundColor3 = color,
					BackgroundTransparency = transparency,
					BorderSizePixel = 0
				}, Divider)

				Corner(Line, height / 2)

				local dividerAPI = {
					SetColor = function(c)
						Line.BackgroundColor3 = c
					end,
					SetTransparency = function(t)
						Line.BackgroundTransparency = t
					end,
					SetHeight = function(h)
						Line.Size = UDim2.new(1, -padding * 2, 0, h)
						Divider.Size = UDim2.new(1, -11, 0, h + (padding * 2))
						Corner(Line, h / 2)
					end,
					Destroy = function()
						Divider:Destroy()
					end
				}

				return dividerAPI
			end

			function sectionAPI:CreateDropdown(config)
					config = config or {}
					local Options = config.Options or {}
					local CurrentOption = config.CurrentOption
					local MultiSelect = config.MultiSelect or false
					local Callback = config.Callback

					-- Normalize options to {Name, Value} format
					local function normalizeOptions(opts)
						local normalized = {}
						for i, opt in ipairs(opts) do
							if type(opt) == "table" then
								table.insert(normalized, {Name = opt.Name or tostring(opt.Value or opt), Value = opt.Value or opt.Name or tostring(opt)})
							else
								table.insert(normalized, {Name = tostring(opt), Value = opt})
							end
						end
						return normalized
					end

					Options = normalizeOptions(Options)

					-- Initialize CurrentOption based on option format
					if MultiSelect then
						if type(CurrentOption) ~= "table" then
							CurrentOption = {}
						end
						local newCurrent = {}
						for _, opt in ipairs(Options) do
							if CurrentOption[opt.Value] == true or CurrentOption[opt.Name] == true then
								newCurrent[opt.Value] = true
							end
						end
						CurrentOption = newCurrent
					else
						if CurrentOption == nil and #Options > 0 then
							CurrentOption = Options[1].Value
						elseif CurrentOption ~= nil then
							local found = false
							for _, opt in ipairs(Options) do
								if opt.Value == CurrentOption or opt.Name == CurrentOption then
									CurrentOption = opt.Value
									found = true
									break
								end
							end
							if not found then
								CurrentOption = #Options > 0 and Options[1].Value or nil
							end
						end
					end

					-- Selection highlight color (lighter accent for visibility)
					local SelectionHighlight = Color3.fromRGB(
						math.min(255, math.floor(ThemeColor.Accent.R * 255 + 60)),
						math.min(255, math.floor(ThemeColor.Accent.G * 255 + 60)),
						math.min(255, math.floor(ThemeColor.Accent.B * 255 + 60))
					)

					-- Layout constants
					local LABEL_HEIGHT = 24
					local LABEL_GAP = 2
					local BUTTON_HEIGHT = 25
					local BUTTON_GAP = 4
					local OPTION_HEIGHT = 24
					local OPTION_GAP = 4
					local BOTTOM_PADDING = 10
					local SEARCH_BAR_HEIGHT = 25
					local MAX_OPTIONS_HEIGHT = 200 -- Max height of scrollable options area

					-- Calculate collapsed height
					local collapsedHeight = LABEL_HEIGHT + LABEL_GAP + BUTTON_HEIGHT + BOTTOM_PADDING
					-- Expanded height includes search bar (calculated dynamically)

					-- Main element frame - goes in the section's ElementsContainer
					local ElementFrame = self.CreateElement(collapsedHeight, "Dropdown_" .. tostring(config.Name or "Dropdown"))
					ElementFrame.BackgroundColor3 = ThemeColor.Secondary
					ElementFrame.ClipsDescendants = true
					Corner(ElementFrame, 8)

					-- Label
					Create("TextLabel", {
						Name = "DropdownLabel",
						Position = UDim2.fromOffset(12, 4),
						Size = UDim2.new(1, -24, 0, LABEL_HEIGHT),
						BackgroundTransparency = 1,
						Text = config.Name or "Dropdown",
						TextColor3 = ThemeColor.Text,
						TextSize = 13,
						Font = Enum.Font.GothamMedium,
						TextXAlignment = Enum.TextXAlignment.Left
					}, ElementFrame)

					-- Dropdown button (shows current selection)
					local Button = Create("TextButton", {
						Name = "DropdownButton",
						Position = UDim2.fromOffset(10, LABEL_HEIGHT + LABEL_GAP),
						Size = UDim2.new(1, -20, 0, BUTTON_HEIGHT),
						BackgroundColor3 = ThemeColor.Element,
						Text = "",
						TextColor3 = ThemeColor.Text,
						TextSize = 11,
						Font = Enum.Font.Gotham,
						AutoButtonColor = false,
						TextXAlignment = Enum.TextXAlignment.Left,
						TextTruncate = Enum.TextTruncate.AtEnd,
						ZIndex = 2
					}, ElementFrame)

					Corner(Button, 6)
					Create("UIPadding", {PaddingLeft = UDim.new(0, 12)}, Button)

					-- Arrow indicator
					local Arrow = Create("TextLabel", {
						Name = "DropdownArrow",
						Size = UDim2.fromOffset(20, 20),
						Position = UDim2.new(1, -24, 0.5, 0),
						AnchorPoint = Vector2.new(0, 0.5),
						BackgroundTransparency = 1,
						Text = "▼",
						TextColor3 = ThemeColor.Muted,
						TextSize = 10,
						Font = Enum.Font.GothamBold,
						ZIndex = 2
					}, Button)

					-- Options container (inside ElementFrame, below button) - ScrollingFrame for many options
					local OptionsContainer = Create("ScrollingFrame", {
						Name = "OptionsContainer",
						Position = UDim2.fromOffset(10, LABEL_HEIGHT + LABEL_GAP + BUTTON_HEIGHT + BUTTON_GAP),
						Size = UDim2.new(1, -20, 0, 0),
						BackgroundTransparency = 1,
						Visible = false,
						ClipsDescendants = true,
						ScrollBarThickness = 0, -- No scrollbar
						ScrollingDirection = Enum.ScrollingDirection.Y,
						CanvasSize = UDim2.new(0, 0, 0, 0),
						AutomaticCanvasSize = Enum.AutomaticSize.Y
					}, ElementFrame)

					-- Search bar
					local SearchBar = Create("TextBox", {
						Name = "DropdownSearchBar",
						Size = UDim2.new(1.006, -20, 0, SEARCH_BAR_HEIGHT),
						Position = UDim2.fromOffset(0, 0),
						BackgroundColor3 = ThemeColor.Element,
						Text = "",
						PlaceholderText = "Search...",
						PlaceholderColor3 = ThemeColor.Muted,
						TextColor3 = ThemeColor.Text,
						TextSize = 11,
						Font = Enum.Font.Gotham,
						ClearTextOnFocus = false,
						TextXAlignment = Enum.TextXAlignment.Left,
						LayoutOrder = -1, -- Always at top
					}, OptionsContainer)

					Corner(SearchBar, 6)
					Create("UIPadding", {PaddingLeft = UDim.new(0, 12), PaddingRight = UDim.new(0, 12)}, SearchBar)
					Stroke(SearchBar, ThemeColor.Border, 0.5)

					local OptionsLayout = Create("UIListLayout", {
						Padding = UDim.new(0, OPTION_GAP),
						SortOrder = Enum.SortOrder.LayoutOrder
					}, OptionsContainer)

					-- Search filtering
					local function filterOptions(searchText)
						searchText = searchText:lower()
						for _, child in ipairs(OptionsContainer:GetChildren()) do
							if child:IsA("TextButton") then
								local optName = child.Text:lower():gsub("^%s+", "")
								local matches = searchText == "" or optName:find(searchText, 1, true)
								child.Visible = matches
							end
						end
					end

					SearchBar:GetPropertyChangedSignal("Text"):Connect(function()
						filterOptions(SearchBar.Text)
					end)

					local expanded = false
					local outsideConnection = nil

					-- Helper: get display text for current selection
					local function getDisplayText()
						if MultiSelect then
							local selected = {}
							for _, opt in ipairs(Options) do
								if CurrentOption[opt.Value] then
									table.insert(selected, opt.Name)
								end
							end
							return #selected > 0 and table.concat(selected, ", ") or "None"
						else
							if CurrentOption == nil then return "None" end
							for _, opt in ipairs(Options) do
								if opt.Value == CurrentOption then
									return opt.Name
								end
							end
							return tostring(CurrentOption)
						end
					end

					-- Helper: update all option highlights
					local function updateHighlights()
						for _, child in ipairs(OptionsContainer:GetChildren()) do
							if child:IsA("TextButton") then
								local optValue = child:GetAttribute("OptionValue")
								local isSelected = false
								if MultiSelect then
									isSelected = CurrentOption[optValue] == true
								else
									isSelected = CurrentOption == optValue
								end

								if isSelected then
									Tween(child, {BackgroundTransparency = 0.7, BackgroundColor3 = SelectionHighlight})
								else
									Tween(child, {BackgroundTransparency = 1})
								end
							end
						end
					end

					-- Expand/collapse logic
					local function SetExpanded(state)
						expanded = state

						if state then
							OptionsContainer.Visible = true
							SearchBar.Text = "" -- Clear search on open
							filterOptions("") -- Show all options

							-- Full options height (AbsoluteSize is reliable once visible)
							local optionsHeight = OptionsContainer.AbsoluteSize.Y
							if optionsHeight <= 0 then
								-- Fallback: compute manually
								optionsHeight = 0
								for _, child in ipairs(OptionsContainer:GetChildren()) do
									if child:IsA("TextButton") then
										optionsHeight = optionsHeight + OPTION_HEIGHT + OPTION_GAP
									end
								end
								if optionsHeight > 0 then optionsHeight -= OPTION_GAP end
							end

							-- Cap at max height for scrolling
							optionsHeight = math.min(optionsHeight, MAX_OPTIONS_HEIGHT)

							local totalHeight = collapsedHeight + BUTTON_GAP + optionsHeight

							-- Start from collapsed height so the tween is smooth even if interrupted
							ElementFrame.Size = UDim2.new(1, -5, 0, collapsedHeight)
							OptionsContainer.Size = UDim2.new(1, -20, 0, optionsHeight)
							Tween(ElementFrame, {Size = UDim2.new(1, -5, 0, totalHeight)}, 0.25)
							Tween(Arrow, {Rotation = 90}, 0.15)

							-- Add click-outside detection for single select
							if not MultiSelect and not outsideConnection then
								outsideConnection = UserInputService.InputBegan:Connect(function(input)
									if input.UserInputType == Enum.UserInputType.MouseButton1 and expanded then
										local mousePos = UserInputService:GetMouseLocation()
										local absPos = ElementFrame.AbsolutePosition
										local absSize = ElementFrame.AbsoluteSize

										-- Check if click is outside the element frame
										if mousePos.X < absPos.X or mousePos.X > absPos.X + absSize.X
										or mousePos.Y < absPos.Y or mousePos.Y > absPos.Y + absSize.Y then
											SetExpanded(false)
										end
									end
								end)
							end
						else
							-- Collapse: shrink the options container AND the frame together
							OptionsContainer.Visible = true -- keep visible during the shrink so the clip looks clean
							Tween(OptionsContainer, {Size = UDim2.new(1, -5, 0, 0)}, 0.25)
							Tween(ElementFrame, {Size = UDim2.new(1, -5, 0, collapsedHeight)}, 0.25)
							Tween(Arrow, {Rotation = 0}, 0.15)

							-- Hide after the animation finishes so nothing pops
							task.delay(0.25, function()
								if not expanded then
									OptionsContainer.Visible = false
								end
							end)

							-- Clean up click-outside connection
							if outsideConnection then
								outsideConnection:Disconnect()
								outsideConnection = nil
							end
						end
					end

					-- Function to create option buttons
					local function CreateOption(optName, optValue, layoutOrder)
						local OptButton = Create("TextButton", {
							Name = "Option_" .. tostring(optName),
							Size = UDim2.new(0.969, 0, 0, OPTION_HEIGHT),
							BackgroundTransparency = 1,
							Text = "  " .. tostring(optName),
							TextColor3 = ThemeColor.Text,
							TextSize = 11,
							Font = Enum.Font.Gotham,
							AutoButtonColor = false,
							TextXAlignment = Enum.TextXAlignment.Left,
							LayoutOrder = layoutOrder
						}, OptionsContainer)

						-- Store the value as an attribute for reliable comparison
						OptButton:SetAttribute("OptionValue", optValue)

						Corner(OptButton, 4)

						-- Initial highlight
						local isSelected = false
						if MultiSelect then
							isSelected = CurrentOption[optValue] == true
						else
							isSelected = CurrentOption == optValue
						end

						if isSelected then
							OptButton.BackgroundTransparency = 0.7
							OptButton.BackgroundColor3 = SelectionHighlight
						end

						-- Hover effects: check CurrentOption directly so it never goes stale
						-- (a closure-captured isSelected becomes outdated after Set() is called)
						OptButton.MouseEnter:Connect(function()
							local isSel = MultiSelect and CurrentOption[optValue] == true or CurrentOption == optValue
							if not isSel then
								Tween(OptButton, {BackgroundTransparency = 0.9, BackgroundColor3 = ThemeColor.Accent})
							end
						end)
						OptButton.MouseLeave:Connect(function()
							local isSel = MultiSelect and CurrentOption[optValue] == true or CurrentOption == optValue
							if not isSel then
								Tween(OptButton, {BackgroundTransparency = 1})
							end
						end)

						OptButton.MouseButton1Click:Connect(function()
							if MultiSelect then
								CurrentOption[optValue] = not CurrentOption[optValue]
								isSelected = CurrentOption[optValue]

								local selected = {}
								for _, opt in ipairs(Options) do
									if CurrentOption[opt.Value] then
										table.insert(selected, opt.Name)
									end
								end
								Button.Text = #selected > 0 and table.concat(selected, ", ") or "None"

								-- Update visual
								if isSelected then
									Tween(OptButton, {BackgroundTransparency = 0.7, BackgroundColor3 = SelectionHighlight})
								else
									Tween(OptButton, {BackgroundTransparency = 1})
								end
							else
								-- Single select: highlight the clicked option first, then close smoothly
								CurrentOption = optValue
								Button.Text = optName
								isSelected = true

								-- Instantly flash the highlight so it's visible before any tween
								OptButton.BackgroundTransparency = 0.4
								OptButton.BackgroundColor3 = SelectionHighlight
								-- Then settle into the resting selected look
								Tween(OptButton, {BackgroundTransparency = 0.7, BackgroundColor3 = SelectionHighlight}, 0.15)

								-- Dim all other options
								for _, child in ipairs(OptionsContainer:GetChildren()) do
									if child:IsA("TextButton") and child ~= OptButton then
										Tween(child, {BackgroundTransparency = 1}, 0.15)
									end
								end

								-- Let the user see the highlight, then close
								task.delay(0.35, function()
									if expanded then
										SetExpanded(false)
									end
								end)
							end

							if Callback then
								task.spawn(Callback, CurrentOption)
							end
						end)
					end

					-- Create initial options
					for i, opt in ipairs(Options) do
						CreateOption(opt.Name, opt.Value, i)
					end

					Button.Text = getDisplayText()

					Button.MouseButton1Click:Connect(function()
						SetExpanded(not expanded)
					end)

					-- Return API
					return {
						Set = function(val)
							if MultiSelect then
								CurrentOption = val or {}
								-- Normalize to Value keys
								local normalized = {}
								for _, opt in ipairs(Options) do
									if CurrentOption[opt.Value] == true or CurrentOption[opt.Name] == true then
										normalized[opt.Value] = true
									end
								end
								CurrentOption = normalized
								Button.Text = getDisplayText()
							else
								-- Find matching option
								local found = false
								if val ~= nil then
									for _, opt in ipairs(Options) do
										if opt.Value == val or opt.Name == val then
											CurrentOption = opt.Value
											found = true
											break
										end
									end
								end
								if not found then
									CurrentOption = nil
								end
								Button.Text = getDisplayText()
							end
							updateHighlights()
						end,
						Get = function()
							if MultiSelect then
								-- Return both Name and Value for convenience
								local result = {}
								for _, opt in ipairs(Options) do
									if CurrentOption[opt.Value] then
										result[opt.Name] = true
										result[opt.Value] = true
									end
								end
								return result
							else
								return CurrentOption
							end
						end,
						Refresh = function(newOptions)
							Options = normalizeOptions(newOptions or {})
							CurrentOption = MultiSelect and {} or (#Options > 0 and Options[1].Value or nil)
							Button.Text = getDisplayText()

							-- Clear and rebuild
							for _, child in ipairs(OptionsContainer:GetChildren()) do
								if child:IsA("TextButton") then child:Destroy() end
							end
							for i, opt in ipairs(Options) do
								CreateOption(opt.Name, opt.Value, i)
							end
							updateHighlights()
						end,
						SetExpanded = SetExpanded,
						IsExpanded = function() return expanded end,
						Destroy = function()
							if outsideConnection then
								outsideConnection:Disconnect()
								outsideConnection = nil
							end
							ElementFrame:Destroy()
						end
					}
				end

				return sectionAPI
			end

		-- Tab-level CreateSection - creates section on the page
		function Tab:CreateSection(name)
			return CreateSection(name, Page)
		end

		Tab.Button = TabButton
		Tab.Page = Page

		TabButton.MouseButton1Click:Connect(function()
			Tab:Select()
		end)

		table.insert(Window.Tabs, Tab)

		if #Window.Tabs == 1 then
			Tab:Select()
		end

		return Tab
	end

	function Window:Destroy()
		Main:Destroy()
	end

	function Window:Toggle()
		if Window.ToggleUI then
			Window.ToggleUI()
		else
			Main.Visible = not Main.Visible
		end
	end

	Window.CreateTab = CreateTab
	Window.Main = Main

	UserInputService.InputBegan:Connect(function(input, processed)
		if not processed and input.KeyCode == Enum.KeyCode.RightShift then
			if Window.ToggleUI then
				Window.ToggleUI()
			else
				Main.Visible = not Main.Visible
			end
		end
	end)

	return Window
end

function SmoothUI.new()
	local existing = PlayerGui:FindFirstChild("SmoothUILibrary")
	if existing then
		existing:Destroy()
	end

	local self = setmetatable({}, SmoothUI)

	self.ScreenGui = Create("ScreenGui", {
		Name = "SmoothUILibrary",
		ResetOnSpawn = false,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
		IgnoreGuiInset = true
	}, PlayerGui)

	return self
end

return SmoothUI