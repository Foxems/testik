--[[
    Skript pro Robot Claw Minigame s VYLEPŠENOU GUI konzolí v3
    Cílem je opravit drag a zajistit spuštění minihry.
]]

-- Store original print/warn functions IMMEDIATELY
local _G = getfenv(0) -- Get global environment
local oldPrint = _G.print
local oldWarn = _G.warn

oldPrint("DEBUG: Script execution started. Original print/warn captured.")

-- Nastavení pro GUI Konzoli
local MAX_CONSOLE_LINES = 70
local CONSOLE_VISIBLE_BY_DEFAULT = true

-- === SEKCIE GUI KONZOLE ===
local Players = game:GetService("Players")
local CoreGui = game:GetService("CoreGui")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local consoleScreenGui = nil
local consoleFrame = nil
local scrollingFrame = nil
local uiListLayout = nil -- Reference for scrolling

local guiInitializationSuccess = false

-- Wrap GUI creation in pcall
local success, err = pcall(function()
    oldPrint("DEBUG: Attempting to initialize GUI console...")

    local existingConsole = CoreGui:FindFirstChild("InGameConsoleAI_v3")
    if existingConsole then existingConsole:Destroy() end

    consoleScreenGui = Instance.new("ScreenGui")
    consoleScreenGui.Name = "InGameConsoleAI_v3"
    consoleScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    consoleScreenGui.ResetOnSpawn = false
    consoleScreenGui.Parent = CoreGui
    oldPrint("DEBUG: ScreenGui created.")

    consoleFrame = Instance.new("Frame")
    consoleFrame.Name = "ConsoleFrame"
    consoleFrame.Size = UDim2.new(0.6, 0, 0.45, 0)
    consoleFrame.Position = UDim2.new(0.02, 0, 0.02, 0)
    consoleFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
    consoleFrame.BackgroundTransparency = 0.1
    consoleFrame.BorderSizePixel = 1
    consoleFrame.BorderColor3 = Color3.fromRGB(70, 70, 70)
    consoleFrame.Active = true -- ESSENTIAL for input detection on itself or children
    consoleFrame.Draggable = false -- Using custom drag
    consoleFrame.Visible = CONSOLE_VISIBLE_BY_DEFAULT
    consoleFrame.Parent = consoleScreenGui
    oldPrint("DEBUG: ConsoleFrame created. Active:", consoleFrame.Active)

    local consoleTitleBar = Instance.new("Frame")
    consoleTitleBar.Name = "TitleBar"
    consoleTitleBar.Size = UDim2.new(1, 0, 0, 30)
    consoleTitleBar.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
    consoleTitleBar.BorderSizePixel = 0
    consoleTitleBar.Active = true -- ESSENTIAL for input detection for dragging
    consoleTitleBar.Parent = consoleFrame
    oldPrint("DEBUG: TitleBar created. Active:", consoleTitleBar.Active)

    local consoleTitle = Instance.new("TextLabel")
    consoleTitle.Name = "Title"
    consoleTitle.Size = UDim2.new(0.5, 0, 1, 0)
    consoleTitle.Position = UDim2.new(0.02, 0, 0, 0)
    consoleTitle.BackgroundTransparency = 1
    consoleTitle.Font = Enum.Font.SourceSansSemibold
    consoleTitle.Text = "Script Output v3"
    consoleTitle.TextColor3 = Color3.fromRGB(210, 210, 210)
    consoleTitle.TextSize = 16
    consoleTitle.TextXAlignment = Enum.TextXAlignment.Left
    consoleTitle.Parent = consoleTitleBar

    local buttonSize = UDim2.new(0, 40, 0.8, 0)
    local buttonSpacing = 7

    local toggleButton = Instance.new("TextButton")
    toggleButton.Name = "ToggleButton"
    toggleButton.Size = buttonSize
    toggleButton.AnchorPoint = Vector2.new(1, 0.5)
    toggleButton.Position = UDim2.new(1, -buttonSpacing, 0.5, 0)
    toggleButton.BackgroundColor3 = Color3.fromRGB(60,60,60)
    toggleButton.Text = "–"
    toggleButton.ToolTip = "Hide/Show Console"
    toggleButton.TextColor3 = Color3.fromRGB(230,230,230)
    toggleButton.Font = Enum.Font.SourceSansBold
    toggleButton.TextSize = 20
    toggleButton.Parent = consoleTitleBar
    toggleButton.MouseButton1Click:Connect(function()
        consoleFrame.Visible = not consoleFrame.Visible
    end)

    local clearButton = Instance.new("TextButton")
    clearButton.Name = "ClearButton"
    clearButton.Size = buttonSize
    clearButton.AnchorPoint = Vector2.new(1, 0.5)
    clearButton.Position = UDim2.new(1, -(buttonSize.X.Offset + buttonSpacing * 2), 0.5, 0)
    clearButton.BackgroundColor3 = Color3.fromRGB(60,60,60)
    clearButton.Text = "Clr"
    clearButton.ToolTip = "Clear Console"
    clearButton.TextColor3 = Color3.fromRGB(230,230,230)
    clearButton.Font = Enum.Font.SourceSansBold
    clearButton.TextSize = 16
    clearButton.Parent = consoleTitleBar

    local copyButton = Instance.new("TextButton")
    copyButton.Name = "CopyButton"
    copyButton.Size = UDim2.new(0, 50, 0.8, 0)
    copyButton.AnchorPoint = Vector2.new(1, 0.5)
    copyButton.Position = UDim2.new(1, -(buttonSize.X.Offset * 2 + buttonSpacing * 3 + (copyButton.Size.X.Offset - buttonSize.X.Offset)/2 + 5), 0.5, 0)
    copyButton.BackgroundColor3 = Color3.fromRGB(60,60,60)
    copyButton.Text = "Copy"
    copyButton.ToolTip = "Copy All to Clipboard"
    copyButton.TextColor3 = Color3.fromRGB(230,230,230)
    copyButton.Font = Enum.Font.SourceSansBold
    copyButton.TextSize = 16
    copyButton.Parent = consoleTitleBar
    oldPrint("DEBUG: Buttons created.")

    scrollingFrame = Instance.new("ScrollingFrame")
    scrollingFrame.Name = "Log"
    scrollingFrame.Size = UDim2.new(1, 0, 1, -consoleTitleBar.Size.Y.Offset)
    scrollingFrame.Position = UDim2.new(0, 0, 0, consoleTitleBar.Size.Y.Offset)
    scrollingFrame.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
    scrollingFrame.BackgroundTransparency = 0
    scrollingFrame.BorderSizePixel = 0
    scrollingFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
    scrollingFrame.ScrollBarThickness = 10
    scrollingFrame.ScrollingEnabled = true
    scrollingFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
    scrollingFrame.Parent = consoleFrame

    uiListLayout = Instance.new("UIListLayout") -- Assign to the upvalue
    uiListLayout.Parent = scrollingFrame
    uiListLayout.SortOrder = Enum.SortOrder.LayoutOrder
    uiListLayout.Padding = UDim.new(0, 3)
    uiListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left
    uiListLayout.FillDirection = Enum.FillDirection.Vertical
    oldPrint("DEBUG: ScrollingFrame and UIListLayout created.")

    clearButton.MouseButton1Click:Connect(function()
        for _, child in ipairs(scrollingFrame:GetChildren()) do
            if child:IsA("TextLabel") then
                child:Destroy()
            end
        end
        scrollingFrame.CanvasPosition = Vector2.new(0,0)
    end)

    copyButton.MouseButton1Click:Connect(function()
        local allText = {}
        for _, child in ipairs(scrollingFrame:GetChildren()) do
            if child:IsA("TextLabel") then
                table.insert(allText, child.Text)
            end
        end
        local fullLog = table.concat(allText, "\n")
        
        local clipboardFunc = _G.setclipboard or (_G.game and _G.game.SetClipboard)
        if clipboardFunc then
            pcall(clipboardFunc, fullLog)
            _G.print("[GUI Console] Log zkopírován do schránky.") -- Use new print
        else
            _G.warn("[GUI Console] Funkce pro kopírování do schránky není dostupná.") -- Use new warn
        end
    end)

    -- Vlastní logika pro přetahování (Draggable)
    local dragging = false
    local dragStartMousePos = nil
    local frameStartPos = nil

    consoleTitleBar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            oldPrint("DEBUG: Drag InputBegan")
            dragging = true
            dragStartMousePos = input.Position
            frameStartPos = consoleFrame.Position
            
            local connChanged
            connChanged = input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                    oldPrint("DEBUG: Drag InputEnded (via changed)")
                    if connChanged then connChanged:Disconnect() end
                end
            end)
        end
    end)

    consoleTitleBar.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            if dragging then -- Only if it was already dragging (safety)
                 dragging = false
                 oldPrint("DEBUG: Drag InputEnded (direct)")
            end
        end
    end)
    
    -- Use RenderStepped for smoother dragging, but ensure it only runs when dragging
    RunService.RenderStepped:Connect(function()
        if dragging and dragStartMousePos and frameStartPos then
            local currentMousePos = UserInputService:GetMouseLocation() -- More reliable for continuous drag
            if UserInputService.TouchEnabled and UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) == false then
                 -- For touch, rely on InputEnded mostly. This is a fallback if finger lifted without InputEnded firing for titlebar.
                 -- However, GetMouseLocation might not be ideal for touch.
                 -- For simplicity now, let's assume touch drag ends mostly with InputEnded on the titlebar.
                 -- If touch drag is problematic, we might need specific touch event handling.
            end
            local delta = currentMousePos - dragStartMousePos
            consoleFrame.Position = UDim2.new(frameStartPos.X.Scale, frameStartPos.X.Offset + delta.X,
                                              frameStartPos.Y.Scale, frameStartPos.Y.Offset + delta.Y)
        end
    end)
    oldPrint("DEBUG: Drag logic connected.")
    guiInitializationSuccess = true
