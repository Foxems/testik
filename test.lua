--[[
    Robot Claw Collector with Rayfield UI Console
    PLEASE ENSURE YOUR EXECUTOR CAN RUN HttpGet AND LOAD RAYFIELD.
]]

-- Store original print/warn functions IMMEDIATELY
local _G = getfenv(0)
local oldPrint = _G.print
local oldWarn = _G.warn

oldPrint("DEBUG: Script started. Attempting to load Rayfield UI Library...")

-- === 1. LOAD RAYFIELD UI LIBRARY ===
local Rayfield
local rayfieldLoaded = false
local rayfieldLoadError = ""

-- Common Rayfield loadstring (ensure this link is active and your executor supports it)
local success, result = pcall(function()
    Rayfield = loadstring(game:HttpGet('https://raw.githubusercontent.com/shlexware/Rayfield/main/source'))()
end)

if success and Rayfield and Rayfield.CreateWindow then
    oldPrint("DEBUG: Rayfield loaded successfully.")
    rayfieldLoaded = true
else
    rayfieldLoadError = success and "Rayfield loaded but API seems missing." or tostring(result)
    oldPrint("ERROR: Failed to load Rayfield UI Library. Error: " .. rayfieldLoadError)
    oldPrint("The script will continue using basic print for output if your executor shows it.")
    oldPrint("A GUI console will NOT be available.")
    -- Revert to old print/warn if Rayfield fails
    _G.print = oldPrint
    _G.warn = oldWarn
end

-- === 2. SETUP RAYFIELD WINDOW AND CONSOLE ELEMENTS (if loaded) ===
local Window, ConsoleTab
local consoleLogLines = {} -- Store lines of text for the console
local MAX_CONSOLE_LOG_LINES = 100 -- Max lines to keep in our Rayfield display
local consoleOutputLabel = nil -- This will be our "text area"

if rayfieldLoaded then
    local themeSuccess, themeErr = pcall(function()
        -- Attempt to set a theme if desired (optional)
        Rayfield:SetTheme("Dark") -- Or other themes like "Bloody", "Midnight", etc.
        
        Window = Rayfield:CreateWindow({
            Name = "Robot Claw Collector",
            LoadingTitle = "Collector Initializing",
            LoadingSubtitle = "by YourName & AI",
            ConfigurationSaving = {
                Enabled = false, -- No settings to save for this simple script
            },
            KeySystem = false -- No key system needed
        })

        ConsoleTab = Window:CreateTab({ Name = "Console Output" })

        local ConsoleSection = ConsoleTab:CreateSection({ Name = "Log" })

        -- Rayfield doesn't have a simple "LogBox". We'll use a label and update it.
        -- Create an initial dummy label that we'll update.
        consoleOutputLabel = ConsoleSection:CreateLabel({ Text = "Console Initializing..." })
        
        ConsoleSection:CreateButton({
            Name = "Clear Console",
            Callback = function()
                consoleLogLines = {"[Console Cleared]"}
                if consoleOutputLabel then
                    consoleOutputLabel:SetText(table.concat(consoleLogLines, "\n"))
                end
            end
        })

        ConsoleSection:CreateButton({
            Name = "Copy Log to Clipboard",
            Callback = function()
                local fullLog = table.concat(consoleLogLines, "\n")
                local clipboardFunc = _G.setclipboard or (_G.game and _G.game.SetClipboard)
                if clipboardFunc then
                    pcall(clipboardFunc, fullLog)
                    _G.print("[Rayfield Console] Log copied to clipboard.") -- Use hooked print
                else
                    _G.warn("[Rayfield Console] Clipboard function not available.") -- Use hooked warn
                end
            end
        })
    end)
    if not themeSuccess then
        oldPrint("ERROR initializing Rayfield Window/Theme: " .. tostring(themeErr))
        oldPrint("Stack: " .. debug.traceback())
        rayfieldLoaded = false -- Treat as failed if window setup fails
        _G.print = oldPrint
        _G.warn = oldWarn
    end
end

-- === 3. HOOK PRINT AND WARN TO USE RAYFIELD CONSOLE ===
local function updateRayfieldConsole()
    if rayfieldLoaded and consoleOutputLabel and Window and Window.Visible then
        -- Limit the number of lines displayed directly in the label to avoid performance issues
        local displayLines = {}
        local startIndex = math.max(1, #consoleLogLines - MAX_CONSOLE_LOG_LINES + 1)
        for i = startIndex, #consoleLogLines do
            table.insert(displayLines, consoleLogLines[i])
        end
        consoleOutputLabel:SetText(table.concat(displayLines, "\n"))
    end
end

if rayfieldLoaded then
    _G.print = function(...)
        local args = {...}
        local message = table.concat(args, "\t")
        oldPrint(message) -- Keep original print for executor's console

        table.insert(consoleLogLines, "[P] " .. message)
        if #consoleLogLines > (MAX_CONSOLE_LOG_LINES + 20) then -- Keep a bit more in memory than displayed
            table.remove(consoleLogLines, 1)
        end
        updateRayfieldConsole()
    end

    _G.warn = function(...)
        local args = {...}
        local message = table.concat(args, "\t")
        oldWarn(message) -- Keep original warn

        table.insert(consoleLogLines, "<font color='rgb(255,200,0)'>[W] " .. message .. "</font>") -- Rayfield labels support RichText
        if #consoleLogLines > (MAX_CONSOLE_LOG_LINES + 20) then
            table.remove(consoleLogLines, 1)
        end
        updateRayfieldConsole()
    end
    print("Rayfield Console ready. Subsequent prints will appear here.")
else
    print("Rayfield not loaded or failed to init window. Using fallback print.")
end


-- === YOUR CORE SCRIPT LOGIC STARTS HERE ===
print("DEBUG: Main script logic starting now...") -- This should go to Rayfield or fallback

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
    local remotePathString = "ReplicatedStorage.Shared.Framework.Network.Remote.Event"
    
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