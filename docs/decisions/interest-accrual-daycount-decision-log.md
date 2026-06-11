# Interest Accrual Day-Count Convention — Decision Log

This decision log records every non-trivial decision and deviation made while delivering the **Interest Accrual Day-Count Convention**
feature, and it provides bidirectional traceability at 100% coverage between requirements, implementing files, and acceptance scenarios
(Rule 1 — Explainability). The feature adds a configurable, per-loan-product day-count convention for accrued-interest computation,
supporting exactly three conventions — **Actual/360**, **Actual/365 (Fixed)**, and **30/360 (US / bond basis)** — applied through the
canonical formula `accrued_interest = principal × annual_rate × day_count_fraction`, with the result rounded HALF_UP to currency precision.
Each convention differs only in how `day_count_fraction` is derived. The default behavior — when a product selects no convention — is
byte-for-byte identical to today's accrual, because the configuration value is nullable and the accrual path is fully null-guarded. This
file is the single source of truth for "why": all rationale is documented here and never embedded in code comments (existing-file edits
carry only a terse `// [Day-Count Convention feature]` marker).

## Decision Log

| # | Decision | Alternatives considered | Rationale | Risk / mitigation |
|---|----------|-------------------------|-----------|-------------------|
| D1 | Introduce a **new `DayCountConvention` enum** (+ calculators) rather than extending `DaysInYearType`/`DaysInMonthType` | Reuse/extend existing enums | Existing enums are loan-product interest settings consumed by schedule generation, not independently selectable accrual conventions; isolation honors minimal-change | Slight duplication of "360/365" concepts; mitigated by clear naming and an isolated package |
| D2 | Place the abstraction in **`fineract-core/.../portfolio/common/{domain,accrual}`** | `fineract-loan` only | `fineract-core` is reachable by both server-side accrual and (test-scope) e2e modules; sits beside `DaysInYearType` | None material |
| D3 | Modify **`AbstractCumulativeLoanScheduleGenerator.getPeriodInterestTillDate` (L2828–L2860)** as the single change point | Modify `LoanAccrualsProcessingServiceImpl` only; modify both | This is where the day-count fraction is actually derived; one null-guarded branch is the least-modification approach | Progressive path differs (out of scope, D8); mitigated by null-default fallback preserving current behavior |
| D4 | **Nullable** `accrual_day_count_convention` column with **NULL = today's behavior** | Non-null with a default value | A non-null default would silently change existing products; nullable preserves exact current behavior | Requires null-guard everywhere; covered by tests |
| D5 | **Migration part `0236`** (next after highest existing `0235`) | Reuse/renumber | Sequential Liquibase numbering matches repository convention | None |
| D6 | **Reuse `Money`/`MoneyHelper` HALF_UP** rounding to currency precision | Custom rounding | Matches dataset's HALF_UP @ 2dp and avoids a new numeric approach | Per-tenant rounding mode; calculator pins HALF_UP for the convention math |
| D7 | **DEVIATION — CSV committed under `features/`, not `data/`.** Loader targets `features/InterestAccrualDayCount.csv` | Follow prompt's `data/` path literally | The file physically exists only under `features/`; the prompt's `data/` path is incorrect | Wrong path ⇒ tests cannot load data; mitigated by using the verified classpath location and never moving the CSV |
| D8 | **30/360 US only**; do not implement Eurobond/ISDA/German/PSA variants | Implement multiple variants | Only three conventions are required; S4 dataset behavior confirms US bond basis | Future variants would need new enum constants; acceptable additive extension |
| D9 | **E2E exercises the real production calculator** (CSV-driven), default Option B (test-scope `:fineract-core` dependency in `fineract-e2e-tests-core`) | (A) full server-driven loan flow; (C) internal calc endpoint via Feign | Deterministic, uses real code, matches the dataset's (inputs → output) contract; e2e-core otherwise only has the Feign client | Option B couples e2e-core to `fineract-core` at test scope; Option A remains the fuller end-to-end alternative if preferred |
| D10 | **Create `InterestAccrualDayCount.feature`** (absent today) | Assume it exists | The feature file does not exist in the repository | Without it, no scenarios run; creating it is mandatory |
| D11 | **`LoanProductData` exposes only the scalar `accrualDayCountConvention`; it intentionally OMITS an `accrualDayCountConventionOptions` dropdown list** | Add a template options list mirroring `daysInYearTypeOptions` | The scalar value satisfies R2 response exposure; an options/template list is a separate UI-template concern and this feature has no rendered UI (AAP §0.5.3). Honors minimal-change | A future UI needing a dropdown can add the options list additively; no current consumer requires it |
| D12 | **Swagger documents `accrualDayCountConvention` on the CREATE request DTO (`PostLoanProductsRequest`) only** | Also annotate the PUT request and GET response Swagger DTOs | The field is optional/additive and the create example fully conveys the contract (codes 1/2/3). Functional behavior is wired across create (assembler), update (update util) and response (`LoanProductData`); Swagger annotation breadth is documentation-only and kept minimal | Slightly narrower Swagger coverage; serialized behavior is unaffected and annotations can be extended additively |
| D13 | **Retain wide source lines where wrapping would lose content, break syntax, or diverge from repository convention:** the consolidated decision/traceability Markdown tables, the migration `xsi:schemaLocation` line, and the Grafana `expr` query strings | Force every source line ≤140 by restructuring tables, wrapping the schemaLocation attribute, or embedding `\n` in queries | (a) Markdown table rows are single-line by syntax — preserving full content and the AAP §0.7.2 consolidated-table format (Rule 1) takes precedence; (b) the migration schemaLocation matches the universal repo convention (223/236 tenant changelog parts use the identical 148-char line) so wrapping only this file would be inconsistent; (c) JSON has no line-continuation and embedding newlines in PromQL/LogQL `expr` would change the queries (explicitly forbidden by the finding). The 140-char limit is a review heuristic, not a build gate (checkstyle defers LineLength to Spotless, which does not wrap md/xml/json) | A few source lines exceed the heuristic; rendering and semantics are unaffected and content is fully preserved |
| D14 | **Observability metrics use a Counter `fineract.accrual.daycount.computations` (→ Prometheus `fineract_accrual_daycount_computations_total`) plus a separately-named companion Timer `fineract.accrual.daycount.computations.duration` (→ `fineract_accrual_daycount_computations_duration_seconds_{sum,count,max}`), both tagged `convention`** | (a) a single meter named `fineract.accrual.daycount.computations` serving as both counter and timer; (b) Timer-only; (c) Counter-only | Micrometer forbids a Counter and a Timer sharing one name — empirically verified against the project's own jars (micrometer-core 1.15.11 + prometheus-metrics-core 1.3.10) it throws `IllegalArgumentException` ("already a registered meter of a different type (PrometheusCounter vs. Timer)"), which would abort the accrual computation. Two distinct names keep the counter's `_total` series byte-identical to the CP1 dashboard's primary panels and `convention` template variable, while the `.duration` timer supplies the timing series. Timer-only loses the `_total` count panels; Counter-only loses the timing panel | A same-name registration would crash accrual; mitigated by the verified two-name design. The single timing panel (id=5) is realigned to the `_duration_seconds_*` series — the ONLY dashboard change; panels 1–4, the `convention` template variable, the Loki log panels, and the Tempo panel are unchanged |
| D15 | **Emit the metrics via the static `io.micrometer.core.instrument.Metrics.globalRegistry`** from `AbstractCumulativeLoanScheduleGenerator` | Constructor-inject a `MeterRegistry`; `@Autowired` field injection | The abstract generator is built by its concrete subclasses (`CumulativeFlatInterestLoanScheduleGenerator`, `CumulativeDecliningBalanceInterestLoanScheduleGenerator`) via `super(...)`; those subclasses are OUT of feature scope, so changing the constructor would force out-of-scope edits, and field injection would NPE when the generators are constructed via `new` in non-Spring unit tests. `Metrics.globalRegistry` needs no DI change, is a safe no-op when Prometheus export is disabled, and binds to the Prometheus registry when enabled (Spring Boot `management.metrics.use-global-registry` defaults true; no override in the repo). `micrometer-core` is already on the `fineract-loan` compile classpath, so no build-file change is needed | Global registry is a static seam, acceptable for domain code not managed by DI; mitigated by the no-op-when-disabled behavior and the existing default binding |
| D16 | **Structured accrual log at DEBUG, guarded by `log.isDebugEnabled()`, emitted only on the main apportionment path; the rare zero-full-fraction degenerate case returns `0` without a computation metric** | INFO-level logging; also logging/metering inside the `signum()==0` guard | DEBUG keeps the line production-safe during Close-of-Business (which iterates many installments) and avoids the extra `dayCount(...)` calls plus message construction at the default level; the message text contains "day-count convention" so the dashboard Loki panels match the `(?i)day.?count` regex, and trace/span correlation is automatic via the existing MDC. The `signum()==0` branch represents no real apportionment (returns `0`), so it is intentionally not counted | Slight undercount in the rare degenerate case (documented, acceptable); no sensitive/PII data is logged — only loan id, convention, period dates, day-count days/fractions, period interest, and the accrued amount |

