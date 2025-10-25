-- Load Rayfield UI
local Rayfield = loadstring(game:HttpGet("https://raw.githubusercontent.com/shlexware/Rayfield/main/source.lua"))()

local Window = Rayfield:CreateWindow({
	Name = "Tower Automation",
	LoadingTitle = "WFS Tower",
	LoadingSubtitle = "by Garou",
	ConfigurationSaving = {
		Enabled = false
	},
	KeySystem = false
})

local Tab = Window:CreateTab("Tower")
local SettingsTab = Window:CreateTab("Settings")

local CurrentFloor = 5
local AutoTower = false

-- Input starting floor
Tab:CreateInput({
	Name = "Starting Floor (divisible by 5)",
	PlaceholderText = "e.g. 25",
	RemoveTextAfterFocusLost = false,
	Callback = function(Value)
		local num = tonumber(Value)
		if num and num % 5 == 0 then
			CurrentFloor = num
		end
	end
})

-- Auto Tower Toggle
Tab:CreateToggle({
	Name = "Auto Tower",
	CurrentValue = false,
	Callback = function(state)
		AutoTower = state
		while AutoTower and task.wait(3) do
			-- Get target
			local target
			if CurrentFloor % 5 == 0 then
				target = workspace.Fight.ClientChests:FindFirstChild("Boss_1") and workspace.Fight.ClientChests.Boss_1:FindFirstChild("Root")
			else
				target = workspace.Fight.ClientChests:FindFirstChild("Boss_2") and workspace.Fight.ClientChests.Boss_2:FindFirstChild("Root")
			end

			-- Teleport to target
			if target then
				game.Players.LocalPlayer.Character.HumanoidRootPart.CFrame = target.CFrame
			end

			-- Auto kill + reward collect
			if target then
				workspace.Fight.Events.FightAttack:InvokeServer(0, target.Name)
				for _, v in pairs(workspace.Rewards:GetChildren()) do
					v.CFrame = game.Players.LocalPlayer.Character.HumanoidRootPart.CFrame
				end
			end

			-- Wait then teleport to next
			task.wait(5)
			for _, arena in pairs(workspace.Fight:GetChildren()) do
				if arena.Name:match("^FightArena_2097%d+") and arena:FindFirstChild("Tele") then
					game.Players.LocalPlayer.Character.HumanoidRootPart.CFrame = arena.Tele.CFrame
					break
				end
			end

			-- Increment floor
			CurrentFloor += 1
		end
	end
})

-- UI Toggle
SettingsTab:CreateKeybind({
	Name = "Toggle UI",
	CurrentKeybind = "RightControl",
	HoldToInteract = false,
	Callback = function()
		Rayfield:Toggle()
	end
})

-- UI Color
SettingsTab:CreateColorPicker({
	Name = "UI Color",
	Callback = function(color)
		Window:SetBackgroundColor(color)
	end
})