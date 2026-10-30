# Unit and Assessment Improvement Plan

## Status and scope

This document records the decisions agreed during the unit/assessment audit and
clarification interview. The implementation and subsequent Rails review retain
this agreed scope.

The goal is to make each inspection present the correct checklist for its unit's
primary type and permitted components, including the missing bouncing-pillow
assessment. The same applicability rules must govern forms, completion, guidance,
prefilling and detailed reports.

The original audit was source-based. Implementation and review were subsequently
verified using the repository's Nix development environment:

- 572 examples passed across 42 affected test targets, including the existing
  inspection model, unit requests, browser workflows, reports and migrations.
- StandardRB passed for 103 affected Ruby files; ERB lint passed for all nine
  changed templates; the Sorbet changed-signature check passed.
- Live Chromium checks exercised fractional slide runout, Pillow N/A answers
  with comments, the Results summary, advisory bungee guidance, and JSON/PDF/CSV
  responses. CSV remained summary-only; explicit N/A survived detailed export.

Review refinements centralised configuration display and comment collection,
consolidated UI-driven test setup, and removed an unreferenced summary partial
and its redundant view spec. Regression fixes preserve fractional slide runout
and the PDF table's optional-inspection contract. This was focused verification,
not a full-suite run; screenshot-tagged examples retained their default exclusion.
Spencer's checklist remains a working specification, not a certification claim.

## Agreed product decisions

### Equipment model and working specifications

1. **Use a primary type plus permitted components.** The primary type determines
   the core checklist. Components add relevant checks without permitting
   impossible combinations. Do not reproduce Spencer's unrestricted combination
   of assessment sections.

2. **Keep the existing eight primary types.** Do not add separate primary types
   for standalone slides, obstacle courses or combi units in this work. Represent
   supported configurations through the existing types and permitted components.

3. **Store unit defaults and inspection snapshots separately.** Enduring physical
   configuration belongs on the unit and initialises an inspection's own
   configuration snapshot. Later unit changes must not alter historical
   inspection configuration or answers.

4. **Use Spencer's app as the working specification.** Reuse its checklist
   requirements, qualifications and values rather than independently inventing
   replacements. Known disagreements are not independently verified standards
   compliance. Bouncing pillows use the separate local specification described
   below because Spencer's app contains no pillow workflow.

### Component and field applicability

5. **Restrict slide and total-enclosure components by primary type.** The agreed
   permissions and outdoor anchorage coverage are:

   | Primary type | Slide permitted | Total enclosure permitted | Anchorage for outdoor use |
   |---|---|---|---|
   | Bouncy Castle (`bouncy_castle`) | Yes | Yes | Yes |
   | Bouncing Pillow (`bouncing_pillow`) | No | No | No; use pillow foundation/site checks |
   | Bungee Run (`bungee_run`) | No | No | Yes |
   | Catch Bed (`catch_bed`) | No | No | Yes |
   | Inflatable Ball Pool (`inflatable_ball_pool`) | No | No | Yes |
   | Inflatable Game (`inflatable_game`) | Yes | Yes | Yes |
   | PAT Testable Appliance (`pat_testable`) | No | No | No |
   | Play Zone (`play_zone`) | Yes | Yes | Yes |

   Catch beds must never offer slide or total-enclosure configuration. Validate
   component permissions in the application model as well as hiding unsupported
   controls in the interface.

6. **Apply indoor-only anchorage behaviour consistently.** Indoor-only units skip
   Anchorage assessments. For outdoor use, all inflatable types except bouncing
   pillows receive Anchorage assessments, including ball pools, games and play
   zones that currently lack them. Show the indoor-only setting wherever it
   affects applicability; do not leave it as an ignored control.

7. **Make Play Zone components independent.** A slide, ball pool and air jugglers
   are separate configuration choices. Ball-pool checks must not require an
   air-juggler component, or vice versa. Absent components must not leave their
   questions or measurements required elsewhere in the Play Zone assessment.

