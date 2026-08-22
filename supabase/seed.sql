-- Eureka Starter Seed Data: Component Categories and Initial Definitions

-- 1. Component Categories
INSERT INTO component_categories (id, name, description) VALUES
  ('cat_mcu', 'Microcontrollers', 'Microcontroller development boards (ESP32, Arduino, Raspberry Pi Pico)'),
  ('cat_sensor', 'Sensors', 'Input sensors (temperature, humidity, soil moisture, motion, ultrasonic)'),
  ('cat_actuator', 'Actuators & Outputs', 'Relays, servo motors, DC motors, buzzers, LEDs'),
  ('cat_display', 'Displays', 'OLED, LCD, e-Paper, RGB matrix displays'),
  ('cat_power', 'Power Management', 'Voltage regulators, battery shields, boost converters'),
  ('cat_passive', 'Passives & Discrete', 'Resistors, capacitors, diodes, transistors')
ON CONFLICT DO NOTHING;
