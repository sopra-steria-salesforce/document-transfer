public inherited sharing class AwardedOpportunities extends Opportunities{
	public List<Opportunity> awardedOpportunities;

	public AwardedOpportunities(List<Opportunity> opportunities) {
		List<Opportunity> awardedOpportunities = new List<Opportunity>();
		for (Opportunity opportunity : opportunities) {
			if (opportunity.StageName == Utils.AWARDED) {
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
			if (newOpportunity.StageName == Utils.AWARDED && newOpportunity.StageName!=oldOpportunity.StageName) {
				awardedOpportunities.add(newOpportunity);
			}
		}
		this.awardedOpportunities=awardedOpportunities;
	}

	public void filterByMatchingOwnerCountry(){
		List<Opportunity> opportunitiesWhereOwnerCountryMatchesNavisionCountry = new List<Opportunity>();
		Map<Id, Account> parentAccountsByIds = getParentAccountByIdsFromChildOpportunities();
		for (Opportunity opportunity:this.opportunities){
			if (doesOpportunityOwnerCountryMatchNavisionCustomerCountry(opportunity, parentAccountsByIds.get(opportunity.AccountId))) {
				opportunitiesWhereOwnerCountryMatchesNavisionCountry.add(opportunity);
			} else{
				Logger.error('Opportunity Owner Country: "'+opportunity.Owner_Country__c+'" does not match the Account\'s Country in Navision', opportunity);
			}
		}
		this.opportunities=opportunitiesWhereOwnerCountryMatchesNavisionCountry;
	}
	public Boolean doesOpportunityOwnerCountryMatchNavisionCustomerCountry(Opportunity opportunity, Account parentAccount){
		return
				opportunity.Owner.Country=='Norway' && parentAccount.Navision_Customer_NO__c ||
						opportunity.Owner.Country=='Sweden' && parentAccount.Navision_Customer_SE__c ||
						opportunity.Owner.Country=='Denmark' && parentAccount.Navision_Customer_DK__c;
	}

	public Map<Id, Account> getParentAccountByIdsFromChildOpportunities(){
		Set<Id> accountIds = new Set<Id>();
		for (Opportunity opportunity:this.opportunities){
			accountIds.add(opportunity.AccountId);
		}
		return new Map<Id, Account>([SELECT Navision_Customer_NO__c, Navision_Customer_DK__c, Navision_Customer_SE__c FROM Account WHERE Id IN: accountIds]);
	}
}