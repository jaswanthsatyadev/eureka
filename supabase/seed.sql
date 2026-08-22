-- ==============================================================================
-- seed.sql: Starter Seed Data for Eureka Component Catalog & Project Categories
-- ==============================================================================

-- 1. Project Categories
INSERT INTO public.project_categories (id, name, description) VALUES
    ('cat_iot', 'Internet of Things (IoT)', 'Connected smart devices, sensors, and telemetry'),
    ('cat_home_auto', 'Home Automation', 'Smart home controls, relays, environmental monitors'),
    ('cat_robotics', 'Robotics & Motion', 'Motor drivers, servos, robotic arms, wheeled platforms'),
    ('cat_audio', 'Audio & Music', 'Synthesizers, audio players, buzzers, sound reactive devices'),
    ('cat_wearables', 'Wearables', 'Low-power portable electronics and displays'),
    ('cat_general', 'General Prototyping', 'Experimental circuits, breadboard tests, educational projects')
ON CONFLICT (id) DO UPDATE SET name = EXCLUDED.name, description = EXCLUDED.description;

-- 2. Component Categories
INSERT INTO public.component_categories (id, name, description, sort_order) VALUES
    ('mcu', 'Microcontrollers', 'Microcontroller development boards (ESP32, Arduino, Pico)', 1),
    ('sensors', 'Sensors', 'Sensory inputs (temperature, soil, motion, distance, gas)', 2),
    ('actuators', 'Actuators & Relays', 'Outputs (relays, motors, buzzers, servos)', 3),
    ('displays', 'Displays', 'Visual outputs (OLED, LCD, LED matrices)', 4),
    ('power', 'Power Management', 'Battery shields, voltage regulators, power modules', 5),
    ('passives', 'Passives & Prototyping', 'Breadboards, resistors, LEDs, push buttons', 6)
ON CONFLICT (id) DO UPDATE SET name = EXCLUDED.name, description = EXCLUDED.description, sort_order = EXCLUDED.sort_order;

