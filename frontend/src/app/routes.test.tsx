import { act, cleanup, fireEvent, render, screen, within } from "@testing-library/react";
import { MemoryRouter, Route, Routes, useLocation } from "react-router-dom";
import { afterEach, beforeEach, describe, expect, it, vi } from "vitest";

import { TripShell } from "../pages/trip/TripShell";
import { MockTripSessionService } from "../services/functions/tripSessionService";
import { AuthProvider, PlatformServicesProvider } from "./providers";
import { AppRoutes } from "./routes";

const dialogPrototype = HTMLDialogElement.prototype;
const nativeShowModal = Object.getOwnPropertyDescriptor(dialogPrototype, "showModal");
const nativeClose = Object.getOwnPropertyDescriptor(dialogPrototype, "close");

// JSDOM has no modal dialog methods. Keep this shim local, without faking focus restoration.
beforeEach(() => {
  Object.defineProperty(dialogPrototype, "showModal", {
    configurable: true,
    value(this: HTMLDialogElement) {
      this.open = true;
      (
        this.querySelector<HTMLElement>("[autofocus]") ??
        this.querySelector<HTMLElement>("button, select, input")
      )?.focus();
    },
  });
  Object.defineProperty(dialogPrototype, "close", {
    configurable: true,
    value(this: HTMLDialogElement) {
      if (!this.open) return;
      this.open = false;
      this.dispatchEvent(new Event("close"));
    },
  });
});

afterEach(() => {
  cleanup();
  vi.restoreAllMocks();
  if (nativeShowModal) Object.defineProperty(dialogPrototype, "showModal", nativeShowModal);
  else Reflect.deleteProperty(dialogPrototype, "showModal");
  if (nativeClose) Object.defineProperty(dialogPrototype, "close", nativeClose);
  else Reflect.deleteProperty(dialogPrototype, "close");
});

function RouteLocation() {
  const location = useLocation();
  return (
    <output aria-label="현재 경로">
      {location.pathname}
      {location.search}
    </output>
  );
}

function renderRoute(path: string) {
  return render(
    <MemoryRouter initialEntries={[path]}>
      <RouteLocation />
      <PlatformServicesProvider>
        <AuthProvider>
          <AppRoutes />
        </AuthProvider>
      </PlatformServicesProvider>
    </MemoryRouter>,
  );
}

async function openDetails() {
  fireEvent.click(await screen.findByRole("button", { name: "동선·일정 열기" }));
  return screen.findByRole("dialog", { name: "동선·일정" });
}

function closeDetails() {
  fireEvent.click(screen.getByRole("button", { name: "동선·일정 닫기" }));
}

