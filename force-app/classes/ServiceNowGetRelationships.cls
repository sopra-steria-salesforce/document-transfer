public with sharing class ServiceNowGetRelationships {
    static Map<String, String> serviceNowContractId2SalesforceContractId = new Map<String, String>();
    static List<Account_Contract_Archive_Junction__c> accountContractArchiveJunctions = new List<Account_Contract_Archive_Junction__c>();
    static List<String> accountIds = new List<String>();
    @Future(Callout=true)
    public static void assignContractsWithAccounts() {
        try {
            HttpResponse response = Utils.doRequest(Utils.NAMED_CREDENTIAL_SERVICE_NOW, Utils.API_GET_ALL_CONTRACTS_AND_CUSTOMERS_M2M, Utils.METHOD_GET, null);
            if (response.getStatusCode() == 200) {
                System.debug(response.getBody());
                OuterWrapper outerWrapper = (OuterWrapper) System.JSON.deserialize(response.getBody(), OuterWrapper.class);
                createFilterMaps();
                createJunctions(outerWrapper);
                upsert accountContractArchiveJunctions Account_Contract_Archive_Junction_Sys_Id__c;
            } else {
                Utils.logFailure('ServiceNowGetRelationships', 'assignContractsWithAccounts', response.getBody(), 'Failed', UserInfo.getUserName(), 'Failed to retrieve relationships between Accounts and Contract Archives');
            }
        } catch (Exception e) {
            Utils.logFailure('ServiceNowGetRelationships', 'assignContractsWithAccounts', e.getMessage(), 'Failed',  UserInfo.getUserName(), 'Exception occurred during API call');
        }
    }


    public static void createJunctions(OuterWrapper outerWrapper) {
        try {
            for (ResponseWrapper wrapper : outerWrapper.result) {
                if (serviceNowContractId2SalesforceContractId.containsKey(wrapper.contract_sys_id) && accountIds.contains(wrapper.customer_salesforce_id)) {
                    createNewJunctionsRecords(wrapper);
                }
            }
        } catch (Exception e) {
            Utils.logFailure('ServiceNowGetRelationships', 'createJunctions', e.getMessage(), 'Failed', UserInfo.getUserName(), 'Exception occurred during junction creation');
        }
    }


    public static void createNewJunctionsRecords(ResponseWrapper wrapper) {
        Account_Contract_Archive_Junction__c accountContractArchiveJunction = new Account_Contract_Archive_Junction__c();
        if (wrapper.customer_salesforce_id != null && wrapper.customer_salesforce_id != '') {
            accountContractArchiveJunction.Account__c = wrapper.customer_salesforce_id;
            accountContractArchiveJunction.Contract_Archive__c = serviceNowContractId2SalesforceContractId.get(wrapper.contract_sys_id);
            accountContractArchiveJunction.Internal_Contract_Number__c = wrapper.contract_internal_number;
            accountContractArchiveJunction.Account_Contract_Archive_Junction_Sys_Id__c = wrapper.relationship_sys_id;
            accountContractArchiveJunctions.add(accountContractArchiveJunction);
        }
    }
    public static void createFilterMaps() {
        for (Contract_Archive__c contractArchive : ServiceNowIntegrationSelector.retrieveContracts()) {
            serviceNowContractId2SalesforceContractId.put(contractArchive.Sys_Id_External__c, contractArchive.Id);
        }
        for (Account acc : ServiceNowIntegrationSelector.retrieveAccount(null)) {
            accountIds.add(acc.Id);
        }
    }

    public class OuterWrapper {
        public List<ResponseWrapper> result;
    }

    public class ResponseWrapper {
        public String contract_sys_id;
        public String customer_salesforce_id;
        public String contract_internal_number;
        public String relationship_sys_id;
    }
}