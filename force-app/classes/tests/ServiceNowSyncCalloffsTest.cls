@isTest
private class ServiceNowSyncCalloffsTest {
    @isTest static void syncCalloffsTest() {
        ServiceNow_Settings__c settings = new ServiceNow_Settings__c(Name='Test',LastContractsSynchronization__c = DateTime.now().addDays(-1),LastCallOffSynchronizationTime__c = DateTime.now().addDays(-1));
        insert settings;
        Account testAccount = new Account(Name = 'Test Account');
        insert testAccount;

        Contract_Archive__c testContractArchive = new Contract_Archive__c(Name = 'Test Contract Archive', Sys_Id_External__c = 'TestSysId');
        insert testContractArchive;

        Call_Off_Contract__c testCallOffContract = new Call_Off_Contract__c(Name = 'Test Call Off Contract', Sys_Id_External__c = 'TestSysId');
        insert testCallOffContract;

        Test.setMock(HttpCalloutMock.class, new ServiceNowSyncCalloffsMock());

        Test.startTest();
        ServiceNowSyncCallOffRecords.syncCallOffRecords();
        Test.stopTest();

        testCallOffContract = [SELECT State__c, Number__c FROM Call_Off_Contract__c WHERE Name = 'Test Archive'];
//        Assert.areEqual('Active', testCallOffContract.State__c);
//        Assert.areEqual('123456', testCallOffContract.Number__c);
    }


    private class ServiceNowSyncCalloffsMock implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            // Create a fake response
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setBody('{"result": [{"agreement_sys_id": "TestSysId", "archive_name": "Test Archive", "contract_type": "TestType", "archive_sys_id": "test_archive", "final_expiration_confirmed": "1", "archive_number": "TestArchiveNum", "identification_number": "TestId", "archive_state": "Active", "archive_internal_number": "123456", "final_date_of_expiry": "TestExpiryDate", "sub_area": "TestSubArea"}]}');
            res.setStatusCode(200);
            return res;
        }
    }
}