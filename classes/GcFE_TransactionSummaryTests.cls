/**
 * @description This covers unit tests for the Transaction Summary service and related code
 * @author Eddie Bates
 * @date 22 January 2018
 * @copyright: Giveclarity.org, 2018
 **/
@isTest
private class GcFE_TransactionSummaryTests {
	private static List<Opportunity> testOpportunities;
	private static Set<Id> testOpportunityIds;
    private static Id contactId;
    private static Id contactId2;

	// Constants
	private static final String TEST_SETTING_NAME = 'Test_Opportunity_Amount_Export';
	
    //static{
        // Create custom settings to allow triggers to run
    //    Process_Control__c pcSettings = Process_Control__c.getInstance();
    //    pcSettings.Recurring_Donation_Trigger__c=true;
    //    pcSettings.Account_Trigger__c =true;
    //    pcSettings.Opportunity_Validation__c = false;
    //    upsert pcSettings;
    //}

	/** 
	 * @description Create test data for the Unit Tests
	 **/
	private static void init() {

		// Create an Account that Donations can be linked to
		Account testAccount = TestFactory.createAccount('Test Account');
		insert testAccount;

        //Create Contact
         Contact con = new Contact (firstname = 'john', lastname = 'test', AccountId = testAccount.id, Email = 'test@test.com');
    	 Insert con;
        contactId = con.Id;
        
		// Create a Campaign that Opportunities can be linked to
		Campaign testCampaign = TestFactory.createCampaign();
		insert testCampaign;

		// Create a batch of Opportunities
		testOpportunities = new List<Opportunity>();

		// First group of Opportunities
		testOpportunities.add(createOpportunity(testCampaign, Date.newInstance(2017, 2, 15), testAccount.Id, 'Paid', '2017~2~15~FIN0001', 'FIN0001', 23));
		testOpportunities.add(createOpportunity(testCampaign, Date.newInstance(2017, 2, 15), testAccount.Id, 'Paid', '2017~2~15~FIN0001', 'FIN0001', 11));
		testOpportunities.add(createOpportunity(testCampaign, Date.newInstance(2017, 2, 15), testAccount.Id, 'Paid', '2017~2~15~FIN0001', 'FIN0001', 12));

		// Second group of Opportunities
		testOpportunities.add(createOpportunity(testCampaign, Date.newInstance(2017, 2, 21), testAccount.Id, 'Paid', '2017~2~21~FIN0002', 'FIN0002', 14));
		testOpportunities.add(createOpportunity(testCampaign, Date.newInstance(2017, 2, 21), testAccount.Id, 'Paid', '2017~2~21~FIN0002', 'FIN0002', 12));

		// Third group of Opportunities
		testOpportunities.add(createOpportunity(testCampaign, Date.newInstance(2017, 2, 22), testAccount.Id, 'Paid', '2017~2~22~FIN0003', 'FIN0003', 99));
		testOpportunities.add(createOpportunity(testCampaign, Date.newInstance(2017, 2, 22), testAccount.Id, 'Paid', '2017~2~22~FIN0003', 'FIN0003', 100));

		// Insert the Opportunities
		insert testOpportunities;

		// Get the Opportunity IDs
		testOpportunityIds = new Set<Id>();
		for (Opportunity opp : testOpportunities) {
			testOpportunityIds.add(opp.Id);
		}

	}

	/**
	 * @description Given a number of Transaction objects, this tests that Summary objects are created
	 **/
	static testMethod void testSummaryCreation() {

		// Create Opportunities for testing
		init();

		// Create a Transaction Summary Header
		Transaction_Summary_Header__c transSummaryHeader = createSummaryHeader('New',Date.newInstance(2017, 1, 1),TEST_SETTING_NAME);
		insert transSummaryHeader;

		// Create one Transaction Summary that should be updated
		List<Transaction_Summary__c> transSummaries = new List<Transaction_Summary__c>();
		transSummaries.add(createSummary(transSummaryHeader.id, '2017~2~15~FIN0001', 1000, 'FIN0001', Date.newInstance(2017, 2, 15),null,null));
		insert transSummaries;

		// Get the Transaction settings
		Transaction_Export_Settings__mdt transactionSetting = getTransactionSummarySettings(TEST_SETTING_NAME);

		// Start the testing
		Test.startTest();

		// Create the Summaries from the Opportunities
		Gc_LogService logService = Gc_LogService.getInstance('GcFE_TransactionSummaryBatch', transSummaryHeader.Id);
		GcFE_TransactionSummaryService.CreateUpdateSummaries(TEST_SETTING_NAME, transSummaryHeader.Id, testOpportunities, logService);

		logService = Gc_LogService.getInstance();
		
		logService.createErrorLog('errorType', 'fullMessage', null, 'stackTrace');
		logService.saveLogs();
		
		ETFBatchableHelper etf = new ETFBatchableHelper();
		
		// Stop the testing
		Test.stopTest();

		// Get the Transaction Summary records and check them
		List<Transaction_Summary__c> updatedTransSummaries = [SELECT Id, Transaction_Summary_Header__c, 
                                                              Group_ID__c, 
                                                              Total_Amount__c, 
                                                              Finance_Code__c, 
                                                              Banking_Date__c 
                                                              FROM Transaction_Summary__c];
		System.assertEquals(3, updatedTransSummaries.size());
		Map<String, Transaction_Summary__c> transSummariesByGroupId = new Map<String, Transaction_Summary__c>();
		for (Transaction_Summary__c transSummary : updatedTransSummaries) {
			// Add to the map for use later
			transSummariesByGroupId.put(transSummary.Group_ID__c, transSummary);

			// Check the Amounts and Fields
			if (transSummary.Group_ID__c == '2017~2~15~FIN0001') {
				System.assertEquals(1046.00,transSummary.Total_Amount__c);
				System.assertEquals('FIN0001',transSummary.Finance_Code__c);
			} else if (transSummary.Group_ID__c == '2017~2~21~FIN0002') {
				System.assertEquals(26,transSummary.Total_Amount__c);
				System.assertEquals('FIN0002',transSummary.Finance_Code__c);
			} else if (transSummary.Group_ID__c == '2017~2~22~FIN0003') {
				System.assertEquals(199,transSummary.Total_Amount__c);
				System.assertEquals('FIN0003',transSummary.Finance_Code__c);
			} else {
				System.assert(false, 'This group ID is not valid : ' + transSummary);
			}					

		}

		// Get the Opportunities and test that they have been updated
		List<Opportunity> updatedOpportunities = [SELECT Id, Posted_Finance_Code__c, 
                                                  Transaction_Summary__c, 
                                                  NextStep, 
                                                  npsp__Grant_Contract_Number__c 
                                                  FROM Opportunity 
                                                  WHERE Id IN:testOpportunityIds];
		System.assertEquals(7, updatedOpportunities.size());
		for (Opportunity opp : updatedOpportunities) {
			System.assertEquals(opp.NextStep, opp.Posted_Finance_Code__c);
			System.assertEquals(transSummariesByGroupId.get(opp.npsp__Grant_Contract_Number__c).Id, opp.Transaction_Summary__c);
		}

	}

