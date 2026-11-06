-- Game: Above

local SmoothUI = loadstring(readfile("Starfall_Hub/guis/library.lua"))()

local Library = SmoothUI.new()

local Window = Library:CreateWindow({
    Title = "Starfall-Above"
})

local Tabs = {
    Main = Window:CreateTab("AutoFarm"),
    Visuals = Window:CreateTab("Visuals"),
    Misc = Window:CreateTab("Misc")
}

local Sections = {
    Main = {
        AutoFarm = Tabs.Main:CreateSection("AutoFarm")
    },
    Visuals = {
        ESP = Tabs.Visuals:CreateSection("ESP")
    },
    Misc = {
        Misc = Tabs.Misc:CreateSection("Misc")
    }
}
