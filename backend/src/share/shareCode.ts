import { randomInt } from "node:crypto";

import { getShareCodeLength } from "../shared/env";

const SHARE_CODE_ALPHABET = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789";

export function normalizeShareCode(code: string): string {
  return code.replace(/[\s-]/g, "").toUpperCase();
}

export function generateShareCode(length = getShareCodeLength()): string {
  let code = "";

  for (let index = 0; index < length; index += 1) {
    code += SHARE_CODE_ALPHABET[randomInt(SHARE_CODE_ALPHABET.length)];
  }

  return code;
}

export function isValidShareCode(code: string): boolean {
  const normalized = normalizeShareCode(code);
  return (
    normalized.length >= 6 &&
    normalized.length <= 12 &&
    [...normalized].every((character) => SHARE_CODE_ALPHABET.includes(character))
  );
}
