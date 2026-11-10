local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local Player = Players.LocalPlayer
local Parent = (gethui and gethui()) or Player:WaitForChild("PlayerGui")

local Folder = "Starfall_Hub"
local KeyFile = Folder .. "/Key.txt"
local SDK_URL = "https://auth.hungquan99.lol/sdk/library.lua"
local SCRIPT_ID = "starfall-hub"

if not isfolder(Folder) then
    makefolder(Folder)
end

local Theme = {
    Background = Color3.fromRGB(18, 18, 24),
    Secondary = Color3.fromRGB(26, 26, 34),
    Element = Color3.fromRGB(34, 34, 44),
    Accent = Color3.fromRGB(130, 90, 255),
    Text = Color3.fromRGB(240, 240, 245),
    Muted = Color3.fromRGB(145, 145, 160),
    Border = Color3.fromRGB(48, 48, 60),
    Success = Color3.fromRGB(90, 210, 130),
    Error = Color3.fromRGB(235, 85, 95)
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
    local animation = TweenService:Create(
        object,
        TweenInfo.new(duration or 0.2, Enum.EasingStyle.Quart, Enum.EasingDirection.Out),
        properties
    )

    animation:Play()
    return animation
end

local Existing = Parent:FindFirstChild("StarfallKeySystem")
if Existing then
    Existing:Destroy()
end

local ScreenGui = Create("ScreenGui", {
    Name = "StarfallKeySystem",
    ResetOnSpawn = false,
    ZIndexBehavior = Enum.ZIndexBehavior.Sibling
}, Parent)

local Main = Create("Frame", {
    Name = "Main",
    Size = UDim2.fromOffset(370, 235),
    Position = UDim2.fromScale(0.5, 0.5),
    AnchorPoint = Vector2.new(0.5, 0.5),
    BackgroundColor3 = Theme.Background,
    BorderSizePixel = 0
}, ScreenGui)

Corner(Main, 12)
Stroke(Main, Theme.Border)

local Topbar = Create("Frame", {
    Size = UDim2.new(1, 0, 0, 48),
    BackgroundColor3 = Theme.Secondary,
    BorderSizePixel = 0
}, Main)

Corner(Topbar, 12)

Create("Frame", {
    Position = UDim2.new(0, 0, 1, -12),
    Size = UDim2.new(1, 0, 0, 12),
    BackgroundColor3 = Theme.Secondary,
    BorderSizePixel = 0
}, Topbar)

Create("TextLabel", {
    Position = UDim2.fromOffset(16, 0),
    Size = UDim2.new(1, -60, 1, 0),
    BackgroundTransparency = 1,
    Text = "STARFALL HUB",
    TextColor3 = Theme.Text,
    TextSize = 16,
    Font = Enum.Font.GothamBold,
    TextXAlignment = Enum.TextXAlignment.Left
}, Topbar)

local CloseButton = Create("TextButton", {
    Size = UDim2.fromOffset(30, 30),
    Position = UDim2.new(1, -40, 0, 9),
    BackgroundColor3 = Theme.Element,
    Text = "×",
    TextColor3 = Theme.Muted,
    TextSize = 21,
    Font = Enum.Font.GothamMedium,
    AutoButtonColor = false
}, Topbar)

Corner(CloseButton, 7)

CloseButton.MouseButton1Click:Connect(function()
    Tween(Main, {
        Size = UDim2.fromOffset(340, 210),
        BackgroundTransparency = 1
    }, 0.2)

    task.wait(0.2)
    ScreenGui:Destroy()
end)

Create("TextLabel", {
    Position = UDim2.fromOffset(20, 62),
    Size = UDim2.new(1, -40, 0, 25),
    BackgroundTransparency = 1,
    Text = "Enter your access key",
    TextColor3 = Theme.Text,
    TextSize = 15,
    Font = Enum.Font.GothamBold,
    TextXAlignment = Enum.TextXAlignment.Left
}, Main)

Create("TextLabel", {
    Position = UDim2.fromOffset(20, 87),
    Size = UDim2.new(1, -40, 0, 20),
    BackgroundTransparency = 1,
    Text = "Your key will be saved automatically.",
    TextColor3 = Theme.Muted,
    TextSize = 11,
    Font = Enum.Font.Gotham,
    TextXAlignment = Enum.TextXAlignment.Left
}, Main)

local KeyBox = Create("TextBox", {
    Name = "KeyInput",
    Position = UDim2.fromOffset(20, 119),
    Size = UDim2.new(1, -40, 0, 38),
    BackgroundColor3 = Theme.Element,
    BorderSizePixel = 0,
    Text = "",
    PlaceholderText = "Enter your key...",
    PlaceholderColor3 = Theme.Muted,
    TextColor3 = Theme.Text,
    TextSize = 12,
    Font = Enum.Font.Gotham,
    ClearTextOnFocus = false,
    TextXAlignment = Enum.TextXAlignment.Left
}, Main)

Corner(KeyBox, 7)
Stroke(KeyBox, Theme.Border, 0.2)

Create("UIPadding", {
    PaddingLeft = UDim.new(0, 12),
    PaddingRight = UDim.new(0, 12)
}, KeyBox)

local VerifyButton = Create("TextButton", {
    Name = "VerifyButton",
    Position = UDim2.fromOffset(20, 168),
    Size = UDim2.new(1, -40, 0, 35),
    BackgroundColor3 = Theme.Accent,
    BorderSizePixel = 0,
    Text = "Verify Key",
    TextColor3 = Theme.Text,
    TextSize = 13,
    Font = Enum.Font.GothamBold,
    AutoButtonColor = false
}, Main)

Corner(VerifyButton, 7)

local Status = Create("TextLabel", {
    Position = UDim2.fromOffset(20, 207),
    Size = UDim2.new(1, -40, 0, 18),
    BackgroundTransparency = 1,
    Text = "Waiting for key...",
    TextColor3 = Theme.Muted,
    TextSize = 10,
    Font = Enum.Font.Gotham,
    TextXAlignment = Enum.TextXAlignment.Center
}, Main)

local function SetStatus(message, color)
    Status.Text = message
    Status.TextColor3 = color or Theme.Muted
end

local function LoadSavedKey()
    if isfile(KeyFile) then
        local success, savedKey = pcall(readfile, KeyFile)

        if success and type(savedKey) == "string" and savedKey ~= "" then
            return savedKey
        end
    end

    if getgenv().script_key then
        return tostring(getgenv().script_key)
    end

    return ""
end

KeyBox.Text = LoadSavedKey()

local Checking = false

local function VerifyKey()
    if Checking then
        return
    end

    local key = KeyBox.Text:gsub("^%s+", ""):gsub("%s+$", "")

    if key == "" then
        SetStatus("Please enter a key.", Theme.Error)
        return
    end

    Checking = true
    VerifyButton.Text = "Verifying..."
    VerifyButton.BackgroundColor3 = Theme.Element
    SetStatus("Checking your key...", Theme.Muted)

    task.spawn(function()
        local success, result = pcall(function()
            local api = loadstring(game:HttpGet(SDK_URL))()

            api.script_id = SCRIPT_ID

            local response = api.check_key(key)

            if response.code == "KEY_VALID" or response.code == "KEYLESS" then
                if not isfolder(Folder) then
                    makefolder(Folder)
                end

                writefile(KeyFile, key)
                getgenv().script_key = key

                SetStatus("Key accepted. Loading...", Theme.Success)
                VerifyButton.Text = "Verified"

                task.wait(0.4)
                api.load_script(key)
            elseif response.code == "KEY_HWID_LOCKED" then
                SetStatus("Key is locked to another device.", Theme.Error)
            elseif response.code == "KEY_EXPIRED" then
                SetStatus("Your key has expired.", Theme.Error)
            else
                SetStatus(tostring(response.code) .. ": " .. tostring(response.message), Theme.Error)
            end
        end)

        if not success then
            SetStatus("Error: " .. tostring(result), Theme.Error)
        end

        Checking = false

        if VerifyButton and VerifyButton.Parent then
            VerifyButton.Text = "Verify Key"
            VerifyButton.BackgroundColor3 = Theme.Accent
        end
    end)
end

VerifyButton.MouseButton1Click:Connect(VerifyKey)

KeyBox.FocusLost:Connect(function(enterPressed)
    if enterPressed then
        VerifyKey()
    end
end)

VerifyButton.MouseEnter:Connect(function()
    if not Checking then
        Tween(VerifyButton, {
            BackgroundColor3 = Theme.Accent:Lerp(Color3.new(1, 1, 1), 0.12)
        })
    end
end)

VerifyButton.MouseLeave:Connect(function()
    if not Checking then
        Tween(VerifyButton, {
            BackgroundColor3 = Theme.Accent
        })
    end
end)

local Dragging = false
local DragStart
local StartPosition

Topbar.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then

        Dragging = true
        DragStart = input.Position
        StartPosition = Main.Position
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if Dragging and (
        input.UserInputType == Enum.UserInputType.MouseMovement
        or input.UserInputType == Enum.UserInputType.Touch
    ) then
        local delta = input.Position - DragStart

        Main.Position = UDim2.new(
            StartPosition.X.Scale,
            StartPosition.X.Offset + delta.X,
            StartPosition.Y.Scale,
            StartPosition.Y.Offset + delta.Y
        )
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
        Dragging = false
    end
end)

Main.Size = UDim2.fromOffset(340, 210)
Main.BackgroundTransparency = 1

Tween(Main, {
    Size = UDim2.fromOffset(370, 235),
    BackgroundTransparency = 0
}, 0.3)