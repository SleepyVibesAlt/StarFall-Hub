
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
LoadingSubtitle.Position = UDim2.new(0, 0, 0, 228)
LoadingSubtitle.BackgroundTransparency = 1
LoadingSubtitle.Text = "Initializing..."
LoadingSubtitle.TextColor3 = Color3.fromRGB(145, 145, 160)
LoadingSubtitle.TextSize = 14
LoadingSubtitle.Font = Enum.Font.Gotham
LoadingSubtitle.TextXAlignment = Enum.TextXAlignment.Center
LoadingSubtitle.Parent = LoadingFrame

-- Phase indicators container
local PhaseContainer = Instance.new("Frame")
PhaseContainer.Name = "PhaseContainer"
PhaseContainer.Size = UDim2.new(0.5, 0, 0, 24)
PhaseContainer.Position = UDim2.new(0.25, 0, 0, 256)
PhaseContainer.BackgroundTransparency = 1
PhaseContainer.Parent = LoadingFrame

local PhaseLayout = Instance.new("UIListLayout")
PhaseLayout.FillDirection = Enum.FillDirection.Horizontal
PhaseLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
PhaseLayout.VerticalAlignment = Enum.VerticalAlignment.Center
PhaseLayout.Padding = UDim.new(0, 8)
PhaseLayout.Parent = PhaseContainer

-- Phase labels (will be created dynamically)
local phaseLabels = {}
local phaseArrows = {}
local PHASES = {"Downloading", "Verifying", "Installing", "Ready"}

for i, phaseName in ipairs(PHASES) do
	local phaseFrame = Instance.new("Frame")
	phaseFrame.Name = "Phase_" .. phaseName
	phaseFrame.Size = UDim2.new(0, 0, 1, 0)
	phaseFrame.AutomaticSize = Enum.AutomaticSize.X
	phaseFrame.BackgroundTransparency = 1
	phaseFrame.LayoutOrder = i
	phaseFrame.Parent = PhaseContainer

	local phaseLabel = Instance.new("TextLabel")
	phaseLabel.Name = "Label"
	phaseLabel.Size = UDim2.new(0, 0, 1, 0)
	phaseLabel.AutomaticSize = Enum.AutomaticSize.X
	phaseLabel.BackgroundTransparency = 1
	phaseLabel.Text = phaseName
	phaseLabel.TextColor3 = Color3.fromRGB(80, 80, 95)
	phaseLabel.TextSize = 11
	phaseLabel.Font = Enum.Font.GothamMedium
	phaseLabel.TextXAlignment = Enum.TextXAlignment.Center
	phaseLabel.Parent = phaseFrame

	local phaseDot = Instance.new("Frame")
	phaseDot.Name = "Dot"
	phaseDot.Size = UDim2.new(0, 8, 0, 8)
	phaseDot.Position = UDim2.new(0.5, -4, 1, 4)
	phaseDot.AnchorPoint = Vector2.new(0.5, 0)
	phaseDot.BackgroundColor3 = Color3.fromRGB(80, 80, 95)
	phaseDot.BorderSizePixel = 0
	phaseDot.Parent = phaseFrame

	local dotCorner = Instance.new("UICorner")
	dotCorner.CornerRadius = UDim.new(1, 0)
	dotCorner.Parent = phaseDot

	phaseLabels[i] = {frame = phaseFrame, label = phaseLabel, dot = phaseDot}

	-- Add arrow between phases (except last)
	if i < #PHASES then
		local arrow = Instance.new("TextLabel")
		arrow.Name = "Arrow"
		arrow.Size = UDim2.new(0, 16, 1, 0)
		arrow.BackgroundTransparency = 1
		arrow.Text = "▸"
		arrow.TextColor3 = Color3.fromRGB(60, 60, 75)
		arrow.TextSize = 14
		arrow.Font = Enum.Font.Gotham
		arrow.TextXAlignment = Enum.TextXAlignment.Center
		arrow.LayoutOrder = i + 0.5  -- Between phases
		arrow.Parent = PhaseContainer
		table.insert(phaseArrows, arrow)
	end
