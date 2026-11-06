-- StarFall Hub — Loader
-- Downloads assets, checks game ID, loads matching script

local Players = game:GetService("Players")
local Player = Players.LocalPlayer
local PlayerGui = Player:WaitForChild("PlayerGui")
local TweenService = game:GetService("TweenService")
local HttpService = game:GetService("HttpService")

local REPO_BASE = "https://raw.githubusercontent.com/SleepyVibesAlt/StarFall-Hub/main/"
local REPO_API = "https://api.github.com/repos/SleepyVibesAlt/StarFall-Hub/contents/games?ref=main"

-- All downloaded files are kept inside one hub directory.
local ROOT_DIR = "Starfall_Hub"
local GUI_DIR = ROOT_DIR .. "/guis"
local GAME_DIR = ROOT_DIR .. "/games"

local function ensureFolder(path)
	local exists = false
	if isfolder then
		local ok, result = pcall(isfolder, path)
		exists = ok and result == true
	end

	if not exists then
		local ok, err = pcall(makefolder, path)
		if not ok then
			-- Some executors report an error when the folder already exists.
			if isfolder then
				local checkOk, result = pcall(isfolder, path)
				if not checkOk or not result then
					return false, tostring(err)
				end
			else
				return false, tostring(err)
			end
		end
	end

	return true
end

local function prepareFolders()
	for _, folder in ipairs({ROOT_DIR, GUI_DIR, GAME_DIR}) do
		local ok, err = ensureFolder(folder)
		if not ok then
			return false, "Could not create folder " .. folder .. ": " .. tostring(err)
		end
	end
	return true
end

local foldersReady, folderError = prepareFolders()
if not foldersReady then
	error("[StarFall] " .. tostring(folderError))
end

-- ============ LOADING SCREEN ============

local LoadingScreen = Instance.new("ScreenGui")
LoadingScreen.Name = "StarFallLoading"
LoadingScreen.ResetOnSpawn = false
LoadingScreen.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
LoadingScreen.IgnoreGuiInset = true
LoadingScreen.Parent = PlayerGui

local LoadingFrame = Instance.new("Frame")
LoadingFrame.Name = "LoadingFrame"
LoadingFrame.Size = UDim2.fromScale(1, 1)
LoadingFrame.BackgroundColor3 = Color3.fromRGB(18, 18, 24)
LoadingFrame.BorderSizePixel = 0
LoadingFrame.Parent = LoadingScreen

local LoadingCorner = Instance.new("UICorner")
LoadingCorner.CornerRadius = UDim.new(0, 0)
LoadingCorner.Parent = LoadingFrame

local LoadingTitle = Instance.new("TextLabel")
LoadingTitle.Name = "LoadingTitle"
LoadingTitle.Size = UDim2.new(1, 0, 0, 40)
LoadingTitle.Position = UDim2.new(0, 0, 0, 200)
LoadingTitle.BackgroundTransparency = 1
LoadingTitle.Text = "StarFall Hub"
LoadingTitle.TextColor3 = Color3.fromRGB(130, 90, 255)
LoadingTitle.TextSize = 28
LoadingTitle.Font = Enum.Font.GothamBold
LoadingTitle.TextXAlignment = Enum.TextXAlignment.Center
LoadingTitle.Parent = LoadingFrame

local LoadingSubtitle = Instance.new("TextLabel")
LoadingSubtitle.Name = "LoadingSubtitle"
LoadingSubtitle.Size = UDim2.new(1, 0, 0, 20)
LoadingSubtitle.Position = UDim2.new(0, 0, 0, 248)
LoadingSubtitle.BackgroundTransparency = 1
LoadingSubtitle.Text = "Initializing..."
LoadingSubtitle.TextColor3 = Color3.fromRGB(145, 145, 160)
LoadingSubtitle.TextSize = 14
LoadingSubtitle.Font = Enum.Font.Gotham
LoadingSubtitle.TextXAlignment = Enum.TextXAlignment.Center
LoadingSubtitle.Parent = LoadingFrame

local ProgressBar = Instance.new("Frame")
ProgressBar.Name = "ProgressBar"
ProgressBar.Size = UDim2.new(0.5, 0, 0, 6)
ProgressBar.Position = UDim2.new(0.25, 0, 0, 280)
ProgressBar.BackgroundColor3 = Color3.fromRGB(34, 34, 44)
ProgressBar.BorderSizePixel = 0
ProgressBar.Parent = LoadingFrame

local ProgressCorner = Instance.new("UICorner")
ProgressCorner.CornerRadius = UDim.new(1, 0)
ProgressCorner.Parent = ProgressBar

