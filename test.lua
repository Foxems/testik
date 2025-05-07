--[[
    Robot Claw Collector with Rayfield UI Console (v2 - Official Load URL)
    Using official Rayfield loading URL: https://sirius.menu/rayfield
]]

-- Store original print/warn functions IMMEDIATELY
local _G = getfenv(0)
local oldPrint = _G.print
local oldWarn = _G.warn

oldPrint("DEBUG: Script started. Attempting to load Rayfield UI Library from official source...")

-- === 1. LOAD RAYFIELD UI LIBRARY ===
local Rayfield
local rayfieldLoaded = false
local rayfieldLoadError = ""

-- Official Rayfield loadstring from https://docs.sirius.menu/rayfield/configuration/booting-library
local success, result = pcall(function()
    Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))() -- OFFICIAL URL
end)

if success and Rayfield and Rayfield.CreateWindow then
    oldPrint("DEBUG: Rayfield loaded successfully from official source.")
    rayfieldLoaded = true
else
    rayfieldLoadError = success and "Rayfield loaded but API (CreateWindow) seems missing." or tostring(result)
    oldPrint("ERROR: Failed to load Rayfield UI Library. Error: " .. rayfieldLoadError)
    oldPrint("The script will continue using basic print for output if your executor shows it.")
    oldPrint("A GUI console will NOT be available.")
    -- Revert to old print/warn if Rayfield fails
    _G.print = oldPrint
    _G.warn = oldWarn
end

-- === 2. SETUP RAYFIELD WINDOW AND CONSOLE ELEMENTS (if loaded) ===
local Window, ConsoleTab
local consoleLogLines = {} 
local MAX_CONSOLE_LOG_LINES = 100
local consoleOutputLabel = nil 

if rayfieldLoaded then
    local themeSuccess, themeErr = pcall(function()
        -- Rayfield usually defaults to a dark theme, explicit setting is optional.
        -- Rayfield:SetTheme("Dark") 

        Window = Rayfield:CreateWindow({
            Name = "Robot Claw Collector",
            LoadingTitle = "Collector Initializing",
            LoadingSubtitle = "by YourName & AI",
            ConfigurationSaving = { Enabled = false }, -- No settings to save
            KeySystem = false -- No key system
        })
        oldPrint("DEBUG: Rayfield Window created.")

        ConsoleTab = Window:CreateTab({ Name = "Console Output" })
        oldPrint("DEBUG: Rayfield ConsoleTab created.")

        local ConsoleSection = ConsoleTab:CreateSection({ Name = "Log Output" }) -- Changed section name for clarity
        oldPrint("DEBUG: Rayfield ConsoleSection created.")

        consoleOutputLabel = ConsoleSection:CreateLabel({ Text = "Console Initializing..." }) -- Will be updated
        oldPrint("DEBUG: Rayfield consoleOutputLabel created.")
        
        ConsoleSection:CreateButton({
            Name = "Clear Console",
            Callback = function()
                consoleLogLines = {"[Console Cleared by User]"}
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
                    local copySuccess, copyErr = pcall(clipboardFunc, fullLog)
                    if copySuccess then
                         _G.print("[Rayfield Console] Log copied to clipboard.")
                    else
                        _G.warn("[Rayfield Console] Error copying to clipboard: " .. tostring(copyErr))
                    end
                else
                    _G.warn("[Rayfield Console] Clipboard function not available.")
                end
            end
        })
        oldPrint("DEBUG: Rayfield console buttons created.")

    end)
    if not themeSuccess then
        oldPrint("ERROR initializing Rayfield Window/Theme: " .. tostring(themeErr))
        oldPrint("Stack: " .. debug.traceback())
        rayfieldLoaded = false 
        _G.print = oldPrint
        _G.warn = oldWarn
    else
        oldPrint("DEBUG: Rayfield UI setup appears successful.")
    end
end

