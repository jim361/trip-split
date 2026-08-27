import { httpsCallable } from "firebase/functions";

import type { ParsedReceipt } from "../../shared/types";
import { getFirebaseClient } from "../firebase/client";
import { mapFirebaseError } from "../firebase/errorMapper";

export type ParseReceiptRequest = {
  tripId: string;
  imageBase64: string;
  mimeType: string;
};

export interface ReceiptParser {
  parseReceipt(input: ParseReceiptRequest): Promise<ParsedReceipt>;
}

/**
 * CLOVA 호출 구현은 정산·영수증 담당 영역입니다. 이 어댑터는 callable 계약만 고정합니다.
 */
export class CallableReceiptParser implements ReceiptParser {
  async parseReceipt(input: ParseReceiptRequest): Promise<ParsedReceipt> {
    try {
      const callable = httpsCallable<ParseReceiptRequest, ParsedReceipt>(
        getFirebaseClient().functions,
        "parseReceipt",
      );
      return (await callable(input)).data;
    } catch (error) {
      throw mapFirebaseError(error);
    }
  }
}
