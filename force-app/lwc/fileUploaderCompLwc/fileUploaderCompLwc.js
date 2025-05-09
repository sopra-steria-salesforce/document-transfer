import {LightningElement, api, wire, track} from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { getRecord, getFieldValue } from "lightning/uiRecordApi";
import CONTRACT_LOOKUP from "@salesforce/schema/Opportunity.Contract_Lookup__c";
import CONNECTED_TO_EXISTING_CONTRACT from "@salesforce/schema/Opportunity.ConnectedToExistingContract__c";
import uploadContract from '@salesforce/apex/ServiceNowUploadContracts.uploadContracts'
import {refreshApex} from "@salesforce/apex";
import {getLogger} from 'c/logger';
const FIELDS = [CONTRACT_LOOKUP,CONNECTED_TO_EXISTING_CONTRACT];

export default class FileUploaderCompLwc extends LightningElement {
    logger = getLogger();
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
        this.logger.info('validateUpload', this.validateUpload);
        this.logger.saveLog();
    }


    @wire(getRecord, { recordId: '$recordId', fields: '$fields' })
    fetchOpp(response) {
        if(response) {
            this.logger.info('fetchOpp',response);
            this.opportunity = response;
            this.getValidateUpload
            refreshApex(this.opportunity)
            this.logger.info('opportunity',this.opportunity.data);
            this.logger.saveLog();
        }
    }



    get contractLookup() {
        return !!getFieldValue(this.opportunity.data, CONTRACT_LOOKUP);
    }

    openfileUpload(event) {
        console.log(event.target.files);
        this.logger.info('target files', event.target.files);
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
            this.logger.info('fileData', this.fileData);
            this.logger.saveLog();
            this.show = true;
        }
        reader.readAsDataURL(file)
    }


    handleClick(){
        console.log(this.contractLookup);
        this.logger.info('handleClick', this.contractLookup)
        const {base64, filename, recordId} = this.fileData
        let contractLookup = this.contractLookup;
        uploadContract({base64,filename,recordId,contractLookup}).then(response   =>{
                    let title;
                    this.fileData = null
                    if(response.result === 'Error'){
                        title = `${filename} didn't upload`
                        this.logger.error('Error uploading file', response.result);
                        this.show = false;
                        this.toast(title,'ERROR')
                    }else{
                        if(response.result === 'SUCCESS') {
                            title = `${filename} uploaded successfully!!`
                            this.logger.info('handleClick', response.result);
                            this.toast(title,response.result)
                        }else{
                            title = `${filename} didn't upload`
                            this.logger.error('Error uploading file', response.result);
                            this.toast(title,'ERROR')
                        }
                    }
                })
        this.logger.saveLog();
    }

    toast(title,variant){
        const toastEvent = new ShowToastEvent({
            title,
            variant:variant
        })
        this.logger.debug('toastEvent', toastEvent);
        this.logger.saveLog();
        this.dispatchEvent(toastEvent)
    }
}