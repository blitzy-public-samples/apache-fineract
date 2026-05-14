@WorkingCapitalLoanChargesFeature
Feature: WorkingCapitalLoanChargesFeature

  @TestRailId:Cxxxx1
  Scenario: Verify that charge can be created modified and deleted
    When Admin creates working capital loan charge
    When Admin updates working capital loan charge
    When Admin deletes working capital loan charge