	/**
	 * @description Given a number of Transaction objects, this tests that Summary objects are created
	 *
	static testMethod void testSummaryCreation_controller() {

		// Create Opportunities for testing
		init();

		// Create a Transaction Summary Header
		Transaction_Summary_Header__c transSummaryHeader = createSummaryHeader('New',Date.newInstance(2017, 1, 1),TEST_SETTING_NAME);
		insert transSummaryHeader;

		// Create one Transaction Summary that should be updated
		List<Transaction_Summary__c> transSummaries = new List<Transaction_Summary__c>();
		transSummaries.add(createSummary(transSummaryHeader.id, '2017~2~15~FIN0001', 1000, 'FIN0001', Date.newInstance(2017, 2, 15),null,null));
		insert transSummaries;

		// Get the Transaction settings
		Transaction_Export_Settings__mdt transactionSetting = getTransactionSummarySettings(TEST_SETTING_NAME);

		// Start the testing
		Test.startTest();

		// Create the Summaries from the Opportunities
		Gc_LogService logService = Gc_LogService.getInstance('GcFE_TransactionSummaryBatch', transSummaryHeader.Id);
		GcFE_TransactionSummaryService.CreateUpdateSummaries(TEST_SETTING_NAME, transSummaryHeader.Id, testOpportunities, logService);
		
		GcFE_GenerateTransSummariesController cntrl = new GcFE_GenerateTransSummariesController();
		cntrl.selectedExportSettings = transactionSetting;
		
		// Stop the testing
		Test.stopTest();

		// Get the Transaction Summary records and check them
		List<Transaction_Summary__c> updatedTransSummaries = [SELECT Id, Transaction_Summary_Header__c, 
                                                              Group_ID__c, 
                                                              Total_Amount__c, 
                                                              Finance_Code__c, 
                                                              Banking_Date__c 
                                                              FROM Transaction_Summary__c];
		System.assertEquals(3, updatedTransSummaries.size());
		Map<String, Transaction_Summary__c> transSummariesByGroupId = new Map<String, Transaction_Summary__c>();
		for (Transaction_Summary__c transSummary : updatedTransSummaries) {
			// Add to the map for use later
			transSummariesByGroupId.put(transSummary.Group_ID__c, transSummary);

			// Check the Amounts and Fields
			if (transSummary.Group_ID__c == '2017~2~15~FIN0001') {
				System.assertEquals(1046.00,transSummary.Total_Amount__c);
				System.assertEquals('FIN0001',transSummary.Finance_Code__c);
			} else if (transSummary.Group_ID__c == '2017~2~21~FIN0002') {
				System.assertEquals(26,transSummary.Total_Amount__c);
				System.assertEquals('FIN0002',transSummary.Finance_Code__c);
			} else if (transSummary.Group_ID__c == '2017~2~22~FIN0003') {
				System.assertEquals(199,transSummary.Total_Amount__c);
				System.assertEquals('FIN0003',transSummary.Finance_Code__c);
			} else {
				System.assert(false, 'This group ID is not valid : ' + transSummary);
			}					

		}

		// Get the Opportunities and test that they have been updated
		List<Opportunity> updatedOpportunities = [SELECT Id, Posted_Finance_Code__c, 
                                                  Transaction_Summary__c, 
                                                  NextStep, 
                                                  npsp__Grant_Contract_Number__c 
                                                  FROM Opportunity 
                                                  WHERE Id IN:testOpportunityIds];
		System.assertEquals(7, updatedOpportunities.size());
		for (Opportunity opp : updatedOpportunities) {
			System.assertEquals(opp.NextStep, opp.Posted_Finance_Code__c);
			System.assertEquals(transSummariesByGroupId.get(opp.npsp__Grant_Contract_Number__c).Id, opp.Transaction_Summary__c);
		}

	} */
	
	/**
	 * @description Test that a batch process finds Opportunities and creates the summary and summary header records
	 **/
	static testMethod void testBatchCreate() {

		// Create Opportunities for testing
		init();

		// Start the test
		Test.startTest();

		// Create the Batch process
		GcFE_TransactionSummaryBatch transSummaryBatch = new GcFE_TransactionSummaryBatch(TEST_SETTING_NAME, Date.newInstance(2017, 2, 21), Date.newInstance(2017, 2, 23), null, null);

		// Execute the Batch
		Database.executeBatch(transSummaryBatch);

		// Stop the test
		Test.stopTest();

		// Check that a Header record has been created
		List<Transaction_Summary_Header__c> transHeaders = [SELECT Id, Status__c, Export_Name__c FROM Transaction_Summary_Header__c WHERE Export_Name__c=:TEST_SETTING_NAME];
		System.assertEquals(1, transHeaders.size());

		// Get the Header ID
		Id transHeaderId = transHeaders[0].Id;

		// Check that a couple of Summaries have been created
		List<Transaction_Summary__c> transSummaries = [SELECT Id, Transaction_Summary_Header__c, 
                                                       Total_Amount__c, 
                                                       Group_ID__c, 
                                                       Finance_Code__c, 
                                                       Banking_Date__c 
															FROM Transaction_Summary__c
															WHERE Transaction_Summary_Header__c=:transHeaderId];
		System.assertEquals(2, transSummaries.size());

		// Test the group IDs and Amounts
		for (Transaction_Summary__c transSummary : transSummaries) {
			if (transSummary.Group_ID__c == '2017~2~21~FIN0002') {
				System.assertEquals(26,transSummary.Total_Amount__c);
				System.assertEquals('FIN0002',transSummary.Finance_Code__c);
			} else if (transSummary.Group_ID__c == '2017~2~22~FIN0003') {
				System.assertEquals(199,transSummary.Total_Amount__c);
				System.assertEquals('FIN0003',transSummary.Finance_Code__c);
			} else {
				System.assert(false, 'This group ID is not valid : ' + transSummary);
			}					

		}

	}

