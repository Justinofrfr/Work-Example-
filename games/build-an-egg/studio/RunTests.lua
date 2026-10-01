local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local StarterPlayer = game:GetService("StarterPlayer")
local StudioTestService = game:GetService("StudioTestService")

local BASE = "http://127.0.0.1:34877/studio/"

local function fetch(name)
	return HttpService:GetAsync(BASE .. name .. ".lua?t=" .. tostring(os.clock()), true)
end

local remote = Instance.new("RemoteEvent")
remote.Name = "__TestLog"
remote.Parent = ReplicatedStorage

local server = Instance.new("Script")
server.Name = "__TestServer"
server.Source = fetch("TestServer")
server.Parent = ServerScriptService

local client = Instance.new("LocalScript")
client.Name = "__TestClient"
client.Source = fetch("TestClient")
client.Parent = StarterPlayer.StarterPlayerScripts

local ok, result = pcall(function()
	return StudioTestService:ExecutePlayModeAsync({})
end)

remote:Destroy()
server:Destroy()
client:Destroy()

print(ok and tostring(result) or ("RUN FAILED: " .. tostring(result)))
