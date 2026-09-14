import { describe, expect, it } from "vitest";

import type { ItineraryItem } from "../../shared/types";
import { layoutDayItems } from "./timetableLayout";

function item(id: string, startTime?: string, endTime?: string, order = 0): ItineraryItem {
  return {
    id,
    tripId: "trip",
    date: "2026-11-25",
    title: id,
    startTime,
    endTime,
    order,
    updatedAt: 0,
  };
}

describe("하루 시간표 레이아웃", () => {
  it("현지 시각의 정확한 분을 유지하고 종료 미정은 최대 자정까지 30분을 표시한다", () => {
    const { timed, untimed } = layoutDayItems([
      item("airport-bus", "07:35", "08:12"),
      item("lunch", "12:07"),
      item("late", "23:50", ""),
      item("midnight", "00:00", "00:01"),
    ]);

    expect(
      timed.map(({ item, startMinute, endMinute }) => [item.id, startMinute, endMinute]),
    ).toEqual([
      ["midnight", 0, 1],
      ["airport-bus", 455, 492],
      ["lunch", 727, 757],
      ["late", 1430, 1440],
    ]);
    expect(untimed).toEqual([]);
  });

  it("연결된 겹침 그룹마다 최소 lane 수를 공유하고 끝난 lane을 재사용한다", () => {
    const { timed } = layoutDayItems([
      item("a", "09:00", "10:00"),
      item("b", "09:30", "11:00"),
      item("c", "10:00", "10:30"),
      item("d", "10:15", "10:45"),
      item("e", "10:45", "11:15"),
      item("separate", "13:00", "14:00"),
    ]);

    expect(timed.map(({ item, lane, laneCount }) => [item.id, lane, laneCount])).toEqual([
      ["a", 0, 3],
      ["b", 1, 3],
      ["c", 0, 3],
      ["d", 2, 3],
      ["e", 0, 3],
      ["separate", 0, 1],
    ]);
  });

  it("맞닿은 경계는 겹치지 않으며 동일 시작 시 order와 id 순서를 유지한다", () => {
    const { timed } = layoutDayItems([
      item("b", "09:00", "09:30", 1),
      item("a", "09:00", "09:30", 1),
      item("first", "09:00", "09:30", 0),
      item("next", "09:30", "10:00"),
    ]);

    expect(timed.map(({ item, lane, laneCount }) => [item.id, lane, laneCount])).toEqual([
      ["first", 0, 3],
      ["a", 1, 3],
      ["b", 2, 3],
      ["next", 0, 1],
    ]);
  });

  it("시간 미정과 잘못된 기존 시간을 모두 untimed에 보존한다", () => {
    const invalid = [
      item("missing"),
      item("empty", "", ""),
      item("end-only", undefined, "10:00"),
      item("equal", "09:00", "09:00"),
      item("reversed", "10:00", "09:00"),
      item("bad-start", "9:00", "10:00"),
      item("bad-minute", "09:60", "10:00"),
      item("bad-end", "09:00", "24:01"),
      item("start-at-24", "24:00"),
      item("bad-text", "morning", "afternoon"),
    ];
    const last = item("last", "23:59", "24:00");
    const source = [...invalid, last];
    const before = structuredClone(source);
    const { timed, untimed } = layoutDayItems(source);

    expect(timed).toEqual([
      { item: last, startMinute: 1439, endMinute: 1440, lane: 0, laneCount: 1 },
    ]);
    expect(untimed).toHaveLength(invalid.length);
    expect(new Set(untimed)).toEqual(new Set(invalid));
    expect(source).toEqual(before);
  });

  it("빈 시간에 가짜 블록을 만들지 않고 빈 하루도 처리한다", () => {
    expect(layoutDayItems([])).toEqual({ timed: [], untimed: [] });
    const { timed } = layoutDayItems([
      item("morning", "08:00", "09:00"),
      item("evening", "20:00", "21:00"),
    ]);
    expect(timed).toHaveLength(2);
    expect(timed.map(({ startMinute, endMinute }) => [startMinute, endMinute])).toEqual([
      [480, 540],
      [1200, 1260],
    ]);
  });
});