	/**
	 * @description Test that a batch process finds Opportunities and creates the summary and summary header records
	 **/
	static testMethod void testBatchCreate_controller() {

		// Create Opportunities for testing
		init();

		// Start the test
		Test.startTest();

		GcFE_GenerateTransSummariesController cntrl = new GcFE_GenerateTransSummariesController();
		cntrl.selectedExportSettings = TEST_SETTING_NAME;

		cntrl.proxySelectionDetails = new Transaction_Summary_Header__c ();
		cntrl.proxySelectionDetails.Start_Date__c = Date.newInstance(2017, 2, 21);
		cntrl.proxySelectionDetails.End_Date__c = Date.newInstance(2017, 2, 23);
		cntrl.startProcess();
		cntrl.pollJobs();
		cntrl.getExportTypeOptions();
		cntrl.getIsStarted();
		
		ScheduledJobsController sCntrl = new ScheduledJobsController();
		sCntrl.getscheduledJobs();
		sCntrl.cancelJob();
		 
		ScheduledJobsController.BatchJob job = new ScheduledJobsController.BatchJob(new CronTrigger());
		
				
		// Create the Batch process
//		GcFE_TransactionSummaryBatch transSummaryBatch = new GcFE_TransactionSummaryBatch(TEST_SETTING_NAME, Date.newInstance(2017, 2, 21), Date.newInstance(2017, 2, 23), null, null);

		// Execute the Batch
//		Database.executeBatch(transSummaryBatch);

		// Stop the test
		Test.stopTest();

		// Check that a Header record has been created
		List<Transaction_Summary_Header__c> transHeaders = [SELECT Id, Status__c, Export_Name__c FROM Transaction_Summary_Header__c WHERE Export_Name__c=:TEST_SETTING_NAME];
		System.assertEquals(1, transHeaders.size());

		// Get the Header ID
		Id transHeaderId = transHeaders[0].Id;

		// Check that a couple of Summaries have been created
		List<Transaction_Summary__c> transSummaries = [SELECT Id, Transaction_Summary_Header__c, 
                                                       Total_Amount__c, 
                                                       Group_ID__c, 
                                                       Finance_Code__c, 
                                                       Banking_Date__c 
															FROM Transaction_Summary__c
															WHERE Transaction_Summary_Header__c=:transHeaderId];
		System.assertEquals(2, transSummaries.size());

		// Test the group IDs and Amounts
		for (Transaction_Summary__c transSummary : transSummaries) {
			if (transSummary.Group_ID__c == '2017~2~21~FIN0002') {
				System.assertEquals(26,transSummary.Total_Amount__c);
				System.assertEquals('FIN0002',transSummary.Finance_Code__c);
			} else if (transSummary.Group_ID__c == '2017~2~22~FIN0003') {
				System.assertEquals(199,transSummary.Total_Amount__c);
				System.assertEquals('FIN0003',transSummary.Finance_Code__c);
			} else {
				System.assert(false, 'This group ID is not valid : ' + transSummary);
			}					

		}


		
	}
	
	/**
	 * @description Test that a batch process finds Opportunities and creates the summary and summary header records
	 **/
	static testMethod void testBatchCreate_controller_scheduled() {

		// Create Opportunities for testing
		init();

		// Start the test
		Test.startTest();

		GcFE_GenerateTransSummariesController cntrl = new GcFE_GenerateTransSummariesController();
		cntrl.selectedExportSettings = TEST_SETTING_NAME;

		cntrl.proxySelectionDetails = new Transaction_Summary_Header__c ();
		cntrl.proxySelectionDetails.Start_Date__c = Date.newInstance(2017, 2, 21);
		cntrl.proxySelectionDetails.End_Date__c = Date.newInstance(2017, 2, 23);
		cntrl.proxySelectionDetails.Scheduled_Date__c = Datetime.now();
		cntrl.startProcess();
		cntrl.pollJobs();
		cntrl.getExportTypeOptions();
		cntrl.getIsStarted();
		
		ScheduledJobsController sCntrl = new ScheduledJobsController();
		sCntrl.getscheduledJobs();
		sCntrl.cancelJob();
		 
		ScheduledJobsController.BatchJob job = new ScheduledJobsController.BatchJob(new CronTrigger());
		
				
		// Create the Batch process
//		GcFE_TransactionSummaryBatch transSummaryBatch = new GcFE_TransactionSummaryBatch(TEST_SETTING_NAME, Date.newInstance(2017, 2, 21), Date.newInstance(2017, 2, 23), null, null);

		// Execute the Batch
//		Database.executeBatch(transSummaryBatch);

		// Stop the test
		Test.stopTest();

		GcFE_ExportFileService gfe = new GcFE_ExportFileService();

		Plugin.getInstanceIETFBatchPreFinish();
		
	}
	
	/**
	 * @description Test that the correct SOQL string is returned given certain parameters
	 **/
	static testMethod void testSOQLCreation() {

		// Start the test
		Test.startTest();

		// Call the method to get the SOQL
		String testQuery = GcFE_TransactionSummaryService.getObjectQuery(TEST_SETTING_NAME, Date.newInstance(2017, 3, 1), Date.newInstance(2017, 4, 1), null, null);

		// Stop the test
		Test.stopTest();

		// Check that the query is correct
		System.assertEquals(true, testQuery.contains('Id'));
        System.assertEquals(true, testQuery.contains('CloseDate'));
        System.assertEquals(true, testQuery.contains('Transaction_Summary__c'));
        System.assertEquals(true, testQuery.contains('Amount'));
        System.assertEquals(true, testQuery.contains('NextStep'));
        System.assertEquals(true, testQuery.contains('Posted_Finance_Code__c'));
        System.assertEquals(true, testQuery.contains('FROM'));
        System.assertEquals(true, testQuery.contains('Opportunity'));
        System.assertEquals(true, testQuery.contains('WHERE'));
        System.assertEquals(true, testQuery.contains('CloseDate>=2017-03-01'));
        System.assertEquals(true, testQuery.contains('AND'));
        System.assertEquals(true, testQuery.contains('CloseDate<=2017-04-01'));
	}


