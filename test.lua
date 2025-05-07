local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local remote = ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Framework"):WaitForChild("Network"):WaitForChild("Remote"):WaitForChild("Event")
local screenGui = player:WaitForChild("PlayerGui"):WaitForChild("ScreenGui")

-- 🟢 1) Spusť minihru - Robot Claw - Insane mode
remote:FireServer("StartMinigame", "Robot Claw", "Insane")
print("🎮 Minihra spuštěna: Robot Claw (Insane)")

-- 🟡 2) Automatický sběrač ClawItemů
screenGui.ChildAdded:Connect(function(child)
	if child:IsA("ImageLabel") and child.Name:match("^ClawItem") then
		wait(0.1)
		local id = child.Name:gsub("^ClawItem", "")
		if id and #id > 10 then
			remote:FireServer("GrabMinigameItem", id)
			print("✅ Posbíráno ID: " .. id)
		end
	end
end)