local ProgressFill = Instance.new("Frame")
ProgressFill.Name = "ProgressFill"
ProgressFill.Size = UDim2.new(0, 0, 1, 0)
ProgressFill.BackgroundColor3 = Color3.fromRGB(130, 90, 255)
ProgressFill.BorderSizePixel = 0
ProgressFill.Parent = ProgressBar

local ProgressFillCorner = Instance.new("UICorner")
ProgressFillCorner.CornerRadius = UDim.new(1, 0)
ProgressFillCorner.Parent = ProgressFill

local ProgressGradient = Instance.new("UIGradient")
ProgressGradient.Color = ColorSequence.new({
	ColorSequenceKeypoint.new(0, Color3.fromRGB(105, 75, 235)),
	ColorSequenceKeypoint.new(1, Color3.fromRGB(165, 110, 255)),
})
ProgressGradient.Parent = ProgressFill

local StatusText = Instance.new("TextLabel")
StatusText.Name = "StatusText"
StatusText.Size = UDim2.new(1, 0, 0, 20)
StatusText.Position = UDim2.new(0, 0, 0, 292)
StatusText.BackgroundTransparency = 1
StatusText.Text = "0%"
StatusText.TextColor3 = Color3.fromRGB(145, 145, 160)
StatusText.TextSize = 12
StatusText.Font = Enum.Font.Gotham
StatusText.TextXAlignment = Enum.TextXAlignment.Center
StatusText.Parent = LoadingFrame

-- Fade the loading interface in instead of showing it abruptly.
LoadingFrame.BackgroundTransparency = 1

