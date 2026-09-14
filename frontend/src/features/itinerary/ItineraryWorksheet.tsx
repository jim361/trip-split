import { useRef, useState, type FormEvent } from "react";

import { usePlatformServices } from "../../app/providers";
import type { AppError } from "../../shared/contracts";
import type { ItineraryCategory, ItineraryItem, ItineraryPlanId, Place } from "../../shared/types";
import { layoutDayItems } from "./timetableLayout";

const categories: Record<ItineraryCategory, string> = {
  flight: "항공",
  transport: "이동",
  meal: "식사",
  activity: "관광·활동",
  stay: "숙박·휴식",
  other: "기타",
};
const dateFormatter = new Intl.DateTimeFormat("ko-KR", {
  month: "numeric",
  day: "numeric",
  weekday: "short",
  timeZone: "UTC",
});
const formatDate = (date: string) => dateFormatter.format(new Date(`${date}T00:00:00Z`));
const formatHour = (hour: number) => `${String(hour).padStart(2, "0")}:00`;

type ScheduleDraft = {
  date: string;
  startTime: string;
  endTime: string;
  title: string;
  placeId: string;
  category: ItineraryCategory;
  memo: string;
};
type Editor = { itemId?: string; draft?: ScheduleDraft; message?: string; error?: boolean };
type ItineraryWorksheetProps = {
  tripId: string;
  startDate?: string;
  endDate?: string;
  selectedDate?: string;
  dates: string[];
  planId: ItineraryPlanId;
  items: ItineraryItem[];
  places: Place[];
  onSelectDate(date: string): void;
  onSelectPlan(plan: ItineraryPlanId): void;
};

function toDraft(item?: ItineraryItem, date = ""): ScheduleDraft {
  return {
    date: item?.date ?? date,
    startTime: item ? (item.startTime ?? "") : "09:00",
    endTime: item ? (item.endTime ?? "") : "10:00",
    title: item?.title ?? "",
    placeId: item?.placeId ?? "",
    category: item?.category ?? "other",
    memo: item?.memo ?? "",
  };
}

function validateDraft(draft: ScheduleDraft, startDate?: string, endDate?: string) {
  if (!/^\d{4}-\d{2}-\d{2}$/.test(draft.date)) return "날짜를 확인해 주세요.";
  if (startDate && draft.date < startDate) return "여행 시작일 이후 날짜를 선택해 주세요.";
  if (endDate && draft.date > endDate) return "여행 종료일 이전 날짜를 선택해 주세요.";
  if (!draft.title.trim()) return "일정 제목을 입력해 주세요.";
  const timePattern = /^([01]\d|2[0-3]):[0-5]\d$/;
  if (draft.startTime && !timePattern.test(draft.startTime)) return "시작 시간을 확인해 주세요.";
  if (draft.endTime && !timePattern.test(draft.endTime)) return "종료 시간을 확인해 주세요.";
  if (!draft.startTime && draft.endTime) return "시작 시간을 먼저 입력해 주세요.";
  if (draft.startTime && draft.endTime && draft.startTime >= draft.endTime) {
    return "종료 시간은 시작 시간보다 늦어야 합니다. 자정을 넘는 일정은 날짜별로 나누어 주세요.";
  }
  return null;
}

