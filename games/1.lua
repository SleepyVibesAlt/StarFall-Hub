local SaveFolderName = "SavedStructures"

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")
local Player = Players.LocalPlayer
local Grid = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Grid"))
local RequestPlace = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("RequestPlace")
local CellSize = Grid.CellSize

local FileEnabled = type(SaveFolderName) == "string" and SaveFolderName ~= ""
local FileFunctionsAvailable = type(isfile) == "function" and type(readfile) == "function" and type(writefile) == "function" and type(listfiles) == "function"

local Corners = {}
local SelectedBlocks = {}
local Holograms = {}
local CornerMarkers = {}
local GridOrigin
local CursorCell = {x = 0, y = 0, z = 0}
local MoveOffset = {x = 0, y = 0, z = 0}
local RotationSteps = 0
local RotationCenter = {x = 0, z = 0}
local Mode = "FirstCorner"
local CornerMarker
local ConfirmButton
local IsPasting = false
local CancelPaste = false
local SaveData = {}
local SavePrompt
local LoadPanel
local LoadList
local refreshLoadList
local PromptConnection

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "BlockCopyController"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = Player:WaitForChild("PlayerGui")

local Main = Instance.new("Frame")
Main.Size = UDim2.fromOffset(245, 320)
Main.Position = UDim2.new(0, 20, 0.5, -160)
Main.BackgroundColor3 = Color3.fromRGB(22, 25, 34)
Main.BorderSizePixel = 0
Main.Parent = ScreenGui

local MainCorner = Instance.new("UICorner")
MainCorner.CornerRadius = UDim.new(0, 12)
MainCorner.Parent = Main

local MainStroke = Instance.new("UIStroke")
MainStroke.Color = Color3.fromRGB(65, 75, 100)
MainStroke.Transparency = 0.25
MainStroke.Thickness = 1
MainStroke.Parent = Main

local TopBar = Instance.new("Frame")
TopBar.Size = UDim2.new(1, 0, 0, 38)
TopBar.BackgroundColor3 = Color3.fromRGB(31, 37, 51)
TopBar.BorderSizePixel = 0
TopBar.Parent = Main

local TopCorner = Instance.new("UICorner")
TopCorner.CornerRadius = UDim.new(0, 12)
TopCorner.Parent = TopBar

local TopCover = Instance.new("Frame")
TopCover.Size = UDim2.new(1, 0, 0, 12)
TopCover.Position = UDim2.new(0, 0, 1, -12)
TopCover.BackgroundColor3 = TopBar.BackgroundColor3
TopCover.BorderSizePixel = 0
TopCover.Parent = TopBar

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, -20, 1, 0)
Title.Position = UDim2.fromOffset(12, 0)
Title.BackgroundTransparency = 1
Title.Text = "Building Assistance."
Title.TextColor3 = Color3.fromRGB(225, 232, 245)
Title.TextSize = 13
Title.Font = Enum.Font.GothamBold
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.Parent = TopBar

local CloseButton = Instance.new("TextButton")
CloseButton.Name = "CloseButton"
CloseButton.Size = UDim2.fromOffset(25, 25)
CloseButton.Position = UDim2.new(1, -31, 0, 6)
CloseButton.BackgroundTransparency = 1
CloseButton.BorderSizePixel = 0
CloseButton.Text = "×"
CloseButton.TextColor3 = Color3.fromRGB(255, 255, 255)
CloseButton.TextTransparency = 0.1
CloseButton.TextSize = 21
CloseButton.Font = Enum.Font.Gotham
CloseButton.ZIndex = 5
CloseButton.Parent = TopBar

local Status = Instance.new("TextLabel")
Status.Size = UDim2.new(1, -20, 0, 25)
Status.Position = UDim2.fromOffset(10, 43)
Status.BackgroundTransparency = 1
Status.Text = "First corner"
Status.TextColor3 = Color3.fromRGB(130, 190, 255)
Status.TextSize = 12
Status.Font = Enum.Font.GothamMedium
Status.Parent = Main

local Coordinates = Instance.new("TextLabel")
Coordinates.Size = UDim2.new(1, -20, 0, 20)
Coordinates.Position = UDim2.fromOffset(10, 67)
Coordinates.BackgroundTransparency = 1
Coordinates.Text = "X: 0   Y: 0   Z: 0"
Coordinates.TextColor3 = Color3.fromRGB(190, 198, 215)
Coordinates.TextSize = 11
Coordinates.Font = Enum.Font.Gotham
Coordinates.Parent = Main

local function createButton(name, text, position, size, color, callback)
	local button = Instance.new("TextButton")
	button.Name = name
	button.Size = size
	button.Position = position
	button.BackgroundColor3 = color
	button.BorderSizePixel = 0
	button.Text = text
	button.TextColor3 = Color3.fromRGB(245, 248, 255)
	button.TextSize = 19
	button.Font = Enum.Font.GothamBold
	button.AutoButtonColor = true
	button.Parent = Main

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 8)
	corner.Parent = button

	local stroke = Instance.new("UIStroke")
	stroke.Color = Color3.fromRGB(255, 255, 255)
	stroke.Transparency = 0.88
	stroke.Thickness = 1
	stroke.Parent = button

	button.Activated:Connect(callback)
	return button
end

local function updateCoordinates()
	Coordinates.Text = string.format("X: %d   Y: %d   Z: %d", CursorCell.x, CursorCell.y, CursorCell.z)
end

local function getWorldPosition(cell)
	return Grid.cellToWorld(GridOrigin, cell)
end

local function getCell(part)
	local key = part:GetAttribute("CellKey")

	if type(key) ~= "string" then
		return nil
	end

	local success, cell = pcall(function()
		return Grid.fromKey(key)
	end)

	if success then
		return cell
	end

	return nil
end

local function getBlockInfo(part)
	local machineId = part:GetAttribute("MachineId")

	if machineId ~= nil then
		return tostring(machineId), true
	end

	local name = part:GetAttribute("BlockName")

	if name ~= nil then
		return tostring(name), false
	end

	local blockId = part:GetAttribute("BlockId")

	if blockId ~= nil then
		return tostring(blockId), false
	end

	return part.Name, false
end

