@InterestAccrualDayCountFeature
Feature: Interest Accrual Day-Count Convention

  Acceptance coverage for the configurable interest-accrual day-count convention feature.
  Each row drives the real fineract-core day-count calculator (through the
  InterestAccrualDayCountStepDef step definitions) and asserts only the expected accrued
  interest. Rows mirror the committed dataset features/InterestAccrualDayCount.csv
  (6 scenarios x 3 conventions = 18 rows): S1 base one-month period, S2 full non-leap year,
  S3 leap-year February, S4 quarter crossing a 31st month-end, S5 single-day period,
  S6 zero-day boundary.

  Scenario Outline: Accrued interest matches the committed dataset for each day-count convention
    Then Accrued interest for principal "<principal>" annual rate "<annual_rate_pct>" percent day-count convention "<day_count_convention>" from "<start_date>" to "<end_date>" equals "<expected_accrued_interest>"

    Examples:
      | principal | annual_rate_pct | day_count_convention | start_date | end_date   | expected_accrued_interest |
      | 100000    | 5.0             | Actual/360           | 2025-01-01 | 2025-02-01 | 430.56                    |
      | 100000    | 5.0             | Actual/365           | 2025-01-01 | 2025-02-01 | 424.66                    |
      | 100000    | 5.0             | 30/360               | 2025-01-01 | 2025-02-01 | 416.67                    |
      | 100000    | 5.0             | Actual/360           | 2025-01-01 | 2026-01-01 | 5069.44                   |
      | 100000    | 5.0             | Actual/365           | 2025-01-01 | 2026-01-01 | 5000.00                   |
      | 100000    | 5.0             | 30/360               | 2025-01-01 | 2026-01-01 | 5000.00                   |
      | 250000    | 4.25            | Actual/360           | 2024-02-01 | 2024-03-01 | 855.90                    |
      | 250000    | 4.25            | Actual/365           | 2024-02-01 | 2024-03-01 | 844.18                    |
      | 250000    | 4.25            | 30/360               | 2024-02-01 | 2024-03-01 | 885.42                    |
      | 100000    | 5.0             | Actual/360           | 2025-01-01 | 2025-03-31 | 1236.11                   |
      | 100000    | 5.0             | Actual/365           | 2025-01-01 | 2025-03-31 | 1219.18                   |
      | 100000    | 5.0             | 30/360               | 2025-01-01 | 2025-03-31 | 1250.00                   |
      | 1000000   | 3.65            | Actual/360           | 2025-06-01 | 2025-06-02 | 101.39                    |
      | 1000000   | 3.65            | Actual/365           | 2025-06-01 | 2025-06-02 | 100.00                    |
      | 1000000   | 3.65            | 30/360               | 2025-06-01 | 2025-06-02 | 101.39                    |
      | 100000    | 5.0             | Actual/360           | 2025-01-01 | 2025-01-01 | 0.00                      |
      | 100000    | 5.0             | Actual/365           | 2025-01-01 | 2025-01-01 | 0.00                      |
      | 100000    | 5.0             | 30/360               | 2025-01-01 | 2025-01-01 | 0.00                      |
