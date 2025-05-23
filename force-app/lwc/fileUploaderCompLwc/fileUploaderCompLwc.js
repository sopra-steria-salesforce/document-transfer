import {LightningElement, api, wire, track} from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { getRecord, getFieldValue } from "lightning/uiRecordApi";
import CONTRACT_LOOKUP from "@salesforce/schema/Opportunity.Contract_Lookup__c";
import CONNECTED_TO_EXISTING_CONTRACT from "@salesforce/schema/Opportunity.ConnectedToExistingContract__c";
import uploadContract from '@salesforce/apex/ServiceNowUploadContracts.uploadContracts'
import {refreshApex} from "@salesforce/apex";
const FIELDS = [CONTRACT_LOOKUP,CONNECTED_TO_EXISTING_CONTRACT];

export default class FileUploaderCompLwc extends LightningElement {
    fields = FIELDS;
    @track validateUpload = false;
    contractLookupField = CONTRACT_LOOKUP;
    connectedToExistingContract = CONNECTED_TO_EXISTING_CONTRACT;
    @api recordId;
    fileData
    @track opportunity

    @api objectApiName;
    @track show = false;


    // @wire(getRecord, {recordId: "$recordId", fields})
    // opportunity;

    get getValidateUpload () {
        this.validateUpload = (this.opportunity.data?.fields.ConnectedToExistingContract__c.value === 'No' && this.opportunity.data?.fields.Contract_Lookup__c.value == null) ||
            (this.opportunity.data?.fields.ConnectedToExistingContract__c.value === 'Yes' && this.opportunity.data?.fields.Contract_Lookup__c.value != null);
    }


    @wire(getRecord, { recordId: '$recordId', fields: '$fields' })
    fetchOpp(response) {
        if(response) {
            this.opportunity = response;
            this.getValidateUpload
            refreshApex(this.opportunity)
        }
    }



    get contractLookup() {
        return !!getFieldValue(this.opportunity.data, CONTRACT_LOOKUP);
    }

    openfileUpload(event) {
        console.log(event.target.files);
        const file = event.target.files[0]
        var reader = new FileReader()
        reader.onload = () => {
            var base64 = reader.result.split(',')[1]
            this.fileData = {
                'filename': file.name,
                'base64': base64,
                'recordId': this.recordId,
            }
            console.log(this.fileData)
            this.show = true;
        }
        reader.readAsDataURL(file)
    }


    handleClick(){
        console.log(this.contractLookup);
        const {base64, filename, recordId} = this.fileData
        let contractLookup = this.contractLookup;
        uploadContract({base64,filename,recordId,contractLookup}).then(response   =>{
                    let title;
                    this.fileData = null
                    if(response.result === 'Error'){
                        this.show = false;
                        this.toast(title,'ERROR')
                    }else{
                        if(response.result === 'SUCCESS') {
                            title = `${filename} uploaded successfully!!`
                            this.toast(title,response.result)
                        }else{
                            title = `${filename} didn't upload`
                            this.toast(title,'ERROR')
                        }
                    }
                })
    }

    toast(title,variant){
        const toastEvent = new ShowToastEvent({
            title,
            variant:variant
        })
        this.dispatchEvent(toastEvent)
    }
}