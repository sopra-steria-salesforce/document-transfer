public with sharing class ServiceNowSyncCallOffRecords implements Queueable, Database.AllowsCallouts{
    static ServiceNow_Settings__c settings = [SELECT Id, LastCallOffSynchronizationTime__c FROM ServiceNow_Settings__c LIMIT 1];
    static Map<String,Id> opportunityIdsByCallOffSysExternalIds = new Map<String, Id>();

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
                Logger.info('# of received call off records: ' + outerWrapper.result.size());
                List<Call_Off_Contract__c> callOffRecords = createCallOffRecords(outerWrapper);
                BatchUpsertCallOffRecords.opportunityIdsByCallOffSysExternalIds = opportunityIdsByCallOffSysExternalIds;
				BatchUpsertCallOffRecords.callOffContracts=callOffRecords;
				Database.executeBatch(new BatchUpsertCallOffRecords(),100);
            }
        }catch(Exception e) {
            Logger.error('Exception occurred during API call',  e).addTag('Sync call off records');
            Logger.saveLog();
        }
		Logger.saveLog();
    }

    private static OuterWrapper deserializeResponse(HttpResponse response) {
        return (OuterWrapper) JSON.deserialize(response.getBody(), OuterWrapper.class);
    }

    private static List<Call_Off_Contract__c> createCallOffRecords(OuterWrapper outerWrapper) {
        List<Call_Off_Contract__c> callOffRecords = new List<Call_Off_Contract__c>();
        List<Account> accounts = [SELECT Id, Name FROM Account];
        List<Contract_Archive__c> contractArchives  = [SELECT Id, Sys_Id_External__c FROM Contract_Archive__c];

        Map<String, String> externalIds2ContractArchiveId = new Map<String, String>();
        for(Contract_Archive__c contractArchive : contractArchives) {
            externalIds2ContractArchiveId.put(contractArchive.Sys_Id_External__c, contractArchive.Id);
        }
        Set<Id> accountIds = new Set<Id>();
        for(Account acc : accounts) {
            accountIds.add(acc.Id);
        }
        for(ResponseWrapper responseWrapper : outerWrapper.result) {
            Call_Off_Contract__c callOffRecord = new Call_Off_Contract__c();
            callOffRecord.Identification_Number__c = responseWrapper.archive_internal_number;
            callOffRecord.Name = responseWrapper.archive_name.length() > 80 ? responseWrapper.archive_name.substring(0, 80) : responseWrapper.archive_name;
            callOffRecord.Contract_Number__c = responseWrapper.archive_number.length() > 80 ? responseWrapper.archive_number.substring(0, 80) : responseWrapper.archive_number;
            callOffRecord.ArchiveState__c = responseWrapper.archive_state;
            callOffRecord.Sys_Id_External__c = responseWrapper.archive_sys_id;
            callOffRecord.Contract_Type__c = responseWrapper.contract_type;
            if(!String.isEmpty(responseWrapper.customer_salesforce_id) && accountIds.contains(responseWrapper.customer_salesforce_id)) {
                callOffRecord.Account__c = responseWrapper.customer_salesforce_id;
            }
            callOffRecord.Parent_Contract__c = externalIds2ContractArchiveId.get(responseWrapper.agreement_sys_id);
            callOffRecord.Final_Date_of_Expiry__c = responseWrapper.final_date_of_expiry;
            callOffRecord.FinalExpirationConfirmed__c = Boolean.valueOf(responseWrapper.final_expiration_confirmed);
            callOffRecord.Identification_Number__c = responseWrapper.identification_number;
            callOffRecord.Start_Date__c = responseWrapper.start_date;
            if(!String.isEmpty(responseWrapper.opportunity_salesforce_id)){
                opportunityIdsByCallOffSysExternalIds.put(responseWrapper.archive_sys_id, responseWrapper.opportunity_salesforce_id);
            }
         //   callOffRecord.Sub_Area__c = responseWrapper.sub_area;
            callOffRecords.add(callOffRecord);
        }
        return callOffRecords;
    }

    public class OuterWrapper {
        public List<ResponseWrapper> result;
    }

    public class ResponseWrapper {
        public String agreement_business_unit;
        public String agreement_internal_number;
        public String agreement_name;
        public String agreement_sys_id;
        public String archive_internal_number;
        public String archive_name;
        public String archive_number;
        public String archive_state;
        public String archive_sys_id;
        public String contract_approved;
        public String contract_signed;
        public String contract_type;
        public String customer_name;
        public String customer_salesforce_id;
        public String final_date_of_expiry;
        public String final_expiration_confirmed;
        public String identification_number;
        public String start_date;
        public String opportunity_salesforce_id;
        public String sub_area;
    }
}