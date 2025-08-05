@isTest
public class ServiceNowUploadContractsQueueableTest {
    @TestSetup
    static void setupTestData() {
        // Create test data
        Account testAccount = new Account(Name = 'Test Account', SN_sys_id__c = 'TestSysId');
        insert testAccount;

        List<Opportunity> opportunities = new List<Opportunity>();
        for (Integer i = 0; i < 5; i++) {
            opportunities.add(
                new Opportunity(
                    Type = 'Frame Agreement',
                    Name = 'Opportunity',
                    StageName = '1 - Possibility',
                    Status__c = '-',
                    Business_Unit__c = 'APPS',
                    CloseDate = Date.today(),
                    Consultants__c = 1,
                    Months__c = 1,
                    AccountID = testAccount.Id,
                    Proposal_Due_Date_Time__c = DateTime.now()
                )
            );
        }

        insert opportunities;
    }

    @isTest
    static void testUploadNewContract() {
        List<Opportunity> opportunities = [SELECT Id, Name, Type, CloseDate, Contract_Category__c, AccountId FROM Opportunity LIMIT 1];

        for (Opportunity opp : opportunities) {
            opp.Type = 'Project';
            opp.Contract_Category__c = 'New contract (not connected to framework/capacity agreement)';
        }

        ServiceNowUploadContractsQueueable queueable = new ServiceNowUploadContractsQueueable(opportunities);

        Test.setMock(HttpCalloutMock.class, new ServiceNowUploadContractsMock());

        Test.startTest();
        System.enqueueJob(queueable);
        Test.stopTest();

        // Verify the contract upload process
        List<Opportunity> updatedOpportunities = [SELECT Id, Contract_Lookup__c, CloseDate, IsContractSent__c, ContractServiceNowUrl__c FROM Opportunity WHERE Id = :opportunity.Id];

        for (Opportunity updatedOpportunity : updatedOpportunities) {
            // System.assert(updatedOpportunity.IsContractSent__c, 'Contract should be marked as sent');
            // System.assertNotEquals(null, updatedOpportunity.ContractServiceNowUrl__c, 'ContractServiceNowUrl should be populated');
        }
    }

    @isTest
    static void testUploadExistingContract() {
        List<Opportunity> opportunities = [SELECT Id, Name, CloseDate, Sub_Area__c, Contract_Category__c FROM Opportunity LIMIT 1];

        for (Opportunity opp : opportunities) {
            opp.Type = 'Project';
            opp.Contract_Category__c = 'Change to an active call off or contract';
        }
        update opportunities;

        ServiceNowUploadContractsQueueable queueable = new ServiceNowUploadContractsQueueable(opportunities);

        Test.setMock(HttpCalloutMock.class, new ServiceNowUploadContractsMock());

        Test.startTest();
        System.enqueueJob(queueable);
        Test.stopTest();

        // Verify the contract upload process
        List<Opportunity> updatedOpportunities = [SELECT Id, CloseDate, Contract_Lookup__c, IsContractSent__c, ContractServiceNowUrl__c FROM Opportunity WHERE Id = :opportunity.Id];
        for (Opportunity updatedOpportunity : updatedOpportunities) {
            System.assert(updatedOpportunity.IsContractSent__c, 'Contract should be marked as sent');
            //  System.assertNotEquals(null, updatedOpportunity.ContractServiceNowUrl__c, 'ContractServiceNowUrl should be populated');
        }
    }

    public class ServiceNowUploadContractsMock implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setBody(
                '{"result": {"result": "success", "contract_sys_id": "TestSysId", "internal_contract_number": "TestInternalNumber", "task_sys_id": "TestTaskSysId", "task_number": "TestTaskNumber", "relationship_sys_id": "TestRelationshipSysId"}}'
            );
            res.setStatusCode(200);
            return res;
        }
    }
}