local function findGridOrigin()
	local character = Player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")

	if not root then
		return nil
	end

	local closestPart
	local closestDistance = math.huge
	local closestCell

	for _, instance in ipairs(workspace:GetDescendants()) do
		if not instance:IsA("BasePart") then
			continue
		end

		if type(instance:GetAttribute("CellKey")) ~= "string" then
			continue
		end

		local blockName, isMachine = getBlockInfo(instance)

		if not blockName or blockName == "" then
			continue
		end

		if not isMachine and instance:GetAttribute("BlockName") == nil and instance:GetAttribute("BlockId") == nil then
			continue
		end

		local cell = getCell(instance)

		if not cell then
			continue
		end

		local distance = (instance.Position - root.Position).Magnitude

		if distance < closestDistance then
			closestDistance = distance
			closestPart = instance
			closestCell = cell
		end
	end

	if not closestPart then
		return nil
	end

	return closestPart.Position - Vector3.new(
		closestCell.x * CellSize,
		closestCell.y * CellSize,
		closestCell.z * CellSize
	)
end

local function getPlayerGridCell(height)
	local character = Player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")

	if not root or not GridOrigin then
		return nil
	end

	return Grid.worldToCell(
		GridOrigin,
		root.Position + Vector3.new(0, height or CellSize, 0)
	)
end

local function createMarker(cell, color, transparency)
	local marker = Instance.new("Part")
	marker.Name = "BlockCopyCornerMarker"
	marker.Size = Vector3.new(CellSize, CellSize, CellSize)
	marker.Anchored = true
	marker.CanCollide = false
	marker.CanTouch = false
	marker.CanQuery = false
	marker.Material = Enum.Material.ForceField
	marker.Color = color
	marker.Transparency = transparency or 0.45
	marker.Position = getWorldPosition(cell)
	marker.Parent = workspace

	local selection = Instance.new("SelectionBox")
	selection.Adornee = marker
	selection.Color3 = color
	selection.LineThickness = 0.06
	selection.SurfaceTransparency = 1
	selection.Parent = marker

	return marker
end

local function updateCornerMarker()
	if not GridOrigin then
		return
	end

	if not CornerMarker then
		CornerMarker = createMarker(CursorCell, Color3.fromRGB(65, 170, 255), 0.45)
	end

	CornerMarker.Position = getWorldPosition(CursorCell)
end

local function clearMarkers()
	for _, marker in ipairs(CornerMarkers) do
		marker:Destroy()
	end

	table.clear(CornerMarkers)

	if CornerMarker then
		CornerMarker:Destroy()
		CornerMarker = nil
	end
end

local function clearHolograms()
	for _, hologram in ipairs(Holograms) do
		if hologram.preview then
			hologram.preview:Destroy()
		end
	end

	table.clear(Holograms)
end

local function rotateCell(cell, steps)
	local x = cell.x * 2 - RotationCenter.x
	local z = cell.z * 2 - RotationCenter.z

	for _ = 1, steps % 4 do
		x, z = z, -x
	end

	return {
		x = (x + RotationCenter.x) / 2,
		y = cell.y,
		z = (z + RotationCenter.z) / 2
	}
end

local function getTargetCell(data)
	local rotatedCell = rotateCell(data.cell, RotationSteps)

	return {
		x = rotatedCell.x + MoveOffset.x,
		y = rotatedCell.y + MoveOffset.y,
		z = rotatedCell.z + MoveOffset.z
	}
end

local function updateHolograms()
	for _, data in ipairs(Holograms) do
		if not data.preview then
			continue
		end

		local targetCell = getTargetCell(data)
		local targetPosition = Grid.cellToWorld(GridOrigin, targetCell)
		local rotation = CFrame.Angles(0, math.rad(90 * RotationSteps), 0) * data.rotation
		local targetCFrame = CFrame.new(targetPosition) * rotation

		if data.preview:IsA("Model") then
			data.preview:PivotTo(targetCFrame * (data.pivotOffset or CFrame.new()))
		else
			data.preview.CFrame = targetCFrame
		end

		data.preview:SetAttribute("CellKey", Grid.key(targetCell))

		if data.isMachine then
			data.preview:SetAttribute("MachineId", data.blockName)
		else
			data.preview:SetAttribute("BlockName", data.blockName)
		end
	end
end

local function move(x, y, z)
	if IsPasting then
		return
	end

	if Mode == "FirstCorner" or Mode == "SecondCorner" then
		CursorCell.x += x
		CursorCell.y += y
		CursorCell.z += z
		updateCoordinates()
		updateCornerMarker()
	elseif Mode == "MoveHologram" then
		MoveOffset.x += x
		MoveOffset.y += y
		MoveOffset.z += z
		updateHolograms()

		Coordinates.Text = string.format(
			"X: %d   Y: %d   Z: %d",
			MoveOffset.x,
			MoveOffset.y,
			MoveOffset.z
		)
	end
end

local function rotate(steps)
	if Mode ~= "MoveHologram" or IsPasting then
		return
	end

	RotationSteps = (RotationSteps + steps) % 4
	updateHolograms()

	Status.Text = "Rotation: " .. tostring(RotationSteps * 90) .. "°"
end

local function getSavePath(name)
	return SaveFolderName .. "/" .. name .. ".json"
end

local function ensureSaveFolder()
	if type(isfolder) == "function" and isfolder(SaveFolderName) then
		return true
	end

	if type(makefolder) ~= "function" then
		return false
	end

	local success = pcall(function()
		makefolder(SaveFolderName)
	end)

	if success then
		return true
	end

	return type(isfolder) == "function" and isfolder(SaveFolderName)
end