8. **Hide irrelevant shared checks automatically.** Use type and component
   configuration to remove inapplicable questions, not merely their tab links.
   This includes relevant distinctions for walls, ramps, platforms, troughs,
   pressure, evacuation and blowers. Hidden checks must not block saving or
   completion, appear in missing-field lists, or affect guidance.

   Bouncing pillows are the only sealed-air units. The other inflatable types
   are constant-air units with required blowers and Fan assessments. A pillow's
   blower presence is a separate component: assess its inflation blower when
   present and omit Fan checks when absent. Do not equate sealed-air construction
   with the absence of an inflation blower.

### Bouncing pillows

9. **Implement the documented pillow checklist.** Use
   [BOUNCING_PILLOW_FIELDS.md](BOUNCING_PILLOW_FIELDS.md) as the working field
   inventory. Its example values and comments are inspection examples, not
   default measurements, universal limits or automatically passed answers.

   | Section | Required field coverage when the section applies |
   |---|---|
   | Inflatable | Security of seams; air-loss points; foundation; average gradient; fabric fire resistance and strength; internal pressure; grounding; deflation/evacuation time; artwork; identification |
   | Site | Slope; clear area; headroom |
   | Impact Area | Hard objects; depth of impact attenuation; signage; number of users |
   | Fencing | Distance; height; strength; visibility; entrapment; gateways |

   Preserve the documented measurements and associated outcomes/comments, with
   explicit units. Include applicable actual user limits under decision 16.

10. **Provide one Pillow tab with four sections.** Inflatable, Site, Impact Area
    and applicable Fencing checks share one save action and completion indicator.
    Fan remains a separate tab when a blower is present. Do not build four
    independently navigated pillow assessment tabs.

11. **Treat pillows as movable units.** Keep the unit's identity when it moves.
    Each inspection records and assesses the site where the pillow is installed;
    foundation, slope, clearances and impact-area findings must not exist only as
    mutable current-site information on the unit.

12. **Make fencing optional.** A fencing component controls the entire Fencing
    section. No fence omits that section without causing a failure by itself.
    Measurements for absent fencing must not be required for completion.

### Dedicated checklists, requirements and user limits

13. **Keep one Catch Bed checklist.** Retain a free-text description of the catch
    bed or associated equipment. Do not introduce structured ride subtypes or
    subtype-specific checklist branches in this work.

14. **Adopt Spencer's bungee requirements as the working rules.** Use its harness
    pull-test requirement and bungee-specific anchorage calculation, rather than
    silently reusing the castle calculation.

    | Requirement | Agreed working rule | Reference |
    |---|---|---|
    | Harness pull test | 2,400 N | `spencers_app/Form1.Designer.cs:1582-1591` |
    | Bungee anchorage | Reference bungee calculation, labelled per side and rounded up, using its bungee multiplier | `spencers_app/Form1.Designer.cs:6018` |

    Trace the reference calculation's area inputs, multiplier, rounding and
    per-side versus total-count interpretation before mapping it to the existing
    anchorage model. Do not assume that a per-side result can be compared directly
    with the current total anchor count. Adoption of the reference is not a claim
    of independent verification against a published standard.

15. **Use a game core checklist plus explicit components.** Keep the game
    description as free text. Inflatable bed, containing walls and ancillary
    equipment are components controlling their relevant checks, alongside the
    permitted slide and enclosure components. Preserve the source's conditional
    meaning in labels and guidance, including bed-dependent mass-marking and
    containing-wall requirements. Do not introduce a game-subtype catalogue.

16. **Record actual user limits where applicable.** Capture the relevant user
    numbers, age ranges, height limits and mass limits as values, alongside checks
    that required markings are present/correct. A marking outcome is not a
    substitute for the actual permitted limit. Hide limits that do not apply to
    the type or configuration and make units and meanings explicit.

17. **Keep Play Zone and Slide geometry independent.** The Play Zone gradient
    refers to access to the platform, not the slide slope. Preserve that
    distinction in fields and guidance. Keep Play Zone and Slide platform heights
    independently recorded; do not merge or automatically synchronise them.

### Assessment answers, judgement and completion

