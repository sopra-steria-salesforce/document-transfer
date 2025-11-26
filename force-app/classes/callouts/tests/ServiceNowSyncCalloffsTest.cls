@IsTest
private class ServiceNowSyncCalloffsTest {

	@TestSetup
	static void setupTestData(){
		ServiceNow_Settings__c settings = new ServiceNow_Settings__c(Name = 'Test', LastContractsSynchronization__c = Datetime.now().addDays(-1), LastCallOffSynchronizationTime__c = DateTime.now().addDays(-1));
		insert settings;

		List<Account> accounts = new List<Account>{
				new Account(
						Name = 'Test Account 1'
				),
				new Account(
						Name='Test Account 2'
				)
		};
		insert accounts;

		List<Opportunity> opportunities = TestDataFactory.createOpportunities(2,false,false);
		opportunities[0].AccountId=accounts[0].Id;
		opportunities[1].AccountId=accounts[1].Id;
		insert opportunities;

		List<Contract_Archive__c> contractArchives = new List<Contract_Archive__c>{
				new Contract_Archive__c(
						Name = 'Test Contract Archive 1',
						Sys_Id_External__c = '123'
				),
				new Contract_Archive__c(
						Name = 'Test Contract Archive 2',
						Sys_Id_External__c = 'abc'
				)
		};
		insert contractArchives;

		Call_Off_Contract__c callOffContractToBeUpserted = new Call_Off_Contract__c(Name = 'Test Call Off Contract', Sys_Id_External__c = '321');
		insert callOffContractToBeUpserted;
	}

	@IsTest static void syncCallOffsTest() {
		List<Opportunity> opportunities = [SELECT Id, AccountId FROM Opportunity];
		List<Contract_Archive__c> contractArchives = [SELECT Sys_Id_External__c FROM Contract_Archive__c];
		Call_Off_Contract__c callOffContract = [SELECT Sys_Id_External__c FROM Call_Off_Contract__c LIMIT 1];
		setupStaticResourceMock('syncCallOffsResponse', opportunities, contractArchives, callOffContract);
		Test.startTest();
		ServiceNowSyncCallOffRecords.syncCallOffRecords();
		Test.stopTest();

		List<Call_Off_Contract__c> callOffContracts = [SELECT Id, Account__c, Parent_Contract__c FROM Call_Off_Contract__c];
		//Check if 1 CallOff has been created
		Assert.areEqual(2, callOffContracts.size(), 'Two CallOff contracts should exist. An existing one prior to sync. And a new one that is created from the sync');
		// Check if both CallOffs are related to an Account
		Assert.isNotNull(callOffContracts[0].Account__c);
		Assert.isNotNull(callOffContracts[1].Account__c);

		// Check if both CallOffs are related to a Contract Archive
		Assert.isNotNull(callOffContracts[0].Parent_Contract__c);
		Assert.isNotNull(callOffContracts[1].Parent_Contract__c);

		// Check if Opportunities are related to a Call Off
		for (Opportunity opportunity:[SELECT Call_Off_Contract__c FROM Opportunity]){
			Assert.isNotNull(opportunity.Call_Off_Contract__c);
		}
	}

	@IsTest
	static void testValidCustomerIdsFromServiceNow() {
		List<Account> accounts = new List<Account>{
				new Account(Name = 'Test Account 1'),
				new Account(Name = 'Test Account 2')
		};
		insert accounts;
		List<Call_Off_Contract__c> callOffContracts = new List<Call_Off_Contract__c>{
				new Call_Off_Contract__c(Account__c = accounts[0].Id),
				new Call_Off_Contract__c(Account__c = accounts[1].Id)
		};
		Assert.isTrue(ServiceNowSyncCallOffRecords.matchCustomerIdsFromServiceNowAgainstAccounts(callOffContracts).isEmpty());
	}

	@IsTest
	static void testInvalidCustomerIdsFromServiceNow() {
		Account account = new Account(Name = 'Test Account');
		insert account;
		List<Call_Off_Contract__c> callOffContracts = new List<Call_Off_Contract__c>{
				new Call_Off_Contract__c(Account__c = account.Id),
				new Call_Off_Contract__c(Account__c = TestDataFactory.generateFakeId(Account.getSObjectType()))
		};
		Assert.isFalse(ServiceNowSyncCallOffRecords.matchCustomerIdsFromServiceNowAgainstAccounts(callOffContracts).isEmpty());
	}

	@IsTest
	static void testAddParentContractRelation() {
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
				new Call_Off_Contract__c(Sys_Id_External__c = '321'),
				new Call_Off_Contract__c(Sys_Id_External__c = 'cba')
		};
		Map<String, String> callOffSysExternalIdsByParentContractSysExternalIds = new Map<String, String>{
				parentContracts[0].Sys_Id_External__c => callOffContracts[0].Sys_Id_External__c,
				parentContracts[1].Sys_Id_External__c => callOffContracts[1].Sys_Id_External__c
		};
		callOffContracts = ServiceNowSyncCallOffRecords.addParentContractRelation(callOffContracts, callOffSysExternalIdsByParentContractSysExternalIds);
		Assert.areEqual(parentContracts[0].Id, callOffContracts[0].Parent_Contract__c, 'Parent Contract should set as defined in callOffSysExternalIdsByParentContractSysExternalIds');
		Assert.areEqual(parentContracts[1].Id, callOffContracts[1].Parent_Contract__c, 'Parent Contract should set as defined in callOffSysExternalIdsByParentContractSysExternalIds');
	}

	private static void setupStaticResourceMock(String staticResourceAPIName, List<Opportunity> opportunities, List<Contract_Archive__c>contractArchives, Call_Off_Contract__c callOffContract) {
		String jsonResponse = [SELECT Body FROM StaticResource WHERE Name=:staticResourceAPIName LIMIT 1].Body.toString();
		ServiceNowSyncCallOffRecords.OuterWrapper outerWrapper = (ServiceNowSyncCallOffRecords.OuterWrapper) JSON.deserialize(jsonResponse, ServiceNowSyncCallOffRecords.OuterWrapper.class);
		List<ServiceNowSyncCallOffRecords.ResponseWrapper> responseWrappers = outerWrapper.result;
		responseWrappers[0].customer_salesforce_id=opportunities[0].AccountId;
		responseWrappers[0].opportunity_salesforce_id=opportunities[0].Id;
		responseWrappers[0].agreement_sys_id=contractArchives[0].Sys_Id_External__c;
		responseWrappers[0].archive_sys_id=callOffContract.Sys_Id_External__c;

		responseWrappers[1].customer_salesforce_id=opportunities[1].AccountId;
		responseWrappers[1].opportunity_salesforce_id=opportunities[1].Id;
		responseWrappers[1].agreement_sys_id=contractArchives[1].Sys_Id_External__c;
		responseWrappers[1].archive_sys_id='cba';
		outerWrapper.result = responseWrappers;

		Test.setMock(HttpCalloutMock.class, new HTTPMock(JSON.serialize(outerWrapper)));
	}

	public class HTTPMock implements HttpCalloutMock {
		private String responseBody;
		public HTTPMock(String responseBody){
			this.responseBody=responseBody;
		}
		public HttpResponse respond(HttpRequest request) {
			HttpResponse response = new HttpResponse();
			response.setHeader('Content-Type', 'application/json');
			response.setStatusCode(200);
			response.setBody(this.responseBody);
			return response;
		}
	}

}