local function refreshSaveData()
	table.clear(SaveData)

	if not FileEnabled or not FileFunctionsAvailable then
		return false
	end

	local folderExists = false

	if type(isfolder) == "function" then
		local success, result = pcall(function()
			return isfolder(SaveFolderName)
		end)

		folderExists = success and result == true
	else
		local success, files = pcall(function()
			return listfiles(SaveFolderName)
		end)

		folderExists = success and type(files) == "table"
	end

	if not folderExists then
		return true
	end

	local success, files = pcall(function()
		return listfiles(SaveFolderName)
	end)

	if not success or type(files) ~= "table" then
		return false
	end


	for _, path in ipairs(files) do
		if type(path) ~= "string" then
			continue
		end

		if not path:lower():match("%.json$") then
			continue
		end

		local readSuccess, result = pcall(function()
			return HttpService:JSONDecode(readfile(path))
		end)

		if not readSuccess then
			continue
		end

		if type(result) ~= "table" then
			continue
		end

		if type(result.blocks) ~= "table" then
			continue
		end

		local name = result.name

		if type(name) ~= "string" or name == "" then
			name = path:match("[/\\]([^/\\]+)%.json$")
		end

		if type(name) == "string" and name ~= "" then
			SaveData[name] = result
		else
		end
	end

	return true
end

local function writeSaveFile(name, data)
	if not FileEnabled or not FileFunctionsAvailable then
		return false
	end

	if not ensureSaveFolder() then
		return false
	end

	local path = getSavePath(name)

	local success, encoded = pcall(function()
		return HttpService:JSONEncode(data)
	end)

	if not success then
		return false
	end

	local writeSuccess = pcall(function()
		writefile(path, encoded)
	end)

	return writeSuccess
end

local function findTemplate(blockName, isMachine)
	for _, instance in ipairs(workspace:GetDescendants()) do
		if not instance:IsA("BasePart") then
			continue
		end

		local name, machine = getBlockInfo(instance)

		if name == blockName and machine == isMachine then
			return instance
		end
	end

	return nil
end

local function createPreview(data)
	local template = findTemplate(data.blockName, data.isMachine)
	local hologram
	local pivotOffset

	if template then
		local source = template

		if data.isMachine then
			local artwork = template:FindFirstChild(data.blockName)

			if not artwork or not artwork:IsA("Model") then
				for _, descendant in ipairs(template:GetDescendants()) do
					if descendant:IsA("Model") and descendant.Name == data.blockName then
						artwork = descendant
						break
					end
				end
			end

			if artwork and artwork:IsA("Model") then
				local success, result = pcall(function()
					return artwork:Clone()
				end)

				if success then
					hologram = result
					pivotOffset = template.CFrame:ToObjectSpace(artwork:GetPivot())
				end
			end
		else
			local success, result = pcall(function()
				return source:Clone()
			end)

			if success then
				hologram = result
			end
		end
	end

	if not hologram then
		hologram = Instance.new("Part")
		hologram.Size = Vector3.new(CellSize, CellSize, CellSize)
		hologram.Material = Enum.Material.ForceField
		hologram.Color = data.isMachine and Color3.fromRGB(190, 135, 255) or Color3.fromRGB(65, 170, 255)
	end

	hologram.Name = "BlockCopyHologram"

	if hologram:IsA("BasePart") then
		hologram.Anchored = true
		hologram.CanCollide = false
		hologram.CanTouch = false
		hologram.CanQuery = false
		hologram.Transparency = 0.45
	end

	for _, child in ipairs(hologram:GetDescendants()) do
		if child:IsA("Script") or child:IsA("LocalScript") then
			child:Destroy()
		elseif child:IsA("BasePart") then
			child.Anchored = true
			child.CanCollide = false
			child.CanTouch = false
			child.CanQuery = false
			if child.Transparency < 1 then
				child.Transparency = math.max(child.Transparency, 0.45)
			end
		elseif child:IsA("Decal") or child:IsA("Texture") then
			child.Transparency = math.max(child.Transparency, 0.45)
		elseif child:IsA("PointLight") or child:IsA("SpotLight") or child:IsA("SurfaceLight") then
			child.Enabled = false
		end
	end

	hologram.Parent = workspace

	return hologram, pivotOffset
end

local function buildHolograms(blockData, center, initialOffset, rotationSteps)
	clearHolograms()

	RotationCenter = center
	MoveOffset = initialOffset
	RotationSteps = rotationSteps or 0

	for _, data in ipairs(blockData) do
		local hologram, pivotOffset = createPreview(data)

		table.insert(Holograms, {
			preview = hologram,
			pivotOffset = pivotOffset,
			cell = data.cell,
			blockName = data.blockName,
			isMachine = data.isMachine,
			rotation = data.rotation
		})
	end

	if #Holograms == 0 then
		Status.Text = "No saved blocks found"
		return false
	end

	updateHolograms()

	Mode = "MoveHologram"
	ConfirmButton.Text = "PASTE BLOCKS"
	ConfirmButton.BackgroundColor3 = Color3.fromRGB(45, 175, 110)

	Coordinates.Text = string.format(
		"X: %d   Y: %d   Z: %d",
		MoveOffset.x,
		MoveOffset.y,
		MoveOffset.z
	)

	Status.Text = "Hologram ready"
	return true
end

local function saveCurrentStructure(name)
	if not FileEnabled or not FileFunctionsAvailable then
		Status.Text = "File saving unavailable"
		return false
	end

	if Mode ~= "MoveHologram" or #Holograms == 0 then
		Status.Text = "Create a hologram first"
		return false
	end

	refreshSaveData()

	if SaveData[name] ~= nil then
		Status.Text = "That save name already exists"
		return false
	end

	local minX, minY, minZ = math.huge, math.huge, math.huge
	local maxX, maxY, maxZ = -math.huge, -math.huge, -math.huge

	for _, data in ipairs(Holograms) do
		local cell = data.cell

		minX = math.min(minX, cell.x)
		minY = math.min(minY, cell.y)
		minZ = math.min(minZ, cell.z)
		maxX = math.max(maxX, cell.x)
		maxY = math.max(maxY, cell.y)
		maxZ = math.max(maxZ, cell.z)
	end

	local blocks = {}

	for _, data in ipairs(Holograms) do
		local rx, ry, rz = data.rotation:ToOrientation()

		table.insert(blocks, {
			x = data.cell.x - minX,
			y = data.cell.y - minY,
			z = data.cell.z - minZ,
			name = data.blockName,
			machine = data.isMachine,
			rx = rx,
			ry = ry,
			rz = rz
		})
	end

	local savedData = {
		name = name,
		blocks = blocks,
		width = maxX - minX,
		height = maxY - minY,
		depth = maxZ - minZ,
		rotationSteps = RotationSteps
	}

	if not writeSaveFile(name, savedData) then
		Status.Text = "Could not write save file"
		return false
	end

	SaveData[name] = savedData
	Status.Text = "Saved: " .. name
	return true
