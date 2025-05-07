--[[
    Robot Claw Collector - Custom UI (Inspired by Moon X)
    Designed for mobile, aiming for Delta compatibility.
]]

-- Store original print/warn functions IMMEDIATELY
local _G = getfenv(0)
local oldPrint = _G.print
local oldWarn = _G.warn

oldPrint("DEBUG: Script initiated. Custom UI will be built.")

-- Services
local CoreGui = game:GetService("CoreGui")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")

-- Script Configuration
local SCRIPT_TITLE = "Claw Collector Pro"
local MAX_CONSOLE_LINES = 100
local CONSOLE_AUTO_SCROLL = true
local WINDOW_INITIAL_VISIBLE = true

-- GUI Instance Storage
local ScreenGui
local MainWindow
local TitleBar, TitleLabel
local SidebarFrame, ContentFrame
local Tabs = {} -- Stores {button=TabButton, content=ContentPageFrame}
local CurrentTabContent = nil

-- Console Specific
local ConsoleScrollingFrame, ConsoleUIListLayout
local consoleLogLines = {}

-- GUI Theme/Style (Approximating Moon X)
local THEME = {
    Background = Color3.fromRGB(35, 38, 46),        -- Main window bg
    Sidebar = Color3.fromRGB(28, 30, 37),           -- Sidebar bg
    Content = Color3.fromRGB(35, 38, 46),           -- Content area bg
    TitleBar = Color3.fromRGB(22, 24, 29),          -- Title bar bg
    TextPrimary = Color3.fromRGB(220, 221, 222),    -- Main text
    TextSecondary = Color3.fromRGB(150, 152, 158),  -- Lighter text
    Accent = Color3.fromRGB(88, 101, 242),          -- Accent color (e.g., for active toggle)
    AccentHover = Color3.fromRGB(71, 82, 196),
    Button = Color3.fromRGB(54, 57, 66),
    ButtonHover = Color3.fromRGB(64, 68, 78),
    InputBorder = Color3.fromRGB(20, 20, 20),
    ActiveTabButton = Color3.fromRGB(45, 48, 56),
    Font = Enum.Font.GothamSemibold, -- Gotham is often used in these UIs
    FontSecondary = Enum.Font.Gotham,
    FontSize = 14,
    FontSizeSmall = 12,
    FontSizeTitle = 16,
}

-- Forward declare functions
local AddToConsole
local CreateDraggable

-- =========================================================================
-- GUI CREATION FUNCTIONS
-- =========================================================================

local function CreateElement(className, properties)
    local element = Instance.new(className)
    for prop, value in pairs(properties or {}) do
        element[prop] = value
    end
    return element
end

local function SelectTab(tabData)
    if CurrentTabContent then
        CurrentTabContent.Visible = false
    end
    for _, t in ipairs(Tabs) do
         t.button.BackgroundColor3 = (t == tabData) and THEME.ActiveTabButton or THEME.Sidebar
         t.button.TextColor3 = (t == tabData) and THEME.Accent or THEME.TextPrimary
    end

    tabData.content.Visible = true
    CurrentTabContent = tabData.content
end

local function CreateSidebarButton(text, order, parent)
    local button = CreateElement("TextButton", {
        Name = text .. "TabButton",
        Text = "  " .. text, -- Padding for icon later if needed
        TextColor3 = THEME.TextPrimary,
        Font = THEME.Font,
        TextSize = THEME.FontSize,
        TextXAlignment = Enum.TextXAlignment.Left,
        BackgroundColor3 = THEME.Sidebar,
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 0, 40),
        LayoutOrder = order,
        Parent = parent,
    })
    button.MouseEnter:Connect(function()
        if Tabs[order].content ~= CurrentTabContent then
            button.BackgroundColor3 = THEME.ButtonHover
        end
    end)
    button.MouseLeave:Connect(function()
        if Tabs[order].content ~= CurrentTabContent then
             button.BackgroundColor3 = THEME.Sidebar
        end
    end)
    return button
end

