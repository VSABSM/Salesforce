/**
 * @description Given a Summary Header ID this gets all the Summary records, 
 * resets the linked Transactions then removes the Summary records
 * @author Eddie Bates
 * @date 22 January 2018
 * @copyright: Giveclarity.org, 2018
 **/
global with sharing class GcFE_TransactionSummaryRollbackBatch implements Database.Batchable<sObject> {
	public Id headerId;
	public String query;
	public Integer errorCount;
	global Gc_LogService logService;	
	
	/**
	 * @description Given a Header ID this gets all the Transaction Summaries
	 * @param Id Summary Header Id
	 **/
	global GcFE_TransactionSummaryRollbackBatch(Id summaryHeaderId) {
		this.headerId = summaryHeaderId;

		// Set the error count to zero
		this.errorCount = 0;

		// Build up he query
//		query = 'SELECT Id FROM Transaction_Summary__c WHERE Transaction_Summary_Header__c=:headerId';

		query = GcFE_TransactionSummaryService.getRollbackTransactionQuery(summaryHeaderId);
		// Create a new Log Service
		this.logService = Gc_LogService.getInstance('GcFE_TransactionSummaryRollbackBatch', this.headerId);		

	}
	
	global Database.QueryLocator start(Database.BatchableContext BC) {
		return Database.getQueryLocator(query);
	}

    /**
	 * @description Call the process to create the Summary records
	 **/
   	global void execute(Database.BatchableContext BC, List<sObject> scope) {
		// Get the Summary Header object along with the export setting
		Transaction_Summary_Header__c summaryHeader = [SELECT Id, Status__c, Export_Name__c FROM Transaction_Summary_Header__c WHERE Id=:headerId];
   		
   		// Call the process to create the Summary records from the found objects
		GcFE_TransactionSummaryService.rollbackTransactionSummaries(scope, summaryHeader, logService);
	
	}
	
    /**
	 * @description Update the Status of the Transaction Summary Header to 'Rolled Back'
	 **/
	global void finish(Database.BatchableContext BC) {

		// Change the status of the Header record to 'Rolled Back'
		Transaction_Summary_Header__c summaryHeader = [SELECT Id, Status__c FROM Transaction_Summary_Header__c WHERE Id=:headerId];
		summaryHeader.Status__c = 'Rolled Back';
		update summaryHeader;
		
		List<sObject> transactionSummaryObjs = [SELECT Id FROM Transaction_Summary__c WHERE Transaction_Summary_Header__c=:headerId];
		delete transactionSummaryObjs;
	}
	
}