-- === 3. HOOK PRINT AND WARN TO USE RAYFIELD CONSOLE ===
local function updateRayfieldConsole()
    if rayfieldLoaded and consoleOutputLabel and Window and Window.Visible then
        local displayLines = {}
        local startIndex = math.max(1, #consoleLogLines - MAX_CONSOLE_LOG_LINES + 1)
        for i = startIndex, #consoleLogLines do
            table.insert(displayLines, consoleLogLines[i])
        end
        -- Use pcall for SetText as it can error if the label is destroyed or invalid
        local setSuccess, setErr = pcall(function()
            consoleOutputLabel:SetText(table.concat(displayLines, "\n"))
        end)
        if not setSuccess then
            oldPrint("ERROR updating Rayfield label: " .. tostring(setErr))
        end
    end
end

if rayfieldLoaded then
    _G.print = function(...)
        local args = {...}
        local message = table.concat(args, "\t")
        oldPrint(message) 

        table.insert(consoleLogLines, "[P] " .. message)
        if #consoleLogLines > (MAX_CONSOLE_LOG_LINES + 20) then 
            table.remove(consoleLogLines, 1)
        end
        updateRayfieldConsole()
    end

    _G.warn = function(...)
        local args = {...}
        local message = table.concat(args, "\t")
        oldWarn(message) 

        table.insert(consoleLogLines, "<font color='rgb(255,200,0)'>[W] " .. message:gsub("<","<"):gsub(">",">") .. "</font>")
        if #consoleLogLines > (MAX_CONSOLE_LOG_LINES + 20) then
            table.remove(consoleLogLines, 1)
        end
        updateRayfieldConsole()
    end
    print("Rayfield Console (v2) ready. Subsequent prints/warns will appear here.") -- This will use the new print
else
    print("Rayfield not loaded or failed to init window. Using fallback print for all output.") -- This uses oldPrint if Rayfield failed
end


-- === YOUR CORE SCRIPT LOGIC STARTS HERE ===
print("DEBUG: Main script logic starting now...") 

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

function StartRobotClawInsane(remoteEventInstance)
    if not remoteEventInstance or not remoteEventInstance:IsA("RemoteEvent") then
        warn("[StartRobotClawInsane] RemoteEvent for starting minigame not provided or not a RemoteEvent!")
        return
    end
    local args = { "StartMinigame", "Robot Claw", "Insane" }
    print("[StartRobotClawInsane] Starting minigame Robot Claw (Insane)... Args:", table.concat(args, ", "))
    local fireSuccess, fireErr = pcall(function() remoteEventInstance:FireServer(unpack(args)) end)
    if fireSuccess then
        print("[StartRobotClawInsane] FireServer called for StartMinigame.")
    else
        warn("[StartRobotClawInsane] Error calling FireServer for StartMinigame: " .. tostring(fireErr))
    end
end

function GrabItem(itemId, remoteEventInstance)
    if not remoteEventInstance or not remoteEventInstance:IsA("RemoteEvent") then
        warn("[GrabItem] RemoteEvent for grabbing item not provided or not a RemoteEvent!")
        return
    end
    local args = { "GrabMinigameItem", itemId }
    pcall(function() remoteEventInstance:FireServer(unpack(args)) end) -- Fire and forget, error handled by game if critical
end

function FindAllItemIDs()
    local itemIDs = {}
    print("[FindAllItemIDs] Starting function.")
    local renderedFolder = Workspace:FindFirstChild("Rendered")
    if not renderedFolder then
        print("[FindAllItemIDs] Folder 'Workspace.Rendered' NOT FOUND.")
        return itemIDs 
    else
        print("[FindAllItemIDs] Folder 'Workspace.Rendered' found: " .. renderedFolder:GetFullName())
    end

    local chunkerFolder = renderedFolder:FindFirstChild("Chunker")
    if not chunkerFolder then
        print("[FindAllItemIDs] Folder 'Workspace.Rendered.Chunker' NOT FOUND.")
        return itemIDs
    else
        print("[FindAllItemIDs] Folder 'Workspace.Rendered.Chunker' found: " .. chunkerFolder:GetFullName())
    end

    local children = chunkerFolder:GetChildren()
    print("[FindAllItemIDs] Number of direct children in Chunker folder: " .. #children)
    if #children == 0 then print("[FindAllItemIDs] Chunker folder is empty.") end

    for i, itemInstance in ipairs(children) do
        print("[FindAllItemIDs] Processing child #" .. i .. " | Name: '" .. itemInstance.Name .. "' | ClassName: '" .. itemInstance.ClassName .. "'")
        if string.len(itemInstance.Name) == 36 and string.find(itemInstance.Name, "-", 1, true) then 
            print("[FindAllItemIDs] ---> Found potential item ID (by name):", itemInstance.Name)
            table.insert(itemIDs, itemInstance.Name)
        else
            -- print("[FindAllItemIDs] ---> Name '" .. itemInstance.Name .. "' does not match ID format (length 36 and hyphen), ignoring.")
        end
    end

    if #itemIDs == 0 then warn("[FindAllItemIDs] After processing all children, no item IDs matching criteria were found.") end
    print("[FindAllItemIDs] Found total ".. #itemIDs .." item IDs to collect.")
    return itemIDs
end

function Main()
    print("[Main] Main function started.")
    print("[Main] Verifying RemoteEvent...")
    local remote = nil
    local remotePathString = "ReplicatedStorage.Shared.Framework.Network.Remote.Event"
    
    local findRemoteSuccess, remoteEventInstanceOrError = pcall(function()
        return ReplicatedStorage:WaitForChild("Shared", 30):WaitForChild("Framework", 15):WaitForChild("Network", 15):WaitForChild("Remote", 15):WaitForChild("Event", 15)
    end)

    if not findRemoteSuccess then
         warn("[Main] CRITICAL ERROR finding RemoteEvent (pcall failed): ", tostring(remoteEventInstanceOrError))
         warn("[Main] Path: ", remotePathString)
         print("[Main] Script cannot run without RemoteEvent.")
         return
    end
    if not remoteEventInstanceOrError or not remoteEventInstanceOrError:IsA("RemoteEvent") then
         warn("[Main] CRITICAL ERROR: RemoteEvent at path '"..remotePathString.."' NOT found (WaitForChild timeout or not a RemoteEvent)! Script cannot continue.")
         print("[Main] Value returned from WaitForChild chain: ", tostring(remoteEventInstanceOrError))
         return
    end

    remote = remoteEventInstanceOrError
    print("[Main] RemoteEvent successfully found: " .. remote:GetFullName())

    StartRobotClawInsane(remote)

    print("[Main] Waiting for items to appear in Chunker (max 30 seconds)...")
    local startTime = tick()
    local chunkerFolder = nil
    local renderedFolder = Workspace:FindFirstChild("Rendered") 

    if renderedFolder then
        print("[Main_WaitLoop] 'Rendered' folder found immediately.")
        chunkerFolder = renderedFolder:FindFirstChild("Chunker")
        if chunkerFolder then print("[Main_WaitLoop] 'Chunker' folder found immediately.") end
    end
    
    local iteration = 0
    while not (chunkerFolder and #chunkerFolder:GetChildren() > 0) and (tick() - startTime < 30) do
        iteration = iteration + 1
        wait(0.5)
        if not renderedFolder then 
            renderedFolder = Workspace:FindFirstChild("Rendered")
            if renderedFolder then print("[Main_WaitLoop] 'Rendered' folder found in iteration " .. iteration) end
        end
        if renderedFolder and not chunkerFolder then 
            chunkerFolder = renderedFolder:FindFirstChild("Chunker") 
            if chunkerFolder then print("[Main_WaitLoop] 'Chunker' folder found in iteration " .. iteration) end
        end
    end

    if not (chunkerFolder and #chunkerFolder:GetChildren() > 0) then
        warn("[Main] Timeout or Chunker folder still empty/non-existent after " .. string.format("%.1f", tick() - startTime) .. " seconds. Collection will not start.")
        if not renderedFolder then print("[Main_Debug] Folder 'Workspace.Rendered' was not found even after waiting.") end
        if renderedFolder and not chunkerFolder then print("[Main_Debug] Folder 'Workspace.Rendered.Chunker' was not found even after waiting.") end
        if chunkerFolder and #chunkerFolder:GetChildren() == 0 then print("[Main_Debug] Folder 'Workspace.Rendered.Chunker' was found, but is empty.") end
        return
    end
    print("[Main] Items detected in Chunker (after " .. string.format("%.1f", tick() - startTime) .. "s). Child count: " .. #chunkerFolder:GetChildren() .. ". Proceeding with collection.")
    
    print("[Main] Short additional pause (1s) for any other items to generate...")
    wait(1)

    local itemIDsToCollect = FindAllItemIDs()

    if #itemIDsToCollect > 0 then
        print("[Main] Starting to collect " .. #itemIDsToCollect .. " items...")
        for i, itemID in ipairs(itemIDsToCollect) do
            print("[Main] ===> ATTEMPTING TO COLLECT item " .. i .. "/" .. #itemIDsToCollect .. " with ID: " .. itemID .. " <===")
            GrabItem(itemID, remote) 
            wait(0.1)
        end
        print("[Main] All " .. #itemIDsToCollect .. " found items have been processed (collection attempt sent).")
    else
        print("[Main] No items to collect based on criteria in FindAllItemIDs. Check debug output from that function.")
    end
    print("[Main] Script operations completed.")
end

-- === Spuštění skriptu ===
print("DEBUG: Preparing to run Main() via task.spawn().")
task.spawn(Main)
print("DEBUG: task.spawn(Main) called. Main logic should run asynchronously.")