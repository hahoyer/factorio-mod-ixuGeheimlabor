local roboport_entity = table.deepcopy(data.raw["roboport-equipment"]["personal-roboport-mk2-equipment"])
roboport_entity.name = "roboport_von_ixu"
roboport_entity.take_result = "roboport_von_ixu"
roboport_entity.robot_limit = 32
roboport_entity.construction_radius = 32
roboport_entity.energy_source.buffer_capacity = "350MJ"

local roboport_item = table.deepcopy(data.raw["item"]["personal-roboport-mk2-equipment"])
roboport_item.name = "roboport_von_ixu"
roboport_item.place_as_equipment_result = "roboport_von_ixu"

local robot_entity = table.deepcopy(data.raw["construction-robot"]["construction-robot"])
robot_entity.name = "robot_von_ixu"
robot_entity.minable.result = "robot_von_ixu"
robot_entity.minable.mining_time = 2
robot_entity.resistances[1].percent = 99
robot_entity.resistances[2].percent = 99
robot_entity.max_payload_size = 100
robot_entity.speed = 0.6

local robot_item = table.deepcopy(data.raw["item"]["construction-robot"])
robot_item.name = "robot_von_ixu"
robot_item.place_result = "robot_von_ixu"

local solar_entity = table.deepcopy(data.raw["solar-panel-equipment"]["solar-panel-equipment"])
solar_entity.name = "solarpanel_von_ixu"
solar_entity.take_result = "solarpanel_von_ixu"
solar_entity.power = "300kW"

local solar_item = table.deepcopy(data.raw["item"]["solar-panel-equipment"])
solar_item.name = "solarpanel_von_ixu"
solar_item.place_as_equipment_result = "solarpanel_von_ixu"

data:extend({
    roboport_entity, roboport_item,
    robot_entity,robot_item,
    solar_entity, solar_item

})
