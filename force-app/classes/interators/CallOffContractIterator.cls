public with sharing class CallOffContractIterator {
    private List<Call_Off_Contract__c> callOffContracts;
    private Integer index = 0;

    public CallOffContractIterator(List<Call_Off_Contract__c> callOffContracts) {
        this.callOffContracts = callOffContracts;
    }

    public Boolean hasNext(){
        return index < callOffContracts.size();
    }

    public Call_Off_Contract__c next(){
        return callOffContracts[index++];
    }
}