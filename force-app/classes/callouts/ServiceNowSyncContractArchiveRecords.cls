public with sharing class ServiceNowSyncContractArchiveRecords {
    static ServiceNow_Settings__c settings = [SELECT Id, LastContractsSynchronization__c FROM ServiceNow_Settings__c LIMIT 1];
    static Map<String,String> opportunityId2ExternalId = new Map<String, String>();
    @Future(callout=true)
    public static void syncContractArchiveRecords() {
//        try {
            HttpResponse response = Utils.doRequest(
                    Utils.NAMED_CREDENTIAL_SERVICE_NOW,
                    Utils.API_GET_ALL_AGREEMENTS + '?sysparm_limit=2500&sysparm_offset=0&sysparm_query=sys_updated_on%3E' + String.valueOf(settings.LastContractsSynchronization__c).replaceAll(' ', '%20'),
                    Utils.METHOD_GET,
                    null
            );
            if (response.getStatusCode() == 200) {
                ResponseWrapper responseWrapper = deserializeResponse(response);
                Logger.info('responseWrapper' + responseWrapper).addTag('Sync Contact Archive Records');
                List<Contract_Archive__c> contractsArchives = createContractArchives(responseWrapper);
                upsertContractArchives(contractsArchives);
            }
//        } catch (Exception e) {
//            Utils.logFailure('ServiceNowSyncContractArchiveRecords', 'syncContractArchiveRecords', e.getMessage(), 'Failed', UserInfo.getUserName(), 'Exception occurred during API call');
//        }
    }

    private static ResponseWrapper deserializeResponse(HttpResponse response) {
        return (ResponseWrapper) JSON.deserialize(response.getBody(), ResponseWrapper.class);
    }

    private static List<Contract_Archive__c> createContractArchives(ResponseWrapper responseWrapper) {
//        try {
            List<Contract_Archive__c> contractsArchives = new List<Contract_Archive__c>();
            List<Account> accounts = [SELECT Id FROM Account];
            List<Contract_Archive__c> contractArchives = [SELECT Id, Sys_Id_External__c FROM Contract_Archive__c];

            Set<String> accountsIds = new Set<String>();
            for (Account acc : accounts) {
                accountsIds.add(acc.Id);
            }

            Map<String, String> externalId2SalesforceId = new Map<String, String>();
            for (Contract_Archive__c contractArchive : contractArchives) {
                if (contractArchive.Sys_Id_External__c != null) {
                    externalId2SalesforceId.put(contractArchive.Sys_Id_External__c, contractArchive.Id);
                }
            }
            for (ContractWrapper rw : responseWrapper.result) {
                Contract_Archive__c contractArchive = new Contract_Archive__c(
                        Contract_State__c = String.valueOf(rw.contract_state),
                        Approved__c = String.valueOf(rw.contract_approved),
                        ContractSigned__c = String.valueOf(rw.contract_signed),
                        Sub_Area__c = rw.sub_areas,
                        FinalExpirationConfirmed__c = Boolean.valueOf(rw.final_expiration_confirmed),
                        Customer_Number__c = rw.customer_contract_number,
                        Internal_Contract_Number__c = rw.internal_contract_number,
                        Final_Date_Of_Expiry__c = String.isNotBlank(rw.final_date_of_expiry) ? Date.valueOf(rw.final_date_of_expiry) : null,
                        Start_Date__c = String.isNotBlank(rw.start_date) ? Date.valueOf(rw.start_date) : null,
                        Contract_Type__c = rw.contract_type,
                        Business_Unit__c = rw.business_unit_name,
                        Sys_Id_External__c = rw.sys_id,
                        LegalOwner__c = rw.legal_owner_name
                );
                if (accountsIds.contains(rw.primary_customer_salesforce_id)) {
                    contractArchive.Primary_Customer__c = rw.primary_customer_salesforce_id;
                }

                if (rw.customer_contract_name != null) {
                    if (rw.customer_contract_name.length() > 80) {
                        contractArchive.Name = rw.customer_contract_name.substring(0, 80);
                    } else {
                        contractArchive.Name = rw.customer_contract_name;
                    }
                }
                contractsArchives.add(contractArchive);
                if(rw.opportunity_salesforce_id != null){
                    opportunityId2ExternalId.put(rw.opportunity_salesforce_id, rw.sys_id);
                }
            }
            return contractsArchives;
//        } catch (Exception e) {
//            Utils.logFailure('ServiceNowSyncContractArchiveRecords', 'createContractArchives', e.getMessage(), 'Failed', UserInfo.getUserName(), 'Exception occurred during creating Contract Archive records');
//            return null;
//        }
    }


    private static void upsertContractArchives(List<Contract_Archive__c> contractsArchives) {
//        try {
            Boolean foundError = false;
            Logger.info('contractArchives', contractsArchives).addTag('Sync Contact Archive Records');
            Database.UpsertResult[] upsertResults = Database.upsert(contractsArchives, Contract_Archive__c.Fields.Sys_Id_External__c, false);
            Logger.info('upsertResults: ', upsertResults).addTag('Sync Contact Archive Records');
            for (Database.UpsertResult upsertResult : upsertResults) {
                Logger.info('upsertResult', upsertResult).addTag('Sync Contact Archive Records');
                if (!upsertResult.isSuccess()) {
                    for (Database.Error error : upsertResult.getErrors()) {
                        Logger.error('Error: ' + error.getStatusCode() + error.getMessage(), upsertResult.getId()).addTag('Sync Contact Archive Records');
                    }
                    foundError = true;
                }
            }
            if (!foundError) {
                List<Contract_Archive__c> contractArchives = [SELECT Id, Sys_Id_External__c FROM Contract_Archive__c WHERE Sys_Id_External__c IN :opportunityId2ExternalId.values()];
                Map<String,String> externalId2contractId = new Map<String,String>();
                for(Contract_Archive__c contractArchive : contractArchives){
                    externalId2contractId.put(contractArchive.Sys_Id_External__c, contractArchive.Id);
                }
                List<Opportunity> opportunities = [SELECT Id, Contract_Lookup__c FROM Opportunity WHERE Id IN :opportunityId2ExternalId.keySet()];
                for(Opportunity opp : opportunities) {
                    opp.Contract_Lookup__c = externalId2contractId.get(opportunityId2ExternalId.get(opp.Id));
                }
                Database.update(opportunities,true);
                settings.LastContractsSynchronization__c = Datetime.now().addHours(-2);
                update settings;
            } else{
				Logger.saveLog();
			}
//        } catch (Exception e) {
//            Utils.logFailure('ServiceNowSyncContractArchiveRecords', 'upsertContractArchives', e.getMessage(), 'Failed', UserInfo.getUserName(), 'Exception occurred during upserting Contract Archive records');
//        }
    }

    public class ResponseWrapper {
        public List<ContractWrapper> result;
    }

    public class ContractWrapper {
        public String final_expiration_confirmed;
        public String contract_state;
        public String customer_contract_name;
        public String contract_approved;
        public String contract_signed;
        public String sys_id;
        public String primary_customer_name;
        public String customer_contract_number;
        public String sub_areas;
        public String final_date_of_expiry;
        public String start_date;
        public String contract_type;
        public String business_unit_name;
        public String primary_customer_salesforce_id;
        public String internal_contract_number;
        public String legal_owner_name;
        public String opportunity_salesforce_id;
    }
}