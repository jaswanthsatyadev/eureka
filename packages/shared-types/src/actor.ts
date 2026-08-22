/**
 * Actor attribution model adhering to Global Technical Convention #7.
 */
export type ActorType = 'user' | 'ai';

export interface Actor {
  actor_type: ActorType;
  user_id: string | null;
  ai_run_id: string | null;
}