18. **Offer Pass, Fail and N/A for assessment outcomes.** An unanswered applicable
    outcome remains incomplete. An inspector may explicitly select N/A on a
    visible check; measurements belonging to an N/A check need not be supplied.
    Comments are always optional, including on Fail and N/A answers. Do not add a
    separate Not Inspected state or mandatory explanation rules.

    Outcome states are distinct from physical Yes/No configuration answers. A
    component selector or a factual construction question must not become a
    Pass/Fail/N/A outcome merely because its current storage is boolean.

19. **Keep the overall result independent.** The inspector chooses the overall
    Pass/Fail result independently of individual check outcomes. Do not force an
    overall failure, require an override justification, or prevent a fully
    answered failed inspection from being completed.

20. **Provide calculated guidance without taking over the answers.** Compare
    numerical measurements with the applicable working rules and display useful
    guidance. The inspector still selects each check's outcome. A valid
    measurement that fails a safety limit must remain saveable and reportable;
    distinguish that from invalid data types or formats. Do not prefill measured
    values with threshold values or sample inspection measurements.

### Prefilling, draft changes and historical records

21. **Retain the existing bouncy-castle prefilling system.** Apply that behaviour
    across the applicable assessment types, including assessment values, comments
    and outcomes. Do not replace it with a stable-data-only or outcomes-blank
    policy. Retain its existing review presentation and existing exclusions for
    system fields and the independently chosen overall inspection result.

    Reuse the existing creation-time and form-level mechanisms, preserving
    already-entered draft answers rather than overwriting them with older data.
    Only applicable, compatible fields may be prefilled. A previous example or
    threshold is not a substitute for a prior inspection answer.

22. **Rebuild a draft's checklist when its unit or type changes.** Recalculate the
    primary type, component configuration, tabs, field applicability and required
    answers. Keep answers for checks that remain applicable and compatible;
    remove answers for checks that no longer apply. Do not reset all answers or
    prohibit a change simply because answers already exist.

    Cover normal inspection creation, attaching a unit to an existing draft,
    creating a unit from an inspection, switching the associated unit and changing
    the unit's primary type for an actively edited draft. A creation-only type
    callback is insufficient. Compatibility must refer to the meaning of a check,
    not merely an identical attribute name in unrelated assessments.

23. **Leave existing inspections as-is until edited.** Do not bulk upgrade their
    checklists, change their answers or completion status, or add retrospective
    missing-check flags to normal viewing and reporting.

    Opening the intentional edit workflow shows gaps against the current
    applicable checklist. Merely viewing or exporting an old inspection must not
    upgrade it. Visiting an edit screen should not itself write new assessment
    answers or mutate the record; persist changes through the normal save path.

    Once edited, an inspection can be saved as a draft, but must satisfy the
    current applicable checklist before being marked complete again. New gaps
    cannot be dismissed as warnings while re-completing the inspection.

    Preserve historical requirement interpretation as well as answers. In
    particular, do not relabel a historical bungee test as if the newly adopted
    requirement had been used at the time.

### Reports and exports

24. **Omit irrelevant checks but retain explicit N/A answers.** PDF and JSON
    reports omit checks excluded by type/components. Checks the inspector
    explicitly answered N/A remain in the report, with any optional comment.
    Include the applicable pillow data, site findings, configuration and actual
    user limits in detailed reporting, respecting existing public-field rules.

    **CSV remains a summary export.** Keep its inspection/unit-summary purpose;
    do not add assessment measurements, outcomes or comments, or a separate
    detailed CSV export. JSON is the full assessment-data export. This supersedes
    the earlier interview answer proposing detailed CSV assessment columns.

## Implementation approach

### Phase 1: Establish configuration and checklist lifecycle data

- Extend the existing unit/inspection model rather than adding new primary types
  or a freely combinable assessment builder.
- Define the type/component permission and field-applicability mapping using the
  agreed matrix and working specifications. Include measurement units and the
  relevant user-limit fields in this inventory.
- Add unit configuration defaults and inspection configuration snapshots. Use an
  explicit checklist revision boundary to distinguish untouched existing records
  from new or intentionally edited inspections.
