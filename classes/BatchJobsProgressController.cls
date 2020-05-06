/**
 * @description This is the controller for the component that shows a batch progress
 * @author Eddie Bates
 * @date 22 January 2018
 * @copyright: Giveclarity.org, 2018 
 **/
global with sharing class BatchJobsProgressController {
     private List<BatchJob> batchJobs;

     // Properties passed into the component
    global Integer numberOfJobs {get; set;} // Number of batch jobs the control will monitor
    global String batchComponentLabel {get; set;} // label to display at the top of the progress meter
    global String apexClassId {get; set;} // The id of the apex class to display
 
	/**
     * @description query for the current batch job progress
     * TODO: Restrict to a class
	 **/ 	
    global List<BatchJob> getBatchJobs() {
        //Create new list of BatchJobs, a wrapper class that includes the job and percent complete.
        batchJobs = new List<BatchJob>();
 
        //If number of jobs was not defined, default to 20
        if(numberOfJobs== null || numberofJobs <= 0) {
            numberofJobs = 20;
        }
        
        if(batchComponentLabel== null) {
            batchComponentLabel = 'Batch Apex Jobs';
        }
 
        // Get the apex jobs to display
        List<AsyncApexJob> apexJobs;
        if (apexClassId == null) {
        	apexJobs = [SELECT TotalJobItems, Status, NumberOfErrors, MethodName, JobType, JobItemsProcessed, Id, 
        						CreatedDate, CreatedById, CompletedDate, ApexClassId, ApexClass.Name, ExtendedStatus
        							FROM AsyncApexJob 
        							WHERE JobType='BatchApex' 
        							ORDER BY CreatedDate DESC LIMIT :numberOfJobs];
        } else {
        	apexJobs = [SELECT TotalJobItems, Status, NumberOfErrors, MethodName, JobType, JobItemsProcessed, Id, 
        						CreatedDate, CreatedById, CompletedDate, ApexClassId, ApexClass.Name, ExtendedStatus
        							FROM AsyncApexJob 
        							WHERE JobType='BatchApex' AND ApexClassId=:apexClassId 
        							ORDER BY CreatedDate DESC LIMIT :numberOfJobs];
        }

        //Query the Batch apex jobs
        for(AsyncApexJob a : apexJobs) {
            Double itemsProcessed = a.JobItemsProcessed;
            Double totalItems = a.TotalJobItems;
 
            BatchJob j = new BatchJob(a);
            //j.job = a;
 
            //Determine the percent complete based on the number of batches complete
            if(a.status == 'Completed') {
            	j.percentComplete = 100;
            //Determine the percent complete based on the number of batches complete
            } else if (totalItems == 0) {
                //A little check here as we don't want to divide by 0.
                j.percentComplete = 0;
            } else {
                j.percentComplete = ((itemsProcessed  / totalItems) * 100.0).intValue();
            }
 
            batchJobs.add(j);
        }
        return batchJobs;

    }
 
    /**************************** INNER CLASSES **************************/
	/**
     * @description wrapper class includes the job itself and a value for the percent complete
	 **/ 	
    global Class BatchJob{
        global AsyncApexJob job;
        global Integer percentComplete {get; set;}
        global String className  {get; private set;}
        global DateTime createdDate  {get; private set;}
        global Id createdById  {get; private set;}
        global String jobStatus  {get; private set;}
        global Integer totalJobItems  {get; private set;}
        global Integer jobItemsProcessed  {get; private set;}
        global Integer numberOfErrors  {get; private set;}
        global String extendedStatus  {get; private set;}
        global DateTime completedDate {get; private set;}
        BatchJob(AsyncApexJob job) {
            this.job = job;
            this.className = job.ApexClass.Name;
            this.createdDate = job.CreatedDate;
            this.createdById = job.CreatedById;
            this.jobStatus = job.Status;
            this.totalJobItems = job.TotalJobItems;
            this.jobItemsProcessed = job.JobItemsProcessed;
            this.numberOfErrors = job.NumberOfErrors;
            this.extendedStatus = job.ExtendedStatus;    
            this.completedDate = job.completedDate; 
        }
    }
    
}