end

local function closeSavePrompt()
	if PromptConnection then
		PromptConnection:Disconnect()
		PromptConnection = nil
	end

	if SavePrompt then
		SavePrompt:Destroy()
		SavePrompt = nil
	end
end

local function openSavePrompt()
	if not FileEnabled then
		Status.Text = "Saving is disabled"
		return
	end

	if not FileFunctionsAvailable then
		Status.Text = "Executor file functions unavailable"
		return
	end

	if Mode ~= "MoveHologram" or #Holograms == 0 then
		Status.Text = "Create a hologram first"
		return
	end

	if SavePrompt then
		return
	end

	local isMobile = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled

	SavePrompt = Instance.new("Frame")
	SavePrompt.Name = "SavePrompt"
	SavePrompt.Size = UDim2.fromOffset(270, 125)
	SavePrompt.Position = isMobile and UDim2.new(0.5, -135, 0.38, -62) or UDim2.new(0.5, -135, 0.5, -62)
	SavePrompt.BackgroundColor3 = Color3.fromRGB(27, 32, 44)
	SavePrompt.BorderSizePixel = 0
	SavePrompt.ZIndex = 10
	SavePrompt.Parent = ScreenGui

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 12)
	corner.Parent = SavePrompt

	local stroke = Instance.new("UIStroke")
	stroke.Color = Color3.fromRGB(75, 95, 125)
	stroke.Parent = SavePrompt

	local title = Instance.new("TextLabel")
	title.Size = UDim2.new(1, -20, 0, 28)
	title.Position = UDim2.fromOffset(10, 8)
	title.BackgroundTransparency = 1
	title.Text = "SAVE STRUCTURE"
	title.TextColor3 = Color3.fromRGB(225, 232, 245)
	title.TextSize = 13
	title.Font = Enum.Font.GothamBold
	title.ZIndex = 11
	title.Parent = SavePrompt

	local textBox = Instance.new("TextBox")
	textBox.Name = "SaveNameInput"
	textBox.Size = isMobile and UDim2.fromOffset(1, 1) or UDim2.new(1, -24, 0, 34)
	textBox.Position = isMobile and UDim2.fromOffset(-100, -100) or UDim2.fromOffset(12, 43)
	textBox.BackgroundColor3 = Color3.fromRGB(40, 48, 65)
	textBox.BackgroundTransparency = isMobile and 1 or 0
	textBox.TextTransparency = isMobile and 1 or 0
	textBox.TextColor3 = Color3.fromRGB(245, 248, 255)
	textBox.PlaceholderText = "Enter save name..."
	textBox.PlaceholderColor3 = Color3.fromRGB(145, 155, 175)
	textBox.TextSize = 13
	textBox.Font = Enum.Font.Gotham
	textBox.ClearTextOnFocus = false
	textBox.Text = ""
	textBox.ZIndex = 12
	textBox.Parent = SavePrompt

	local inputCorner = Instance.new("UICorner")
	inputCorner.CornerRadius = UDim.new(0, 7)
	inputCorner.Parent = textBox

	local cancelButton = Instance.new("TextButton")
	cancelButton.Size = UDim2.fromOffset(90, 27)
	cancelButton.Position = UDim2.new(0.5, -96, 1, -35)
	cancelButton.BackgroundColor3 = Color3.fromRGB(115, 65, 75)
	cancelButton.BorderSizePixel = 0
	cancelButton.Text = "CANCEL"
	cancelButton.TextColor3 = Color3.fromRGB(255, 255, 255)
	cancelButton.TextSize = 11
	cancelButton.Font = Enum.Font.GothamBold
	cancelButton.ZIndex = 11
	cancelButton.Parent = SavePrompt

	local cancelCorner = Instance.new("UICorner")
	cancelCorner.CornerRadius = UDim.new(0, 6)
	cancelCorner.Parent = cancelButton

	local saveButton = Instance.new("TextButton")
	saveButton.Size = UDim2.fromOffset(90, 27)
	saveButton.Position = UDim2.new(0.5, 6, 1, -35)
	saveButton.BackgroundColor3 = Color3.fromRGB(45, 145, 105)
	saveButton.BorderSizePixel = 0
	saveButton.Text = "SAVE"
	saveButton.TextColor3 = Color3.fromRGB(255, 255, 255)
	saveButton.TextSize = 11
	saveButton.Font = Enum.Font.GothamBold
	saveButton.ZIndex = 11
	saveButton.Parent = SavePrompt

	local saveCorner = Instance.new("UICorner")
	saveCorner.CornerRadius = UDim.new(0, 6)
	saveCorner.Parent = saveButton

	local function submit()
		local name = textBox.Text:gsub("^%s+", ""):gsub("%s+$", "")

		if name == "" then
			Status.Text = "Enter a save name"
			return
		end

		if name:find("[/\\:*?\"<>|]") then
			Status.Text = "Save name contains invalid characters"
			return
		end

		refreshSaveData()

		if SaveData[name] ~= nil or isfile(getSavePath(name)) then
			Status.Text = "That save name already exists"
			textBox.Text = ""
			return
		end

		if saveCurrentStructure(name) then
			closeSavePrompt()
		end
	end

	cancelButton.Activated:Connect(closeSavePrompt)
	saveButton.Activated:Connect(submit)

	PromptConnection = textBox.FocusLost:Connect(function(enterPressed)
		if enterPressed then
			submit()
		else
			closeSavePrompt()
		end
	end)

	task.defer(function()
		if textBox.Parent then
			textBox:CaptureFocus()
		end
	end)
end

local function closeLoadPanel()
	if LoadPanel then
		LoadPanel:Destroy()
		LoadPanel = nil
		LoadList = nil
	end

end

