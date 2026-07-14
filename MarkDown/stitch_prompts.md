# Trip Split Stitch Prompts

This document contains ready-to-use prompts for generating frontend mockups in Stitch.

> **2026-07-14 product update:** The itinerary and map are now one primary destination. Use exactly three primary destinations — `일정·지도`, `정산`, `영수증`. Put a compact expandable map above the itinerary. Treat any later instruction for four destinations or a standalone map screen as archived guidance.

Use English for all design instructions. Keep the actual UI labels, button text, sample data, and visible screen copy in Korean.

## 0. How To Use

Start with the `Master Style Prompt`, then generate each screen with the matching screen prompt. For responsive app screens, generate a 390px mobile state first and a desktop expansion second while preserving the same navigation and content hierarchy.

If Stitch produces something too much like a marketing page, add this sentence to the screen prompt:

```text
Do not make this a marketing landing page. Make it a usable app screen.
```

## 1. Master Style Prompt

Use this first to establish the overall visual language.

```text
Create a high-fidelity responsive web/PWA interface for a Korean domestic travel planning app called "Trip Split".

Write the prompt interpretation, layout, and design reasoning in English, but all visible UI copy in the generated screen must be Korean.

The product is a collaborative trip planner that connects places, a daily timeline, a map route visualization, receipt OCR, personal spending, and expense settlement. It is not a marketing landing page. It must feel like a dense but clear app used before, during, and after a trip.

Backend and collaboration concept:
- The app starts without a visible login wall.
- Internally it uses Firebase anonymous user sessions.
- Users can optionally connect Google to keep their trip list.
- Share codes and invite links let friends join the same real-time trip session.

Design direction:
- Design mobile-first for a 390px-wide PWA, then progressively expand the same information architecture for desktop.
- Airbnb-inspired travel product style, but more tool-like and practical.
- Warm, bright, clean, friendly, Korean travel app feeling.
- White background, light gray surfaces, thin borders, rounded controls.
- Primary coral accent #FF385C.
- Text color #222222, muted text #717171, border #DDDDDD, surface #F7F7F7.
- Use Pretendard or system sans-serif style typography.
- Use compact cards, lists, sticky summaries, bottom sheets, and side panels. Avoid huge hero sections.
- Use Korean UI labels.
- Use clear app controls: tabs, segmented controls, search fields, place cards, timetable rows, map pins, expense rows, upload areas, dialogs.
- Keep the same three primary destinations in this exact order on every viewport: "일정·지도", "정산", "영수증". Use a persistent bottom navigation on mobile and an expanded equivalent on desktop.
- "장소 보관함" is not a fourth primary destination. Show it inside the combined itinerary-map workspace.
- Put a compact expandable map above the mobile vertical timeline. On desktop, keep the map full-width above the date list, timeline, and place library columns.
- Mobile settlement content order is personal summary, final settlement, then expense list. Desktop expands expense management and settlement results into multiple columns.
- Clearly separate the concepts "내가 결제한 금액", "내가 부담한 금액", and "받을 금액" or "보낼 금액".
- Avoid dark dashboards, purple gradients, decorative blobs, overly abstract illustrations, and heavy marketing copy.

The main product objects are:
- Trip
- Trip member
- Participant
- Place
- Itinerary item
- Map pin
- Expense
- Receipt item
- Editable receipt OCR draft
- Share code
- Realtime sync status
- Optional Google account connection

Use sample trip data for Gangneung, Korea:
- Trip title: 강릉 1박 2일 여행
- Dates: 7월 3일 - 7월 4일
- Places: 테라로사 커피공장 강릉본점, 형제칼국수, 안목해변, 경포 그곳에가면펜션, 강릉중앙시장, 대관령양떼목장
- Participants: 나, 민수, 지연, 도윤
- Item split example: "순두부 12,000원 · 나", "커피 6,000원 · 지연", "감자전 15,000원 · 나, 민수, 지연 균등"
- Whole-expense split example: "숙소 180,000원 · 4명 균등"
```

## 2. Home And Trip Entry

Use this for the first app entry screen. It should support creating a trip and joining with a share code.

