--[[
    Robot Claw Collector - vFinal Attempt - Custom UI & Refined Logic
    Designed for mobile (e.g., Delta), aiming for Moon X style.
    Focus on robust item detection and GUI stability.
]]

-- Store original print/warn functions IMMEDIATELY
local _G = getfenv(0)
local oldPrint = _G.print
local oldWarn = _G.warn

oldPrint("DEBUG: Script initiated. Custom UI & Refined Logic. Version: Final_Attempt_1")

-- Services
local CoreGui = game:GetService("CoreGui")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")

-- Script Configuration
local SCRIPT_TITLE = "Claw Collector Pro"
local MAX_CONSOLE_LINES = 120 -- Increased slightly
local CONSOLE_AUTO_SCROLL = true
local WINDOW_INITIAL_VISIBLE = true

-- GUI Instance Storage
local ScreenGui
local MainWindow
local TitleBar, TitleLabel
local SidebarFrame, ContentFrame
local Tabs = {} 
local CurrentTabContent = nil

-- Console Specific
local ConsoleScrollingFrame, ConsoleUIListLayout
local consoleLogLines = {}

-- GUI Theme/Style (Approximating Moon X)
local THEME = {
    Background = Color3.fromRGB(35, 38, 46),
    Sidebar = Color3.fromRGB(28, 30, 37),
    Content = Color3.fromRGB(35, 38, 46),
    TitleBar = Color3.fromRGB(22, 24, 29),
    TextPrimary = Color3.fromRGB(220, 221, 222),
    TextSecondary = Color3.fromRGB(150, 152, 158),
    Accent = Color3.fromRGB(88, 101, 242),
    AccentHover = Color3.fromRGB(71, 82, 196),
    Button = Color3.fromRGB(54, 57, 66),
    ButtonHover = Color3.fromRGB(64, 68, 78),
    InputBorder = Color3.fromRGB(20, 20, 20),
    ActiveTabButton = Color3.fromRGB(45, 48, 56),
    Font = Enum.Font.GothamSemibold,
    FontSecondary = Enum.Font.Gotham,
    FontSize = 14,
    FontSizeSmall = 12,
    FontSizeTitle = 16,
}

-- Forward declare functions
local AddToConsole
local CreateDraggable

-- =========================================================================
-- GUI CREATION FUNCTIONS (Copied from previous working version)
-- =========================================================================
local function CreateElement(className, properties)
    local element = Instance.new(className)
    for prop, value in pairs(properties or {}) do
        element[prop] = value
    end
    return element
end

local function SelectTab(tabData)
    if CurrentTabContent then CurrentTabContent.Visible = false end
    for _, t in ipairs(Tabs) do
         t.button.BackgroundColor3 = (t == tabData) and THEME.ActiveTabButton or THEME.Sidebar
         t.button.TextColor3 = (t == tabData) and THEME.Accent or THEME.TextPrimary
    end
    tabData.content.Visible = true
    CurrentTabContent = tabData.content
end

local function CreateSidebarButton(text, order, parent)
    local button = CreateElement("TextButton", { Name = text .. "TabButton", Text = "  " .. text, TextColor3 = THEME.TextPrimary, Font = THEME.Font, TextSize = THEME.FontSize, TextXAlignment = Enum.TextXAlignment.Left, BackgroundColor3 = THEME.Sidebar, BorderSizePixel = 0, Size = UDim2.new(1, 0, 0, 40), LayoutOrder = order, Parent = parent, })
    button.MouseEnter:Connect(function() if Tabs[order].content ~= CurrentTabContent then button.BackgroundColor3 = THEME.ButtonHover end end)
    button.MouseLeave:Connect(function() if Tabs[order].content ~= CurrentTabContent then button.BackgroundColor3 = THEME.Sidebar end end)
    return button
end

local function CreateContentPage(name, parent) return CreateElement("Frame", { Name = name .. "Page", BackgroundTransparency = 1, Size = UDim2.new(1, 0, 1, 0), Visible = false, Parent = parent, }) end

