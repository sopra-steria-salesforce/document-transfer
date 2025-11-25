@IsTest
private class OpportunityContractControllerTest {
    @TestSetup
    static void setup() {
        Account acc = new Account(Name = 'Test Account');
        insert acc;

        Opportunity opp = new Opportunity(
            Name = 'Test Opp',
            Proposal_Due_Date_Time__c = Datetime.now(),
            Amount = 1,
            Business_Unit__c = 'DPS',
            StageName = '0 - Planning',
            Status__c = '-',
            ConnectedToExistingContract__c = 'Yes',
            CloseDate = Date.today(),
            AccountId = acc.Id
        );
        insert opp;

        Contract_Archive__c contractArchive = new Contract_Archive__c(Name = 'Test Contract Archive', Sys_Id_External__c = 'a6934a998721d5101b9e98683cbb351a', LegalOwner__c = 'Sopra Steria Norway');
        insert contractArchive;

        Account_Contract_Archive_Junction__c junction = new Account_Contract_Archive_Junction__c(Account__c = acc.Id, Contract_Archive__c = contractArchive.Id);
        insert junction;
    }

    @IsTest
    static void testGetRelatedContracts() {
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        List<OpportunityContractController.ContractWrapper> resultContracts = OpportunityContractController.getRelatedContracts(opp.Id);
        //    System.assertEquals(1, resultContracts.size(), 'Expected 1 related Contract Archive.');
    }

    @IsTest
    static void testUpdateOpportunity() {
        Opportunity opp = [SELECT Id, Contract_Lookup__c FROM Opportunity];
        System.assert(opp.Contract_Lookup__c == null);
        Contract_Archive__c contract = [SELECT Id FROM Contract_Archive__c];

        Test.startTest();
        OpportunityContractController.updateOpportunityWithContract(opp.Id, contract.Id);
        Test.stopTest();

        Opportunity oppAfterUpdate = [SELECT Id, Contract_Lookup__c FROM Opportunity];
        //     System.assert(oppAfterUpdate.Contract_Lookup__c == contract.Id);
    }
}