local function loadSavedStructure(name)
	local saved = SaveData[name]

	if type(saved) ~= "table" or type(saved.blocks) ~= "table" then
		Status.Text = "Invalid save data"
		return
	end

	if not GridOrigin then
		GridOrigin = findGridOrigin()
	end

	if not GridOrigin then
		Status.Text = "Island grid not found"
		return
	end

	local minX = math.huge
	local minY = math.huge
	local minZ = math.huge
	local blockData = {}

	for _, item in ipairs(saved.blocks) do
		if type(item) ~= "table" or type(item.name) ~= "string" then
			continue
		end

		local x = tonumber(item.x)
		local y = tonumber(item.y)
		local z = tonumber(item.z)

		if not x or not y or not z then
			continue
		end

		local rx = tonumber(item.rx) or 0
		local ry = tonumber(item.ry) or 0
		local rz = tonumber(item.rz) or 0

		local cell = {
			x = x,
			y = y,
			z = z
		}

		minX = math.min(minX, x)
		minY = math.min(minY, y)
		minZ = math.min(minZ, z)

		table.insert(blockData, {
			cell = cell,
			blockName = item.name,
			isMachine = item.machine == true,
			rotation = CFrame.fromOrientation(rx, ry, rz)
		})
	end

	if #blockData == 0 then
		Status.Text = "Save contains no valid blocks"
		return
	end

	for _, data in ipairs(blockData) do
		data.cell.x -= minX
		data.cell.y -= minY
		data.cell.z -= minZ
	end

	local maxX = tonumber(saved.width) or 0
	local maxZ = tonumber(saved.depth) or 0

	local center = {
		x = maxX,
		z = maxZ
	}

	local playerCell = getPlayerGridCell(CellSize * 2)

	if not playerCell then
		Status.Text = "Could not locate player grid"
		return
	end

	local offset = {
		x = playerCell.x,
		y = playerCell.y,
		z = playerCell.z
	}

	if buildHolograms(blockData, center, offset, tonumber(saved.rotationSteps) or 0) then
		Status.Text = "Loaded: " .. name
		closeLoadPanel()
	end
end

local function openLoadPanel()
	if not FileEnabled then
		Status.Text = "Saving and loading are disabled"
		return
	end

	if not FileFunctionsAvailable then
		Status.Text = "Executor file functions unavailable"
		return
	end

	if IsPasting then
		return
	end

	if LoadPanel then
		closeLoadPanel()
		return
	end

	if not refreshSaveData() then
		Status.Text = "Could not read saved structures"
		return
	end

	LoadPanel = Instance.new("Frame")
	LoadPanel.Name = "LoadPanel"
	LoadPanel.Size = UDim2.fromOffset(270, 300)
	LoadPanel.Position = UDim2.new(0.5, -135, 0.5, -150)
	LoadPanel.BackgroundColor3 = Color3.fromRGB(27, 32, 44)
	LoadPanel.BorderSizePixel = 0
	LoadPanel.ZIndex = 10
	LoadPanel.Parent = ScreenGui

	local panelCorner = Instance.new("UICorner")
	panelCorner.CornerRadius = UDim.new(0, 12)
	panelCorner.Parent = LoadPanel

	local panelStroke = Instance.new("UIStroke")
	panelStroke.Color = Color3.fromRGB(75, 95, 125)
	panelStroke.Parent = LoadPanel

	local title = Instance.new("TextLabel")
	title.Size = UDim2.new(1, -50, 0, 32)
	title.Position = UDim2.fromOffset(12, 7)
	title.BackgroundTransparency = 1
	title.Text = "LOAD STRUCTURE"
	title.TextColor3 = Color3.fromRGB(225, 232, 245)
	title.TextSize = 13
	title.Font = Enum.Font.GothamBold
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.ZIndex = 11
	title.Parent = LoadPanel

	local close = Instance.new("TextButton")
	close.Size = UDim2.fromOffset(30, 27)
	close.Position = UDim2.new(1, -38, 0, 8)
	close.BackgroundColor3 = Color3.fromRGB(115, 65, 75)
	close.BorderSizePixel = 0
	close.Text = "X"
	close.TextColor3 = Color3.fromRGB(255, 255, 255)
	close.TextSize = 12
	close.Font = Enum.Font.GothamBold
	close.ZIndex = 11
	close.Parent = LoadPanel

	local closeCorner = Instance.new("UICorner")
	closeCorner.CornerRadius = UDim.new(0, 6)
	closeCorner.Parent = close

	close.Activated:Connect(closeLoadPanel)

	local loadStatus = Instance.new("TextLabel")
	loadStatus.Size = UDim2.new(1, -20, 0, 20)
	loadStatus.Position = UDim2.fromOffset(10, 38)
	loadStatus.BackgroundTransparency = 1
	loadStatus.Text = "Select a saved structure"
	loadStatus.TextColor3 = Color3.fromRGB(150, 175, 210)
	loadStatus.TextSize = 11
	loadStatus.Font = Enum.Font.Gotham
	loadStatus.Parent = LoadPanel
	loadStatus.ZIndex = 11

	LoadList = Instance.new("ScrollingFrame")
	LoadList.Size = UDim2.new(1, -20, 1, -72)
	LoadList.Position = UDim2.fromOffset(10, 63)
	LoadList.BackgroundTransparency = 1
	LoadList.BorderSizePixel = 0
	LoadList.ScrollBarThickness = 4
	LoadList.CanvasSize = UDim2.fromOffset(0, 0)
	LoadList.AutomaticCanvasSize = Enum.AutomaticSize.Y
	LoadList.ZIndex = 11
	LoadList.Parent = LoadPanel

	local layout = Instance.new("UIListLayout")
	layout.Padding = UDim.new(0, 6)
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Parent = LoadList

	refreshLoadList(LoadList, loadStatus)
end

local function findPlacedBlockAtCell(cell, previewParts)
	local targetKey = Grid.key(cell)

	for _, instance in ipairs(workspace:GetDescendants()) do
		if not instance:IsA("BasePart") or previewParts[instance] then
			continue
		end

		if instance:GetAttribute("CellKey") == targetKey then
			return instance
		end
	end

	return nil
end

