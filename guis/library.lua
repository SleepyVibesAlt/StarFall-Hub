local SmoothUI = {}
SmoothUI.__index = SmoothUI

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
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")

local Player = Players.LocalPlayer
local PlayerGui = Player:WaitForChild("PlayerGui")

-- ==========================================
-- SAVE SYSTEM - Cross Environment Support
-- ==========================================
local SaveSystem = {}
SaveSystem.__index = SaveSystem

-- Detect environment
local isExecutor = (writefile and readfile and listfiles and delfile and isfile) ~= nil
local isStudio = RunService:IsStudio()

-- Mock file system for Studio
local studioFileSystem = {}

local function getFolder(folderName)
	folderName = folderName or "StarFallHub"
	if isExecutor then
		return folderName
	else
		if not studioFileSystem[folderName] then
			studioFileSystem[folderName] = {}
		end
		return studioFileSystem[folderName]
	end
end

function SaveSystem.WriteFile(folder, fileName, content)
	local fullPath = folder .. "/" .. fileName
	if isExecutor then
		if not isfolder(folder) then makefolder(folder) end
		writefile(fullPath, content)
	else
		local fs = getFolder(folder)
		fs[fileName] = content
	end
end

function SaveSystem.ReadFile(folder, fileName)
	local fullPath = folder .. "/" .. fileName
	if isExecutor then
		if isfile(fullPath) then
			return readfile(fullPath)
		end
		return nil
	else
		local fs = getFolder(folder)
		return fs[fileName]
	end
end

function SaveSystem.ListFiles(folder)
	if isExecutor then
		if not isfolder(folder) then return {} end
		local files = listfiles(folder)
		local result = {}
		for _, f in ipairs(files) do
			local name = f:match("([^/\\]+)$")
			if name and name:match("%.json$") then
				table.insert(result, name)
			end
		end
		return result
	else
		local fs = getFolder(folder)
		local result = {}
		for name, _ in pairs(fs) do
			if name:match("%.json$") then
				table.insert(result, name)
			end
		end
		return result
	end
end

function SaveSystem.DeleteFile(folder, fileName)
	local fullPath = folder .. "/" .. fileName
	if isExecutor then
		if isfile(fullPath) then delfile(fullPath) end
	else
		local fs = getFolder(folder)
		fs[fileName] = nil
	end
end

function SaveSystem.FolderExists(folder)
	if isExecutor then
		return isfolder(folder)
	else
		return studioFileSystem[folder] ~= nil
	end
end

