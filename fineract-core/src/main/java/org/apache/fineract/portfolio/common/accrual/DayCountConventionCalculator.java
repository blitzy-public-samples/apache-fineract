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

import java.math.BigDecimal;
import java.math.MathContext;
import java.math.RoundingMode;
import java.time.LocalDate;

public interface DayCountConventionCalculator {

    long dayCount(LocalDate periodStart, LocalDate periodEnd);

    BigDecimal dayCountFraction(LocalDate periodStart, LocalDate periodEnd);

    default BigDecimal accruedInterest(final BigDecimal principal, final BigDecimal annualRatePercent, final LocalDate periodStart,
            final LocalDate periodEnd, final MathContext mathContext) {
        if (periodStart.equals(periodEnd)) {
            return BigDecimal.ZERO.setScale(2, RoundingMode.HALF_UP);
        }
        final BigDecimal rate = annualRatePercent.divide(BigDecimal.valueOf(100), mathContext);
        final BigDecimal fraction = dayCountFraction(periodStart, periodEnd);
        final BigDecimal accrued = principal.multiply(rate, mathContext).multiply(fraction, mathContext);
        return accrued.setScale(2, RoundingMode.HALF_UP);
    }
}
