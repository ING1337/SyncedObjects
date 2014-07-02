-- SyncedObjects Server by ING
-- It's not allowed to use that script to create any kind of donor stuff!

-- ####################################################################################################################################

class 'SyncedObjects'

function SyncedObjects:__init()
	self.fullsynced = {}
	Events:Subscribe("CreateSyncedObject", self, self.Create)
	Events:Subscribe("UpdateSyncedObject", self, self.Update)
	Events:Subscribe("RemoveSyncedObject", self, self.Remove)
	Events:Subscribe("ClearSyncedObject", self, self.Clear)
	Events:Subscribe("PlayerJoin", self, self.PlayerJoin)
end

-- ####################################################################################################################################

function SyncedObjects:Create(args)
	if args.fullsync then self.fullsynced[args.id] = args end
	if args.players then
		Network:SendToPlayers(args.players, "SyncedObjectCreate", args)
	elseif args.nearby then
		Network:SendNearby(args.nearby, "SyncedObjectCreate", args)
		Network:Send(args.nearby, "SyncedObjectCreate", args)
	else
		Network:Broadcast("SyncedObjectCreate", args)
	end
end

function SyncedObjects:Update(args)
	Network:Broadcast("SyncedObjectUpdate", args)
end

function SyncedObjects:Remove(args)
	self.fullsynced[args.id] = nil
	Network:Broadcast("SyncedObjectRemove", args)
end

function SyncedObjects:Clear(args)
	for k, v in pairs(self.fullsynced) do
		if not args or args == v.parent then self.fullsynced[k] = nil end
	end
	Network:Broadcast("SyncedObjectClear", args)
end

function SyncedObjects:PlayerJoin(args)
	Network:Send(args.player, "SyncedObjectList", self.fullsynced)
end

-- ####################################################################################################################################

syncedObjects = SyncedObjects()
