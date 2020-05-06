/**
 * @description This is the batch process that is used to generate a header record and summary records
 * @author Eddie Bates
 * @date 22 January 2018
 * @copyright: Giveclarity.org, 2018
 **/
global with sharing class GcFE_TransactionSummaryBatch implements Database.Batchable<sObject>, Database.Stateful {
	global Transaction_Summary_Header__c summaryHeader;
	global String exportName;
	global Gc_LogService logService;
	global String latestError;
	
	String query;

    /**
     * @description Creates the batch and sets the query details
     * @param String the name of the export
     * @param Date the start date of the export
     * @param Date the end date of the export
     * @param List a list of the 1st optional selections
     * @param List a list of the 2nd optional selections
     **/
    global GcFE_TransactionSummaryBatch(String exportName, Date startDate, Date endDate, List<String> settingValues1, List<String> settingValues2) {

		// Set the export name
		this.exportName = exportName;
	
		// Create the summary header
		this.summaryHeader = new Transaction_Summary_Header__c();
		this.summaryHeader.Status__c = 'New';
		this.summaryHeader.Posted_Date__c = null;
		this.summaryHeader.Export_Name__c = exportName;
		this.summaryHeader.Start_Date__c = startDate;
		this.summaryHeader.End_Date__c = endDate;
		//this.summaryHeader.Selection_1__c = String.valueOf(settingValues1);
		//this.summaryHeader.Selection_2__c = String.valueOf(settingValues2);
		this.summaryHeader.Selection_1__c = settingValues1 != null ? String.join(settingValues1,',') : null;
		this.summaryHeader.Selection_2__c = settingValues2 != null ? String.join(settingValues2,',') : null;
		insert this.summaryHeader;
	
		// Create a new log service
		this.logService = Gc_LogService.getInstance('GcFE_TransactionSummaryBatch', this.summaryHeader.Id);
	
		// Get the query
		query = GcFE_TransactionSummaryService.getObjectQuery(exportName, startDate, endDate, settingValues1, settingValues2);
	
		system.debug('query - ' + query);
		
		// Log an info log about the query
		logService.createInfoLog('Summary Creation Query', query, this.summaryHeader.Id);
	}

    private boolean enforceSingleton(Database.BatchableContext BC) {
		boolean retVal = false;
    	ID jobId = BC.getJobId();
    	AsyncApexJob thisJob = [SELECT ApexClassId,CompletedDate,ExtendedStatus,Id,JobItemsProcessed,JobType,MethodName,NumberOfErrors,ParentJobId,Status,TotalJobItems FROM AsyncApexJob where id=:jobId];
    	
    	List<AsyncApexJob> jobs = [SELECT ApexClassId,CompletedDate,ExtendedStatus,Id,JobItemsProcessed,JobType,ApexClass.Name, MethodName,NumberOfErrors,ParentJobId,Status,TotalJobItems FROM AsyncApexJob where ApexClassId=:thisJob.ApexClassId and id <> :jobId  and JobType='BatchApex' and status not in ('Completed', 'Aborted', 'Failed')];
		
		if (jobs.size() > 0) {
			retVal = true;
//			system.abortJob(BC.getJobId()); 
		}
		return retVal;
    }
    
    global Database.QueryLocator start(Database.BatchableContext BC) {

        Database.QueryLocator queryLocator;
	    if (enforceSingleton(BC) == false) {
			queryLocator = Database.getQueryLocator(query);
	    }
        else {
        	queryLocator = Database.getQueryLocator('select ID from Account limit 0');
        }	    
        // Get the records
		return queryLocator;
        
    }

	/**
	 * @description This creates/refreshes the summary records for the process
	 **/
   	global void execute(Database.BatchableContext BC, List<sObject> scope) {

   		try {
			// Get the settings
			Transaction_Export_Settings__mdt exportSettings = GcFE_TransactionSummaryService.getExportSettings(this.exportName);

		    ETFBatchableHelper.ETFBatchPreExecute(exportSettings);
		
	   		// Call the process to create the summary records from the found objects
			GcFE_TransactionSummaryService.createUpdateSummaries(this.exportName, this.summaryHeader.Id, scope, logService);

   		} catch (Exception e) {
			latestError = e.getMessage();
			throw e;
   		}

	}
	
 
	/** 
	 * @description This determines whether the process should be rolled back at the end and where an email should be sent
	 **/
	global void finish(Database.BatchableContext BC) {
		
		Transaction_Export_Settings__mdt exportSettings = GcFE_TransactionSummaryService.getExportSettings(this.exportName);

		// Change the status
	    ETFBatchableHelper.ETFBatchPreFinish(exportSettings);


        // Write out the log records
        logService.saveLogs();  

		// Get details of the batch process and write these to the summary header
   		AsyncApexJob batchJob = [SELECT Id, Status, NumberOfErrors, JobItemsProcessed, TotalJobItems, CreatedBy.Email
   									FROM AsyncApexJob 
   									WHERE Id =:BC.getJobId()];

   		// Update the summary header
   		this.summaryHeader.Number_of_Batch_Errors__c = batchJob.NumberOfErrors;
   		this.summaryHeader.Total_Batch_Count__c = batchJob.TotalJobItems;
   		this.summaryHeader.Last_Batch_Error__c = this.latestError;
   		update this.summaryHeader;

    }

    
}