> Any further deviations discovered during implementation MUST be appended to this table as new explicit rows (e.g., D11, D12, …). This
> decision log is the single source of truth for "why"; rationale must never be placed in code comments.

## Traceability — Requirements → Implementing Files

| Requirement | Implementing file(s) |
|-------------|----------------------|
| **R1** — three conventions + exact 30/360 US month-end rules | `DayCountConvention.java`; `Actual360DayCountCalculator`, `Actual365DayCountCalculator`, `Thirty360UsDayCountCalculator` (+ `DayCountConventionCalculator` interface and optional `DayCountConventionCalculatorFactory`) |
| **R2** — select convention per product | `LoanProductRelatedDetail.java`, `LoanProductConstants.java`, `LoanProductDataValidator.java`, `LoanProductAssembler.java`, `LoanProductData.java`, `LoanProductsApiResourceSwagger.java`, `0236_add_accrual_day_count_convention.xml`, `changelog-tenant.xml` |
| **R1+R2** — apply at accrual time | `AbstractCumulativeLoanScheduleGenerator.java` (method `getPeriodInterestTillDate`, L2828–L2860) |
| **R3** — correct GL postings | `AccrualBasedAccountingProcessorForLoan.java`, `LoanJournalEntryPoster.java` (REUSED unchanged) |
| **R4** — acceptance correctness | `InterestAccrualDayCount.feature`, `InterestAccrualDayCountStepDef.java`, `*DayCountCalculatorTest.java` |