```text
Design the home screen for "Trip Split", a Korean travel planning and expense splitting web/PWA.

All visible UI copy must be Korean.

This is an app entry screen, not a marketing landing page.

Layout:
- Top navigation with the Trip Split wordmark on the left and a subtle "도움말" link on the right.
- Main content centered in a max-width app container.
- On mobile, stack create-trip and join-by-code panels in one column.
- On desktop, expand them into create-trip on the left and join-by-code on the right.
- Under the panels, show a "최근 여행" section with 2 compact trip cards.
- Add a small optional Google connection banner. It must not block app usage.

Content:
- Main title: "여행 일정과 정산을 한 번에"
- Supporting text: "장소를 모으고, 시간표를 만들고, 여행 후 정산까지 함께 관리하세요."
- Primary button: "새 여행 만들기"
- Share code input label: "공유 코드로 입장"
- Placeholder: "예: GANGNEUNG24"
- Secondary button: "여행 불러오기"
- Optional account banner text: "Google로 연결하면 내 여행 목록을 안전하게 보관할 수 있어요."
- Banner button: "Google로 연결"

Visual style:
- Airbnb-inspired warm coral accent.
- White background, light gray panels, rounded 12px cards.
- Use small travel-related details, but do not use generic stock illustration as the main focus.
- Make the screen feel ready to use immediately.

Include states:
- Empty recent trip card
- Recent trip card with title "강릉 1박 2일 여행", dates, participant count, and last edited time
```

## 3. Create Trip Screen Or Modal

Use this for the trip creation flow.

```text
Design a create trip screen for the Trip Split app.

All visible UI copy must be Korean.

The user creates a trip without a visible login wall. The app uses an anonymous Firebase session in the background.

Layout:
- A compact page or large modal centered on the screen.
- Header: "새 여행 만들기"
- Form fields:
  - 여행 이름
  - 여행 지역 type segmented control: 국내 여행 selected, 해외 여행 disabled or "나중에"
  - 시작일
  - 종료일
  - 기본 통화: KRW
- Participant quick setup section:
  - Add participant input
  - Participant chips: 나, 민수, 지연, 도윤
- Footer actions:
  - Cancel button "취소"
  - Primary coral button "여행 만들기"

Design details:
- Warm, minimal, Airbnb-inspired.
- Inputs are rounded, clear, and practical.
- Show a short note: "공유 코드로 함께 편집하고, Google로 연결하면 내 여행 목록을 보관할 수 있어요."
- Do not make it look like a marketing form.
```

## 4. Main Trip Workspace

Use this for the main trip detail page, the core product screen.

```text
Design the responsive main workspace for a Korean trip planning PWA called Trip Split.

All visible UI copy must be Korean.

This is the primary app screen for an existing trip: "강릉 1박 2일 여행".

Shared app shell:
- Mobile top bar shows back, trip title, realtime state "동기화됨", and "더보기" only. Put date context inside the active page and move participants, sharing, and account actions into the more sheet.
- Desktop expands the same top bar to show date range "7월 3일 - 7월 4일", participant avatars, and action "공유".
- The three primary destinations are "일정·지도", "정산", "영수증" in that order. The active destination is "일정·지도".
- Do not add "장소 보관함" to primary navigation.

Mobile-first layout at 390px:
- Sticky compact top bar and persistent bottom navigation.
- A day segmented control followed by a single-column vertical timeline.
- Touch-friendly timeline cards with time, place, note, linked expense badge, drag handle, and overflow action.
- Primary floating action "일정 추가".
- A collapsed handle "장소 보관함 열기" opens a draggable bottom sheet with place search, Naver link paste, direct input, and saved place cards.

Desktop expansion:
- Keep the same navigation order in an expanded horizontal app tab treatment.
- Use three productive areas: date list on the left, selected-day timeline in the center, and an expanded "장소 보관함" panel on the right.
- Keep sharing and realtime controls in the top bar; do not create a different desktop information architecture.

Timeline content:
- Day tabs: 1일차, 2일차
- Rows with time, place, note:
  - 08:00 수원 출발
  - 11:00 테라로사 커피공장 강릉본점
  - 12:10 형제칼국수
  - 13:30 안목해변
  - 16:10 경포 그곳에가면펜션
- Each row has a small drag handle, time, place title, memo, and kebab menu.

Place library panel or bottom sheet:
- Search input: "장소 검색 또는 네이버 링크 붙여넣기"
- Button: "장소 추가"
- Place cards with category tags and address.

Design style:
- Bright app workspace, not a landing page.
- Compact rounded cards, thin lines, high readability.
- Coral accent for active tab and primary actions.
- Keep mobile touch targets comfortable while making desktop information dense and scannable.
```

