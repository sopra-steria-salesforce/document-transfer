/**
 * Created by pjakubiak on 7/3/2023.
 */public with sharing class OpportunityContractController {
    private static final String EXPIRED = 'Expired';

    @AuraEnabled(Cacheable=true) public static List<ContractWrapper> getRelatedContracts(Id opportunityId) {
        try {
            List<Contract_Archive__c> contracts = new List<Contract_Archive__c>();
            Opportunity opportunity = [SELECT Id, AccountId, Owner.Country FROM Opportunity WHERE Id = :opportunityId];

            List<Account_Contract_Archive_Junction__c> junctionRecords = [
                    SELECT Id,
                            Name,
                            Contract_Archive__c,
                            Account__c,
                            Internal_Contract_Number__c,
                            Contract_Archive__r.LegalOwnerCountry__c,
                            Contract_Archive__r.FinalExpirationConfirmed__c
                    FROM Account_Contract_Archive_Junction__c
                    WHERE Account__c = :opportunity.AccountId
                    AND (Contract_Archive__r.Contract_State__c != :EXPIRED
                    OR (Contract_Archive__r.FinalExpirationConfirmed__c = FALSE
                    AND (Contract_Archive__r.Contract_State__c = 'Terminated'
                    OR Contract_Archive__r.Contract_State__c = :EXPIRED)))

                    AND Contract_Archive__r.LegalOwnerCountry__c = :opportunity.Owner.Country
                    AND Contract_Archive__r.Contract_State__c != ''
            ];
            Set<Id> contractIds = new Set<Id>();
            for (Account_Contract_Archive_Junction__c junctionRec : junctionRecords) {
                if (!String.isEmpty(junctionRec.Contract_Archive__c) && !String.isEmpty(junctionRec.Account__c)) {
                    contractIds.add(junctionRec.Contract_Archive__c);
                }
            }
            if (!contractIds.isEmpty()) {
                contracts = [
                        SELECT Id, Name, Final_Date_Of_Expiry__c, Start_Date__c, Internal_Contract_Number__c, Contract_Type__c, Contract_State__c, Primary_Customer__c, Primary_Customer__r.Name,
                                Approved__c,
                                Customer_Number__c, Parent_Contract_Archive__r.Name, Business_Unit__c, Sub_Area__c
                        FROM Contract_Archive__c
                        WHERE Id IN :contractIds
                ];
            }
            List<ContractWrapper> contractWrappers = new List<ContractWrapper>();
            for (Contract_Archive__c contract : contracts) {
                ContractWrapper contractWrapper = new ContractWrapper(contract);
                contractWrappers.add(contractWrapper);
            }
            Logger.info('contarctWrappers' + contractWrappers);
            return contractWrappers;
        }catch (Exception e) {
            Logger.Error('Expception', Id.valueOf(opportunityId), e);
            Logger.saveLog();
            return null;
        }
    }

    @AuraEnabled public static void updateOpportunityWithContract(String opportunityId, String selectedContract) {
        try {
            Opportunity opp = [SELECT Id, Contract_Lookup__c, Account_Contract_Archive_Junction__c, AccountId FROM Opportunity WHERE Id = :opportunityId];
            Map<String, Object> contractMap = (Map<String, Object>) JSON.deserializeUntyped(selectedContract);
            System.debug(contractMap);
            List<Object> selectedContracts = (List<Object>) contractMap.get('selectedContract');
            List<Object> selectedSubArea = (List<Object>) contractMap.get('selectedSubArea');
            Map<String, Object> contract = (Map<String, Object>) selectedContracts[0] == null ? new Map<String, Object>() : (Map<String, Object>) selectedContracts[0];
            Map<String, Object> subArea = (Map<String, Object>) selectedSubArea[0] == null ? new Map<String, Object>() : (Map<String, Object>) selectedSubArea[0];
            String subAreaNameContract = (String) subArea.get('subAreaName');

            opp.Contract_Lookup__c = (String) contract.get('contractId');
            Account_Contract_Archive_Junction__c junction = [SELECT Id, Contract_Archive__c FROM Account_Contract_Archive_Junction__c WHERE Account__c = :opp.AccountId AND Contract_Archive__c = :(String) contract.get('contractId') LIMIT 1];

            opp.Account_Contract_Archive_Junction__c = junction.Id;
            opp.Sub_Area__c = subAreaNameContract;
            update opp;
        }catch(Exception e){
            Logger.Error('Expception', Id.valueOf(opportunityId), e);
            Logger.saveLog();

        }
    }

    @AuraEnabled(Cacheable=true) public static Opportunity getOpportunityFields(Id opportunityId) {
        Opportunity opp = [SELECT Id, Name, Type, StageName, CloseDate FROM Opportunity WHERE Id = :opportunityId];
        return opp;
    }

    @AuraEnabled public static List<CallOffWrapper> retrieveCallOffContracts(String contractId) {
        try {
            List<Call_Off_Contract__c> callOffContracts = [
                    SELECT Id, Name, Parent_Contract__c, Parent_Contract__r.Name, Sub_Area__c, Final_Date_of_Expiry__c, Number__c, Start_Date__c, Identification_Number__c, Contract_Number__c, Contract_Type__c, State__c
                    FROM Call_Off_Contract__c
                    WHERE Parent_Contract__c = :contractId AND (State__c = 'Active' OR State__c = 'Draft')
            ];
            List<CallOffWrapper> callOffWrappers = new List<CallOffWrapper>();
            for (Call_Off_Contract__c callOff : callOffContracts) {
                CallOffWrapper callOffWrapper = new CallOffWrapper(callOff);
                callOffWrappers.add(callOffWrapper);
            }
            Logger.info('calloffWrappers' + callOffWrappers);
            return callOffWrappers;
        }catch (Exception e) {
            Logger.Error('Expception', Id.valueOf(contractId), e);
            Logger.saveLog();
            return null;
        }
    }

    public class CallOffWrapper {
        @AuraEnabled public String callOffId;
        @AuraEnabled public String callOffName;
        @AuraEnabled public String parentContractName;
        @AuraEnabled public String subArea;
        @AuraEnabled public String finalDateOfExpiry;
        @AuraEnabled public String internalNumber;
        @AuraEnabled public String startDate;
        @AuraEnabled public String identificationNumber;
        @AuraEnabled public String contractNumber;
        @AuraEnabled public String contractType;
        @AuraEnabled public String state;

        public CallOffWrapper(Call_Off_Contract__c callOff) {
            this.callOffId = callOff.Id;
            this.callOffName = callOff.Name;
            this.parentContractName = callOff.Parent_Contract__r.Name;
            this.subArea = callOff.Sub_Area__c;
            this.finalDateOfExpiry = callOff.Final_Date_of_Expiry__c;
            this.internalNumber = callOff.Number__c;
            this.startDate = callOff.Start_Date__c;
            this.identificationNumber = callOff.Identification_Number__c;
            this.contractNumber = callOff.Contract_Number__c;
            this.contractType = callOff.Contract_Type__c;
            this.state = callOff.State__c;
        }
    }
    public class ContractWrapper {
        @AuraEnabled public String contractId;
        @AuraEnabled public String contractName;
        @AuraEnabled public String internalContractNumber;
        @AuraEnabled public String contractType;
        @AuraEnabled public String contractState;
        @AuraEnabled public String primaryCustomer;
        @AuraEnabled public String primaryCustomerName;
        @AuraEnabled public String contractApproved;
        @AuraEnabled public String parentAgreementName;
        @AuraEnabled public String customerNumber;
        @AuraEnabled public String businessUnit;
        @AuraEnabled public String subArea;
        @AuraEnabled public Date finalDateOfExpiry;
        @AuraEnabled public Date startDate;

        public ContractWrapper(Contract_Archive__c contract) {
            this.contractName = contract.Name;
            this.internalContractNumber = contract.Internal_Contract_Number__c;
            this.contractType = contract.Contract_Type__c;
            this.primaryCustomer = contract.Primary_Customer__c;
            this.primaryCustomerName = contract.Primary_Customer__r.Name;
            this.contractApproved = contract.Approved__c;
            this.contractId = contract.Id;
            this.contractState = contract.Contract_State__c;
            this.finalDateOfExpiry = contract.Final_Date_Of_Expiry__c;
            this.startDate = contract.Start_Date__c;
            this.parentAgreementName = contract.Parent_Contract_Archive__r.Name;
            this.customerNumber = contract.Customer_Number__c;
            this.businessUnit = contract.Business_Unit__c;
            this.subArea = contract.Sub_Area__c;
        }
    }
}