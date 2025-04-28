/**
 * Created by kjachowicz on 29.09.2023.
 */

public with sharing class ServiceNowIntegrationSelector {

    public static Opportunity retrieveOpportunity(String recordId) {
        return [
                SELECT Id,
                        Name,
                        Account.SN_sys_id__c,
                        AccountId,
                        Owner.Email,
                        Contract_Lookup__r.Sys_Id_External__c,
                        ContractSysId__c,
                        Comments__c,
                        OwnerId,
                        Sub_Area__c,
                        Call_Off_Contract__r.Name,
                        Call_Off_Contract__r.Number__c,
                        Call_Off_Contract__r.Sys_Id_External__c,
                        UploadTime__c,
                        Contract_Category__c,
                        Owner.Username
                FROM Opportunity
                WHERE Id = :recordId
        ];
    }

    public static List<Account> retrieveAccount(Opportunity opportunity) {
        if (opportunity != null) {
            return [SELECT Id, SN_sys_id__c FROM Account WHERE Name = :opportunity.Owner.CompanyName];
        } else {
            return [SELECT Id, SN_sys_id__c FROM Account];
        }
    }

    public static List<Contract_Archive__c> retrieveContracts() {
        return [
                SELECT Id,
                        Sys_Id_External__c,
                        Account__c,
                        Name,
                        Internal_Contract_Number__c,
                        Final_Date_Of_Expiry__c,
                        Start_Date__c,
                        Contract_Manager__c,
                        LegalOwner__c,
                        LegalOwnerCountry__c
                FROM Contract_Archive__c
        ];
    }

    public static List<Account_Contract_Archive_Junction__c> retrieveJunctions(){
        return [
                SELECT Id,Account__c,Contract_Archive__c
                FROM Account_Contract_Archive_Junction__c
        ];
    }
}