local function CreateContentPage(name, parent)
    return CreateElement("Frame", {
        Name = name .. "Page",
        BackgroundTransparency = 1, -- Or THEME.Content if no transparency desired
        Size = UDim2.new(1, 0, 1, 0),
        Visible = false,
        Parent = parent,
    })
end

local function CreateSection(title, parentPage)
    local sectionFrame = CreateElement("Frame", {
        Name = title .. "Section",
        BackgroundTransparency = 1,
        Size = UDim2.new(1, -20, 0, 0), -- Auto height, padding
        AutomaticSize = Enum.AutomaticSize.Y,
        Position = UDim2.new(0, 10, 0, 10),
        Parent = parentPage,
    })
    CreateElement("UIListLayout", {
        Parent = sectionFrame,
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = UDim.new(0, 8),
    })
    if title and title ~= "" then
        CreateElement("TextLabel", {
            Name = "SectionTitle",
            Text = title,
            Font = THEME.Font,
            TextSize = THEME.FontSizeTitle,
            TextColor3 = THEME.TextPrimary,
            TextXAlignment = Enum.TextXAlignment.Left,
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 0, 25),
            LayoutOrder = 0,
            Parent = sectionFrame,
        })
    end
    return sectionFrame
end

local function CreateButton(text, parentSection, callback)
    local button = CreateElement("TextButton", {
        Name = text .. "Button",
        Text = text,
        Font = THEME.FontSecondary,
        TextSize = THEME.FontSize,
        TextColor3 = THEME.TextPrimary,
        BackgroundColor3 = THEME.Button,
        BorderSizePixel = 1,
        BorderColor3 = THEME.InputBorder,
        Size = UDim2.new(1, 0, 0, 35),
        LayoutOrder = (parentSection:FindFirstChild("UIListLayout") and #parentSection:GetChildren() or 1),
        Parent = parentSection,
    })
    CreateElement("UICorner", {CornerRadius = UDim.new(0,4), Parent = button})

    button.MouseEnter:Connect(function() button.BackgroundColor3 = THEME.ButtonHover end)
    button.MouseLeave:Connect(function() button.BackgroundColor3 = THEME.Button end)
    if callback then
        button.MouseButton1Click:Connect(callback)
    end
    return button
end

local function CreateToggle(text, parentSection, initialValue, callback)
    local toggleFrame = CreateElement("Frame", {
        Name = text .. "Toggle",
        BackgroundTransparency = 1,
        Size = UDim2.new(1,0,0,30),
        LayoutOrder = (parentSection:FindFirstChild("UIListLayout") and #parentSection:GetChildren() or 1),
        Parent = parentSection
    })
    local label = CreateElement("TextLabel", {
        Text = text, Font = THEME.FontSecondary, TextSize = THEME.FontSize, TextColor3 = THEME.TextSecondary,
        BackgroundTransparency = 1, Size = UDim2.new(0.8, -5, 1, 0), TextXAlignment = Enum.TextXAlignment.Left,
        Parent = toggleFrame
    })
    local switch = CreateElement("TextButton", {
        Text = "", BackgroundColor3 = initialValue and THEME.Accent or THEME.Button,
        Size = UDim2.new(0.2, 0, 0.8, 0), Position = UDim2.new(0.8,0,0.1,0), AnchorPoint = Vector2.new(0,0),
        Parent = toggleFrame
    })
    local knob = CreateElement("Frame", {
        BackgroundColor3 = THEME.TextPrimary, Size = UDim2.new(0.4,0,0.8,0), Position = UDim2.new(initialValue and 0.55 or 0.05, 0, 0.1,0),
        Parent = switch
    })
    CreateElement("UICorner", {CornerRadius = UDim.new(0,6), Parent = switch})
    CreateElement("UICorner", {CornerRadius = UDim.new(1,0), Parent = knob})

    local value = initialValue
    switch.MouseButton1Click:Connect(function()
        value = not value
        switch.BackgroundColor3 = value and THEME.Accent or THEME.Button
        knob:TweenPosition(UDim2.new(value and 0.55 or 0.05, 0, 0.1,0), Enum.EasingDirection.Out, Enum.EasingStyle.Quad, 0.15, true)
        if callback then callback(value) end
    end)
    return toggleFrame, function() return value end, function(newValue) value=newValue; switch.BackgroundColor3 = value and THEME.Accent or THEME.Button; knob.Position = UDim2.new(value and 0.55 or 0.05, 0, 0.1,0) end
end

-- =========================================================================
-- MAIN GUI STRUCTURE
-- =========================================================================
local function BuildGUI()
    oldPrint("DEBUG: BuildGUI called.")
    if ScreenGui then ScreenGui:Destroy() end

    ScreenGui = CreateElement("ScreenGui", {Name = SCRIPT_TITLE .. "Gui", ResetOnSpawn = false, Parent = CoreGui})
    oldPrint("DEBUG: ScreenGui created.")

    MainWindow = CreateElement("Frame", {
        Name = "MainWindow",
        Size = UDim2.new(0, 550, 0, 380), -- Typical desktop script UI size, might need adjustment for mobile
        Position = UDim2.new(0.5, -275, 0.5, -190),
        BackgroundColor3 = THEME.Background,
        BorderSizePixel = 1,
        BorderColor3 = THEME.InputBorder,
        ClipsDescendants = true,
        Visible = WINDOW_INITIAL_VISIBLE,
        Parent = ScreenGui,
    })
    CreateElement("UICorner", {CornerRadius = UDim.new(0,6), Parent = MainWindow})
    oldPrint("DEBUG: MainWindow created.")

    TitleBar = CreateElement("Frame", {
        Name = "TitleBar",
        Size = UDim2.new(1, 0, 0, 35),
        BackgroundColor3 = THEME.TitleBar,
        BorderSizePixel = 0,
        Parent = MainWindow,
    })
    TitleLabel = CreateElement("TextLabel", {
        Name = "TitleLabel",
        Text = SCRIPT_TITLE,
        Font = THEME.Font,
        TextSize = THEME.FontSizeTitle,
        TextColor3 = THEME.TextPrimary,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, -10, 1, 0),
        Position = UDim2.new(0, 10, 0, 0),
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = TitleBar,
    })
    -- Placeholder for close button if needed, Venyx/Rayfield handle this. We might need one for custom.
    local closeButton = CreateElement("TextButton", {
        Name = "CloseButton", Text = "X", Font = THEME.Font, TextSize = 18, TextColor3 = THEME.TextSecondary,
        BackgroundTransparency = 1, Size = UDim2.new(0,30,0,30), Position = UDim2.new(1,-35,0,2.5),
        Parent = TitleBar
    })
    closeButton.MouseEnter:Connect(function() closeButton.TextColor3 = THEME.Accent end)
    closeButton.MouseLeave:Connect(function() closeButton.TextColor3 = THEME.TextSecondary end)
    closeButton.MouseButton1Click:Connect(function() MainWindow.Visible = false end)


    SidebarFrame = CreateElement("Frame", {
        Name = "SidebarFrame",
        Size = UDim2.new(0, 150, 1, -TitleBar.Size.Y.Offset),
        Position = UDim2.new(0, 0, 0, TitleBar.Size.Y.Offset),
        BackgroundColor3 = THEME.Sidebar,
        BorderSizePixel = 0,
        Parent = MainWindow,
    })
    CreateElement("UIListLayout", {
        Parent = SidebarFrame,
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = UDim.new(0, 5),
        FillDirection = Enum.FillDirection.Vertical,
        HorizontalAlignment = Enum.HorizontalAlignment.Center,
        VerticalAlignment = Enum.VerticalAlignment.Top,
    })
    oldPrint("DEBUG: SidebarFrame created.")

    ContentFrame = CreateElement("Frame", {
        Name = "ContentFrame",
        Size = UDim2.new(1, -SidebarFrame.Size.X.Offset, 1, -TitleBar.Size.Y.Offset),
        Position = UDim2.new(0, SidebarFrame.Size.X.Offset, 0, TitleBar.Size.Y.Offset),
        BackgroundColor3 = THEME.Content,
        BackgroundTransparency = 1, -- Main content area transparent, pages will have color if needed
        BorderSizePixel = 0,
        ClipsDescendants = true,
        Parent = MainWindow,
    })
    oldPrint("DEBUG: ContentFrame created.")

    -- Create Tabs
    local tabOrder = 1
    local function AddTab(name)
        local page = CreateContentPage(name, ContentFrame)
        local button = CreateSidebarButton(name, tabOrder, SidebarFrame)
        local tabData = {name = name, button = button, content = page, order = tabOrder}
        Tabs[tabOrder] = tabData
        button.MouseButton1Click:Connect(function() SelectTab(tabData) end)
        tabOrder = tabOrder + 1
        return page
    end

    -- Collector Tab
    local collectorPage = AddTab("Collector")
    local collectorSection = CreateSection("Auto Actions", collectorPage)
    local startMinigameButton = CreateButton("Start Robot Claw", collectorSection, function()
        AddToConsole("INFO", "Attempting to start Robot Claw minigame...")
        task.spawn(Main) -- Run the core logic
    end)

    -- Console Tab
    local consolePage = AddTab("Console")
    local consoleButtonsSection = CreateSection("", consolePage) -- No title for this button section
    consoleButtonsSection.Size = UDim2.new(1, -20, 0, 35) -- Fixed height for buttons
    consoleButtonsSection.Position = UDim2.new(0,10,1,-45) -- Position at bottom
    consoleButtonsSection.LayoutOrder = 2 -- Make it appear after scrolling frame

    local consoleButtonLayout = consoleButtonsSection:FindFirstChildOfClass("UIListLayout")
    if consoleButtonLayout then consoleButtonLayout:Destroy() end -- Remove vertical list
    CreateElement("UIListLayout", { -- Add horizontal list for buttons
        Parent = consoleButtonsSection, FillDirection = Enum.FillDirection.Horizontal,
        HorizontalAlignment = Enum.HorizontalAlignment.Center, VerticalAlignment = Enum.VerticalAlignment.Center,
        Padding = UDim.new(0,10)
    })

    CreateButton("Clear", consoleButtonsSection, function()
        for _,lineLabel in ipairs(ConsoleScrollingFrame:GetChildren()) do
            if lineLabel:IsA("TextLabel") then lineLabel:Destroy() end
        end
        consoleLogLines = {}
        AddToConsole("INFO", "Console cleared.")
    end).Size = UDim2.new(0.45,0,1,0)

    CreateButton("Copy Log", consoleButtonsSection, function()
        local fullLog = ""
        for _, line in ipairs(consoleLogLines) do fullLog = fullLog .. line.raw .. "\n" end
        local clipboardFunc = _G.setclipboard or (_G.game and _G.game.SetClipboard)
        if clipboardFunc then
            pcall(clipboardFunc, fullLog)
            AddToConsole("INFO", "Log copied to clipboard.")
        else
            AddToConsole("WARN", "Clipboard function not available.")
        end
    end).Size = UDim2.new(0.45,0,1,0)
    
    ConsoleScrollingFrame = CreateElement("ScrollingFrame", {
        Name = "ConsoleScrollingFrame",
        Size = UDim2.new(1, -20, 1, -65), -- Adjust for padding and button section
        Position = UDim2.new(0, 10, 0, 10),
        BackgroundTransparency = 1,
        CanvasSize = UDim2.new(0,0,0,0),
        ScrollBarThickness = 6,
        ScrollBarImageColor3 = THEME.TextSecondary,
        LayoutOrder = 1,
        Parent = consolePage,
    })
    ConsoleUIListLayout = CreateElement("UIListLayout", {
        Parent = ConsoleScrollingFrame,
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = UDim.new(0, 2),
    })

    -- Settings Tab
    local settingsPage = AddTab("Settings")
    local settingsSection = CreateSection("General", settingsPage)
    local guiVisibleToggle, getGuiVisible, setGuiVisible = CreateToggle("Show GUI", settingsSection, MainWindow.Visible, function(value)
        MainWindow.Visible = value
    end)
    -- Add listener for when MainWindow visibility changes externally (e.g. close button)
    MainWindow:GetPropertyChangedSignal("Visible"):Connect(function()
        setGuiVisible(MainWindow.Visible)
    end)


    -- Select first tab by default
    if #Tabs > 0 then SelectTab(Tabs[1]) end

    -- Make window draggable
    CreateDraggable(MainWindow, TitleBar)
    oldPrint("DEBUG: BuildGUI finished.")
end

-- =========================================================================
-- GUI HELPER FUNCTIONS (DRAGGING, LOGGING)
-- =========================================================================
function CreateDraggable(frame, triggerFrame)
    triggerFrame = triggerFrame or frame
    local dragging = false
    local dragInput, dragStart, originalPosition

    triggerFrame.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            originalPosition = frame.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then dragging = false end
            end)
        end
    end)
    triggerFrame.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - dragStart
            frame.Position = UDim2.new(originalPosition.X.Scale, originalPosition.X.Offset + delta.X,
                                       originalPosition.Y.Scale, originalPosition.Y.Offset + delta.Y)
        end
    end)
