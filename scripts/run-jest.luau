local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Packages = ReplicatedStorage:WaitForChild("Packages")
local Tests = ReplicatedStorage:WaitForChild("Tests")
local Jest = require(Packages:WaitForChild("Jest"))

local status, result = Jest.runCLI(Tests, {
	ci = true,
	verbose = true,
}, { Tests }):awaitStatus()

if status == "Rejected" then
	error(tostring(result))
end

if not result.results.success then
	error("Jest tests failed")
end

print(string.format("CAR_WASH_RUSH_TESTS_PASSED: %d tests", result.results.numPassedTests))