export function ItineraryWorksheet({
  tripId,
  startDate,
  endDate,
  selectedDate,
  dates,
  planId,
  items,
  places,
  onSelectDate,
  onSelectPlan,
}: ItineraryWorksheetProps) {
  const { repositories } = usePlatformServices();
  const [editors, setEditors] = useState<Record<ItineraryPlanId, Editor>>({ A: {}, B: {} });
  const [busy, setBusy] = useState<"save" | "delete" | null>(null);
  const [hours, setHours] = useState({ start: 6, end: 24 });
  const formRef = useRef<HTMLFormElement>(null);
  const planItems = items.filter((item) => (item.planId ?? "A") === planId);
  const editor = editors[planId];
  const editingItem = planItems.find((item) => item.id === editor.itemId);
  const values = editor.draft ?? toDraft(editingItem, selectedDate ?? startDate ?? dates[0]);
  const hasUnsavedChanges = Boolean(
    editor.draft &&
    JSON.stringify(editor.draft) !==
      JSON.stringify(toDraft(editingItem, selectedDate ?? startDate ?? dates[0])),
  );
  const missingItem = Boolean(editor.itemId && !editingItem);
  const layouts = dates.map((date) => ({
    date,
    ...layoutDayItems(planItems.filter((item) => item.date === date)),
  }));
  const untimed = layouts.flatMap((day) => day.untimed);
  const outsideCount = layouts.reduce(
    (count, day) =>
      count +
      day.timed.filter(
        (entry) => entry.startMinute < hours.start * 60 || entry.endMinute > hours.end * 60,
      ).length,
    0,
  );
  const height = (hours.end - hours.start) * 24;
  const placeById = new Map(places.map((place) => [place.id, place]));
  const setEditor = (next: Editor) => setEditors((current) => ({ ...current, [planId]: next }));
  const update = <Key extends keyof ScheduleDraft>(key: Key, value: ScheduleDraft[Key]) => {
    setEditor({ ...editor, draft: { ...values, [key]: value }, message: undefined, error: false });
  };
  const selectItem = (item: ItineraryItem) => {
    if (busy) return;
    if (editor.itemId !== item.id) {
      if (
        hasUnsavedChanges &&
        !window.confirm("저장하지 않은 변경사항을 버리고 다른 일정을 선택할까요?")
      )
        return;
      setEditor({ itemId: item.id });
    }
    onSelectDate(item.date);
    formRef.current?.scrollIntoView?.({ behavior: "auto", block: "nearest" });
  };
  const startNew = () => {
    if (
      hasUnsavedChanges &&
      !window.confirm("저장하지 않은 변경사항을 버리고 새 일정을 작성할까요?")
    )
      return;
    setEditor({});
  };
  const moveToEditor = () => {
    if (busy) return;
    formRef.current?.scrollIntoView?.({ behavior: "auto", block: "start" });
    formRef.current
      ?.querySelector<HTMLInputElement>('input[name="title"]')
      ?.focus({ preventScroll: true });
  };
  const labelFor = (item: ItineraryItem) =>
    [
      item.title,
      formatDate(item.date),
      item.startTime ? `${item.startTime}–${item.endTime || "종료 미정"}` : "시간 미정",
      categories[item.category ?? "other"],
      item.placeId ? placeById.get(item.placeId)?.name : "",
    ]
      .filter(Boolean)
      .join(" · ");

  const save = async (event: FormEvent<HTMLFormElement>) => {
    event.preventDefault();
    const problem = missingItem
      ? "삭제된 일정입니다. 새 일정 작성으로 전환해 주세요."
      : validateDraft(values, startDate, endDate);
    if (problem) {
      setEditor({ ...editor, draft: values, message: problem, error: true });
      return;
    }
    const order =
      planItems
        .filter((item) => item.date === values.date && item.id !== editor.itemId)
        .reduce((highest, item) => Math.max(highest, item.order), -1) + 1;
    setBusy("save");
    setEditor({ ...editor, draft: values });
    try {
      const shared = {
        date: values.date,
        title: values.title.trim(),
        planId,
        category: values.category,
      };
      if (editingItem) {
        await repositories.itinerary.updateItineraryItem(tripId, editingItem.id, {
          ...shared,
          startTime: values.startTime || null,
          endTime: values.endTime || null,
          placeId: values.placeId || null,
          memo: values.memo.trim() || null,
          ...(editingItem.date !== values.date ? { order } : {}),
        });
      } else {
        await repositories.itinerary.createItineraryItem(tripId, {
          ...shared,
          startTime: values.startTime || undefined,
          endTime: values.endTime || undefined,
          placeId: values.placeId || undefined,
          memo: values.memo.trim() || undefined,
          order,
        });
      }
      const [hour, minute] = values.startTime.split(":").map(Number);
      const [endHour, endMinute] = values.endTime.split(":").map(Number);
      if (values.startTime)
        setHours((current) => ({
          start: Math.min(current.start, hour),
          end: Math.max(
            current.end,
            values.endTime
              ? Math.min(endHour + (endMinute > 0 ? 1 : 0), 24)
              : Math.min(Math.ceil((hour * 60 + minute + 30) / 60), 24),
          ),
        }));
      onSelectDate(values.date);
      setEditor(
        editingItem
          ? { itemId: editingItem.id, message: "저장됨" }
          : {
              draft: toDraft(undefined, values.date),
              message: "새 일정이 추가됐습니다.",
            },
      );
    } catch (error) {
      setEditor({
        ...editor,
        draft: values,
        message: (error as AppError).message ?? "일정을 저장하지 못했습니다.",
        error: true,
      });
    } finally {
      setBusy(null);
    }
  };
  const remove = async () => {
    if (!editingItem || !window.confirm(`“${editingItem.title}” 일정을 삭제할까요?`)) return;
    setBusy("delete");
    try {
      await repositories.itinerary.deleteItineraryItem(tripId, editingItem.id);
      setEditor({ message: "일정을 삭제했습니다." });
    } catch (error) {
      setEditor({
        ...editor,
        draft: values,
        message: (error as AppError).message ?? "일정을 삭제하지 못했습니다.",
        error: true,
      });
    } finally {
      setBusy(null);
    }
  };

  return (
    <section className="trip-planner" aria-labelledby="trip-planner-title">
      <h2 id="trip-planner-title" className="visually-hidden">
        여행 시간표
      </h2>
      <header className="trip-planner__header">
        <div className="trip-planner__plans" role="group" aria-label="계획안 선택">
          {(["A", "B"] as const).map((plan) => (
            <button
              key={plan}
              type="button"
              aria-pressed={planId === plan}
              disabled={busy !== null}
              onClick={() => onSelectPlan(plan)}
            >
              {plan}안
            </button>
          ))}
        </div>
        <div className="trip-planner__settings">
          <label>
            표시 시작
            <select
              aria-label="표시 시작"
              value={hours.start}
              onChange={(event) => {
                const start = Number(event.target.value);
                setHours({ start, end: Math.max(hours.end, start + 1) });
              }}
            >
              {Array.from({ length: 24 }, (_, hour) => (
                <option key={hour} value={hour}>
                  {formatHour(hour)}
                </option>
              ))}
            </select>
          </label>
          <label>
            표시 종료
            <select
              aria-label="표시 종료"
              value={hours.end}
              onChange={(event) => {
                const end = Number(event.target.value);
                setHours({ start: Math.min(hours.start, end - 1), end });
              }}
            >
              {Array.from({ length: 24 }, (_, index) => index + 1).map((hour) => (
                <option key={hour} value={hour}>
                  {formatHour(hour)}
                </option>
              ))}
            </select>
          </label>
        </div>
        <p className="trip-planner__summary">
          {dates.length}일 · {planItems.length}개 일정
        </p>
        <button
          className="button button--primary trip-planner__editor-link"
          type="button"
          aria-label={editor.itemId ? "일정 수정으로 이동" : "새 일정 추가로 이동"}
          disabled={busy !== null}
          onClick={moveToEditor}
        >
          일정 입력
        </button>
      </header>
      <div className="trip-planner__legend" aria-label="일정 유형별 색상">
        {Object.entries(categories).map(([category, label]) => (
          <span key={category}>
            <i aria-hidden="true" className={`schedule-color schedule-color--${category}`} />
            {label}
          </span>
        ))}
      </div>
      {outsideCount ? (
        <p className="trip-planner__notice">
          표시 시간 밖에 걸친 일정 {outsideCount}개
          <button type="button" onClick={() => setHours({ start: 0, end: 24 })}>
            24시간 보기
          </button>
        </p>
      ) : null}
      {!planItems.length ? (
        <p className="trip-planner__empty">
          {planId}안이 비어 있어요. 아래에서 첫 일정을 추가해 보세요.
        </p>
      ) : null}
      <div
        className="trip-planner__scroll"
        role="region"
        aria-label={`${planId}안 전체 시간표`}
        tabIndex={0}
      >
        <div
          className="time-grid"
          style={{
            gridTemplateColumns: `56px repeat(${dates.length}, minmax(128px, 1fr))`,
            minWidth: 56 + dates.length * 128,
          }}
        >
          <div className="time-grid__corner">시간</div>
          <div
            className="time-grid__dates"
            role="group"
            aria-label="여행 날짜 선택"
            style={{ gridTemplateColumns: `repeat(${dates.length}, minmax(128px, 1fr))` }}
          >
            {dates.map((date, index) => (
              <button
                key={date}
                type="button"
                aria-pressed={date === selectedDate}
                disabled={busy !== null}
                onClick={() => onSelectDate(date)}
              >
                <strong>{index + 1}일차</strong>
                <span>{formatDate(date)}</span>
              </button>
            ))}
          </div>
          <div className="time-grid__hours" style={{ height }} aria-hidden="true">
            {Array.from({ length: hours.end - hours.start }, (_, index) => (
              <span key={index} style={{ top: index * 24 }}>
                {formatHour(hours.start + index)}
              </span>
            ))}
          </div>
          {layouts.map((day) => (
            <div key={day.date} className="time-grid__day" style={{ height }}>
              {day.timed
                .filter(
                  (entry) =>
                    entry.endMinute > hours.start * 60 && entry.startMinute < hours.end * 60,
                )
                .map((entry) => {
                  const eventHeight =
                    (Math.min(entry.endMinute, hours.end * 60) -
                      Math.max(entry.startMinute, hours.start * 60)) *
                    0.4;
                  return (
                    <button
                      key={entry.item.id}
                      type="button"
                      disabled={busy !== null}
                      className={`time-grid__event schedule-color--${entry.item.category ?? "other"}${editor.itemId === entry.item.id ? " is-editing" : ""}`}
                      style={{
                        top:
                          (Math.max(entry.startMinute, hours.start * 60) - hours.start * 60) * 0.4,
                        height: eventHeight,
                        left: `${(entry.lane / entry.laneCount) * 100}%`,
                        width: `${100 / entry.laneCount}%`,
                      }}
                      aria-label={labelFor(entry.item)}
                      title={labelFor(entry.item)}
                      onClick={() => selectItem(entry.item)}
                    >
                      <strong>{entry.item.title}</strong>
                      {eventHeight >= 24 ? (
                        <span>
                          {entry.item.startTime}–{entry.item.endTime || "미정"}
                        </span>
                      ) : null}
                      {eventHeight >= 38 ? (
                        <span>{categories[entry.item.category ?? "other"]}</span>
                      ) : null}
                    </button>
                  );
                })}
            </div>
          ))}
        </div>
      </div>
      {untimed.length ? (
        <div className="trip-planner__untimed" role="group" aria-label="시간 미정 일정">
          <h3>시간 미정</h3>
          {untimed.map((item) => (
            <button
              key={item.id}
              type="button"
              disabled={busy !== null}
              onClick={() => selectItem(item)}
            >
              {labelFor(item)}
            </button>
          ))}
        </div>
      ) : null}
      <details className="trip-planner__accessible-list">
        <summary>
          선택 날짜 일정 전체 보기 · {selectedDate ? formatDate(selectedDate) : "날짜 미정"}
        </summary>
        {planItems
          .filter((item) => item.date === selectedDate)
          .map((item) => (
            <button
              key={item.id}
              type="button"
              disabled={busy !== null}
              onClick={() => selectItem(item)}
            >
              {labelFor(item)}
            </button>
          ))}
      </details>
      <form
        ref={formRef}
        className="schedule-editor"
        aria-label={editor.itemId ? "일정 수정" : "새 일정 추가"}
        onSubmit={save}
      >
        <header>
          <div>
            <p className="eyebrow">
              {planId} / {editor.itemId ? "EDIT SCHEDULE" : "NEW SCHEDULE"}
            </p>
            <h3>{editor.itemId ? "일정 수정" : "새 일정 추가"}</h3>
          </div>
          <p>날짜와 시간을 입력하면 유형에 맞는 색상으로 시간표에 표시됩니다.</p>
        </header>
        <div className="schedule-editor__fields">
          <label className="schedule-editor__date">
            <span>날짜</span>
            <input
              type="date"
              min={startDate}
              max={endDate}
              value={values.date}
              disabled={busy !== null}
              required
              onChange={(event) => update("date", event.target.value)}
            />
          </label>
          <label>
            <span>시작</span>
            <input
              type="time"
              value={values.startTime}
              disabled={busy !== null}
              onChange={(event) => update("startTime", event.target.value)}
            />
          </label>
          <label>
            <span>종료</span>
            <input
              type="time"
              value={values.endTime}
              disabled={busy !== null}
              onChange={(event) => update("endTime", event.target.value)}
            />
          </label>
          <label className="schedule-editor__category">
            <span>유형</span>
            <select
              value={values.category}
              disabled={busy !== null}
              onChange={(event) => update("category", event.target.value as ItineraryCategory)}
            >
              {Object.entries(categories).map(([category, label]) => (
                <option key={category} value={category}>
                  {label}
                </option>
              ))}
            </select>
          </label>
          <label className="schedule-editor__title">
            <span>일정 제목</span>
            <input
              name="title"
              value={values.title}
              disabled={busy !== null}
              maxLength={160}
              required
              placeholder="일정 제목을 입력하세요"
              onChange={(event) => update("title", event.target.value)}
            />
          </label>
          <label className="schedule-editor__place">
            <span>장소</span>
            <select
              value={values.placeId}
              disabled={busy !== null}
              onChange={(event) => update("placeId", event.target.value)}
            >
              <option value="">장소 없음</option>
              {places.map((place) => (
                <option key={place.id} value={place.id}>
                  {place.name}
                </option>
              ))}
            </select>
          </label>
          <label className="schedule-editor__memo">
            <span>메모</span>
            <input
              value={values.memo}
              disabled={busy !== null}
              maxLength={500}
              placeholder="선택 메모"
              onChange={(event) => update("memo", event.target.value)}
            />
          </label>
        </div>
        <div className="schedule-editor__actions">
          <button className="button button--primary" disabled={busy !== null || missingItem}>
            {busy === "save" ? "저장 중…" : editor.itemId ? "일정 저장" : "새 일정 추가"}
          </button>
          {editor.itemId ? (
            <>
              <button
                type="button"
                className="button button--quiet"
                disabled={busy !== null}
                onClick={startNew}
              >
                새 일정 작성
              </button>
              <button
                type="button"
                className="button button--quiet"
                disabled={busy !== null || missingItem}
                onClick={() => void remove()}
              >
                {busy === "delete" ? "삭제 중…" : "일정 삭제"}
              </button>
            </>
          ) : null}
        </div>
        {missingItem ? (
          <p className="schedule-editor__message" role="alert">
            삭제된 일정입니다. 새 일정 작성으로 전환해 주세요.
          </p>
        ) : null}
        {editor.message ? (
          <p className="schedule-editor__message" role={editor.error ? "alert" : "status"}>
            {editor.message}
          </p>
        ) : null}
      </form>
    </section>
  );
}