describe("여행 라우트", () => {
  it("일정 화면만 작은 헤더에 상태와 서랍 버튼을 모으고 중복 안내 행을 없앤다", async () => {
    renderRoute("/trips/tokyo-2026-11/itinerary");
    const title = await screen.findByRole("heading", { level: 1, name: "일정·지도" });
    const page = title.closest("article")!;
    const header = title.closest("header")!;
    expect(page).toHaveClass("feature-page--compact");
    expect(within(header).getByRole("button", { name: "동선·일정 열기" })).toBeInTheDocument();
    expect(within(header).getByRole("status")).toHaveTextContent("mock");
    expect(header.querySelector(".feature-page__description")).toBeNull();
    expect(page.querySelector(".itinerary-workspace__toolbar")).toBeNull();
    expect(screen.getByRole("heading", { name: "여행 시간표" })).toHaveClass("visually-hidden");
    expect(screen.queryByText("TRIP TIMETABLE")).not.toBeInTheDocument();

    fireEvent.click(screen.getByRole("link", { name: "준비" }));
    const preparation = await screen.findByRole("heading", { level: 1, name: "준비" });
    expect(preparation.closest("article")).not.toHaveClass("feature-page--compact");
    expect(
      preparation.closest("header")?.querySelector(".feature-page__description"),
    ).not.toBeNull();
  });

  it("Stitch 계정 시작 화면에서 계정 없이 여행 선택으로 이동한다", async () => {
    renderRoute("/");

    expect(
      screen.getByRole("heading", { level: 1, name: /여행을 계획하고.*함께 정산하세요/ }),
    ).toBeInTheDocument();
    expect(screen.getByRole("button", { name: "Google로 계속" })).toBeInTheDocument();
    fireEvent.click(await screen.findByRole("button", { name: "계정 없이 시작" }));
    expect(
      await screen.findByRole("link", { name: "도쿄 해외여행 데모 열기" }),
    ).toBeInTheDocument();
  });

  it("여행 루트에서 일정 페이지로 이동한다", async () => {
    renderRoute("/trips/gangneung");

    expect(await screen.findByRole("heading", { level: 1, name: "일정·지도" })).toBeInTheDocument();
    expect(screen.getByRole("link", { name: "일정·지도" })).toHaveAttribute("aria-current", "page");
  });

  it("세 메뉴를 같은 순서로 제공하고 각 placeholder로 이동한다", async () => {
    renderRoute("/trips/gangneung/itinerary");

    const navigation = screen.getByRole("navigation", {
      name: "여행 주요 메뉴",
    });
    const links = within(navigation)
      .getAllByRole("link")
      .filter((link) => link.classList.contains("trip-navigation__link"));

    expect(links.map((link) => link.textContent)).toEqual(["일정·지도", "준비", "비용"]);

    fireEvent.click(screen.getByRole("link", { name: "준비" }));
    expect(await screen.findByRole("heading", { level: 1, name: "준비" })).toBeInTheDocument();

    fireEvent.click(screen.getByRole("link", { name: "비용" }));
    expect(await screen.findByRole("heading", { level: 1, name: "비용" })).toBeInTheDocument();
  });

  it("데스크톱 여행 메뉴를 접고 다시 펼친다", async () => {
    const { container } = renderRoute("/trips/tokyo-2026-11/itinerary");

    const collapseButton = await screen.findByRole("button", { name: "여행 메뉴 접기" });
    expect(collapseButton).toHaveAttribute("aria-expanded", "true");
    fireEvent.click(collapseButton);

    expect(container.querySelector(".trip-shell")).toHaveClass("is-navigation-collapsed");
    expect(screen.getByRole("button", { name: "여행 메뉴 펼치기" })).toHaveAttribute(
      "aria-expanded",
      "false",
    );
    expect(screen.getByRole("link", { name: "일정·지도" })).toBeInTheDocument();
  });

  it("동선 서랍의 닫기·Escape가 포커스를 복원하고 시간표 미저장 입력을 유지한다", async () => {
    renderRoute("/trips/tokyo-2026-11/itinerary?source=planner");
    const form = await screen.findByRole("form", { name: "새 일정 추가" });
    const title = within(form).getByLabelText("일정 제목");
    fireEvent.change(title, { target: { value: "아직 저장하지 않은 일정" } });
    const openButton = screen.getByRole("button", { name: "동선·일정 열기" });
    expect(openButton).toHaveAttribute("aria-expanded", "false");
    expect(screen.queryByRole("region", { name: "오늘의 이동 동선" })).not.toBeInTheDocument();
    openButton.focus();
    const drawer = await openDetails();
    expect(openButton).toHaveAttribute("aria-expanded", "true");
    expect(openButton).toHaveAttribute("aria-controls", drawer.id);
    expect(drawer.contains(document.activeElement)).toBe(true);
    expect(screen.getByLabelText("현재 경로")).toHaveTextContent("details=open");
    closeDetails();
    expect(screen.queryByRole("dialog", { name: "동선·일정" })).not.toBeInTheDocument();
    expect(openButton).toHaveFocus();
    expect(openButton).toHaveAttribute("aria-expanded", "false");
    expect(title).toHaveValue("아직 저장하지 않은 일정");
    expect(screen.getByLabelText("현재 경로")).toHaveTextContent(
      "/trips/tokyo-2026-11/itinerary?source=planner",
    );

    const reopened = await openDetails();
    // Escape produces cancel; JSDOM does not dispatch it from keydown or apply its default close.
    act(() => {
      const cancel = new Event("cancel", { cancelable: true });
      reopened.dispatchEvent(cancel);
      if (!cancel.defaultPrevented) (reopened as HTMLDialogElement).close();
    });
    expect(screen.queryByRole("dialog", { name: "동선·일정" })).not.toBeInTheDocument();
    expect(openButton).toHaveFocus();
    expect(title).toHaveValue("아직 저장하지 않은 일정");
    expect(screen.getByLabelText("현재 경로")).toHaveTextContent(
      "/trips/tokyo-2026-11/itinerary?source=planner",
    );
  });

  it.each(["details=open", "map=expanded", "details=open&map=expanded"])(
    "%s 직접 링크는 서랍을 열고 닫을 때 다른 query를 보존한다",
    async (drawerQuery) => {
      renderRoute(`/trips/tokyo-2026-11/itinerary?source=share&${drawerQuery}`);
      const drawer = await screen.findByRole("dialog", { name: "동선·일정" });
      const openButton = screen.getByRole("button", { name: "동선·일정 열기" });
      expect(openButton).toHaveAttribute("aria-expanded", "true");
      if (drawerQuery.includes("map=expanded")) {
        expect(within(drawer).getByRole("button", { name: "지도 작게 보기" })).toHaveAttribute(
          "aria-expanded",
          "true",
        );
        expect(screen.getByLabelText("현재 경로")).toHaveTextContent("details=open");
        fireEvent.click(within(drawer).getByRole("button", { name: "지도 작게 보기" }));
        expect(screen.getByRole("dialog", { name: "동선·일정" })).toBe(drawer);
        expect(within(drawer).getByRole("button", { name: "지도 크게 보기" })).toHaveAttribute(
          "aria-expanded",
          "false",
        );
        expect(screen.getByLabelText("현재 경로")).toHaveTextContent("details=open");
        expect(screen.getByLabelText("현재 경로")).not.toHaveTextContent("map=expanded");
      } else {
        expect(within(drawer).getByRole("button", { name: "지도 크게 보기" })).toHaveAttribute(
          "aria-expanded",
          "false",
        );
      }
      closeDetails();
      expect(screen.queryByRole("dialog", { name: "동선·일정" })).not.toBeInTheDocument();
      expect(screen.getByLabelText("현재 경로")).toHaveTextContent(
        "/trips/tokyo-2026-11/itinerary?source=share",
      );
      expect(screen.getByLabelText("현재 경로")).not.toHaveTextContent("details=");
      expect(screen.getByLabelText("현재 경로")).not.toHaveTextContent("map=");
    },
  );

  it("닫힌 오른쪽 서랍을 열어 지도·일차 목록과 확대 상태를 확인한다", async () => {
    renderRoute("/trips/gangneung/itinerary");

    expect(screen.queryByRole("dialog", { name: "동선·일정" })).not.toBeInTheDocument();
    const drawer = await openDetails();
    const map = within(drawer).getByRole("region", { name: "오늘의 이동 동선" });
    const timeline = within(drawer).getByRole("region", { name: /1일차 일정/ });
    const expandButton = within(drawer).getByRole("button", { name: "지도 크게 보기" });

    expect(map.compareDocumentPosition(timeline) & Node.DOCUMENT_POSITION_FOLLOWING).toBeTruthy();
    expect(expandButton).toHaveAttribute("aria-expanded", "false");
    expect(screen.getByLabelText(/강릉 1박 2일 여행 동선 지도/)).toHaveTextContent("1");

    fireEvent.click(expandButton);
    expect(within(drawer).getByRole("button", { name: "지도 작게 보기" })).toHaveAttribute(
      "aria-expanded",
      "true",
    );
    expect(screen.getByLabelText("현재 경로")).toHaveTextContent("map=expanded");
  });

  it("기존 지도 URL은 확대된 통합 일정 화면으로 연결한다", async () => {
    renderRoute("/trips/gangneung/map");

    expect(await screen.findByRole("heading", { level: 1, name: "일정·지도" })).toBeInTheDocument();
    const drawer = await screen.findByRole("dialog", { name: "동선·일정" });
    expect(within(drawer).getByRole("button", { name: "지도 작게 보기" })).toHaveAttribute(
      "aria-expanded",
      "true",
    );
    expect(screen.getByRole("link", { name: "일정·지도" })).toHaveAttribute("aria-current", "page");
  });

  it("도쿄 해외여행을 만들 때 입력한 인원을 정산 대상으로 준비한다", async () => {
    const createTrip = vi.spyOn(MockTripSessionService.prototype, "createTrip");
    renderRoute("/trips");

    fireEvent.change(screen.getByRole("textbox", { name: "여행 이름" }), {
      target: { value: "우리 도쿄 여행" },
    });
    fireEvent.change(screen.getByRole("spinbutton", { name: /정산 인원/ }), {
      target: { value: "4" },
    });
    fireEvent.click(screen.getByRole("button", { name: "여행 만들기" }));

    expect(createTrip).toHaveBeenCalledWith(
      expect.objectContaining({
        title: "우리 도쿄 여행",
        countryCode: "JP",
        timeZone: "Asia/Tokyo",
        mapProvider: "google",
        defaultCurrency: "JPY",
        participantCount: 4,
      }),
    );
    expect(await screen.findByText("우리 도쿄 여행")).toBeInTheDocument();
    fireEvent.click(screen.getByRole("link", { name: "비용" }));
    expect(
      await screen.findByRole("heading", { level: 2, name: "정산 인원 4명" }),
    ).toBeInTheDocument();
  });

  it("31일보다 긴 여행도 마지막 날짜까지 시간표에 표시한다", async () => {
    renderRoute("/trips");
    fireEvent.change(screen.getByRole("textbox", { name: "여행 이름" }), {
      target: { value: "긴 여행" },
    });
    fireEvent.change(screen.getByLabelText("시작일"), { target: { value: "2026-11-25" } });
    fireEvent.change(screen.getByLabelText("종료일"), { target: { value: "2026-12-28" } });
    fireEvent.click(screen.getByRole("button", { name: "여행 만들기" }));
    const dateButtons = await screen.findByRole("group", { name: "여행 날짜 선택" });
    const lastDay = await within(dateButtons).findByRole("button", { name: /34일차.*12\. 28/ });
    expect(within(dateButtons).getAllByRole("button")).toHaveLength(34);
    fireEvent.click(lastDay);
    expect(lastDay).toHaveAttribute("aria-pressed", "true");
    await openDetails();
    expect(screen.getByRole("region", { name: /34일차 일정/ })).toBeInTheDocument();
  });

  it("비용 화면에서 정산 인원을 제외하고 다시 추가한다", async () => {
    renderRoute("/trips/tokyo-2026-11/settlement");

    const activeList = await screen.findByRole("list", { name: "활성 정산 인원" });
    expect(within(activeList).getAllByRole("listitem")).toHaveLength(3);

    fireEvent.click(within(activeList).getByRole("button", { name: "동행 3 정산에서 제외" }));
    expect(await within(activeList).findAllByRole("listitem")).toHaveLength(2);
    const restoreButton = screen.getByRole("button", { name: "동행 3 다시 정산에 포함" });
    fireEvent.click(restoreButton);
    expect(await within(activeList).findAllByRole("listitem")).toHaveLength(3);

    fireEvent.change(screen.getByRole("textbox", { name: "인원 추가" }), {
      target: { value: "새 동행" },
    });
    fireEvent.click(screen.getByRole("button", { name: "추가" }));
    expect(await within(activeList).findAllByRole("listitem")).toHaveLength(4);
    expect(within(activeList).getByText("새 동행")).toBeInTheDocument();
  });

  it("도쿄 일정에서 7일 날짜와 Google Maps 길찾기를 제공한다", async () => {
    renderRoute("/trips/tokyo-2026-11/itinerary");

    expect(await screen.findByRole("heading", { level: 1, name: "일정·지도" })).toBeInTheDocument();
    expect(
      within(screen.getByRole("group", { name: "여행 날짜 선택" })).getAllByRole("button"),
    ).toHaveLength(7);
    const drawer = await openDetails();
    expect(screen.getByLabelText(/도쿄 여행 동선 지도/)).toHaveTextContent("1");
    expect(screen.getByRole("link", { name: "Google Maps에서 열기 ↗" })).toHaveAttribute(
      "href",
      expect.stringContaining("google.com/maps/dir"),
    );

    fireEvent.change(within(drawer).getByRole("combobox", { name: "동선 날짜" }), {
      target: { value: "2026-11-26" },
    });
    const map = screen.getByRole("region", { name: "오늘의 이동 동선" });
    expect(within(map).getByText("2일차")).toBeInTheDocument();
    expect(screen.getByLabelText(/2일차 1번, 아사쿠사 산책/)).toBeInTheDocument();
    const routeUrl = screen
      .getByRole("link", { name: "Google Maps에서 열기 ↗" })
      .getAttribute("href");
    expect(routeUrl).toContain("api=1");
    expect(routeUrl).toContain("travelmode=transit");
    expect(decodeURIComponent(routeUrl ?? "")).toContain("origin=센소지");
    expect(decodeURIComponent(routeUrl ?? "")).toContain("destination=도쿄+스카이트리");
    closeDetails();
    expect(screen.getByRole("button", { name: /2일차.*11\. 26/ })).toHaveAttribute(
      "aria-pressed",
      "true",
    );
  });

  it("날짜·시간 시간표에서 블록을 선택해 수정하고 새 일정을 추가한다", async () => {
    renderRoute("/trips/tokyo-2026-11/itinerary");

    const timetable = await screen.findByRole("region", { name: "A안 전체 시간표" });
    fireEvent.click(within(timetable).getByRole("button", { name: /^나리타 공항 도착 ·/ }));
    const editForm = screen.getByRole("form", { name: "일정 수정" });
    fireEvent.change(within(editForm).getByRole("textbox", { name: "일정 제목" }), {
      target: { value: "나리타 입국 완료" },
    });
    fireEvent.click(within(editForm).getByRole("button", { name: "일정 저장" }));

    expect(
      await within(timetable).findByRole("button", { name: /^나리타 입국 완료 ·/ }),
    ).toBeInTheDocument();
    await openDetails();
    expect(
      within(screen.getByRole("region", { name: /1일차 일정/ })).getByText("나리타 입국 완료"),
    ).toBeInTheDocument();
    closeDetails();

    fireEvent.click(within(editForm).getByRole("button", { name: "새 일정 작성" }));
    const addForm = screen.getByRole("form", { name: "새 일정 추가" });
    fireEvent.change(within(addForm).getByLabelText("날짜"), {
      target: { value: "2026-11-27" },
    });
    fireEvent.change(within(addForm).getByLabelText("일정 제목"), {
      target: { value: "팀 저녁 회의" },
    });
    fireEvent.change(within(addForm).getByLabelText("시작"), { target: { value: "19:00" } });
    fireEvent.change(within(addForm).getByLabelText("종료"), { target: { value: "20:00" } });
    fireEvent.click(within(addForm).getByRole("button", { name: "새 일정 추가" }));

    expect(
      await within(timetable).findByRole("button", { name: /^팀 저녁 회의 ·/ }),
    ).toBeInTheDocument();
    expect(await screen.findByText("새 일정이 추가됐습니다.")).toBeInTheDocument();
  });

  it("B안 전환과 장소 연결이 시간표·선택 날짜 지도·일차 목록에 함께 반영된다", async () => {
    renderRoute("/trips/tokyo-2026-11/itinerary");
    await screen.findByRole("region", { name: "A안 전체 시간표" });
    const drawer = await openDetails();
    expect(screen.getByLabelText(/1일차 1번, 나리타 공항 도착/)).toBeInTheDocument();
    fireEvent.change(within(drawer).getByRole("combobox", { name: "동선 계획안" }), {
      target: { value: "B" },
    });
    expect(screen.queryByLabelText(/1일차 1번, 나리타 공항 도착/)).not.toBeInTheDocument();
    closeDetails();
    const form = screen.getByRole("form", { name: "새 일정 추가" });
    fireEvent.change(within(form).getByLabelText("일정 제목"), { target: { value: "B안 센소지" } });
    fireEvent.change(within(form).getByLabelText("유형"), { target: { value: "activity" } });
    const place = within(form).getByRole("option", { name: "센소지" }) as HTMLOptionElement;
    fireEvent.change(within(form).getByLabelText("장소"), { target: { value: place.value } });
    fireEvent.click(within(form).getByRole("button", { name: "새 일정 추가" }));
    const bTimetable = screen.getByRole("region", { name: "B안 전체 시간표" });
    expect(await within(bTimetable).findByRole("button", { name: /^B안 센소지 ·/ })).toHaveClass(
      "schedule-color--activity",
    );
    const reopened = await openDetails();
    expect(screen.getByLabelText(/1일차 1번, B안 센소지/)).toBeInTheDocument();
    const timeline = screen.getByRole("region", { name: /1일차 일정/ });
    expect(within(timeline).getByText("B안 센소지")).toBeInTheDocument();
    expect(within(timeline).queryByText("나리타 공항 도착")).not.toBeInTheDocument();
    fireEvent.change(within(reopened).getByRole("combobox", { name: "동선 계획안" }), {
      target: { value: "A" },
    });
    expect(screen.getByLabelText(/1일차 1번, 나리타 공항 도착/)).toBeInTheDocument();
    expect(within(timeline).queryByText("B안 센소지")).not.toBeInTheDocument();
    closeDetails();
    expect(screen.getByRole("button", { name: "A안" })).toHaveAttribute("aria-pressed", "true");
    expect(screen.getByRole("region", { name: "A안 전체 시간표" })).toBeInTheDocument();
  });

  it("영수증은 비용의 하위 화면으로 내비게이션에 표시한다", async () => {
    renderRoute("/trips/tokyo-2026-11/receipts");

    expect(await screen.findByRole("heading", { level: 1, name: "영수증" })).toBeInTheDocument();
    expect(screen.getByRole("link", { name: "비용" })).toHaveClass("is-active");
    expect(screen.getByRole("link", { name: "비용" })).toHaveAttribute("aria-current", "page");
  });

  it("provider가 전달할 여행·세션·동기화 정보를 표시한다", () => {
    render(
      <MemoryRouter initialEntries={["/trips/custom/itinerary"]}>
        <Routes>
          <Route
            path="/trips/:tripId"
            element={
              <TripShell
                tripTitle="테스트 여행"
                syncLabel="모든 변경사항이 저장됐어요"
                sessionLabel="익명 uid: test-user"
              />
            }
          >
            <Route path="itinerary" element={<p>테스트 본문</p>} />
          </Route>
        </Routes>
      </MemoryRouter>,
    );

    expect(screen.getByText("테스트 여행")).toBeInTheDocument();
    expect(screen.getByText("모든 변경사항이 저장됐어요")).toBeInTheDocument();
    expect(screen.getByText("익명 uid: test-user")).toBeInTheDocument();
    expect(screen.getByText("테스트 본문")).toBeInTheDocument();
  });
});
