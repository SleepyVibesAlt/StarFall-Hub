
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
StarFallLoading.Parent = PlayerGui
StarFallLoading.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
StarFallLoading.ResetOnSpawn = false

local LoadingFrame = Instance.new("Frame")
LoadingFrame.Name = "LoadingFrame"
LoadingFrame.Parent = StarFallLoading
LoadingFrame.BackgroundColor3 = Color3.fromRGB(18, 18, 24)
LoadingFrame.BorderSizePixel = 0
LoadingFrame.Size = UDim2.fromScale(1, 1)

local LoadingTitle = Instance.new("TextLabel")
LoadingTitle.Parent = LoadingFrame
LoadingTitle.BackgroundTransparency = 1
LoadingTitle.Position = UDim2.new(0, 0, 0, 200)
LoadingTitle.Size = UDim2.new(1, 0, 0, 40)
LoadingTitle.Font = Enum.Font.GothamBold
LoadingTitle.Text = "StarFall Hub"
LoadingTitle.TextColor3 = Color3.fromRGB(130, 90, 255)
LoadingTitle.TextSize = 28

local LoadingSubtitle = Instance.new("TextLabel")
LoadingSubtitle.Parent = LoadingFrame
LoadingSubtitle.BackgroundTransparency = 1
LoadingSubtitle.Position = UDim2.new(0, 0, 0, 248)
LoadingSubtitle.Size = UDim2.new(1, 0, 0, 20)
LoadingSubtitle.Font = Enum.Font.Gotham
LoadingSubtitle.Text = "Initializing..."
LoadingSubtitle.TextColor3 = Color3.fromRGB(145, 145, 160)
LoadingSubtitle.TextSize = 14

local ProgressBar = Instance.new("Frame")
ProgressBar.Parent = LoadingFrame
ProgressBar.BackgroundColor3 = Color3.fromRGB(34, 34, 44)
ProgressBar.BorderSizePixel = 0
ProgressBar.Position = UDim2.new(0.25, 0, 0, 280)
ProgressBar.Size = UDim2.new(0.5, 0, 0, 6)

local ProgressCorner = Instance.new("UICorner")
ProgressCorner.CornerRadius = UDim.new(1, 0)
ProgressCorner.Parent = ProgressBar

local ProgressFill = Instance.new("Frame")
ProgressFill.Parent = ProgressBar
ProgressFill.BackgroundColor3 = Color3.fromRGB(130, 90, 255)
ProgressFill.BorderSizePixel = 0
ProgressFill.Size = UDim2.new(0, 0, 1, 0)

local FillCorner = Instance.new("UICorner")
FillCorner.CornerRadius = UDim.new(1, 0)
FillCorner.Parent = ProgressFill

local UIGradient = Instance.new("UIGradient")
UIGradient.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.fromRGB(105, 75, 235)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(165, 110, 255))
})
UIGradient.Parent = ProgressFill

local StatusText = Instance.new("TextLabel")
StatusText.Parent = LoadingFrame
StatusText.BackgroundTransparency = 1
StatusText.Position = UDim2.new(0, 0, 0, 292)
StatusText.Size = UDim2.new(1, 0, 0, 20)
StatusText.Font = Enum.Font.Gotham
StatusText.Text = "0%"
StatusText.TextColor3 = Color3.fromRGB(145, 145, 160)
StatusText.TextSize = 12

--// LOADING SCREEN FADE IN
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

--// PROGRESS
local function setProgress(percent, status)
    percent = math.clamp(percent, 0, 100)

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
    if isfile then
        local success, exists = pcall(isfile, localPath)

        if success and exists then
            return true
        end
    end

    return downloadFile(remoteUrl, localPath)
end

--// ASSET DOWNLOADER
-- Add image files and other assets here.
-- Files are stored in Starfall_Hub/assets/.

local AssetsToDownload = {
    -- Example:
    -- ["logo.png"] = "https://example.com/logo.png",
    -- ["icon.png"] = "https://example.com/icon.png",
}

local function installAssets(forceUpdate)
    local installed = 0
    local skipped = 0
    local failed = 0

    for fileName, remoteUrl in pairs(AssetsToDownload) do
        local localPath = ASSET_DIR .. "/" .. fileName

        local exists = false

        if isfile then
            local success, result = pcall(isfile, localPath)
            exists = success and result == true
        end

        if exists and not forceUpdate then
            skipped += 1
        else
            local success, err = downloadFile(remoteUrl, localPath)

            if success then
                installed += 1
            else
                failed += 1
                warn("[StarFall] Asset error: " .. tostring(err))
            end
        end
    end

    return installed, skipped, failed
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
local function installRepositoryGames(forceUpdate)
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
    local skipped = 0
    local failed = 0

    for _, entry in ipairs(entries) do
        if entry.type == "file"
            and type(entry.name) == "string"
            and entry.name:match("%.lua$")
            and type(entry.download_url) == "string" then

            local localPath = GAME_DIR .. "/" .. entry.name
            local exists = false

            if isfile then
                local success, result = pcall(isfile, localPath)
                exists = success and result == true
            end

            if exists and not forceUpdate then
                skipped += 1
            else
                local success, err = downloadFile(entry.download_url, localPath)

                if success then
                    installed += 1
                else
                    failed += 1
                    warn("[StarFall] Could not install " .. entry.name .. ": " .. tostring(err))
                end
            end
        end
    end

    return true, installed, skipped, failed
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

local assetInstalled, assetSkipped, assetFailed = installAssets(false)

--// PHASE 3: GAMES
progress(1, "Installing games...")

local gamesOk, gamesInstalled, gamesSkipped, gamesFailed =
    installRepositoryGames(false)

if not gamesOk then
    warn("[StarFall] " .. tostring(gamesInstalled))
end

--// PHASE 4: GAME DETECTION
progress(1, "Detecting game...")

task.wait(0.1)

local PlaceId = game.PlaceId
local GameScript = GameMap[PlaceId]

if GameScript then
    setProgress(100, "Game detected!")
else
    setProgress(100, "Game not in library — opening hub...")
end

--// GUI LIBRARY
local librarySource = readfile(GUI_DIR .. "/library.lua")

--// SMOOTH WINDOW PATCH
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
            installRepositoryGames(true)

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

        local installed, skipped, failed = installAssets(true)

        local ok, gameInstalled, gameSkipped, gameFailed =
            installRepositoryGames(true)

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
    task.wait(1)

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

--// OPEN HUB
Window:SetVisible(true)

closeLoadingScreen()

Library:Notify(
    "StarFall Hub",
    "Ready! Press RightShift to toggle.",
    4
)
