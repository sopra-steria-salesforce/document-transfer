public with sharing class FileUploadMultiController {    
    @AuraEnabled
    public static Boolean doesOpportunityCountryMatchNavisionCountry(Id opportunityId){
        Opportunity opportunity = [
            SELECT Id,
                AccountId,
                OwnerId,
                StageName,
                Owner_Country__c,
                Account.Navision_Customer_No__c,
                Account.Navision_Customer_SE__c,
                Account.Navision_Customer_DK__c,
                ContractServiceNowUrl__c,
                New_Or_Renewal__c
            FROM Opportunity
            WHERE Id = :opportunityId
            LIMIT 1
        ];
        AwardedOpportunities awardedOpportunities = new AwardedOpportunities(new List<Opportunity>{opportunity});
        awardedOpportunities.filterByMatchingOwnerCountry();
        return !awardedOpportunities.isEmpty();
    }
}