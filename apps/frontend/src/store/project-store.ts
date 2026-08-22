import { create } from "zustand";
import { CircuitGraph, ComponentInstance, Wire, Finding } from "@eureka/shared-types";

interface ProjectState {
  // Current loaded project
  projectId: string | null;
  title: string;
  circuit: CircuitGraph;
  
  // Selection and UI state
  selectedComponentId: string | null;
  selectedWireId: string | null;
  isAiGenerating: boolean;
  validationFindings: Finding[];
  
  // Actions
  setProject: (id: string, title: string, circuit: CircuitGraph) => void;
  selectComponent: (id: string | null) => void;
  selectWire: (id: string | null) => void;
  setAiGenerating: (isGenerating: boolean) => void;
  setValidationFindings: (findings: Finding[]) => void;
  updateCircuitState: (circuit: CircuitGraph) => void;
}

const initialCircuit: CircuitGraph = {
  schema_version: "1.0.0",
  components: [],
  wires: [],
  nets: [],
  requirements: {
    summary: "",
    inputs: [],
    outputs: [],
    connectivity: [],
  },
  metadata: {},
};

export const useProjectStore = create<ProjectState>((set) => ({
  projectId: null,
  title: "Untitled Project",
  circuit: initialCircuit,
  selectedComponentId: null,
  selectedWireId: null,
  isAiGenerating: false,
  validationFindings: [],

  setProject: (id, title, circuit) =>
    set({ projectId: id, title, circuit, selectedComponentId: null, selectedWireId: null }),

  selectComponent: (id) =>
    set({ selectedComponentId: id, selectedWireId: null }),

  selectWire: (id) =>
    set({ selectedWireId: id, selectedComponentId: null }),

  setAiGenerating: (isGenerating) =>
    set({ isAiGenerating: isGenerating }),

  setValidationFindings: (findings) =>
    set({ validationFindings: findings }),

  updateCircuitState: (circuit) =>
    set({ circuit }),
}));
