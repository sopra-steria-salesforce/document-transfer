public inherited sharing abstract class Opportunities {
	protected List<Opportunity> opportunities;

	public List<Opportunity> getRecords(){
		return this.opportunities;
	}

	public Boolean isEmpty(){
		return this.opportunities.isEmpty();
	}
}