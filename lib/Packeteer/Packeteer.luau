local RunService = game:GetService("RunService")

local Packeteer = {}

local PacketeerInstance = {}
PacketeerInstance.__index = PacketeerInstance

-- imports
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CoreTypes = require("@self/../Types/CoreTypes")
local PacketTypes = require("@self/../Types/PacketTypes")
local CreatePacketEvent = require("@self/.././CreatePacketEvent")
local CreatePacketFunction = require("@self/.././CreatePacketFunction")
local CreateUnreliablePacketEvent = require("@self/.././CreateUnreliablePacketEvent")
local NetworkError = require("@self/.././NetworkError")

-- types
type PacketeerPublic<Server, Client> = {
	Destroy: (self: PacketeerPublic<Server, Client>) -> (),
	Server: Server,
	Client: Client
}

type PacketeerPrivate<Server, Client> =
	PacketeerPublic<Server, Client> & {
		_networkSchema: CoreTypes.NetworkSchema<Server, Client>,
	}


function Packeteer.create<Server, Client>(schema: CoreTypes.NetworkSchema<Server, Client>): PacketeerPublic<Server, Client>
	local self = setmetatable({}, PacketeerInstance) :: PacketeerPrivate<Server, Client>

	self._networkSchema = schema
	
	local function setPacketSchemaType(schema: {}, schemaType: "Client" | "Server")
		if (schema)  then
			for key, value in pairs(schema) do
				if (typeof(value) == "table" and value._schemaType == nil) then
					value._name = key
					value._schemaType = schemaType
					
					value:createPacketEvent()
					
					if value.createConnections and type(value.createConnections) == "function" then
						value:createConnections()
					end
				end
			end	
		end
	end

	setPacketSchemaType(self._networkSchema.Client, "Client")
	setPacketSchemaType(self._networkSchema.Server, "Server")
	
	self.Client = self._networkSchema.Client
	self.Server = self._networkSchema.Server

	return self	
end

function Packeteer.initializeServer(networkingFolder: Folder)
	if (RunService:IsServer()) then
		local requiredModules = {}
		
		if (networkingFolder)  then
			local networkingModules = networkingFolder:GetDescendants()
			
			for _, module in pairs(networkingModules) do
				if (module and module:IsA("ModuleScript") and table.find(requiredModules, module.Name) == nil) then
					require(module)
					requiredModules[module.Name] = module.Name
				end
			end
			
		else
			warn(NetworkError.new({ kind = "Init", 
				message = `'{networkingFolder}' does not exist.` , 
				context = "Packeteer" }):__tostring())
		end
	else
		warn(NetworkError.new({ kind = "Init", 
			message = "Attempted to initialize Packeteer on the client.", 
			context = "Packeteer" }):__tostring())
		return
	end
end

function Packeteer.event<T>(): PacketTypes.PublicEventPacket<T>
	return CreatePacketEvent.new()
end

function Packeteer.packetFunction<T, R>(): PacketTypes.PublicFunctionPacket<T, R>
	return CreatePacketFunction.new()
end

function Packeteer.unreliable<T>(): PacketTypes.PublicUnreliablePacket<T>
	return CreateUnreliablePacketEvent.new()
end

function PacketeerInstance.Destroy()
	self._networkSchema = nil
end

return Packeteer