## 5. Place Library Panel And Bottom Sheet

Use this for the embedded place collection feature. It must not become a primary app route.

```text
Design the responsive "장소 보관함" component for Trip Split.

All visible UI copy must be Korean.

Purpose:
Users collect places before placing them into the trip timetable. They can search, paste a Naver place link, or manually add a place.

Navigation rule:
- This is not a main navigation destination.
- On a 390px mobile itinerary or map screen, render it as a draggable bottom sheet with collapsed, half, and full states.
- On desktop, render it as a right-side panel inside the itinerary workspace or a contextual panel inside the map workspace.

Content:
- Header: "장소 보관함"
- Subtitle: "네이버 장소 링크를 붙여넣거나 검색해서 여행 장소를 모아보세요."
- Top input area:
  - Large input: "장소명 또는 네이버 지도 링크"
  - Primary button: "가져오기"
  - Secondary button: "직접 입력"
- Segmented filter:
  - 전체
  - 음식점
  - 카페
  - 숙소
  - 관광
- Place list cards:
  - Place name
  - Category badge
  - Address
  - Source: "네이버 링크"
  - Action button: "일정에 추가"
  - Small memo field or memo preview

Sample cards:
- 테라로사 커피공장 강릉본점 / 카페 / 강원 강릉시 구정면 현천길 7
- 형제칼국수 / 음식점 / 강원 강릉시 강릉대로204번길 2
- 안목해변 / 관광 / 강원 강릉시 창해로14번길
- 경포 그곳에가면펜션 / 숙박 / 강원 강릉시 해안로 381-2

Include fallback state:
- A small warning panel: "링크에서 장소 정보를 가져오지 못했어요. 검색 후보를 선택하거나 직접 입력해 주세요."

Visual style:
- Airbnb-inspired place cards.
- Clean, practical, dense enough for planning.
- Keep sheet drag handle, close action "닫기", and panel collapse action visible without creating a separate page header.
- Do not rely on Naver saved list import.
```

## 6. Itinerary Timetable Screen

Use this for the date-based schedule editor.

```text
Design a detailed itinerary timetable screen for Trip Split.

All visible UI copy must be Korean.

Purpose:
Users create a date-based timetable and connect each time slot to a saved place.

Mobile-first layout at 390px:
- Sticky day segmented control "1일차 7/3", "2일차 7/4".
- A single-column vertical timeline with touch-friendly cards.
- Open "일정 상세" in a bottom sheet and open "장소 보관함" in a separate contextual bottom sheet.
- Floating action "일정 추가".

Desktop expansion:
- Left column: date list.
- Center column: vertical timeline with time blocks.
- Right column: expanded "장소 보관함" with search, Naver link paste, direct input, and saved place cards.
- Open the selected "일정 상세" editor as a drawer, overlay, or inline expansion without replacing the three-column date/timeline/place-library contract.
- Preserve the same content and action order as mobile.

Timetable details:
- Each row has:
  - Time input
  - Place title
  - Note
  - Linked place status
  - Small expense indicator if an expense is connected
- Use a subtle vertical line connecting time blocks.
- Active row has a coral left border or highlight.

Selected item editor:
- Title: "일정 상세"
- Fields:
  - 시간
  - 장소 선택
  - 메모
- Buttons:
  - "저장"
  - "삭제"

Sample rows:
- 08:00 수원 출발 / 이동
- 11:00 테라로사 커피공장 / 커피 한 잔
- 12:10 형제칼국수 / 점심
- 13:30 안목해변 / 산책
- 16:10 경포 그곳에가면펜션 / 체크인

Design:
- Use Cal.com-like clarity for time editing, but keep Airbnb warmth.
- Compact and highly usable.
- Korean UI labels.
```