end

local ProgressBar = Instance.new("Frame")
ProgressBar.Name = "ProgressBar"
ProgressBar.Size = UDim2.new(0.5, 0, 0, 6)
ProgressBar.Position = UDim2.new(0.25, 0, 0, 296)
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
StatusText.Position = UDim2.new(0, 0, 0, 308)
StatusText.BackgroundTransparency = 1
StatusText.Text = "0%"
StatusText.TextColor3 = Color3.fromRGB(145, 145, 160)
StatusText.TextSize = 12
StatusText.Font = Enum.Font.Gotham
StatusText.TextXAlignment = Enum.TextXAlignment.Center
StatusText.Parent = LoadingFrame

-- Tips label (rotating tips)
local TipsLabel = Instance.new("TextLabel")
TipsLabel.Name = "TipsLabel"
TipsLabel.Size = UDim2.new(1, -40, 0, 20)
TipsLabel.Position = UDim2.new(0, 20, 1, -60)
TipsLabel.BackgroundTransparency = 1
TipsLabel.Text = ""
TipsLabel.TextColor3 = Color3.fromRGB(90, 90, 105)
TipsLabel.TextSize = 12
TipsLabel.Font = Enum.Font.Gotham
TipsLabel.TextXAlignment = Enum.TextXAlignment.Center
TipsLabel.TextWrapped = true
TipsLabel.Parent = LoadingFrame

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

--// ROTATING TIPS
local LOADING_TIPS = {
	"Tip: Press RightShift to toggle the hub anytime.",
	"Tip: Game scripts auto-load when you join a supported game.",
	"Tip: Use 'Install / Update Games' to get the latest scripts.",
	"Tip: Check the Settings tab for PlaceID and asset updates.",
	"Tip: Scripts are cached locally for faster loading next time.",
	"Tip: Report bugs on the StarFall Hub GitHub repository.",
	"Tip: The hub works on most popular executors.",
	"Tip: Right-click the title bar to minimize quickly.",
}

local tipIndex = 1
local tipsRunning = true

task.spawn(function()
	while tipsRunning and StarFallLoading and StarFallLoading.Parent do
		if TipsLabel and TipsLabel.Parent then
			TipsLabel.Text = LOADING_TIPS[tipIndex]
		end
		tipIndex = tipIndex % #LOADING_TIPS + 1
		task.wait(4) -- Rotate tip every 4 seconds
	end
end)

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

