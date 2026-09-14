import { act, cleanup, fireEvent, render, screen, within } from "@testing-library/react";
import { useEffect, useState } from "react";
import { afterEach, describe, expect, it, vi } from "vitest";

import { PlatformServicesProvider, type PlatformServices } from "../../app/providers";
import { MockTripSessionService } from "../../services/functions/tripSessionService";
import { createInMemoryTripRepositories } from "../../services/mock";
import { MockAuthService } from "../../services/mock/mockAuthService";
import type { ItineraryItem, ItineraryPlanId } from "../../shared/types";
import {
  GANGNEUNG_TRIP_ID,
  gangneungFixtureIds,
  gangneungTripFixture,
  gangneungTripRepositorySeed,
} from "../../test/fixtures/gangneungTrip";
import { ItineraryWorksheet } from "./ItineraryWorksheet";

afterEach(() => {
  cleanup();
  vi.restoreAllMocks();
});

function renderWorksheet(extraItems: ItineraryItem[] = []) {
  const repositories = createInMemoryTripRepositories(
    {
      ...gangneungTripRepositorySeed,
      itinerary: [...gangneungTripFixture.itinerary, ...extraItems],
    },
    { getActorUid: () => gangneungFixtureIds.users.owner },
  );
  const onSelectDate = vi.fn();
  const services: PlatformServices = {
    dataSource: "mock",
    auth: new MockAuthService(),
    repositories,
    tripSessions: new MockTripSessionService(repositories),
  };
  function WorksheetWithSubscription() {
    const [items, setItems] = useState(() => repositories.snapshot().itinerary);
    const [planId, setPlanId] = useState<ItineraryPlanId>("A");
    const [date, setDate] = useState(gangneungTripFixture.trip.startDate);
    useEffect(
      () =>
        repositories.itinerary.subscribeItinerary(GANGNEUNG_TRIP_ID, setItems, (error) => {
          throw error;
        }),
      [],
    );
    return (
      <PlatformServicesProvider services={services}>
        <ItineraryWorksheet
          tripId={GANGNEUNG_TRIP_ID}
          startDate={gangneungTripFixture.trip.startDate}
          endDate={gangneungTripFixture.trip.endDate}
          selectedDate={date}
          dates={["2026-07-03", "2026-07-04"]}
          planId={planId}
          onSelectPlan={setPlanId}
          items={items}
          places={gangneungTripFixture.places}
          onSelectDate={(next) => {
            setDate(next);
            onSelectDate(next);
          }}
        />
      </PlatformServicesProvider>
    );
  }
  render(<WorksheetWithSubscription />);
  return { repositories, onSelectDate };
}

function pendingCommand() {
  let resolve!: () => void;
  const promise = new Promise<void>((complete) => {
    resolve = complete;
  });
  return { promise, resolve };
}
function block(title: string, plan = "A") {
  return within(screen.getByRole("region", { name: `${plan}안 전체 시간표` })).getByRole("button", {
    name: new RegExp(`^${title} ·`),
  });
}
function edit(title = "수원 출발") {
  fireEvent.click(block(title));
  return screen.getByRole("form", { name: "일정 수정" });
}