## Traceability — Acceptance Scenarios → Conventions

| Scenario | Boundary exercised | Conventions (rows) |
|----------|--------------------|--------------------|
| **S1** Base one-month period | Standard 31-day month | Actual/360 (430.56), Actual/365 (424.66), 30/360 (416.67) |
| **S2** Full non-leap year | 365-day year (Actual/365 fraction = 1; 30/360 = 1) | Actual/360, Actual/365, 30/360 (30/360 = 5000.00) |
| **S3** Leap-year February | 29-day February vs 30/360 = 30 days | Actual/360, Actual/365, 30/360 (30/360 = 885.42 for principal 250000 @ 4.25%) |
| **S4** Quarter crossing a 31st month-end | End-day 31 NOT adjusted (start not 30/31) ⇒ 90 days | Actual/360, Actual/365, 30/360 (30/360 = 1250.00, fraction 0.25) |
| **S5** Single-day period | Minimal 1-day accrual | Actual/360 (101.39 for principal 1000000 @ 3.65%), Actual/365, 30/360 |
| **S6** Zero-day boundary | `start == end` ⇒ accrue 0.00 with no divide-by-zero | Actual/360, Actual/365, 30/360 (all 0.00) |

> The dataset is 18 rows (6 scenarios × 3 conventions). The ONLY asserted output is `expected_accrued_interest`; all other CSV columns
> (`day_count_days`, `day_count_fraction`, `notes`, etc.) are reference-only and MUST NOT be asserted. The committed CSV at
> `fineract-e2e-tests-runner/src/test/resources/features/InterestAccrualDayCount.csv` is READ-ONLY and must NEVER be modified, reordered,
> deleted, or extended.

