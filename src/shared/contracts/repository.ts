import type { AppError } from "./error";

export type Unsubscribe = () => void;
export type OnData<T> = (value: T) => void;
export type OnError = (error: AppError) => void;
