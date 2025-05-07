--[[
    Skript pro Robot Claw Minigame s vylepšenou GUI konzolí pro mobilní zařízení
]]

-- Nastavení pro GUI Konzoli
local MAX_CONSOLE_LINES = 70 -- Maximální počet řádků v konzoli
local CONSOLE_VISIBLE_BY_DEFAULT = true

-- === SEKCIE GUI KONZOLE ===
local Players = game:GetService("Players")
local CoreGui = game:GetService("CoreGui")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService") -- Pro plynulejší drag

local consoleScreenGui = CoreGui:FindFirstChild("InGameConsoleAI")
if consoleScreenGui then consoleScreenGui:Destroy() end

consoleScreenGui = Instance.new("ScreenGui")
consoleScreenGui.Name = "InGameConsoleAI"
consoleScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
consoleScreenGui.ResetOnSpawn = false
consoleScreenGui.Parent = CoreGui

local consoleFrame = Instance.new("Frame")
consoleFrame.Name = "ConsoleFrame"
consoleFrame.Size = UDim2.new(0.6, 0, 0.4, 0) -- Větší pro lepší čitelnost na mobilu
consoleFrame.Position = UDim2.new(0.02, 0, 0.02, 0)
consoleFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
consoleFrame.BackgroundTransparency = 0.1
consoleFrame.BorderSizePixel = 1
consoleFrame.BorderColor3 = Color3.fromRGB(70, 70, 70)
consoleFrame.Active = true -- Pro detekci kliknutí (důležité pro drag)
consoleFrame.Draggable = false -- Vypneme defaultní, implementujeme vlastní
consoleFrame.Visible = CONSOLE_VISIBLE_BY_DEFAULT
consoleFrame.Parent = consoleScreenGui

local consoleTitleBar = Instance.new("Frame")
consoleTitleBar.Name = "TitleBar"
consoleTitleBar.Size = UDim2.new(1, 0, 0, 25) -- Trochu vyšší titulní pruh
consoleTitleBar.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
consoleTitleBar.BorderSizePixel = 0
consoleTitleBar.Parent = consoleFrame

local consoleTitle = Instance.new("TextLabel")
consoleTitle.Name = "Title"
consoleTitle.Size = UDim2.new(0.5, 0, 1, 0)
consoleTitle.Position = UDim2.new(0.02, 0, 0, 0)
consoleTitle.BackgroundTransparency = 1
consoleTitle.Font = Enum.Font.SourceSansSemibold
consoleTitle.Text = "Script Output"
consoleTitle.TextColor3 = Color3.fromRGB(210, 210, 210)
consoleTitle.TextSize = 16
consoleTitle.TextXAlignment = Enum.TextXAlignment.Left
consoleTitle.Parent = consoleTitleBar

-- Tlačítka v titulním pruhu (zprava doleva)
local buttonSize = UDim2.new(0, 35, 0.8, 0) -- Velikost pro tlačítka
local buttonSpacing = 5 -- Mezera mezi tlačítky

local toggleButton = Instance.new("TextButton")
toggleButton.Name = "ToggleButton"
toggleButton.Size = buttonSize
toggleButton.AnchorPoint = Vector2.new(1, 0.5) -- Zarovnání doprava
toggleButton.Position = UDim2.new(0.99, -buttonSpacing, 0.5, 0)
toggleButton.BackgroundColor3 = Color3.fromRGB(60,60,60)
toggleButton.Text = "–"
toggleButton.ToolTip = "Hide/Show Console"
toggleButton.TextColor3 = Color3.fromRGB(230,230,230)
toggleButton.Font = Enum.Font.SourceSansBold
toggleButton.TextSize = 18
toggleButton.Parent = consoleTitleBar
toggleButton.MouseButton1Click:Connect(function()
    local mainFrame = toggleButton.Parent.Parent
    mainFrame.Visible = not mainFrame.Visible
end)

local clearButton = Instance.new("TextButton")
clearButton.Name = "ClearButton"
clearButton.Size = buttonSize
clearButton.AnchorPoint = Vector2.new(1, 0.5)
clearButton.Position = UDim2.new(0.99, -(buttonSize.X.Offset + buttonSpacing * 2), 0.5, 0)
clearButton.BackgroundColor3 = Color3.fromRGB(60,60,60)
clearButton.Text = "Clr"
clearButton.ToolTip = "Clear Console"
clearButton.TextColor3 = Color3.fromRGB(230,230,230)
clearButton.Font = Enum.Font.SourceSansBold
clearButton.TextSize = 16
clearButton.Parent = consoleTitleBar

