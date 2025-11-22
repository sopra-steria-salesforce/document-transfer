public with sharing class ServiceNowSyncCallOffRecords implements Queueable, Database.AllowsCallouts{
	private static Boolean logError = false;
	private static ServiceNow_Settings__c settings {
		get{
			if (settings==null) {
				settings=[SELECT Id, LastCallOffSynchronizationTime__c FROM ServiceNow_Settings__c LIMIT 1];
			}
			return settings;
		}
		private set;
	}

	private static Map<String,Id> opportunityIdsByCallOffSysExternalIds = new Map<String, Id>();

	public void execute(QueueableContext context) {
		syncCallOffRecords();
	}
	public static void syncCallOffRecords() {
		Logger.info('Retrieving call off records from ServiceNow');
		try {
			HttpResponse response = Utils.doRequest(
					Utils.NAMED_CREDENTIAL_SERVICE_NOW,
					Utils.API_GET_ALL_ARCHIVES + '?sysparm_limit=3100&sysparm_offset=0&sysparm_query=sys_updated_on%3E' + String.valueOf(settings.LastCallOffSynchronizationTime__c).replaceAll(' ', '%20'),
					Utils.METHOD_GET,
					null
			);

			if (response.getStatusCode() == 200) {
				OuterWrapper outerWrapper = deserializeResponse(response);
				List<Call_Off_Contract__c> callOffRecords = createCallOffRecords(outerWrapper);
				if (callOffRecords.isEmpty()) {
					return;
				}
				Logger.info('# of received call off records: ' + callOffRecords.size());
				BatchUpsertCallOffRecords batchUpsertCallOffRecords= new BatchUpsertCallOffRecords(opportunityIdsByCallOffSysExternalIds, callOffRecords);
				Database.executeBatch(batchUpsertCallOffRecords,100);
			}
		} catch(Exception e) {
			Logger.exception('Exception occurred during API call',  e);
		}
		if (logError) {
			Logger.saveLog();
		}
	}

	private static OuterWrapper deserializeResponse(HttpResponse response) {
		return (OuterWrapper) JSON.deserialize(response.getBody(), OuterWrapper.class);
	}

	private static List<Call_Off_Contract__c> createCallOffRecords(OuterWrapper outerWrapper) {
		List<Call_Off_Contract__c> callOffRecords = new List<Call_Off_Contract__c>();
		Map<String, String> callOffSysExternalIdsByParentContractSysExternalIds = new Map<String, String>();

		for(ResponseWrapper responseWrapper : outerWrapper.result) {
			Call_Off_Contract__c callOffRecord = new Call_Off_Contract__c(
					ArchiveState__c = responseWrapper.archive_state,
					Sys_Id_External__c = responseWrapper.archive_sys_id,
					Contract_Type__c = responseWrapper.contract_type,
					Final_Date_of_Expiry__c = responseWrapper.final_date_of_expiry,
					FinalExpirationConfirmed__c = Boolean.valueOf(responseWrapper.final_expiration_confirmed),
					Identification_Number__c = responseWrapper.identification_number,
					Start_Date__c = responseWrapper.start_date
			);
			callOffRecord.Name = responseWrapper.archive_name.length() > 80 ? responseWrapper.archive_name.substring(0, 80) : responseWrapper.archive_name;
			callOffRecord.Contract_Number__c = responseWrapper.archive_number.length() > 80 ? responseWrapper.archive_number.substring(0, 80) : responseWrapper.archive_number;
			if(!String.isEmpty(responseWrapper.opportunity_salesforce_id)){
				opportunityIdsByCallOffSysExternalIds.put(responseWrapper.archive_sys_id, responseWrapper.opportunity_salesforce_id);
			}
			callOffSysExternalIdsByParentContractSysExternalIds.put(responseWrapper.agreement_sys_id, responseWrapper.archive_sys_id);

			try {
				callOffRecord.Account__c = responseWrapper.customer_salesforce_id;
			} catch (StringException stringException){
				Logger.error('Invalid Customer Id from Service Now: '+responseWrapper.customer_salesforce_id + ' for Sys External Id:' +responseWrapper.archive_sys_id).addTag('Scheduled Sync Call Off records');
				logError=true;
			}
			callOffRecords.add(callOffRecord);
		}
		callOffRecords=addParentContractRelation(callOffRecords, callOffSysExternalIdsByParentContractSysExternalIds);
		return validateCustomerIdsFromServiceNow(callOffRecords);
	}

	@TestVisible
	private static List<Call_Off_Contract__c> addParentContractRelation(List<Call_Off_Contract__c> callOffContracts, Map<String, String> callOffSysExternalIdsByParentContractSysExternalIds){
		Map<String, Id> parentContractIdsByCallOffSysExternalIds = new Map<String, Id>();
		for (Contract_Archive__c parentContract: [SELECT Id, Sys_Id_External__c FROM Contract_Archive__c WHERE Sys_Id_External__c IN: callOffSysExternalIdsByParentContractSysExternalIds.keySet()]){
			parentContractIdsByCallOffSysExternalIds.put(
					callOffSysExternalIdsByParentContractSysExternalIds.get(parentContract.Sys_Id_External__c),
					parentContract.Id
			);
		}
		for (Call_Off_Contract__c callOffContract:callOffContracts){
			callOffContract.Parent_Contract__c=parentContractIdsByCallOffSysExternalIds.get(callOffContract.Sys_Id_External__c);
		}
		return callOffContracts;
	}
	@TestVisible
	private static List<Call_Off_Contract__c> validateCustomerIdsFromServiceNow(List<Call_Off_Contract__c> callOffContracts){
		Set<Id> invalidCustomerIdsFromServiceNow = matchCustomerIdsFromServiceNowAgainstAccounts(callOffContracts);
		if (invalidCustomerIdsFromServiceNow.isEmpty()) {
			return callOffContracts;
		} else{
			for (Call_Off_Contract__c callOffContract:callOffContracts){
				if (invalidCustomerIdsFromServiceNow.contains(callOffContract.Account__c)) {
					Logger.error('Invalid Customer Id from Service Now: '+callOffContract.Account__c + ' for Sys External Id: '+callOffContract.Sys_Id_External__c).addTag('Scheduled Sync Call Off records');
					callOffContract.Account__c=null;
					logError=true;
				}
			}
			return callOffContracts;
		}
	}

	@TestVisible
	private static Set<Id> matchCustomerIdsFromServiceNowAgainstAccounts(List<Call_Off_Contract__c> callOffContracts){
		Set<Id> customerIdsFromServiceNow = new Set<Id>();
		for (Call_Off_Contract__c callOffContract:callOffContracts){
			customerIdsFromServiceNow.add(callOffContract.Account__c);
		}
		Set<Id> validAccountIds = new Map<Id, Account>([SELECT Id FROM Account WHERE Id IN:customerIdsFromServiceNow]).keySet();
		customerIdsFromServiceNow.removeAll(validAccountIds);
		return customerIdsFromServiceNow;
	}

	public class OuterWrapper {
		public List<ResponseWrapper> result;
	}

	public class ResponseWrapper {
		public String agreement_sys_id;
		public String archive_name;
		public String archive_number;
		public String archive_state;
		public String archive_sys_id;
		public String contract_type;
		public String customer_salesforce_id;
		public String final_date_of_expiry;
		public String final_expiration_confirmed;
		public String identification_number;
		public String start_date;
		public String opportunity_salesforce_id;
	}
}