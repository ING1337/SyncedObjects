-- SyncedObjects Client by ING
-- It's not allowed to use that script to create any kind of donor stuff!

-- ####################################################################################################################################

class 'SyncedObjects'

function SyncedObjects:__init(tps)
	self.objects      = {}
	self.timer        = Timer()
	self.lastRender   = 0
	
	self.testInterval = 1000 / (tps or 2)
	self.testNext     = 0
	
	Network:Subscribe("SyncedObjectCreate", self, self.Create)
	Network:Subscribe("SyncedObjectUpdate", self, self.Update)
	Network:Subscribe("SyncedObjectRemove", self, self.Remove)
	Network:Subscribe("SyncedObjectList", self, self.List)
	Network:Subscribe("SyncedObjectClear", self, self.Clear)
	
	Events:Subscribe("ModuleUnload", self, self.Clear)
	Events:Subscribe("Render", self, self.Render)
end

-- ####################################################################################################################################

function SyncedObjects:Create(e)
	e.id = e.id or os.time() * math.random()
	self.objects[e.id] = e
	self:InitObject(e)
	self.testNext = 0
end

function SyncedObjects:Update(e)
	v = self.objects[e.id]
	if v then
		self:RemoveObject(v)
		for key, value in pairs(e) do v[key] = value end
		self:InitObject(v)
		self.testNext = 0
	end
end

function SyncedObjects:Remove(e)
	v = self.objects[e.id]
	if v then
		self:RemoveObject(v)
		self.objects[e.id] = nil
	end
end

function SyncedObjects:Clear(e)
	for k, v in pairs(self.objects) do
		if not e or e == v.parent then self:Remove(v) end
	end
end

function SyncedObjects:List(e)
	for k, v in pairs(e) do self:Create(v) end
end

-- ####################################################################################################################################

function SyncedObjects:InitObject(e)
	e.distance = e.distance or 512
	e.position = e.position or Vector3()
	e.angle    = e.angle or Angle()
	e.time     = e.time and e.time * 1000 + self.timer:GetMilliseconds() or nil
	e.velocity = e.velocity or Vector3()
	e.spin     = e.spin or Angle()
	e.offset   = e.offset or e.position
	e.rotate   = e.rotate or e.angle
	
	if e.parent then 
		self:Attach(e)
		if e.velocity:Length() > 0 then 
			e.velocity = IsValid(e.parent) and e.parent:GetAngle() * e.velocity or e.velocity
			e.parent   = nil
		end
	end
end

function SyncedObjects:CreateObject(e)
	self:RemoveObject(e)
	
	if e.effect_id then
		e.object = ClientEffect.Create(AssetLocation.Game, e)
	elseif e.path then
		e.object = ClientParticleSystem.Create(AssetLocation.Game, e)
	elseif e.bank_id then
		e.object = ClientEffect.Create(AssetLocation.Game, e)
	elseif e.multiplier then
		e.object = ClientLight.Create(e)
	elseif e.model then
		e.object = ClientStaticObject.Create(e)
	else
		print("Invalid synced object type!")
		self:Remove(e)
	end
end

function SyncedObjects:RemoveObject(e)
	if IsValid(e.object) then e.object:Remove() end
	e.object = nil
end

-- ####################################################################################################################################

function SyncedObjects:Render()
	time            = self.timer:GetMilliseconds()
	timing          = (time - self.lastRender) / 1000
	self.lastRender = time
	test            = false
	
	if time > self.testNext then
		test = true
		self.testNext = time + self.testInterval
	end
	
	for k, e in pairs(self.objects) do
		if e.time and e.time <= time then
			self:Remove(e)
		else
			e.position = e.position + e.velocity * timing
			e.rotate   = e.rotate * self:ScaleAngle(e.spin, timing)
			self:Attach(e)
			
			if test then
				if Vector3.Distance(e.position, LocalPlayer:GetPosition()) <= e.distance and (not e.parent or IsValid(e.parent)) then
					if not e.object then self:CreateObject(e) end
				else
					if e.object then self:RemoveObject(e) end
				end
			end
			
			if e.object then
				e.object:SetPosition(e.position)
				e.object:SetAngle(e.angle * e.rotate)
			end
		end
	end
end

function SyncedObjects:Attach(e)
	if IsValid(e.parent) then
		if e.bone then
			bones      = e.parent:GetBones()
			e.angle    = bones[e.bone].angle
			e.position = bones[e.bone].position + e.angle * e.offset
		else
			e.angle    = e.parent:GetAngle()
			e.position = e.parent:GetPosition() + e.angle * e.offset
		end
	end
end

function SyncedObjects:ScaleAngle(angle, scale)
	return Angle(angle.yaw * scale, angle.pitch * scale, angle.roll * scale)
end

-- ####################################################################################################################################

syncedObjects = SyncedObjects()
