@isTest
private class ServiceNowGetRelationshipsTest {
    static Account testAccount;
    @isTest static void assignContractsWithAccountsTest() {
        testAccount = new Account(Name = 'Test Account');
        insert testAccount;

        Contract_Archive__c testContractArchive = new Contract_Archive__c(Name = 'Test Contract Archive', Sys_Id_External__c = 'TestSysId');
        insert testContractArchive;

        Test.setMock(HttpCalloutMock.class, new ServiceNowGetRelationshipsMock());

        Test.startTest();
        ServiceNowGetRelationships.assignContractsWithAccounts();
        Test.stopTest();
       }


    @TestVisible
    private class ServiceNowGetRelationshipsMock implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setBody('{"result": [{"contract_sys_id": "TestSysId", "customer_salesforce_id": "' + testAccount.Id + '", "contract_internal_number": "TestContractNum"}]}');
            res.setStatusCode(200);
            return res;
        }
    }
}