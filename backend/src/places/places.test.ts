import { expect, it } from "vitest";
import { googleLinkQuery, searchDemoPlaces } from "./places";

it("검색은 후보/빈 결과를 구분하고 URL은 허용된 Google 검색 형식만 해석한다", () => {
  expect(searchDemoPlaces("우에노")).toHaveLength(2);
  expect(searchDemoPlaces("없는 장소")).toEqual([]);
  expect(googleLinkQuery("https://maps.google.com/?q=Ueno+Station")).toBe("Ueno Station");
  expect(googleLinkQuery("https://www.google.com/maps/search/?api=1&query=우에노")).toBe("우에노");
  for (const url of [
    "http://maps.google.com/?q=a",
    "https://maps.google.com.evil.test/?q=a",
    "https://127.0.0.1/?q=a",
    "https://user@maps.google.com/?q=a",
    "https://maps.app.goo.gl/short",
    "https://www.google.com/search?q=a",
    "https://maps.google.com:8080/?q=a",
  ]) {
    expect(() => googleLinkQuery(url)).toThrow();
  }
});