describe("여행 시간표", () => {
  it("상단 입력 바로가기는 생성 중인 A/B 입력·날짜·표시 시간을 보존하고 제목으로 이동한다", () => {
    const { onSelectDate } = renderWorksheet();
    fireEvent.click(screen.getByRole("button", { name: /2일차/ }));
    fireEvent.change(screen.getByRole("combobox", { name: "표시 시작" }), {
      target: { value: "8" },
    });
    fireEvent.change(screen.getByRole("combobox", { name: "표시 종료" }), {
      target: { value: "20" },
    });
    const form = screen.getByRole("form", { name: "새 일정 추가" });
    const title = within(form).getByLabelText("일정 제목");
    const scroll = vi.fn();
    Object.defineProperty(form, "scrollIntoView", { configurable: true, value: scroll });
    const focus = vi.spyOn(title, "focus");
    fireEvent.change(title, { target: { value: "A안 작성 중" } });
    fireEvent.change(within(form).getByLabelText("시작"), { target: { value: "10:15" } });
    const dateCalls = onSelectDate.mock.calls.length;
    const jump = screen.getByRole("button", { name: "새 일정 추가로 이동" });
    jump.focus();
    fireEvent.click(jump);
    expect(title).toHaveFocus();
    expect(scroll).toHaveBeenLastCalledWith({ behavior: "auto", block: "start" });
    expect(focus).toHaveBeenLastCalledWith({ preventScroll: true });
    expect(title).toHaveValue("A안 작성 중");
    expect(within(form).getByLabelText("날짜")).toHaveValue("2026-07-04");
    expect(within(form).getByLabelText("시작")).toHaveValue("10:15");
    expect(onSelectDate).toHaveBeenCalledTimes(dateCalls);

    fireEvent.click(screen.getByRole("button", { name: "B안" }));
    fireEvent.change(title, { target: { value: "B안 작성 중" } });
    fireEvent.click(screen.getByRole("button", { name: "새 일정 추가로 이동" }));
    expect(title).toHaveFocus();
    expect(title).toHaveValue("B안 작성 중");
    expect(screen.getByRole("button", { name: "B안" })).toHaveAttribute("aria-pressed", "true");
    fireEvent.click(screen.getByRole("button", { name: "A안" }));
    fireEvent.click(screen.getByRole("button", { name: "새 일정 추가로 이동" }));
    expect(title).toHaveValue("A안 작성 중");
    expect(within(form).getByLabelText("시작")).toHaveValue("10:15");
    expect(screen.getByRole("button", { name: /2일차/ })).toHaveAttribute("aria-pressed", "true");
    expect(screen.getByRole("combobox", { name: "표시 시작" })).toHaveValue("8");
    expect(screen.getByRole("combobox", { name: "표시 종료" })).toHaveValue("20");
    expect(onSelectDate).toHaveBeenCalledTimes(dateCalls);
  });

  it("편집 바로가기는 선택 항목과 미저장 수정을 그대로 유지한다", () => {
    const { onSelectDate } = renderWorksheet();
    const originalBlock = block("수원 출발");
    const form = edit();
    const title = within(form).getByLabelText("일정 제목");
    fireEvent.change(title, { target: { value: "수원 출발 수정 중" } });
    fireEvent.change(within(form).getByLabelText("메모"), { target: { value: "차량 확인 필요" } });
    const confirm = vi.spyOn(window, "confirm");
    const dateCalls = onSelectDate.mock.calls.length;
    const jump = screen.getByRole("button", { name: "일정 수정으로 이동" });
    jump.focus();
    fireEvent.click(jump);
    expect(title).toHaveFocus();
    expect(title).toHaveValue("수원 출발 수정 중");
    expect(within(form).getByLabelText("메모")).toHaveValue("차량 확인 필요");
    expect(screen.getByRole("form", { name: "일정 수정" })).toBe(form);
    expect(block("수원 출발")).toBe(originalBlock);
    expect(originalBlock).toHaveClass("is-editing");
    expect(confirm).not.toHaveBeenCalled();
    expect(onSelectDate).toHaveBeenCalledTimes(dateCalls);
  });

  it("같은 블록 재선택은 입력을 보존하고 다른 블록·새 작성은 변경 폐기를 확인한다", () => {
    renderWorksheet();
    const form = edit();
    const title = within(form).getByLabelText("일정 제목");
    const confirm = vi.spyOn(window, "confirm").mockReturnValue(false);
    fireEvent.change(title, { target: { value: "출발 수정 중" } });
    fireEvent.click(block("수원 출발"));
    expect(title).toHaveValue("출발 수정 중");
    expect(confirm).not.toHaveBeenCalled();
    fireEvent.click(block("형제칼국수 점심"));
    expect(confirm).toHaveBeenCalledOnce();
    expect(title).toHaveValue("출발 수정 중");
    fireEvent.click(within(form).getByRole("button", { name: "새 일정 작성" }));
    expect(title).toHaveValue("출발 수정 중");
    expect(screen.getByRole("form", { name: "일정 수정" })).toBe(form);
    confirm.mockReturnValue(true);
    fireEvent.click(block("형제칼국수 점심"));
    expect(title).toHaveValue("형제칼국수 점심");
    fireEvent.change(title, { target: { value: "점심 수정 중" } });
    fireEvent.click(within(form).getByRole("button", { name: "새 일정 작성" }));
    expect(screen.getByRole("form", { name: "새 일정 추가" })).toBe(form);
    expect(title).toHaveValue("");
  });

  it("외부 일정 갱신 중 미저장 입력과 블록 identity를 보존하고 저장 완료를 표시한다", async () => {
    const { repositories } = renderWorksheet();
    const originalBlock = block("수원 출발");
    const form = edit();
    const title = within(form).getByLabelText("일정 제목");
    fireEvent.change(title, { target: { value: "서울 출발" } });
    await act(() =>
      repositories.itinerary.updateItineraryItem(
        GANGNEUNG_TRIP_ID,
        gangneungFixtureIds.itinerary.depart,
        { title: "동행이 수정한 출발" },
      ),
    );
    expect(block("동행이 수정한 출발")).toBe(originalBlock);
    expect(title).toHaveValue("서울 출발");
    fireEvent.click(within(form).getByRole("button", { name: "일정 저장" }));
    expect(await within(form).findByRole("status")).toHaveTextContent("저장됨");
    expect(block("서울 출발")).toBe(originalBlock);
    expect(
      repositories
        .snapshot()
        .itinerary.find((item) => item.id === gangneungFixtureIds.itinerary.depart),
    ).toMatchObject({ title: "서울 출발" });
  });

  it("저장 중 입력과 계획 전환을 잠그고 다른 날짜의 같은 안에서 마지막 순서를 부여한다", async () => {
    const { repositories, onSelectDate } = renderWorksheet([
      {
        ...gangneungTripFixture.itinerary[0],
        id: "b-late-order",
        date: "2026-07-04",
        planId: "B",
        order: 99,
      },
    ]);
    const pending = pendingCommand();
    const update = repositories.itinerary.updateItineraryItem;
    const updateSpy = vi
      .spyOn(repositories.itinerary, "updateItineraryItem")
      .mockImplementation(async (...args) => {
        await pending.promise;
        await update(...args);
      });
    const form = edit();
    fireEvent.change(within(form).getByLabelText("날짜"), { target: { value: "2026-07-04" } });
    fireEvent.click(within(form).getByRole("button", { name: "일정 저장" }));
    for (const input of form.querySelectorAll("input, select, button"))
      expect(input).toBeDisabled();
    expect(screen.getByRole("button", { name: "B안" })).toBeDisabled();
    expect(screen.getByRole("button", { name: "일정 수정으로 이동" })).toBeDisabled();
    expect(updateSpy).toHaveBeenCalledWith(
      GANGNEUNG_TRIP_ID,
      gangneungFixtureIds.itinerary.depart,
      expect.objectContaining({ date: "2026-07-04", planId: "A", order: 2 }),
    );
    await act(async () => pending.resolve());
    expect(await within(form).findByRole("status")).toHaveTextContent("저장됨");
    expect(within(form).getByLabelText("날짜")).toBeEnabled();
    expect(screen.getByRole("button", { name: "B안" })).toBeEnabled();
    expect(screen.getByRole("button", { name: "일정 수정으로 이동" })).toBeEnabled();
    expect(onSelectDate).toHaveBeenCalledWith("2026-07-04");
    expect(
      repositories
        .snapshot()
        .itinerary.find((item) => item.id === gangneungFixtureIds.itinerary.depart),
    ).toMatchObject({ date: "2026-07-04", order: 2 });
  });

  it("추가 중 입력을 잠그고 완료 후 새 입력을 받는다", async () => {
    const { repositories } = renderWorksheet();
    const pending = pendingCommand();
    const create = repositories.itinerary.createItineraryItem;
    vi.spyOn(repositories.itinerary, "createItineraryItem").mockImplementation(async (...args) => {
      await pending.promise;
      return create(...args);
    });
    const form = screen.getByRole("form", { name: "새 일정 추가" });
    const title = within(form).getByLabelText("일정 제목");
    fireEvent.change(title, { target: { value: "저녁 회의" } });
    fireEvent.click(within(form).getByRole("button", { name: "새 일정 추가" }));
    for (const input of form.querySelectorAll("input, select, button"))
      expect(input).toBeDisabled();
    expect(screen.getByRole("button", { name: "B안" })).toBeDisabled();
    expect(screen.getByRole("button", { name: "새 일정 추가로 이동" })).toBeDisabled();
    await act(async () => pending.resolve());
    expect(await within(form).findByRole("status")).toHaveTextContent("새 일정이 추가됐습니다.");
    expect(block("저녁 회의")).toBeInTheDocument();
    expect(title).toBeEnabled();
    expect(screen.getByRole("button", { name: "새 일정 추가로 이동" })).toBeEnabled();
    expect(title).toHaveValue("");
    fireEvent.change(title, { target: { value: "다음 일정" } });
    expect(title).toHaveValue("다음 일정");
  });

  it("A/B안별 미저장 입력을 보존하고 유형·장소·시간을 독립적으로 저장한다", async () => {
    const { repositories } = renderWorksheet();
    const form = screen.getByRole("form", { name: "새 일정 추가" });
    fireEvent.change(within(form).getByLabelText("일정 제목"), {
      target: { value: "A안 작성 중" },
    });
    fireEvent.click(screen.getByRole("button", { name: "B안" }));
    expect(within(form).getByLabelText("일정 제목")).toHaveValue("");
    fireEvent.change(within(form).getByLabelText("일정 제목"), { target: { value: "B안 브런치" } });
    fireEvent.change(within(form).getByLabelText("시작"), { target: { value: "10:15" } });
    fireEvent.change(within(form).getByLabelText("종료"), { target: { value: "11:45" } });
    fireEvent.change(within(form).getByLabelText("유형"), { target: { value: "meal" } });
    const placeId = gangneungTripFixture.places[0].id;
    fireEvent.change(within(form).getByLabelText("장소"), { target: { value: placeId } });
    fireEvent.click(screen.getByRole("button", { name: "A안" }));
    expect(within(form).getByLabelText("일정 제목")).toHaveValue("A안 작성 중");
    fireEvent.click(screen.getByRole("button", { name: "B안" }));
    expect(within(form).getByLabelText("일정 제목")).toHaveValue("B안 브런치");
    fireEvent.click(within(form).getByRole("button", { name: "새 일정 추가" }));
    expect(await within(form).findByRole("status")).toHaveTextContent("새 일정이 추가됐습니다.");
    expect(block("B안 브런치", "B")).toHaveClass("schedule-color--meal");
    expect(block("B안 브런치", "B")).toHaveStyle({ top: "102px", height: "36px" });
    expect(
      repositories.snapshot().itinerary.find((item) => item.title === "B안 브런치"),
    ).toMatchObject({
      planId: "B",
      category: "meal",
      placeId,
      startTime: "10:15",
      endTime: "11:45",
      order: 0,
    });
    expect(
      within(screen.getByRole("region", { name: "B안 전체 시간표" })).queryByRole("button", {
        name: /^수원 출발/,
      }),
    ).not.toBeInTheDocument();
    fireEvent.click(screen.getByRole("button", { name: "A안" }));
    expect(within(form).getByLabelText("일정 제목")).toHaveValue("A안 작성 중");
    expect(block("수원 출발")).toBeInTheDocument();
  });

  it("시간 미정 일정과 표시 시간 밖 일정을 보존하며 24시간으로 펼친다", () => {
    renderWorksheet([
      {
        ...gangneungTripFixture.itinerary[0],
        id: "untimed",
        title: "시간 나중에",
        startTime: undefined,
        endTime: undefined,
      },
      {
        ...gangneungTripFixture.itinerary[0],
        id: "early",
        title: "새벽 비행",
        startTime: "04:35",
        endTime: "05:20",
      },
    ]);
    expect(screen.getByRole("heading", { name: "시간 미정" })).toBeInTheDocument();
    const untimed = screen.getByRole("group", { name: "시간 미정 일정" });
    expect(within(untimed).getByRole("button", { name: /^시간 나중에 ·/ })).toBeInTheDocument();
    expect(screen.getByText(/표시 시간 밖에 걸친 일정 1개/)).toBeInTheDocument();
    fireEvent.click(screen.getByRole("button", { name: "24시간 보기" }));
    expect(block("새벽 비행")).toHaveStyle({ top: "110px", height: "18px" });
    fireEvent.click(within(untimed).getByRole("button", { name: /^시간 나중에 ·/ }));
    expect(
      within(screen.getByRole("form", { name: "일정 수정" })).getByLabelText("시작"),
    ).toHaveValue("");
  });

  it("자정을 넘는 입력은 거절하고 선택 일정 삭제를 확인받는다", async () => {
    const { repositories } = renderWorksheet();
    const update = vi.spyOn(repositories.itinerary, "updateItineraryItem");
    const form = edit();
    fireEvent.change(within(form).getByLabelText("시작"), { target: { value: "23:00" } });
    fireEvent.change(within(form).getByLabelText("종료"), { target: { value: "01:00" } });
    fireEvent.click(within(form).getByRole("button", { name: "일정 저장" }));
    expect(await within(form).findByRole("alert")).toHaveTextContent(
      "자정을 넘는 일정은 날짜별로 나누어 주세요.",
    );
    expect(update).not.toHaveBeenCalled();
    const confirm = vi.spyOn(window, "confirm").mockReturnValue(false);
    fireEvent.click(within(form).getByRole("button", { name: "일정 삭제" }));
    expect(block("수원 출발")).toBeInTheDocument();
    confirm.mockReturnValue(true);
    fireEvent.click(within(form).getByRole("button", { name: "일정 삭제" }));
    expect(await screen.findByText("일정을 삭제했습니다.")).toBeInTheDocument();
    expect(
      repositories
        .snapshot()
        .itinerary.find((item) => item.id === gangneungFixtureIds.itinerary.depart),
    ).toBeUndefined();
    expect(block("형제칼국수 점심")).toBeInTheDocument();
  });

  it("기존 24:00 종료 일정은 표시하되 같은 값을 새로 저장하지 않는다", async () => {
    const { repositories } = renderWorksheet([
      {
        ...gangneungTripFixture.itinerary[0],
        id: "legacy-midnight",
        title: "기존 자정 일정",
        startTime: "23:00",
        endTime: "24:00",
      },
    ]);
    expect(block("기존 자정 일정")).toHaveAttribute(
      "title",
      expect.stringContaining("23:00–24:00"),
    );
    const form = edit("기존 자정 일정");
    const update = vi.spyOn(repositories.itinerary, "updateItineraryItem");
    fireEvent.click(within(form).getByRole("button", { name: "일정 저장" }));
    expect(await within(form).findByRole("alert")).toHaveTextContent("종료 시간을 확인해 주세요.");
    expect(update).not.toHaveBeenCalled();
  });

  it("종료 미정의 기본 30분이 표시 범위를 넘으면 저장 후 끝까지 자동 확장한다", async () => {
    renderWorksheet();
    fireEvent.change(screen.getByRole("combobox", { name: "표시 시작" }), {
      target: { value: "9" },
    });
    fireEvent.change(screen.getByRole("combobox", { name: "표시 종료" }), {
      target: { value: "10" },
    });
    const form = screen.getByRole("form", { name: "새 일정 추가" });
    fireEvent.change(within(form).getByLabelText("일정 제목"), {
      target: { value: "시간 범위 확장" },
    });
    fireEvent.change(within(form).getByLabelText("시작"), { target: { value: "09:45" } });
    fireEvent.change(within(form).getByLabelText("종료"), { target: { value: "" } });
    fireEvent.click(within(form).getByRole("button", { name: "새 일정 추가" }));
    expect(await within(form).findByRole("status")).toHaveTextContent("새 일정이 추가됐습니다.");
    expect(screen.getByRole("combobox", { name: "표시 종료" })).toHaveValue("11");
    expect(block("시간 범위 확장")).toHaveStyle({ top: "18px", height: "12px" });
  });
});