- Preserve the semantics of existing stored answers. When outcome booleans become
  Pass/Fail/N/A enums, preserve false as Fail, true as Pass and unanswered values
  as unanswered; do not fabricate N/A or Pass answers during migration.
- Leave existing inspections on their original checklist interpretation until
  edited. Do not infer historical applicability solely from assessment-row
  existence: current getters can create assessment rows independently of whether
  their checks apply.
- Fix the single-enabled-type creation path: hiding the selector must still
  assign the permitted type rather than silently using the castle default.

Primary touchpoints: `app/models/unit.rb`, `app/models/inspection.rb`,
`app/config/units_config.rb`, unit creation/edit forms and controllers, and new
schema migrations.

### Phase 2: Make applicability consistent across existing paths

- Extend the existing assessment registry/schema mechanisms with record-aware
  filtering. The current class-only rendering schema cannot determine component
  applicability for a particular inspection.
- Use the same applicability decisions for form fields, tabs, permitted component
  configuration, completion checks, missing-field lists, guidance and detailed
  reports. Do not establish separate hand-maintained rules for each surface.
- Wire slide and enclosed assessments to all permitted types. Apply the outdoor
  and indoor-only anchorage rules consistently.
- Apply filtering within shared and dedicated assessments, not just at assessment
  boundaries. Inactive Play Zone components must not leave mandatory fields in
  the surviving Play Zone tab.
- Update all unit-assignment/type-change paths together, retaining compatible
  answers and the existing prefilling behaviour.
- Ensure historical show/report paths do not run current-checklist integrity
  checks against untouched records or create newly introduced assessments merely
  by reading them. Apply current rules in the explicit edit/save workflow.

Primary touchpoints: `Inspection`, `InspectionCompletion`, `AssessmentSchema`,
`FormConfigurable`, `AssessmentCompletion`, `app/views/chobble_forms/_fields.html.erb`,
inspection form/tab helpers, `InspectionCreationService`,
`UnitCreationFromInspectionService` and `InspectionsController`.

### Phase 3: Complete pillow and type-specific assessment coverage

- Add a single `Assessments::BouncingPillowAssessment` with sectioned form
  configuration, translations, controller/routes, persistence and factory data.
  One record/form should serve the agreed single save/completion surface; four
  separate assessment-table/tab contracts are unnecessary.
- Implement every field in the pillow inventory, per-inspection site information,
  conditional fencing and conditional Fan applicability.
- Add actual applicable user-limit values without removing the corresponding
  marking checks.
- Add the game components and conditional checks. Keep catch-bed and game type
  descriptions as free text.
- Correct the Play Zone access-gradient meaning, preserve independent platform
  heights and restore source qualifications omitted from current labels.
- Integrate all additions into creation, prefilling, completion, reports and
  existing form/i18n coverage before considering the relevant type complete.

Primary touchpoints: `app/models/assessments/`, assessment controllers,
`config/forms/`, split files under `config/locales/`, `config/routes.rb`, migrations
and the corresponding factories and feature specs.

### Phase 4: Align outcome storage, guidance and completion behaviour

- Apply Pass/Fail/N/A consistently to outcome fields while retaining physical
  boolean answers where appropriate.
- Make completion depend on applicable answers and N/A measurement exemptions,
  never on optional comments or all individual checks passing.
- Treat both true and false as answered overall results in progress indicators
  and completion/navigation logic; a failed result must not appear unanswered.
- Add source-based numerical guidance, including the bungee-specific anchorage
  calculation, without overwriting the inspector's chosen answers.
- Keep calculation inputs, units, rounding and per-side/total presentation
  consistent. Retain the existing castle calculation behaviour where unchanged.
- Ensure numeric composite fields participate correctly in the shared schema and
  validation mechanisms; distinguish format/type validation from a safety limit.

Primary touchpoints: assessment models, `AssessmentSchema`,
`ValidationConfigurable`, completion concerns, form partials, inspection helpers
and existing safety-result views/calculation integration.

### Phase 5: Finish reports and prove the integrated behaviour

- Make PDF/JSON use the inspection's applicable configuration and checklist
  lifecycle, including the single Pillow assessment and explicit N/A outcomes.