	/**
	 * @descrpition Test that the correct export file is created without grouping
	 **/
	static testMethod void testSimpleExportFileCreation() {

		// Create a Summary Header object
		Transaction_Summary_Header__c summaryHeader = createSummaryHeader('New', null, TEST_SETTING_NAME);
		insert summaryHeader;

		// Create Summary records
		List<Transaction_Summary__c> transSummaries = new List<Transaction_Summary__c>();

		// Create some records for sub-group 1 
		transSummaries.add(createSummary(summaryHeader.Id, 'FH0080000000000~~~~~', 5232, 'FH0080000000000', null, 'D,,ADNIMP,170117,1136XXXXXXXXX170101,,','O1'));
		transSummaries.add(createSummary(summaryHeader.Id, 'NCN200K96F00000,,-20,O1,888,E1', -20, 'NCN200K96F00000', null, 'D,,ADNIMP,170117,1136XXXXXXXXX170101,,','O1'));
		transSummaries.add(createSummary(summaryHeader.Id, 'NDH200JA3300000,,-10,O3,851,E2', -10, 'NDH200JA3300000', null, 'D,,ADNIMP,170117,1136XXXXXXXXX170101,,','O1'));
		transSummaries.add(createSummary(summaryHeader.Id, 'NDH200JA3400000,,-5,O4,852,E3', -5, 'NDH200JA3400000', null, 'D,,ADNIMP,170117,1136XXXXXXXXX170101,,','O3'));
		transSummaries.add(createSummary(summaryHeader.Id, 'NDH200JA7100000,,-30,O1,853,E4', -30, 'NDH200JA7100000', null, 'D,,ADNIMP,170117,1136XXXXXXXXX170101,,','O2'));

		// Create some records for sub-group 2 
		transSummaries.add(createSummary(summaryHeader.Id, 'FH0080000000000,,8.92,,,', 8.92, 'FH0080000000000', null, 'D,,ADNIMP,221116,15626 SKYL P 221102,,','O3'));
		transSummaries.add(createSummary(summaryHeader.Id, 'RIR200J63900000,,-8.92,,,', -8.92, 'RIR200J63900000', null, 'D,,ADNIMP,221116,15626 SKYL P 221102,,','O4'));

		// Create some records for sub-group 3 
		transSummaries.add(createSummary(summaryHeader.Id, 'FH0052ZZ0100000,,12518.18,,,', 12518.18, 'FH0052ZZ0100000', null, 'D,,ADNIMP,121216,1612072071CFX121203,,','O1'));
		transSummaries.add(createSummary(summaryHeader.Id, 'NCD200J02H00000,,-12518.18,,,', -12518.18, 'NCD200J02H00000', null, 'D,,ADNIMP,121216,1612072071CFX121203,,','O2'));
		transSummaries.add(createSummary(summaryHeader.Id, 'FH0078000000000,,545.55,,,', 545.55, 'FH0078000000000', null, 'D,,ADNIMP,121216,1612072071CFX121203,,','O1'));		

		// Insert the Transaction Summaries
 		insert transSummaries;

		// Start the Test
		Test.startTest();

		// Create the file
		GcFE_TransactionSummaryService.createExportFile(summaryHeader.Id);

		// Stop the test
		Test.stopTest();

		// Get the attachment and test the contents
		List<Attachment> exportFiles = [SELECT Id, ParentId, Name, Body, ContentType FROM Attachment WHERE ParentId=:summaryHeader.Id];
		System.assertEquals(1, exportFiles.size());

		// Test the name of the export file
		Datetime currentTime = System.now();
		System.assertEquals('SRM Import DY' + currentTime.format('ddMMYY') + '.csv',exportFiles[0].Name);

		// Test the file contents
 	    Blob fileBlob = exportFiles[0].Body;
        String fileContents = fileBlob.toString();
        List<String> fileRows = fileContents.split(GcFE_ExportFileService.NEWLINE);
        System.assertEquals(14, fileRows.size()); // Should include a header, a group row for each group (3) and then 10 detail rows
        
        // Test that the header is OK
		System.assertEquals('H,,,SRM Import DY' + currentTime.format('ddMMYY') + ',,,',fileRows[0]);

		// Test the third sub-header row and detail rows
		System.assertEquals('D,,ADNIMP,121216,1612072071CFX121203,,',fileRows[1]);		
		System.assertEquals('G,FH0052ZZ0100000,,12518.18,O1',fileRows[2]);		
		System.assertEquals('G,FH0078000000000,,545.55,O1',fileRows[3]);				
		System.assertEquals('G,NCD200J02H00000,,-12518.18,O2',fileRows[4]);		

		// Test the first sub-header row and detail rows
		System.assertEquals('D,,ADNIMP,170117,1136XXXXXXXXX170101,,',fileRows[5]);		
		System.assertEquals('G,FH0080000000000,,5232,O1',fileRows[6]);		
		System.assertEquals('G,NCN200K96F00000,,-20,O1',fileRows[7]);
		System.assertEquals('G,NDH200JA3300000,,-10,O1',fileRows[8]);		
		System.assertEquals('G,NDH200JA3400000,,-5,O3',fileRows[9]);		
		System.assertEquals('G,NDH200JA7100000,,-30,O2',fileRows[10]);	

		// Test the second sub-header row and detail rows
		System.assertEquals('D,,ADNIMP,221116,15626 SKYL P 221102,,',fileRows[11]);		
		System.assertEquals('G,FH0080000000000,,8.92,O3',fileRows[12]);		
		System.assertEquals('G,RIR200J63900000,,-8.92,O4',fileRows[13]);		

		// Check that the header status has been changed
		Transaction_Summary_Header__c updatedSummaryHeader = [SELECT Id, Status__c, Posted_Date__c FROM Transaction_Summary_Header__c WHERE Id=:summaryHeader.Id];
		System.assertNotEquals(null, updatedSummaryHeader.Posted_Date__c);
		System.assertEquals('Posted', updatedSummaryHeader.Status__c);

	}


