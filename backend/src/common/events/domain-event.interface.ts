export interface DomainEvent<TPayload extends Record<string, unknown> = Record<string, unknown>> {
  name: string;
  aggregateType?: string;
  aggregateId?: string | number | null;
  actorUserId?: number | null;
  source?: string;
  idempotencyKey?: string;
  payload: TPayload;
  occurredAt?: Date;
}

export interface PublishedDomainEvent {
  published: true;
  event_name: string;
  event_id: string;
  outbox_id: string;
  occurred_at: string;
}
