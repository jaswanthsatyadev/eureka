# 🎨 Component Asset Collection & Pin Mapping Guide

> **Mission:** Build the visual component library for Eureka. Every component you collect powers the interactive 2D circuit canvas that users see and wire!

---

## 📁 Where to Put the Files

All component graphics should be placed in the `assets/components/` folder organized by category:

```text
eureka/
└── assets/
    ├── component_catalog.csv          # Tracking spreadsheet with pin positions & metadata
    └── components/
        ├── microcontrollers/          # e.g., esp32-devkit-v1.svg, arduino-uno-r3.svg
        ├── sensors/                   # e.g., dht22.svg, soil-moisture.svg, ultrasonic-hcsr04.svg
        ├── actuators/                 # e.g., relay-5v-1ch.svg, servo-sg90.svg, buzzer.svg
        ├── displays/                  # e.g., oled-0.96-i2c.svg, lcd-1602-i2c.svg
        ├── power/                     # e.g., mb102-power-supply.svg, battery-9v.svg
        └── passives/                  # e.g., resistor.svg, led-red.svg, push-button.svg
```

> **Naming Rule:** Use lowercase letters with hyphens. Example: `soil-moisture-sensor.svg`, `esp32-devkit-v1.svg`.

---

## 📐 Visual Standards (Simple Rules for SVGs)

1. **Format:** Must be clean **`.svg`** (Vector graphic).
2. **Background:** Must be **Transparent** (no white or black background box around the component).
3. **Top-Down Perspective:** Components should look flat top-down or 2.5D breadboard-friendly (just like on Fritzing or Wokwi).
4. **Visible Pin Pads:** Every pin/terminal where a wire connects should have a clear circular or rectangular pad.
5. **Standardized ViewBox:**
   - Every SVG must have a defined `viewBox` attribute (e.g., `viewBox="0 0 160 240"`).
   - Keep stroke lines crisp (around `1.5px` to `2px`).

---

## 📍 How to Record Pin Positions (Coordinates)

When a user clicks on an SVG in our app, wires snap to exact **pin positions**. You need to record the `(X, Y)` position of each pin.

### How to find `(X, Y)` coordinates in 10 seconds:

1. Open the SVG in **Figma** (free) or **Boxy SVG** / **Inkscape**.
2. Click on the center of the pin circle.
3. Look at the right sidebar for **X** and **Y** position numbers.
4. Record those numbers in `assets/component_catalog.csv`.

---

## 📊 Catalog Spreadsheet Template (`assets/component_catalog.csv`)

Add one row per component with its details and pin coordinates:

| Part Name       | Category         | File Path                                                  | ViewBox Width | ViewBox Height | Pins (Name:X,Y:Role)                                                                                                                     |
| --------------- | ---------------- | ---------------------------------------------------------- | ------------- | -------------- | ---------------------------------------------------------------------------------------------------------------------------------------- |
| ESP32 DevKit V1 | Microcontrollers | `assets/components/microcontrollers/esp32-devkit-v1.svg` | 160           | 260            | `3V3:10,20:power_vcc; GND:10,40:power_gnd; D15:10,60:gpio; D2:10,80:gpio; D4:10,100:gpio; VIN:150,20:power_vcc; GND2:150,40:power_gnd` |
| 5V Relay 1-CH   | Actuators        | `assets/components/actuators/relay-5v-1ch.svg`           | 120           | 180            | `VCC:20,20:power_vcc; GND:20,40:power_gnd; IN:20,60:gpio; NO:100,20:passive; COM:100,40:passive; NC:100,60:passive`                    |
| 0.96" OLED I2C  | Displays         | `assets/components/displays/oled-0.96-i2c.svg`           | 140           | 140            | `GND:35,10:power_gnd; VCC:55,10:power_vcc; SCL:75,10:i2c_scl; SDA:95,10:i2c_sda`                                                       |

### Pin Roles to Use:

- `power_vcc` (Power 3.3V / 5V / VIN)
- `power_gnd` (Ground GND)
- `gpio` (Digital input/output)
- `analog_in` (Analog sensor input)
- `pwm` (PWM signal e.g. for Servo)
- `i2c_sda` / `i2c_scl` (I2C communication)
- `passive` (Relay contacts, resistor terminals, switch legs)

---

## 🎯 Priority Checklist (Top 25 Components to Collect First)

Start with these 25 essential components so we can test the most common user projects:

### 1. Microcontrollers

- [ ] **ESP32 DevKit V1** (30-pin)
- [ ] **Arduino Uno R3**
- [ ] **Arduino Nano**
- [ ] **Raspberry Pi Pico**

### 2. Sensors

- [ ] **DHT11 / DHT22** (Temperature & Humidity Sensor - 3/4 pins)
- [ ] **Capacitive Soil Moisture Sensor v1.2** (3 pins: VCC, GND, AOUT)
- [ ] **HC-SR04** (Ultrasonic Distance Sensor - 4 pins: VCC, Trig, Echo, GND)
- [ ] **PIR Motion Sensor HC-SR501** (3 pins: VCC, OUT, GND)
- [ ] **LDR Light Sensor Module** (3/4 pins: VCC, GND, DO, AO)
- [ ] **MQ-2 Gas / Smoke Sensor** (4 pins: VCC, GND, DO, AO)
- [ ] **MPU-6050** (Gyro + Accelerometer I2C module)

### 3. Actuators & Outputs

- [ ] **5V Single Channel Relay Module**
- [ ] **SG90 9g Micro Servo Motor** (3 wires: Brown=GND, Red=5V, Orange=PWM)
- [ ] **Active 5V Buzzer Module**
- [ ] **5mm LEDs** (Red, Green, Blue, Yellow - Anode & Cathode)
- [ ] **28BYJ-48 Stepper Motor + ULN2003 Driver Board**

### 4. Displays

- [ ] **0.96" I2C OLED Display SSD1306** (4 pins: GND, VCC, SCL, SDA)
- [ ] **16x2 Character LCD with I2C Backpack** (4 pins: GND, VCC, SDA, SCL)
- [ ] **WS2812B NeoPixel 8-LED Strip / Ring**

### 5. Power & Prototyping

- [ ] **Half-Size Breadboard (400 tie-points)**
- [ ] **Full-Size Breadboard (830 tie-points)**
- [ ] **MB102 Breadboard Power Supply Module** (5V / 3.3V)
- [ ] **9V Battery with DC Barrel Jack / Clip**
- [ ] **10kΩ and 220Ω Resistors**
- [ ] **Tactile Push Button (4 pins)**

---

## 🔍 Great Free Places to Source SVGs

1. **Fritzing App Open Source Parts:** [GitHub Fritzing Parts](https://github.com/fritzing/fritzing-parts/tree/master/svg/core/breadboard)
2. **Wokwi Open Source Parts:** [Wokwi Elements](https://github.com/wokwi/wokwi-elements)
3. **Wikimedia Commons Electronics:** Search for vector schematics and breadboard graphics.
4. **Figma Community:** Search "Electronics Components UI Kit" or "Arduino Breadboard Kit".