	/**
	 * @descrpition Test that the correct export file is created without grouping
	 **/
	static testMethod void testSimpleExportFileCreation_controller() {

		// Create a Summary Header object
		Transaction_Summary_Header__c summaryHeader = createSummaryHeader('New', null, TEST_SETTING_NAME);
		insert summaryHeader;

		// Create Summary records
		List<Transaction_Summary__c> transSummaries = new List<Transaction_Summary__c>();

		// Create some records for sub-group 1 
		transSummaries.add(createSummary(summaryHeader.Id, 'FH0080000000000~~~~~', 5232, 'FH0080000000000', null, 'D,,ADNIMP,170117,1136XXXXXXXXX170101,,','O1'));
		transSummaries.add(createSummary(summaryHeader.Id, 'NCN200K96F00000,,-20,O1,888,E1', -20, 'NCN200K96F00000', null, 'D,,ADNIMP,170117,1136XXXXXXXXX170101,,','O1'));
		transSummaries.add(createSummary(summaryHeader.Id, 'NDH200JA3300000,,-10,O3,851,E2', -10, 'NDH200JA3300000', null, 'D,,ADNIMP,170117,1136XXXXXXXXX170101,,','O1'));
		transSummaries.add(createSummary(summaryHeader.Id, 'NDH200JA3400000,,-5,O4,852,E3', -5, 'NDH200JA3400000', null, 'D,,ADNIMP,170117,1136XXXXXXXXX170101,,','O3'));
		transSummaries.add(createSummary(summaryHeader.Id, 'NDH200JA7100000,,-30,O1,853,E4', -30, 'NDH200JA7100000', null, 'D,,ADNIMP,170117,1136XXXXXXXXX170101,,','O2'));

		// Create some records for sub-group 2 
		transSummaries.add(createSummary(summaryHeader.Id, 'FH0080000000000,,8.92,,,', 8.92, 'FH0080000000000', null, 'D,,ADNIMP,221116,15626 SKYL P 221102,,','O3'));
		transSummaries.add(createSummary(summaryHeader.Id, 'RIR200J63900000,,-8.92,,,', -8.92, 'RIR200J63900000', null, 'D,,ADNIMP,221116,15626 SKYL P 221102,,','O4'));

		// Create some records for sub-group 3 
		transSummaries.add(createSummary(summaryHeader.Id, 'FH0052ZZ0100000,,12518.18,,,', 12518.18, 'FH0052ZZ0100000', null, 'D,,ADNIMP,121216,1612072071CFX121203,,','O1'));
		transSummaries.add(createSummary(summaryHeader.Id, 'NCD200J02H00000,,-12518.18,,,', -12518.18, 'NCD200J02H00000', null, 'D,,ADNIMP,121216,1612072071CFX121203,,','O2'));
		transSummaries.add(createSummary(summaryHeader.Id, 'FH0078000000000,,545.55,,,', 545.55, 'FH0078000000000', null, 'D,,ADNIMP,121216,1612072071CFX121203,,','O1'));		

		// Insert the Transaction Summaries
 		insert transSummaries;

		// Start the Test
		Test.startTest();

		GcFE_ExportController cntrl = new GcFE_ExportController();
		
		GcFE_ExportController.exportTransactionSummaries(summaryHeader.Id);
		// Create the file
//		GcFE_TransactionSummaryService.createExportFile(summaryHeader.Id);
		GcFE_ExportController.getSummaryHeader(summaryHeader.Id);

		
		// Stop the test
		Test.stopTest();

		// Get the attachment and test the contents
		List<Attachment> exportFiles = [SELECT Id, ParentId, Name, Body, ContentType FROM Attachment WHERE ParentId=:summaryHeader.Id];
		System.assertEquals(1, exportFiles.size());

		// Test the name of the export file
		Datetime currentTime = System.now();
		System.assertEquals('SRM Import DY' + currentTime.format('ddMMYY') + '.csv',exportFiles[0].Name);

		// Test the file contents
 	    Blob fileBlob = exportFiles[0].Body;
        String fileContents = fileBlob.toString();
        List<String> fileRows = fileContents.split(GcFE_ExportFileService.NEWLINE);
        System.assertEquals(14, fileRows.size()); // Should include a header, a group row for each group (3) and then 10 detail rows
        
        // Test that the header is OK
		System.assertEquals('H,,,SRM Import DY' + currentTime.format('ddMMYY') + ',,,',fileRows[0]);

		// Test the third sub-header row and detail rows
		System.assertEquals('D,,ADNIMP,121216,1612072071CFX121203,,',fileRows[1]);		
		System.assertEquals('G,FH0052ZZ0100000,,12518.18,O1',fileRows[2]);		
		System.assertEquals('G,FH0078000000000,,545.55,O1',fileRows[3]);				
		System.assertEquals('G,NCD200J02H00000,,-12518.18,O2',fileRows[4]);		

		// Test the first sub-header row and detail rows
		System.assertEquals('D,,ADNIMP,170117,1136XXXXXXXXX170101,,',fileRows[5]);		
		System.assertEquals('G,FH0080000000000,,5232,O1',fileRows[6]);		
		System.assertEquals('G,NCN200K96F00000,,-20,O1',fileRows[7]);
		System.assertEquals('G,NDH200JA3300000,,-10,O1',fileRows[8]);		
		System.assertEquals('G,NDH200JA3400000,,-5,O3',fileRows[9]);		
		System.assertEquals('G,NDH200JA7100000,,-30,O2',fileRows[10]);	

		// Test the second sub-header row and detail rows
		System.assertEquals('D,,ADNIMP,221116,15626 SKYL P 221102,,',fileRows[11]);		
		System.assertEquals('G,FH0080000000000,,8.92,O3',fileRows[12]);		
		System.assertEquals('G,RIR200J63900000,,-8.92,O4',fileRows[13]);		

		// Check that the header status has been changed
		Transaction_Summary_Header__c updatedSummaryHeader = [SELECT Id, Status__c, Posted_Date__c FROM Transaction_Summary_Header__c WHERE Id=:summaryHeader.Id];
		System.assertNotEquals(null, updatedSummaryHeader.Posted_Date__c);
		System.assertEquals('Posted', updatedSummaryHeader.Status__c);

	}