-- 3. Initial Component Definitions (High Quality Starter Catalog)
INSERT INTO public.component_definitions (
    id, name, category_id, purpose, manufacturer, part_number,
    structured_pins, electrical_characteristics, unit_price, currency,
    asset_key, view_box, confidence
) VALUES
(
    '00000000-0000-0000-0001-000000000001',
    'ESP32 DevKit V1 (30-Pin)',
    'mcu',
    'Dual-core WiFi & Bluetooth enabled microcontroller development board',
    'Espressif Systems',
    'ESP32-WROOM-32',
    '[
        {"name": "3V3", "role": "power_vcc", "position": {"x": 10, "y": 20}, "voltage_range": {"min": 3.0, "max": 3.6}},
        {"name": "GND", "role": "power_gnd", "position": {"x": 10, "y": 40}},
        {"name": "D15", "role": "gpio", "position": {"x": 10, "y": 60}},
        {"name": "D2", "role": "gpio", "position": {"x": 10, "y": 80}},
        {"name": "D4", "role": "gpio", "position": {"x": 10, "y": 100}},
        {"name": "RX2", "role": "uart_rx", "position": {"x": 10, "y": 120}},
        {"name": "TX2", "role": "uart_tx", "position": {"x": 10, "y": 140}},
        {"name": "D5", "role": "gpio", "position": {"x": 10, "y": 160}},
        {"name": "D18", "role": "gpio", "position": {"x": 10, "y": 180}},
        {"name": "D19", "role": "gpio", "position": {"x": 10, "y": 200}},
        {"name": "D21", "role": "i2c_sda", "position": {"x": 10, "y": 220}},
        {"name": "D22", "role": "i2c_scl", "position": {"x": 10, "y": 240}},
        {"name": "VIN", "role": "power_vcc", "position": {"x": 150, "y": 20}, "voltage_range": {"min": 5.0, "max": 12.0}},
        {"name": "GND2", "role": "power_gnd", "position": {"x": 150, "y": 40}},
        {"name": "D13", "role": "gpio", "position": {"x": 150, "y": 60}},
        {"name": "D12", "role": "gpio", "position": {"x": 150, "y": 80}},
        {"name": "D14", "role": "gpio", "position": {"x": 150, "y": 100}},
        {"name": "D27", "role": "gpio", "position": {"x": 150, "y": 120}},
        {"name": "D26", "role": "gpio", "position": {"x": 150, "y": 140}},
        {"name": "D25", "role": "gpio", "position": {"x": 150, "y": 160}},
        {"name": "D33", "role": "gpio", "position": {"x": 150, "y": 180}},
        {"name": "D32", "role": "gpio", "position": {"x": 150, "y": 200}},
        {"name": "D35", "role": "analog_in", "position": {"x": 150, "y": 220}},
        {"name": "D34", "role": "analog_in", "position": {"x": 150, "y": 240}}
    ]'::jsonb,
    '{"operating_voltage_min": 3.0, "operating_voltage_max": 3.6, "typical_voltage": 3.3, "max_current_draw_ma": 250, "logic_level_voltage": 3.3}'::jsonb,
    4.50,
    'USD',
    'components/microcontrollers/esp32-devkit-v1.svg',
    '{"width": 160, "height": 260}'::jsonb,
    'verified'
),
(
    '00000000-0000-0000-0001-000000000002',
    'Capacitive Soil Moisture Sensor v1.2',
    'sensors',
    'Measures soil moisture levels via capacitive sensing with corrosion-resistant probe',
    'Generic',
    'CAP-SOIL-V1.2',
    '[
        {"name": "VCC", "role": "power_vcc", "position": {"x": 20, "y": 20}, "voltage_range": {"min": 3.3, "max": 5.5}},
        {"name": "GND", "role": "power_gnd", "position": {"x": 30, "y": 20}},
        {"name": "AOUT", "role": "analog_in", "position": {"x": 40, "y": 20}}
    ]'::jsonb,
    '{"operating_voltage_min": 3.3, "operating_voltage_max": 5.5, "typical_voltage": 3.3, "max_current_draw_ma": 5, "logic_level_voltage": 3.3}'::jsonb,
    1.20,
    'USD',
    'components/sensors/soil-moisture-v1.2.svg',
    '{"width": 60, "height": 180}'::jsonb,
    'verified'
),
(
    '00000000-0000-0000-0001-000000000003',
    '5V Single-Channel Relay Module',
    'actuators',
    'High-current relay switch for controlling AC/DC appliances safely with optocoupler isolation',
    'Songle',
    'SRD-05VDC-SL-C',
    '[
        {"name": "VCC", "role": "power_vcc", "position": {"x": 20, "y": 20}, "voltage_range": {"min": 4.5, "max": 5.5}},
        {"name": "GND", "role": "power_gnd", "position": {"x": 20, "y": 40}},
        {"name": "IN", "role": "gpio", "position": {"x": 20, "y": 60}},
        {"name": "NO", "role": "passive", "position": {"x": 100, "y": 20}},
        {"name": "COM", "role": "passive", "position": {"x": 100, "y": 40}},
        {"name": "NC", "role": "passive", "position": {"x": 100, "y": 60}}
    ]'::jsonb,
    '{"operating_voltage_min": 4.5, "operating_voltage_max": 5.5, "typical_voltage": 5.0, "max_current_draw_ma": 70, "logic_level_voltage": 3.3}'::jsonb,
    1.10,
    'USD',
    'components/actuators/relay-5v-1ch.svg',
    '{"width": 120, "height": 160}'::jsonb,
    'verified'
),
(
    '00000000-0000-0000-0001-000000000004',
    '0.96 inch I2C OLED Display (SSD1306)',
    'displays',
    'Monochrome 128x64 pixel graphic display with high contrast and I2C 2-wire interface',
    'Generic',
    'SSD1306-0.96',
    '[
        {"name": "GND", "role": "power_gnd", "position": {"x": 35, "y": 10}},
        {"name": "VCC", "role": "power_vcc", "position": {"x": 55, "y": 10}, "voltage_range": {"min": 3.3, "max": 5.0}},
        {"name": "SCL", "role": "i2c_scl", "position": {"x": 75, "y": 10}},
        {"name": "SDA", "role": "i2c_sda", "position": {"x": 95, "y": 10}}
    ]'::jsonb,
    '{"operating_voltage_min": 3.3, "operating_voltage_max": 5.0, "typical_voltage": 3.3, "max_current_draw_ma": 20, "logic_level_voltage": 3.3}'::jsonb,
    2.50,
    'USD',
    'components/displays/oled-0.96-i2c.svg',
    '{"width": 140, "height": 140}'::jsonb,
    'verified'
),
(
    '00000000-0000-0000-0001-000000000005',
    'SG90 9g Micro Servo Motor',
    'actuators',
    'Lightweight position control actuator with 180-degree rotation range',
    'TowerPro',
    'SG90',
    '[
        {"name": "GND", "role": "power_gnd", "position": {"x": 40, "y": 100}},
        {"name": "VCC", "role": "power_vcc", "position": {"x": 60, "y": 100}, "voltage_range": {"min": 4.8, "max": 6.0}},
        {"name": "PWM", "role": "pwm", "position": {"x": 80, "y": 100}}
    ]'::jsonb,
    '{"operating_voltage_min": 4.8, "operating_voltage_max": 6.0, "typical_voltage": 5.0, "max_current_draw_ma": 500, "logic_level_voltage": 3.3}'::jsonb,
    1.80,
    'USD',
    'components/actuators/servo-sg90.svg',
    '{"width": 120, "height": 120}'::jsonb,
    'verified'
),
(
    '00000000-0000-0000-0001-000000000006',
    'Arduino Uno R3',
    'mcu',
    'Standard ATmega328P microcontroller board operating at 5V logic',
    'Arduino',
    'A000066',
    '[
        {"name": "5V", "role": "power_vcc", "position": {"x": 30, "y": 160}, "voltage_range": {"min": 4.8, "max": 5.2}},
        {"name": "3V3", "role": "power_vcc", "position": {"x": 45, "y": 160}, "voltage_range": {"min": 3.2, "max": 3.4}},
        {"name": "GND", "role": "power_gnd", "position": {"x": 60, "y": 160}},
        {"name": "GND2", "role": "power_gnd", "position": {"x": 75, "y": 160}},
        {"name": "VIN", "role": "power_vcc", "position": {"x": 90, "y": 160}, "voltage_range": {"min": 7.0, "max": 12.0}},
        {"name": "A0", "role": "analog_in", "position": {"x": 120, "y": 160}},
        {"name": "A1", "role": "analog_in", "position": {"x": 135, "y": 160}},
        {"name": "A2", "role": "analog_in", "position": {"x": 150, "y": 160}},
        {"name": "A3", "role": "analog_in", "position": {"x": 165, "y": 160}},
        {"name": "A4", "role": "i2c_sda", "position": {"x": 180, "y": 160}},
        {"name": "A5", "role": "i2c_scl", "position": {"x": 195, "y": 160}},
        {"name": "D0", "role": "uart_rx", "position": {"x": 30, "y": 20}},
        {"name": "D1", "role": "uart_tx", "position": {"x": 45, "y": 20}},
        {"name": "D2", "role": "gpio", "position": {"x": 60, "y": 20}},
        {"name": "D3", "role": "pwm", "position": {"x": 75, "y": 20}},
        {"name": "D4", "role": "gpio", "position": {"x": 90, "y": 20}},
        {"name": "D5", "role": "pwm", "position": {"x": 105, "y": 20}},
        {"name": "D6", "role": "pwm", "position": {"x": 120, "y": 20}},
        {"name": "D7", "role": "gpio", "position": {"x": 135, "y": 20}},
        {"name": "D8", "role": "gpio", "position": {"x": 160, "y": 20}},
        {"name": "D9", "role": "pwm", "position": {"x": 175, "y": 20}},
        {"name": "D10", "role": "pwm", "position": {"x": 190, "y": 20}},
        {"name": "D11", "role": "pwm", "position": {"x": 205, "y": 20}},
        {"name": "D12", "role": "gpio", "position": {"x": 220, "y": 20}},
        {"name": "D13", "role": "gpio", "position": {"x": 235, "y": 20}}
    ]'::jsonb,
    '{"operating_voltage_min": 4.8, "operating_voltage_max": 5.2, "typical_voltage": 5.0, "max_current_draw_ma": 50, "logic_level_voltage": 5.0}'::jsonb,
    12.00,
    'USD',
    'components/microcontrollers/arduino-uno-r3.svg',
    '{"width": 240, "height": 180}'::jsonb,
    'verified'
)
ON CONFLICT (id) DO UPDATE SET
    name = EXCLUDED.name,
    purpose = EXCLUDED.purpose,
    structured_pins = EXCLUDED.structured_pins,
    electrical_characteristics = EXCLUDED.electrical_characteristics,
    unit_price = EXCLUDED.unit_price;
