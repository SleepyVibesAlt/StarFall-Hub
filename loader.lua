
--// STARFALL HUB — LOADER
--// Downloads assets, installs game scripts, detects PlaceID,
--// and loads the matching script.

--// SERVICES
local Players = game:GetService("Players")
local Player = Players.LocalPlayer
local PlayerGui = Player:WaitForChild("PlayerGui")
local TweenService = game:GetService("TweenService")
local HttpService = game:GetService("HttpService")

--// REPOSITORY
local REPO_BASE = "https://raw.githubusercontent.com/SleepyVibesAlt/StarFall-Hub/main/"
local REPO_API = "https://api.github.com/repos/SleepyVibesAlt/StarFall-Hub/contents/games?ref=main"

--// DIRECTORIES
local ROOT_DIR = "Starfall_Hub"
local GUI_DIR = ROOT_DIR .. "/guis"
local GAME_DIR = ROOT_DIR .. "/games"
local ASSET_DIR = ROOT_DIR .. "/assets"

--// FILE SYSTEM
local function ensureFolder(path)
    if isfolder then
        local success, exists = pcall(isfolder, path)
        if success and exists then
            return true
        end
    end

    local success, err = pcall(makefolder, path)

    if not success then
        if isfolder then
            local checkSuccess, exists = pcall(isfolder, path)
            if checkSuccess and exists then
                return true
            end
        end

        return false, tostring(err)
    end

    return true
end

local function prepareFolders()
    for _, folder in ipairs({
        ROOT_DIR,
        GUI_DIR,
        GAME_DIR,
        ASSET_DIR
    }) do
        local success, err = ensureFolder(folder)

        if not success then
            return false, "Could not create " .. folder .. ": " .. tostring(err)
        end
    end

    return true
end

local foldersReady, folderError = prepareFolders()

if not foldersReady then
    error("[StarFall] " .. tostring(folderError))
end

--// LOADING SCREEN
local StarFallLoading = Instance.new("ScreenGui")
StarFallLoading.Name = "StarFallLoading"
StarFallLoading.ResetOnSpawn = false
StarFallLoading.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
StarFallLoading.IgnoreGuiInset = true
StarFallLoading.Parent = PlayerGui

local LoadingFrame = Instance.new("Frame")
LoadingFrame.Name = "LoadingFrame"
LoadingFrame.Size = UDim2.fromScale(1, 1)
LoadingFrame.BackgroundColor3 = Color3.fromRGB(18, 18, 24)
LoadingFrame.BorderSizePixel = 0
LoadingFrame.Parent = StarFallLoading

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

