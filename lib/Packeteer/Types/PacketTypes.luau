local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Promise = require("@self/../../Include/Promise")

export type SchemaTypes = "Client" | "Server"

export type PublicEventPacket<T> = {
	Fire: (self: PublicEventPacket<T>, recipient: (Player | {Player}) | nil, paramaters: T) -> (),
	Connect: (self: PublicEventPacket<T>, callback: (sender: Player, paramaters: T) -> ()) -> RBXScriptConnection?
}

export type PrivateEventPacket<T> =
	PublicEventPacket<T> & {
		_referenceEvent: RemoteEvent,
		_name: string,
		_schemaType: SchemaTypes,
		_referenceEventExists: (action: string, callback: () -> ()) -> ()
	}

export type PublicFunctionPacket<T, R> = {
	Invoke: (self: PublicFunctionPacket<T, R>, recipient: Player | nil, paramaters: T) -> Promise.TypedPromise<R>,
	SetCallback: (self: PublicFunctionPacket<T, R>, callback: (sender: Player | nil, parameters: T) -> R) -> PublicFunctionPacket<T, R>
}

export type PrivateFunctionPacket<T, R> = PublicFunctionPacket<T, R> & {
	_referenceEvent: RemoteEvent,
	_name: string,
	_schemaType: SchemaTypes,
	_pendingRequests: { [number]: Promise.PendingRequest<R> },
	_callback: ((sender: Player, parameters: T) -> R)?,
	_referenceEventExists: (action: string, callback: () -> ()) -> (), 
}

export type PublicUnreliablePacket<T> = {
	Fire: (self: PublicUnreliablePacket<T>, recipient: (Player | {Player}) | nil, paramaters: T) -> (),
	Connect: (self: PublicUnreliablePacket<T>, callback: (sender: Player, paramaters: T) -> ()) -> RBXScriptConnection?
}

export type PrivateUnreliablePacket<T> = PublicUnreliablePacket<T> & {
	_referenceEvent: UnreliableRemoteEvent,
	_name: string,
	_schemaType: SchemaTypes,
	_referenceEventExists: (action: string, callback: () -> ()) -> ()
}

return {}