	/**
	 * @description Test that a process can be rolled back
	 **/
	static testMethod void testRollbackSummary() {

		// Create a Summary Header object
		Transaction_Summary_Header__c summaryHeader = createSummaryHeader('New', null, TEST_SETTING_NAME);
		insert summaryHeader;

		// Create Summary records
		Map<String, Transaction_Summary__c> transSummariesByName = new Map<String, Transaction_Summary__c>();

		// Create some records for sub-group 1 2 and 3
		transSummariesByName.put('TS1', createSummary(summaryHeader.Id, 'FH0080000000000~~~~~', 5232, 'FH0080000000000', null, 'D,,ADNIMP,170117,1136XXXXXXXXX170101,,','O1'));
		transSummariesByName.put('TS2', createSummary(summaryHeader.Id, 'FH0080000000000,,8.92,,,', 8.92, 'FH0080000000000', null, 'D,,ADNIMP,221116,15626 SKYL P 221102,,','O3'));
		transSummariesByName.put('TS3', createSummary(summaryHeader.Id, 'FH0052ZZ0100000,,12518.18,,,', 12518.18, 'FH0052ZZ0100000', null, 'D,,ADNIMP,121216,1612072071CFX121203,,','O1'));

		// Insert the Transaction Summaries
 		insert transSummariesByName.values();

		// Create an Account that Donations can be linked to
		Account testAccount = TestFactory.createAccount('Test Account');
		insert testAccount;

        //Create Contact
         Contact con = new Contact (firstname = 'john', lastname = 'test', AccountId = testAccount.id, Email = 'test@test.com');
    	 Insert con;
         contactId2 = con.Id;
        
		// Create a campaign that Opportunities can be linked to
		Campaign testCampaign = TestFactory.createCampaign();
		insert testCampaign;

 		// First group of Opportunities
 		List<Opportunity> testOpportunities = new List<Opportunity>();
		testOpportunities.add(createOpportunity(testCampaign, Date.newInstance(2017, 2, 15), testAccount.Id, 'Paid', '2017~2~15~FIN0001', 'FIN0001', 23, transSummariesByName.get('TS1').id));
		testOpportunities.add(createOpportunity(testCampaign, Date.newInstance(2017, 2, 15), testAccount.Id, 'Paid', '2017~2~15~FIN0001', 'FIN0001', 11, transSummariesByName.get('TS1').id));
		testOpportunities.add(createOpportunity(testCampaign, Date.newInstance(2017, 2, 15), testAccount.Id, 'Paid', '2017~2~15~FIN0001', 'FIN0001', 12, transSummariesByName.get('TS1').id));

		// Second group of Opportunities
		testOpportunities.add(createOpportunity(testCampaign, Date.newInstance(2017, 2, 21), testAccount.Id, 'Paid', '2017~2~21~FIN0002', 'FIN0002', 14, transSummariesByName.get('TS2').id));
		testOpportunities.add(createOpportunity(testCampaign, Date.newInstance(2017, 2, 21), testAccount.Id, 'Paid', '2017~2~21~FIN0002', 'FIN0002', 12, transSummariesByName.get('TS2').id));

		// Third group of Opportunities
		testOpportunities.add(createOpportunity(testCampaign, Date.newInstance(2017, 2, 22), testAccount.Id, 'Paid', '2017~2~22~FIN0003', 'FIN0003', 99, transSummariesByName.get('TS3').id));
		testOpportunities.add(createOpportunity(testCampaign, Date.newInstance(2017, 2, 22), testAccount.Id, 'Paid', '2017~2~22~FIN0003', 'FIN0003', 100, transSummariesByName.get('TS3').id)); 		

		// Step through the Opportunities and update the export date and status
		for (Opportunity opp : testOpportunities) {
			opp.Finance_Export_Status__c = 'Exported';
			opp.Finance_Export_Date__c = System.today();
            opp.npsp__Primary_Contact__c = contactId2;
		}

		// Insert the Opportunities
		insert testOpportunities;

		// Get the Opportunity IDs
		Set<Id> opportunityIds = new Set<Id>();
		for (Opportunity opp : testOpportunities) {
			opportunityIds.add(opp.id);
		}

		// Start the test
		Test.startTest();

		// Create the roll back batch process
		GcFE_TransactionSummaryRollbackBatch rollbackBatch = new GcFE_TransactionSummaryRollbackBatch(summaryHeader.Id);

		// Execute the batch
		Database.executeBatch(rollbackBatch);

		// Stop the test
		Test.stopTest();

		// Get the summary header and check the status
		Transaction_Summary_Header__c updatedSummaryHeader = [SELECT Id, Status__c FROM Transaction_Summary_Header__c WHERE Id =:summaryHeader.id];
		System.assertEquals('Rolled Back',updatedSummaryHeader.Status__c);

		// Check that the summaries have been removed
		List<Transaction_Summary__c> updatedTransSummaries = [SELECT Id FROM Transaction_Summary__c WHERE Transaction_Summary_Header__c=:summaryHeader.Id];
		System.assertEquals(0, updatedTransSummaries.size());

		// Check that the Opportunities have been reset (i.e. date cleared, lookup cleared and status reset)
		List<Opportunity> updatedOpportunities = [SELECT Id, Finance_Export_Date__c, Finance_Export_Status__c, Transaction_Summary__c FROM Opportunity WHERE Id IN :opportunityIds];
		System.assertEquals(7, updatedOpportunities.size());
		for (Opportunity opp : updatedOpportunities) {
			System.assertEquals(null, opp.Finance_Export_Date__c);
			System.assertEquals(null, opp.Transaction_Summary__c);
			System.assertEquals('To Be Exported', opp.Finance_Export_Status__c);
		}

	}