--// PHASE INDICATORS
local function setPhase(phaseIndex)
    phaseIndex = math.clamp(phaseIndex, 1, #PHASES)

    for i, phaseData in ipairs(phaseLabels) do
        local isActive = i <= phaseIndex
        local isComplete = i < phaseIndex

        if isComplete then
            -- Completed phase - purple
            TweenService:Create(
                phaseData.label,
                TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
                {TextColor3 = Color3.fromRGB(130, 90, 255)}
            ):Play()
            TweenService:Create(
                phaseData.dot,
                TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
                {BackgroundColor3 = Color3.fromRGB(130, 90, 255)}
            ):Play()
        elseif isActive then
            -- Current phase - bright purple with pulse
            TweenService:Create(
                phaseData.label,
                TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
                {TextColor3 = Color3.fromRGB(165, 110, 255)}
            ):Play()
            TweenService:Create(
                phaseData.dot,
                TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
                {BackgroundColor3 = Color3.fromRGB(165, 110, 255)}
            ):Play()

            -- Pulse animation for current phase
            task.spawn(function()
                while tipsRunning and phaseLabels[i] and phaseLabels[i].dot and i == phaseIndex do
                    TweenService:Create(
                        phaseLabels[i].dot,
                        TweenInfo.new(0.8, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut),
                        {Size = UDim2.new(0, 12, 0, 12)}
                    ):Play()
                    task.wait(0.8)
                    if not (phaseLabels[i] and i == phaseIndex) then break end
                    TweenService:Create(
                        phaseLabels[i].dot,
                        TweenInfo.new(0.8, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut),
                        {Size = UDim2.new(0, 8, 0, 8)}
                    ):Play()
                    task.wait(0.8)
                end
            end)
        else
            -- Future phase - dim
            TweenService:Create(
                phaseData.label,
                TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
                {TextColor3 = Color3.fromRGB(80, 80, 95)}
            ):Play()
            TweenService:Create(
                phaseData.dot,
                TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
                {BackgroundColor3 = Color3.fromRGB(80, 80, 95), Size = UDim2.new(0, 8, 0, 8)}
            ):Play()
        end

        -- Update arrows
        for arrowIdx, arrow in ipairs(phaseArrows) do
            -- Color arrow based on completion (arrowIdx corresponds to phase before it)
            if arrowIdx < phaseIndex then
                arrow.TextColor3 = Color3.fromRGB(130, 90, 255)
            else
                arrow.TextColor3 = Color3.fromRGB(60, 60, 75)
            end
        end
    end
end

local function closeLoadingScreen()
    if not StarFallLoading or not StarFallLoading.Parent then
        return
    end

    -- Stop rotating tips and phase animations
    tipsRunning = false

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

local AssetsToDownload = {
    ["left_logo.png"] = "https://raw.githubusercontent.com/SleepyVibesAlt/StarFall-Hub/main/assets/Logo-Left.png",
    ["right_logo.png"] = "https://raw.githubusercontent.com/SleepyVibesAlt/StarFall-Hub/main/assets/Logo-Right.png",
}

-- Verify if local asset matches remote (by content comparison)
local function verifyAsset(localPath, remoteUrl)
    if not isfile then return false end

    local success, exists = pcall(isfile, localPath)
    if not success or not exists then return false end

    -- Get local file content
    local readOk, localContent = pcall(readfile, localPath)
    if not readOk or type(localContent) ~= "string" then return false end

    -- Get remote file content
    local getOk, remoteContent = pcall(function()
        return game:HttpGet(remoteUrl)
    end)
    if not getOk or type(remoteContent) ~= "string" then return false end

    -- Compare content (size is usually enough, but content is more accurate)
    return #localContent == #remoteContent
end

local function installAssets(forceUpdate)
    local installed = 0
    local skipped = 0
    local failed = 0

    for fileName, remoteUrl in pairs(AssetsToDownload) do
        local localPath = ASSET_DIR .. "/" .. fileName

        local needsUpdate = forceUpdate

        if not needsUpdate then
            local isValid = verifyAsset(localPath, remoteUrl)
            if not isValid then
                needsUpdate = true
            else
                skipped += 1
            end
        end

        if needsUpdate then
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

--// PHASE 1: GUI LIBRARY (Downloading)
setPhase(1)
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

--// PHASE 2: ASSETS (Verifying)
setPhase(2)
progress(1, "Installing assets...")

local assetInstalled, assetSkipped, assetFailed = installAssets(false)

--// PHASE 3: GAMES (Installing)
setPhase(3)
progress(1, "Installing games...")

local gamesOk, gamesInstalled, gamesSkipped, gamesFailed =
    installRepositoryGames(false)

if not gamesOk then
    warn("[StarFall] " .. tostring(gamesInstalled))
end

--// PHASE 4: GAME DETECTION (Ready)
setPhase(4)
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

--// AUTO UPDATE CHECK
local function checkForUpdates()
    local requestOk, response = pcall(function()
        return game:HttpGet(REPO_BASE .. "guis/library.lua")
    end)

    if not requestOk or type(response) ~= "string" then
        return false, "Failed to check for updates"
    end

    local localOk, localContent = pcall(readfile, GUI_DIR .. "/library.lua")
    if not localOk or type(localContent) ~= "string" then
        return false, "Failed to read local library"
    end

    -- Compare content (simple size check, could use hash for better accuracy)
    if #localContent ~= #response then
        return true, "Update available"
    end

    return false, "Up to date"
end

-- Run update check in background
task.spawn(function()
    local hasUpdate, msg = checkForUpdates()
    if hasUpdate and Library and Library.Notify then
        Library:Notify("Update Available", msg .. " — Click 'Re-download Assets' to update", 6)
    end
end)

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