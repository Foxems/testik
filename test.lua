--[[
    Robot Claw Collector with Venyx UI Console
    Attempting to use Venyx UI Library.
]]

-- Store original print/warn functions IMMEDIATELY
local _G = getfenv(0)
local oldPrint = _G.print
local oldWarn = _G.warn

oldPrint("DEBUG: Script started. Attempting to load Venyx UI Library...")

-- === 1. LOAD VENYX UI LIBRARY ===
local Venyx
local venyxLoaded = false
local venyxLoadError = ""

-- Common Venyx loadstring
local success, result = pcall(function()
    Venyx = loadstring(game:HttpGet("https://raw.githubusercontent.com/Stefanuk12/Venyx-UI-Library/main/source.lua"))()
end)

if success and Venyx and Venyx.Window then
    oldPrint("DEBUG: Venyx loaded successfully.")
    venyxLoaded = true
else
    venyxLoadError = success and "Venyx loaded but API (Venyx.Window) seems missing." or tostring(result)
    oldPrint("ERROR: Failed to load Venyx UI Library. Error: " .. venyxLoadError)
    oldPrint("Stack trace: " .. debug.traceback())
    oldPrint("The script will continue using basic print for output if your executor shows it.")
    oldPrint("A GUI console will NOT be available.")
    _G.print = oldPrint
    _G.warn = oldWarn
end

-- === 2. SETUP VENYX WINDOW AND CONSOLE ELEMENTS (if loaded) ===
local MainWindow, ConsoleTab
local consoleLogLinesVenyx = {}
local MAX_CONSOLE_LOG_LINES_VENYX = 100
local consoleOutputLabelVenyx = nil -- This will be our "text area" in Venyx

if venyxLoaded then
    local venyxSetupSuccess, venyxSetupErr = pcall(function()
        MainWindow = Venyx.Window({
            Title = "Robot Claw Collector (Venyx)",
            Color = Color3.fromRGB(30, 30, 30), -- Main window color
            Draggable = true,
            ShowMinimize = true,
            ShowClose = true, -- Venyx handles its own close button
            Size = UDim2.new(0, 500, 0, 350)
        })
        oldPrint("DEBUG: Venyx Window created.")

        ConsoleTab = MainWindow:Tab({ Name = "Console Output" })
        oldPrint("DEBUG: Venyx ConsoleTab created.")

        -- Venyx doesn't have a multi-line text box for logs. We'll use a label and update it.
        -- It's better to create individual labels for each line for better performance with Venyx if many lines.
        -- However, for simplicity and to match the previous approach, we'll try a single updating label first.
        -- If performance is an issue, this part would need to be refactored to create many small labels.
        
        ConsoleTab:Label({Text = "Log Output:", Font = {Size = 16}}) -- Section title
        consoleOutputLabelVenyx = ConsoleTab:Label({ Text = "Console Initializing...", Font = {Size = 12} })
        oldPrint("DEBUG: Venyx consoleOutputLabel created.")

        ConsoleTab:Button({
            Text = "Clear Console",
            Callback = function()
                consoleLogLinesVenyx = {"[Console Cleared by User]"}
                if consoleOutputLabelVenyx then
                    consoleOutputLabelVenyx:SetText(table.concat(consoleLogLinesVenyx, "\n"))
                end
            end,
            Color = Color3.fromRGB(50,50,50)
        })

        ConsoleTab:Button({
            Text = "Copy Log to Clipboard",
            Callback = function()
                local fullLog = table.concat(consoleLogLinesVenyx, "\n")
                local clipboardFunc = _G.setclipboard or (_G.game and _G.game.SetClipboard)
                if clipboardFunc then
                    local copySuccessCb, copyErrCb = pcall(clipboardFunc, fullLog)
                    if copySuccessCb then
                         _G.print("[Venyx Console] Log copied to clipboard.")
                    else
                        _G.warn("[Venyx Console] Error copying to clipboard: " .. tostring(copyErrCb))
                    end
                else
                    _G.warn("[Venyx Console] Clipboard function not available.")
                end
            end,
            Color = Color3.fromRGB(50,50,50)
        })
        oldPrint("DEBUG: Venyx console buttons created.")

    end)

    if not venyxSetupSuccess then
        oldPrint("ERROR initializing Venyx Window/Elements: " .. tostring(venyxSetupErr))
        oldPrint("Stack: " .. debug.traceback())
        venyxLoaded = false
        _G.print = oldPrint
        _G.warn = oldWarn
    else
        oldPrint("DEBUG: Venyx UI setup appears successful.")
    end
end

-- === 3. HOOK PRINT AND WARN TO USE VENYX CONSOLE ===
local function updateVenyxConsole()
    if venyxLoaded and consoleOutputLabelVenyx and MainWindow and MainWindow.Enabled then -- Check if window is enabled/visible
        local displayLines = {}
        local startIndex = math.max(1, #consoleLogLinesVenyx - MAX_CONSOLE_LOG_LINES_VENYX + 1)
        for i = startIndex, #consoleLogLinesVenyx do
            table.insert(displayLines, consoleLogLinesVenyx[i])
        end
        
        local setSuccess, setErr = pcall(function()
            consoleOutputLabelVenyx:SetText(table.concat(displayLines, "\n"))
        end)
        if not setSuccess then
            oldPrint("ERROR updating Venyx label: " .. tostring(setErr))
        end
    end
end

if venyxLoaded then
    _G.print = function(...)
        local args = {...}
        local message = table.concat(args, "\t")
        oldPrint(message)

        table.insert(consoleLogLinesVenyx, "[P] " .. message)
        if #consoleLogLinesVenyx > (MAX_CONSOLE_LOG_LINES_VENYX + 20) then
            table.remove(consoleLogLinesVenyx, 1)
        end
        updateVenyxConsole()
    end

    _G.warn = function(...)
        local args = {...}
        local message = table.concat(args, "\t")
        oldWarn(message)

        -- Venyx labels might not directly support RichText like Rayfield, so we'll just prefix.
        -- For colored text, Venyx might require specific HTML-like tags if supported, or separate colored labels.
        table.insert(consoleLogLinesVenyx, "[W] " .. message)
        if #consoleLogLinesVenyx > (MAX_CONSOLE_LOG_LINES_VENYX + 20) then
            table.remove(consoleLogLinesVenyx, 1)
        end
        updateVenyxConsole()
    end
    print("Venyx Console ready. Subsequent prints/warns will appear here.")
else
    print("Venyx not loaded or failed to init window. Using fallback print for all output.")
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
    pcall(function() remoteEventInstance:FireServer(unpack(args)) end)
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