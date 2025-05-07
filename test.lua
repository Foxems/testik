--[[
    Skript pro Robot Claw Minigame s vestavěnou GUI konzolí
    Autor původního skriptu: (Ty)
    GUI Konzole a úpravy: (AI)
]]

-- Nastavení pro GUI Konzoli
local MAX_CONSOLE_LINES = 50 -- Maximální počet řádků v konzoli, než se začnou mazat staré
local CONSOLE_VISIBLE_BY_DEFAULT = true -- Zda má být konzole viditelná hned po spuštění

-- === SEKCIE GUI KONZOLE ===
local Players = game:GetService("Players")
local CoreGui = game:GetService("CoreGui") -- Použijeme CoreGui pro vyšší prioritu zobrazení

local consoleScreenGui = CoreGui:FindFirstChild("InGameConsole")
if consoleScreenGui then consoleScreenGui:Destroy() end -- Odstraní starou konzoli, pokud existuje

consoleScreenGui = Instance.new("ScreenGui")
consoleScreenGui.Name = "InGameConsole"
consoleScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling -- Nebo Global, pokud je potřeba být vždy navrchu
consoleScreenGui.ResetOnSpawn = false
consoleScreenGui.Parent = CoreGui

local consoleFrame = Instance.new("Frame")
consoleFrame.Name = "ConsoleFrame"
consoleFrame.Size = UDim2.new(0.4, 0, 0.3, 0) -- Šířka 40% obrazovky, výška 30%
consoleFrame.Position = UDim2.new(0.01, 0, 0.01, 0) -- Vlevo nahoře
consoleFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
consoleFrame.BackgroundTransparency = 0.2
consoleFrame.BorderSizePixel = 1
consoleFrame.BorderColor3 = Color3.fromRGB(80, 80, 80)
consoleFrame.Active = true -- Pro detekci kliknutí
consoleFrame.Draggable = true -- Umožní přetahování
consoleFrame.Visible = CONSOLE_VISIBLE_BY_DEFAULT
consoleFrame.Parent = consoleScreenGui

local consoleTitleBar = Instance.new("Frame")
consoleTitleBar.Name = "TitleBar"
consoleTitleBar.Size = UDim2.new(1, 0, 0, 20) -- Výška 20 pixelů
consoleTitleBar.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
consoleTitleBar.BorderSizePixel = 0
consoleTitleBar.Parent = consoleFrame

local consoleTitle = Instance.new("TextLabel")
consoleTitle.Name = "Title"
consoleTitle.Size = UDim2.new(0.8, 0, 1, 0)
consoleTitle.Position = UDim2.new(0, 5, 0, 0)
consoleTitle.BackgroundTransparency = 1
consoleTitle.Font = Enum.Font.SourceSansSemibold
consoleTitle.Text = "Script Output"
consoleTitle.TextColor3 = Color3.fromRGB(220, 220, 220)
consoleTitle.TextSize = 14
consoleTitle.TextXAlignment = Enum.TextXAlignment.Left
consoleTitle.Parent = consoleTitleBar

local toggleButton = Instance.new("TextButton")
toggleButton.Name = "ToggleButton"
toggleButton.Size = UDim2.new(0.1, 0, 0.8, 0)
toggleButton.Position = UDim2.new(0.89, -5, 0.1, 0)
toggleButton.BackgroundColor3 = Color3.fromRGB(70,70,70)
toggleButton.Text = "X" -- Nebo "–" pro minimalizaci
toggleButton.TextColor3 = Color3.fromRGB(255,255,255)
toggleButton.Font = Enum.Font.SourceSansBold
toggleButton.TextSize = 14
toggleButton.Parent = consoleTitleBar
toggleButton.MouseButton1Click:Connect(function()
    consoleFrame.Visible = not consoleFrame.Visible
end)

local clearButton = Instance.new("TextButton")
clearButton.Name = "ClearButton"
clearButton.Size = UDim2.new(0.1, 0, 0.8, 0)
clearButton.Position = UDim2.new(0.78, -5, 0.1, 0)
clearButton.BackgroundColor3 = Color3.fromRGB(70,70,70)
clearButton.Text = "Clr"
clearButton.TextColor3 = Color3.fromRGB(255,255,255)
clearButton.Font = Enum.Font.SourceSansBold
clearButton.TextSize = 14
clearButton.Parent = consoleTitleBar

