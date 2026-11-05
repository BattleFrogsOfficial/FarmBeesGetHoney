--!strict
-- The processor turns queued honey into money at its level's rate.

local Economy = require(script.Parent.Economy)
local Types = require(script.Parent.Types)

local Processor = {}

-- Processes up to dt seconds of honey. Returns honey processed and money made (already added).
function Processor.step(data: Types.Profile, dt: number, moneyPerHoney: number): (number, number)
	local honey = math.min(data.queuedHoney, Economy.processorRate(data.processorLevel) * dt)
	if honey <= 0 then
		return 0, 0
	end
	data.queuedHoney -= honey
	local money = honey * moneyPerHoney
	data.money += money
	data.stats.lifetimeMoney += money
	return honey, money
end

function Processor.upgradeCost(data: Types.Profile): number
	return Economy.upgradeCost(data.processorLevel)
end

function Processor.upgrade(data: Types.Profile): boolean
	local cost = Processor.upgradeCost(data)
	if data.money < cost then
		return false
	end
	data.money -= cost
	data.processorLevel += 1
	return true
end

-- Hand in carried honey at the beekeeper.
function Processor.handIn(data: Types.Profile): number
	local honey = data.carriedHoney
	data.queuedHoney += honey
	data.carriedHoney = 0
	return honey
end

return Processor
