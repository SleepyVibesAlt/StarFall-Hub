-- StarFall Hub — Loader
-- Downloads assets, checks game ID, loads matching script

local Players = game:GetService("Players")
local Player = Players.LocalPlayer
local PlayerGui = Player:WaitForChild("PlayerGui")

local REPO_BASE = "https://raw.githubusercontent.com/SleepyVibesAlt/StarFall-Hub/main/"

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

local function setProgress(percent, status)
    ProgressFill.Size = UDim2.new(percent / 100, 0, 1, 0)
    StatusText.Text = percent .. "% — " .. status
    LoadingSubtitle.Text = status
end

local function closeLoadingScreen()
    task.delay(0.3, function()
        LoadingScreen:Destroy()
    end)
end

local gameToggles = {} -- Store toggles for games

-- ============ FILE MANAGEMENT ============
local FilesToDownload = {
    ["guis/library.lua"] = REPO_BASE .. "guis/library.lua",
}

local function downloadFile(remoteUrl, localPath)
    local success, content = pcall(function()
        return game:HttpGet(remoteUrl)
    end)
    if not success or not content then
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
    [124357835578554] = "games/124357835578554.lua",
    -- Add more games here:
    -- [GAME_PLACE_ID] = "games/PLACE_ID.lua",
}

-- ============ SETUP ============
local totalSteps = #FilesToDownload + 2 -- files + scan + load
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

-- Phase 2: Scan for local games
progress(1, "Scanning local games...")
task.wait(0.1)

-- Phase 3: Detect game and load
progress(1, "Detecting game...")
task.wait(0.1)

local PlaceId = game.PlaceId
local GameScript = GameMap[PlaceId]

if GameScript then
    setProgress(100, "Loading game script...")
    local ok, err = ensureFile(GameScript, REPO_BASE .. GameScript)
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

closeLoadingScreen()

-- ============ HUB UI ============
local SmoothUI = loadstring(readfile("guis/library.lua"))()
local Library = SmoothUI.new()

local Window = Library:CreateWindow({
    Title = "StarFall Hub"
})

-- ============ LOAD GAME SCRIPT ============
local function loadScript(filePath)
    local success, result = pcall(function()
        local content = readfile(filePath)
        if not content then error("Cannot read file: " .. filePath) end
        local fn = loadstring(content, filePath)
        if not fn then error("Invalid script: " .. filePath) end
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
    local files = listfiles("games/")
    for _, file in ipairs(files) do
        if string.find(file, "%.lua$") then
            local name = file:gsub("games/", ""):gsub("%.lua$", "")
            table.insert(games, { name = name, path = file })
        end
    end
    return games
end

local function buildGameList()
    -- Clear existing toggles
    for _, child in ipairs(GamesSection.Container:GetChildren()) do
        child:Destroy()
    end
    gameToggles = {}

    local games = getAvailableGames()
    for _, game in ipairs(games) do
        local isSelected = game.path == GameMap[PlaceId]
        gameToggles[game.name] = GamesSection:CreateToggle({
            Name = game.name,
            CurrentValue = isSelected,
            Callback = function(enabled)
                if enabled then loadScript(game.path) end
            end
        })
    end

    Library:Notify("Games", #games .. " script(s) available", 2)
end

GamesSection:CreateButton({
    Name = "Refresh Game List",
    Callback = buildGameList
})

GamesSection:CreateButton({
    Name = "Load All",
    Callback = function()
        local loaded = 0
        for name, toggle in pairs(gameToggles) do
            if toggle.Get() then
                for _, g in ipairs(getAvailableGames()) do
                    if g.name == name then
                        loadScript(g.path)
                        loaded = loaded + 1
                        break
                    end
                end
            end
        end
        Library:Notify("Loaded", loaded .. " script(s)", 2)
    end
})

-- ============ SETTINGS TAB ============
local SettingsTab = Window:CreateTab("Settings")
local SettingsSection = SettingsTab:CreateSection("Options")

SettingsSection:CreateButton({
    Name = "Re-download Assets",
    Callback = function()
        setProgress(0, "Re-downloading...")
        LoadingScreen:Destroy()
        -- Re-run setup
        for localPath, remoteUrl in pairs(FilesToDownload) do
            local ok, err = ensureFile(localPath, remoteUrl)
            if not ok then
                error(tostring(err))
            end
        end
        Library:Notify("Updated", "All assets refreshed!", 2)
    end
})

SettingsSection:CreateButton({
    Name = "Current PlaceID",
    Callback = function()
        Library:Notify("Place ID", tostring(PlaceId), 3)
    end
})

SettingsSection:CreateButton({
    Name = "Register This Game",
    Callback = function()
        Library:InputPrompt({
            Title = "Register Game",
            Message = "Enter the Place ID for this game:",
            Placeholder = "e.g. 124357835578554",
            Buttons = {
                {Text = "Cancel"},
                {Text = "Register", Primary = true, Callback = function(text)
                    local pid = tonumber(text)
                    if pid then
                        GameMap[pid] = "games/" .. tostring(pid) .. ".lua"
                        Library:Notify("Registered", "PlaceID " .. tostring(pid) .. " mapped!", 3)
                    else
                        Library:Notify("Error", "Invalid Place ID", 3)
                    end
                end}
            }
        })
    end
})

-- ============ INIT ============
buildGameList()

-- Auto-load if game is known
if GameMap[PlaceId] then
    task.wait(1)
    loadScript(GameMap[PlaceId])
end

Library:Notify("StarFall Hub", "Ready! Press RightShift to toggle.", 4)
