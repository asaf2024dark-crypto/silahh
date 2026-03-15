local Spring = {}

function Spring.create(mass, force, damping, speed)
	local self = {
		Target = Vector3.zero,
		Position = Vector3.zero,
		Velocity = Vector3.zero,
		Mass = mass or 5,
		Force = force or 50,
		Damping = damping or 4,
		Speed = speed or 4,
	}

	function self:shove(v)
		local y = v.Y
		if y ~= y or y == math.huge or y == -math.huge then
			y = 0
		end
		self.Velocity += Vector3.new(0, y, 0)
	end

	function self:update(dt)
		local scaled = math.min(dt, 1) * self.Speed / 8
		for _ = 1, 8 do
			self.Velocity += ((self.Target - self.Position) * self.Force / self.Mass - self.Velocity * self.Damping) * scaled
			self.Position += self.Velocity * scaled
		end
		return self.Position
	end

	return self
end

return Spring
