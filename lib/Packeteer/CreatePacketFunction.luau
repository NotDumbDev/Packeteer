local PacketFunction = {}
local Packet = {} :: PacketTypes.PrivateFunctionPacket<any, any>
Packet.__index = Packet

local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local PacketTypes = require("@self/../Types/PacketTypes")
local FolderUtil = require("@self/../Util/FolderUtil")
local NetworkError = require("@self/../NetworkError")
local Promise = require("@self/../Include/Promise")

function Packet:_referenceEventExists(action: string, ifExists: () -> ()): () -> ()
	const self = self :: PacketTypes.PrivateFunctionPacket<any, any>
	--print(self)

	assert(self._name, "PacketFunction has no name. Did you forget to register it in Packeteer.create()?")
	if (self._referenceEvent) then
		return ifExists()
	else
		const packetEvents = ReplicatedStorage:WaitForChild("PacketFunctionEvents") :: Folder?
		const packetEvent = packetEvents:WaitForChild(self._name) :: RemoteEvent?
		self._referenceEvent = packetEvent
		
		if (self._referenceEvent) then
			return ifExists()
		else
			warn(NetworkError.new({ 
				kind = "Internal",
				context = "PacketFunction",
				message = `Couldn't {action} packet event because the PacketFunctionEvent didn't intialize properly (No reference event!)`,
			}))
		end
	end
end

function PacketFunction.new<T, R>(): PacketTypes.PrivateFunctionPacket<T, R>
	local self = setmetatable({}, Packet :: PacketTypes.PrivateFunctionPacket<T, R>)
	self._callback = nil
	self._pendingRequests = {}
	
	--print(self)
	
	return self :: PacketTypes.PrivateFunctionPacket<T, R>
end

function Packet:Invoke(recipient: Player | nil, args: any?): Promise.Promise | nil
	const self = self :: PacketTypes.PrivateFunctionPacket<any, any>
	const id = HttpService:GenerateGUID(false)
	
	const promise = Promise.new(function(resolve, reject, onCancel)
		self:_referenceEventExists("invoke", function()
			-- clean up
			onCancel(function()
				if (self._pendingRequests[id]) then
					self._pendingRequests[id] = nil
				end
			end)
			
			if (self._schemaType == "Server" and RunService:IsServer()) then
				if (not recipient or typeof(recipient) ~= "Instance") then
					return reject(NetworkError.new({
						kind = "InvalidArguments",
						context = "PacketFunction:Invoke",
						message = `Invalid 'recipient' argument: expected player instance, received '{typeof(recipient)}'`,
					}))
				end
			end
			
			if (self._pendingRequests[id] == nil) then
				self._pendingRequests[id] = {
					reject = reject,
					resolve = resolve
				}
				
				if (self._schemaType == "Server") then
					if (RunService:IsServer()) then
						self._referenceEvent:FireClient(recipient, id, args, "Request")
					end
				else
					if (RunService:IsClient()) then
						self._referenceEvent:FireServer(id, args, "Request")
					end
				end
			else
				reject(NetworkError.new({
					kind = "Internal",
					context = "Packet:Invoke",
					message = string.format("Couldn't invoke packet function because the request id '%s' already exists...", id),
				}))
			end	
		end)
	end)
	
	return promise
end

function Packet:SetCallback(callback: (player: Player | nil, ...any?) -> any?)
	const self = self :: PacketTypes.PrivateFunctionPacket<any, any>
	
	self._callback = callback
	return self
end

function Packet:createConnections()
	const self = self :: PacketTypes.PrivateFunctionPacket<any, any>
	
	if (RunService:IsServer()) then
		self._referenceEvent.OnServerEvent:Connect(function(sender: Player, id: string, data: any?, packetType: "Request" | "Response" | "Error")
			if (packetType == "Request") then
				if not self._callback then
					warn(NetworkError.new({
						kind = "Internal",
						context = "PacketFunction",
						message = "Received invoke request but no callback has been assigned.",
						suggestions = {
							"Make sure to set a callback using ':SetCallback()'."
						}
					}))
					return
				end

				const success, result = xpcall(self._callback, debug.traceback, sender, data)

				if (success) then
					self._referenceEvent:FireClient(sender, id, result, "Response")
				else
					self._referenceEvent:FireClient(sender, id, result, "Error")
				end
			elseif (packetType == "Response") then
				const request = self._pendingRequests[id]

				if (request) then
					request.resolve(data)
					self._pendingRequests[id] = nil
				end
			elseif (packetType == "Error") then
				const request = self._pendingRequests[id]

				if (request) then
					request.reject(data)
					self._pendingRequests[id] = nil
				end
			end
		end)
	else
		self._referenceEvent.OnClientEvent:Connect(function(id: string, data: any?, packetType: "Request" | "Response" | "Error")
			if (packetType == "Request") then
				if not self._callback then
					warn(NetworkError.new({
						kind = "Internal",
						context = "PacketFunction",
						message = "Received invoke request but no callback has been assigned.",
						suggestions = {
							"Make sure to set a callback using ':SetCallback()'."
						}
					}))
					return
				end

				const success, result = xpcall(self._callback, debug.traceback, data)

				if (success) then
					self._referenceEvent:FireServer(id, result, "Response")
				else
					self._referenceEvent:FireServer(id, result, "Error")
				end

			elseif (packetType == "Response") then
				const request = self._pendingRequests[id]

				if (request) then
					request.resolve(data)
					self._pendingRequests[id] = nil
				end
			elseif (packetType == "Error") then
				const request = self._pendingRequests[id]

				if (request) then
					request.reject(data)
					self._pendingRequests[id] = nil
				end
			end
		end)
	end
end

function Packet:createPacketEvent() 
	const self = self :: PacketTypes.PrivateFunctionPacket<any, any>
	if (RunService:IsServer()) then
		const parent = FolderUtil.folderExists("PacketFunctionEvents")

		if (parent) then
			self._referenceEvent = Instance.new("RemoteEvent")
			self._referenceEvent.Name = self._name
			self._referenceEvent.Parent = parent
		else
			warn(NetworkError.new({ 
				kind = "Internal", 
				context = "createPacketEvent", 
				message = "Couldn't create packet function because 'PacketFunctionEvents' folder does not exist.", 
			}):__tostring())
			return
		end
	else
		local packetEvents = ReplicatedStorage:WaitForChild("PacketFunctionEvents")
		self._referenceEvent = packetEvents:WaitForChild(self._name)
	end
end

return PacketFunction
