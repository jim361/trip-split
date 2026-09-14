import type { EntityId, EpochMillis, ParticipantId } from "../contracts";

export type LocalDate = string;
export type KrwAmount = number;
export type CurrencyCode = "KRW" | "JPY";
export type AllocationMethod = "equal" | "itemized" | "custom";
export type ItineraryPlanId = "A" | "B";
export type ItineraryCategory = "flight" | "transport" | "meal" | "activity" | "stay" | "other";

export type MoneyAllocation = {
  participantId: ParticipantId;
  amount: KrwAmount;
};

export type ExpensePayer = {
  participantId: ParticipantId;
  amount: KrwAmount;
};

export type Trip = {
  id: EntityId;
  title: string;
  countryCode: string;
  timeZone: string;
  mapProvider: "google" | "naver";
  defaultCurrency: CurrencyCode;
  startDate: LocalDate;
  endDate: LocalDate;
  ownerUid: string;
  shareCode: string;
  createdAt: EpochMillis;
  updatedAt: EpochMillis;
};

export type UserProfile = {
  uid: string;
  displayName: string;
  email?: string;
  photoURL?: string;
  authProvider: "anonymous" | "google";
  createdAt: EpochMillis;
  updatedAt: EpochMillis;
};

export type TripMember = {
  uid: string;
  tripId: EntityId;
  displayName: string;
  photoURL?: string;
  role: "editor";
  joinedAt: EpochMillis;
  lastActiveAt: EpochMillis;
};

export type Participant = {
  id: ParticipantId;
  tripId: EntityId;
  name: string;
  color?: string;
  linkedUid?: string;
  isActive: boolean;
  createdAt: EpochMillis;
  updatedAt: EpochMillis;
};

export type Place = {
  id: EntityId;
  tripId: EntityId;
  name: string;
  address?: string;
  lat?: number;
  lng?: number;
  provider: "google" | "naver" | "manual";
  source: "googleSearch" | "googleMapsUrl" | "naverSearch" | "naverLink" | "manual";
  providerPlaceId?: string;
  sourceUrl?: string;
  addedBy?: string;
  memo?: string;
  createdAt: EpochMillis;
  updatedAt: EpochMillis;
};

export type ItineraryItem = {
  id: EntityId;
  tripId: EntityId;
  date: LocalDate;
  planId?: ItineraryPlanId;
  category?: ItineraryCategory;
  startTime?: string;
  endTime?: string;
  placeId?: EntityId;
  title: string;
  memo?: string;
  order: number;
  updatedBy?: string;
  updatedAt: EpochMillis;
};

export type ReceiptItem = {
  id: EntityId;
  kind: "item" | "discount" | "serviceFee" | "adjustment";
  name: string;
  amount: KrwAmount;
  consumers: ParticipantId[];
  allocationMethod: "equal" | "custom";
  allocatedAmounts: MoneyAllocation[];
  source: "ocr" | "manual";
  sortOrder: number;
};

export type Expense = {
  id: EntityId;
  tripId: EntityId;
  title: string;
  category: string;
  expenseDate: LocalDate;
  totalAmount: KrwAmount;
  currency: CurrencyCode;
  payer: ExpensePayer;
  consumers: ParticipantId[];
  allocationMethod: AllocationMethod;
  allocatedAmounts: MoneyAllocation[];
  receiptItems: ReceiptItem[];
  source: "manual" | "ocr";
  placeId?: EntityId;
  itineraryItemId?: EntityId;
  memo?: string;
  createdBy: string;
  updatedBy: string;
  createdAt: EpochMillis;
  updatedAt: EpochMillis;
};

export type ShareCode = {
  code: string;
  tripId: EntityId;
  createdBy: string;
  createdAt: EpochMillis;
  expiresAt?: EpochMillis;
  isActive: boolean;
  maxUses?: number;
  useCount: number;
};

export type OcrItemCandidate = {
  name: string;
  amount?: number;
  confidence?: number;
  sourceOrder: number;
};

export type ParsedReceipt = {
  rawText: string;
  merchantName?: string;
  expenseDate?: string;
  totalAmountCandidate?: number;
  items: OcrItemCandidate[];
  warnings: string[];
};
