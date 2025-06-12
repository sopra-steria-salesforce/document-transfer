import { LightningElement, wire, api, track } from 'lwc';
import getRelatedContracts from '@salesforce/apex/OpportunityContractController.getRelatedContracts';
import retrieveCallOffContracts from '@salesforce/apex/OpportunityContractController.retrieveCallOffContracts';
import { CurrentPageReference } from 'lightning/navigation';
import CONTRACT_CATEGORY from '@salesforce/schema/Opportunity.Contract_Category__c';
import { getRecord, getFieldValue } from "lightning/uiRecordApi";
const fields = [CONTRACT_CATEGORY];
const subAreaColumns = [
    { label: 'Sub Area', fieldName: 'subAreaName' },
    { label: 'Contract Number', fieldName: 'internalContractNumber'}
];

const columns = [
    { label: 'Contract Name', fieldName: 'contractName' },
    { label: 'Customer', fieldName: 'primaryCustomerName'},
    { label: 'Contract Number', fieldName: 'customerNumber' },
    { label: 'Contract Type', fieldName: 'contractType' },
    { label: 'Internal Contract Number', fieldName: 'internalContractNumber' },
    { label: 'Final Date of Expiry', fieldName: 'finalDateOfExpiry' }
];

const callOffWrapperColumns = [
    { label: 'Call Off Name', fieldName: 'callOffName' },
    { label: 'Contract Number', fieldName: 'contractNumber' },
    { label: 'Contract Type', fieldName: 'contractType' },
    { label: 'Number', fieldName: 'internalNumber' },
    { label: 'Sub Area', fieldName: 'subArea' },
    { label: 'Identification Number', fieldName: 'identificationNumber' }
];

export default class ContractsList extends LightningElement {
    @api recordId;
    @track contracts = [];
    @track subAreas = [];
    @track parentAgreements = [];
    selectedContract;
    displaySubArea;
    @track contractExist ;
    data =[];
    columns = columns;
    subAreaColumns = subAreaColumns;
    callOffWrapperColumns = callOffWrapperColumns;
    combinedContractWithSubArea = {};
    combinedContractWithCallOff = {};
    opportunity = {};
    displayCallOffs = false;


    @wire(getRecord, { recordId: "$recordId", fields })
    wiredOpportunity;
    @wire(CurrentPageReference)
    getStateParameters(currentPageReference) {
        if (currentPageReference) {
            this.recordId = currentPageReference.state.recordId;
        }
    }
    @wire(getRelatedContracts, { opportunityId: '$recordId' })
    wiredContracts({ error, data }) {
        if (data) {
            this.data = data;
            this.contracts = data.map(contract => ({ ...contract, isSelected: false }));
            this.contractExist = !!this.contracts.length > 0;
        } else if (error) {
            console.error('Error retrieving contracts:', error);
        }
    }
    get newCallOff() {
        return getFieldValue(this.wiredOpportunity.data, CONTRACT_CATEGORY) === 'New call off (Agreement on existing contract)';
    }
    get changeCallOff() {
        return getFieldValue(this.wiredOpportunity.data, CONTRACT_CATEGORY) === 'Change to an active call off or contract';
    }
    handleContract(event) {
        this.subAreas = [];
        this.selectedContract = event.detail.selectedRows;
        console.log(this.selectedContract)
        this.combinedContractWithSubArea["selectedContract"] = this.selectedContract;
//        this.combinedContractWithCallOff["selectedContract"] = this.selectedContract;

        if (this.newCallOff) {
            if (this.selectedContract[0].subArea) {
                const subAreas = this.selectedContract[0].subArea.split(';');
                for (let i = 0; i < subAreas.length; i++) {
                    let obj = {};
                    obj['subAreaName'] = subAreas[i];
                    obj['internalContractNumber'] = this.selectedContract[0].internalContractNumber;
                    this.subAreas.push(obj);
                }
                this.displaySubArea = true;
            }else{
                this.combinedContractWithSubArea["selectedSubArea"] = [{
                    "subAreaName": '',
                    "internalContractNumber": ''
                }];
                this.dispatchEvent(new CustomEvent('contractselect', {detail:this.combinedContractWithSubArea}));

            }

        }
            if (this.changeCallOff) {
                console.log('calloff');
                console.log(this.combinedContractWithSubArea);
                this.combinedContractWithSubArea["selectedSubArea"] = [{
                    "subAreaName": '',
                    "internalContractNumber": ''
                }];
                this.dispatchEvent(new CustomEvent('contractselect', {detail:this.combinedContractWithSubArea}));
            }



    }
    handleSubArea(event) {
        this.selectedSubArea = event.detail.selectedRows;
        this.combinedContractWithSubArea['selectedSubArea'] = this.selectedSubArea;
        this.dispatchEvent(new CustomEvent('contractselect', {detail: this.combinedContractWithSubArea}));
    }
    handleCallOff(event) {
        this.selectedCallOff = event.detail.selectedRows;
        this.combinedContractWithCallOff["selectedSubArea"] = [{
            "subAreaName": '',
            "internalContractNumber": ''
        }];
        this.combinedContractWithCallOff['selectedCallOff'] = this.selectedCallOff;
        this.dispatchEvent(new CustomEvent('contractselect', {detail: this.combinedContractWithCallOff}));
    }
}