for _, object in ipairs(LoadingFrame:GetDescendants()) do
    if object:IsA("Frame") then
        object.BackgroundTransparency = 1

        TweenService:Create(
            object,
            TweenInfo.new(0.45, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
            {BackgroundTransparency = 0}
        ):Play()

    elseif object:IsA("TextLabel") then
        object.TextTransparency = 1

        TweenService:Create(
            object,
            TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
            {TextTransparency = 0}
        ):Play()
    end
end

TweenService:Create(
    LoadingFrame,
    TweenInfo.new(0.45, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
    {BackgroundTransparency = 0}
):Play()

-- Timing config (must be before setProgress which uses them)
local loadStartTime = tick()
local MIN_LOAD_TIME = 3 -- seconds

--// PROGRESS
local function setProgress(percent, status)
    percent = math.clamp(percent, 0, 100)

    -- Cap progress bar at 15% until minimum load time is reached
    local elapsed = tick() - loadStartTime
    if elapsed < MIN_LOAD_TIME then
        percent = math.min(percent, 15)
    end

    TweenService:Create(
        ProgressFill,
        TweenInfo.new(0.4, Enum.EasingStyle.Quart, Enum.EasingDirection.Out),
        {Size = UDim2.new(percent / 100, 0, 1, 0)}
    ):Play()

    StatusText.Text = percent .. "% — " .. status
    LoadingSubtitle.Text = status
end

local function closeLoadingScreen()
    if not StarFallLoading or not StarFallLoading.Parent then
        return
    end

    local tweens = {}

    for _, object in ipairs(LoadingFrame:GetDescendants()) do
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

    if StarFallLoading and StarFallLoading.Parent then
        StarFallLoading:Destroy()
    end
end

--// FILE DOWNLOADER
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
    -- Always redownload, skip verification
    return downloadFile(remoteUrl, localPath)
end

local AssetsToDownload = {
    ["left_logo.png"] = "https://raw.githubusercontent.com/SleepyVibesAlt/StarFall-Hub/main/assets/Logo-Left.png",
    ["right_logo.png"] = "https://raw.githubusercontent.com/SleepyVibesAlt/StarFall-Hub/main/assets/Logo-Right.png",
}

local function installAssets()
    local installed = 0
    local failed = 0

    for fileName, remoteUrl in pairs(AssetsToDownload) do
        local localPath = ASSET_DIR .. "/" .. fileName

        -- Always redownload
        local success, err = downloadFile(remoteUrl, localPath)

        if success then
            installed += 1
        else
            failed += 1
            warn("[StarFall] Asset error: " .. tostring(err))
        end
    end

    return installed, 0, failed
end

--// ASSET LOADER
local function getAsset(fileName)
    local path = ASSET_DIR .. "/" .. fileName

    if not isfile or not getcustomasset then
        warn("[StarFall] Custom assets are not supported by this executor.")
        return nil
    end

    local success, exists = pcall(isfile, path)

    if not success or not exists then
        warn("[StarFall] Asset does not exist: " .. path)
        return nil
    end

    local assetSuccess, asset = pcall(getcustomasset, path)

    if not assetSuccess then
        warn("[StarFall] Could not load asset: " .. tostring(asset))
        return nil
    end

    return asset
end

--// GAME MAP
local GameMap = {
    [124357835578554] = GAME_DIR .. "/124357835578554.lua",

    -- [PLACE_ID] = GAME_DIR .. "/PLACE_ID.lua",
}

--// GAMES DIRECTORY INSTALLER
local function installRepositoryGames()
    local requestOk, response = pcall(function()
        return game:HttpGet(REPO_API)
    end)

    if not requestOk or type(response) ~= "string" then
        return false, "Could not retrieve GitHub games directory."
    end

    local decodeOk, entries = pcall(function()
        return HttpService:JSONDecode(response)
    end)

    if not decodeOk or type(entries) ~= "table" then
        return false, "GitHub returned an invalid directory listing."
    end

    local installed = 0
    local failed = 0

    for _, entry in ipairs(entries) do
        if entry.type == "file"
            and type(entry.name) == "string"
            and entry.name:match("%.lua$")
            and type(entry.download_url) == "string" then

            local localPath = GAME_DIR .. "/" .. entry.name

            -- Always redownload
            local success, err = downloadFile(entry.download_url, localPath)

            if success then
                installed += 1
            else
                failed += 1
                warn("[StarFall] Could not install " .. entry.name .. ": " .. tostring(err))
            end
        end
    end

    return true, installed, 0, failed
end

--// SETUP
local FilesToDownload = {
    [GUI_DIR .. "/library.lua"] = REPO_BASE .. "guis/library.lua",
}

local totalSteps = #FilesToDownload + 3
local currentStep = 0

local function progress(amount, status)
    currentStep += amount

    local percent = math.floor((currentStep / totalSteps) * 100)
    setProgress(math.min(percent, 100), status)
end

--// PHASE 1: GUI LIBRARY
for localPath, remoteUrl in pairs(FilesToDownload) do
    progress(1, "Downloading GUI library...")

    local success, err = ensureFile(localPath, remoteUrl)

    if not success then
        setProgress(100, "Download failed")
        task.wait(2)
        closeLoadingScreen()
        error(tostring(err))
    end
end

--// PHASE 2: ASSETS
progress(1, "Installing assets...")

local assetInstalled, assetSkipped, assetFailed = installAssets()

--// PHASE 3: GAMES
progress(1, "Installing games...")

local gamesOk, gamesInstalled, gamesSkipped, gamesFailed =
    installRepositoryGames()

if not gamesOk then
    warn("[StarFall] " .. tostring(gamesInstalled))
end

--// PHASE 4: GAME DETECTION
progress(1, "Detecting game...")

task.wait(0.1)

local PlaceId = game.PlaceId
local GameScript = GameMap[PlaceId]

-- Wait until minimum load time reached
local elapsed = tick() - loadStartTime
if elapsed < MIN_LOAD_TIME then
    task.wait(MIN_LOAD_TIME - elapsed)
end

-- Animate progress from 15% to 100% with status messages
local statusMessages = {
    "Finalizing assets...",
    "Loading game data...",
    "Preparing interface...",
    "Almost ready...",
}

for i, msg in ipairs(statusMessages) do
    local targetPercent = 15 + math.floor((i / #statusMessages) * 85)
    setProgress(targetPercent, msg)
    task.wait(0.15)
end

if GameScript then
    setProgress(100, "Game detected!")
else
    setProgress(100, "Game not in library — opening hub...")
end

task.wait(0.3)

--// GUI LIBRARY
local librarySource = readfile(GUI_DIR .. "/library.lua")

local SmoothUI = loadstring(librarySource, "StarFall SmoothUI")()

if not SmoothUI then
    closeLoadingScreen()
    error("[StarFall] Failed to initialize GUI library.")
end

local Library = SmoothUI.new()

local Window = Library:CreateWindow({
    Title = "StarFall Hub",
})

--// SCRIPT LOADER
local function loadScript(filePath)
    local success, result = pcall(function()
        local content = readfile(filePath)

        if not content then
            error("Cannot read file: " .. filePath)
        end

        local fn, compileError = loadstring(content, filePath)

        if not fn then
            error(compileError or "Invalid script.")
        end

        fn()
    end)

    if not success then
        Library:Notify("Load Error", tostring(result), 5)
        warn("[StarFall] Error: " .. tostring(result))
    else
        Library:Notify("Loaded", filePath, 2)
    end

    return success
end

--// GAMES TAB
local GamesTab = Window:CreateTab("Games")
local GamesSection = GamesTab:CreateSection("Select Script")

local function getAvailableGames()
    local games = {}

    local success, files = pcall(function()
        return listfiles(GAME_DIR .. "/")
    end)

    if not success or type(files) ~= "table" then
        return games
    end

    for _, file in ipairs(files) do
        local normalized = file:gsub("\\", "/")

        if normalized:match("%.lua$") then
            local name = normalized:match("([^/]+)%.lua$")

            if name then
                table.insert(games, {
                    name = name,
                    path = file
                })
            end
        end
    end

    table.sort(games, function(a, b)
        return a.name:lower() < b.name:lower()
    end)

    return games
end

local function buildGameList()
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
        Library:Notify("Installing", "Updating game scripts...", 3)

        local ok, installed, skipped, failed =
            installRepositoryGames()

        if not ok then
            Library:Notify("Install Error", tostring(installed), 5)
            return
        end

        buildGameList()

        Library:Notify(
            "Games Updated",
            tostring(installed) .. " installed, " ..
            tostring(skipped) .. " skipped, " ..
            tostring(failed) .. " failed.",
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
            if loadScript(gameEntry.path) then
                loaded += 1
            end
        end

        Library:Notify("Loaded", loaded .. " script(s)", 3)
    end,
})

--// SETTINGS TAB
local SettingsTab = Window:CreateTab("Settings")
local SettingsSection = SettingsTab:CreateSection("Options")

SettingsSection:CreateButton({
    Name = "Re-download Assets",

    Callback = function()
        Library:Notify("Updating", "Refreshing hub assets and scripts...", 3)

        for localPath, remoteUrl in pairs(FilesToDownload) do
            local success, err = downloadFile(remoteUrl, localPath)

            if not success then
                Library:Notify("Error", tostring(err), 5)
                return
            end
        end

        local installed, skipped, failed = installAssets()

        local ok, gameInstalled, gameSkipped, gameFailed =
            installRepositoryGames()

        if not ok then
            Library:Notify("Update Error", tostring(gameInstalled), 5)
            return
        end

        buildGameList()

        Library:Notify(
            "Updated",
            tostring(installed) .. " assets and " ..
            tostring(gameInstalled) .. " games installed.",
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

--// INIT
buildGameList()

--// AUTO LOAD KNOWN GAME
if GameMap[PlaceId] then
    local success, err = ensureFile(
        GameScript,
        REPO_BASE .. "games/" .. GameScript:match("([^/]+)$")
    )

    if success then
        loadScript(GameScript)
    else
        Library:Notify("Game Error", tostring(err), 5)
    end
end

closeLoadingScreen()

Library:Notify(
    "StarFall Hub",
    "Ready! Press RightShift to toggle.",
    4
)