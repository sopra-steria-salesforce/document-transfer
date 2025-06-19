public inherited sharing class AwardedOpportunities extends Opportunities{
	private List<Opportunity> awardedOpportunities;

	public AwardedOpportunities(List<Opportunity> opportunities) {
		List<Opportunity> awardedOpportunities = new List<Opportunity>();
		for (Opportunity opportunity : opportunities) {
			if (opportunity.StageName == AWARDED) {
				awardedOpportunities.add(opportunity);
			}
		}
		this.awardedOpportunities=awardedOpportunities;
	}

	public AwardedOpportunities(List<Opportunity> newOpportunities, List<Opportunity> oldOpportunities) {
		List<Opportunity> awardedOpportunities = new List<Opportunity>();
		Map<Id, Opportunity> oldOpportunitiesByIds = new Map<Id, Opportunity>(oldOpportunities);
		for (Opportunity newOpportunity : newOpportunities) {
			Opportunity oldOpportunity = oldOpportunitiesByIds.get(newOpportunity.Id);
			if (newOpportunity.StageName == AWARDED && newOpportunity.StageName!=oldOpportunity.StageName) {
				awardedOpportunities.add(newOpportunity);
			}
		}
		this.awardedOpportunities=awardedOpportunities;
	}

	public AwardedOpportunities filterByMatchingOwnerCountry(){
		List<Opportunity> opportunitiesWhereOwnerCountryMatchesNavisionCountry = new List<Opportunity>();
		Map<Id, Account> parentAccountsByIds = getParentAccountByIds();
		Map<Id, User> opportunityOwnerByIds = getOpportunityOwnersByIds();
		for (Opportunity opportunity:this.opportunities){
			if (doesOpportunityOwnerCountryMatchNavisionCustomerCountry(parentAccountsByIds.get(opportunity.AccountId), opportunityOwnerByIds.get(opportunity.OwnerId))) {
				opportunitiesWhereOwnerCountryMatchesNavisionCountry.add(opportunity);
			} else{
				Logger.error('Opportunity Owner Country: "'+opportunity.Owner_Country__c+'" does not match the Account\'s Country in Navision', opportunity);
			}
		}
		this.awardedOpportunities=opportunitiesWhereOwnerCountryMatchesNavisionCountry;
		return this;
	}

	public Boolean doesOpportunityOwnerCountryMatchNavisionCustomerCountry(Account parentAccount, User opportunityOwner){
		return
				opportunityOwner.Country=='Norway' && parentAccount.Navision_Customer_NO__c ||
				opportunityOwner.Country=='Sweden' && parentAccount.Navision_Customer_SE__c ||
				opportunityOwner.Country=='Denmark' && parentAccount.Navision_Customer_DK__c;
	}
}