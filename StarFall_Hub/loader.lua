-- StarFall Hub — Loader
-- Downloads assets and game scripts from the repo, runs them on button click

local Players = game:GetService("Players")
local Player = Players.LocalPlayer
local PlayerGui = Player:WaitForChild("PlayerGui")

local REPO_BASE = "https://raw.githubusercontent.com/SleepyVibesAlt/StarFall-Hub/main/"
local GAMES_REMOTE = REPO_BASE .. "StarFall_Hub/games/"

-- ============ LOADING SCREEN ============
local LoadingScreen = Instance.new("ScreenGui")
LoadingScreen.Name = "StarFallLoading"
LoadingScreen.ResetOnSpawn = false
LoadingScreen.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
LoadingScreen.IgnoreGuiInset = true
LoadingScreen.Parent = PlayerGui

local LoadingFrame = Instance.new("Frame")
LoadingFrame.Size = UDim2.fromScale(1, 1)
LoadingFrame.BackgroundColor3 = Color3.fromRGB(18, 18, 24)
LoadingFrame.BorderSizePixel = 0
LoadingFrame.Parent = LoadingScreen

local LoadingTitle = Instance.new("TextLabel")
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
LoadingSubtitle.Size = UDim2.new(1, 0, 0, 20)
LoadingSubtitle.Position = UDim2.new(0, 0, 0, 248)
LoadingSubtitle.BackgroundTransparency = 1
LoadingSubtitle.Text = "Initializing..."
LoadingSubtitle.TextColor3 = Color3.fromRGB(145, 145, 160)
LoadingSubtitle.TextSize = 14
LoadingSubtitle.Font = Enum.Font.Gotham
LoadingSubtitle.TextXAlignment = Enum.TextXAlignment.Left
LoadingSubtitle.Parent = LoadingFrame

local ProgressBar = Instance.new("Frame")
ProgressBar.Name = "ProgressBar"
ProgressBar.Size = UDim2.new(0.5, 0, 0, 6)
ProgressBar.Position = UDim2.new(0.25, 0, 0, 280)
ProgressBar.BackgroundColor3 = Color3.fromRGB(34, 34, 44)
ProgressBar.BorderSizePixel = 0
ProgressBar.Parent = LoadingFrame

local ProgressFill = Instance.new("Frame")
ProgressFill.Name = "ProgressFill"
ProgressFill.Size = UDim2.new(0, 0, 1, 0)
ProgressFill.BackgroundColor3 = Color3.fromRGB(130, 90, 255)
ProgressFill.BorderSizePixel = 0
ProgressFill.Parent = ProgressBar

local StatusText = Instance.new("TextLabel")
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

-- ============ DOWNLOAD SYSTEM ============
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
        return false, "Failed to write " .. localPath
    end
    return true
end

local function ensureFile(localPath, remoteUrl)
    local exists, _ = pcall(function()
        return readfile(localPath)
    end)
    if exists then return true end
    return downloadFile(remoteUrl, localPath)
end

-- ============ DOWNLOAD PHASE ============
setProgress(5, "Downloading library...")

-- 1. Download library
local ok, err = ensureFile("guis/library.lua", REPO_BASE .. "guis/library.lua")
if not ok then
    setProgress(100, "Error: " .. tostring(err))
    task.wait(3)
    LoadingScreen:Destroy()
    error(tostring(err))
end

-- 2. List and download game scripts
setProgress(20, "Fetching game list...")
local gameListRaw = game:HttpGet(REPO_BASE .. "StarFall_Hub/games/")
local gameFiles = {}
for line in gameListRaw:gmatch("[^\r\n]+") do
    if line:match("%.lua$") and not line:match("/$") then
        local name = line:gsub("/", ""):gsub("%.lua$", "")
        table.insert(gameFiles, { name = name, path = "games/" .. line })
    end
end

if #gameFiles == 0 then
    setProgress(100, "No games found in repository")
    task.wait(3)
    LoadingScreen:Destroy()
    error("No games found in the repository!")
end

-- 3. Download each game script
local downloaded = 0
for i, game in ipairs(gameFiles) do
    setProgress(20 + math.floor((i / #gameFiles) * 70), "Downloading " .. game.name .. ".lua (" .. i .. "/" .. #gameFiles .. ")")
    local url = GAMES_REMOTE .. game.path
    local success = ensureFile(game.path, url)
    if not success then
        print("[StarFall] Failed to download " .. game.name)
    else
        downloaded = downloaded + 1
    end
    task.wait(0.05)
end

setProgress(95, "Setup complete (" .. downloaded .. " game(s) downloaded)")
task.wait(0.3)
closeLoadingScreen()

-- ============ HUB UI ============
local SmoothUI = loadstring(readfile("guis/library.lua"))()
local Library = SmoothUI.new()

local Window = Library:CreateWindow({
    Title = "StarFall Hub"
})

-- ============ RUN SCRIPT ============
local function runScript(filePath)
    local success, result = pcall(function()
        local content = readfile(filePath)
        if not content then error("Cannot read file: " .. filePath) end
        local fn = loadstring(content, filePath)
        if not fn then error("Invalid script: " .. filePath) end
        fn()
    end)
    if not success then
        Library:Notify("Error", tostring(result), 5)
        print("[StarFall] Error: " .. tostring(result))
    else
        Library:Notify("Loaded", filePath, 2)
    end
end

-- ============ GAMES TAB ============
local GamesTab = Window:CreateTab("Games")
local GamesSection = GamesTab:CreateSection("Game Scripts")

for _, game in ipairs(gameFiles) do
    GamesSection:CreateButton({
        Name = game.name,
        Callback = function()
            runScript(game.path)
        end
    })
end

GamesSection:CreateButton({
    Name = "Refresh & Re-download All",
    Callback = function()
        -- Delete all downloaded games
        for _, game in ipairs(gameFiles) do
            pcall(function() delfile(game.path) end)
        end
        pcall(function() delfile("guis/library.lua") end)
        -- Force re-download
        for _, game in ipairs(gameFiles) do
            downloadFile(GAMES_REMOTE .. game.path, game.path)
        end
        downloadFile(REPO_BASE .. "guis/library.lua", "guis/library.lua")
        Library:Notify("Refreshed", "All scripts re-downloaded!", 3)
    end
})

-- ============ SETTINGS TAB ============
local SettingsTab = Window:CreateTab("Settings")
local SettingsSection = SettingsTab:CreateSection("Options")

SettingsSection:CreateLabel({
    Text = "Games available: " .. #gameFiles,
    Height = 30
})

SettingsSection:CreateButton({
    Name = "Open Games Folder",
    Callback = function()
        setclipboard("games/")
        Library:Notify("Copied", "Path copied to clipboard", 2)
    end
})

SettingsSection:CreateButton({
    Name = "Current PlaceID",
    Callback = function()
        Library:Notify("Place ID", tostring(game.PlaceId), 3)
    end
})

-- ============ INIT ============
Library:Notify("StarFall Hub", "Ready! Press RightShift to toggle.", 4)