	static testMethod void testRollbackSummary_Controller() {

		// Create a Summary Header object
		Transaction_Summary_Header__c summaryHeader = createSummaryHeader('New', null, TEST_SETTING_NAME);
		insert summaryHeader;

		// Create Summary records
		Map<String, Transaction_Summary__c> transSummariesByName = new Map<String, Transaction_Summary__c>();

		// Create some records for sub-group 1 2 and 3
		transSummariesByName.put('TS1', createSummary(summaryHeader.Id, 'FH0080000000000~~~~~', 5232, 'FH0080000000000', null, 'D,,ADNIMP,170117,1136XXXXXXXXX170101,,','O1'));
		transSummariesByName.put('TS2', createSummary(summaryHeader.Id, 'FH0080000000000,,8.92,,,', 8.92, 'FH0080000000000', null, 'D,,ADNIMP,221116,15626 SKYL P 221102,,','O3'));
		transSummariesByName.put('TS3', createSummary(summaryHeader.Id, 'FH0052ZZ0100000,,12518.18,,,', 12518.18, 'FH0052ZZ0100000', null, 'D,,ADNIMP,121216,1612072071CFX121203,,','O1'));

		// Insert the Transaction Summaries
 		insert transSummariesByName.values();

		// Create an Account that Donations can be linked to
		Account testAccount = TestFactory.createAccount('Test Account');
		insert testAccount;

        //Create Contact
         Contact con = new Contact (firstname = 'john', lastname = 'test', AccountId = testAccount.id, Email = 'test@test.com');
    	 Insert con;
         contactId2 = con.Id;
        
		// Create a campaign that Opportunities can be linked to
		Campaign testCampaign = TestFactory.createCampaign();
		insert testCampaign;

 		// First group of Opportunities
 		List<Opportunity> testOpportunities = new List<Opportunity>();
		testOpportunities.add(createOpportunity(testCampaign, Date.newInstance(2017, 2, 15), testAccount.Id, 'Paid', '2017~2~15~FIN0001', 'FIN0001', 23, transSummariesByName.get('TS1').id));
		testOpportunities.add(createOpportunity(testCampaign, Date.newInstance(2017, 2, 15), testAccount.Id, 'Paid', '2017~2~15~FIN0001', 'FIN0001', 11, transSummariesByName.get('TS1').id));
		testOpportunities.add(createOpportunity(testCampaign, Date.newInstance(2017, 2, 15), testAccount.Id, 'Paid', '2017~2~15~FIN0001', 'FIN0001', 12, transSummariesByName.get('TS1').id));

		// Second group of Opportunities
		testOpportunities.add(createOpportunity(testCampaign, Date.newInstance(2017, 2, 21), testAccount.Id, 'Paid', '2017~2~21~FIN0002', 'FIN0002', 14, transSummariesByName.get('TS2').id));
		testOpportunities.add(createOpportunity(testCampaign, Date.newInstance(2017, 2, 21), testAccount.Id, 'Paid', '2017~2~21~FIN0002', 'FIN0002', 12, transSummariesByName.get('TS2').id));

		// Third group of Opportunities
		testOpportunities.add(createOpportunity(testCampaign, Date.newInstance(2017, 2, 22), testAccount.Id, 'Paid', '2017~2~22~FIN0003', 'FIN0003', 99, transSummariesByName.get('TS3').id));
		testOpportunities.add(createOpportunity(testCampaign, Date.newInstance(2017, 2, 22), testAccount.Id, 'Paid', '2017~2~22~FIN0003', 'FIN0003', 100, transSummariesByName.get('TS3').id)); 		

		// Step through the Opportunities and update the export date and status
		for (Opportunity opp : testOpportunities) {
			opp.Finance_Export_Status__c = 'Exported';
			opp.Finance_Export_Date__c = System.today();
            opp.npsp__Primary_Contact__c = contactId2;
		}

		// Insert the Opportunities
		insert testOpportunities;

		// Get the Opportunity IDs
		Set<Id> opportunityIds = new Set<Id>();
		for (Opportunity opp : testOpportunities) {
			opportunityIds.add(opp.id);
		}

		// Start the test
		Test.startTest();

		GcFE_RollbackTransSummariesController contrl = new GcFE_RollbackTransSummariesController();

		GcFE_RollbackTransSummariesController.rollbackTransactionSummaries(summaryHeader.Id);
		// Create the roll back batch process
	//	GcFE_TransactionSummaryRollbackBatch rollbackBatch = new GcFE_TransactionSummaryRollbackBatch(summaryHeader.Id);
		GcFE_RollbackTransSummariesController.getSummaryHeader(summaryHeader.Id);

		// Execute the batch
//		Database.executeBatch(rollbackBatch);

		// Stop the test
		Test.stopTest();

		GcFE_ShowBatchProcessController cnt = new GcFE_ShowBatchProcessController();
		
		// Get the summary header and check the status
		Transaction_Summary_Header__c updatedSummaryHeader = [SELECT Id, Status__c FROM Transaction_Summary_Header__c WHERE Id =:summaryHeader.id];
		System.assertEquals('Rolled Back',updatedSummaryHeader.Status__c);

		// Check that the summaries have been removed
		List<Transaction_Summary__c> updatedTransSummaries = [SELECT Id FROM Transaction_Summary__c WHERE Transaction_Summary_Header__c=:summaryHeader.Id];
		System.assertEquals(0, updatedTransSummaries.size());

		// Check that the Opportunities have been reset (i.e. date cleared, lookup cleared and status reset)
		List<Opportunity> updatedOpportunities = [SELECT Id, Finance_Export_Date__c, Finance_Export_Status__c, Transaction_Summary__c FROM Opportunity WHERE Id IN :opportunityIds];
		System.assertEquals(7, updatedOpportunities.size());
		for (Opportunity opp : updatedOpportunities) {
			System.assertEquals(null, opp.Finance_Export_Date__c);
			System.assertEquals(null, opp.Transaction_Summary__c);
			System.assertEquals('To Be Exported', opp.Finance_Export_Status__c);
		}

	}



	/**
	 * @description Test that a process can be rolled back
	 **/
	static testMethod void testRollbackSummary_No_Summaries() {

		// Create a Summary Header object
		Transaction_Summary_Header__c summaryHeader = createSummaryHeader('New', null, TEST_SETTING_NAME);
		insert summaryHeader;

		// Create an Account that Donations can be linked to
		Account testAccount = TestFactory.createAccount('Test Account');
		insert testAccount;

        //Create Contact
         Contact con = new Contact (firstname = 'john', lastname = 'test', AccountId = testAccount.id, Email = 'test@test.com');
    	 Insert con;
         contactId2 = con.Id;
        
		// Create a campaign that Opportunities can be linked to
		Campaign testCampaign = TestFactory.createCampaign();
		insert testCampaign;

 		// First group of Opportunities
 		List<Opportunity> testOpportunities = new List<Opportunity>();
		testOpportunities.add(createOpportunity(testCampaign, Date.newInstance(2017, 2, 15), testAccount.Id, 'Paid', '2017~2~15~FIN0001', 'FIN0001', 23, null));
		testOpportunities.add(createOpportunity(testCampaign, Date.newInstance(2017, 2, 15), testAccount.Id, 'Paid', '2017~2~15~FIN0001', 'FIN0001', 11, null));
		testOpportunities.add(createOpportunity(testCampaign, Date.newInstance(2017, 2, 15), testAccount.Id, 'Paid', '2017~2~15~FIN0001', 'FIN0001', 12, null));

		// Second group of Opportunities
		testOpportunities.add(createOpportunity(testCampaign, Date.newInstance(2017, 2, 21), testAccount.Id, 'Paid', '2017~2~21~FIN0002', 'FIN0002', 14, null));
		testOpportunities.add(createOpportunity(testCampaign, Date.newInstance(2017, 2, 21), testAccount.Id, 'Paid', '2017~2~21~FIN0002', 'FIN0002', 12, null));

		// Third group of Opportunities
		testOpportunities.add(createOpportunity(testCampaign, Date.newInstance(2017, 2, 22), testAccount.Id, 'Paid', '2017~2~22~FIN0003', 'FIN0003', 99, null));
		testOpportunities.add(createOpportunity(testCampaign, Date.newInstance(2017, 2, 22), testAccount.Id, 'Paid', '2017~2~22~FIN0003', 'FIN0003', 100, null)); 		

		// Step through the Opportunities and update the export date and status
		for (Opportunity opp : testOpportunities) {
			opp.Finance_Export_Status__c = 'Exported';
			opp.Finance_Export_Date__c = System.today();
            opp.npsp__Primary_Contact__c = contactId2;
		}

		// Insert the Opportunities
		insert testOpportunities;

		// Get the Opportunity IDs
		Set<Id> opportunityIds = new Set<Id>();
		for (Opportunity opp : testOpportunities) {
			opportunityIds.add(opp.id);
		}

		// Start the test
		Test.startTest();

		// Create the roll back batch process
		GcFE_TransactionSummaryRollbackBatch rollbackBatch = new GcFE_TransactionSummaryRollbackBatch(summaryHeader.Id);

		// Execute the batch
		Database.executeBatch(rollbackBatch);

		// Stop the test
		Test.stopTest();

		// Get the summary header and check the status
		Transaction_Summary_Header__c updatedSummaryHeader = [SELECT Id, Status__c FROM Transaction_Summary_Header__c WHERE Id =:summaryHeader.id];
		System.assertEquals('Rolled Back',updatedSummaryHeader.Status__c);

		// Check that the summaries have been removed
		List<Transaction_Summary__c> updatedTransSummaries = [SELECT Id FROM Transaction_Summary__c WHERE Transaction_Summary_Header__c=:summaryHeader.Id];
		System.assertEquals(0, updatedTransSummaries.size());

		// Check that the Opportunities have been reset (i.e. date cleared, lookup cleared and status reset)
		List<Opportunity> updatedOpportunities = [SELECT Id, Finance_Export_Date__c, Finance_Export_Status__c, Transaction_Summary__c FROM Opportunity WHERE Id IN :opportunityIds];
		System.assertEquals(7, updatedOpportunities.size());
		for (Opportunity opp : updatedOpportunities) {
			System.assertNotEquals(null, opp.Finance_Export_Date__c);
			System.assertEquals(null, opp.Transaction_Summary__c);
			System.assertEquals('Exported', opp.Finance_Export_Status__c);
		}

	}
	