local supportDirections = {
	{ x = 0, y = -1, z = 0, normal = Vector3.new(0, 1, 0) },
	{ x = 1, y = 0, z = 0, normal = Vector3.new(-1, 0, 0) },
	{ x = -1, y = 0, z = 0, normal = Vector3.new(1, 0, 0) },
	{ x = 0, y = 0, z = 1, normal = Vector3.new(0, 0, -1) },
	{ x = 0, y = 0, z = -1, normal = Vector3.new(0, 0, 1) },
	{ x = 0, y = 1, z = 0, normal = Vector3.new(0, -1, 0) }
}

local function getPlacedCellMap(previewParts)
	local placedCells = {}

	for _, instance in ipairs(workspace:GetDescendants()) do
		if not instance:IsA("BasePart") or previewParts[instance] then
			continue
		end

		local cellKey = instance:GetAttribute("CellKey")

		if type(cellKey) == "string" and not placedCells[cellKey] then
			placedCells[cellKey] = instance
		end
	end

	return placedCells
end

local function getSupportingNormal(cell, placedCells)
	for _, direction in ipairs(supportDirections) do
		local neighborCell = {
			x = cell.x + direction.x,
			y = cell.y + direction.y,
			z = cell.z + direction.z
		}

		if placedCells[Grid.key(neighborCell)] then
			return direction.normal
		end
	end

	return nil
end

local function pasteHolograms()
	if Mode ~= "MoveHologram" or #Holograms == 0 then
		return
	end

	if IsPasting then
		CancelPaste = true
		Status.Text = "Cancelling build..."
		return
	end

	CancelPaste = false
	IsPasting = true
	ConfirmButton.Text = "CANCEL BUILD"
	ConfirmButton.BackgroundColor3 = Color3.fromRGB(105, 115, 130)

	local horizontalRange = 20
	local verticalRange = 20
	local pollInterval = 0.2
	local confirmationTimeout = 5
	local confirmationPollInterval = 0.1
	local placed = 0
	local alreadyPresent = 0
	local failed = 0
	local unsupported = 0
	local total = #Holograms
	local pending = {}
	local previewParts = {}

	for _, data in ipairs(Holograms) do
		if data.preview then
			previewParts[data.preview] = true

			for _, descendant in ipairs(data.preview:GetDescendants()) do
				if descendant:IsA("BasePart") then
					previewParts[descendant] = true
				end
			end
		end

		local targetCell = getTargetCell(data)
		table.insert(pending, {
			data = data,
			cell = targetCell,
			key = Grid.key(targetCell),
			position = Grid.cellToWorld(GridOrigin, targetCell)
		})
	end

	while #pending > 0 and not CancelPaste do
		local character = Player.Character
		local root = character and character:FindFirstChild("HumanoidRootPart")

		if not root then
			Status.Text = string.format("Waiting for character (%d/%d)", placed + alreadyPresent + 1, total)
			task.wait(pollInterval)
			continue
		end

		local placedCells = getPlacedCellMap(previewParts)
		local existingIndex

		for index, entry in ipairs(pending) do
			if placedCells[entry.key] then
				existingIndex = index
				break
			end
		end

		if existingIndex then
			alreadyPresent += 1
			Status.Text = string.format("Skipping existing block (%d/%d)", placed + alreadyPresent, total)
			table.remove(pending, existingIndex)
			task.wait(0.05)
			continue
		end

		local lowestY = math.huge
		local nextIndex
		local nextSupportNormal
		local closestHorizontalDistance = math.huge

		for index, entry in ipairs(pending) do
			local supportNormal = getSupportingNormal(entry.cell, placedCells)

			if supportNormal then
				local offset = entry.position - root.Position
				local horizontalDistance = Vector3.new(offset.X, 0, offset.Z).Magnitude

				if entry.cell.y < lowestY or (entry.cell.y == lowestY and horizontalDistance < closestHorizontalDistance) then
					lowestY = entry.cell.y
					closestHorizontalDistance = horizontalDistance
					nextIndex = index
					nextSupportNormal = supportNormal
				end
			end
		end

		if not nextIndex then
			unsupported = #pending
			Status.Text = string.format("Build stopped: no connected support for %d remaining block(s)", unsupported)
			break
		end

		local entry = pending[nextIndex]
		local existingBlock = findPlacedBlockAtCell(entry.cell, previewParts)

		if existingBlock then
			alreadyPresent += 1
			Status.Text = string.format("Skipping existing block (%d/%d)", placed + alreadyPresent, total)
			table.remove(pending, nextIndex)
			task.wait(0.05)
			continue
		end

		local offset = entry.position - root.Position
		local horizontalDistance = Vector3.new(offset.X, 0, offset.Z).Magnitude
		local verticalDistance = math.abs(offset.Y)

		if horizontalDistance > horizontalRange or verticalDistance > verticalRange then
			Status.Text = string.format(
				"Waiting for range (%d/%d): H %.1f/%.0f, V %.1f/%.0f",
				placed + alreadyPresent + 1,
				total,
				horizontalDistance,
				horizontalRange,
				verticalDistance,
				verticalRange
			)
			task.wait(pollInterval)
			continue
		end

		local blockName = entry.data.blockName

		if not blockName or blockName == "" then
			failed += 1
			Status.Text = "Build stopped: a block has no name"
			break
		end

		Status.Text = string.format("Placing %d/%d", placed + alreadyPresent + 1, total)
		local success = pcall(function()
			RequestPlace:FireServer(
				entry.cell,
				blockName,
				0,
				Vector3.new(0, 1, 0),
				false,
				nil,
				false,
				1
			)
		end)

		if not success then
			failed += 1
			Status.Text = "Build stopped: placement request failed"
			break
		end

		Status.Text = string.format("Verifying placement %d/%d", placed + alreadyPresent + 1, total)
		local confirmationDeadline = os.clock() + confirmationTimeout
		local confirmedBlock

		while not CancelPaste and os.clock() < confirmationDeadline do
			confirmedBlock = findPlacedBlockAtCell(entry.cell, previewParts)

			if confirmedBlock then
				break
			end

			task.wait(confirmationPollInterval)
		end

		if CancelPaste then
			break
		end

		if not confirmedBlock then
			failed += 1
			Status.Text = "Build stopped: no block detected at target position"
			break
		end

		placed += 1
		table.remove(pending, nextIndex)
		task.wait(0.05)
	end

	local wasCancelled = CancelPaste
	CancelPaste = false
	IsPasting = false
	ConfirmButton.Text = "PASTE BLOCKS"
	ConfirmButton.BackgroundColor3 = Color3.fromRGB(45, 175, 110)

	if wasCancelled then
		Status.Text = string.format("Build cancelled: %d placed, %d already present", placed, alreadyPresent)
	elseif failed > 0 then
		Status.Text = string.format("Build stopped: %d placed, %d already present, %d failed", placed, alreadyPresent, failed)
	else
		Status.Text = string.format("Build complete: %d placed, %d already present", placed, alreadyPresent)
	end