local Theme = {
	Background = Color3.fromRGB(18, 18, 24),
	Secondary = Color3.fromRGB(26, 26, 34),
	Element = Color3.fromRGB(34, 34, 44),
	Accent = Color3.fromRGB(130, 90, 255),
	Text = Color3.fromRGB(240, 240, 245),
	Muted = Color3.fromRGB(145, 145, 160),
	Border = Color3.fromRGB(48, 48, 60)
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

local function Stroke(parent, color, transparency)
	Create("UIStroke", {
		Color = color or Theme.Border,
		Transparency = transparency or 0,
		Thickness = 1
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
		Position = UDim2.new(1, 300, 1, -80),
		AnchorPoint = Vector2.new(1, 1),
		BackgroundColor3 = Theme.Secondary,
		BorderSizePixel = 0,
		Text = "",
		AutoButtonColor = false
	}, self.ScreenGui)

	Corner(notification, 8)

	-- Title
	Create("TextLabel", {
		Name = "TitleLabel",
		Position = UDim2.fromOffset(12, 4),
		Size = UDim2.new(1, -24, 0, 20),
		BackgroundTransparency = 1,
		Text = toString(title),
		TextColor3 = Theme.Text,
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
		TextColor3 = Theme.Muted,
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
		TextColor3 = Theme.Muted,
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
			Position = UDim2.new(1, 300, 1, -80)
		}, 0.25)

		task.wait(0.3)
		notification:Destroy()
	end

	-- Click to dismiss
	notification.MouseButton1Click:Connect(dismiss)

	-- Slide in horizontally
	Tween(notification, {
		Position = UDim2.new(1, -20, 1, -80)
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
		BackgroundColor3 = Theme.Background,
		BorderSizePixel = 0
	}, self.ScreenGui)

	Corner(Main, 12)
	Stroke(Main)

	local Topbar = Create("Frame", {
		Name = "Topbar",
		Size = UDim2.new(1, 0, 0, 45),
		BackgroundColor3 = Theme.Secondary,
		BorderSizePixel = 0
	}, Main)

	Corner(Topbar, 12)

	Create("TextLabel", {
		Name = "WindowTitle",
		Position = UDim2.fromOffset(16, 0),
		Size = UDim2.new(1, -32, 1, 0),
		BackgroundTransparency = 1,
		Text = toString(config.Title or "Smooth UI"),
		TextColor3 = Theme.Text,
		TextSize = 16,
		Font = Enum.Font.GothamBold,
		TextXAlignment = Enum.TextXAlignment.Left
	}, Topbar)

	Create("Frame", {
		Name = "WindowTitleBackground",
		Position = UDim2.new(0, 0, 0, 16),
		Size = UDim2.new(1.05, -32, 0.639999986, 0),
		BackgroundColor3 = Theme.Secondary,
		BorderSizePixel = 0,
		ZIndex = 0
	}, Topbar)

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
		BackgroundColor3 = Theme.Secondary,
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
			BackgroundColor3 = Theme.Element,
			BackgroundTransparency = 1,
			Text = toString(TabName or "Tab"),
			TextColor3 = Theme.Muted,
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
			ScrollBarImageColor3 = Theme.Accent,
			CanvasSize = UDim2.new(),
			AutomaticCanvasSize = Enum.AutomaticSize.Y,
			Visible = false
		}, Content)

		Create("UIListLayout", {
			Name = "PageListLayout",
			Padding = UDim.new(0, 8),
			SortOrder = Enum.SortOrder.LayoutOrder
		}, Page)

		Create("UIPadding", {
			Name = "PagePadding",
			PaddingTop = UDim.new(0, 3),
			PaddingRight = UDim.new(0, 5)
		}, Page)

		function Tab:Select()
			for _, other in pairs(Window.Tabs) do
				other.Page.Visible = false
				Tween(other.Button, {
					BackgroundTransparency = 1,
					TextColor3 = Theme.Muted
				})
			end

			Page.Visible = true

			Tween(TabButton, {
				BackgroundTransparency = 0,
				BackgroundColor3 = Theme.Accent,
				TextColor3 = Theme.Text
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
				TextColor3 = Theme.Accent,
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
				TextColor3 = Theme.Accent,
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
				SortOrder = Enum.SortOrder.LayoutOrder
			}, ElementsContainer)

			local expanded = true

			local function SetExpanded(state)
				expanded = state
				ElementsContainer.Visible = state
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
						Size = UDim2.new(1, -5, 0, height),
						BackgroundColor3 = Theme.Secondary,
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
					TextColor3 = Theme.Text,
					TextSize = 13,
					Font = Enum.Font.GothamMedium,
					AutoButtonColor = false
				}, Button)

				Text.MouseEnter:Connect(function()
					Tween(Button, {BackgroundColor3 = Theme.Element})
				end)

				Text.MouseLeave:Connect(function()
					Tween(Button, {BackgroundColor3 = Theme.Secondary})
				end)

				Text.MouseButton1Click:Connect(function()
					if config.Callback then
						task.spawn(config.Callback)
					end
				end)
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
					TextColor3 = Theme.Text,
					TextSize = 13,
					Font = Enum.Font.GothamMedium,
					TextXAlignment = Enum.TextXAlignment.Left
				}, Toggle)

				local Switch = Create("Frame", {
					Name = "ToggleSwitch",
					Size = UDim2.fromOffset(36, 19),
					Position = UDim2.new(1, -48, 0.5, 0),
					AnchorPoint = Vector2.new(0, 0.5),
					BackgroundColor3 = Enabled and Theme.Accent or Theme.Element
				}, Toggle)

				Corner(Switch, 20)

				local Knob = Create("Frame", {
					Name = "ToggleKnob",
					Size = UDim2.fromOffset(13, 13),
					Position = Enabled and UDim2.new(1, -16, 0.5, 0)
						or UDim2.new(0, 3, 0.5, 0),
					AnchorPoint = Vector2.new(0, 0.5),
					BackgroundColor3 = Color3.new(1, 1, 1)
				}, Switch)

				Corner(Knob, 20)

				local function Set(value)
					Enabled = value

					Tween(Switch, {
						BackgroundColor3 = Enabled and Theme.Accent or Theme.Element
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

				return {
					Set = Set,
					Get = function() return Enabled end
				}
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
					TextColor3 = Theme.Text,
					TextSize = 13,
					Font = Enum.Font.GothamMedium,
					TextXAlignment = Enum.TextXAlignment.Left
				}, Frame)

				local Bar = Create("Frame", {
					Name = "SliderBar",
					Position = UDim2.fromOffset(12, 29),
					Size = UDim2.new(1, -24, 0, 5),
					BackgroundColor3 = Theme.Element
				}, Frame)

				Corner(Bar, 10)

				local Fill = Create("Frame", {
					Name = "SliderFill",
					Size = UDim2.new((Value - Min) / (Max - Min), 0, 1, 0),
					BackgroundColor3 = Theme.Accent
				}, Bar)

				Corner(Fill, 10)

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

				return {
					Set = Set,
					Get = function() return Value end
				}
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
					TextColor3 = Theme.Text,
					TextSize = 13,
					Font = Enum.Font.GothamMedium,
					TextXAlignment = Enum.TextXAlignment.Left
				}, Frame)

				local Input = Create("TextBox", {
					Name = "TextboxInput",
					Position = UDim2.fromOffset(10, 29),
					Size = UDim2.new(1, -20, 0, 28),
					BackgroundColor3 = Theme.Element,
					Text = "",
					PlaceholderText = config.PlaceholderText or "Enter text...",
					TextColor3 = Theme.Text,
					PlaceholderColor3 = Theme.Muted,
					TextSize = 12,
					Font = Enum.Font.Gotham,
					ClearTextOnFocus = false
				}, Frame)

				Corner(Input, 6)

				Input.FocusLost:Connect(function()
					if config.Callback then
						config.Callback(Input.Text)
					end
				end)

				return Input
			end

			function sectionAPI:CreateDropdown(config)
				local Frame = self.CreateElement(55, "Dropdown_" .. toString(config.Name or "Dropdown"))
				Corner(Frame, 8)

				local Options = config.Options or {}
				local CurrentOption = config.CurrentOption or (Options[1] or "None")
				local MultiSelect = config.MultiSelect or false

				local Label = Create("TextLabel", {
					Name = "DropdownLabel",
					Position = UDim2.fromOffset(12, 4),
					Size = UDim2.new(1, -24, 0, 20),
					BackgroundTransparency = 1,
					Text = toString(config.Name or "Dropdown"),
					TextColor3 = Theme.Text,
					TextSize = 13,
					Font = Enum.Font.GothamMedium,
					TextXAlignment = Enum.TextXAlignment.Left
				}, Frame)

				local Button = Create("TextButton", {
					Name = "DropdownButton",
					Position = UDim2.fromOffset(10, 26),
					Size = UDim2.new(1, -20, 0, 25),
					BackgroundColor3 = Theme.Element,
					Text = toString(CurrentOption),
					TextColor3 = Theme.Text,
					TextSize = 11,
					Font = Enum.Font.Gotham,
					AutoButtonColor = false,
					TextXAlignment = Enum.TextXAlignment.Left,
					TextTruncate = Enum.TextTruncate.AtEnd
				}, Frame)

				Corner(Button, 6)
				Create("UIPadding", {PaddingLeft = UDim.new(0, 8)}, Button)

				local Arrow = Create("TextLabel", {
					Name = "DropdownArrow",
					Size = UDim2.fromOffset(20, 20),
					Position = UDim2.new(1, -24, 0.5, 0),
					AnchorPoint = Vector2.new(0, 0.5),
					BackgroundTransparency = 1,
					Text = "▼",
					TextColor3 = Theme.Muted,
					TextSize = 10,
					Font = Enum.Font.GothamBold
				}, Button)

				local DropdownFrame = Create("Frame", {
					Name = "DropdownList",
					Size = UDim2.new(1, -20, 0, 0),
					Position = UDim2.fromOffset(10, 53),
					BackgroundColor3 = Theme.Secondary,
					BorderSizePixel = 0,
					Visible = false,
					ZIndex = 10,
					ClipsDescendants = true,
					AutomaticSize = Enum.AutomaticSize.Y
				}, Frame)

				Corner(DropdownFrame, 6)
				Create("UIListLayout", {Padding = UDim.new(0, 2), SortOrder = Enum.SortOrder.LayoutOrder}, DropdownFrame)

				local function CreateOption(optName, optValue)
					local OptButton = Create("TextButton", {
						Name = "Option_" .. toString(optName),
						Size = UDim2.new(1, 0, 0, 24),
						BackgroundTransparency = 1,
						Text = "  " .. toString(optName),
						TextColor3 = Theme.Text,
						TextSize = 11,
						Font = Enum.Font.Gotham,
						AutoButtonColor = false,
						TextXAlignment = Enum.TextXAlignment.Left,
						ZIndex = 10
					}, DropdownFrame)

					OptButton.MouseEnter:Connect(function()
						Tween(OptButton, {BackgroundTransparency = 0.8, BackgroundColor3 = Theme.Accent})
					end)
					OptButton.MouseLeave:Connect(function()
						Tween(OptButton, {BackgroundTransparency = 1})
					end)

					OptButton.MouseButton1Click:Connect(function()
						if MultiSelect then
							-- Toggle selection
							CurrentOption[optValue] = not CurrentOption[optValue]
							local selected = {}
							for k, v in pairs(CurrentOption) do
								if v then table.insert(selected, k) end
							end
							Button.Text = #selected > 0 and table.concat(selected, ", ") or "None"
						else
							CurrentOption = optValue
							Button.Text = toString(optName)
							DropdownFrame.Visible = false
							Tween(Arrow, {Rotation = 0}, 0.15)
						end
						if config.Callback then
							config.Callback(MultiSelect and CurrentOption or optValue)
						end
					end)

					if not MultiSelect then
						if CurrentOption == optValue then
							OptButton.BackgroundTransparency = 0.8
							OptButton.BackgroundColor3 = Theme.Accent
						end
					else
						if CurrentOption[optValue] then
							OptButton.BackgroundTransparency = 0.8
							OptButton.BackgroundColor3 = Theme.Accent
						end
					end
				end

				for _, opt in ipairs(Options) do
					if type(opt) == "table" then
						CreateOption(opt.Name, opt.Value)
					else
						CreateOption(opt, opt)
					end
				end

				Button.MouseButton1Click:Connect(function()
					DropdownFrame.Visible = not DropdownFrame.Visible
					Tween(Arrow, {Rotation = DropdownFrame.Visible and 90 or 0}, 0.15)
				end)

				-- Close when clicking outside
				UserInputService.InputBegan:Connect(function(input)
					if input.UserInputType == Enum.UserInputType.MouseButton1 then
						local mousePos = UserInputService:GetMouseLocation()
						local absPos = DropdownFrame.AbsolutePosition
						local absSize = DropdownFrame.AbsoluteSize
						if DropdownFrame.Visible and (mousePos.X < absPos.X or mousePos.X > absPos.X + absSize.X or mousePos.Y < absPos.Y or mousePos.Y > absPos.Y + absSize.Y) then
							DropdownFrame.Visible = false
							Tween(Arrow, {Rotation = 0}, 0.15)
						end
					end
				end)

				return {
					Set = function(val)
						if MultiSelect then
							CurrentOption = val or {}
							local selected = {}
							for k, v in pairs(CurrentOption) do if v then table.insert(selected, k) end end
							Button.Text = #selected > 0 and table.concat(selected, ", ") or "None"
						else
							CurrentOption = val
							Button.Text = toString(val)
						end
					end,
					Get = function() return CurrentOption end,
					Refresh = function(newOptions)
						Options = newOptions or {}
						-- Clear and rebuild
						for _, child in ipairs(DropdownFrame:GetChildren()) do
							if child:IsA("TextButton") then child:Destroy() end
						end
						for _, opt in ipairs(Options) do
							if type(opt) == "table" then CreateOption(opt.Name, opt.Value) else CreateOption(opt, opt) end
						end
					end
				}
			end

			function sectionAPI:CreateSection(name)
				-- Nested sections - create at page level
				return CreateSection(name, Page)
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
		Main.Visible = not Main.Visible
	end

	-- Save API
	function Window:AddSaveApi(cfg)
		cfg = cfg or {}
		local folderName = cfg.Folder or "StarFallHub"
		local defaultConfig = cfg.DefaultConfig or "default"
		local autoLoad = cfg.AutoLoad ~= false

		-- Create Settings tab if it doesn't exist
		local SettingsTab = nil
		for _, tab in pairs(self.Tabs) do
			if tab.Button and tab.Button.Text == "Settings" then
				SettingsTab = tab
				break
			end
		end
		if not SettingsTab then
			SettingsTab = self:CreateTab("Settings")
		end

		local SaveSection = SettingsTab:CreateSection("Configuration")

		-- Config name input
		local configNameInput = SaveSection:CreateTextbox({
			Name = "Config Name",
			PlaceholderText = "Enter config name...",
			Callback = function(_)
				-- Just store it, used by save/load
			end
		})
		configNameInput.Text = defaultConfig

		-- Config dropdown
		local configDropdown = SaveSection:CreateDropdown({
			Name = "Saved Configs",
			Options = {},
			CurrentOption = defaultConfig,
			Callback = function(selected)
				configNameInput.Text = selected
			end
		})

		local function RefreshConfigs()
			local files = SaveSystem.ListFiles(folderName)
			local options = {}
			for _, f in ipairs(files) do
				local name = f:gsub("%.json$", "")
				table.insert(options, name)
			end
			if #options == 0 then
				options = {"(none)"}
			end
			configDropdown.Refresh(options)
			if #options > 0 and options[1] ~= "(none)" then
				configDropdown.Set(options[1])
				configNameInput.Text = options[1]
			end
		end

		-- Save button
		SaveSection:CreateButton({
			Name = "Save Config",
			Callback = function()
				local name = configNameInput.Text
				if name == "" or name == "(none)" then
					self.Library:Notify("Error", "Enter a config name first", 3)
					return
				end

				-- For now, save _G table (common pattern)
				local success, err = pcall(function()
					SaveSystem.WriteFile(folderName, name .. ".json", HttpService:JSONEncode(_G))
				end)

				if success then
					self.Library:Notify("Saved", "Config '" .. name .. "' saved!", 2)
					RefreshConfigs()
				else
					self.Library:Notify("Error", "Failed to save: " .. tostring(err), 3)
				end
			end
		})

		-- Load button
		SaveSection:CreateButton({
			Name = "Load Config",
			Callback = function()
				local name = configNameInput.Text
				if name == "" or name == "(none)" then
					self.Library:Notify("Error", "Select a config first", 3)
					return
				end

				local content = SaveSystem.ReadFile(folderName, name .. ".json")
				if content then
					local success, data = pcall(function()
						return HttpService:JSONDecode(content)
					end)
					if success and data then
						for k, v in pairs(data) do
							_G[k] = v
						end
						self.Library:Notify("Loaded", "Config '" .. name .. "' loaded!", 2)
						-- Trigger callbacks to update UI
						-- Note: This requires elements to have Get/Set methods
					else
						self.Library:Notify("Error", "Invalid config file", 3)
					end
				else
					self.Library:Notify("Error", "Config not found", 3)
				end
			end
		})

		-- Delete button
		SaveSection:CreateButton({
			Name = "Delete Config",
			Callback = function()
				local name = configNameInput.Text
				if name == "" or name == "(none)" then
					self.Library:Notify("Error", "Select a config first", 3)
					return
				end

				SaveSystem.DeleteFile(folderName, name .. ".json")
				self.Library:Notify("Deleted", "Config '" .. name .. "' deleted", 2)
				RefreshConfigs()
				configNameInput.Text = ""
			end
		})

		-- Refresh button
		SaveSection:CreateButton({
			Name = "Refresh List",
			Callback = function()
				RefreshConfigs()
				self.Library:Notify("Refreshed", "Config list updated", 2)
			end
		})

		if autoLoad then
			task.delay(0.5, RefreshConfigs)
		end

		return {
			Refresh = RefreshConfigs,
			Folder = folderName
		}
	end

	Window.CreateTab = CreateTab
	Window.Main = Main

	UserInputService.InputBegan:Connect(function(input, processed)
		if not processed and input.KeyCode == Enum.KeyCode.RightShift then
			Main.Visible = not Main.Visible
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
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	}, PlayerGui)

	return self
