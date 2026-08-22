/**
 * Validation finding severity adhering to Global Technical Convention #9.
 * Exactly three levels: critical (blocks completion / triggers auto-repair), warning, info.
 */
export type FindingSeverity = 'critical' | 'warning' | 'info';

export interface AffectedPinRef {
  component_id: string;
  pin_name: string;
}

export interface Finding {
  rule_id: string;
  message: string;
  severity: FindingSeverity;
  affected_component_ids: string[];
  affected_pins: AffectedPinRef[];
  suggestion?: string | null;
  confidence?: 'high' | 'medium' | 'low';
}

export interface ValidationResult {
  is_valid: boolean; // false if any finding is 'critical'
  findings: Finding[];
  validated_at: string; // ISO 8601 UTC
}
