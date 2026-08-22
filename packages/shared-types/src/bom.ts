/**
 * Bill of Materials (BOM) & Cost Models.
 * Adheres to Convention 10: Decimal/number pricing with explicit currency.
 */

export interface BOMItem {
  catalog_id: string;
  name: string;
  category: string;
  designators: string[]; // e.g. ["R1", "R2"]
  quantity: number;
  unit_price: number;
  total_price: number;
  currency: string;
  has_alternatives: boolean;
}

export interface BOMSnapshot {
  items: BOMItem[];
  total_cost: number;
  currency: string;
  calculated_at: string;
}