end

refreshLoadList = function(loadList, loadStatus)
	if not loadList or not loadList.Parent or not loadStatus or not loadStatus.Parent then
		return
	end

	for _, child in ipairs(loadList:GetChildren()) do
		if not child:IsA("UIListLayout") then
			child:Destroy()
		end
	end

	local names = {}

	for name in pairs(SaveData) do
		if type(name) == "string" then
			table.insert(names, name)
		end
	end

	table.sort(names, function(a, b)
		return a:lower() < b:lower()
	end)

	if #names == 0 then
		local empty = Instance.new("TextLabel")
		empty.Size = UDim2.new(1, -10, 0, 35)
		empty.BackgroundTransparency = 1
		empty.Text = "No saved structures"
		empty.TextColor3 = Color3.fromRGB(155, 165, 185)
		empty.TextSize = 12
		empty.Font = Enum.Font.Gotham
		empty.ZIndex = 12
		empty.Parent = loadList
		return
	end

	for _, name in ipairs(names) do
		local row = Instance.new("Frame")
		row.Size = UDim2.new(1, -8, 0, 34)
		row.BackgroundTransparency = 1
		row.ZIndex = 12
		row.Parent = loadList

		local item = Instance.new("TextButton")
		item.Size = UDim2.new(1, -42, 1, 0)
		item.BackgroundColor3 = Color3.fromRGB(43, 53, 72)
		item.BorderSizePixel = 0
		item.Text = "  " .. name
		item.TextColor3 = Color3.fromRGB(235, 240, 250)
		item.TextSize = 12
		item.Font = Enum.Font.GothamMedium
		item.TextXAlignment = Enum.TextXAlignment.Left
		item.ZIndex = 12
		item.Parent = row

		local itemCorner = Instance.new("UICorner")
		itemCorner.CornerRadius = UDim.new(0, 6)
		itemCorner.Parent = item

		local delete = Instance.new("TextButton")
		delete.Size = UDim2.new(0, 34, 1, 0)
		delete.Position = UDim2.new(1, -34, 0, 0)
		delete.BackgroundColor3 = Color3.fromRGB(170, 55, 65)
		delete.BorderSizePixel = 0
		delete.Text = "×"
		delete.TextColor3 = Color3.fromRGB(255, 255, 255)
		delete.TextSize = 20
		delete.Font = Enum.Font.GothamBold
		delete.ZIndex = 12
		delete.Parent = row

		local deleteCorner = Instance.new("UICorner")
		deleteCorner.CornerRadius = UDim.new(0, 6)
		deleteCorner.Parent = delete

		item.Activated:Connect(function()
			loadSavedStructure(name)
		end)

		delete.Activated:Connect(function()
			if not loadList.Parent or not loadStatus.Parent then
				return
			end

			if type(delfile) ~= "function" then
				loadStatus.Text = "Delete is not supported"
				return
			end

			local path = getSavePath(name)

			if isfile(path) then
				delfile(path)
			end

			SaveData[name] = nil
			loadStatus.Text = "Deleted " .. name
			refreshLoadList(loadList, loadStatus)
		end)
	end
end

local function resetController()
	if IsPasting then
		return
	end

	clearHolograms()
	clearMarkers()

	table.clear(SelectedBlocks)
	table.clear(Corners)

	GridOrigin = findGridOrigin()
	MoveOffset = {x = 0, y = 0, z = 0}
	RotationSteps = 0
	RotationCenter = {x = 0, z = 0}
	Mode = "FirstCorner"

	if ConfirmButton then
		ConfirmButton.Text = "CONFIRM CORNER"
		ConfirmButton.BackgroundColor3 = Color3.fromRGB(45, 145, 105)
	end

	local playerCell = getPlayerGridCell(CellSize)

	if playerCell then
		CursorCell = playerCell
	else
		CursorCell = {x = 0, y = 0, z = 0}
	end

	Status.Text = "First corner"
	updateCoordinates()
	updateCornerMarker()
end

local function createHologram()
	local blockData = {}
	local minCell = {
		x = math.huge,
		y = math.huge,
		z = math.huge
	}

	for _, original in pairs(SelectedBlocks) do
		local cell = getCell(original)

		if not cell then
			continue
		end

		local blockName, isMachine = getBlockInfo(original)

		minCell.x = math.min(minCell.x, cell.x)
		minCell.y = math.min(minCell.y, cell.y)
		minCell.z = math.min(minCell.z, cell.z)

		table.insert(blockData, {
			original = original,
			cell = cell,
			blockName = blockName,
			isMachine = isMachine,
			rotation = original.CFrame.Rotation
		})
	end

	if #blockData == 0 then
		Status.Text = "Could not read block cells"
		resetController()
		return
	end

	local first = Corners[1]
	local second = Corners[2]

	RotationCenter = {
		x = first.x + second.x,
		z = first.z + second.z
	}

	local playerCell = getPlayerGridCell(CellSize * 2)

	if not playerCell then
		Status.Text = "Could not locate player grid"
		resetController()
		return
	end

	local offset = {
		x = playerCell.x - minCell.x,
		y = playerCell.y - minCell.y,
		z = playerCell.z - minCell.z
	}

	local center = {
		x = RotationCenter.x - minCell.x * 2,
		z = RotationCenter.z - minCell.z * 2
	}

	for _, data in ipairs(blockData) do
		data.cell = {
			x = data.cell.x - minCell.x,
			y = data.cell.y - minCell.y,
			z = data.cell.z - minCell.z
		}
	end

	buildHolograms(blockData, center, offset, 0)
end

