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
package org.apache.fineract.portfolio.common.accrual;

import static org.assertj.core.api.Assertions.assertThat;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.time.LocalDate;
import org.apache.fineract.organisation.monetary.domain.MoneyHelper;
import org.junit.jupiter.api.Test;

/**
 * Unit tests for {@link Thirty360UsDayCountCalculator} (30/360 US bond-basis convention) covering the six boundary
 * cases (S1-S6) of the committed Interest-Accrual Day-Count acceptance dataset. S4 exercises the crux of the US rule:
 * the end-day 31 is NOT adjusted when the start day is not 30/31, yielding 90 days. Each test drives the real
 * production calculator and asserts the expected accrued interest rounded HALF_UP to currency precision.
 */
class Thirty360UsDayCountCalculatorTest {

    @Test
    void s1_baseOneMonthPeriod() {
        Thirty360UsDayCountCalculator calculator = new Thirty360UsDayCountCalculator();
        BigDecimal accrued = calculator.accruedInterest(new BigDecimal("100000"), new BigDecimal("5.0"), LocalDate.of(2025, 1, 1),
                LocalDate.of(2025, 2, 1), MoneyHelper.createMathContext(RoundingMode.HALF_UP));
        assertThat(accrued).isEqualByComparingTo(new BigDecimal("416.67"));
    }

    @Test
    void s2_fullNonLeapYear() {
        Thirty360UsDayCountCalculator calculator = new Thirty360UsDayCountCalculator();
        BigDecimal accrued = calculator.accruedInterest(new BigDecimal("100000"), new BigDecimal("5.0"), LocalDate.of(2025, 1, 1),
                LocalDate.of(2026, 1, 1), MoneyHelper.createMathContext(RoundingMode.HALF_UP));
        assertThat(accrued).isEqualByComparingTo(new BigDecimal("5000.00"));
    }

    @Test
    void s3_leapYearFebruary() {
        Thirty360UsDayCountCalculator calculator = new Thirty360UsDayCountCalculator();
        BigDecimal accrued = calculator.accruedInterest(new BigDecimal("250000"), new BigDecimal("4.25"), LocalDate.of(2024, 2, 1),
                LocalDate.of(2024, 3, 1), MoneyHelper.createMathContext(RoundingMode.HALF_UP));
        assertThat(accrued).isEqualByComparingTo(new BigDecimal("885.42"));
    }

    @Test
    void s4_quarterCrossingA31stMonthEnd() {
        Thirty360UsDayCountCalculator calculator = new Thirty360UsDayCountCalculator();
        BigDecimal accrued = calculator.accruedInterest(new BigDecimal("100000"), new BigDecimal("5.0"), LocalDate.of(2025, 1, 1),
                LocalDate.of(2025, 3, 31), MoneyHelper.createMathContext(RoundingMode.HALF_UP));
        assertThat(accrued).isEqualByComparingTo(new BigDecimal("1250.00"));
    }

    @Test
    void s5_singleDayPeriod() {
        Thirty360UsDayCountCalculator calculator = new Thirty360UsDayCountCalculator();
        BigDecimal accrued = calculator.accruedInterest(new BigDecimal("1000000"), new BigDecimal("3.65"), LocalDate.of(2025, 6, 1),
                LocalDate.of(2025, 6, 2), MoneyHelper.createMathContext(RoundingMode.HALF_UP));
        assertThat(accrued).isEqualByComparingTo(new BigDecimal("101.39"));
    }

    @Test
    void s6_zeroDayBoundary() {
        Thirty360UsDayCountCalculator calculator = new Thirty360UsDayCountCalculator();
        LocalDate date = LocalDate.of(2025, 1, 1);
        BigDecimal accrued = calculator.accruedInterest(new BigDecimal("100000"), new BigDecimal("5.0"), date, date,
                MoneyHelper.createMathContext(RoundingMode.HALF_UP));
        assertThat(accrued).isEqualByComparingTo(new BigDecimal("0.00"));
        assertThat(calculator.dayCount(date, date)).isZero();
        assertThat(calculator.dayCountFraction(date, date)).isEqualByComparingTo(BigDecimal.ZERO);
    }
}