end)

if not success then
    oldPrint("FATAL ERROR INITIALIZING GUI CONSOLE:", err)
    oldPrint("Stack trace:", debug.traceback())
end

-- Přepsání globálních funkcí print a warn
local function AddToConsole(messageType, ...)
    if not guiInitializationSuccess or not consoleScreenGui or not consoleScreenGui.Parent or not scrollingFrame or not scrollingFrame.Parent then
        -- Fallback to oldPrint if GUI isn't ready or got destroyed
        local args = {...}
        local messageParts = {}
        for i = 1, #args do table.insert(messageParts, tostring(args[i])) end
        oldPrint((messageType == "WARN" and "[WARN_FALLBACK] " or "[PRINT_FALLBACK] ") .. table.concat(messageParts, "\t"))
        return
    end

    local args = {...}
    local messageParts = {}
    for i = 1, #args do table.insert(messageParts, tostring(args[i])) end
    local fullMessage = table.concat(messageParts, "\t")

    -- Also call original print/warn for other potential listeners (e.g. exploit console)
    if messageType == "PRINT" then oldPrint(fullMessage)
    elseif messageType == "WARN" then oldWarn(fullMessage) end

    local textLabel = Instance.new("TextLabel")
    textLabel.Name = "LogEntry"
    textLabel.BackgroundTransparency = 1
    textLabel.Size = UDim2.new(1, -scrollingFrame.ScrollBarThickness - 5, 0, 0)
    textLabel.AutomaticSize = Enum.AutomaticSize.Y
    textLabel.Font = Enum.Font.Code
    textLabel.TextSize = 14
    textLabel.TextXAlignment = Enum.TextXAlignment.Left
    textLabel.TextYAlignment = Enum.TextYAlignment.Top
    textLabel.TextWrapped = true
    textLabel.RichText = true
    
    local prefix = ""
    if messageType == "WARN" then
        textLabel.TextColor3 = Color3.fromRGB(255, 200, 0)
        prefix = "<font color='#FFC800'>[WARN]</font> "
    else
        textLabel.TextColor3 = Color3.fromRGB(225, 225, 225)
    end
    textLabel.Text = prefix .. fullMessage:gsub("<", "<"):gsub(">", ">")
    textLabel.Parent = scrollingFrame

    while #scrollingFrame:GetChildren() > MAX_CONSOLE_LINES + 1 do
        local childToRemove = scrollingFrame:GetChildren()[1]
        if childToRemove ~= uiListLayout then childToRemove:Destroy()
        elseif #scrollingFrame:GetChildren() > 1 then scrollingFrame:GetChildren()[2]:Destroy() end
    end
    
    task.wait()
    if scrollingFrame and uiListLayout and scrollingFrame.CanvasSize.Y.Offset > scrollingFrame.AbsoluteSize.Y then
        scrollingFrame.CanvasPosition = Vector2.new(0, uiListLayout.AbsoluteContentSize.Y) -- Prefer AbsoluteContentSize for more accuracy
    end
