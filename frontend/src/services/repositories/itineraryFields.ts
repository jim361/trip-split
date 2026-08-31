import { createAppError } from "../../shared/contracts";
import type { ItineraryCategory, ItineraryPlanId } from "../../shared/types";

/** Missing legacy fields keep the original itinerary in plan A without rewriting it. */
export function readItineraryPlanFields(input: { planId?: unknown; category?: unknown }): {
  planId: ItineraryPlanId;
  category: ItineraryCategory;
} {
  const planId = input.planId === undefined ? "A" : input.planId;
  const category = input.category === undefined ? "other" : input.category;
  if (planId !== "A" && planId !== "B") {
    throw createAppError("invalid-argument", "일정은 A안 또는 B안을 선택해 주세요.", {
      retryable: false,
      field: "planId",
    });
  }
  if (
    category !== "flight" &&
    category !== "transport" &&
    category !== "meal" &&
    category !== "activity" &&
    category !== "stay" &&
    category !== "other"
  ) {
    throw createAppError("invalid-argument", "올바른 일정 유형을 선택해 주세요.", {
      retryable: false,
      field: "category",
    });
  }
  return { planId, category };
}
