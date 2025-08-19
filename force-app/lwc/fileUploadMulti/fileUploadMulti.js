import {LightningElement, api, track, wire} from 'lwc';
import {getFieldValue, getRecord, getRecordNotifyChange, notifyRecordUpdateAvailable} from "lightning/uiRecordApi";
import CONTRACT_CATEGORY from "@salesforce/schema/Opportunity.Contract_Category__c";
import CONTRACT_SERVICE_NOW_URL from '@salesforce/schema/Opportunity.ContractServiceNowUrl__c';
import IS_CONTRACT_UPLOADED from '@salesforce/schema/Opportunity.IsContractUploaded__c';
import NAVISION_SE from '@salesforce/schema/Opportunity.Navision_Customer_SE__c';
import NAVISION_NO from '@salesforce/schema/Opportunity.Navision_Customer_NO__c';
import NAVISION_DK from '@salesforce/schema/Opportunity.Navision_Customer_DK__c';
import NAVISION_ACCOUNT from '@salesforce/schema/Opportunity.Navision_Account_in_Owners_Country__c';
import OPPORTUNITY_OWNER_COUNTRY from '@salesforce/schema/Opportunity.Owner_Country__c';
import STAGE_NAME from '@salesforce/schema/Opportunity.StageName';
import {onError, subscribe, unsubscribe} from "lightning/empApi";
import { RefreshEvent } from 'lightning/refresh';
import {refreshApex} from "@salesforce/apex";
import doesOpportunityCountryMatchNavisionCountry from '@salesforce/apex/FileUploadMultiController.doesOpportunityCountryMatchNavisionCountry';
const FIELDS = [IS_CONTRACT_UPLOADED,CONTRACT_SERVICE_NOW_URL,CONTRACT_CATEGORY,STAGE_NAME,NAVISION_SE,NAVISION_DK,NAVISION_NO,OPPORTUNITY_OWNER_COUNTRY,NAVISION_ACCOUNT];

export default class fileUploadMulti extends LightningElement {
    fields = FIELDS;
    @api recordId;
    @track filesData = [];
    showSpinner = false;
    @track showConditionalSection = false;
    @track contractServiceNowUrl = false;
    @track validateUpload
    @track showContent = false;
    channelName = '/event/Refresh_Custom_Components__e';
    @track navisionCheck = false;
    subscription = {}; // holds subscription, used for unsubscribe
    connectedCallback() {
        //  this.showSpinner = true;
        const self = this;
        const callbackFunction = function(response) {
            console.log('callbackFunction', response);
        }
        subscribe(this.channelName, -1, callbackFunction).then(response => {
            console.log('Subscribed to change events', response);
        });
        self.refreshMyData();
        if(this.opportunity.data){
            this.showConditionalSection = this.opportunity.data.fields.StageName.value === '5 - Awarded' && (this.opportunity.data.fields.ContractServiceNowUrl__c.value === null || this.opportunity.data.fields.ContractServiceNowUrl__c.value === undefined || this.opportunity.data.fields.ContractServiceNowUrl__c.value === '');
            doesOpportunityCountryMatchNavisionCountry({opportunity: this.opportunity})
                .then(result => { this.navisionCheck = result;})
        }
        refreshApex(this.opportunity).then(() => {
        });
    }
    refreshMyData() {
        refreshApex(this.opportunity).then(() => {
            if(this.opportunity.data){
                this.showConditionalSection = this.opportunity.data.fields.StageName.value === '5 - Awarded' && (this.opportunity.data.fields.ContractServiceNowUrl__c.value === null || this.opportunity.data.fields.ContractServiceNowUrl__c.value === undefined || this.opportunity.data.fields.ContractServiceNowUrl__c.value === '');
                console.log('this.showConditionalSection');
                console.log(this.showConditionalSection);
            }
        });
    }
    @wire(getRecord, { recordId: '$recordId', fields: '$fields' })
    opportunity(result) {
        this.opportunity = result;
        if (result.data) {
            this.showConditionalSection = result.data.fields.StageName.value === '5 - Awarded' &&
                (result.data.fields.ContractServiceNowUrl__c.value === null ||
                    result.data.fields.ContractServiceNowUrl__c.value === undefined ||
                    result.data.fields.ContractServiceNowUrl__c.value === '');
            this.contractServiceNowUrl = result.data.fields.ContractServiceNowUrl__c.value;
            console.log('Wire Opportunity');
            doesOpportunityCountryMatchNavisionCountry({opportunity: this.opportunity})
                .then(result => { this.navisionCheck = result;})
                console.log('this.navisionCheck')
                console.log(this.navisionCheck)
            }
    }
    refresh(){
        refreshApex(this.opportunity).then(() => {
            console.log('refreshApex done');
        });
    }
    get showConditionalSection() {
        console.log(this.opportunity.data);
        if (this.opportunity.data) {
            return this.opportunity.data.fields.StageName.value === '5 - Awarded' && (this.opportunity.data.fields.ContractServiceNowUrl__c.value === null || this.opportunity.data.fields.ContractServiceNowUrl__c.value === undefined || this.opportunity.data.fields.ContractServiceNowUrl__c.value === '');
        }
        return false;
    }
    get contractServiceNowUrl() {
        return !!getFieldValue(this.opportunity.data, CONTRACT_SERVICE_NOW_URL);
    }
    get isContractUploaded() {
        return getFieldValue(this.opportunity.data, IS_CONTRACT_UPLOADED);
    }
    get stageName() {
        return getFieldValue(this.opportunity.data, STAGE_NAME);
    }
    get contractCategory() {
        return getFieldValue(this.opportunity.data, CONTRACT_CATEGORY);
    }
    handleClick(){
        window.open(this.opportunity.data.fields.ContractServiceNowUrl__c.value , '_blank');
    }
    handleRefresh(){
        window.location.reload();
    }
}