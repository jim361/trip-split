/** Firestore document IDs are opaque strings at the domain boundary. */
export type EntityId = string;

export type ParticipantId = EntityId;

export function isEntityId(value: unknown): value is EntityId {
  return typeof value === "string" && value.trim().length > 0;
}
