/**
 * Licensed to the Apache Software Foundation (ASF) under one
 * or more contributor license agreements. See the NOTICE file
 * distributed with this work for additional information
 * regarding copyright ownership. The ASF licenses this file
 * to you under the Apache License, Version 2.0 (the
 * "License"); you may not use this file except in compliance
 * with the License. You may obtain a copy of the License at
 *
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing,
 * software distributed under the License is distributed on an
 * "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
 * KIND, either express or implied. See the License for the
 * specific language governing permissions and limitations
 * under the License.
 */
package org.apache.fineract.test.stepdef.accrual;

import static org.assertj.core.api.Assertions.assertThat;

import io.cucumber.java.en.Then;
import java.math.BigDecimal;
import java.math.MathContext;
import java.time.LocalDate;
import lombok.extern.slf4j.Slf4j;
import org.apache.fineract.portfolio.common.accrual.DayCountConventionCalculator;
import org.apache.fineract.portfolio.common.accrual.DayCountConventionCalculatorFactory;
import org.apache.fineract.portfolio.common.domain.DayCountConvention;
import org.apache.fineract.test.stepdef.AbstractStepDef;

// [Day-Count Convention feature] CSV-driven acceptance step definitions for interest-accrual day-count conventions.
// Drives the committed dataset (InterestAccrualDayCount.csv, 18 rows) through the REAL fineract-core calculator.
// Asserts ONLY expected_accrued_interest; no stubbing/mocking/hard-coding of the expected result.
@Slf4j
public class InterestAccrualDayCountStepDef extends AbstractStepDef {

    @Then("Accrued interest for principal {string} annual rate {string} percent day-count convention {string} from {string} to {string} equals {string}")
    public void accruedInterestEquals(final String principal, final String annualRatePercent, final String dayCountConvention,
            final String startDate, final String endDate, final String expectedAccruedInterest) {
        final BigDecimal principalAmount = new BigDecimal(principal.trim());
        final BigDecimal annualRatePct = new BigDecimal(annualRatePercent.trim());
        final LocalDate periodStart = LocalDate.parse(startDate.trim());
        final LocalDate periodEnd = LocalDate.parse(endDate.trim());
        final BigDecimal expected = new BigDecimal(expectedAccruedInterest.trim());

        final DayCountConvention convention = toConvention(dayCountConvention);
        final DayCountConventionCalculator calculator = DayCountConventionCalculatorFactory.forConvention(convention);

        // Real production calculation. MathContext.DECIMAL128 is intentional (NOT MoneyHelper.getMathContext()):
        // the E2E JVM has no Fineract tenant context, and the calculator rounds HALF_UP to 2dp internally regardless.
        final BigDecimal actual = calculator.accruedInterest(principalAmount, annualRatePct, periodStart, periodEnd,
                MathContext.DECIMAL128);

        log.debug("Accrued interest [{}] principal={} ratePct={} {}->{} actual={} expected={}", dayCountConvention, principalAmount,
                annualRatePct, periodStart, periodEnd, actual, expected);

        assertThat(actual.compareTo(expected))
                .as("Accrued interest for convention '%s' principal=%s rate=%s%% from %s to %s: expected %s but was %s", dayCountConvention,
                        principalAmount, annualRatePct, periodStart, periodEnd, expected, actual)
                .isZero();
    }

    private static DayCountConvention toConvention(final String token) {
        return switch (token.trim()) {
            case "Actual/360" -> DayCountConvention.ACTUAL_360;
            case "Actual/365" -> DayCountConvention.ACTUAL_365;
            case "30/360" -> DayCountConvention.THIRTY_360_US;
            default -> throw new IllegalArgumentException("Unknown day_count_convention token: '" + token + "'");
        };
    }
}