end

if guiInitializationSuccess then
    _G.print = function(...) AddToConsole("PRINT", ...) end
    _G.warn = function(...) AddToConsole("WARN", ...) end
    print("GUI Console v3 initialized. New print/warn active.")
    print("Testing console with a few lines...")
    for i=1, 3 do print("Test line for scrolling #" .. i) end
else
    oldPrint("GUI Console v3 FAILED to initialize. Using fallback print/warn.")
    _G.print = oldPrint -- Revert to old if GUI failed
    _G.warn = oldWarn
end


-- === TVŮJ PŮVODNÍ SKRIPT ZAČÍNÁ ZDE ===
print("DEBUG: Main script logic starting now...")

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

function StartRobotClawInsane(remoteEventInstance)
    if not remoteEventInstance or not remoteEventInstance:IsA("RemoteEvent") then
        warn("[StartRobotClawInsane] RemoteEvent pro spuštění minihry nebyl poskytnut nebo není RemoteEvent!")
        return
    end
    local args = { "StartMinigame", "Robot Claw", "Insane" }
    print("[StartRobotClawInsane] Spouštím minihru Robot Claw (Insane)... Args:", table.concat(args, ", "))
    remoteEventInstance:FireServer(unpack(args))
    print("[StartRobotClawInsane] FireServer called for StartMinigame.")