## 7. Expanded Map State Inside Itinerary

Use this for the expanded map state inside the combined itinerary-map screen.

```text
Design the expanded map state of the itinerary screen for Trip Split.

All visible UI copy must be Korean.

Purpose:
Show the trip route visually using numbered pins and straight-line connections based on the timetable order. This is not real road navigation.

Shared shell:
- Use the same three primary destinations "일정·지도", "정산", "영수증" and make "일정·지도" active.
- Do not make "장소 보관함" a main destination.

Mobile-first layout at 390px:
- Let the map fill the screen between the compact top bar and bottom navigation.
- Overlay a small day filter "1일차 / 2일차 / 전체" and map controls.
- Put the ordered itinerary in a draggable bottom sheet titled "지도 동선". Its collapsed state shows the next place; expanded state shows the full ordered list and a contextual "장소 보관함" action.

Desktop expansion:
- Use a large map canvas with an itinerary side panel titled "지도 동선".
- Keep the day selector and ordered list in the side panel and the legend at the map bottom-right.

Map visual:
- Use a light map-like background.
- Show Gangneung area style map placeholder.
- Show numbered circular pins:
  - Day 1 pins in coral #FF385C
  - Day 2 pins in dark #222222
  - White number text inside pins
- Connect same-day pins using straight polyline:
  - Day 1 solid coral line
  - Day 2 dashed dark line
- The route is clearly marked as "번호 순서대로 이동".

Itinerary bottom sheet or side panel:
- Title: "지도 동선"
- Day toggle: 1일차, 2일차, 전체
- Ordered list:
  1. 테라로사 커피공장
  2. 형제칼국수
  3. 안목해변
  4. 경포 그곳에가면펜션
- Each list item has time, place name, and small category.

Legend:
- 동선
- Coral dot: 1일차
- Dark dot: 2일차
- Text: "직선은 실제 경로가 아닌 일정 순서 표시입니다."

Design:
- The map must be the visual focus.
- Bottom sheets and floating panels are white, rounded, lightly shadowed.
- Do not overdecorate. Keep map pins readable.
```

## 8. Settlement Overview Screen

Use this to regenerate the personal spending and settlement dashboard.

```text
Design a high-fidelity responsive settlement overview for Trip Split.

All visible UI copy must be Korean.

Purpose:
Help one selected participant understand three different concepts without mixing them:
1. "내가 결제한 금액": money paid upfront.
2. "내가 부담한 금액": the participant's actual personal consumption.
3. "정산 결과": money to receive from or send to other participants.

Shared shell:
- Use the three primary destinations "일정·지도", "정산", "영수증" and make "정산" active.
- Participant switcher chips: "나", "민수", "지연", "도윤".
- Primary action: "지출 추가".

Mobile-first layout at 390px, in this exact top-level order:
1. Personal section titled "나의 정산".
   - Three clearly separate cards: "내가 결제한 금액 33,000원", "내가 부담한 금액 62,000원", "보낼 금액 29,000원".
   - Never combine paid and owed into one ambiguous total.
   - Nested category block titled "카테고리별 내 소비" with compact rows "식비 17,000원", "숙박 45,000원".
   - Nested detail block titled "내 소비 내역". Group by date and place, then show menu or expense rows.
   - Detail rows: "7월 3일 · 형제칼국수 · 순두부 12,000원", "7월 3일 · 형제칼국수 · 감자전 5,000원", "7월 3일 · 숙소 · 숙소 45,000원".
   - Detail filters: "날짜", "장소", "카테고리".
2. Final settlement section titled "최종 정산".
   - Transfer rows: "나 → 민수 29,000원", "지연 → 민수 56,000원", "도윤 → 민수 45,000원".
   - Action: "정산 문구 복사".
3. Expense list titled "지출 목록".
   - "점심 영수증 33,000원 · 결제 나 · 항목별 분할"
   - "숙소 180,000원 · 결제 민수 · 4명 균등"
   - Each row includes date, category, payer, split method, linked place, edit action.

Desktop expansion:
- Keep the same information hierarchy, but use a dense multi-column workspace.
- Left column: expense list and "지출 추가".
- Middle column: selected participant summary, category totals, and personal detail.
- Right column: final transfer results and copy action.
- Make columns independently scannable without turning the screen into a spreadsheet.

Use this canonical sample allocation:
- "순두부 12,000원": 나.
- "커피 6,000원": 지연.
- "감자전 15,000원": 나, 민수, 지연 equally, 5,000원 each.
- "숙소 180,000원": 나, 민수, 지연, 도윤 equally, 45,000원 each.
- The lunch receipt is paid by 나 and the lodging is paid by 민수.

Include compact states:
- Loading skeleton.
- Empty state: "아직 지출이 없어요" and action "첫 지출 추가".
- Realtime indicator: "방금 동기화됨".
- Error banner: "정산 정보를 불러오지 못했어요" and action "다시 시도".

Design:
- Practical financial UI but warm and friendly.
- Use tabular numerals, clear signs and arrows, compact cards, and coral only for meaningful emphasis.
- Make paid, owed, and net visually distinguishable by labels and layout, not color alone.
- Avoid spreadsheet-heavy look.
```

