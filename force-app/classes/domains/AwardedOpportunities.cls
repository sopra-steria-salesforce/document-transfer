public inherited sharing class AwardedOpportunities extends Opportunities{
	public AwardedOpportunities(List<Opportunity> opportunities) {
		this.opportunities = new List<Opportunity>();
		for (Opportunity opportunity : opportunities) {
			if (opportunity.StageName == AWARDED) {
				this.opportunities.add(opportunity);
			}
		}
	}

	public AwardedOpportunities(List<Opportunity> newOpportunities, List<Opportunity> oldOpportunities) {
		this.opportunities = new List<Opportunity>();
		Map<Id, Opportunity> oldOpportunitiesByIds = new Map<Id, Opportunity>(oldOpportunities);
		for (Opportunity newOpportunity : newOpportunities) {
			Opportunity oldOpportunity = oldOpportunitiesByIds.get(newOpportunity.Id);
			if (newOpportunity.StageName == AWARDED && newOpportunity.StageName!=oldOpportunity.StageName) {
				this.opportunities.add(newOpportunity);
			}
		}
	}

	/**
	 * @description: Remove Opportunities where Owner Country does not match the Country that the Parent Account is registerd in Navision
	 */
	public AwardedOpportunities filterByMatchingOwnerCountry(){
		List<Opportunity> opportunitiesWhereOwnerCountryMatchesNavisionCountry = new List<Opportunity>();
		for (Opportunity opportunity:this.opportunities){
			if (doesOpportunityOwnerCountryMatchNavisionCustomerCountry(parentAccountsByIds.get(opportunity.AccountId), opportunityOwnersByIds.get(opportunity.OwnerId))) {
				opportunitiesWhereOwnerCountryMatchesNavisionCountry.add(opportunity);
			} else{
				Logger.error('Opportunity Owner Country: "'+opportunity.Owner_Country__c+'" does not match the Account\'s Country in Navision', opportunity);
			}
		}
		this.opportunities =opportunitiesWhereOwnerCountryMatchesNavisionCountry;
		return this;
	}

	public AwardedOpportunities filterNewOpportunitiesWithoutContracts(){
		List<Opportunity> opportunitiesWithNoContractInServiceNow = new List<Opportunity>();
		for (Opportunity opportunity:this.opportunities){
			if(
				opportunity.New_Or_Renewal__c == 'New' &&
				String.isBlank(opportunity.ContractServiceNowUrl__c)
			){
				opportunitiesWithNoContractInServiceNow.add(opportunity);
				Logger.info('Contract is created in ServiceNow for this Opportunity', opportunity).addTag('Opportunity trigger handler service');
			} else {
				Logger.info('Contract is not created is ServiceNow for this Opportunity', opportunity).addTag('Opportunity trigger handler service');
				Logger.info('New or renewal: ' + opportunity.New_Or_Renewal__c).addTag('Opportunity trigger handler service');
				Logger.info('Service Now contract url: ' + opportunity.ContractServiceNowUrl__c).addTag('Opportunity trigger handler service');
			}
		}
		if (!this.isEmpty()) {
			Logger.saveLog();
		}

		this.opportunities=opportunitiesWithNoContractInServiceNow;
		return this;
	}

	public void upsertContractToServiceNow(){
		//TODO: Bulkify - CIS-105
		List<Opportunity> clonedOpportunities = this.opportunities.deepClone(true); //Need to clone to prevent "Record is read-only" error in Queueable due to being After Update context.
		for (Opportunity opportunity:clonedOpportunities){
			DML.enqueueJob(new ServiceNowUploadContractsQueueable(opportunity));
		}
	}

	public Boolean doesOpportunityOwnerCountryMatchNavisionCustomerCountry(Account parentAccount, User opportunityOwner){
		return
				opportunityOwner.Country=='Norway' && parentAccount.Navision_Customer_NO__c ||
				opportunityOwner.Country=='Sweden' && parentAccount.Navision_Customer_SE__c ||
				opportunityOwner.Country=='Denmark' && parentAccount.Navision_Customer_DK__c;
	}
}