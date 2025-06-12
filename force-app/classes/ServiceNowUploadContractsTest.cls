@isTest
private class ServiceNowUploadContractsTest {

    @testSetup
    static void setup() {
        // Insert test data
        Account testAccount = new Account(Name = 'Test Account', SN_sys_id__c = 'TestSysId');
        insert testAccount;

        Opportunity testOpportunity = new Opportunity(Type = 'Frame Agreement', Name = 'Opportunity', StageName = '1 - Possibility', Status__c = '-', Business_Unit__c = 'APPS', CloseDate = Date.today(), Consultants__c = 1, Months__c = 1, AccountID = testAccount.Id, Proposal_Due_Date_Time__c = DateTime.now());

        insert testOpportunity;

        ServiceNow_Settings__c settings = new ServiceNow_Settings__c(Name = 'test',LastContractsSynchronization__c = DateTime.now().addDays(-1));
        insert settings;
    }

    @isTest
    static void testUploadNewContract() {
        // Retrieve test data
        Opportunity testOpportunity = [SELECT Id FROM Opportunity LIMIT 1];

        // Create mock data
        List<ServiceNowUploadContracts.Attachment> attachments = new List<ServiceNowUploadContracts.Attachment>{
                new ServiceNowUploadContracts.Attachment('testfile.txt', 'dGVzdCBjb250ZW50', 'text/plain')
        };
        String filedata = JSON.serialize(attachments);

        // Mock the HTTP response
        Test.setMock(HttpCalloutMock.class, new ServiceNowUploadContractsMock());

        // Call the method to be tested
        Test.startTest();
        ServiceNowUploadContracts.ResponseWrapper response = ServiceNowUploadContracts.uploadContracts(
                testOpportunity.Id,
                filedata,
                false, // contractLookup
                null, // opportunityContractSysId
                'Test Customer',
                'Test Contract Number'
        );
        Test.stopTest();

        // Perform assertions
        System.assertNotEquals(null, response, 'Response should not be null');
        System.assertEquals('success', response.result, 'Result should be success');
    }

    @isTest
    static void testUploadExistingContract() {
        // Retrieve test data
        Opportunity testOpportunity = [SELECT Id FROM Opportunity LIMIT 1];

        // Create mock data
        List<ServiceNowUploadContracts.Attachment> attachments = new List<ServiceNowUploadContracts.Attachment>{
                new ServiceNowUploadContracts.Attachment('testfile.txt', 'dGVzdCBjb250ZW50', 'text/plain')
        };
        String filedata = JSON.serialize(attachments);

        // Mock the HTTP response
        Test.setMock(HttpCalloutMock.class, new ServiceNowUploadContractsMock());

        // Call the method to be tested
        Test.startTest();
        ServiceNowUploadContracts.ResponseWrapper response = ServiceNowUploadContracts.uploadContracts(
                testOpportunity.Id,
                filedata,
                true, // contractLookup
                '123', // opportunityContractSysId
                'Test Customer',
                'Test Contract Number'
        );
        Test.stopTest();

        // Perform assertions
        System.assertNotEquals(null, response, 'Response should not be null');
        System.assertEquals('success', response.result, 'Result should be success');
    }

    private class ServiceNowUploadContractsMock implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setBody('{"result": {"result": "success", "contract_sys_id": "TestSysId", "internal_contract_number": "TestInternalNumber", "task_sys_id": "TestTaskSysId", "task_number": "TestTaskNumber", "relationship_sys_id": "TestRelationshipSysId"}}');
            res.setStatusCode(200);
            return res;
        }
    }
}