local command = "start calc"
local success, error = os.execute(command)

if success then
    print("Successfully attempted to open Calculator.")
else
    warn("Failed to execute command. os.execute() might be disabled by your executor.")
    warn("Error: " .. tostring(error))
end
