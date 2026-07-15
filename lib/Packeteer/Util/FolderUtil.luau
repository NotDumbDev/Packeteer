local FolderUtil = {}
local ReplicatedStorage = game:GetService("ReplicatedStorage")

--[[
	Checks wether the folder exists in the given location.
	
	@param name The name of the folder to check.
	@param whereToCheck The location to check for the folder. Defaults to ReplicatedStorage.
	@param createIfNotExists If true, the folder will be created if it does not exist. Defaults to true.
	@return The folder if it exists or was created, nil otherwise.
]]
function FolderUtil.folderExists(name: string, whereToCheck: Instance?, createIfNotExists: boolean? ): Folder
	whereToCheck = whereToCheck or ReplicatedStorage
	createIfNotExists = createIfNotExists or true
	
	local folder = whereToCheck:FindFirstChild(name)
	
	if (not folder) then
		if (createIfNotExists) then
			const newFolder = Instance.new("Folder")
			newFolder.Parent = whereToCheck
			newFolder.Name = name
			return newFolder
		else
			return nil
		end
	end
	return folder
end
	
return FolderUtil