## Observability — Reused vs Added (Rule 3)

Observability ships with the feature by reusing Fineract's existing tooling and adding only feature-specific, additive signals. The
reused-versus-added split is recorded below.

### Reused (verified present)

- SLF4J + Logback structured logging (`@Slf4j`).
- MDC-based correlation IDs via `CorrelationHeaderFilter` + `MDCWrapper`.
- Spring Boot Actuator + Micrometer Prometheus metrics at `/fineract-provider/actuator/prometheus`.
- Grafana Tempo distributed tracing.
- Provisioned Grafana dashboards `config/docker/grafana/dashboards/fineract-spring-boot.json` and `fineract-loki.json`, with datasources
  `config/docker/grafana/datasources/datasource.yml`.
- Local observability stack `config/docker/compose/observability.yml` (Loki 2.9.2, Prometheus v2.47.2, Grafana 10.2.0, Tempo 2.2.4).
- Actuator health/readiness endpoints.

### Added (feature-specific, additive)

- A structured DEBUG log line at the single accrual change point (`AbstractCumulativeLoanScheduleGenerator.getPeriodInterestTillDate`),
  guarded by `log.isDebugEnabled()`, emitting loan id, convention, period start/end, target date, full/partial day-count days, full/partial
  day-count fractions, the period interest, and the computed accrued amount — automatically correlated by the existing MDC. The message
  contains the phrase "day-count convention" so the dashboard's Loki panels match the `(?i)day.?count` regex (see D16).
- Two Micrometer meters tagged `convention` (label values `actual_360`, `actual_365`, `thirty_360_us`), emitted via `Metrics.globalRegistry`
  and surfaced on the existing Prometheus endpoint: a Counter `fineract.accrual.daycount.computations` (→ `*_total`) and a companion Timer
  `fineract.accrual.daycount.computations.duration` (→ `*_duration_seconds_{sum,count,max}`). Two distinct names are required because
  Micrometer forbids a Counter and a Timer sharing a name (see D14, D15).
- A new Grafana dashboard template `config/docker/grafana/dashboards/fineract-interest-accrual-daycount.json` reusing the existing
  datasources; its single timing panel queries the `_duration_seconds_*` series (the only panel realigned for D14).

## 30/360 US Day-Count Rule (Context)

This grounding context supports decisions D6 and D8 and the S4 acceptance boundary; it is descriptive only. The 30/360 US (bond basis) day
count is `360·(Y2−Y1) + 30·(M2−M1) + (D2−D1)`, divided by 360 for the fraction. Month-end adjustments are applied in order: if `D1 = 31`
then `D1 → 30`; then if `D2 = 31` **and** `D1 ∈ {30, 31}` then `D2 → 30`. Crucially, an end day of 31 is **not** adjusted when the start day
is neither 30 nor 31 — which is exactly the S4 behavior (`2025-01-01 → 2025-03-31` ⇒ 90 days, fraction 0.25). The two actual conventions are
simpler: **Actual/360** divides the actual elapsed days by 360, and **Actual/365 (Fixed)** divides the actual elapsed days by a fixed 365
denominator. All three guard the zero-day boundary (`start == end ⇒ fraction 0`, accrued `0.00`) so there is no divide-by-zero.
