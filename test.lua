local Players = game:GetService("Players")
local player = Players.LocalPlayer
local remote = game:GetService("ReplicatedStorage"):WaitForChild("RemoteEvent") 
-- [[Pozn.: Nahraďte cestu k RemoteEvent ve vaší hře.]]

-- 1) Spuštění minihry Robot Claw (Insane)
remote:FireServer("StartMinigame", "Robot Claw", "Insane")

-- 2) Příprava GUI
local playerGui = player:WaitForChild("PlayerGui")
local screenGui = Instance.new("ScreenGui", playerGui)
screenGui.Name = "ClawFarmGUI"

local mainFrame = Instance.new("Frame", screenGui)
mainFrame.Size = UDim2.new(0.3, 0, 0.5, 0)
mainFrame.Position = UDim2.new(0, 10, 0, 10)
mainFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
mainFrame.BorderSizePixel = 0

local toggleBtn = Instance.new("TextButton", mainFrame)
toggleBtn.Size = UDim2.new(0, 80, 0, 30)
toggleBtn.Position = UDim2.new(0, 10, 0, 10)
toggleBtn.Text = "SBĚR ON"
toggleBtn.TextColor3 = Color3.new(1,1,1)
toggleBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
toggleBtn.BorderSizePixel = 0
toggleBtn.TextScaled = true  -- automatické škálování textu:contentReference[oaicite:11]{index=11}

local closeBtn = Instance.new("TextButton", mainFrame)
closeBtn.Size = UDim2.new(0, 30, 0, 30)
closeBtn.Position = UDim2.new(1, -40, 0, 10)
closeBtn.Text = "X"
closeBtn.TextColor3 = Color3.new(1,1,1)
closeBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
closeBtn.BorderSizePixel = 0
closeBtn.TextScaled = true

local scroll = Instance.new("ScrollingFrame", mainFrame)
scroll.Position = UDim2.new(0, 0, 0, 50)
scroll.Size = UDim2.new(1, 0, 1, -50)
scroll.BackgroundTransparency = 0.2
scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y  -- automatické zvětšení podle obsahu:contentReference[oaicite:12]{index=12}

local listLayout = Instance.new("UIListLayout", scroll)
listLayout.SortOrder = Enum.SortOrder.LayoutOrder
listLayout.VerticalAlignment = Enum.VerticalAlignment.Top
listLayout.Padding = UDim.new(0, 4)

-- 3) Proměnné pro sběr a frontu
local queue = {}
local grabbing = true

-- 4) Funkce pro výpis do logu
function logMessage(msg, color)
    local label = Instance.new("TextLabel", scroll)
    label.Text = msg
    label.Size = UDim2.new(1, 0, 0, 20)
    label.BackgroundTransparency = 1
    label.TextColor3 = color or Color3.new(1,1,1)
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.TextYAlignment = Enum.TextYAlignment.Center
    label.Font = Enum.Font.SourceSans
    label.TextSize = 14
    label.TextWrapped = true
    label.LayoutOrder = #scroll:GetChildren() + 1
    scroll.CanvasPosition = Vector2.new(0, scroll.AbsoluteCanvasSize.Y)
end

-- 5) Obsluha nalezení nových ClawItem obrazů
local function onClawItemAdded(obj)
    if obj:IsA("ImageLabel") and obj.Name:match("^ClawItem") then
        local id = obj.Name:sub(9)  -- z názvu odstraní "ClawItem"
        if grabbing then
            table.insert(queue, id)
        end
        logMessage("[OK] Item " .. id .. " přidán do fronty", Color3.new(0,1,0))
    end
end

for _, gui in ipairs(playerGui:GetChildren()) do
    if gui:IsA("ScreenGui") then
        gui.DescendantAdded:Connect(onClawItemAdded)
    end
end
playerGui.ChildAdded:Connect(function(gui)
    if gui:IsA("ScreenGui") then
        gui.DescendantAdded:Connect(onClawItemAdded)
    end
end)

-- 6) Smyčka pro zpracování fronty
task.spawn(function()
    while true do
        if grabbing and #queue > 0 then
            local itemId = table.remove(queue, 1)
            remote:FireServer("GrabMinigameItem", itemId)
            logMessage("[OK] Item " .. itemId .. " sesbírán", Color3.new(0,1,0))
            task.wait(0.1)
        else
            task.wait(0.1)
        end
    end
end)

-- 7) Ovládací tlačítka
toggleBtn.Activated:Connect(function()
    grabbing = not grabbing
    toggleBtn.Text = grabbing and "SBĚR ON" or "SBĚR OFF"
    logMessage("[INFO] Sběr " .. (grabbing and "zapnut" or "vypnut"), Color3.fromRGB(1,1,0))
end)

closeBtn.Activated:Connect(function()
    screenGui:Destroy()
end)
