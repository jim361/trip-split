import { cleanup, fireEvent, render, screen, within } from "@testing-library/react";
import { MemoryRouter, Route, Routes } from "react-router-dom";
import { afterEach, describe, expect, it } from "vitest";

import { TripShell } from "../pages/trip/TripShell";
import { AuthProvider, PlatformServicesProvider } from "./providers";
import { AppRoutes } from "./routes";

afterEach(cleanup);

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

    expect(await screen.findByRole("heading", { level: 1, name: "일정" })).toBeInTheDocument();
    expect(screen.getByRole("link", { name: "일정·지도" })).toHaveAttribute("aria-current", "page");
  });

  it("세 메뉴를 같은 순서로 제공하고 각 placeholder로 이동한다", async () => {
    renderRoute("/trips/gangneung/itinerary");

    const navigation = screen.getByRole("navigation", {
      name: "여행 주요 메뉴",
    });
    const links = within(navigation).getAllByRole("link");

    expect(links.map((link) => link.textContent)).toEqual(["일정·지도", "정산", "영수증"]);

    fireEvent.click(screen.getByRole("link", { name: "정산" }));
    expect(await screen.findByRole("heading", { level: 1, name: "정산" })).toBeInTheDocument();

    fireEvent.click(screen.getByRole("link", { name: "영수증" }));
    expect(await screen.findByRole("heading", { level: 1, name: "영수증" })).toBeInTheDocument();
  });

  it("일정 위에 지도를 표시하고 확대 상태를 공유 가능한 URL로 전환한다", async () => {
    renderRoute("/trips/gangneung/itinerary");

    const map = await screen.findByRole("region", { name: "여행 동선" });
    const timeline = screen.getByRole("region", { name: "시간표" });
    const expandButton = screen.getByRole("button", { name: "지도 크게 보기" });

    expect(map.compareDocumentPosition(timeline) & Node.DOCUMENT_POSITION_FOLLOWING).toBeTruthy();
    expect(expandButton).toHaveAttribute("aria-expanded", "false");
    expect(screen.getByLabelText(/강릉 여행 동선 지도/)).toHaveTextContent("1");

    fireEvent.click(expandButton);
    expect(screen.getByRole("button", { name: "지도 작게 보기" })).toHaveAttribute(
      "aria-expanded",
      "true",
    );
  });

  it("기존 지도 URL은 확대된 통합 일정 화면으로 연결한다", async () => {
    renderRoute("/trips/gangneung/map");

    expect(await screen.findByRole("heading", { level: 1, name: "일정" })).toBeInTheDocument();
    expect(screen.getByRole("button", { name: "지도 작게 보기" })).toHaveAttribute(
      "aria-expanded",
      "true",
    );
    expect(screen.getByRole("link", { name: "일정·지도" })).toHaveAttribute("aria-current", "page");
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
