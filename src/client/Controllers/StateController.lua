--!strict
-- Holds the latest server snapshot and tells listeners when it changes. Display only.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Remotes = require(ReplicatedStorage.Shared.Remotes)
local Signal = require(ReplicatedStorage.Shared.Signal)
local Types = require(ReplicatedStorage.Shared.Types)

local StateController = {}

StateController.snapshot = nil :: Types.Snapshot?
StateController.Changed = Signal.new() -- (snapshot)

function StateController.Init() end

function StateController.Start()
	Remotes.get("State").OnClientEvent:Connect(function(snap: Types.Snapshot)
		StateController.snapshot = snap
		StateController.Changed:Fire(snap)
	end)
end

return StateController
