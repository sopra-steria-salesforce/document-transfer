public with sharing class CallOffContractIterable implements Iterable<Call_Off_Contract__c>{
    private List<Call_Off_Contract__c> callOffContracts;
    
    public CallOffContractIterable(List<Call_Off_Contract__c> callOffContracts) {
        this.callOffContracts = callOffContracts;
    }

    public Iterator<Call_Off_Contract__c> Iterator(){
        return new CallOffContractIterable(callOffContracts);
    }
}