local introTweens = {}
for _, object in ipairs(LoadingFrame:GetDescendants()) do
	if object:IsA("Frame") then
		object.BackgroundTransparency = 1
		table.insert(introTweens, TweenService:Create(
			object,
			TweenInfo.new(0.45, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
			{BackgroundTransparency = 0}
		))
	elseif object:IsA("TextLabel") then
		object.TextTransparency = 1
		table.insert(introTweens, TweenService:Create(
			object,
			TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
			{TextTransparency = 0}
		))
	end
end

table.insert(introTweens, TweenService:Create(
	LoadingFrame,
	TweenInfo.new(0.45, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
	{BackgroundTransparency = 0}
))

for _, tween in ipairs(introTweens) do
	tween:Play()
end

local function setProgress(percent, status)
	TweenService:Create(
		ProgressFill,
		TweenInfo.new(0.4, Enum.EasingStyle.Quart, Enum.EasingDirection.Out),
		{Size = UDim2.new(percent / 100, 0, 1, 0)}
	):Play()

	StatusText.Text = percent .. "% — " .. status
	LoadingSubtitle.Text = status
end

local function closeLoadingScreen()
	if not LoadingScreen or not LoadingScreen.Parent then
		return
	end

	local tweens = {}
	for _, object in ipairs(LoadingScreen:GetDescendants()) do
		if object:IsA("Frame") then
			table.insert(tweens, TweenService:Create(
				object,
				TweenInfo.new(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
				{BackgroundTransparency = 1}
			))
		elseif object:IsA("TextLabel") then
			table.insert(tweens, TweenService:Create(
				object,
				TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
				{TextTransparency = 1}
			))
		end
	end

	table.insert(tweens, TweenService:Create(
		LoadingFrame,
		TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{BackgroundTransparency = 1}
	))

	for _, tween in ipairs(tweens) do
		tween:Play()
	end

	task.wait(0.45)

	if LoadingScreen and LoadingScreen.Parent then
		LoadingScreen:Destroy()
	end
end

-- ============ FILE MANAGEMENT ============

local FilesToDownload = {
	[GUI_DIR .. "/library.lua"] = REPO_BASE .. "guis/library.lua",
}

local function downloadFile(remoteUrl, localPath)
	local success, content = pcall(function()
		return game:HttpGet(remoteUrl)
	end)

	if not success or type(content) ~= "string" or content == "" then
		return false, "Failed to download: " .. remoteUrl
	end

	local writeSuccess, err = pcall(function()
		writefile(localPath, content)
	end)

	if not writeSuccess then
		return false, "Failed to write " .. localPath .. ": " .. tostring(err)
	end

	return true
end

local function ensureFile(localPath, remoteUrl)
	-- If file already exists locally, skip download
	local success, content = pcall(function()
		return readfile(localPath)
	end)
	if success and content then
		return true
	end

	return downloadFile(remoteUrl, localPath)
end

-- ============ GAME MAP (PlaceID -> Game Script) ============

local GameMap = {
	[124357835578554] = GAME_DIR .. "/124357835578554.lua",

	-- Add game mappings here using local GAME_DIR paths:
	-- [GAME_PLACE_ID] = GAME_DIR .. "/PLACE_ID.lua",
}

-- ============ GAMES DIRECTORY INSTALLER ============

-- Reads the repository's games/ directory through GitHub's public contents API,
-- then downloads every top-level .lua game script into Starfall_Hub/games/.
-- Existing local scripts that are not in the repository are left untouched.
local function installRepositoryGames()
	local requestOk, response = pcall(function()
		return game:HttpGet(REPO_API)
	end)

	if not requestOk or type(response) ~= "string" then
		return false, "Could not retrieve the GitHub games directory."
	end

	local decodeOk, entries = pcall(function()
		return HttpService:JSONDecode(response)
	end)

	if not decodeOk or type(entries) ~= "table" then
		return false, "GitHub returned an invalid games directory listing."
	end

	local installed = 0
	local skipped = 0

	for _, entry in ipairs(entries) do
		if entry.type == "file"
			and type(entry.name) == "string"
			and entry.name:match("%.lua$")
			and type(entry.download_url) == "string" then

			local localPath = GAME_DIR .. "/" .. entry.name
			local ok, err = downloadFile(entry.download_url, localPath)

			if ok then
				installed += 1
			else
				skipped += 1
				warn("[StarFall] Could not install " .. entry.name .. ": " .. tostring(err))
			end
		end
	end

	return true, installed, skipped
end

-- ============ SETUP ============

local totalSteps = #FilesToDownload + 3 -- assets + games install + scan + detect
local currentStep = 0

local function progress(amount, status)
	currentStep = currentStep + amount
	local percent = math.floor((currentStep / totalSteps) * 100)
	setProgress(math.min(percent, 100), status)
end

-- Phase 1: Download & write assets
for localPath, remoteUrl in pairs(FilesToDownload) do
	progress(1, "Downloading " .. localPath .. "...")

	local ok, err = ensureFile(localPath, remoteUrl)
	if not ok then
		setProgress(100, "Error: " .. tostring(err))
		task.wait(3)
		LoadingScreen:Destroy()
		error(tostring(err))
	end
end

-- Phase 2: Create and populate the local games directory.
progress(1, "Installing games directory...")
local gamesInstallOk, gamesInstalled, gamesSkipped = installRepositoryGames()

if not gamesInstallOk then
	warn("[StarFall] " .. tostring(gamesInstalled))
else
	setProgress(
		math.floor((currentStep / totalSteps) * 100),
		"Installed " .. tostring(gamesInstalled) .. " game script(s)"
	)
end

-- Phase 3: Scan for local games.
progress(1, "Scanning local games...")
task.wait(0.1)

-- Phase 4: Detect game and load
progress(1, "Detecting game...")
task.wait(0.1)

local PlaceId = game.PlaceId
local GameScript = GameMap[PlaceId]

if GameScript then
	setProgress(100, "Loading game script...")

	local repoRelativePath = "games/" .. GameScript:match("([^/]+)$")
	local ok, err = ensureFile(GameScript, REPO_BASE .. repoRelativePath)

	if not ok then
		setProgress(100, "Error loading game: " .. tostring(err))
		task.wait(3)
		LoadingScreen:Destroy()
		error(tostring(err))
	end

	local success, result = pcall(function()
		local content = readfile(GameScript)
		local fn = loadstring(content, GameScript)
		if fn then fn() end
	end)

	if not success then
		setProgress(100, "Runtime error: " .. tostring(result))
		task.wait(3)
		LoadingScreen:Destroy()
		error(tostring(result))
	end
else
	setProgress(100, "Game not in library — opening hub...")
	task.wait(0.5)
end

-- ============ HUB UI ============

local librarySource = readfile(GUI_DIR .. "/library.lua")

-- Patch the library so the main window animates instead of appearing instantly.
local visibilityPatch = [[
	function Window:SetVisible(visible)
		if self._visibilityTween then
			self._visibilityTween:Cancel()
			self._visibilityTween = nil
		end

		if visible then
			Main.Visible = true
			self._windowScale.Scale = 0.92
			self._visibilityTween = TweenService:Create(
				self._windowScale,
				TweenInfo.new(0.32, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
				{Scale = 1}
			)
			self._visibilityTween:Play()
		else
			self._visibilityTween = TweenService:Create(
				self._windowScale,
				TweenInfo.new(0.22, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
				{Scale = 0.92}
			)
			self._visibilityTween:Play()
			self._visibilityTween.Completed:Once(function()
				if self._windowScale.Scale <= 0.93 then
					Main.Visible = false
				end
			end)
		end
	end
]]

librarySource = librarySource:gsub(
	"Corner%(Main, 12%)",
	"Corner(Main, 12)\n\tMain.Visible = false\n\tlocal windowScale = Create(\"UIScale\", {Scale = 0.92}, Main)\n\tWindow._windowScale = windowScale"
)

librarySource = librarySource:gsub(
	"function Window:Destroy%(%)",
	visibilityPatch .. "function Window:Destroy()"
)

librarySource = librarySource:gsub(
	"function Window:Toggle%(%)%s*Main.Visible = not Main.Visible%s*end",
	"function Window:Toggle()\n\t\tself:SetVisible(not Main.Visible)\n\tend"
)

librarySource = librarySource:gsub(
	"Main.Visible = not Main.Visible",
	"Window:SetVisible(not Main.Visible)"
)

local SmoothUI = loadstring(librarySource, "StarFall SmoothUI")()
local Library = SmoothUI.new()

local Window = Library:CreateWindow({
	Title = "StarFall Hub",
})

-- ============ LOAD GAME SCRIPT ============

local function loadScript(filePath)
	local success, result = pcall(function()
		local content = readfile(filePath)
		if not content then
			error("Cannot read file: " .. filePath)
		end

		local fn = loadstring(content, filePath)
		if not fn then
			error("Invalid script: " .. filePath)
		end

		fn()
	end)

	if not success then
		Library:Notify("Load Error", tostring(result), 5)
		print("[StarFall] Error: " .. tostring(result))
	else
		Library:Notify("Loaded", filePath, 2)
	end
end

-- ============ GAMES TAB ============

local GamesTab = Window:CreateTab("Games")
local GamesSection = GamesTab:CreateSection("Select Script")

local function getAvailableGames()
	local games = {}
	local files = listfiles(GAME_DIR .. "/")

	for _, file in ipairs(files) do
		if string.find(file, "%.lua$") then
			local name = file:match("([^/]+)%.lua$") or file
			table.insert(games, {name = name, path = file})
		end
	end

	return games
end

local function buildGameList()
	-- Clear existing entries
	for _, child in ipairs(GamesSection.Container:GetChildren()) do
		child:Destroy()
	end

	local games = getAvailableGames()

	for _, gameEntry in ipairs(games) do
		GamesSection:CreateButton({
			Name = gameEntry.name,
			Callback = function()
				loadScript(gameEntry.path)
			end,
		})
	end

	Library:Notify("Games", #games .. " script(s) available", 2)
end

GamesSection:CreateButton({
	Name = "Install / Update Games",
	Callback = function()
		Library:Notify("Installing", "Downloading scripts from the GitHub games folder...", 3)

		local ok, installed, skipped = installRepositoryGames()
		if not ok then
			Library:Notify("Install Error", tostring(installed), 5)
			return
		end

		buildGameList()
		Library:Notify(
			"Games Installed",
			tostring(installed) .. " script(s) installed; " .. tostring(skipped) .. " failed.",
			4
		)
	end,
})

GamesSection:CreateButton({
	Name = "Refresh Game List",
	Callback = buildGameList,
})

GamesSection:CreateButton({
	Name = "Load All",
	Callback = function()
		local loaded = 0
		for _, gameEntry in ipairs(getAvailableGames()) do
			loadScript(gameEntry.path)
			loaded += 1
		end

		Library:Notify("Loaded", loaded .. " script(s)", 2)
	end,
})

-- ============ SETTINGS TAB ============

local SettingsTab = Window:CreateTab("Settings")
local SettingsSection = SettingsTab:CreateSection("Options")

SettingsSection:CreateButton({
	Name = "Re-download Assets",
	Callback = function()
		Library:Notify("Updating", "Refreshing hub files and game scripts...", 3)

		for localPath, remoteUrl in pairs(FilesToDownload) do
			local ok, err = downloadFile(remoteUrl, localPath)
			if not ok then
				Library:Notify("Error", "Failed: " .. tostring(err), 5)
				return
			end
		end

		local ok, installed, skipped = installRepositoryGames()
		if not ok then
			Library:Notify("Update Error", tostring(installed), 5)
			return
		end

		buildGameList()
		Library:Notify(
			"Updated",
			tostring(installed) .. " game script(s) installed; " .. tostring(skipped) .. " failed.",
			4
		)
	end,
})

SettingsSection:CreateButton({
	Name = "Current PlaceID",
	Callback = function()
		Library:Notify("Place ID", tostring(PlaceId), 3)
	end,
})

-- ============ INIT ============

buildGameList()

-- Auto-load if game is known
if GameMap[PlaceId] then
	task.wait(1)
	loadScript(GameMap[PlaceId])
end

Window:SetVisible(true)
closeLoadingScreen()

Library:Notify("StarFall Hub", "Ready! Press RightShift to toggle.", 4)