@WorkingCapitalNearBreachEvaluationFeature
Feature: Working Capital Near Breach Evaluation

  @TestRailId:C76635
  Scenario: Verify near breach detected when outstanding exceeds threshold at evaluation date
    When Admin sets the business date to "01 January 2026"
    And Admin creates a client with random data
    And Admin creates a Working Capital Loan Product with breach and near breach config and overrides enabled:
      | breachFrequency | breachFrequencyType | breachAmountCalculationType | breachAmount | nearBreachFrequency | nearBreachFrequencyType | nearBreachThreshold | delinquencyGraceDays |
      | 3               | MONTHS              | FLAT                        | 900          | 60                  | DAYS                    | 33.33               |                      |
    And Admin creates a working capital loan using created product with the following data:
      | submittedOnDate | expectedDisbursementDate | principalAmount | totalPayment | periodPaymentRate | discount |
      | 01 January 2026 | 01 January 2026          | 9000            | 100000       | 18                | 0        |
    And Admin successfully approves the working capital loan on "01 January 2026" with "9000" amount and expected disbursement date on "01 January 2026"
    When Admin successfully disburse the Working Capital loan on "01 January 2026" with "9000" EUR transaction amount
    And Admin runs inline COB job for Working Capital Loan by loanId
    # Period 1: 01-01 -> 03-31, freq=60d -> 1 eval at 03-02 (required = 33.33% of 900 = 299.97)
    # No payment -> window [01-01, 03-02] paid=0 < 299.97 -> trigger Y
    When Admin sets the business date to "03 March 2026"
    And Admin runs inline COB job for Working Capital Loan by loanId
    Then Working Capital loan breach schedule has the following data:
      | periodNumber | fromDate   | toDate     | minPaymentAmount | outstandingAmount | nearBreach | breach |
      | 1            | 2026-01-01 | 2026-03-31 | 900.00           | 900.00            | true       | null   |

  @TestRailId:C76636
  Scenario: Verify near breach not triggered when payment brings outstanding below threshold before evaluation date
    When Admin sets the business date to "01 January 2026"
    And Admin creates a client with random data
    And Admin creates a Working Capital Loan Product with breach and near breach config and overrides enabled:
      | breachFrequency | breachFrequencyType | breachAmountCalculationType | breachAmount | nearBreachFrequency | nearBreachFrequencyType | nearBreachThreshold | delinquencyGraceDays |
      | 3               | MONTHS              | FLAT                        | 900          | 60                  | DAYS                    | 33.33               |                      |
    And Admin creates a working capital loan using created product with the following data:
      | submittedOnDate | expectedDisbursementDate | principalAmount | totalPayment | periodPaymentRate | discount |
      | 01 January 2026 | 01 January 2026          | 9000            | 100000       | 18                | 0        |
    And Admin successfully approves the working capital loan on "01 January 2026" with "9000" amount and expected disbursement date on "01 January 2026"
    When Admin successfully disburse the Working Capital loan on "01 January 2026" with "9000" EUR transaction amount
    And Admin runs inline COB job for Working Capital Loan by loanId
    # Period 1: 01-01 -> 03-31, freq=60d -> 1 eval at 03-02 (required = 299.97)
    # Pay 700 on 15 Feb -> window [01-01, 03-02] paid=700 >= 299.97 -> not trigger
    # After period end (31 Mar) -> nearBreach=false; outstanding=200>0 -> breach=true
    When Admin sets the business date to "15 February 2026"
    And Customer makes repayment on "15 February 2026" with 700.0 transaction amount on Working Capital loan
    When Admin sets the business date to "01 April 2026"
    And Admin runs inline COB job for Working Capital Loan by loanId
    Then Working Capital loan breach schedule has the following data:
      | periodNumber | fromDate   | toDate     | minPaymentAmount | outstandingAmount | nearBreach | breach |
      | 1            | 2026-01-01 | 2026-03-31 | 900.00           | 200.00            | false      | true   |
      | 2            | 2026-04-01 | 2026-06-30 | 900.00           | 900.00            | null       | null   |

  @TestRailId:C76637
  Scenario: Verify near breach null when no near breach config on product
    When Admin sets the business date to "01 January 2026"
    And Admin creates a client with random data
    And Admin creates a Working Capital Loan Product with custom breach config and overrides enabled:
      | breachFrequency | breachFrequencyType | breachAmountCalculationType | breachAmount | delinquencyGraceDays |
      | 1               | MONTHS              | FLAT                        | 500          |                      |
    And Admin creates a working capital loan using created product with the following data:
      | submittedOnDate | expectedDisbursementDate | principalAmount | totalPayment | periodPaymentRate | discount |
      | 01 January 2026 | 01 January 2026          | 9000            | 100000       | 18                | 0        |
    And Admin successfully approves the working capital loan on "01 January 2026" with "9000" amount and expected disbursement date on "01 January 2026"
    When Admin successfully disburse the Working Capital loan on "01 January 2026" with "9000" EUR transaction amount
    And Admin runs inline COB job for Working Capital Loan by loanId
    When Admin sets the business date to "01 February 2026"
    And Admin runs inline COB job for Working Capital Loan by loanId
    Then Working Capital loan breach schedule has the following data:
      | periodNumber | fromDate   | toDate     | minPaymentAmount | outstandingAmount | nearBreach | breach |
      | 1            | 2026-01-01 | 2026-01-31 | 500.00           | 500.00            | null       | true   |
      | 2            | 2026-02-01 | 2026-02-28 | 500.00           | 500.00            | null       | null   |

  @TestRailId:C76638
  Scenario: Verify near breach is immutable - stays true after subsequent payment
    When Admin sets the business date to "01 January 2026"
    And Admin creates a client with random data
    And Admin creates a Working Capital Loan Product with breach and near breach config and overrides enabled:
      | breachFrequency | breachFrequencyType | breachAmountCalculationType | breachAmount | nearBreachFrequency | nearBreachFrequencyType | nearBreachThreshold | delinquencyGraceDays |
      | 3               | MONTHS              | FLAT                        | 900          | 60                  | DAYS                    | 33.33               |                      |
    And Admin creates a working capital loan using created product with the following data:
      | submittedOnDate | expectedDisbursementDate | principalAmount | totalPayment | periodPaymentRate | discount |
      | 01 January 2026 | 01 January 2026          | 9000            | 100000       | 18                | 0        |
    And Admin successfully approves the working capital loan on "01 January 2026" with "9000" amount and expected disbursement date on "01 January 2026"
    When Admin successfully disburse the Working Capital loan on "01 January 2026" with "9000" EUR transaction amount
    And Admin runs inline COB job for Working Capital Loan by loanId
    # No payment -> window [01-01, 03-02] paid=0 < 299.97 -> trigger Y at eval 03-02
    When Admin sets the business date to "03 March 2026"
    And Admin runs inline COB job for Working Capital Loan by loanId
    Then Working Capital loan breach schedule has the following data:
      | periodNumber | fromDate   | toDate     | minPaymentAmount | outstandingAmount | nearBreach | breach |
      | 1            | 2026-01-01 | 2026-03-31 | 900.00           | 900.00            | true       | null   |
    # Now pay full amount - near breach must stay true (immutable)
    When Admin sets the business date to "15 March 2026"
    And Customer makes repayment on "15 March 2026" with 900.0 transaction amount on Working Capital loan
    When Admin sets the business date to "01 April 2026"
    And Admin runs inline COB job for Working Capital Loan by loanId
    Then Working Capital loan breach schedule has the following data:
      | periodNumber | fromDate   | toDate     | minPaymentAmount | outstandingAmount | nearBreach | breach |
      | 1            | 2026-01-01 | 2026-03-31 | 900.00           | 0.00              | true       | false  |
      | 2            | 2026-04-01 | 2026-06-30 | 900.00           | 900.00            | null       | null   |

  @TestRailId:C76640
  Scenario: Verify near breach evaluation before eval date - near breach stays null
    When Admin sets the business date to "01 January 2026"
    And Admin creates a client with random data
    And Admin creates a Working Capital Loan Product with breach and near breach config and overrides enabled:
      | breachFrequency | breachFrequencyType | breachAmountCalculationType | breachAmount | nearBreachFrequency | nearBreachFrequencyType | nearBreachThreshold | delinquencyGraceDays |
      | 3               | MONTHS              | FLAT                        | 900          | 60                  | DAYS                    | 33.33               |                      |
    And Admin creates a working capital loan using created product with the following data:
      | submittedOnDate | expectedDisbursementDate | principalAmount | totalPayment | periodPaymentRate | discount |
      | 01 January 2026 | 01 January 2026          | 9000            | 100000       | 18                | 0        |
    And Admin successfully approves the working capital loan on "01 January 2026" with "9000" amount and expected disbursement date on "01 January 2026"
    When Admin successfully disburse the Working Capital loan on "01 January 2026" with "9000" EUR transaction amount
    And Admin runs inline COB job for Working Capital Loan by loanId
    # freq=60d -> 1 eval at 03-02. COB on 01 Mar -> evalDate not yet passed -> nearBreach stays null
    When Admin sets the business date to "01 March 2026"
    And Admin runs inline COB job for Working Capital Loan by loanId
    Then Working Capital loan breach schedule has the following data:
      | periodNumber | fromDate   | toDate     | minPaymentAmount | outstandingAmount | nearBreach | breach |
      | 1            | 2026-01-01 | 2026-03-31 | 900.00           | 900.00            | null       | null   |

  @TestRailId:C76641
  Scenario: Verify near breach with PERCENTAGE breach amount and WEEKS near breach frequency
    When Admin sets the business date to "01 January 2026"
    And Admin creates a client with random data
    And Admin creates a Working Capital Loan Product with breach and near breach config and overrides enabled:
      | breachFrequency | breachFrequencyType | breachAmountCalculationType | breachAmount | nearBreachFrequency | nearBreachFrequencyType | nearBreachThreshold | delinquencyGraceDays |
      | 2               | MONTHS              | PERCENTAGE                  | 10           | 2                   | WEEKS                   | 50                  |                      |
    And Admin creates a working capital loan using created product with the following data:
      | submittedOnDate | expectedDisbursementDate | principalAmount | totalPayment | periodPaymentRate | discount |
      | 01 January 2026 | 01 January 2026          | 9000            | 100000       | 18                | 0        |
    And Admin successfully approves the working capital loan on "01 January 2026" with "9000" amount and expected disbursement date on "01 January 2026"
    When Admin successfully disburse the Working Capital loan on "01 January 2026" with "9000" EUR transaction amount
    And Admin runs inline COB job for Working Capital Loan by loanId
    # Period 1: 01-01 -> 02-28 (2 months -1 day), minPayment=10% of 9000=900
    # freq=2 weeks -> 4 evals: 01-15, 01-29, 02-12, 02-26 (required = 50% of 900 = 450)
    # No payment -> window#1 [01-01, 01-15] paid=0 < 450 -> trigger Y at eval#1
    When Admin sets the business date to "16 January 2026"
    And Admin runs inline COB job for Working Capital Loan by loanId
    Then Working Capital loan breach schedule has the following data:
      | periodNumber | fromDate   | toDate     | minPaymentAmount | outstandingAmount | nearBreach | breach |
      | 1            | 2026-01-01 | 2026-02-28 | 900.00           | 900.00            | true       | null   |

  @TestRailId:C76642
  Scenario: Verify near breach not triggered when outstanding equals threshold exactly - strict greater than
    When Admin sets the business date to "01 January 2026"
    And Admin creates a client with random data
    And Admin creates a Working Capital Loan Product with breach and near breach config and overrides enabled:
      | breachFrequency | breachFrequencyType | breachAmountCalculationType | breachAmount | nearBreachFrequency | nearBreachFrequencyType | nearBreachThreshold | delinquencyGraceDays |
      | 3               | MONTHS              | FLAT                        | 900          | 60                  | DAYS                    | 50                  |                      |
    And Admin creates a working capital loan using created product with the following data:
      | submittedOnDate | expectedDisbursementDate | principalAmount | totalPayment | periodPaymentRate | discount |
      | 01 January 2026 | 01 January 2026          | 9000            | 100000       | 18                | 0        |
    And Admin successfully approves the working capital loan on "01 January 2026" with "9000" amount and expected disbursement date on "01 January 2026"
    When Admin successfully disburse the Working Capital loan on "01 January 2026" with "9000" EUR transaction amount
    And Admin runs inline COB job for Working Capital Loan by loanId
    # freq=60d -> 1 eval at 03-02 (required = 50% of 900 = 450)
    # Pay 450 on 15 Jan -> window paid=450; strict less-than means 450 is NOT below 450 -> not trigger
    # After period end -> nearBreach=false; outstanding=450>0 -> breach=true
    When Admin sets the business date to "15 January 2026"
    And Customer makes repayment on "15 January 2026" with 450.0 transaction amount on Working Capital loan
    When Admin sets the business date to "01 April 2026"
    And Admin runs inline COB job for Working Capital Loan by loanId
    Then Working Capital loan breach schedule has the following data:
      | periodNumber | fromDate   | toDate     | minPaymentAmount | outstandingAmount | nearBreach | breach |
      | 1            | 2026-01-01 | 2026-03-31 | 900.00           | 450.00            | false      | true   |
      | 2            | 2026-04-01 | 2026-06-30 | 900.00           | 900.00            | null       | null   |

  @TestRailId:C76643
  Scenario: Verify near breach evaluated independently per breach period
    When Admin sets the business date to "01 January 2026"
    And Admin creates a client with random data
    And Admin creates a Working Capital Loan Product with breach and near breach config and overrides enabled:
      | breachFrequency | breachFrequencyType | breachAmountCalculationType | breachAmount | nearBreachFrequency | nearBreachFrequencyType | nearBreachThreshold | delinquencyGraceDays |
      | 1               | MONTHS              | FLAT                        | 500          | 15                  | DAYS                    | 50                  |                      |
    And Admin creates a working capital loan using created product with the following data:
      | submittedOnDate | expectedDisbursementDate | principalAmount | totalPayment | periodPaymentRate | discount |
      | 01 January 2026 | 01 January 2026          | 9000            | 100000       | 18                | 0        |
    And Admin successfully approves the working capital loan on "01 January 2026" with "9000" amount and expected disbursement date on "01 January 2026"
    When Admin successfully disburse the Working Capital loan on "01 January 2026" with "9000" EUR transaction amount
    And Admin runs inline COB job for Working Capital Loan by loanId
    # Period 1: 01-01 -> 01-31, freq=15d -> 2 evals: 01-16, 01-31 (required = 50% of 500 = 250)
    # No payment in P1 -> window#1 [01-01, 01-16] paid=0 < 250 -> nearBreach=true at eval#1
    # Period 2: 02-01 -> 02-28, 1 eval at 02-16; pay 300 in P2 -> window paid=300 >= 250 -> not trigger
    # Run COB first so period 2 is generated, then pay 300 in period 2
    When Admin sets the business date to "05 February 2026"
    And Admin runs inline COB job for Working Capital Loan by loanId
    And Customer makes repayment on "05 February 2026" with 300.0 transaction amount on Working Capital loan
    When Admin sets the business date to "01 March 2026"
    And Admin runs inline COB job for Working Capital Loan by loanId
    Then Working Capital loan breach schedule has the following data:
      | periodNumber | fromDate   | toDate     | minPaymentAmount | outstandingAmount | nearBreach | breach |
      | 1            | 2026-01-01 | 2026-01-31 | 500.00           | 500.00            | true       | true   |
      | 2            | 2026-02-01 | 2026-02-28 | 500.00           | 200.00            | false      | true   |
      | 3            | 2026-03-01 | 2026-03-31 | 500.00           | 500.00            | null       | null   |

  @TestRailId:C76644
  Scenario: Verify near breach with non-zero grace days shifts breach period and eval dates
    When Admin sets the business date to "01 January 2026"
    And Admin creates a client with random data
    And Admin creates a Working Capital Loan Product with breach and near breach config and overrides enabled:
      | breachFrequency | breachFrequencyType | breachAmountCalculationType | breachAmount | nearBreachFrequency | nearBreachFrequencyType | nearBreachThreshold | delinquencyGraceDays |
      | 3               | MONTHS              | FLAT                        | 900          | 60                  | DAYS                    | 33.33               | 10                   |
    And Admin creates a working capital loan using created product with the following data:
      | submittedOnDate | expectedDisbursementDate | principalAmount | totalPayment | periodPaymentRate | discount |
      | 01 January 2026 | 01 January 2026          | 9000            | 100000       | 18                | 0        |
    And Admin successfully approves the working capital loan on "01 January 2026" with "9000" amount and expected disbursement date on "01 January 2026"
    When Admin successfully disburse the Working Capital loan on "01 January 2026" with "9000" EUR transaction amount
    And Admin runs inline COB job for Working Capital Loan by loanId
    # graceDays=10 -> Period 1: 01-11 -> 04-10; freq=60d -> 1 eval at 03-12 (required = 33.33% of 900 = 299.97)
    # No payment -> window [01-11, 03-12] paid=0 < 299.97 -> trigger Y
    When Admin sets the business date to "13 March 2026"
    And Admin runs inline COB job for Working Capital Loan by loanId
    Then Working Capital loan breach schedule has the following data:
      | periodNumber | fromDate   | toDate     | minPaymentAmount | outstandingAmount | nearBreach | breach |
      | 1            | 2026-01-11 | 2026-04-10 | 900.00           | 900.00            | true       | null   |

  @TestRailId:C76645
  Scenario: Verify near breach with PERCENTAGE breach amount and non-zero discount
    When Admin sets the business date to "01 January 2026"
    And Admin creates a client with random data
    And Admin creates a Working Capital Loan Product with breach and near breach config and overrides enabled:
      | breachFrequency | breachFrequencyType | breachAmountCalculationType | breachAmount | nearBreachFrequency | nearBreachFrequencyType | nearBreachThreshold | delinquencyGraceDays |
      | 2               | MONTHS              | PERCENTAGE                  | 10           | 30                  | DAYS                    | 50                  |                      |
    And Admin creates a working capital loan using created product with the following data:
      | submittedOnDate | expectedDisbursementDate | principalAmount | totalPayment | periodPaymentRate | discount |
      | 01 January 2026 | 01 January 2026          | 9000            | 100000       | 18                | 500      |
    And Admin successfully approves the working capital loan on "01 January 2026" with "9000" amount and "500" discount amount and expected disbursement date on "01 January 2026"
    When Admin successfully disburse the Working Capital loan on "01 January 2026" with "9000" EUR transaction amount and "500" discount amount
    And Admin runs inline COB job for Working Capital Loan by loanId
    # minPayment = 10% of (9000 + 500 discount) = 950; freq=30d -> 1 eval at 01-31 (required = 50% of 950 = 475)
    # No payment -> window [01-01, 01-31] paid=0 < 475 -> trigger Y
    When Admin sets the business date to "01 February 2026"
    And Admin runs inline COB job for Working Capital Loan by loanId
    Then Working Capital loan breach schedule has the following data:
      | periodNumber | fromDate   | toDate     | minPaymentAmount | outstandingAmount | nearBreach | breach |
      | 1            | 2026-01-01 | 2026-02-28 | 950.00           | 950.00            | true       | null   |

  @TestRailId:C76646
  Scenario: Verify near breach stays null when eval date falls outside period due to February short month
    # Near breach freq=29 DAYS passes validation vs 1 MONTH (29 < 30 in comparator)
    # But in February (28 days), eval date = Feb 1 + 29 = Mar 2 which is outside the period
    When Admin sets the business date to "01 February 2026"
    And Admin creates a client with random data
    And Admin creates a Working Capital Loan Product with breach and near breach config and overrides enabled:
      | breachFrequency | breachFrequencyType | breachAmountCalculationType | breachAmount | nearBreachFrequency | nearBreachFrequencyType | nearBreachThreshold | delinquencyGraceDays |
      | 1               | MONTHS              | FLAT                        | 500          | 29                  | DAYS                    | 50                  |                      |
    And Admin creates a working capital loan using created product with the following data:
      | submittedOnDate  | expectedDisbursementDate | principalAmount | totalPayment | periodPaymentRate | discount |
      | 01 February 2026 | 01 February 2026         | 9000            | 100000       | 18                | 0        |
    And Admin successfully approves the working capital loan on "01 February 2026" with "9000" amount and expected disbursement date on "01 February 2026"
    When Admin successfully disburse the Working Capital loan on "01 February 2026" with "9000" EUR transaction amount
    And Admin runs inline COB job for Working Capital Loan by loanId
    When Admin sets the business date to "01 April 2026"
    And Admin runs inline COB job for Working Capital Loan by loanId
    Then Working Capital loan breach schedule has the following data:
      | periodNumber | fromDate   | toDate     | minPaymentAmount | outstandingAmount | nearBreach | breach |
      | 1            | 2026-02-01 | 2026-02-28 | 500.00           | 500.00            | null       | true   |
      | 2            | 2026-03-01 | 2026-03-31 | 500.00           | 500.00            | true       | true   |
      | 3            | 2026-04-01 | 2026-04-30 | 500.00           | 500.00            | null       | null   |

  @TestRailId:C76647
  Scenario: Verify near breach eval date exactly on period end - both evaluated in same COB run
    When Admin sets the business date to "01 January 2026"
    And Admin creates a client with random data
    And Admin creates a Working Capital Loan Product with breach and near breach config and overrides enabled:
      | breachFrequency | breachFrequencyType | breachAmountCalculationType | breachAmount | nearBreachFrequency | nearBreachFrequencyType | nearBreachThreshold | delinquencyGraceDays |
      | 2               | MONTHS              | FLAT                        | 500          | 58                  | DAYS                    | 50                  |                      |
    And Admin creates a working capital loan using created product with the following data:
      | submittedOnDate | expectedDisbursementDate | principalAmount | totalPayment | periodPaymentRate | discount |
      | 01 January 2026 | 01 January 2026          | 9000            | 100000       | 18                | 0        |
    And Admin successfully approves the working capital loan on "01 January 2026" with "9000" amount and expected disbursement date on "01 January 2026"
    When Admin successfully disburse the Working Capital loan on "01 January 2026" with "9000" EUR transaction amount
    And Admin runs inline COB job for Working Capital Loan by loanId
    # freq=58d, breach=2m -> 1 eval at 02-28 (boundary: eval falls exactly on toDate); required = 50% of 500 = 250
    # No payment -> window [01-01, 02-28] paid=0 < 250 -> trigger Y
    When Admin sets the business date to "01 March 2026"
    And Admin runs inline COB job for Working Capital Loan by loanId
    Then Working Capital loan breach schedule has the following data:
      | periodNumber | fromDate   | toDate     | minPaymentAmount | outstandingAmount | nearBreach | breach |
      | 1            | 2026-01-01 | 2026-02-28 | 500.00           | 500.00            | true       | true   |
      | 2            | 2026-03-01 | 2026-04-30 | 500.00           | 500.00            | null       | null   |

  @TestRailId:C76648
  Scenario: Verify near breach not triggered with multiple partial payments bringing outstanding below threshold
    When Admin sets the business date to "01 January 2026"
    And Admin creates a client with random data
    And Admin creates a Working Capital Loan Product with breach and near breach config and overrides enabled:
      | breachFrequency | breachFrequencyType | breachAmountCalculationType | breachAmount | nearBreachFrequency | nearBreachFrequencyType | nearBreachThreshold | delinquencyGraceDays |
      | 3               | MONTHS              | FLAT                        | 900          | 60                  | DAYS                    | 50                  |                      |
    And Admin creates a working capital loan using created product with the following data:
      | submittedOnDate | expectedDisbursementDate | principalAmount | totalPayment | periodPaymentRate | discount |
      | 01 January 2026 | 01 January 2026          | 9000            | 100000       | 18                | 0        |
    And Admin successfully approves the working capital loan on "01 January 2026" with "9000" amount and expected disbursement date on "01 January 2026"
    When Admin successfully disburse the Working Capital loan on "01 January 2026" with "9000" EUR transaction amount
    And Admin runs inline COB job for Working Capital Loan by loanId
    # freq=60d -> 1 eval at 03-02 (required = 50% of 900 = 450)
    # 3 payments: 200(10 Jan) + 150(25 Jan) + 200(15 Feb) = 550 in window [01-01, 03-02] -> 550 >= 450 -> not trigger
    # After period end -> nearBreach=false; outstanding=350>0 -> breach=true
    When Admin sets the business date to "10 January 2026"
    And Customer makes repayment on "10 January 2026" with 200.0 transaction amount on Working Capital loan
    When Admin sets the business date to "25 January 2026"
    And Customer makes repayment on "25 January 2026" with 150.0 transaction amount on Working Capital loan
    When Admin sets the business date to "15 February 2026"
    And Customer makes repayment on "15 February 2026" with 200.0 transaction amount on Working Capital loan
    When Admin sets the business date to "01 April 2026"
    And Admin runs inline COB job for Working Capital Loan by loanId
    Then Working Capital loan breach schedule has the following data:
      | periodNumber | fromDate   | toDate     | minPaymentAmount | outstandingAmount | nearBreach | breach |
      | 1            | 2026-01-01 | 2026-03-31 | 900.00           | 350.00            | false      | true   |
      | 2            | 2026-04-01 | 2026-06-30 | 900.00           | 900.00            | null       | null   |

  @TestRailId:C76649
  Scenario: Verify near breach false and breach false when full payment made before first eval date
    When Admin sets the business date to "01 January 2026"
    And Admin creates a client with random data
    And Admin creates a Working Capital Loan Product with breach and near breach config and overrides enabled:
      | breachFrequency | breachFrequencyType | breachAmountCalculationType | breachAmount | nearBreachFrequency | nearBreachFrequencyType | nearBreachThreshold | delinquencyGraceDays |
      | 3               | MONTHS              | FLAT                        | 900          | 60                  | DAYS                    | 33.33               |                      |
    And Admin creates a working capital loan using created product with the following data:
      | submittedOnDate | expectedDisbursementDate | principalAmount | totalPayment | periodPaymentRate | discount |
      | 01 January 2026 | 01 January 2026          | 9000            | 100000       | 18                | 0        |
    And Admin successfully approves the working capital loan on "01 January 2026" with "9000" amount and expected disbursement date on "01 January 2026"
    When Admin successfully disburse the Working Capital loan on "01 January 2026" with "9000" EUR transaction amount
    And Admin runs inline COB job for Working Capital Loan by loanId
    # freq=60d -> 1 eval at 03-02 (required = 33.33% of 900 = 299.97)
    # Pay 900 on 15 Jan (full) -> window [01-01, 03-02] paid=900 >= 299.97 -> not trigger
    # After period end -> nearBreach=false; outstanding=0 -> breach=false (immediate via applyRepayment)
    When Admin sets the business date to "15 January 2026"
    And Customer makes repayment on "15 January 2026" with 900.0 transaction amount on Working Capital loan
    When Admin sets the business date to "01 April 2026"
    And Admin runs inline COB job for Working Capital Loan by loanId
    Then Working Capital loan breach schedule has the following data:
      | periodNumber | fromDate   | toDate     | minPaymentAmount | outstandingAmount | nearBreach | breach |
      | 1            | 2026-01-01 | 2026-03-31 | 900.00           | 0.00              | false      | false  |
      | 2            | 2026-04-01 | 2026-06-30 | 900.00           | 900.00            | null       | null   |

  @TestRailId:C76650
  Scenario: Verify near breach evaluated correctly across 4 consecutive breach periods with mixed results
    When Admin sets the business date to "01 January 2026"
    And Admin creates a client with random data
    And Admin creates a Working Capital Loan Product with breach and near breach config and overrides enabled:
      | breachFrequency | breachFrequencyType | breachAmountCalculationType | breachAmount | nearBreachFrequency | nearBreachFrequencyType | nearBreachThreshold | delinquencyGraceDays |
      | 1               | MONTHS              | FLAT                        | 300          | 15                  | DAYS                    | 50                  |                      |
    And Admin creates a working capital loan using created product with the following data:
      | submittedOnDate | expectedDisbursementDate | principalAmount | totalPayment | periodPaymentRate | discount |
      | 01 January 2026 | 01 January 2026          | 9000            | 100000       | 18                | 0        |
    And Admin successfully approves the working capital loan on "01 January 2026" with "9000" amount and expected disbursement date on "01 January 2026"
    When Admin successfully disburse the Working Capital loan on "01 January 2026" with "9000" EUR transaction amount
    And Admin runs inline COB job for Working Capital Loan by loanId
    When Admin sets the business date to "01 February 2026"
    And Admin runs inline COB job for Working Capital Loan by loanId
    Then Working Capital loan breach schedule has the following data:
      | periodNumber | fromDate   | toDate     | minPaymentAmount | outstandingAmount | nearBreach | breach |
      | 1            | 2026-01-01 | 2026-01-31 | 300.00           | 300.00            | true       | true   |
      | 2            | 2026-02-01 | 2026-02-28 | 300.00           | 300.00            | null       | null   |
    # --- P2: pay 200 -> window#1 [02-01, 02-16] paid=200 >= 150 -> nearBreach=false; outstanding=100>0 -> breach=true ---
    When Admin sets the business date to "05 February 2026"
    And Customer makes repayment on "05 February 2026" with 200.0 transaction amount on Working Capital loan
    When Admin sets the business date to "01 March 2026"
    And Admin runs inline COB job for Working Capital Loan by loanId
    Then Working Capital loan breach schedule has the following data:
      | periodNumber | fromDate   | toDate     | minPaymentAmount | outstandingAmount | nearBreach | breach |
      | 1            | 2026-01-01 | 2026-01-31 | 300.00           | 300.00            | true       | true   |
      | 2            | 2026-02-01 | 2026-02-28 | 300.00           | 100.00            | false      | true   |
      | 3            | 2026-03-01 | 2026-03-31 | 300.00           | 300.00            | null       | null   |
    # --- P3: no payment -> window#1 [03-01, 03-16] paid=0 < 150 -> nearBreach=true; breach=true ---
    When Admin sets the business date to "01 April 2026"
    And Admin runs inline COB job for Working Capital Loan by loanId
    # --- P4: pay 300 on 04-01 -> window#1 [04-01, 04-16] paid=300 >= 150 -> nearBreach=false; outstanding=0 -> breach=false (immediate via applyRepayment) ---
    And Customer makes repayment on "01 April 2026" with 300.0 transaction amount on Working Capital loan
    When Admin sets the business date to "01 May 2026"
    And Admin runs inline COB job for Working Capital Loan by loanId
    Then Working Capital loan breach schedule has the following data:
      | periodNumber | fromDate   | toDate     | minPaymentAmount | outstandingAmount | nearBreach | breach |
      | 1            | 2026-01-01 | 2026-01-31 | 300.00           | 300.00            | true       | true   |
      | 2            | 2026-02-01 | 2026-02-28 | 300.00           | 100.00            | false      | true   |
      | 3            | 2026-03-01 | 2026-03-31 | 300.00           | 300.00            | true       | true   |
      | 4            | 2026-04-01 | 2026-04-30 | 300.00           | 0.00              | false      | false  |
      | 5            | 2026-05-01 | 2026-05-31 | 300.00           | 300.00            | null       | null   |

  @TestRailId:C76651
  Scenario: Verify non-disbursed loan has no breach schedule and no near breach evaluation
    When Admin sets the business date to "01 January 2026"
    And Admin creates a client with random data
    And Admin creates a Working Capital Loan Product with breach and near breach config and overrides enabled:
      | breachFrequency | breachFrequencyType | breachAmountCalculationType | breachAmount | nearBreachFrequency | nearBreachFrequencyType | nearBreachThreshold | delinquencyGraceDays |
      | 3               | MONTHS              | FLAT                        | 900          | 60                  | DAYS                    | 33.33               |                      |
    And Admin creates a working capital loan using created product with the following data:
      | submittedOnDate | expectedDisbursementDate | principalAmount | totalPayment | periodPaymentRate | discount |
      | 01 January 2026 | 01 January 2026          | 9000            | 100000       | 18                | 0        |
    And Admin successfully approves the working capital loan on "01 January 2026" with "9000" amount and expected disbursement date on "01 January 2026"
    # Loan is approved but NOT disbursed - no breach schedule should exist
    Then Working Capital loan breach schedule has no data

  Scenario: Verify near breach window#1 OK, window#2 fails with two eval points
    When Admin sets the business date to "01 January 2026"
    And Admin creates a client with random data
    And Admin creates a Working Capital Loan Product with breach and near breach config and overrides enabled:
      | breachFrequency | breachFrequencyType | breachAmountCalculationType | breachAmount | nearBreachFrequency | nearBreachFrequencyType | nearBreachThreshold | delinquencyGraceDays |
      | 3               | MONTHS              | FLAT                        | 900          | 30                  | DAYS                    | 33                  |                      |
    And Admin creates a working capital loan using created product with the following data:
      | submittedOnDate | expectedDisbursementDate | principalAmount | totalPayment | periodPaymentRate | discount |
      | 01 January 2026 | 01 January 2026          | 9000            | 100000       | 18                | 0        |
    And Admin successfully approves the working capital loan on "01 January 2026" with "9000" amount and expected disbursement date on "01 January 2026"
    When Admin successfully disburse the Working Capital loan on "01 January 2026" with "9000" EUR transaction amount
    And Admin runs inline COB job for Working Capital Loan by loanId
    # Period 1: 01-01 -> 03-31, freq=30d -> 2 evals: 01-31, 03-02 (required = 33% of 900 = 297)
    # Pay 300 on 15 Jan -> window#1 [01-01, 01-31] paid=300 >= 297 -> not trigger
    # Pay 100 on 10 Feb -> window#2 [02-01, 03-02] paid=100 < 297 -> trigger Y at eval#2
    When Admin sets the business date to "15 January 2026"
    And Customer makes repayment on "15 January 2026" with 300.0 transaction amount on Working Capital loan
    When Admin sets the business date to "10 February 2026"
    And Customer makes repayment on "10 February 2026" with 100.0 transaction amount on Working Capital loan
    When Admin sets the business date to "03 March 2026"
    And Admin runs inline COB job for Working Capital Loan by loanId
    Then Working Capital loan breach schedule has the following data:
      | periodNumber | fromDate   | toDate     | minPaymentAmount | outstandingAmount | nearBreach | breach |
      | 1            | 2026-01-01 | 2026-03-31 | 900.00           | 500.00            | true       | null   |

  Scenario: Verify near breach triggered when full minimum is paid front-loaded but no payment in later window
    When Admin sets the business date to "01 January 2026"
    And Admin creates a client with random data
    And Admin creates a Working Capital Loan Product with breach and near breach config and overrides enabled:
      | breachFrequency | breachFrequencyType | breachAmountCalculationType | breachAmount | nearBreachFrequency | nearBreachFrequencyType | nearBreachThreshold | delinquencyGraceDays |
      | 3               | MONTHS              | FLAT                        | 900          | 30                  | DAYS                    | 50                  |                      |
    And Admin creates a working capital loan using created product with the following data:
      | submittedOnDate | expectedDisbursementDate | principalAmount | totalPayment | periodPaymentRate | discount |
      | 01 January 2026 | 01 January 2026          | 9000            | 100000       | 18                | 0        |
    And Admin successfully approves the working capital loan on "01 January 2026" with "9000" amount and expected disbursement date on "01 January 2026"
    When Admin successfully disburse the Working Capital loan on "01 January 2026" with "9000" EUR transaction amount
    And Admin runs inline COB job for Working Capital Loan by loanId
    # Per-window regression guard: front-loaded over-payment in window#1, zero in window#2.
    # Period 1: 01-01 -> 03-31, freq=30d -> 2 evals: 01-31, 03-02 (required = 50% of 900 = 450)
    # Pay 900 on 11 Jan -> window#1 [01-01, 01-31] paid=900 >= 450 -> not trigger
    # Window#2 [02-01, 03-02] paid=0 < 450 -> trigger Y at eval#2 (cumulative-paid would be 900 >= 2x450 -> NO trigger; per-window canon expects trigger)
    When Admin sets the business date to "11 January 2026"
    And Customer makes repayment on "11 January 2026" with 900.0 transaction amount on Working Capital loan
    When Admin sets the business date to "03 March 2026"
    And Admin runs inline COB job for Working Capital Loan by loanId
    Then Working Capital loan breach schedule has the following data:
      | periodNumber | fromDate   | toDate     | minPaymentAmount | outstandingAmount | nearBreach | breach |
      | 1            | 2026-01-01 | 2026-03-31 | 900.00           | 0.00              | true       | false  |

  Scenario: Verify near breach false when payments meet required amount in every window across multi-eval period
    When Admin sets the business date to "01 January 2026"
    And Admin creates a client with random data
    And Admin creates a Working Capital Loan Product with breach and near breach config and overrides enabled:
      | breachFrequency | breachFrequencyType | breachAmountCalculationType | breachAmount | nearBreachFrequency | nearBreachFrequencyType | nearBreachThreshold | delinquencyGraceDays |
      | 3               | MONTHS              | FLAT                        | 900          | 30                  | DAYS                    | 33                  |                      |
    And Admin creates a working capital loan using created product with the following data:
      | submittedOnDate | expectedDisbursementDate | principalAmount | totalPayment | periodPaymentRate | discount |
      | 01 January 2026 | 01 January 2026          | 9000            | 100000       | 18                | 0        |
    And Admin successfully approves the working capital loan on "01 January 2026" with "9000" amount and expected disbursement date on "01 January 2026"
    When Admin successfully disburse the Working Capital loan on "01 January 2026" with "9000" EUR transaction amount
    And Admin runs inline COB job for Working Capital Loan by loanId
    # Period 1: 01-01 -> 03-31, evals: 01-31, 03-02 (required per window = 33% of 900 = 297)
    # Pay 300 on 01-15 -> window#1 [01-01,01-31] paid=300 >= 297 -> not trigger
    # Pay 300 on 02-15 -> window#2 [02-01,03-02] paid=300 >= 297 -> not trigger
    # After period end (04-01) -> all eval points passed, none triggered -> nearBreach=false, breach=true (outstanding=300>0)
    When Admin sets the business date to "15 January 2026"
    And Customer makes repayment on "15 January 2026" with 300.0 transaction amount on Working Capital loan
    When Admin sets the business date to "15 February 2026"
    And Customer makes repayment on "15 February 2026" with 300.0 transaction amount on Working Capital loan
    When Admin sets the business date to "01 April 2026"
    And Admin runs inline COB job for Working Capital Loan by loanId
    Then Working Capital loan breach schedule has the following data:
      | periodNumber | fromDate   | toDate     | minPaymentAmount | outstandingAmount | nearBreach | breach |
      | 1            | 2026-01-01 | 2026-03-31 | 900.00           | 300.00            | false      | true   |
      | 2            | 2026-04-01 | 2026-06-30 | 900.00           | 900.00            | null       | null   |
