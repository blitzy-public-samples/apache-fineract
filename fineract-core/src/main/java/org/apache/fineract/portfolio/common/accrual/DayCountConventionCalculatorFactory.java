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

import org.apache.fineract.portfolio.common.domain.DayCountConvention;

public final class DayCountConventionCalculatorFactory {

    private static final DayCountConventionCalculator ACTUAL_360 = new Actual360DayCountCalculator();
    private static final DayCountConventionCalculator ACTUAL_365 = new Actual365DayCountCalculator();
    private static final DayCountConventionCalculator THIRTY_360_US = new Thirty360UsDayCountCalculator();

    private DayCountConventionCalculatorFactory() {}

    public static DayCountConventionCalculator forConvention(final DayCountConvention convention) {
        if (convention == null) {
            return null;
        }
        return switch (convention) {
            case ACTUAL_360 -> ACTUAL_360;
            case ACTUAL_365 -> ACTUAL_365;
            case THIRTY_360_US -> THIRTY_360_US;
        };
    }
}
