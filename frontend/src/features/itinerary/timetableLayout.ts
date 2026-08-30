import type { ItineraryItem } from "../../shared/types";

export type TimedItineraryItem = {
  item: ItineraryItem;
  startMinute: number;
  endMinute: number;
  lane: number;
  laneCount: number;
};

function parseMinute(time: string | undefined, allowEndOfDay = false): number | null {
  if (allowEndOfDay && time === "24:00") return 1440;
  if (!time || !/^([01]\d|2[0-3]):[0-5]\d$/.test(time)) return null;
  const [hour, minute] = time.split(":").map(Number);
  return hour * 60 + minute;
}

function compareOrder(left: ItineraryItem, right: ItineraryItem) {
  return left.order - right.order || left.id.localeCompare(right.id);
}

export function layoutDayItems(items: ItineraryItem[]): {
  timed: TimedItineraryItem[];
  untimed: ItineraryItem[];
} {
  const timed: TimedItineraryItem[] = [];
  const untimed: ItineraryItem[] = [];

  for (const item of items) {
    const startMinute = parseMinute(item.startTime);
    const endMinute = item.endTime
      ? parseMinute(item.endTime, true)
      : startMinute === null
        ? null
        : Math.min(startMinute + 30, 1440);

    if (startMinute === null || endMinute === null || endMinute <= startMinute) {
      untimed.push(item);
    } else {
      timed.push({ item, startMinute, endMinute, lane: 0, laneCount: 1 });
    }
  }

  timed.sort(
    (left, right) => left.startMinute - right.startMinute || compareOrder(left.item, right.item),
  );
  untimed.sort(compareOrder);

  let group: TimedItineraryItem[] = [];
  let groupEnd = 0;
  let laneEnds: number[] = [];
  const finishGroup = () => {
    for (const entry of group) entry.laneCount = laneEnds.length;
    group = [];
    laneEnds = [];
  };

  for (const entry of timed) {
    if (entry.startMinute >= groupEnd) finishGroup();
    // ponytail: A day's small itinerary needs only a lane scan; use a heap for thousands of overlaps.
    const freeLane = laneEnds.findIndex((end) => end <= entry.startMinute);
    entry.lane = freeLane === -1 ? laneEnds.length : freeLane;
    laneEnds[entry.lane] = entry.endMinute;
    group.push(entry);
    groupEnd = Math.max(groupEnd, entry.endMinute);
  }
  finishGroup();

  return { timed, untimed };
}