## 9. Add Expense Modal

Use this to regenerate the complete expense entry and split flow.

```text
Design a high-fidelity responsive "지출 추가" flow for Trip Split.

All visible UI copy must be Korean.

Purpose:
Create one canonical expense with a payer, consumers, split method, allocated amounts, optional receipt items, and an optional linked place or itinerary item.

Responsive container:
- On a 390px phone, use a full-height sheet or focused page with a sticky total summary and sticky bottom actions.
- On desktop, use a wide modal or right drawer with the same field and action order.

Basic fields:
- "지출명"
- "날짜"
- "카테고리"
- "총액"
- "결제자"
- "연결된 장소 또는 일정" with "선택 안 함" available
- "메모"

Split method segmented control:
1. "전체 균등"
   - Participant chips "나", "민수", "지연", "도윤".
   - Preview example: "숙소 180,000원 · 4명이 각각 45,000원 부담".
2. "항목별 분할"
   - Editable item rows with item name, amount, consumer chips, allocation preview, edit and remove actions.
   - Use these rows:
     - "순두부" / "12,000원" / "나" / "나 12,000원"
     - "커피" / "6,000원" / "지연" / "지연 6,000원"
     - "감자전" / "15,000원" / "나, 민수, 지연" / "각 5,000원"
   - Action: "메뉴 추가".
   - Secondary action: "할인·봉사료·조정 추가" with types "할인", "봉사료", "기타 조정".
   - Each adjustment can be equally divided among selected people or use directly entered personal amounts.
3. "직접 입력"
   - Amount inputs beside each participant.
   - Live remaining amount: "남은 금액 0원".

Validation summary:
- Sticky or clearly visible summary: "항목 합계 33,000원", "총액 33,000원", "차액 0원".
- Show deterministic one-won remainder information when needed: "나머지 1원은 표시된 참여자 순서대로 배분돼요".
- If totals do not match, show "총액과 배분 합계가 일치하지 않아요" beside the invalid area and disable save.

Actions:
- Secondary "취소".
- Primary "지출 저장".
- Disable the primary action while saving and show "저장 중".

Visual:
- White sheet, modal, or drawer with rounded 12px surfaces.
- Coral primary button.
- Participant chips are compact and easy to scan.
- Use Korean labels, KRW formatting, tabular numerals, and clear row-level validation.
- Keep the form dense but touch-friendly; do not hide split logic behind unexplained icons.
```

## 10. Receipt OCR Screen

Use this to regenerate the complete receipt OCR review and split flow.

