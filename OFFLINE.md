# Offline Assessments Plan

## Summary

Operators can create and fill out inspections/assessments offline, then sync when
back online. Offline inspections are created **without a unit** (using the existing
`belongs_to :unit, optional: true` support). A free-text badge ID field captures
which unit the operator intends to link, and the server resolves it on sync.

The approach builds on what already exists:
- `public/manifest.json` is already present and linked in the layout
- Inspections already support `unit: nil` drafts
- The "select unit" and "create unit from inspection" flows already handle linking
  after creation
- Turbo handles all form submissions via `fetch`

No Stimulus is introduced (the app uses vanilla JS classes). No build tooling
changes (importmap stays as-is).

---

## Step 1: Service Worker + Page Caching

**Goal:** The app loads and renders pages when offline. Assessment form pages are
cached on first visit so inspectors can navigate to them without a connection.

### What to build

1. **Service worker** at `app/views/pwa/service-worker.js.erb`
   - Register it from `app/javascript/application.js`
   - Use a versioned cache name (e.g. `play-test-v1`) so deploys invalidate stale
     caches
   - On `install`: precache the offline fallback page and core assets (CSS,
     application JS, fonts, MVP.css)
   - On `fetch`:
     - **Navigation requests** (HTML pages): NetworkFirst strategy — serve from
       network, fall back to cache, last resort show offline fallback page
     - **Assets** (CSS, JS, images, fonts): CacheFirst strategy — serve from cache,
       update in background
     - **API/form submissions** (non-GET): pass through to network (Step 3 handles
       offline queueing)
   - On `activate`: delete old versioned caches

2. **Offline fallback page** at `app/views/pwa/offline.html.erb`
   - Simple page explaining the user is offline and showing cached pages
   - Rendered by the service worker when a navigation request fails and nothing is
     cached

3. **Route** for the service worker (Rails 8 convention)
   - `get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker`
   - `get "offline" => "rails/pwa#offline_page"`
   - (Check if Rails 8.1 already has these routes; if so, just create the views)

4. **Cache key in the `.js.erb`** — use `Rails.application.assets` or a deploy
   timestamp so the cache name changes on each deploy

### Files to create/modify

| File | Action |
|------|--------|
| `app/views/pwa/service-worker.js.erb` | Create |
| `app/views/pwa/offline.html.erb` | Create |
| `app/javascript/application.js` | Add SW registration |
| `config/routes.rb` | Add PWA routes (if not already present) |

### How to test

1. Start the dev server, visit a few inspection edit pages
2. Open DevTools > Application > Service Workers — confirm it's registered
3. Go to DevTools > Network > toggle "Offline"
4. Refresh an inspection page you already visited — it should load from cache
5. Navigate to a page you haven't visited — offline fallback page should appear
6. Go back online, visit a new page — it caches normally

---

## Step 2: Offline State Detection + UI Changes

**Goal:** The app knows when it's offline and adjusts the UI — hides the unit
lookup, shows a free-text badge ID field, and displays an offline status indicator.

### What to build

1. **`OfflineState` JS class** in `app/javascript/offline_state.js`
   - Listens to `online` / `offline` events on `window`
   - Toggles a `data-offline` attribute on `<html>` (`true` / `false`)
   - Dispatches a custom `offline:changed` event so other JS can react
   - Checks `navigator.onLine` on `turbo:load` to set initial state