end

function GrabItem(itemId, remoteEventInstance)
    if not remoteEventInstance or not remoteEventInstance:IsA("RemoteEvent") then
        warn("[GrabItem] RemoteEvent pro sebrání itemu nebyl poskytnut nebo není RemoteEvent!")
        return
    end
    local args = { "GrabMinigameItem", itemId }
    remoteEventInstance:FireServer(unpack(args))
end

function FindAllItemIDs()
    local itemIDs = {}
    print("[FindAllItemIDs] Začátek funkce.")
    local renderedFolder = Workspace:FindFirstChild("Rendered")
    if not renderedFolder then
        print("[FindAllItemIDs] Složka 'Workspace.Rendered' NENALEZENA.")
        return itemIDs 
    else
        print("[FindAllItemIDs] Složka 'Workspace.Rendered' nalezena: " .. renderedFolder:GetFullName())
    end

    local chunkerFolder = renderedFolder:FindFirstChild("Chunker")
    if not chunkerFolder then
        print("[FindAllItemIDs] Složka 'Workspace.Rendered.Chunker' NENALEZENA.")
        return itemIDs
    else
        print("[FindAllItemIDs] Složka 'Workspace.Rendered.Chunker' nalezena: " .. chunkerFolder:GetFullName())
    end

    local children = chunkerFolder:GetChildren()
    print("[FindAllItemIDs] Počet přímých dětí ve složce Chunker: " .. #children)
    if #children == 0 then print("[FindAllItemIDs] Složka Chunker je prázdná.") end

    for i, itemInstance in ipairs(children) do
        print("[FindAllItemIDs] Zpracovávám dítě #" .. i .. " | Jméno: '" .. itemInstance.Name .. "' | ClassName: '" .. itemInstance.ClassName .. "'")
        if string.len(itemInstance.Name) == 36 and string.find(itemInstance.Name, "-", 1, true) then 
            print("[FindAllItemIDs] ---> Nalezen potenciální item s ID (dle jména):", itemInstance.Name)
            table.insert(itemIDs, itemInstance.Name)
        else
            print("[FindAllItemIDs] ---> Jméno '" .. itemInstance.Name .. "' neodpovídá formátu ID (délka 36 a pomlčka), ignoruji.")
        end
    end

    if #itemIDs == 0 then warn("[FindAllItemIDs] Po zpracování všech dětí nebyla nalezena žádná IDčka předmětů odpovídající kritériím.") end
    print("[FindAllItemIDs] Nalezeno celkem ".. #itemIDs .." IDček k sebrání.")
    return itemIDs
end

function Main()
    print("[Main] Hlavní funkce Main() spuštěna.")
    print("[Main] Ověřuji RemoteEvent...")
    local remote = nil
    local remotePathString = "ReplicatedStorage.Shared.Framework.Network.Remote.Event" -- For logging
    
    local findRemoteSuccess, remoteEventInstanceOrError = pcall(function()
        return ReplicatedStorage:WaitForChild("Shared", 30):WaitForChild("Framework", 15):WaitForChild("Network", 15):WaitForChild("Remote", 15):WaitForChild("Event", 15)
    end)

    if not findRemoteSuccess then
         warn("[Main] Kritická chyba při hledání RemoteEvent (pcall selhal): ", tostring(remoteEventInstanceOrError))
         warn("[Main] Cesta: ", remotePathString)
         print("[Main] Skript se nemůže spustit bez RemoteEvent.")
         return
    end
    if not remoteEventInstanceOrError or not remoteEventInstanceOrError:IsA("RemoteEvent") then
         warn("[Main] Kritická chyba: RemoteEvent na cestě '"..remotePathString.."' nebyl nalezen (timeout WaitForChild nebo není RemoteEvent)! Skript nemůže pokračovat.")
         print("[Main] Vrácená hodnota z WaitForChild chainu: ", tostring(remoteEventInstanceOrError))
         return
    end

    remote = remoteEventInstanceOrError
    print("[Main] RemoteEvent úspěšně nalezen: " .. remote:GetFullName())

    StartRobotClawInsane(remote)

    print("[Main] Čekám, až se objeví první itemy v Chunkeru (max 30 sekund)...")
    local startTime = tick()
    local chunkerFolder = nil
    local renderedFolder = Workspace:FindFirstChild("Rendered") 

    if renderedFolder then
        print("[Main_WaitLoop] Složka 'Rendered' nalezena ihned.")
        chunkerFolder = renderedFolder:FindFirstChild("Chunker")
        if chunkerFolder then print("[Main_WaitLoop] Složka 'Chunker' nalezena ihned.") end
    end
    
    local iteration = 0
    while not (chunkerFolder and #chunkerFolder:GetChildren() > 0) and (tick() - startTime < 30) do
        iteration = iteration + 1
        wait(0.5)
        if not renderedFolder then 
            renderedFolder = Workspace:FindFirstChild("Rendered")
            if renderedFolder then print("[Main_WaitLoop] Složka 'Rendered' nalezena v iteraci " .. iteration) end
        end
        if renderedFolder and not chunkerFolder then 
            chunkerFolder = renderedFolder:FindFirstChild("Chunker") 
            if chunkerFolder then print("[Main_WaitLoop] Složka 'Chunker' nalezena v iteraci " .. iteration) end
        end
    end

    if not (chunkerFolder and #chunkerFolder:GetChildren() > 0) then
        warn("[Main] Timeout nebo Chunker složka stále prázdná/neexistuje po " .. string.format("%.1f", tick() - startTime) .. " sekundách. Sbírání se nespustí.")
        if not renderedFolder then print("[Main_Debug] Složka 'Workspace.Rendered' nebyla nalezena ani po čekání.") end
        if renderedFolder and not chunkerFolder then print("[Main_Debug] Složka 'Workspace.Rendered.Chunker' nebyla nalezena ani po čekání.") end
        if chunkerFolder and #chunkerFolder:GetChildren() == 0 then print("[Main_Debug] Složka 'Workspace.Rendered.Chunker' byla nalezena, ale je prázdná.") end
        return
    end
    print("[Main] Itemy detekovány v Chunkeru (po " .. string.format("%.1f", tick() - startTime) .. "s). Počet dětí: " .. #chunkerFolder:GetChildren() .. ". Pokračuji sběrem.")
    
    print("[Main] Krátká dodatečná pauza (1s) pro případné další itemy...")
    wait(1)

    local itemIDsToCollect = FindAllItemIDs()

    if #itemIDsToCollect > 0 then
        print("[Main] Začínám sbírat " .. #itemIDsToCollect .. " předmětů...")
        for i, itemID in ipairs(itemIDsToCollect) do
            print("[Main] ===> POKUS O SEBRÁNÍ předmětu " .. i .. "/" .. #itemIDsToCollect .. " s ID: " .. itemID .. " <===")
            GrabItem(itemID, remote) 
            wait(0.1)
        end
        print("[Main] Všechny " .. #itemIDsToCollect .. " nalezené předměty byly zpracovány (pokus o sebrání odeslán).")
    else
        print("[Main] Nebyly nalezeny žádné předměty k sebrání podle kritérií ve funkci FindAllItemIDs. Zkontroluj debug výpisy z této funkce.")
    end
    print("[Main] Skript dokončil operace.")
end

-- === Spuštění skriptu ===
print("DEBUG: Příprava na spuštění Main() přes task.spawn().")
task.spawn(Main)
print("DEBUG: task.spawn(Main) zavoláno. Hlavní logika by měla běžet asynchronně.")