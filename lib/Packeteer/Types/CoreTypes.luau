local ReplicatedStorage = game:GetService("ReplicatedStorage")
local PacketTypes = require("@self/../PacketTypes")

export type NetworkSchema<Server, Client> = {
	Client: Client,
	Server: Server
}

return {}