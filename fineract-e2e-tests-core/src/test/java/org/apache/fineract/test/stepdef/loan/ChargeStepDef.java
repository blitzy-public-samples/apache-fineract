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
package org.apache.fineract.test.stepdef.loan;

import static org.apache.fineract.client.feign.util.FeignCalls.ok;

import io.cucumber.java.en.When;
import org.apache.fineract.client.feign.FineractFeignClient;
import org.apache.fineract.client.models.ChargeRequest;
import org.apache.fineract.client.models.PostChargesResponse;
import org.apache.fineract.test.data.ChargeCalculationType;
import org.apache.fineract.test.data.ChargeProductAppliesTo;
import org.apache.fineract.test.data.ChargeProductResolver;
import org.apache.fineract.test.data.ChargeProductType;
import org.apache.fineract.test.data.ChargeTimeType;
import org.apache.fineract.test.helper.Utils;
import org.apache.fineract.test.stepdef.AbstractStepDef;
import org.springframework.beans.factory.annotation.Autowired;

public class ChargeStepDef extends AbstractStepDef {

    @Autowired
    private FineractFeignClient fineractClient;

    @Autowired
    private ChargeProductResolver chargeProductResolver;

    @When("Admin updates charge {string} with {string} calculation type and {double} % of transaction amount")
    public void updateCharge(String chargeType, String chargeCalculationType, double amount) {
        ChargeRequest disbursementChargeUpdateRequest = new ChargeRequest();
        ChargeCalculationType chargeProductTypeValue = ChargeCalculationType.valueOf(chargeCalculationType);
        disbursementChargeUpdateRequest.chargeCalculationType(chargeProductTypeValue.value).amount(amount).locale("en");

        ChargeProductType chargeProductType = ChargeProductType.valueOf(chargeType);
        Long chargeId = chargeProductResolver.resolve(chargeProductType);

        ok(() -> fineractClient.charges().updateCharge(chargeId, disbursementChargeUpdateRequest));
    }

    @When("Admin updates charge {string} with {string} calculation type and {double} EUR amount")
    public void updateChargeWithFlatAmount(String chargeType, String chargeCalculationType, double flatAmount) {
        ChargeRequest disbursementChargeUpdateRequest = new ChargeRequest();
        ChargeCalculationType chargeProductTypeValue = ChargeCalculationType.valueOf(chargeCalculationType);
        disbursementChargeUpdateRequest.chargeCalculationType(chargeProductTypeValue.value).amount(flatAmount).locale("en");

        ChargeProductType chargeProductType = ChargeProductType.valueOf(chargeType);
        Long chargeId = chargeProductResolver.resolve(chargeProductType);

        ok(() -> fineractClient.charges().updateCharge(chargeId, disbursementChargeUpdateRequest));
    }

    @When("Admin creates working capital loan charge")
    public void createWorkingCapitalLoanCharge() {
        ChargeRequest request = new ChargeRequest().chargeAppliesTo(ChargeProductAppliesTo.WORKING_CAPITAL_LOAN.value) //
                .chargeTimeType(ChargeTimeType.SPECIFIED_DUE_DATE.value) //
                .chargeCalculationType(ChargeCalculationType.FLAT.value) //
                .name(Utils.randomStringGenerator("WCL_CHARGE_", 10)) //
                .amount(20.0D).active(true).currencyCode("EUR").locale("en").penalty(false);
        PostChargesResponse response = ok(() -> fineractClient.charges().createCharge(request));
        testContext().set("WORKING_CAPITAL_LOAN_CHARGE_ID", response.getResourceId());
    }

    @When("Admin updates working capital loan charge")
    public void updateWorkingCapitalLoanCharge() {
        Long id = testContext().get("WORKING_CAPITAL_LOAN_CHARGE_ID");
        ChargeRequest request = new ChargeRequest().chargeAppliesTo(ChargeProductAppliesTo.WORKING_CAPITAL_LOAN.value) //
                .chargeTimeType(ChargeTimeType.SPECIFIED_DUE_DATE.value) //
                .chargeCalculationType(ChargeCalculationType.FLAT.value) //
                .name(Utils.randomStringGenerator("WCL_CHARGE_", 10)) //
                .active(true).currencyCode("EUR").locale("en").amount(30.0D).penalty(true);
        ok(() -> fineractClient.charges().updateCharge(id, request));
    }

    @When("Admin deletes working capital loan charge")
    public void deleteWorkingCapitalLoanCharge() {
        Long id = testContext().get("WORKING_CAPITAL_LOAN_CHARGE_ID");
        ok(() -> fineractClient.charges().deleteCharge(id));
    }
}