```text
Design a high-fidelity responsive receipt OCR workspace for Trip Split.

All visible UI copy must be Korean.

Purpose:
Guide the user through local image selection, stateless OCR, editable item review, participant allocation, total validation, and explicit expense saving. OCR must never auto-create an expense.

Shared shell:
- Use the three primary destinations "일정·지도", "정산", "영수증" and make "영수증" active.
- Show a compact progress indicator with Korean labels: "이미지 선택", "항목 확인", "배분 및 저장".

Mobile-first layout at 390px:
- Use one vertical step flow.
- Step 1 shows local upload and image preview.
- Step 2 replaces or collapses the preview and shows editable OCR items.
- Step 3 shows allocation, total validation, and a sticky explicit-save action.
- Keep a back action so users can change the image without losing confirmed fields unexpectedly.

Desktop expansion:
- Use three columns.
- Left: local receipt preview, upload controls, privacy notice, raw text disclosure.
- Center: editable receipt fields and item rows.
- Right: allocation controls, validation summary, and save action.
- Keep the editing and allocation columns independently scrollable and the total summary sticky.

Image and privacy area:
- Drag-and-drop area and button "영수증 이미지 선택".
- Note: "이미지는 Firebase Storage에 저장하지 않으며 OCR 처리를 위해 CLOVA OCR로 전송돼요."
- State labels: "인식 중", "인식 완료", "인식하지 못했어요".
- Actions: "이미지 바꾸기", "다시 인식".

Editable receipt draft:
- Header "영수증 항목 확인" and helper text "항목명과 금액을 확인하고 필요한 내용을 고쳐 주세요".
- Basic fields "지출명", "날짜", "카테고리", "총액", "결제자", "연결된 장소 또는 일정".
- Editable rows:
  - "순두부" / "12,000원"
  - "커피" / "6,000원"
  - "감자전" / "15,000원"
- Every row has edit and remove actions.
- Actions: "누락 항목 추가" and "할인·봉사료·조정 추가".
- Optional disclosure "추출된 원문 보기"; do not make raw OCR text the primary editor.

Allocation controls:
- Offer "전체 균등", "항목별 분할", and "직접 입력".
- In the itemized state show:
  - "순두부 12,000원 · 나"
  - "커피 6,000원 · 지연"
  - "감자전 15,000원 · 나, 민수, 지연 · 각 5,000원"
- Let common items be split equally among selected participants.
- Let every item, discount, service charge, or adjustment use directly entered personal amounts.

Validation and confirmation:
- Show "항목 합계 33,000원", "영수증 총액 33,000원", "차액 0원" together.
- If values differ, show "총액과 항목 합계가 일치하지 않아요" and disable saving.
- Primary action: "확인하고 지출 저장".
- Supporting copy: "저장하기 전에는 정산에 반영되지 않아요".

OCR failure fallback:
- Show a calm error card titled "영수증을 인식하지 못했어요".
- Actions: "다시 시도" and "전체 금액으로 직접 등록".
- The manual fallback asks only for total, payer, selected consumers, and equal or direct split; it must not pretend OCR items were found.

Design:
- Clean, trustworthy, warm, and travel-friendly.
- Use compact editable rows, clear KRW alignment, visible total validation, and touch-friendly controls.
- Avoid medical/financial heavy tone.
- Make the Firebase no-storage and explicit-confirmation boundaries impossible to miss without using alarming language. Do not claim that CLOVA retains nothing unless the verified provider policy supports that copy.
```

## 11. Share Dialog

Use this for the trip sharing modal.

```text
Design a share dialog for Trip Split.

All visible UI copy must be Korean.

Purpose:
The trip owner shares the trip with friends. The app uses anonymous Firebase sessions by default. Everyone with the invite link can edit in MVP.

Dialog content:
- Title: "여행 공유"
- Share code card:
  - Code: GANGNEUNG24
  - Button: "코드 복사"
- Invite link card:
  - URL field
  - Button: "링크 복사"
- Permission notice:
  - "MVP에서는 링크를 가진 모든 사람이 장소, 일정, 지출을 함께 편집할 수 있어요."
- Realtime note:
  - "변경 사항은 참여자 화면에 실시간으로 반영됩니다."
- Account note:
  - "Google로 연결하면 내 여행 목록에 저장됩니다."
- Backup action:
  - Secondary button: ".trip.json 내보내기"

Visual:
- Friendly and clear.
- Coral primary action.
- Use small warning/info box, not scary.
```

## 12. Backup Import Export Screen

Use this for `.trip.json` backup and restore.