local copyButton = Instance.new("TextButton")
copyButton.Name = "CopyButton"
copyButton.Size = UDim2.new(0, 45, 0.8, 0) -- Širší pro text "Copy"
copyButton.AnchorPoint = Vector2.new(1, 0.5)
copyButton.Position = UDim2.new(0.99, -(buttonSize.X.Offset * 2 + buttonSpacing * 3 + (copyButton.Size.X.Offset - buttonSize.X.Offset)/2), 0.5, 0) -- Upravená pozice
copyButton.BackgroundColor3 = Color3.fromRGB(60,60,60)
copyButton.Text = "Copy"
copyButton.ToolTip = "Copy All to Clipboard"
copyButton.TextColor3 = Color3.fromRGB(230,230,230)
copyButton.Font = Enum.Font.SourceSansBold
copyButton.TextSize = 16
copyButton.Parent = consoleTitleBar

local scrollingFrame = Instance.new("ScrollingFrame")
scrollingFrame.Name = "Log"
scrollingFrame.Size = UDim2.new(1, 0, 1, -consoleTitleBar.Size.Y.Offset)
scrollingFrame.Position = UDim2.new(0, 0, 0, consoleTitleBar.Size.Y.Offset)
scrollingFrame.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
scrollingFrame.BackgroundTransparency = 0
scrollingFrame.BorderSizePixel = 0
scrollingFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
scrollingFrame.ScrollBarThickness = 8 -- Silnější scrollbar pro mobil
scrollingFrame.ScrollingEnabled = true -- Explicitně povoleno
scrollingFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y -- Automatické přizpůsobení výšky canvasu
scrollingFrame.Parent = consoleFrame

local uiListLayout = Instance.new("UIListLayout")
uiListLayout.Parent = scrollingFrame
uiListLayout.SortOrder = Enum.SortOrder.LayoutOrder
uiListLayout.Padding = UDim.new(0, 3)
uiListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left
uiListLayout.FillDirection = Enum.FillDirection.Vertical

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
    
    if setclipboard then -- Globální funkce poskytovaná exploitem
        pcall(function()
            setclipboard(fullLog)
            print("[GUI Console] Log zkopírován do schránky.")
        end)
    elseif game.SetClipboard then -- Starší API, pokud by setclipboard nebylo dostupné
         pcall(function()
            game:SetClipboard(fullLog)
            print("[GUI Console] Log zkopírován do schránky (použito game:SetClipboard).")
        end)
    else
        warn("[GUI Console] Funkce pro kopírování do schránky (setclipboard) není dostupná.")
    end
end)

-- Vlastní logika pro přetahování (Draggable)
local dragging = false
local dragInput = nil
local dragStart = nil
local startPos = nil

consoleTitleBar.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragStart = input.Position
        startPos = consoleFrame.Position
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                dragging = false
            end
        end)
    end
end)

consoleTitleBar.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = false
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        local delta = input.Position - dragStart
        consoleFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
end)


-- Přepsání globálních funkcí print a warn
local oldPrint = print
local oldWarn = warn
local consoleLines = {} -- Nemusíme uchovávat reference na labely zde, UIListLayout se postará

local function AddToConsole(messageType, ...)
    local args = {...}
    local messageParts = {}
    for i = 1, #args do
        table.insert(messageParts, tostring(args[i]))
    end
    local fullMessage = table.concat(messageParts, "\t")

    if messageType == "PRINT" then
        oldPrint(fullMessage)
    elseif messageType == "WARN" then
        oldWarn(fullMessage)
    end

    if not consoleScreenGui or not consoleScreenGui.Parent or not scrollingFrame.Parent then return end

    local textLabel = Instance.new("TextLabel")
    textLabel.Name = "LogEntry"
    textLabel.BackgroundTransparency = 1
    textLabel.Size = UDim2.new(1, -scrollingFrame.ScrollBarThickness - 5, 0, 0) -- Automatická výška
    textLabel.AutomaticSize = Enum.AutomaticSize.Y -- Důležité pro UIListLayout a wrapování textu
    textLabel.Font = Enum.Font.Code
    textLabel.TextSize = 14 -- Větší text pro mobil
    textLabel.TextXAlignment = Enum.TextXAlignment.Left
    textLabel.TextYAlignment = Enum.TextYAlignment.Top
    textLabel.TextWrapped = true
    textLabel.RichText = true -- Umožní lepší formátování v budoucnu, pokud by bylo třeba
    
    local prefix = ""
    if messageType == "WARN" then
        textLabel.TextColor3 = Color3.fromRGB(255, 200, 0)
        prefix = "<font color='#FFC800'>[WARN]</font> " -- RichText pro barvu prefixu
    else
        textLabel.TextColor3 = Color3.fromRGB(225, 225, 225)
    end
    textLabel.Text = prefix .. fullMessage:gsub("<", "<"):gsub(">", ">") -- Escapování HTML pro RichText
    textLabel.Parent = scrollingFrame

    -- Omezení počtu řádků
    while #scrollingFrame:GetChildren() > MAX_CONSOLE_LINES + 1 do -- +1 kvůli UIListLayout
        local childToRemove = scrollingFrame:GetChildren()[1] -- První je UIListLayout, chceme druhý
        if childToRemove ~= uiListLayout then
             childToRemove:Destroy()
        else -- Pokud je první UIListLayout, vezmeme druhý
            if #scrollingFrame:GetChildren() > 1 then
                scrollingFrame:GetChildren()[2]:Destroy()
            end
        end
    end
    
    -- Automatické scrollování dolů
    task.wait() -- Krátké počkání, aby se UIListLayout a AutomaticSize stihly aktualizovat
    if scrollingFrame.CanvasSize.Y.Offset > scrollingFrame.AbsoluteSize.Y then
        scrollingFrame.CanvasPosition = Vector2.new(0, scrollingFrame.CanvasSize.Y.Offset - scrollingFrame.AbsoluteSize.Y + 5)
    end