local scrollingFrame = Instance.new("ScrollingFrame")
scrollingFrame.Name = "Log"
scrollingFrame.Size = UDim2.new(1, 0, 1, -20) -- Odsazení od titulku
scrollingFrame.Position = UDim2.new(0, 0, 0, 20)
scrollingFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
scrollingFrame.BackgroundTransparency = 0.1
scrollingFrame.BorderSizePixel = 0
scrollingFrame.CanvasSize = UDim2.new(0, 0, 0, 0) -- Automaticky se přizpůsobí obsahu
scrollingFrame.ScrollBarThickness = 6
scrollingFrame.Parent = consoleFrame

local uiListLayout = Instance.new("UIListLayout")
uiListLayout.Parent = scrollingFrame
uiListLayout.SortOrder = Enum.SortOrder.LayoutOrder
uiListLayout.Padding = UDim.new(0, 2)

clearButton.MouseButton1Click:Connect(function()
    for _, child in ipairs(scrollingFrame:GetChildren()) do
        if child:IsA("TextLabel") then
            child:Destroy()
        end
    end
    scrollingFrame.CanvasPosition = Vector2.new(0,0)
end)


-- Přepsání globálních funkcí print a warn
local oldPrint = print
local oldWarn = warn
local consoleLines = {}

local function AddToConsole(messageType, ...)
    local args = {...}
    local messageParts = {}
    for i = 1, #args do
        table.insert(messageParts, tostring(args[i]))
    end
    local fullMessage = table.concat(messageParts, "\t") -- Spojí argumenty tabulátorem

    -- Vypíše i do původní konzole (pokud funguje)
    if messageType == "PRINT" then
        oldPrint(fullMessage)
    elseif messageType == "WARN" then
        oldWarn(fullMessage)
    end

    if not consoleScreenGui or not consoleScreenGui.Parent then return end -- Pokud GUI není aktivní

    local textLabel = Instance.new("TextLabel")
    textLabel.Name = "LogEntry"
    textLabel.BackgroundTransparency = 1
    textLabel.Size = UDim2.new(1, -10, 0, 14) -- -10 pro padding od scrollbaru
    textLabel.Font = Enum.Font.Code -- Nebo SourceSans
    textLabel.TextSize = 12
    textLabel.TextXAlignment = Enum.TextXAlignment.Left
    textLabel.TextWrapped = true
    
    local prefix = ""
    if messageType == "WARN" then
        textLabel.TextColor3 = Color3.fromRGB(255, 200, 0) -- Žlutá pro varování
        prefix = "[WARN] "
    else
        textLabel.TextColor3 = Color3.fromRGB(230, 230, 230) -- Bílá pro běžný print
    end
    textLabel.Text = prefix .. fullMessage
    textLabel.Parent = scrollingFrame

    table.insert(consoleLines, textLabel)

    -- Omezení počtu řádků
    if #consoleLines > MAX_CONSOLE_LINES then
        local lineToRemove = table.remove(consoleLines, 1)
        if lineToRemove then lineToRemove:Destroy() end
    end
    
    -- Automatické scrollování dolů (může vyžadovat krátké počkání na přepočet layoutu)
    task.wait() -- Počkáme na další frame, aby se UIListLayout stihl aktualizovat
    scrollingFrame.CanvasPosition = Vector2.new(0, uiListLayout.AbsoluteContentSize.Y)
end

-- Nové globální funkce
print = function(...) AddToConsole("PRINT", ...) end
warn = function(...) AddToConsole("WARN", ...) end

print("GUI Konzole inicializována. Výpisy se zobrazí zde.")
warn("Toto je testovací varování v GUI konzoli.")

-- === KONEC SEKCIE GUI KONZOLE ===


-- === TVŮJ PŮVODNÍ SKRIPT ZAČÍNÁ ZDE ===
-- (vlož sem zbytek tvého skriptu, který jsi mi poslal minule)

-- Služby
local ReplicatedStorage = game:GetService("ReplicatedStorage")
-- Workspace je již definován v GUI části, ale můžeme ho pro jistotu definovat znovu lokálně, pokud by byl konflikt
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
    -- print("[GrabItem] Pokouším se sebrat předmět s ID:", itemId)
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
        -- U mobilních exploitů může WaitForChild někdy zamrznout, pokud se něco načítá pomalu.
        -- Pokud by to byl problém, zvážit přímé cesty s kontrolou existence.
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
-- task.spawn(Main)
-- nebo
-- Main()

print("Skript pro sběr itemů v Robot Claw (s vestavěnou GUI konzolí) načten. Zavolej Main() nebo task.spawn(Main) pro spuštění.")
-- Příklad automatického spuštění:
task.spawn(Main)