end

AddToConsole = function(type, ...)
    if not ConsoleScrollingFrame or not ConsoleUIListLayout then
        oldPrint("CONSOLE_ERROR: Console GUI not ready for logging.", type, ...)
        return
    end

    local args = {...}
    local message = table.concat(args, " ")
    local prefix = "[" .. string.upper(type or "MSG") .. "] "
    local fullMessage = prefix .. message
    local rawMessage = fullMessage -- For copy log

    local color = THEME.TextSecondary
    if type == "INFO" then color = THEME.Accent
    elseif type == "WARN" then color = Color3.fromRGB(255, 180, 0)
    elseif type == "ERROR" then color = Color3.fromRGB(255, 80, 80)
    end

    table.insert(consoleLogLines, {text=fullMessage, color=color, raw=rawMessage})
    if #consoleLogLines > MAX_CONSOLE_LINES then
        table.remove(consoleLogLines, 1)
        if ConsoleScrollingFrame:GetChildren()[1] and ConsoleScrollingFrame:GetChildren()[1]:IsA("TextLabel") then
            ConsoleScrollingFrame:GetChildren()[1]:Destroy()
        end
    end
    
    local lineLabel = CreateElement("TextLabel", {
        Text = fullMessage,
        Font = THEME.FontSecondary,
        TextSize = THEME.FontSizeSmall,
        TextColor3 = color,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextWrapped = true,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, -ConsoleScrollingFrame.ScrollBarThickness - 4, 0, 0), -- Auto height
        AutomaticSize = Enum.AutomaticSize.Y,
        Parent = ConsoleScrollingFrame,
    })

    if CONSOLE_AUTO_SCROLL and ConsoleScrollingFrame then
        task.wait() -- Allow UI to update
        ConsoleScrollingFrame.CanvasPosition = Vector2.new(0, ConsoleUIListLayout.AbsoluteContentSize.Y)
    end
    oldPrint(fullMessage) -- Also print to default console