end

print = function(...) AddToConsole("PRINT", ...) end
warn = function(...) AddToConsole("WARN", ...) end

print("GUI Konzole v2 inicializována.")
warn("Toto je testovací varování v GUI konzoli.")
for i=1, 5 do print("Testovací řádek pro scroll #" .. i) end -- Test pro scroll

-- === KONEC SEKCIE GUI KONZOLE ===


-- === TVŮJ PŮVODNÍ SKRIPT ZAČÍNÁ ZDE ===
-- Služby
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

-- Funkce pro spuštění minihry
function StartRobotClawInsane(remoteEventInstance)
    if not remoteEventInstance or not remoteEventInstance:IsA("RemoteEvent") then
        warn("[StartRobotClawInsane] RemoteEvent pro spuštění minihry nebyl poskytnut nebo není RemoteEvent!")
        return
    end
    local args = {
        [1] = "StartMinigame",
        [2] = "Robot Claw",
        [3] = "Insane"
    }
    print("[StartRobotClawInsane] Spouštím minihru Robot Claw (Insane)...")
    remoteEventInstance:FireServer(unpack(args))
end

-- Funkce pro sebrání předmětu
function GrabItem(itemId, remoteEventInstance)
    if not remoteEventInstance or not remoteEventInstance:IsA("RemoteEvent") then
        warn("[GrabItem] RemoteEvent pro sebrání itemu nebyl poskytnut nebo není RemoteEvent!")
        return
    end
    local args = {
        "GrabMinigameItem",
        itemId
    }
    remoteEventInstance:FireServer(unpack(args))
end

-- Funkce pro nalezení všech IDček předmětů v minihře
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

    if #children == 0 then
        print("[FindAllItemIDs] Složka Chunker je prázdná.")
    end

    for i, itemInstance in ipairs(children) do
        print("[FindAllItemIDs] Zpracovávám dítě #" .. i .. " | Jméno: '" .. itemInstance.Name .. "' | ClassName: '" .. itemInstance.ClassName .. "'")
        if string.len(itemInstance.Name) == 36 and string.find(itemInstance.Name, "-", 1, true) then 
            print("[FindAllItemIDs] ---> Nalezen potenciální item s ID (dle jména):", itemInstance.Name)
            table.insert(itemIDs, itemInstance.Name)
        else
            print("[FindAllItemIDs] ---> Jméno '" .. itemInstance.Name .. "' neodpovídá formátu ID (délka 36 a pomlčka), ignoruji.")
        end
    end

    if #itemIDs == 0 then
        warn("[FindAllItemIDs] Po zpracování všech dětí nebyla nalezena žádná IDčka předmětů odpovídající kritériím.")
    end
    
    print("[FindAllItemIDs] Nalezeno celkem ".. #itemIDs .." IDček k sebrání.")
    return itemIDs
end

-- Hlavní logika skriptu
function Main()
    print("[Main] Skript spuštěn. Ověřuji RemoteEvent...")
    local remote = nil
    local success, remoteEventInstance = pcall(function()
        return ReplicatedStorage:WaitForChild("Shared", 20):WaitForChild("Framework", 10):WaitForChild("Network", 10):WaitForChild("Remote", 10):WaitForChild("Event", 10)
    end)

    if not success or not remoteEventInstance or not remoteEventInstance:IsA("RemoteEvent") then
         warn("[Main] Kritická chyba: RemoteEvent na cestě '...Shared.Framework.Network.Remote.Event' nebyl nalezen (možná timeout WaitForChild) nebo není RemoteEvent! Skript nemůže pokračovat. Chyba: " .. tostring(remoteEventInstance))
         return
    end
    remote = remoteEventInstance
    print("[Main] RemoteEvent nalezen: " .. remote:GetFullName())

    StartRobotClawInsane(remote)

    print("[Main] Čekám, až se objeví první itemy v Chunkeru (max 30 sekund)...")
    local startTime = tick()
    local chunkerFolder = nil
    local renderedFolder = Workspace:FindFirstChild("Rendered") 

    if renderedFolder then
        print("[Main_WaitLoop] Složka 'Rendered' nalezena ihned.")
        chunkerFolder = renderedFolder:FindFirstChild("Chunker")
        if chunkerFolder then
            print("[Main_WaitLoop] Složka 'Chunker' nalezena ihned.")
        end
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
task.spawn(Main)
print("Skript pro sběr itemů v Robot Claw (s vylepšenou GUI konzolí v2) načten a spuštěn přes task.spawn(Main).")