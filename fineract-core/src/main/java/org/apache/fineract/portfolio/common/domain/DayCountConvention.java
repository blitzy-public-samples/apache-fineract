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
package org.apache.fineract.portfolio.common.domain;

import java.util.Arrays;
import java.util.List;
import org.apache.fineract.infrastructure.core.data.EnumOptionData;

/**
 * Selectable day-count convention governing accrued-interest computation for a loan product. Persisted elsewhere as a
 * nullable Integer; {@code null} preserves the existing accrual behavior.
 */
public enum DayCountConvention {

    ACTUAL_360(1, "DayCountConvention.actual360"), //
    ACTUAL_365(2, "DayCountConvention.actual365"), //
    THIRTY_360_US(3, "DayCountConvention.thirty360US");

    private final Integer value;
    private final String code;

    DayCountConvention(final Integer value, final String code) {
        this.value = value;
        this.code = code;
    }

    public Integer getValue() {
        return this.value;
    }

    public String getCode() {
        return this.code;
    }

    public static DayCountConvention fromInt(final Integer value) {
        if (value == null) {
            return null;
        }
        return switch (value) {
            case 1 -> ACTUAL_360;
            case 2 -> ACTUAL_365;
            case 3 -> THIRTY_360_US;
            default -> throw new IllegalArgumentException("Invalid DayCountConvention value: " + value);
        };
    }

    /**
     * Exposes the selectable conventions as a list of {@link EnumOptionData} for additive inclusion on the loan-product
     * template/response (mirrors the {@code getValuesAsEnumOptionDataList()} idiom used by other loan-product enums).
     */
    public static List<EnumOptionData> getValuesAsEnumOptionDataList() {
        return Arrays.stream(values())
                .map(convention -> new EnumOptionData(convention.value.longValue(), convention.code, convention.name())).toList();
    }
}