	/************************** PRIVATE METHODS *************************/
    /** 
	 * @description Gets the Custom Metadata Type for Export Settings
	 * @param String The Custom Metadatatype name to search for
	 * @return SOQL SOQL code	
	 **/
	private static Transaction_Export_Settings__mdt getTransactionSummarySettings(String settingName) {

		// Get the setting for the given name
		return [SELECT Id, Additional_Filter__c, 
                Export_Fields__c, 
                Export_File_Header_Row__c, 
                Export_File_Name_Pattern__c, 
                Group_Fields__c, 
                Processed_Date_Field__c, 
				Selection_1_Ask_User__c, 
                Selection_1_Default_Value__c, 
                Selection_1_Field_Name__c, 
                Selection_2_Ask_User__c, 
                Selection_2_Default_Value__c, 
                Selection_2_Field_Name__c,
				Sub_Group_Field_Name__c, 
                Transaction_Date_Field__c, 
                Transaction_Object_Name__c, 
                Transaction_Summary_Field_Name__c
					FROM Transaction_Export_Settings__mdt
					WHERE DeveloperName=:settingName];

	}

    /** 
	 * @description Creates an Opportunity
	 * @param Campaign Campaign object
	 * @param Date CloseDate of Opportunity
	 * @param Id Account Id
	 * @param String Stage name of the Opportunity
	 * @param String Group Text
	 * @param String Finance Code
	 * @param Double Amount
	 * @param Id Transaction Summary Id
	 * @return Opportunity a test Opportunity	
	 **/
	private static Opportunity createOpportunity(Campaign camp, Date closeDate, Id accId, String stageName, String groupText, String financeCode, Double amount, Id transSummaryId) {
		Opportunity testOpportunity = createOpportunity(camp, closeDate, accId, stageName, groupText, financeCode, amount);
		testOpportunity.Transaction_Summary__c = transSummaryId;
        testOpportunity.npsp__Primary_Contact__c = contactId;
		return testOpportunity;
	}

    /** 
	 * @description Creates a Donation Opportunity
	 * @param Campaign Campaign object
	 * @param Date CloseDate of Opportunity
	 * @param Id Account Id
	 * @param String Stage name of the Opportunity
	 * @param String Group Text
	 * @param String Finance Code
	 * @param Double Amount
	 * @return Opportunity a Donation Opportunity	
	 **/
	private static Opportunity createOpportunity(Campaign camp, Date closeDate, Id accId, String stageName, String groupText, String financeCode, Double amount) {

		// Create a Donation Opportunity
		Opportunity testOpportunity = TestFactory.createDonation(camp, closeDate, accId,  null, stageName);
		testOpportunity.npsp__Grant_Contract_Number__c = groupText; // Just somewhere random to put a group string
		testOpportunity.NextStep = financeCode; // Just using this as a test place to hold this info
		testOpportunity.Amount = amount;
        testOpportunity.npsp__Primary_Contact__c = contactId;
		return testOpportunity;

	}

    /** 
	 * @description Creates a Transaction Summary Header
	 * @param String Status of the Transaction Summary
	 * @param Date Posted Date of Transaction Sumamry
	 * @param String Name of the Export
	 * @return Transaction_Summary_Header__c a Transaction Summary Header	
	 **/
	private static Transaction_Summary_Header__c createSummaryHeader(String status, Date postedDate, String exportName) {
		Transaction_Summary_Header__c summaryHeader = new Transaction_Summary_Header__c();
		summaryHeader.Status__c = status;
		summaryHeader.Posted_Date__c = postedDate;
		summaryHeader.Export_Name__c = exportName;
		return summaryHeader;
	}

    /** 
	 * @description Creates a Transaction Summary
	 * @param Id Id of the Transaction Summary Header
	 * @param String Group Id
	 * @param Decimal Amount
	 * @param String Finance Code
	 * @param Date Banking Date
	 * @param String Sub Group Id
	 * @param String Outcome
	 * @return Transaction_Summary__c a Transaction Summary	
	 **/
	private static Transaction_Summary__c createSummary(Id transSummaryHeaderId, String groupID, Decimal amount, String financeCode, Date bankingDate, String subGroupId, String outcome) {
		Transaction_Summary__c transSummary = new Transaction_Summary__c();
		transSummary.Transaction_Summary_Header__c = transSummaryHeaderId;
		transSummary.Group_ID__c = groupID;
		transSummary.Total_Amount__c = amount;
		transSummary.Finance_Code__c = financeCode;
		transSummary.Banking_Date__c = bankingDate;
		transSummary.Project__c = subGroupId; // Project is just being used here as a placeholder for this
		transSummary.Outcome__c = outcome;
		return transSummary;
	}

}