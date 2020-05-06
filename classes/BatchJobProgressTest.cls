/**
 * @description Tests for the batch job progress controller. 
 * These are pretty weak tests, but the component is not critical and testing multiple batch progresses is not possible
 * @author Eddie Bates
 * @date 22 January 2018
 * @copyright: Giveclarity.org, 2018 
 **/
@isTest
private class BatchJobProgressTest {

	// Constants
	private static final String TEST_SETTING_NAME = 'Test_Opportunity_Amount_Export';
		
	static {}

	private static void init() {}

	/**
	 * @description This tests when there is no batch process supplied
	 **/
	static testMethod void testNoClassIDSupplied() {

		// Create the batch a batch and execute
		GcFE_TransactionSummaryBatch transSummaryBatch = new GcFE_TransactionSummaryBatch(TEST_SETTING_NAME, Date.newInstance(2017, 2, 21), Date.newInstance(2017, 2, 23), null, null);

		// Execute the batch
		Database.executeBatch(transSummaryBatch);

		// Start the test
		Test.startTest();

		// Create the class and set values
		BatchJobsProgressController batchJobsController = new BatchJobsProgressController();
		List<BatchJobsProgressController.BatchJob> batchJobs = batchJobsController.getBatchJobs();

		// Stop the test
		Test.stopTest();

		// Test that there is one batch process
		System.assertEquals(1, batchJobs.size(), batchJobs);
		System.assertEquals('Queued', batchJobs[0].job.Status);
		System.assertEquals(0, batchJobs[0].percentComplete);

	}

	/**
	 * @description This tests when there is a class ID supplied
	 **/
	static testMethod void testClassIDSupplied() {

		// Create the batch a batch and execute
		GcFE_TransactionSummaryBatch transSummaryBatch = new GcFE_TransactionSummaryBatch(TEST_SETTING_NAME, Date.newInstance(2017, 2, 21), Date.newInstance(2017, 2, 23), null, null);

		// Start the test
		Test.startTest();

		// Execute the batch and it should complete
		Database.executeBatch(transSummaryBatch);

		// Stop the test
		Test.stopTest();

		// Get the ID
        Id apexClassId = [SELECT Name, Id FROM ApexClass WHERE Name = 'GcFE_TransactionSummaryBatch' LIMIT 1][0].id;

		// Create the class and set values
		BatchJobsProgressController batchJobsController = new BatchJobsProgressController();
		batchJobsController.apexClassId = apexClassId;
		List<BatchJobsProgressController.BatchJob> batchJobs = batchJobsController.getBatchJobs();

		// Test that there is one batch process
		System.assertEquals(1, batchJobs.size(), batchJobs);
		System.assertEquals('Completed', batchJobs[0].job.Status);
		System.assertEquals(100, batchJobs[0].percentComplete);		

	}

	
}