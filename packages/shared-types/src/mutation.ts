import { ComponentInstance, Wire, WireEndpoint } from './circuit';

/**
 * Mutation Models adhering to Global Technical Convention #6.
 * All UI edits and AI tool invocations pass through apply_mutation(project_id, mutation, actor).
 */

export interface AddComponentMutation {
  type: 'add_component';
  payload: {
    component: ComponentInstance;
  };
}

export interface RemoveComponentMutation {
  type: 'remove_component';
  payload: {
    component_id: string;
  };
}

export interface ReplaceComponentMutation {
  type: 'replace_component';
  payload: {
    old_component_id: string;
    new_component: ComponentInstance;
    preserve_wiring?: boolean;
  };
}

export interface MoveComponentMutation {
  type: 'move_component';
  payload: {
    component_id: string;
    position: { x: number; y: number };
  };
}

export interface RotateComponentMutation {
  type: 'rotate_component';
  payload: {
    component_id: string;
    rotation: number; // 0, 90, 180, 270
  };
}

export interface ConnectPinsMutation {
  type: 'connect_pins';
  payload: {
    wire: Wire;
  };
}

export interface DisconnectPinsMutation {
  type: 'disconnect_pins';
  payload: {
    wire_id: string;
  };
}

export interface UpdatePropertyMutation {
  type: 'update_property';
  payload: {
    component_id: string;
    key: string;
    value: any;
  };
}

export type CircuitMutation =
  | AddComponentMutation
  | RemoveComponentMutation
  | ReplaceComponentMutation
  | MoveComponentMutation
  | RotateComponentMutation
  | ConnectPinsMutation
  | DisconnectPinsMutation
  | UpdatePropertyMutation;
