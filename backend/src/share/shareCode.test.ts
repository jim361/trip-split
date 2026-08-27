import { describe, expect, it } from "vitest";

import { generateShareCode, isValidShareCode, normalizeShareCode } from "./shareCode";

describe("share code", () => {
  it("혼동하기 쉬운 문자를 제외한 8자리 코드를 생성한다", () => {
    const code = generateShareCode(8);

    expect(code).toHaveLength(8);
    expect(isValidShareCode(code)).toBe(true);
    expect(code).not.toMatch(/[01IO]/);
  });

  it("공백과 하이픈을 제거하고 대문자로 정규화한다", () => {
    expect(normalizeShareCode(" abcd-efgh ")).toBe("ABCDEFGH");
  });
});
