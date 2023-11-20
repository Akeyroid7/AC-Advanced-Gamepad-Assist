-- Launtch-assist clutch by Akeyroid7

local self = {}

self.title = "Launtch-Assist Clutch"
self.description = "The clutch is automatically controlled from stop to start, assist in smooth starting."
self.version = "0.0"
self.author = "Akeyroid7"

local ENGINE_DATA = ac.INIConfig.carData(0, 'engine.ini')
local ENGINE_IDLE = ENGINE_DATA:get('ENGINE_DATA', 'MINIMUM', 1000)
local ENGINE_LIMIT = ENGINE_DATA:get('ENGINE_DATA', 'LIMITER', 8000)

if ENGINE_LIMIT == 0 then ENGINE_LIMIT = 11000 end

local CLUTCH_MAX_TORQUE = ac.INIConfig.carData(0, 'drivetrain.ini'):get('CLUTCH', 'MAX_TORQUE', 300)

local clutchLockUp = true

function self.update()

  local data = ac.getJoypadState()
  local car = car or ac.getCar(0)
  local phys = ac.getCarPhysics(0)

  if not car or not phys then return end

  local drivetrainRatio = phys.gearRatios[car.gear + 1] * phys.finalRatio * 9.54935

  local poweredWheelsRadius = 0
  if car.tractionType == 0 then -- 0 for rwd
    poweredWheelsRadius = (car.wheels[2].tyreRadius + car.wheels[3].tyreRadius) / 2
  elseif car.tractionType == 1 then -- 1 for fwd
    poweredWheelsRadius = (car.wheels[0].tyreRadius + car.wheels[1].tyreRadius) / 2
  else -- 2 for awd, 3 for new awd, -1 for N/A.
    poweredWheelsRadius = (car.wheels[0].tyreRadius + car.wheels[1].tyreRadius + car.wheels[2].tyreRadius + car.wheels[3].tyreRadius) / 4
  end

  local velocityRpm = car.velocity:length() / poweredWheelsRadius * drivetrainRatio * math.sign(car.gear)

  local clutchRpm = car.drivetrainSpeed * drivetrainRatio
  local engineRpmPropo = math.max(car.rpm - ENGINE_IDLE, 0) / (ENGINE_LIMIT - ENGINE_IDLE)

  local clutchForce = math.saturate(engineRpmPropo / 0.2 * (car.drivetrainTorque / CLUTCH_MAX_TORQUE) ^ (1 / 1.5))

  if velocityRpm <= ENGINE_IDLE then
    clutchLockUp = false
  end

  if ENGINE_IDLE < car.rpm and car.rpm <= clutchRpm then
    clutchLockUp = true
  end

  if car.gear == 0 then
    clutchLockUp = true
  end

  if clutchLockUp then
    clutchForce = 1
  end

  if data.clutch < clutchForce then
    clutchForce = data.clutch
  end

  data.clutch = clutchForce

  ac.debug('[A7-LAC] clutch meet', clutchRpm / car.rpm)
  ac.debug('[A7-LAC] lock up', clutchLockUp)

end

return self