end

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

-- ============ COMBAT TAB ============
local CombatTab = Window:CreateTab("Combat")

local Aimbot = CombatTab:CreateSection("Aimbot")
Aimbot:CreateToggle({Name = "Enabled", CurrentValue = false, Callback = function(v) _G.Aimbot = v end})
Aimbot:CreateToggle({Name = "Team Check", CurrentValue = true, Callback = function(v) _G.TeamCheck = v end})
Aimbot:CreateToggle({Name = "Wall Check", CurrentValue = true, Callback = function(v) _G.WallCheck = v end})

-- Dropdown example for target part selection
Aimbot:CreateDropdown({
    Name = "Target Part",
    Options = {"Head", "Torso", "HumanoidRootPart", "Random"},
    CurrentOption = "Head",
    Callback = function(part) _G.AimbotPart = part end
})

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

-- ============ SETTINGS TAB ============
-- Add Save API (automatically creates Settings tab with full config management)
Window:AddSaveApi({
    Folder = "StarFallHub",
    DefaultConfig = "default",
    AutoLoad = true
})

-- Optional: Add unload button to the created Settings tab
local SettingsTab = nil
for _, tab in pairs(Window.Tabs) do
    if tab.Button and tab.Button.Text == "Settings" then
        SettingsTab = tab
        break
    end
end
if SettingsTab then
    local MiscSection = SettingsTab:CreateSection("Miscellaneous")
    MiscSection:CreateButton({
        Name = "Unload UI",
        Callback = function() Window:Destroy() end
    })
end

-- ============ STARTUP ============
Library:Notify("StarFall Hub", "Loaded! Press RightShift to toggle.", 4)

-- Auto-collapse sections after 10 seconds
task.delay(10, function()
    General:SetExpanded(false)
    Player:SetExpanded(false)
    Aimbot:SetExpanded(false)
    ESP:SetExpanded(false)
end)

return SmoothUI