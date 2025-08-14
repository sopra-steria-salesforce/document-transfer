public with sharing class FileUploadMultiController {
    public FileUploadMultiController() {

    }
    
    @AuraEnabled
    public static Boolean doesOpportunityCountryMatchNavisionCountry(Opportunity opportunity){
        System.debug('doesOpportunityCountryMatchNavisionCountry');
        System.debug(opportunity);
        AwardedOpportunities awardedOpportunities = new AwardedOpportunities(new List<Opportunity>{opportunity});
        awardedOpportunities.filterByMatchingOwnerCountry();
        return !awardedOpportunities.isEmpty();
    }
}