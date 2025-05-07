--[[
    Robot Claw Collector - vCorrected - Custom UI & CORRECT Logic
    Uses CollectionService:GetTagged("ClawToyModel") and GetAttribute("ItemGUID")
    based on provided game script analysis.
]]

-- Store original print/warn functions IMMEDIATELY
local _G = getfenv(0)
local oldPrint = _G.print
local oldWarn = _G.warn

oldPrint("DEBUG: Script initiated. Corrected Logic (Tags/Attributes). Version: Corrected_1")

-- Services
local CoreGui = game:GetService("CoreGui")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")
local CollectionService = game:GetService("CollectionService") -- Crucial service

-- Script Configuration
local SCRIPT_TITLE = "Claw Collector Pro (Corrected)" 
local MAX_CONSOLE_LINES = 120 
local CONSOLE_AUTO_SCROLL = true
local WINDOW_INITIAL_VISIBLE = true
local ITEM_TAG = "ClawToyModel"       -- The correct tag from the game script
local ITEM_ID_ATTRIBUTE = "ItemGUID" -- The correct attribute from the game script


-- GUI Instance Storage / Theme / GUI Creation Functions (Identical to last working GUI version)
local ScreenGui, MainWindow, TitleBar, TitleLabel, SidebarFrame, ContentFrame
local Tabs = {} 
local CurrentTabContent = nil
local ConsoleScrollingFrame, ConsoleUIListLayout
local consoleLogLines = {}
local THEME = { Background = Color3.fromRGB(35, 38, 46), Sidebar = Color3.fromRGB(28, 30, 37), Content = Color3.fromRGB(35, 38, 46), TitleBar = Color3.fromRGB(22, 24, 29), TextPrimary = Color3.fromRGB(220, 221, 222), TextSecondary = Color3.fromRGB(150, 152, 158), Accent = Color3.fromRGB(88, 101, 242), AccentHover = Color3.fromRGB(71, 82, 196), Button = Color3.fromRGB(54, 57, 66), ButtonHover = Color3.fromRGB(64, 68, 78), InputBorder = Color3.fromRGB(20, 20, 20), ActiveTabButton = Color3.fromRGB(45, 48, 56), Font = Enum.Font.GothamSemibold, FontSecondary = Enum.Font.Gotham, FontSize = 14, FontSizeSmall = 12, FontSizeTitle = 16, }
local AddToConsole -- Forward declare
local function CreateElement(className, properties) local element = Instance.new(className); for prop, value in pairs(properties or {}) do element[prop] = value end; return element end
local function SelectTab(tabData) if CurrentTabContent then CurrentTabContent.Visible = false end; for _, t in ipairs(Tabs) do t.button.BackgroundColor3 = (t == tabData) and THEME.ActiveTabButton or THEME.Sidebar; t.button.TextColor3 = (t == tabData) and THEME.Accent or THEME.TextPrimary end; tabData.content.Visible = true; CurrentTabContent = tabData.content end
local function CreateSidebarButton(text, order, parent) local b = CreateElement("TextButton", {Name=text.."TabButton",Text="  "..text,TextColor3=THEME.TextPrimary,Font=THEME.Font,TextSize=THEME.FontSize,TextXAlignment=Enum.TextXAlignment.Left,BackgroundColor3=THEME.Sidebar,BorderSizePixel=0,Size=UDim2.new(1,0,0,40),LayoutOrder=order,Parent=parent}); b.MouseEnter:Connect(function()if Tabs[order].content~=CurrentTabContent then b.BackgroundColor3=THEME.ButtonHover end end);b.MouseLeave:Connect(function()if Tabs[order].content~=CurrentTabContent then b.BackgroundColor3=THEME.Sidebar end end);return b end
local function CreateContentPage(name,parent) return CreateElement("Frame",{Name=name.."Page",BackgroundTransparency=1,Size=UDim2.new(1,0,1,0),Visible=false,Parent=parent})end
local function CreateSection(title,parentPage) local sF=CreateElement("Frame",{Name=title.."Section",BackgroundTransparency=1,Size=UDim2.new(1,-20,0,0),AutomaticSize=Enum.AutomaticSize.Y,Position=UDim2.new(0,10,0,10),Parent=parentPage});CreateElement("UIListLayout",{Parent=sF,SortOrder=Enum.SortOrder.LayoutOrder,Padding=UDim.new(0,8)});if title and title~=""then CreateElement("TextLabel",{Name="SectionTitle",Text=title,Font=THEME.Font,TextSize=THEME.FontSizeTitle,TextColor3=THEME.TextPrimary,TextXAlignment=Enum.TextXAlignment.Left,BackgroundTransparency=1,Size=UDim2.new(1,0,0,25),LayoutOrder=0,Parent=sF})end;return sF end
local function CreateButton(text,parentSection,callback) local b=CreateElement("TextButton",{Name=text.."Button",Text=text,Font=THEME.FontSecondary,TextSize=THEME.FontSize,TextColor3=THEME.TextPrimary,BackgroundColor3=THEME.Button,BorderSizePixel=1,BorderColor3=THEME.InputBorder,Size=UDim2.new(1,0,0,35),LayoutOrder=(parentSection:FindFirstChild("UIListLayout")and #parentSection:GetChildren()or 1),Parent=parentSection});CreateElement("UICorner",{CornerRadius=UDim.new(0,4),Parent=b});b.MouseEnter:Connect(function()b.BackgroundColor3=THEME.ButtonHover end);b.MouseLeave:Connect(function()b.BackgroundColor3=THEME.Button end);if callback then b.MouseButton1Click:Connect(callback)end;return b end
local function CreateToggle(text,parentSection,initialValue,callback) local tF=CreateElement("Frame",{Name=text.."Toggle",BackgroundTransparency=1,Size=UDim2.new(1,0,0,30),LayoutOrder=(parentSection:FindFirstChild("UIListLayout")and #parentSection:GetChildren()or 1),Parent=parentSection});CreateElement("TextLabel",{Text=text,Font=THEME.FontSecondary,TextSize=THEME.FontSize,TextColor3=THEME.TextSecondary,BackgroundTransparency=1,Size=UDim2.new(0.8,-5,1,0),TextXAlignment=Enum.TextXAlignment.Left,Parent=tF});local s=CreateElement("TextButton",{Text="",BackgroundColor3=initialValue and THEME.Accent or THEME.Button,Size=UDim2.new(0.2,0,0.8,0),Position=UDim2.new(0.8,0,0.1,0),Parent=tF});local k=CreateElement("Frame",{BackgroundColor3=THEME.TextPrimary,Size=UDim2.new(0.4,0,0.8,0),Position=UDim2.new(initialValue and 0.55 or 0.05,0,0.1,0),Parent=s});CreateElement("UICorner",{CornerRadius=UDim.new(0,6),Parent=s});CreateElement("UICorner",{CornerRadius=UDim.new(1,0),Parent=k});local v=initialValue;s.MouseButton1Click:Connect(function()v=not v;s.BackgroundColor3=v and THEME.Accent or THEME.Button;k:TweenPosition(UDim2.new(v and 0.55 or 0.05,0,0.1,0),Enum.EasingDirection.Out,Enum.EasingStyle.Quad,0.15,true);if callback then callback(v)end end);return tF,function()return v end,function(nV)v=nV;s.BackgroundColor3=v and THEME.Accent or THEME.Button;k.Position=UDim2.new(v and 0.55 or 0.05,0,0.1,0)end end
local function CreateDraggable(frame, triggerFrame) triggerFrame = triggerFrame or frame; local d,di,ds,op; triggerFrame.InputBegan:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then d=true;di=i.Position;op=frame.Position;i.Changed:Connect(function()if i.UserInputState==Enum.UserInputState.End then d=false end end)end end); triggerFrame.InputEnded:Connect(function(i)if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then d=false end end); UserInputService.InputChanged:Connect(function(i)if d and(i.UserInputType==Enum.UserInputType.MouseMovement or i.UserInputType==Enum.UserInputType.Touch)then local delta=i.Position-di;frame.Position=UDim2.new(op.X.Scale,op.X.Offset+delta.X,op.Y.Scale,op.Y.Offset+delta.Y)end end) end
local function BuildGUI()
    oldPrint("DEBUG: BuildGUI called.")
    if ScreenGui and ScreenGui.Parent then ScreenGui:Destroy() end ScreenGui = nil 
    ScreenGui = CreateElement("ScreenGui", {Name = SCRIPT_TITLE .. "Gui", ResetOnSpawn = false, Parent = CoreGui})
    MainWindow = CreateElement("Frame", { Name = "MainWindow", Size = UDim2.new(0, 550, 0, 380), Position = UDim2.new(0.5, -275, 0.5, -190), BackgroundColor3 = THEME.Background, BorderSizePixel = 1, BorderColor3 = THEME.InputBorder, ClipsDescendants = true, Visible = WINDOW_INITIAL_VISIBLE, Parent = ScreenGui, })
    CreateElement("UICorner", {CornerRadius = UDim.new(0,6), Parent = MainWindow})
    TitleBar = CreateElement("Frame", { Name = "TitleBar", Size = UDim2.new(1, 0, 0, 35), BackgroundColor3 = THEME.TitleBar, Parent = MainWindow, })
    TitleLabel = CreateElement("TextLabel", { Name = "TitleLabel", Text = SCRIPT_TITLE, Font = THEME.Font, TextSize = THEME.FontSizeTitle, TextColor3 = THEME.TextPrimary, BackgroundTransparency = 1, Size = UDim2.new(1, -40, 1, 0), Position = UDim2.new(0, 10, 0, 0), TextXAlignment = Enum.TextXAlignment.Left, Parent = TitleBar, })
    local closeButton = CreateElement("TextButton", { Name = "CloseButton", Text = "X", Font = THEME.Font, TextSize = 18, TextColor3 = THEME.TextSecondary, BackgroundTransparency = 1, Size = UDim2.new(0,30,0,30), Position = UDim2.new(1,-35,0,2.5), Parent = TitleBar })
    closeButton.MouseEnter:Connect(function() closeButton.TextColor3 = THEME.Accent end); closeButton.MouseLeave:Connect(function() closeButton.TextColor3 = THEME.TextSecondary end); closeButton.MouseButton1Click:Connect(function() if MainWindow then MainWindow.Visible = false end end)
    SidebarFrame = CreateElement("Frame", { Name = "SidebarFrame", Size = UDim2.new(0, 150, 1, -TitleBar.Size.Y.Offset), Position = UDim2.new(0, 0, 0, TitleBar.Size.Y.Offset), BackgroundColor3 = THEME.Sidebar, Parent = MainWindow, })
    CreateElement("UIListLayout", { Parent = SidebarFrame, SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 5), FillDirection = Enum.FillDirection.Vertical, HorizontalAlignment = Enum.HorizontalAlignment.Center, VerticalAlignment = Enum.VerticalAlignment.Top, })
    ContentFrame = CreateElement("Frame", { Name = "ContentFrame", Size = UDim2.new(1, -SidebarFrame.Size.X.Offset, 1, -TitleBar.Size.Y.Offset), Position = UDim2.new(0, SidebarFrame.Size.X.Offset, 0, TitleBar.Size.Y.Offset), BackgroundColor3 = THEME.Content, BackgroundTransparency = 1, ClipsDescendants = true, Parent = MainWindow, })
    Tabs = {} 
    local tabOrder = 1
    local function AddTab(name) local p=CreateContentPage(name,ContentFrame);local b=CreateSidebarButton(name,tabOrder,SidebarFrame);local d={name=name,button=b,content=p,order=tabOrder};Tabs[tabOrder]=d;b.MouseButton1Click:Connect(function()SelectTab(d)end);tabOrder=tabOrder+1;return p end
    local collectorPage=AddTab("Collector");local cS=CreateSection("Auto Actions",collectorPage);CreateButton("Start Robot Claw",cS,function()AddToConsole("ACTION","Start Robot Claw button clicked.");task.spawn(Main)end)
    local consolePage=AddTab("Console");local cBS=CreateSection("",consolePage);cBS.Size=UDim2.new(1,-20,0,35);cBS.Position=UDim2.new(0,10,1,-45);cBS.LayoutOrder=2
    if cBS:FindFirstChildOfClass("UIListLayout")then cBS:FindFirstChildOfClass("UIListLayout"):Destroy()end;CreateElement("UIListLayout",{Parent=cBS,FillDirection=Enum.FillDirection.Horizontal,HorizontalAlignment=Enum.HorizontalAlignment.Center,VerticalAlignment=Enum.VerticalAlignment.Center,Padding=UDim.new(0,10)})
    CreateButton("Clear",cBS,function()for _,lL in ipairs(ConsoleScrollingFrame:GetChildren())do if lL:IsA("TextLabel")then lL:Destroy()end end;consoleLogLines={};AddToConsole("INFO","Console cleared.")end).Size=UDim2.new(0.45,0,1,0)
    CreateButton("Copy Log",cBS,function()local fL="";for _,l in ipairs(consoleLogLines)do fL=fL..l.raw.."\n"end;local cF=_G.setclipboard or(_G.game and _G.game.SetClipboard);if cF then pcall(cF,fL);AddToConsole("INFO","Log copied.")else AddToConsole("WARN","Clipboard unavailable.")end end).Size=UDim2.new(0.45,0,1,0)
    ConsoleScrollingFrame=CreateElement("ScrollingFrame",{Name="ConsoleScrollingFrame",Size=UDim2.new(1,-20,1,-65),Position=UDim2.new(0,10,0,10),BackgroundTransparency=1,CanvasSize=UDim2.new(0,0,0,0),ScrollBarThickness=7,ScrollBarImageColor3=THEME.TextSecondary,LayoutOrder=1,Parent=consolePage})
    ConsoleUIListLayout=CreateElement("UIListLayout",{Parent=ConsoleScrollingFrame,SortOrder=Enum.SortOrder.LayoutOrder,Padding=UDim.new(0,2)})
    local settingsPage=AddTab("Settings");local sS=CreateSection("General",settingsPage);local _,_,setGuiVisible=CreateToggle("Show GUI",sS,MainWindow.Visible,function(v)if MainWindow then MainWindow.Visible=v end end)
    if MainWindow then MainWindow:GetPropertyChangedSignal("Visible"):Connect(function()if MainWindow and setGuiVisible then setGuiVisible(MainWindow.Visible)end end)end
    if #Tabs>0 then SelectTab(Tabs[1])end
    CreateDraggable(MainWindow,TitleBar)
    oldPrint("DEBUG: BuildGUI finished successfully.")
end
AddToConsole = function(type, ...) if not ConsoleScrollingFrame or not ConsoleScrollingFrame.Parent or not ConsoleUIListLayout or not ConsoleUIListLayout.Parent then oldPrint("CONSOLE_ERROR: Console GUI not fully ready. Message:", type, ...); return end; local args = {...}; local message = table.concat(args, " "); local prefix = "["..string.upper(type or "MSG").."] "; local fullMessage = prefix..message; local rawMessage = fullMessage; local color = THEME.TextSecondary; if type=="INFO"then color=THEME.TextSecondary elseif type=="ACTION"then color=THEME.Accent elseif type=="WARN"then color=Color3.fromRGB(255,180,0)elseif type=="ERROR"then color=Color3.fromRGB(255,80,80)end; table.insert(consoleLogLines, {text=fullMessage, color=color, raw=rawMessage}); if #consoleLogLines > MAX_CONSOLE_LINES then table.remove(consoleLogLines, 1); local firstChild = ConsoleScrollingFrame:FindFirstChildOfClass("TextLabel"); if firstChild then firstChild:Destroy() end end; local lineLabel = CreateElement("TextLabel", {Text=fullMessage,Font=THEME.FontSecondary,TextSize=THEME.FontSizeSmall,TextColor3=color,TextXAlignment=Enum.TextXAlignment.Left,TextWrapped=true,BackgroundTransparency=1,Size=UDim2.new(1,-ConsoleScrollingFrame.ScrollBarThickness-4,0,0),AutomaticSize=Enum.AutomaticSize.Y,Parent=ConsoleScrollingFrame}); if CONSOLE_AUTO_SCROLL and ConsoleScrollingFrame.Parent then task.wait(); ConsoleScrollingFrame.CanvasPosition = Vector2.new(0, ConsoleUIListLayout.AbsoluteContentSize.Y) end; oldPrint(fullMessage) end
_G.print = function(...) AddToConsole("PRINT", ...) end
_G.warn = function(...) AddToConsole("WARN", ...) end
-- =========================================================================
-- =========================================================================
-- CORE SCRIPT LOGIC (Robot Claw Collector) - CORRECTED TAG/ATTRIBUTE LOGIC
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
        warn("ERROR","Failed to find RemoteEvent at",remotePathString,success and ("- Val: "..tostring(remote))or("- PcallErr: "..tostring(remote)))
        remoteEventCache=nil;return nil 
    end
    print("INFO","RemoteEvent found:",remote:GetFullName());remoteEventCache=remote;return remote
end

function StartRobotClawInsane()
    local remote = GetRemoteEvent()
    if not remote then return end
    local args = { "StartMinigame", "Robot Claw", "Insane" }
    print("ACTION", "Attempting to fire StartMinigame: Robot Claw (Insane)")
    local success, err = pcall(function() remote:FireServer(unpack(args)) end)
    if not success then warn("ERROR","Failed to fire StartMinigame event:",err) else print("INFO","StartMinigame event fired.") end
end

function GrabItem(itemId)
    local remote = GetRemoteEvent()
    if not remote then return end
    local args = { "GrabMinigameItem", itemId }
    pcall(function() remote:FireServer(unpack(args)) end)
end

--=========================================================================
--  MODIFIED FIND FUNCTION - USES TAGS AND ATTRIBUTES
--=========================================================================
function FindAllItemIDs_Corrected()
    local itemIDs = {}
    print("INFO", "FindAllItemIDs_Corrected: Searching for items with tag ["..ITEM_TAG.."]")
   
    local taggedItems = CollectionService:GetTagged(ITEM_TAG)
    print("INFO", "FindAllItemIDs_Corrected: Found", #taggedItems, "instances with tag ["..ITEM_TAG.."]")

    if #taggedItems == 0 then
        return itemIDs -- Return empty table if no tagged items found
    end

    for _, itemInstance in ipairs(taggedItems) do
        local guid = itemInstance:GetAttribute(ITEM_ID_ATTRIBUTE)
        if guid and type(guid) == "string" then
             print("INFO", "FindAllItemIDs_Corrected: Found valid item. Instance:", itemInstance.Name, "| GUID from Attribute:", guid)
             table.insert(itemIDs, guid)
        else
             warn("WARN", "FindAllItemIDs_Corrected: Tagged item ["..itemInstance.Name.."] missing or has invalid attribute ["..ITEM_ID_ATTRIBUTE.."]. Value:", tostring(guid))
        end
    end
    
    print("INFO", "FindAllItemIDs_Corrected: Total", #itemIDs, "valid item IDs identified from tagged items.")
    return itemIDs
end
--=========================================================================

function Main() 
    if isMinigameLogicRunning then print("WARN", "Minigame logic already running."); return end
    isMinigameLogicRunning = true
    print("ACTION", "Robot Claw Collector sequence initiated (Corrected Logic).")
    
    StartRobotClawInsane()

    print("INFO", "Waiting for tagged items ["..ITEM_TAG.."] to appear (max 20s)...")
    local startTime = tick()
    local itemsDetected = false
    local taggedItemsCount = 0

    repeat
        taggedItemsCount = #CollectionService:GetTagged(ITEM_TAG)
        if taggedItemsCount > 0 then
             print("INFO", "WAIT_LOOP: Tagged items detected! Count:", taggedItemsCount, ". Time:", string.format("%.1fs", tick()-startTime))
             itemsDetected = true; break
        end
        wait(0.25) -- Check more frequently now that we use a more efficient method
    until tick() - startTime > 20 -- Reduced timeout, as tag check is fast

    if not itemsDetected then
        warn("WARN", "Timeout: No items with tag ["..ITEM_TAG.."] detected after 20s. Collection aborted.")
        isMinigameLogicRunning = false; return
    end
    
    print("INFO", "Items present. Pausing (1s) for full spawn...")
    wait(1) 

    local itemIDsToCollect = FindAllItemIDs_Corrected() -- Use the CORRECT search function
    
    if #itemIDsToCollect == 0 then
        print("WARN", "No valid item IDs found by FindAllItemIDs_Corrected, though tagged items were detected initially. Check attribute names or values.")
        isMinigameLogicRunning = false; return
    end

    print("ACTION", "Starting collection of", #itemIDsToCollect, "items found via Tag/Attribute...")
    for i, itemID in ipairs(itemIDsToCollect) do
        if not (ScreenGui and ScreenGui.Parent and MainWindow and MainWindow.Visible) then print("INFO","GUI closed/hidden, stopping collection."); break end
        print("INFO", "Collecting item", i, "/", #itemIDsToCollect, "-", itemID)
        GrabItem(itemID)
        wait(0.15) -- Delay between grabs
    end
    print("INFO", "Collection cycle completed.")
    isMinigameLogicRunning = false
end

-- =========================================================================
-- INITIALIZATION (Same as before)
-- =========================================================================
local guiBuildSuccess, guiError = pcall(BuildGUI) 

if guiBuildSuccess and ScreenGui and MainWindow then
    AddToConsole("INFO", SCRIPT_TITLE .. " initialized. GUI ready.")
    AddToConsole("INFO", "Select 'Collector' tab and click 'Start Robot Claw'.")
else
    oldWarn("FATAL_ERROR: GUI could not be built or essential elements are missing. Error:", guiError or "Unknown GUI Build Error")
    oldPrint("FATAL_ERROR: GUI could not be built. Script may not be fully functional. Check default console for earlier DEBUG messages.")
end