public inherited sharing abstract class Opportunities {
	protected List<Opportunity> opportunities;

	//STAGENAME
	public static final String PLANNING_0 = '0 - Planning';
	public static final String AWARDED = '5 - Awarded';

	public List<Opportunity> getRecords() {
		return this.opportunities;
	}

	public Map<Id, Account> parentAccountsByIds {
		get{
			if (parentAccountsByIds==null) {
				parentAccountsByIds=getParentAccountByIds();
			}
			return parentAccountsByIds;
		}
		private set;
	}

	public Map<Id, User> opportunityOwnersByIds {
		get{
			if (opportunityOwnersByIds==null) {
				opportunityOwnersByIds = getOpportunityOwnersByIds();
			}
			return opportunityOwnersByIds;
		}
		private set;
	}

	public Boolean isEmpty(){
		return this.opportunities.isEmpty();
	}

	public Map<Id, Account> getParentAccountByIds(){
		Set<Id> accountIds = new Set<Id>();
		for (Opportunity opportunity:this.opportunities){
			accountIds.add(opportunity.AccountId);
		}
		return new Map<Id, Account>([SELECT Navision_Customer_NO__c, Navision_Customer_DK__c, Navision_Customer_SE__c FROM Account WHERE Id IN: accountIds]);
	}

	public Map<Id, User> getOpportunityOwnersByIds(){
		Set<Id> ownerIds = new Set<Id>();
		for (Opportunity opportunity:this.opportunities){
			ownerIds.add(opportunity.OwnerId);
		}
		return new Map<Id, User>([SELECT Country FROM User WHERE Id IN:ownerIds]);
	}
}