end

-- Hook global print and warn
_G.print = function(...) AddToConsole("PRINT", ...) end
_G.warn = function(...) AddToConsole("WARN", ...) end


-- =========================================================================
-- CORE SCRIPT LOGIC (Robot Claw Collector)
-- =========================================================================
local remoteEventCache = nil

local function GetRemoteEvent()
    if remoteEventCache and remoteEventCache.Parent then return remoteEventCache end
    print("INFO", "Locating RemoteEvent...")
    local remotePathString = "ReplicatedStorage.Shared.Framework.Network.Remote.Event"
    local success, remote = pcall(function()
        return ReplicatedStorage:WaitForChild("Shared", 20):WaitForChild("Framework", 10):WaitForChild("Network", 10):WaitForChild("Remote", 10):WaitForChild("Event", 10)
    end)
    if not success or not remote or not remote:IsA("RemoteEvent") then
        warn("ERROR", "Failed to find RemoteEvent at", remotePathString, success and "- Not a RemoteEvent or nil." or "- Error: " .. tostring(remote))
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
    print("INFO", "Starting minigame: Robot Claw (Insane)")
    local success, err = pcall(function() remote:FireServer(unpack(args)) end)
    if not success then warn("ERROR", "Failed to fire StartMinigame event:", err) end
end