local function selectRegion()
	table.clear(SelectedBlocks)

	local first = Corners[1]
	local second = Corners[2]

	local minX, maxX = math.min(first.x, second.x), math.max(first.x, second.x)
	local minY, maxY = math.min(first.y, second.y), math.max(first.y, second.y)
	local minZ, maxZ = math.min(first.z, second.z), math.max(first.z, second.z)

	local candidates = {}

	for _, instance in ipairs(workspace:GetDescendants()) do
		if not instance:IsA("BasePart") then
			continue
		end

		local key = instance:GetAttribute("CellKey")

		if type(key) ~= "string" then
			continue
		end

		local blockName = getBlockInfo(instance)

		if not blockName or blockName == "" then
			continue
		end

		local cell = getCell(instance)

		if not cell then
			continue
		end

		if cell.x < minX or cell.x > maxX
			or cell.y < minY or cell.y > maxY
			or cell.z < minZ or cell.z > maxZ then
			continue
		end

		local expectedPosition = Grid.cellToWorld(GridOrigin, cell)

		if (instance.Position - expectedPosition).Magnitude > CellSize * 2 then
			continue
		end

		local existing = candidates[key]

		if not existing or (instance.Position - expectedPosition).Magnitude < (existing.Position - expectedPosition).Magnitude then
			candidates[key] = instance
		end
	end

	for key, part in pairs(candidates) do
		SelectedBlocks[key] = part
	end

	local count = 0

	for _ in pairs(SelectedBlocks) do
		count += 1
	end

	if count == 0 then
		Status.Text = "No blocks found - resetting"
		resetController()
		return
	end

	createHologram()

	if Mode == "MoveHologram" then
		Status.Text = tostring(count) .. " blocks copied"
	end
end

createButton("YPlus", "↑", UDim2.fromOffset(12, 98), UDim2.fromOffset(66, 34), Color3.fromRGB(55, 125, 100), function()
	move(0, 1, 0)
end)

createButton("ZMinus", "↑", UDim2.fromOffset(85, 98), UDim2.fromOffset(66, 34), Color3.fromRGB(54, 92, 145), function()
	move(0, 0, -1)
end)

createButton("YMinus", "↓", UDim2.fromOffset(158, 98), UDim2.fromOffset(75, 34), Color3.fromRGB(55, 125, 100), function()
	move(0, -1, 0)
end)

createButton("XMinus", "←", UDim2.fromOffset(12, 140), UDim2.fromOffset(66, 34), Color3.fromRGB(54, 92, 145), function()
	move(-1, 0, 0)
end)

createButton("Save", "▣", UDim2.fromOffset(85, 140), UDim2.fromOffset(66, 34), Color3.fromRGB(45, 145, 105), function()
	openSavePrompt()
end)

createButton("XPlus", "→", UDim2.fromOffset(158, 140), UDim2.fromOffset(75, 34), Color3.fromRGB(54, 92, 145), function()
	move(1, 0, 0)
end)

createButton("RotateMinus", "↶", UDim2.fromOffset(12, 182), UDim2.fromOffset(66, 34), Color3.fromRGB(125, 85, 155), function()
	rotate(-1)
end)

createButton("ZPlus", "↓", UDim2.fromOffset(85, 182), UDim2.fromOffset(66, 34), Color3.fromRGB(54, 92, 145), function()
	move(0, 0, 1)
end)

createButton("RotatePlus", "↷", UDim2.fromOffset(158, 182), UDim2.fromOffset(75, 34), Color3.fromRGB(125, 85, 155), function()
	rotate(1)
end)

ConfirmButton = createButton("Confirm", "CONFIRM CORNER", UDim2.fromOffset(12, 224), UDim2.fromOffset(221, 29), Color3.fromRGB(45, 145, 105), function()
	if Mode == "MoveHologram" then
		pasteHolograms()
		return
	end

	if Mode == "FirstCorner" then
		Corners[1] = {
			x = CursorCell.x,
			y = CursorCell.y,
			z = CursorCell.z
		}

		table.insert(CornerMarkers, createMarker(Corners[1], Color3.fromRGB(255, 190, 55), 0.3))

		Mode = "SecondCorner"
		Status.Text = "Select opposite corner"
		return
	end

	if Mode == "SecondCorner" then
		Corners[2] = {
			x = CursorCell.x,
			y = CursorCell.y,
			z = CursorCell.z
		}

		table.insert(CornerMarkers, createMarker(Corners[2], Color3.fromRGB(255, 190, 55), 0.3))
		selectRegion()
	end
end)

createButton("Reset", "RESET", UDim2.fromOffset(12, 258), UDim2.fromOffset(105, 22), Color3.fromRGB(145, 65, 75), function()
	resetController()
end)

createButton("Load", "LOAD", UDim2.fromOffset(128, 258), UDim2.fromOffset(105, 22), Color3.fromRGB(65, 105, 155), function()
	openLoadPanel()
end)

local dragging = false
local dragStart
local startPosition

TopBar.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		dragging = true
		dragStart = input.Position
		startPosition = Main.Position
	end
end)

UserInputService.InputChanged:Connect(function(input)
	if not dragging then
		return
	end

	if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
		local delta = input.Position - dragStart

		Main.Position = UDim2.new(
			startPosition.X.Scale,
			startPosition.X.Offset + delta.X,
			startPosition.Y.Scale,
			startPosition.Y.Offset + delta.Y
		)
	end
end)

UserInputService.InputEnded:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		dragging = false
	end
end)

GridOrigin = findGridOrigin()

if GridOrigin then
	local playerCell = getPlayerGridCell(CellSize)

	if playerCell then
		CursorCell = playerCell
		updateCoordinates()
		updateCornerMarker()
		Status.Text = "First corner - use arrows"
	else
		Status.Text = "Could not locate player grid"
	end
else
	Status.Text = "Island grid not found"
end

if not FileEnabled then
	Status.Text = "File saving and loading disabled"
elseif not FileFunctionsAvailable then
	Status.Text = "Executor file functions unavailable"
end

CloseButton.Activated:Connect(function()
	CancelPaste = true
	IsPasting = false
	clearHolograms()
	clearMarkers()
	closeSavePrompt()
	closeLoadPanel()
	ScreenGui:Destroy()
end)