2. **Offline indicator in layout** — a small bar/element in the application layout
   that's hidden by default, shown via CSS when `html[data-offline="true"]`
   - Uses semantic HTML (e.g. `<aside>` with a `<p>`) — no CSS classes per your
     rules
   - Text from i18n: `offline.indicator.message` ("You are offline — changes will
     sync when reconnected")

3. **CSS rules** in a new `app/assets/stylesheets/offline.css`
   - `html:not([data-offline="true"]) aside[data-offline-indicator] { display: none; }`
   - `html[data-offline="true"] [data-online-only] { display: none; }` — hides
     elements that require connectivity (unit search, badge lookup)
   - `html:not([data-offline="true"]) [data-offline-only] { display: none; }` —
     hides elements that only appear offline (free-text badge ID field)

4. **Badge ID text field on inspection form** — modify
   `app/views/inspections/_form.html.erb`:
   - Add a text input (wrapped in `data-offline-only`) for free-text badge ID entry
   - Field name: `inspection[offline_badge_id]`
   - This is a **new string column** on `inspections` — stores the unvalidated
     badge/unit ID the operator typed in while offline
   - When online, this field is hidden (the normal unit lookup flow is used)
   - When offline, the unit lookup links are hidden (`data-online-only`) and this
     field appears instead

5. **Migration**: add `offline_badge_id` (string, nullable) to `inspections` table

6. **i18n keys** in a new locale file `config/locales/offline.en.yml`:
   - `offline.indicator.message`
   - `forms.inspection.fields.offline_badge_id` (label for the text field)
   - `offline.indicator.saved_locally` (feedback when form queued)

### Files to create/modify

| File | Action |
|------|--------|
| `app/javascript/offline_state.js` | Create |
| `app/javascript/application.js` | Import offline_state |
| `config/importmap.rb` | Pin offline_state |
| `app/assets/stylesheets/offline.css` | Create |
| `app/assets/stylesheets/application.css` | Import offline.css |
| `app/views/layouts/application.html.erb` | Add offline indicator element |
| `app/views/inspections/_form.html.erb` | Add badge ID field + data attributes |
| `db/migrate/xxx_add_offline_badge_id_to_inspections.rb` | Create |
| `config/locales/offline.en.yml` | Create |
| `app/models/inspection.rb` | Permit `offline_badge_id` in params |
| `app/controllers/inspections_controller.rb` | Permit `offline_badge_id` |

### How to test

1. Load an inspection edit page, confirm the badge ID field is **not** visible
2. Toggle DevTools offline — the offline indicator appears, the unit search links
   vanish, and the badge ID text field appears
3. Toggle back online — UI reverts
4. Run migration, confirm column exists
5. Manually set `offline_badge_id` on an inspection in the console — confirm it
   persists

---

## Step 3: Offline Form Queue (IndexedDB)

**Goal:** When offline, form submissions are intercepted, stored in IndexedDB, and
the user gets visual feedback that their work is saved locally.

### What to build

1. **`OfflineFormQueue` JS class** in `app/javascript/offline_form_queue.js`
   - Opens an IndexedDB database (`play-test-offline`) with an object store
     (`pending_submissions`)
   - Each queued entry stores:
     ```
     {
       id: crypto.randomUUID(),
       url: form.action,
       method: form.method,
       body: new FormData(form) serialised to object,
       csrfToken: document.querySelector('meta[name="csrf-token"]').content,
       createdAt: Date.now(),
       status: "pending"
     }
     ```
   - Provides methods: `enqueue(formElement)`, `getAll()`, `remove(id)`,
     `count()`

2. **Intercept Turbo form submissions** — listen for `turbo:before-fetch-request`
   on `document`:
   - If `navigator.onLine === false` and the request is a form submission (POST,
     PATCH, PUT):
     - Call `event.preventDefault()` to stop Turbo from making the fetch
     - Serialise the form data and enqueue it
     - Show a "Saved locally" flash message (update a Turbo stream target or inject
       into the existing `form_save_message` element)
     - Optionally advance to the next tab (mimicking the normal post-save
       navigation) so the operator can keep filling out assessments

3. **Pending submissions counter** — update the offline indicator to show how many
   submissions are queued (e.g. "Offline — 3 changes saved locally")
   - Updated on each enqueue via the `offline:changed` event or a new
     `offline:queued` event

4. **Create inspection while offline** — a special case:
   - The "new inspection" flow currently requires `POST /inspections` with a
     `unit_id`
   - When offline, we need to create a **local draft** in IndexedDB that represents
     the inspection itself (not just a form submission to replay)
   - Add an "offline new inspection" button/flow that:
     - Creates a temporary local ID (UUID)
     - Stores a local inspection record in IndexedDB
     - Renders the edit form client-side against the local record
   - **Simpler alternative:** pre-create inspections while online. The operator hits
     "New Inspection" while they still have signal, which creates a server-side
     draft (unit-less), then the edit/assessment forms are cached pages they fill
     out offline. This is far simpler and matches the existing architecture.
   - **Recommendation: go with the simpler alternative.** Encourage operators to
     tap "New Inspection" while they have signal (creates a unitless draft on the
     server), then fill out all assessments offline. The badge ID field captures
     which unit it's for.

### Files to create/modify

| File | Action |
|------|--------|
| `app/javascript/offline_form_queue.js` | Create |
| `app/javascript/application.js` | Import offline_form_queue |
| `config/importmap.rb` | Pin offline_form_queue |
| `app/javascript/offline_state.js` | Add queue count to indicator |
| `app/views/inspections/_form.html.erb` | Possibly add local feedback target |

### How to test

1. Visit an inspection edit page (while online) so it's cached
2. Go offline
3. Fill out an assessment form tab and hit Save
4. Confirm: no network error, a "Saved locally" message appears, and the pending
   count increments
5. Fill out another tab — same result, count goes to 2
6. Open DevTools > Application > IndexedDB > `play-test-offline` >
   `pending_submissions` — confirm both entries are stored with correct URL, method,
   and form data
7. Refresh the page (loads from SW cache) — the pending count should still show
   (read from IndexedDB on load)

---

## Step 4: Background Sync + Badge ID Resolution

**Goal:** When connectivity returns, queued form submissions are replayed to the
server. The `offline_badge_id` is resolved to a real unit. Conflicts are handled
gracefully.

### What to build

1. **`OfflineSync` JS class** in `app/javascript/offline_sync.js`
   - Listens for the `online` event
   - On reconnect:
     - Reads all pending submissions from IndexedDB
     - Replays them sequentially (order matters — inspection form before
       assessments)
     - For each submission:
       - Fetches a fresh CSRF token first (`GET /csrf_token` — new endpoint, returns
         JSON with token, needed because the cached token may be expired)
       - Sends the `fetch` request with the original URL, method, and body
       - If 2xx: remove from IndexedDB, decrement counter
       - If 422 (validation error): keep in queue, flag as `needs_review`, notify
         user
       - If 5xx or network error: keep in queue, retry next time
     - Shows a "Synced N changes" flash message on completion
   - **Background Sync API** (Chromium only) as progressive enhancement:
     - Register a sync event (`sync` tag: `replay-forms`) in the service worker
     - Service worker's `sync` handler calls replay logic
     - Falls back to `online` event listener for Safari/Firefox

2. **CSRF token endpoint** — `GET /csrf_token`
   - Returns `{ token: form_authenticity_token }` as JSON
   - Needed because cached pages have stale CSRF tokens
   - Alternatively: fetch any cached page and extract the meta tag — but a
     dedicated endpoint is cleaner

3. **Badge ID resolution** — server-side, runs after sync:
   - New concern or service: `OfflineBadgeResolver`
   - Triggered when an inspection is updated and `offline_badge_id` is present but
     `unit_id` is nil
   - Resolution logic:
     1. Normalise the badge ID (strip spaces, upcase, trim to 8 chars — same as
        existing `search_unit_or_badge` logic)
     2. Look up `Unit.find_by(id: normalised)` (exact match on unit ID)
     3. If not found: `Badge.find_by(id: normalised)` then `.unit`
     4. If found and accessible to the user:
        - Set `inspection.unit = resolved_unit`
        - Copy prefill fields from last inspection (same as
          `InspectionCreationService` does)
        - Clear `offline_badge_id`
        - Save
     5. If not found or not accessible:
        - Leave `offline_badge_id` as-is (not cleared)
        - Leave `unit_id` nil
        - The operator resolves it manually via the existing "select unit" flow
   - Hook this into `Inspection#after_save` or call it from the controller after
     a successful update when `offline_badge_id` changed

4. **"Needs attention" UI for unresolved badges** — on the inspection edit page:
   - If `offline_badge_id.present?` and `unit_id.nil?`:
     - Show a warning: "Badge ID [X] could not be matched to a unit"
     - Show the existing "Select Unit" / "Create Unit" links
   - i18n key: `inspections.messages.unresolved_badge_id`

5. **Idempotency** — prevent duplicate submissions on replay:
   - Add an `idempotency_key` field (string, nullable, indexed unique) to
     `inspections` and each assessment table
   - The offline queue includes a UUID per submission
   - The server checks: if a submission with this idempotency key already exists,
     return 200 (success) without re-processing
   - Alternatively, since assessment updates are PATCH (idempotent by nature — same
     form data produces same result), idempotency keys may only be needed for
     `POST /inspections` (creation). Assess whether this is needed based on testing.

### Files to create/modify

| File | Action |
|------|--------|
| `app/javascript/offline_sync.js` | Create |
| `app/javascript/application.js` | Import offline_sync |
| `config/importmap.rb` | Pin offline_sync |
| `app/views/pwa/service-worker.js.erb` | Add Background Sync handler |
| `app/controllers/csrf_controller.rb` | Create (single action) |
| `config/routes.rb` | Add `/csrf_token` route |
| `app/services/offline_badge_resolver.rb` | Create |
| `app/controllers/inspections_controller.rb` | Call badge resolver after update |
| `app/views/inspections/_form.html.erb` | Add unresolved badge warning |
| `config/locales/offline.en.yml` | Add sync-related i18n keys |
| `spec/services/offline_badge_resolver_spec.rb` | Create |
| `spec/features/offline_sync_spec.rb` | Create |

### How to test

1. **Badge resolution (server-side, testable without JS):**
   - Create an inspection with `offline_badge_id: "ABC123XY"` and `unit: nil`
   - Create a unit with ID `ABC123XY`
   - Trigger the resolver (save the inspection or call the service directly)
   - Confirm the inspection now has `unit_id: "ABC123XY"` and `offline_badge_id`
     is cleared

2. **Badge resolution failure:**
   - Create an inspection with `offline_badge_id: "ZZZZZZZZ"` (no matching unit)
   - Trigger the resolver
   - Confirm `unit_id` stays nil and `offline_badge_id` is preserved
   - Visit the inspection edit page — confirm the warning message appears

3. **Full offline-to-online flow (manual/Capybara with JS):**
   - While online: create a new inspection (unitless draft)
   - Visit the edit page so it's cached
   - Go offline
   - Type a badge ID in the offline badge field
   - Fill out the inspection form and each assessment tab, saving each
   - Confirm all saves show "Saved locally" feedback
   - Go back online
   - Confirm the sync runs automatically, pending count drops to 0
   - Confirm the badge ID was resolved and the unit is now linked
   - Confirm all assessment data was saved correctly

4. **Sync retry on failure:**
   - Queue some submissions offline
   - Go online but with the server down (or throttle to simulate 500s)
   - Confirm submissions stay in queue with error status
   - Start the server — confirm next `online` event (or page load) retries
     successfully

---

## Architecture Diagram

```
ONLINE FLOW (unchanged):
  Browser → Turbo fetch → Rails → DB

OFFLINE FLOW (new):
  Browser → Turbo fetch intercepted → IndexedDB queue
                                        ↓ (on reconnect)
                                      OfflineSync → Rails → DB
                                                      ↓
                                              OfflineBadgeResolver
                                              (resolves badge → unit)

SERVICE WORKER:
  All requests → SW fetch handler
    ├─ GET navigation → NetworkFirst (cache fallback)
    ├─ GET assets     → CacheFirst
    └─ POST/PATCH     → passthrough (offline queue handles these)
```

## Browser Compatibility

| Technology | Chrome/Edge | Safari (iOS/macOS) | Firefox |
|---|---|---|---|
| Service Workers | Yes | Yes | Yes |
| IndexedDB | Yes | Yes | Yes |
| `navigator.onLine` / events | Yes | Yes | Yes |
| Cache API | Yes | Yes | Yes |
| Background Sync API | Yes | **No** | **No** |
| `crypto.randomUUID()` | Yes | Yes (15.4+) | Yes |

**What this means in practice:**

- **Chrome/Edge:** Queued submissions sync even if the operator closed the tab. The
  service worker wakes up in the background and replays.
- **Safari/Firefox:** Sync only runs while the page is open, triggered by the
  `online` event. If the operator closes the browser while offline, nothing syncs
  until they reopen the app. This is fine for the field use case — they'll reopen
  the app when back in range.

**Safari cache eviction:** Safari may evict service worker caches after ~7 days of
inactivity. Adding the app to the home screen (PWA install) gives it persistent
storage and avoids this. Operators should be encouraged to "Add to Home Screen"
on their iPads/phones — this is the intended usage pattern anyway.

**Recommendation:** Build the `online` event listener as the primary sync mechanism
(works everywhere). Layer Background Sync on top as a progressive enhancement for
Chromium browsers. Never depend on Background Sync alone.

## Key Design Decisions

1. **No client-side inspection creation** — operators must create the draft while
   online (one tap). This avoids duplicating server-side logic (ID generation,
   assessment record creation, company assignment) in JavaScript.

2. **No Stimulus** — the app uses vanilla JS classes. The offline code follows the
   same pattern with classes that self-initialise on `turbo:load`.

3. **Badge ID is a soft link** — it's a text field, not a foreign key. Resolution
   is best-effort. If it fails, the existing manual flow handles it.

4. **Sequential replay** — queued submissions are replayed in order (inspection
   form first, then assessments) to avoid race conditions. Each waits for the
   previous to complete.

5. **CSRF refresh on sync** — cached pages have stale tokens. A lightweight
   endpoint provides fresh tokens before replay.

6. **Assessment PATCHes are naturally idempotent** — replaying the same form data
   twice produces the same result. Full idempotency keys are only needed if
   `POST /inspections` is queued (which we avoid by creating drafts online).