- Preserve untouched historical reporting without implying newly added checks
  were previously performed. Actual edits must invalidate the relevant cached
  reports through the existing cache mechanisms.
- Keep CSV summary-only. Review its automatically derived headers so new internal
  snapshot/revision fields do not leak into exports as raw implementation data.
- Exercise the complete user journeys below in a working Rails environment.
- After smoke verification, update the existing unit-type/pillow documentation
  and relevant release documentation to match the delivered behaviour, removing
  obsolete four-tab pillow instructions and outdated coverage claims.

Primary touchpoints: `PdfGeneratorService` and its assessment block builder,
`InspectionBlueprint`, `InspectionCsvExportService`, unit reporting, existing
workflow specs and documentation.

## Verification and acceptance

Verify consumer-visible behaviour rather than source text, forwarding calls or
copies of implementation constants.

1. **Creation and configuration:** exercise every row of the permission matrix
   through the real unit/inspection forms. Cover normal creation, inspection-first
   unit attachment, unit creation from a draft, unit switching and reclassification.
   Also exercise a deployment with one enabled non-castle type.

2. **Conditional checklists:** independently toggle allowed slide, enclosure,
   ball-pool, air-juggler, game and pillow components. Observe the actual fields,
   tabs and missing-field lists, including indoor/outdoor anchorage and pillow
   blower/fencing combinations. Verify impossible components cannot be persisted.

3. **Pillow completion:** complete a pillow inspection through its single
   sectioned tab, using real measurements and a recorded site. Move the same unit
   to another site for a later inspection and verify the earlier site findings
   remain attached to their original inspection.

4. **Answers and calculations:** exercise Pass, Fail, N/A and unanswered checks;
   N/A without a numeric value; Fail/N/A without comments; and independently chosen
   overall results. Observe guidance for measurements on both sides of relevant
   limits while retaining the ability to save valid unsafe measurements. Check
   bungee rounding and per-side/total handling against the reference.

5. **Repeat inspections and draft changes:** compare the experience with the
   current bouncy-castle prefilling system, including existing exclusions. Verify
   already-entered answers are not overwritten, compatible answers survive a
   draft change and inapplicable answers are removed through the save workflow.

6. **Historical records:** load, regenerate reports for and export pre-cutover
   inspections without changing them or adding missing-check flags. Then edit one,
   observe current gaps, save it as a draft and verify re-completion is blocked
   until the required answers exist. Include an old fan-only pillow inspection.

7. **Reports and exports:** inspect actual PDF/JSON output for newly supported
   fields, omitted irrelevant checks and retained explicit N/A answers. Verify
   actual user-limit and site values are present in detailed exports, while CSV
   remains a summary and contains no assessment-answer expansion.

Follow repository conventions for implementation and verification:

- Reuse the current form-context/fieldset/field partials and YAML schema patterns.
- Use I18n for every user-facing label, unit, message and guidance string; extend
  split locale files rather than growing the general locale file.
- Use semantic HTML without new CSS classes or inline styles, and retain
  progressive enhancement/Turbo behaviour.
- Add appropriate Sorbet headers and signatures to new/modified Ruby code.
- Extend existing Capybara workflow coverage and add focused behavioural
  regressions for missing/conditional checks and lifecycle transitions. Reuse
  existing comprehensive form/i18n coverage rather than duplicating label tests.
- Run associated focused specs with `--fail-fast`, plus standards checks scoped to
  modified Ruby/ERB files. Do not run the full slow RSpec suite unless requested.
- Use the normal isolated per-process test databases; do not switch browser
  verification to shared in-memory SQLite as a workaround.
- Smoke the actual forms, navigation and outputs in a running application. Passing
  tests alone do not establish that the corrected interface works end to end.

## Completion boundary

The improvement is complete only when all agreed configurations work through
creation, editing, prefilling, completion and reporting, with existing inspections
preserved until edited. A registered type without its required fields, a hidden
tab with still-mandatory fields, a report-only fix, or a partial component rollout
is not complete. CSV detail expansion, new primary types, mandatory comments,
automatic overall results and reduced prefilling are explicitly outside this plan.
