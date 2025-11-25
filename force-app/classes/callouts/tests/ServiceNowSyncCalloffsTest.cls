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
	@IsTest
	static void testValidCustomerIdsFromServiceNow(){
		List<Account> accounts = new List<Account>{
				new Account(Name='Test Account 1'),
				new Account(Name='Test Account 2')
		};
		insert accounts;
		List<Call_Off_Contract__c> callOffContracts = new List<Call_Off_Contract__c>{
				new Call_Off_Contract__c(Account__c=accounts[0].Id),
				new Call_Off_Contract__c(Account__c=accounts[1].Id)
		};
		Assert.isTrue(ServiceNowSyncCallOffRecords.matchCustomerIdsFromServiceNowAgainstAccounts(callOffContracts).isEmpty());
	}

	@IsTest
	static void testInvalidCustomerIdsFromServiceNow(){
		Account account = new Account(Name='Test Account');
		insert account;
		List<Call_Off_Contract__c> callOffContracts = new List<Call_Off_Contract__c>{
				new Call_Off_Contract__c(Account__c=account.Id),
				new Call_Off_Contract__c(Account__c=TestDataFactory.generateFakeId(Account.getSObjectType()))
		};
		Assert.isFalse(ServiceNowSyncCallOffRecords.matchCustomerIdsFromServiceNowAgainstAccounts(callOffContracts).isEmpty());
	}

	@IsTest
	static void testAddParentContractRelation(){
		List<Contract_Archive__c> parentContracts = new List<Contract_Archive__c>{
				new Contract_Archive__c(
						Sys_Id_External__c = '123'
				),
				new Contract_Archive__c(
						Sys_Id_External__c = 'abc'
				)
		};
		insert parentContracts;
		List<Call_Off_Contract__c> callOffContracts = new List<Call_Off_Contract__c>{
				new Call_Off_Contract__c(Sys_Id_External__c='321'),
				new Call_Off_Contract__c(Sys_Id_External__c='cba')
		};
		Map<String, String> callOffSysExternalIdsByParentContractSysExternalIds = new Map<String, String>{
				parentContracts[0].Sys_Id_External__c => callOffContracts[0].Sys_Id_External__c,
				parentContracts[1].Sys_Id_External__c => callOffContracts[1].Sys_Id_External__c
		};
		callOffContracts=ServiceNowSyncCallOffRecords.addParentContractRelation(callOffContracts, callOffSysExternalIdsByParentContractSysExternalIds);
		Assert.areEqual(parentContracts[0].Id, callOffContracts[0].Parent_Contract__c, 'Parent Contract should set as defined in callOffSysExternalIdsByParentContractSysExternalIds');
		Assert.areEqual(parentContracts[1].Id, callOffContracts[1].Parent_Contract__c, 'Parent Contract should set as defined in callOffSysExternalIdsByParentContractSysExternalIds');
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