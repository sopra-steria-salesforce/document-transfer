public with sharing class FileUploadMultiController {
    public FileUploadMultiController() {

    }
    
    @AuraEnabled
    public static Boolean doesOpportunityCountryMatchNavisionCountry(Opportunity opportunity){
        Logger.debug('doesOpportunityCountryMatchNavisionCountry');
        Logger.saveLog();
        Logger.debug('Opportunity ',opportunity);
        AwardedOpportunities awardedOpportunities = new AwardedOpportunities(new List<Opportunity>{opportunity});
        awardedOpportunities.filterByMatchingOwnerCountry();
        return !awardedOpportunities.isEmpty();
    }
}