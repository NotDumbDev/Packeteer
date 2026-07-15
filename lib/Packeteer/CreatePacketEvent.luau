local PacketEvent = {}
local Packet = {} :: PacketTypes.PrivateEventPacket<any>
Packet.__index = Packet

local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local PacketTypes = require("@self/../Types/PacketTypes")
local FolderUtil = require("@self/../Util/FolderUtil")
local NetworkError = require("@self/../NetworkError")

function Packet:_referenceEventExists(action: string, ifExists: () -> ()): () -> ()
	const self = self :: PacketTypes.PrivateEventPacket<any>
	if (self._referenceEvent) then
		return ifExists()
	else
		const packetEvents = ReplicatedStorage:WaitForChild("PacketEvents") :: Folder?
		const packetEvent = packetEvents:WaitForChild(self._name) :: RemoteEvent?
		self._referenceEvent = packetEvent

		if (self._referenceEvent) then
			return ifExists()
		else
			warn(NetworkError.new({ 
				kind = "Internal",
				context = "PacketEvent",
				message = `Couldn't {action} packet event because the PacketEvent didn't intialize properly (No reference event!)`,
			}))
		end
	end
end

function PacketEvent.new<T>(): PacketTypes.PublicEventPacket<T>
	local self = setmetatable({}, Packet :: PacketTypes.PrivateEventPacket<T>)
	
	--self.createPacketEvent(self)
	return self :: PacketTypes.PrivateEventPacket<T>
end

function Packet:Fire(recipient: (Player | {Player}) | nil, args: any?)
	const varArgs = args and {args} or {}
	const self = self :: PacketTypes.PrivateEventPacket<any>
	if (self._schemaType == "Server") then
		if (RunService:IsServer()) then
			self:_referenceEventExists("fire", function()
				if (recipient) then
					if (typeof(recipient) == "table") then
						for _, player in ipairs(recipient) do
							if (typeof(player) == "Instance") then
								self._referenceEvent:FireClient(player, table.unpack(varArgs))
							else
								warn(NetworkError.new({ 
									kind = "InvalidArguments",
									context = "Packet:Fire",
									message = `Invalid 'recipient' argument: expected a table of Player instances, received '{typeof(player)}' for key '{table.find(recipient, player)}'`,
								}))
							end
						end
					else
						self._referenceEvent:FireClient(recipient, table.unpack(varArgs))
					end
				else
					warn(NetworkError.new({ 
						kind = "InvalidArguments",
						context = "Packet:Fire",
						message = `Invalid 'recipient' argument: expected a Player instance or a table of Player instances, received '{typeof(recipient)}'`,
					}))
				end
			end)
		else
			warn(NetworkError.new({ 
				kind = "Environment",
				context = "Packet:Fire",
				message = "Attempted to fire a PacketEvent (Server -> Client) from the client.",
				suggestions = {
					"Server -> Client packets can only be fired from the server.",
					"Move this call into a server-side script."
				}
			}))


		end
	else
		self:_referenceEventExists("fire", function()
			if (RunService:IsClient()) then
				self._referenceEvent:FireServer(table.unpack(varArgs))
			else
				warn(NetworkError.new({ 
					kind = "Environment",
					context = "Packet:Fire",
					message = "Attempted to fire a PacketEvent (Client -> Server) from the server.",
					suggestions = {
						"Client -> Server packets can only be fired from the client.",
						"Move this call into a client-side script."
					}
				}))
			end

		end)
	end
end

function Packet:Connect(callback: (player: Player, args: any?) -> ()): RBXScriptConnection?
	const self = self :: PacketTypes.PrivateEventPacket<any>
	
	return self:_referenceEventExists("connect", function()
		if (self._schemaType == "Client") then
			if (RunService:IsServer()) then
				return self._referenceEvent.OnServerEvent:Connect(callback)
			else
				warn(NetworkError.new({ 
					kind = "Environment",
					context = "Packet:Connect",
					message = "Attempted to connect a PacketEvent (Server -> Client) from the client.",
					suggestions = {
						"Server -> Client packets can only be connected from the server.",
						"Move this call into a server-side script."
					}
				}))
			end
		else
			if (RunService:IsClient()) then
				return self._referenceEvent.OnClientEvent:Connect(callback)
			else
				warn(NetworkError.new({ 
					kind = "Environment",
					context = "Packet:Connect",
					message = "Attempted to connect a PacketEvent (Client -> Server) from the server.",
					suggestions = {
						"Client -> Server packets can only be connected from the client.",
						"Move this call into a client-side script."
					}
				}))
			end
		end
	end)
end

function Packet:createPacketEvent() 
	if (RunService:IsServer()) then
		const parent = FolderUtil.folderExists("PacketEvents")
		
		if (parent) then
			self._referenceEvent = Instance.new("RemoteEvent")
			self._referenceEvent.Name = self._name
			self._referenceEvent.Parent = parent
		else
			warn(NetworkError.new({ 
				kind = "Internal", 
				context = "createPacketEvent", 
				message = "Couldn't create packet event because 'PacketEvents' folder does not exist.", 
			}):__tostring())
			return
		end
	end
end

return PacketEvent