local function CreateSection(title, parentPage)
    local sectionFrame = CreateElement("Frame", { Name = title .. "Section", BackgroundTransparency = 1, Size = UDim2.new(1, -20, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, Position = UDim2.new(0, 10, 0, 10), Parent = parentPage, })
    CreateElement("UIListLayout", { Parent = sectionFrame, SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 8), })
    if title and title ~= "" then CreateElement("TextLabel", { Name = "SectionTitle", Text = title, Font = THEME.Font, TextSize = THEME.FontSizeTitle, TextColor3 = THEME.TextPrimary, TextXAlignment = Enum.TextXAlignment.Left, BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 25), LayoutOrder = 0, Parent = sectionFrame, }) end
    return sectionFrame
end

local function CreateButton(text, parentSection, callback)
    local button = CreateElement("TextButton", { Name = text .. "Button", Text = text, Font = THEME.FontSecondary, TextSize = THEME.FontSize, TextColor3 = THEME.TextPrimary, BackgroundColor3 = THEME.Button, BorderSizePixel = 1, BorderColor3 = THEME.InputBorder, Size = UDim2.new(1, 0, 0, 35), LayoutOrder = (parentSection:FindFirstChild("UIListLayout") and #parentSection:GetChildren() or 1), Parent = parentSection, })
    CreateElement("UICorner", {CornerRadius = UDim.new(0,4), Parent = button})
    button.MouseEnter:Connect(function() button.BackgroundColor3 = THEME.ButtonHover end)
    button.MouseLeave:Connect(function() button.BackgroundColor3 = THEME.Button end)
    if callback then button.MouseButton1Click:Connect(callback) end
    return button
end

local function CreateToggle(text, parentSection, initialValue, callback)
    local toggleFrame = CreateElement("Frame", { Name = text .. "Toggle", BackgroundTransparency = 1, Size = UDim2.new(1,0,0,30), LayoutOrder = (parentSection:FindFirstChild("UIListLayout") and #parentSection:GetChildren() or 1), Parent = parentSection })
    CreateElement("TextLabel", { Text = text, Font = THEME.FontSecondary, TextSize = THEME.FontSize, TextColor3 = THEME.TextSecondary, BackgroundTransparency = 1, Size = UDim2.new(0.8, -5, 1, 0), TextXAlignment = Enum.TextXAlignment.Left, Parent = toggleFrame })
    local switch = CreateElement("TextButton", { Text = "", BackgroundColor3 = initialValue and THEME.Accent or THEME.Button, Size = UDim2.new(0.2, 0, 0.8, 0), Position = UDim2.new(0.8,0,0.1,0), Parent = toggleFrame })
    local knob = CreateElement("Frame", { BackgroundColor3 = THEME.TextPrimary, Size = UDim2.new(0.4,0,0.8,0), Position = UDim2.new(initialValue and 0.55 or 0.05, 0, 0.1,0), Parent = switch })
    CreateElement("UICorner", {CornerRadius = UDim.new(0,6), Parent = switch}); CreateElement("UICorner", {CornerRadius = UDim.new(1,0), Parent = knob})
    local value = initialValue
    switch.MouseButton1Click:Connect(function() value = not value; switch.BackgroundColor3 = value and THEME.Accent or THEME.Button; knob:TweenPosition(UDim2.new(value and 0.55 or 0.05, 0, 0.1,0), Enum.EasingDirection.Out, Enum.EasingStyle.Quad, 0.15, true); if callback then callback(value) end end)
    return toggleFrame, function() return value end, function(newValue) value=newValue; switch.BackgroundColor3 = value and THEME.Accent or THEME.Button; knob.Position = UDim2.new(value and 0.55 or 0.05, 0, 0.1,0) end
end

-- =========================================================================
-- MAIN GUI STRUCTURE (Copied from previous working version)
-- =========================================================================
local function BuildGUI()
    oldPrint("DEBUG: BuildGUI called.")
    if ScreenGui and ScreenGui.Parent then ScreenGui:Destroy() end ScreenGui = nil -- Ensure proper cleanup

    ScreenGui = CreateElement("ScreenGui", {Name = SCRIPT_TITLE .. "Gui", ResetOnSpawn = false, Parent = CoreGui})
    MainWindow = CreateElement("Frame", { Name = "MainWindow", Size = UDim2.new(0, 550, 0, 380), Position = UDim2.new(0.5, -275, 0.5, -190), BackgroundColor3 = THEME.Background, BorderSizePixel = 1, BorderColor3 = THEME.InputBorder, ClipsDescendants = true, Visible = WINDOW_INITIAL_VISIBLE, Parent = ScreenGui, })
    CreateElement("UICorner", {CornerRadius = UDim.new(0,6), Parent = MainWindow})
    TitleBar = CreateElement("Frame", { Name = "TitleBar", Size = UDim2.new(1, 0, 0, 35), BackgroundColor3 = THEME.TitleBar, Parent = MainWindow, })
    TitleLabel = CreateElement("TextLabel", { Name = "TitleLabel", Text = SCRIPT_TITLE, Font = THEME.Font, TextSize = THEME.FontSizeTitle, TextColor3 = THEME.TextPrimary, BackgroundTransparency = 1, Size = UDim2.new(1, -40, 1, 0), Position = UDim2.new(0, 10, 0, 0), TextXAlignment = Enum.TextXAlignment.Left, Parent = TitleBar, })
    local closeButton = CreateElement("TextButton", { Name = "CloseButton", Text = "X", Font = THEME.Font, TextSize = 18, TextColor3 = THEME.TextSecondary, BackgroundTransparency = 1, Size = UDim2.new(0,30,0,30), Position = UDim2.new(1,-35,0,2.5), Parent = TitleBar })
    closeButton.MouseEnter:Connect(function() closeButton.TextColor3 = THEME.Accent end); closeButton.MouseLeave:Connect(function() closeButton.TextColor3 = THEME.TextSecondary end); closeButton.MouseButton1Click:Connect(function() MainWindow.Visible = false end)
    SidebarFrame = CreateElement("Frame", { Name = "SidebarFrame", Size = UDim2.new(0, 150, 1, -TitleBar.Size.Y.Offset), Position = UDim2.new(0, 0, 0, TitleBar.Size.Y.Offset), BackgroundColor3 = THEME.Sidebar, Parent = MainWindow, })
    CreateElement("UIListLayout", { Parent = SidebarFrame, SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 5), FillDirection = Enum.FillDirection.Vertical, HorizontalAlignment = Enum.HorizontalAlignment.Center, VerticalAlignment = Enum.VerticalAlignment.Top, })
    ContentFrame = CreateElement("Frame", { Name = "ContentFrame", Size = UDim2.new(1, -SidebarFrame.Size.X.Offset, 1, -TitleBar.Size.Y.Offset), Position = UDim2.new(0, SidebarFrame.Size.X.Offset, 0, TitleBar.Size.Y.Offset), BackgroundColor3 = THEME.Content, BackgroundTransparency = 1, ClipsDescendants = true, Parent = MainWindow, })
    Tabs = {} -- Reset Tabs table
    local tabOrder = 1
    local function AddTab(name) local page = CreateContentPage(name, ContentFrame); local button = CreateSidebarButton(name, tabOrder, SidebarFrame); local tabData = {name = name, button = button, content = page, order = tabOrder}; Tabs[tabOrder] = tabData; button.MouseButton1Click:Connect(function() SelectTab(tabData) end); tabOrder = tabOrder + 1; return page end
    local collectorPage = AddTab("Collector"); local collectorSection = CreateSection("Auto Actions", collectorPage)
    CreateButton("Start Robot Claw", collectorSection, function() AddToConsole("ACTION", "Start Robot Claw button clicked."); task.spawn(Main) end)
    local consolePage = AddTab("Console"); local consoleButtonsSection = CreateSection("", consolePage); consoleButtonsSection.Size = UDim2.new(1, -20, 0, 35); consoleButtonsSection.Position = UDim2.new(0,10,1,-45); consoleButtonsSection.LayoutOrder = 2
    if consoleButtonsSection:FindFirstChildOfClass("UIListLayout") then consoleButtonsSection:FindFirstChildOfClass("UIListLayout"):Destroy() end; CreateElement("UIListLayout", { Parent = consoleButtonsSection, FillDirection = Enum.FillDirection.Horizontal, HorizontalAlignment = Enum.HorizontalAlignment.Center, VerticalAlignment = Enum.VerticalAlignment.Center, Padding = UDim.new(0,10) })
    CreateButton("Clear", consoleButtonsSection, function() for _,lineLabel in ipairs(ConsoleScrollingFrame:GetChildren()) do if lineLabel:IsA("TextLabel") then lineLabel:Destroy() end end; consoleLogLines = {}; AddToConsole("INFO", "Console cleared.") end).Size = UDim2.new(0.45,0,1,0)
    CreateButton("Copy Log", consoleButtonsSection, function() local fullLog = ""; for _, line in ipairs(consoleLogLines) do fullLog = fullLog .. line.raw .. "\n" end; local cf = _G.setclipboard or (_G.game and _G.game.SetClipboard); if cf then pcall(cf,fullLog); AddToConsole("INFO", "Log copied.") else AddToConsole("WARN","Clipboard unavailable.") end end).Size = UDim2.new(0.45,0,1,0)
    ConsoleScrollingFrame = CreateElement("ScrollingFrame", { Name = "ConsoleScrollingFrame", Size = UDim2.new(1, -20, 1, -65), Position = UDim2.new(0, 10, 0, 10), BackgroundTransparency = 1, CanvasSize = UDim2.new(0,0,0,0), ScrollBarThickness = 7, ScrollBarImageColor3 = THEME.TextSecondary, LayoutOrder = 1, Parent = consolePage, })
    ConsoleUIListLayout = CreateElement("UIListLayout", { Parent = ConsoleScrollingFrame, SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 2), })
    local settingsPage = AddTab("Settings"); local settingsSection = CreateSection("General", settingsPage); local _, _, setGuiVisible = CreateToggle("Show GUI", settingsSection, MainWindow.Visible, function(v) MainWindow.Visible = v end)
    MainWindow:GetPropertyChangedSignal("Visible"):Connect(function() if MainWindow then setGuiVisible(MainWindow.Visible) end end)
    if #Tabs > 0 then SelectTab(Tabs[1]) end
    CreateDraggable(MainWindow, TitleBar)
    oldPrint("DEBUG: BuildGUI finished successfully.")
end

-- =========================================================================
-- GUI HELPER FUNCTIONS (DRAGGING, LOGGING) (Copied from previous working version)
-- =========================================================================
function CreateDraggable(frame, triggerFrame) triggerFrame = triggerFrame or frame; local d,di,ds,op; triggerFrame.InputBegan:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then d=true;di=i.Position;op=frame.Position;i.Changed:Connect(function()if i.UserInputState==Enum.UserInputState.End then d=false end end)end end); triggerFrame.InputEnded:Connect(function(i)if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then d=false end end); UserInputService.InputChanged:Connect(function(i)if d and(i.UserInputType==Enum.UserInputType.MouseMovement or i.UserInputType==Enum.UserInputType.Touch)then local delta=i.Position-di;frame.Position=UDim2.new(op.X.Scale,op.X.Offset+delta.X,op.Y.Scale,op.Y.Offset+delta.Y)end end) end

AddToConsole = function(type, ...)
    if not ConsoleScrollingFrame or not ConsoleScrollingFrame.Parent or not ConsoleUIListLayout or not ConsoleUIListLayout.Parent then oldPrint("CONSOLE_ERROR: Console GUI not fully ready. Message:", type, ...); return end
    local args = {...}; local message = table.concat(args, " "); local prefix = "["..string.upper(type or "MSG").."] "; local fullMessage = prefix..message; local rawMessage = fullMessage
    local color = THEME.TextSecondary; if type=="INFO"then color=THEME.TextSecondary elseif type=="ACTION"then color=THEME.Accent elseif type=="WARN"then color=Color3.fromRGB(255,180,0)elseif type=="ERROR"then color=Color3.fromRGB(255,80,80)end
    table.insert(consoleLogLines, {text=fullMessage, color=color, raw=rawMessage})
    if #consoleLogLines > MAX_CONSOLE_LINES then table.remove(consoleLogLines, 1); local firstChild = ConsoleScrollingFrame:FindFirstChildOfClass("TextLabel"); if firstChild then firstChild:Destroy() end end
    local lineLabel = CreateElement("TextLabel", {Text=fullMessage,Font=THEME.FontSecondary,TextSize=THEME.FontSizeSmall,TextColor3=color,TextXAlignment=Enum.TextXAlignment.Left,TextWrapped=true,BackgroundTransparency=1,Size=UDim2.new(1,-ConsoleScrollingFrame.ScrollBarThickness-4,0,0),AutomaticSize=Enum.AutomaticSize.Y,Parent=ConsoleScrollingFrame})
    if CONSOLE_AUTO_SCROLL and ConsoleScrollingFrame.Parent then task.wait(); ConsoleScrollingFrame.CanvasPosition = Vector2.new(0, ConsoleUIListLayout.AbsoluteContentSize.Y) end
    oldPrint(fullMessage)
end

_G.print = function(...) AddToConsole("PRINT", ...) end
_G.warn = function(...) AddToConsole("WARN", ...) end

-- =========================================================================
-- CORE SCRIPT LOGIC (Robot Claw Collector) - Refined
-- =========================================================================
local remoteEventCache = nil
local isMinigameLogicRunning = false 

local function GetRemoteEvent()
    if remoteEventCache and remoteEventCache.Parent then return remoteEventCache end
    print("INFO", "Locating RemoteEvent...")
    local remotePathString = "ReplicatedStorage.Shared.Framework.Network.Remote.Event"
    local success, remote = pcall(function()
        return ReplicatedStorage:WaitForChild("Shared", 25):WaitForChild("Framework", 12):WaitForChild("Network", 12):WaitForChild("Remote", 12):WaitForChild("Event", 12)
    end)
    if not success or not remote or not remote:IsA("RemoteEvent") then
        warn("ERROR", "Failed to find RemoteEvent at", remotePathString, success and ("- Value: " .. tostring(remote)) or ("- Pcall Error: " .. tostring(remote)))
        remoteEventCache = nil
        return nil
    end
    print("INFO", "RemoteEvent found:", remote:GetFullName())
    remoteEventCache = remote
    return remote
end

function StartRobotClawInsane()
    local remote = GetRemoteEvent()
    if not remote then return end
    local args = { "StartMinigame", "Robot Claw", "Insane" }
    print("ACTION", "Attempting to fire StartMinigame event: Robot Claw (Insane)")
    local success, err = pcall(function() remote:FireServer(unpack(args)) end)
    if not success then warn("ERROR", "Failed to fire StartMinigame event:", err) else print("INFO", "StartMinigame event fired successfully.") end
end

function GrabItem(itemId)
    local remote = GetRemoteEvent()
    if not remote then return end
    local args = { "GrabMinigameItem", itemId }
    pcall(function() remote:FireServer(unpack(args)) end)
end

function FindAllItemIDs()
    local itemIDs = {}
    print("INFO", "FindAllItemIDs: Searching for item IDs...")
    local renderedFolder = Workspace:FindFirstChild("Rendered")
    if not renderedFolder then print("WARN", "FindAllItemIDs: 'Workspace.Rendered' not found."); return {} end
    local chunkerFolder = renderedFolder:FindFirstChild("Chunker")
    if not chunkerFolder then print("WARN", "FindAllItemIDs: 'Workspace.Rendered.Chunker' not found."); return {} end

    print("INFO", "FindAllItemIDs: Chunker folder found at: " .. chunkerFolder:GetFullName())
    
    -- Strategy: Check direct children first, then descendants if no direct children match.
    local children = chunkerFolder:GetChildren()
    print("INFO", "FindAllItemIDs: Processing", #children, "direct children of Chunker.")
    for _, itemInstance in ipairs(children) do
        if type(itemInstance.Name) == "string" and string.len(itemInstance.Name) == 36 and string.find(itemInstance.Name, "-", 1, true) then
            print("INFO", "FindAllItemIDs: Found direct child ID:", itemInstance.Name)
            table.insert(itemIDs, itemInstance.Name)
        end
    end

    if #itemIDs == 0 and #children > 0 then
        print("WARN", "FindAllItemIDs: No direct children matched ID format. Checking descendants of Chunker (1 level deep for models)...")
        for _, child in ipairs(children) do
            if child:IsA("Model") then -- Only look into models one level deep
                 for _, descendant in ipairs(child:GetChildren()) do -- Check children of this model
                    if type(descendant.Name) == "string" and string.len(descendant.Name) == 36 and string.find(descendant.Name, "-", 1, true) then
                        print("INFO", "FindAllItemIDs: Found descendant ID in model '"..child.Name.."':", descendant.Name)
                        table.insert(itemIDs, descendant.Name)
                    end
                 end
            end
        end
    elseif #itemIDs == 0 and #children == 0 then
        print("INFO", "FindAllItemIDs: Chunker folder is empty, no items to find.")
    end

    print("INFO", "FindAllItemIDs: Total", #itemIDs, "valid item IDs identified.")
    return itemIDs
end


function Main() 
    if isMinigameLogicRunning then print("WARN", "Minigame logic already running."); return end
    isMinigameLogicRunning = true
    print("ACTION", "Robot Claw Collector sequence initiated.")
    
    StartRobotClawInsane()

    print("INFO", "Waiting for items in Chunker (max 40s)...")
    local startTime = tick()
    local itemsDetected = false
    local chunker = nil
    local childrenCount = 0

    repeat
        local rendered = Workspace:FindFirstChild("Rendered")
        if rendered then chunker = rendered:FindFirstChild("Chunker") end
        
        if chunker then
            childrenCount = #chunker:GetChildren()
            if childrenCount > 0 then
                print("INFO", "WAIT_LOOP: Items detected in Chunker! Direct child count:", childrenCount, ". Time:", string.format("%.1fs", tick()-startTime))
                itemsDetected = true; break
            end
        end
        if tick() - startTime > 5 and (tick() - startTime) % 5 < 0.5 then -- Log every 5 seconds
            print("DEBUG", "WAIT_LOOP: Still waiting for items. Chunker found:", chunker ~= nil, "Children:", childrenCount, "Time:", string.format("%.1fs", tick()-startTime))
        end
        wait(0.5) 
    until tick() - startTime > 40

    if not itemsDetected then
        warn("WARN", "Timeout: No items detected in Chunker after 40s. Collection aborted.")
        isMinigameLogicRunning = false; return
    end
    
    print("INFO", "Items present. Pausing (2s) for full spawn...")
    wait(2) 

    local itemIDsToCollect = FindAllItemIDs()
    if #itemIDsToCollect == 0 then
        print("WARN", "No valid item IDs found by FindAllItemIDs, though Chunker had children. Items might not match ID format or are nested differently.")
        isMinigameLogicRunning = false; return
    end

    print("ACTION", "Starting collection of", #itemIDsToCollect, "items...")
    for i, itemID in ipairs(itemIDsToCollect) do
        if not (ScreenGui and ScreenGui.Parent and MainWindow and MainWindow.Visible) then print("INFO","GUI closed/hidden, stopping collection."); break end
        print("INFO", "Collecting item", i, "/", #itemIDsToCollect, "-", itemID)
        GrabItem(itemID)
        wait(0.18) 
    end
    print("INFO", "Collection cycle completed.")
    isMinigameLogicRunning = false
end

-- =========================================================================
-- INITIALIZATION
-- =========================================================================
local guiBuildSuccess = pcall(BuildGUI) 

if guiBuildSuccess and ScreenGui and MainWindow then
    AddToConsole("INFO", SCRIPT_TITLE .. " initialized. GUI ready.")
    AddToConsole("INFO", "Select 'Collector' tab and click 'Start Robot Claw'.")
else
    oldWarn("FATAL_ERROR: GUI could not be built or essential elements are missing. Error (if any from pcall):", guiBuildSuccess == false and tostring(MainWindow) or "Unknown GUI Build Error")
    oldPrint("FATAL_ERROR: GUI could not be built. Script may not be fully functional. Check default console for earlier DEBUG messages.")
end