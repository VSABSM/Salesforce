/**
 * @description This is the controller for the page that allows Users to trigger the Summary process
 * @author Eddie Bates
 * @date 22 January 2018
 * @copyright: Giveclarity.org, 2018
 **/
public with sharing class GcFE_GenerateTransSummariesController {
    public String selectedExportSettings {get; set;}
    public Transaction_Summary_Header__c proxySelectionDetails {get; set;} // Used to capture the date details  
    public String selection1Label {get; set;}
    public String selection2Label {get; set;}
    public Boolean displaySelection1 {get; private set;}
    public Boolean displaySelection2 {get; private set;}
    public List<SelectOption> selection1Options {get; private set;}
    public List<SelectOption> selection2Options {get; private set;}
	
    // Get the selected options
    public List<String> selectedOptions1 {get; set;}
    public List<String> selectedOptions2 {get; set;}
    
    // Get the apex class ID for this batch
    public Id apexClassId {get; set;}
    // Get the scheduled Job name
    public string scheduledJobName {get; set;}

    // Batch status
    final public String NOT_START = 'not_started';
    final public String PROCESSING = 'processing';
    final public String FINISHED = 'finished';    
    public String batchStatus {get;set;}

    // All of the export settings by Id
    private Map<Id, Transaction_Export_Settings__mdt> exportSettingsById;

    public GcFE_GenerateTransSummariesController() {
		scheduledJobName = 'Export to Finance';

        // Create a new proxy object to get selection values
        proxySelectionDetails = new Transaction_Summary_Header__c();
		
        // Determine whether the test settings should be used
        Boolean useTest = Test.isRunningTest() ? true : false;
       // Boolean useTest = false;
        
        // Get a map of the export settings
        exportSettingsById = new Map<Id, Transaction_Export_Settings__mdt>([SELECT Id, MasterLabel, 
                                                                                Selection_1_Ask_User__c, 
                                                                                Selection_2_Ask_User__c, 
                                                                                Selection_1_Default_Value__c, 
                                                                                Selection_2_Default_Value__c,
                                                                                Selection_1_Field_Name__c, 
                                                                                Selection_2_Field_Name__c, 
                                                                                Transaction_Object_Name__c, 
                                                                                DeveloperName
                                                                            FROM Transaction_Export_Settings__mdt 
                                                                            WHERE Is_Test__c=:useTest]);

        // Get the initial global settings and get the name
		Transaction_Export_Settings__mdt selectedExportSettingsObj = exportSettingsById.values()[0];
        this.selectedExportSettings = selectedExportSettingsObj != null ? selectedExportSettingsObj.DeveloperName : null;

        // Get a map of the objects
        Map<String, Schema.SObjectType> gd = Schema.getGlobalDescribe();

        // Get a map of all fields on the 'Contact' object
        Map<String, Schema.SObjectField> fMap = gd.get(selectedExportSettingsObj.Transaction_Object_Name__c).getDescribe().Fields.getMap();		

        // By default switch off the selections
        displaySelection1 = false;
        displaySelection2 = false;

        // Get the label for selection field 1
        selectedOptions1 = new List<String>();
        if (selectedExportSettingsObj.Selection_1_Default_Value__c != null) {selectedOptions1.add(selectedExportSettingsObj.Selection_1_Default_Value__c);}
		if (selectedExportSettingsObj.Selection_1_Ask_User__c == true && selectedExportSettingsObj.Selection_1_Field_Name__c != null) {
            displaySelection1 = true;

            // Get the field describe and label
            Schema.SObjectField fld = fMap.get(selectedExportSettingsObj.Selection_1_Field_Name__c);
            Schema.DescribeFieldResult fldDescribe = fld.getDescribe();         
            selection1Label = fldDescribe.getLabel();

            // Get the selection options
            selection1Options = getSelectionOptions(fldDescribe);
		
		}

        // Get the label for selection field 2
        selectedOptions2 = new List<String>();
        if (selectedExportSettingsObj.Selection_2_Default_Value__c != null) {selectedOptions2.add(selectedExportSettingsObj.Selection_2_Default_Value__c);}        
		if (selectedExportSettingsObj.Selection_2_Ask_User__c == true && selectedExportSettingsObj.Selection_2_Field_Name__c != null) {
			displaySelection2 = true;		

            // Get the field describe and label
			Schema.SObjectField fld = fMap.get(selectedExportSettingsObj.Selection_2_Field_Name__c);
			Schema.DescribeFieldResult fldDescribe = fld.getDescribe();			
			selection2Label = fldDescribe.getLabel();

			// Get the picklist values
            selection2Options = getSelectionOptions(fldDescribe);
		
		}

        // Get the apex ID for the progress bar
        apexClassId = [SELECT Name, Id FROM ApexClass WHERE Name = 'GcFE_TransactionSummaryBatch' LIMIT 1][0].id;

        // Set the initial batch status
        batchStatus = NOT_START;

    }

	// handle the action of the commandlink
    public PageReference pollJobs() {
        System.debug('pollJobs ');
		if (checkBatchAlreadyRunning() == false) {
	    		batchStatus = FINISHED;
		}
        System.debug('batchStatus - ' + batchStatus);
        return null;
    }
    private boolean checkBatchAlreadyRunning() {
    	boolean retVal = false;
		List<AsyncApexJob> apexJobs = [SELECT TotalJobItems, Status, NumberOfErrors, MethodName, JobType, JobItemsProcessed, Id, 
                                CreatedDate, CreatedById, CompletedDate, ApexClassId, ApexClass.Name, ExtendedStatus
                                    FROM AsyncApexJob 
                                    WHERE JobType='BatchApex' AND status not in ('Completed', 'Aborted', 'Failed') AND ApexClassId=:apexClassId];
      	if (apexJobs.size() > 0) {
      		retVal = true;	
      	}                 
      	system.debug('checkBatchAlreadyRunning - ' + retVal);
      	return retVal;                               
    }
    private void checkAlreadyRunning(string name) {
		for ( CronTrigger aJob : [ Select id, State, CronJobDetail.Name 
                              from CronTrigger where State NOT IN ('Aborted','Completed', 'DELETED') AND CronJobDetail.Name =:name] ){
      		System.AbortJob(aJob.Id);
		}                           
    }
    /**
     * @description This starts the process to generate summary records
     * @return null
     **/
    Public PageReference startProcess() {

		//system.debug('proxySelectionDetails.Selection_1__c - ' + proxySelectionDetails.Selection_1__c);
  //      //System.debug('@@@ ')
		////system.debug('proxySelectionDetails.Selection_2__c - ' + proxySelectionDetails.Selection_2__c);
  //      //System.debug('proxySelectionDetails.Selection_1__c size ' + proxySelectionDetails.Selection_1__c)
		//List<string> selection1 = new List<string>();
		//List<string> selection2 = new List<string>();
		//if (string.isBlank(proxySelectionDetails.Selection_1__c) == false ) {
		// 	selection1 = proxySelectionDetails.Selection_1__c.split(',');
		//}		
		//if (string.isBlank(proxySelectionDetails.Selection_2__c) == false ) {
		// 	selection2 = proxySelectionDetails.Selection_2__c.split(',');
		//}	
        //system.debug('@@@ selection1 - ' + selection1 + selection1.size());
//system.debug('@@@ selection1[0] - ' + selection1[0] + selection1.size());
System.debug('@@@ selectedOptions1 ' + selectedOptions1);
		// Create the batch process
        GcFE_TransactionSummaryBatch transSummaryBatch = new GcFE_TransactionSummaryBatch(this.selectedExportSettings, proxySelectionDetails.Start_Date__c, proxySelectionDetails.End_Date__c, selectedOptions1, selectedOptions2);

        // Get the export settings 
        Transaction_Export_Settings__mdt exportSettings = GcFE_TransactionSummaryService.getExportSettings(this.selectedExportSettings);
        Integer batchSize = 200;
        if ((exportSettings != null) && (exportSettings.Summary_Batch_Size__c != 0)){
            batchSize = (Integer)exportSettings.Summary_Batch_Size__c;
        }
            

		if (proxySelectionDetails.Scheduled_Date__c != null) {
			checkAlreadyRunning(scheduledJobName);
			integer runInterval = 0;
			Long dt1Long = DateTime.now().getTime();
			Long dt2Long = proxySelectionDetails.Scheduled_Date__c.getTime();
			Long milliseconds = dt2Long - dt1Long;
			Long seconds = milliseconds / 1000;
			Long minutes = seconds / 60;
			runInterval = Integer.valueOf(minutes);
			System.scheduleBatch (transSummaryBatch, scheduledJobName, runInterval, batchSize);
        }
		else {
			if (checkBatchAlreadyRunning() == false) {
	        	Database.executeBatch(transSummaryBatch, batchSize);    
		    	// Set the batch processing status to processing
        batchStatus = PROCESSING;
			}
			else {
				// Signal error
				ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR,'Batch already running'));			
			}
        }

        // Return null
        return null;
    }

    /**


		
            


    
     * @description This returns a list of options for the type of export
     * @return a list of SelectOption for the type of export
     **/
    public List<SelectOption> getExportTypeOptions() {
        List<SelectOption> options = new List<SelectOption>();

        // Find the export 
        for (Transaction_Export_Settings__mdt exportSetting : exportSettingsById.values()) {
            options.add(new SelectOption(exportSetting.DeveloperName,exportSetting.MasterLabel));   
        }

        return options;
        
    }  

    /**
     * @description This returns true if the process has started and is used to hide input fields
     * @return Boolean Returns true if this has started
     **/
    public Boolean getIsStarted() {
        if (batchStatus != PROCESSING) {
            return false;
        } else {
            return true;
        }
    }
	
	private Schema.DescribeFieldResult extractReference(string relationshipName) {
		DescribeFieldResult retVal;
		try {
			pattern myPattern = pattern.compile('(\\w+)(__r\\.)(\\w+)'); 
			matcher m = myPattern.matcher(relationshipName);
			string objectName;
			string fieldName;
	        while (m.find()) {
				system.debug('m.groupCount() - ' + m.groupCount());
				system.debug('m.group(0) - ' + m.group(0));
				system.debug('m.group(1) - ' + m.group(1));
				system.debug('m.group(2) - ' + m.group(2));
				system.debug('m.group(3) - ' + m.group(3));
				if (m.groupCount() == 3) {
					objectName =  m.group(1);
					fieldName =  m.group(3);
				}
	        }	          		
			system.debug('objectName - ' + objectName);
			system.debug('fieldName - ' + fieldName);
	        if ((string.isBlank(objectName) == false) && (string.isBlank(fieldName) == false)) {
		        Map<String, Schema.SObjectType> gd = Schema.getGlobalDescribe();
	            Map<String, Schema.SObjectField> fMap = gd.get(objectName).getDescribe().Fields.getMap();		
	        	Schema.SObjectField fld = fMap.get(fieldName);
	            Schema.DescribeFieldResult fldDescribe = fld.getDescribe(); 
	            retVal = fldDescribe; 	
	        }
		}
		catch (exception e) {
			system.debug('e - ' + e);
		}        
        return retVal;
	}
    /********************** PRIVATE METHODS ***********************/
    /**
     * @description This returns a list of selected options
     * @return a list of SelectOption options
     **/
    private List<SelectOption> getSelectionOptions(Schema.DescribeFieldResult fldDescribe) {
        List<SelectOption> selectionOptions = new List<SelectOption>();

		system.debug('fldDescribe - ' + fldDescribe);
		system.debug('fldDescribe.getCalculatedFormula() - ' + fldDescribe.getCalculatedFormula());
		if (string.isBlank(fldDescribe.getCalculatedFormula()) == false) {
			string relationshipName = fldDescribe.getCalculatedFormula().trim();
			system.debug('relationshipName - ' + relationshipName);
			Schema.DescribeFieldResult refField = extractReference(relationshipName);
			if (refField != null ) {
				selectionOptions = getSelectionOptions(refField);
			}
			else {
		        selectionOptions.add(new SelectOption('all', 'All'));				
			}
    //        selection1Label = fldDescribe.getLabel();
            // Get the selection options
      //      selection1Options = getSelectionOptions(fldDescribe);			
		}	
		else {	
        // Get the picklist values
        List<Schema.PicklistEntry> ple = fldDescribe.getPicklistValues();
        selectionOptions = new List<SelectOption>();
        selectionOptions.add(new SelectOption('all', 'All'));
        for(Schema.PicklistEntry f : ple) {
				system.debug('f - ' + f);
            selectionOptions.add(new SelectOption(f.getValue(), f.getLabel()));
        }    
		}

		system.debug('selectionOptions - ' + selectionOptions);
        // Return the selection options
        return selectionOptions;

    }


}