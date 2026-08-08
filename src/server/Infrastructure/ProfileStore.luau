--!strict

local ProfileStore = {}
ProfileStore.__index = ProfileStore

export type Options = {
	store: any,
	sessionId: string,
	now: (() -> number)?,
	wait: ((number) -> ())?,
	normalize: (any) -> any,
	leaseSeconds: number?,
	retryCount: number?,
}

export type ProfileStore = typeof(setmetatable(
	{} :: {
		store: any,
		sessionId: string,
		now: () -> number,
		wait: (number) -> (),
		normalize: (any) -> any,
		leaseSeconds: number,
		retryCount: number,
	},
	ProfileStore
))

local function deepCopy(value: any): any
	if type(value) ~= "table" then
		return value
	end
	local copy = {}
	for key, child in value do
		copy[deepCopy(key)] = deepCopy(child)
	end
	return copy
end

local function dataFromRecord(record: any): any
	if type(record) == "table" and type(record.data) == "table" then
		return record.data
	end
	return record
end

function ProfileStore.new(options: Options): ProfileStore
	assert(options.store, "ProfileStore requires a DataStore")
	assert(options.sessionId ~= "", "ProfileStore requires a session id")
	return setmetatable({
		store = options.store,
		sessionId = options.sessionId,
		now = options.now or os.time,
		wait = options.wait or task.wait,
		normalize = options.normalize,
		leaseSeconds = options.leaseSeconds or 180,
		retryCount = options.retryCount or 4,
	}, ProfileStore)
end

function ProfileStore:_attempt(operation: () -> any): (boolean, any)
	local lastError: any = "unknown persistence failure"
	for attempt = 1, self.retryCount do
		local success, result = pcall(operation)
		if success then
			return true, result
		end
		lastError = result
		if attempt < self.retryCount then
			self.wait(0.5 * 2 ^ (attempt - 1))
		end
	end
	return false, lastError
end

function ProfileStore:acquire(key: string): (any?, string?)
	local blockedBySession = false
	local success, result = self:_attempt(function()
		return self.store:UpdateAsync(key, function(current: any)
			local now = self.now()
			if type(current) == "table" and type(current.session) == "table" then
				local owner = current.session.id
				local expiresAt = tonumber(current.session.expiresAt) or 0
				if owner ~= self.sessionId and expiresAt > now then
					blockedBySession = true
					return nil
				end
			end

			return {
				formatVersion = 1,
				data = self.normalize(deepCopy(dataFromRecord(current))),
				session = {
					id = self.sessionId,
					expiresAt = now + self.leaseSeconds,
				},
			}
		end)
	end)

	if not success then
		return nil, tostring(result)
	end
	if blockedBySession then
		return nil, "profile is active in another server"
	end
	if type(result) ~= "table" or type(result.data) ~= "table" then
		return nil, "DataStore returned an invalid profile record"
	end
	return self.normalize(deepCopy(result.data)), nil
end

function ProfileStore:save(key: string, profile: any): (boolean, string?)
	local lostSession = false
	local snapshot = deepCopy(profile)
	local success, result = self:_attempt(function()
		return self.store:UpdateAsync(key, function(current: any)
			if
				type(current) ~= "table"
				or type(current.session) ~= "table"
				or current.session.id ~= self.sessionId
			then
				lostSession = true
				return nil
			end

			return {
				formatVersion = 1,
				data = snapshot,
				session = {
					id = self.sessionId,
					expiresAt = self.now() + self.leaseSeconds,
				},
			}
		end)
	end)

	if not success then
		return false, tostring(result)
	end
	if lostSession or result == nil then
		return false, "profile session ownership was lost"
	end
	return true, nil
end

function ProfileStore:release(key: string): (boolean, string?)
	local success, result = self:_attempt(function()
		return self.store:UpdateAsync(key, function(current: any)
			if
				type(current) == "table"
				and type(current.session) == "table"
				and current.session.id == self.sessionId
			then
				local released = deepCopy(current)
				released.session = nil
				return released
			end
			return current
		end)
	end)
	return success, if success then nil else tostring(result)
end

function ProfileStore.clone(value: any): any
	return deepCopy(value)
end

return ProfileStore
