import { LightningElement, api } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { CloseActionScreenEvent } from 'lightning/actions';
import uploadContractToServiceNow from '@salesforce/apex/ServiceNowUploadContractsController.uploadContractToServiceNow';
import { subscribe, unsubscribe, onError } from 'lightning/empApi';
import {getLogger} from 'c/logger';

export default class ServiceNowUploadContractsQA extends LightningElement {
    logger = getLogger();
    @api recordId; // The Opportunity Id
    isLoading = false;
    channelName = '/event/Refresh_Custom_Components__e';
    subscription = null;

    connectedCallback() {
        // Subscribe to the event channel
        this.subscribeToChannel();
    }

    disconnectedCallback() {
        // Unsubscribe from the event channel
        // Unsubscribe from the event channel
        this.unsubscribeFromChannel();
    }

    // Subscribe to the event channel
    subscribeToChannel() {
        // Callback for when a message is received
        const messageCallback = (response) => {
            // Handle the event
            this.handleRefreshEvent(response);
        };

        // Subscribe to the channel and save the returned subscription object
        subscribe(this.channelName, -1, messageCallback)
            .then(response => {
                this.subscription = response;
                this.logger.info('OUTPUT: ', response);
            })
            .catch(error => {
                this.logger.error('Error subscribing to channel', error);
                console.error('Error subscribing to channel: ', error);
            });

        // Register error listener
        onError(error => {
            this.logger.error('Error from empApi', error);
            this.logger.saveLog();
            console.error('Error received from empApi: ', error);
        });
    }

    // Unsubscribe from the channel
    unsubscribeFromChannel() {
        if (this.subscription) {
            this.logger.info('Unsubscribing from channel', this.subscription);
            unsubscribe(this.subscription)
                .then(() => {
                    this.subscription = null;
                })
                .catch(error => {

                    this.logger.error('Error unsubscribing from channel', error);
                    this.logger.saveLog();
                    console.error('Error unsubscribing: ', error);
                });
        }
    }

    // Handle the refresh event
    handleRefreshEvent(response) {
        // When we receive the event, stop the loading spinner
        this.isLoading = false;
        
        // Close the quick action modal
        this.closeQuickAction();
    }

    // Handle the cancel button click
    handleCancel() {
        this.closeQuickAction();
    }

    // Close the quick action modal
    closeQuickAction() {
        this.dispatchEvent(new CloseActionScreenEvent());
    }

    // Handle the button click
    handleUploadClick() {
        this.isLoading = true;
        
        uploadContractToServiceNow({ opportunityId: this.recordId })
            .then(result => {
                if (result.success) {
                    this.showToast('Success', result.message, 'success');
                    this.logger.info('Upload successful', result.success);
                    // Note: We don't set isLoading to false here because we'll wait for the event
                } else {
                    this.showToast('Error', result.message, 'error');
                    this.logger.error('Upload failed', result.message);
                    this.isLoading = false;
                    // If there was an error, close the modal
                    this.closeQuickAction();
                }
            })
            .catch(error => {
                this.showToast('Error', 'An error occurred: ' + this.reduceErrors(error), 'error');
                this.logger.error('Error occurred', error);
                this.logger.saveLog();
                this.isLoading = false;
                // If there was an error, close the modal
                this.closeQuickAction();
            });
    }

    // Helper method to show toast messages
    showToast(title, message, variant) {
        this.dispatchEvent(
            new ShowToastEvent({
                title: title,
                message: message,
                variant: variant
            })
        );
    }

    // Helper method to reduce errors to a string
    reduceErrors(errors) {
        if (!Array.isArray(errors)) {
            errors = [errors];
        }
        
        return errors
            .filter(error => !!error)
            .map(error => {
                if (typeof error === 'string') {
                    return error;
                } else if (error.body && typeof error.body.message === 'string') {
                    return error.body.message;
                } else if (error.message) {
                    return error.message;
                } else {
                    return JSON.stringify(error);
                }
            })
            .join(', ');
    }
}