```text
Design a backup import/export screen for Trip Split.

All visible UI copy must be Korean.

Purpose:
Users can export or import a trip as a .trip.json file.

Layout:
- Header: "여행 파일 백업"
- On mobile, stack the export and import cards.
- On desktop, place the export and import cards side by side.

Export card:
- Text: "현재 여행 데이터를 파일로 저장합니다."
- Filename preview: gangneung-2026.trip.json
- Button: "파일 내보내기"

Import card:
- Upload drop area
- Text: ".trip.json 파일을 가져와 새 여행으로 복원합니다."
- Button: "파일 선택"

Include validation state:
- Success: "여행 파일을 확인했어요."
- Error: "지원하지 않는 파일 형식입니다."

Design:
- Simple utility screen.
- Clean cards, practical controls.
```

## 13. Mobile PWA Trip Screen

Use this to preview the mobile PWA layout.

```text
Design a mobile PWA screen for Trip Split on a 390px wide phone.

All visible UI copy must be Korean.

Screen:
- Existing trip "강릉 1박 2일 여행"
- Active tab "일정"

Mobile layout:
- Sticky top bar with back, trip title, sync status, and "더보기". Put sharing, participants, and account actions in the more sheet.
- Persistent bottom navigation in this exact order: 일정·지도, 정산, 영수증.
- Day segmented control: 1일차, 2일차.
- Compact timetable cards connected as a vertical timeline.
- Floating bottom action button: "일정 추가".

Each timetable card:
- Time
- Place name
- Short memo
- Small map pin indicator
- Optional expense badge

Bottom:
- Collapsed bottom-sheet handle: "장소 보관함 열기".
- Expanded sheet search: "장소 검색 또는 네이버 링크 붙여넣기".
- Do not add the place library as a fifth bottom-navigation item.

Style:
- Airbnb-inspired, bright, rounded.
- Touch-friendly controls.
- No desktop sidebars.
- Keep text readable and avoid cramped layout.
```

## 14. Empty And Error States

Use this to generate reusable empty and error states.

```text
Design empty and error states for Trip Split.

All visible UI copy must be Korean.

Create a single screen showing four compact state cards:

1. Empty places
- Title: "아직 저장한 장소가 없어요"
- Text: "네이버 장소 링크를 붙여넣거나 검색해서 첫 장소를 추가하세요."
- Button: "장소 추가"

2. Empty itinerary
- Title: "일정이 비어 있어요"
- Text: "시간을 추가하고 장소를 연결해보세요."
- Button: "일정 추가"

3. Empty expenses
- Title: "아직 지출이 없어요"
- Text: "첫 지출을 추가하면 정산 결과가 계산됩니다."
- Button: "지출 추가"

4. Link parse error
- Title: "장소 링크를 읽지 못했어요"
- Text: "검색 후보를 선택하거나 직접 입력해 주세요."
- Buttons: "검색하기", "직접 입력"

Design:
- Warm, calm, practical.
- No large illustration.
- Use simple icons and coral accent.
```

## 15. Full Product Preview Prompt

Use this when you want one comprehensive preview of the whole app.

```text
Create a full product preview for Trip Split, a Korean domestic travel planning and expense settlement PWA.

All visible UI copy must be Korean.

Show one realistic desktop itinerary app screen with:
- Top trip bar for "강릉 1박 2일 여행"
- Tabs: 일정·지도, 정산, 영수증
- Active destination "일정·지도"
- Full-width compact expandable map above the planning columns
- Left date list
- Center vertical timeline
- Right embedded place library panel with Naver link input, not a primary tab
- Keep the map inside the active itinerary workspace. Keep the settlement dashboard as a separate primary destination.

The screen should communicate the entire product concept:
"장소를 고르면 일정이 되고, 지출을 확인하면 개인 소비와 정산 결과가 계산됩니다."

Use Airbnb-inspired warm travel UI:
- White background
- Light gray surfaces
- Coral primary accent #FF385C
- Rounded cards
- Compact functional layout
- Korean labels
- Realistic sample Gangneung trip data

Do not create a marketing landing page. Make this a usable app workspace.
```