function GrabItem(itemId)
    local remote = GetRemoteEvent()
    if not remote then return end
    
    local args = { "GrabMinigameItem", itemId }
    -- print("DEBUG", "Attempting to grab item:", itemId) -- Can be spammy
    pcall(function() remote:FireServer(unpack(args)) end)
end

function FindAllItemIDs()
    local itemIDs = {}
    print("INFO", "Searching for item IDs in Chunker...")
    local renderedFolder = Workspace:FindFirstChild("Rendered")
    if not renderedFolder then print("WARN", "'Workspace.Rendered' not found."); return {} end
    local chunkerFolder = renderedFolder:FindFirstChild("Chunker")
    if not chunkerFolder then print("WARN", "'Workspace.Rendered.Chunker' not found."); return {} end

    local children = chunkerFolder:GetChildren()
    print("INFO", #children, "items found in Chunker folder.")
    if #children == 0 then return {} end

    for _, itemInstance in ipairs(children) do
        if string.len(itemInstance.Name) == 36 and string.find(itemInstance.Name, "-", 1, true) then
            -- print("DEBUG", "Potential item ID found:", itemInstance.Name)
            table.insert(itemIDs, itemInstance.Name)
        end
    end
    print("INFO", #itemIDs, "valid item IDs identified for collection.")
    return itemIDs
end

function Main() -- This is the main operational function
    print("INFO", "Robot Claw Collector sequence initiated by user.")
    
    StartRobotClawInsane()

    print("INFO", "Waiting for minigame items to load (up to 30s)...")
    local startTime = tick()
    local itemsDetected = false
    repeat
        local chunker = Workspace:FindFirstChild("Rendered") and Workspace.Rendered:FindFirstChild("Chunker")
        if chunker and #chunker:GetChildren() > 0 then
            itemsDetected = true
            break
        end
        wait(0.5)
    until tick() - startTime > 30

    if not itemsDetected then
        warn("WARN", "No items detected in Chunker after 30s. Aborting collection.")
        return
    end
    print("INFO", "Items detected. Proceeding with collection.")
    wait(1) -- Brief pause for all items to spawn

    local itemIDsToCollect = FindAllItemIDs()
    if #itemIDsToCollect == 0 then
        print("INFO", "No items to collect after final check.")
        return
    end

    print("INFO", "Starting collection of", #itemIDsToCollect, "items...")
    for i, itemID in ipairs(itemIDsToCollect) do
        if not MainWindow.Visible then print("INFO","GUI Hidden, stopping collection."); break end -- Stop if GUI is closed
        print("INFO", "Collecting item", i, "/", #itemIDsToCollect, "-", itemID)
        GrabItem(itemID)
        wait(0.12) -- Slightly increased delay from 0.1 for stability potentially
    end
    print("INFO", "Collection cycle completed.")
end

-- =========================================================================
-- INITIALIZATION
-- =========================================================================
pcall(BuildGUI) -- Build the GUI, wrapped in pcall for safety

if ScreenGui and MainWindow then
    AddToConsole("INFO", SCRIPT_TITLE .. " initialized. GUI ready.")
    AddToConsole("INFO", "Select 'Collector' tab and click 'Start Robot Claw'.")
else
    oldWarn("FATAL_ERROR: GUI could not be built. Check for errors above.")
    oldPrint("FATAL_ERROR: GUI could not be built. Script may not be fully functional.")
end

-- Example of how script might be re-run or if Main needs to be callable globally for some executors
-- _G.RunCollector = Main 