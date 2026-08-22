/**
 * Structured Circuit Domain Models.
 * Adheres to:
 * - Golden Rule: JSON model is source of truth.
 * - Convention 15: Pin coordinates are relative to SVG viewBox.
 */

export interface PinPosition {
  x: number;
  y: number;
}

export type PinRole =
  | 'power_vcc'
  | 'power_gnd'
  | 'gpio'
  | 'analog_in'
  | 'pwm'
  | 'i2c_sda'
  | 'i2c_scl'
  | 'spi_mosi'
  | 'spi_miso'
  | 'spi_sck'
  | 'spi_cs'
  | 'uart_tx'
  | 'uart_rx'
  | 'passive';

export interface PinDefinition {
  name: string;
  role: PinRole;
  position: PinPosition; // Relative to SVG viewBox
  voltage_range?: { min: number; max: number };
  max_current_ma?: number;
  description?: string;
}

export interface ElectricalCharacteristics {
  operating_voltage_min: number;
  operating_voltage_max: number;
  typical_voltage: number;
  max_current_draw_ma: number;
  logic_level_voltage?: number;
  requires_pullup?: boolean;
}

export interface ComponentInstance {
  id: string; // UUID v4
  catalog_id: string; // UUID v4 pointing to component_definitions
  name: string;
  category: string;
  designator: string; // e.g. "U1", "R1", "D1", "ESP1"
  position: { x: number; y: number }; // Canvas coordinate (px)
  rotation: number; // 0, 90, 180, 270 degrees
  properties: Record<string, any>; // e.g. { resistance: "10k", unit: "ohm" }
  pins: Record<string, PinDefinition>; // Keyed by pin name
  asset_url?: string;
  view_box?: { width: number; height: number };
  unit_price: number;
  currency: string;
}

export interface WireEndpoint {
  component_id: string;
  pin_name: string;
}

export interface Wire {
  id: string; // UUID v4
  source: WireEndpoint;
  target: WireEndpoint;
  net_id?: string;
  color?: string;
}

export interface Net {
  id: string;
  name: string;
  net_type: 'power' | 'ground' | 'signal';
  endpoints: WireEndpoint[];
}

export interface ProjectRequirements {
  summary: string;
  controller?: string;
  inputs: string[];
  outputs: string[];
  connectivity: string[];
  power_source?: string;
  target_budget?: number;
  currency?: string;
  ambiguities?: string[];
}

export interface CircuitGraph {
  schema_version: string; // e.g. "1.0.0"
  components: ComponentInstance[];
  wires: Wire[];
  nets: Net[];
  requirements: ProjectRequirements;
  metadata: Record<string, any>;
}
