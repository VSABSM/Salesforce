/**
 * @description This is the controller for the component that shows a bath progress
 * @see https://developer.salesforce.com/forums/?id=906F00000008wypIAA
 **/
global with sharing class ScheduledJobsController {
     private List<BatchJob> batchJobs;

     // Properties passed into the component
    global Integer numberOfJobs {get; set;} // Number of batch jobs the control will monitor
    global String batchComponentLabel {get; set;} // label to display at the top of the progress meter
    global String scheduledJobName {get; set;} // The name of the scheduled jobs to display
  	public id jobId {get; set;}

    /**
     * @description query for the current batch job progress
     * TODO: Restrict to a class
     **/    
    global List<BatchJob> getscheduledJobs() {
        //Create new list of BatchJobs, a wrapper class that includes the job and percent complete.
        batchJobs = new List<BatchJob>();
 
        //If number of jobs was not defined, default to 20
        if(numberOfJobs== null || numberofJobs <= 0) {
            numberofJobs = 20;
        }
        
        if(batchComponentLabel== null) {
            batchComponentLabel = 'Batch Apex Jobs';
        }
 
 		system.debug('scheduledJobName - ' + scheduledJobName);
 		

        // Get the scheduled jobs to display
        List<CronTrigger> chronJobs= new List<CronTrigger>();

        chronJobs = [Select id, State, CronJobDetail.Name, CronJobDetail.JobType, NextFireTime, CreatedById, PreviousFireTime 
                              from CronTrigger where State NOT IN ('Aborted','Completed','DELETED') AND CronJobDetail.JobType='7' AND CronJobDetail.Name =:scheduledJobName
                                    ORDER BY CreatedDate DESC LIMIT :numberOfJobs];

 		system.debug('chronJobs - ' + chronJobs);
	
        //Query the Batch apex jobs
        for(CronTrigger a : chronJobs) {
 
            BatchJob j = new BatchJob(a);
            //j.job = a;
 
            batchJobs.add(j);
        }
 		
        return batchJobs;

    }

	// handle the action of the commandlink
    public PageReference cancelJob() {
        System.debug('jobId: '+jobId);

		if (jobId != null) {
     		System.AbortJob(jobId); 
			}
        return null;
    }
         
    /**************************** INNER CLASSES **************************/
    /**
     * @description wrapper class includes the job itself and a value for the percent complete
     **/    
    global Class BatchJob{
        global CronTrigger cron;
        global id jobId {get; private set;}
        global String className  {get; private set;}
        global DateTime createdDate  {get; private set;}
        global Id createdById  {get; private set;}
        global String jobStatus  {get; private set;}
        global DateTime completedDate {get; private set;}
 
        global BatchJob(CronTrigger job) {
            this.cron = job;
            this.jobId = job.id;
            this.className = job.CronJobDetail.Name;
            this.createdDate = job.NextFireTime;
            this.createdById = job.CreatedById;
            this.jobStatus = job.State;
            this.completedDate = job.PreviousFireTime; 
        }
               

    }
    
}