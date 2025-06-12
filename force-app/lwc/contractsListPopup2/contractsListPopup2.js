import { LightningElement, track, api } from 'lwc';
import updateOpportunityWithContract from '@salesforce/apex/OpportunityContractController.updateOpportunityWithContract';
import { CloseActionScreenEvent } from 'lightning/actions';
import { RefreshEvent } from 'lightning/refresh';

export default class ContractsListPopup extends LightningElement {
    @track popupClass = 'slds-modal slds-fade-in-open slds-modal_large';
    @api recordId;
    @track isSaving;
    selectedContract = {};

    handleContractSelect(event) {
        this.selectedContract = event.detail;
    }
    get disableButton(){
        return !(this.selectedContract);
    }
    handleSave() {
        console.log('handle save');
        console.log(this.selectedContract);
        if (this.selectedContract["selectedContract"].length > 0){
            this.isSaving = true;
            updateOpportunityWithContract({
                opportunityId: this.recordId,
                selectedContract: JSON.stringify(this.selectedContract)
            })
                .then(() => {
                    eval("$A.get('e.force:refreshView').fire();");
                })
                .then(() => {
                    this.closeAction();
                }).then(() => {
                this.closeAction();
                })
                .then(() => {
                    this.closeAction();
                })
                .catch(error => {
                    console.error('Error updating opportunity:', error);
                });
        }
    }

    closeAction() {
        this.dispatchEvent(new CloseActionScreenEvent());
    }
}