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
import java.time.LocalDate;

public class Thirty360UsDayCountCalculator implements DayCountConventionCalculator {

    @Override
    public long dayCount(final LocalDate periodStart, final LocalDate periodEnd) {
        if (periodStart.equals(periodEnd)) {
            return 0L;
        }
        int d1 = periodStart.getDayOfMonth();
        final int m1 = periodStart.getMonthValue();
        final int y1 = periodStart.getYear();
        int d2 = periodEnd.getDayOfMonth();
        final int m2 = periodEnd.getMonthValue();
        final int y2 = periodEnd.getYear();
        if (d1 == 31) {
            d1 = 30;
        }
        if (d2 == 31 && (d1 == 30 || d1 == 31)) {
            d2 = 30;
        }
        return 360L * (y2 - y1) + 30L * (m2 - m1) + (d2 - d1);
    }

    @Override
    public BigDecimal dayCountFraction(final LocalDate periodStart, final LocalDate periodEnd) {
        if (periodStart.equals(periodEnd)) {
            return BigDecimal.ZERO;
        }
        return BigDecimal.valueOf(dayCount(periodStart, periodEnd)).divide(BigDecimal.valueOf(360), MathContext.DECIMAL128);
    }
}
