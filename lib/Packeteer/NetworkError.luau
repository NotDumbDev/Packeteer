local NetworkErrors = {}
NetworkErrors.__index = NetworkErrors

type ErrorKinds = "Internal" | "InvalidArguments" | "Environment"

type NetworkErrorOptions = {
	message: string?,
	kind: ErrorKinds | string?,
	context: string?,
	suggestions: {string}?
}

local function formatTrace(trace: string): string
	local lines = {}

	for line in trace:gmatch("[^\n]+") do
		table.insert(lines, "> " .. line)
	end

	return table.concat(lines, "\n")
end

function NetworkErrors.new(content: NetworkErrorOptions)
	local self = setmetatable({}, NetworkErrors)
	
	self.message = tostring(content.message or "Unknown error")
	self.kind = content.kind or "Internal"
	self.suggestions = content.suggestions or {}
	
	self.context = content.context
	self.createdAt = os.clock()
	self.trace = debug.traceback()

	return self
end

function NetworkErrors:__tostring()
	local formattedTrace = formatTrace(self.trace)

	local output = string.format(
		"[NetworkError:%s] %s\nContext: %s\n\nTrace: \n%s",
		self.kind,
		self.message,
		self.context or "none",
		formattedTrace
	)

	if #self.suggestions > 0 then
		output ..= "\n\nPossible fixes:"

		for index, suggestion in ipairs(self.suggestions) do
			output ..= string.format(
				"\n  %d. %s",
				index,
				suggestion
			)
		end
	end

	return output
end

return NetworkErrors
