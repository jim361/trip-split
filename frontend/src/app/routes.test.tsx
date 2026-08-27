import { cleanup, fireEvent, render, screen, within } from "@testing-library/react";
import { MemoryRouter, Route, Routes } from "react-router-dom";
import { afterEach, describe, expect, it, vi } from "vitest";

import { TripShell } from "../pages/trip/TripShell";
import { MockTripSessionService } from "../services/functions/tripSessionService";
import { AuthProvider, PlatformServicesProvider } from "./providers";
import { AppRoutes } from "./routes";

afterEach(() => {
  cleanup();
  vi.restoreAllMocks();
});

function renderRoute(path: string) {
  return render(
    <MemoryRouter initialEntries={[path]}>
      <PlatformServicesProvider>
        <AuthProvider>
          <AppRoutes />
        </AuthProvider>
      </PlatformServicesProvider>
    </MemoryRouter>,
  );
}

describe("여행 라우트", () => {
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
    const links = within(navigation).getAllByRole("link");

    expect(links.map((link) => link.textContent)).toEqual(["일정·지도", "준비", "비용"]);

    fireEvent.click(screen.getByRole("link", { name: "준비" }));
    expect(await screen.findByRole("heading", { level: 1, name: "준비" })).toBeInTheDocument();

    fireEvent.click(screen.getByRole("link", { name: "비용" }));
    expect(await screen.findByRole("heading", { level: 1, name: "비용" })).toBeInTheDocument();
  });

  it("일정 위에 지도를 표시하고 확대 상태를 공유 가능한 URL로 전환한다", async () => {
    renderRoute("/trips/gangneung/itinerary");

    const map = await screen.findByRole("region", { name: "오늘의 이동 동선" });
    const timeline = screen.getByRole("region", { name: /1일차 일정/ });
    const expandButton = screen.getByRole("button", { name: "지도 크게 보기" });

    expect(map.compareDocumentPosition(timeline) & Node.DOCUMENT_POSITION_FOLLOWING).toBeTruthy();
    expect(expandButton).toHaveAttribute("aria-expanded", "false");
    expect(screen.getByLabelText(/강릉 1박 2일 여행 동선 지도/)).toHaveTextContent("1");

    fireEvent.click(expandButton);
    expect(screen.getByRole("button", { name: "지도 작게 보기" })).toHaveAttribute(
      "aria-expanded",
      "true",
    );
  });

  it("기존 지도 URL은 확대된 통합 일정 화면으로 연결한다", async () => {
    renderRoute("/trips/gangneung/map");

    expect(await screen.findByRole("heading", { level: 1, name: "일정·지도" })).toBeInTheDocument();
    expect(screen.getByRole("button", { name: "지도 작게 보기" })).toHaveAttribute(
      "aria-expanded",
      "true",
    );
    expect(screen.getByRole("link", { name: "일정·지도" })).toHaveAttribute("aria-current", "page");
  });

  it("도쿄 해외여행을 만들 때 입력한 인원을 정산 대상으로 준비한다", async () => {
    const createTrip = vi.spyOn(MockTripSessionService.prototype, "createTrip");
    renderRoute("/");

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
        regionType: "international",
        currency: "JPY",
        participantCount: 4,
      }),
    );
    expect(await screen.findByText("우리 도쿄 여행")).toBeInTheDocument();
    fireEvent.click(screen.getByRole("link", { name: "비용" }));
    expect(
      await screen.findByRole("heading", { level: 2, name: "정산 인원 4명" }),
    ).toBeInTheDocument();
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
    expect(screen.getByLabelText(/도쿄 여행 동선 지도/)).toHaveTextContent("1");
    expect(screen.getByRole("link", { name: "Google Maps에서 열기 ↗" })).toHaveAttribute(
      "href",
      expect.stringContaining("google.com/maps/dir"),
    );

    fireEvent.click(screen.getByRole("button", { name: /2일차.*11\. 26/ }));
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
