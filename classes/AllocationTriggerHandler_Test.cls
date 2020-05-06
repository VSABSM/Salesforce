/**
 * This class contains unit tests for validating the behavior of Apex classes
 * and triggers.
 *
 * Unit tests are class methods that verify whether a particular piece
 * of code is working properly. Unit test methods take no arguments,
 * commit no data to the database, and are flagged with the testMethod
 * keyword in the method definition.
 *
 * All test methods in an organization are executed whenever Apex code is deployed
 * to a production organization to confirm correctness, ensure code
 * coverage, and prevent regressions. All Apex classes are
 * required to have at least 75% code coverage in order to be deployed
 * to a production organization. In addition, all triggers must have some code coverage.
 * 
 * The @isTest class annotation indicates this class only contains test
 * methods. Classes defined with the @isTest annotation do not count against
 * the organization size limit for all Apex scripts.
 *
 * See the Apex Language Reference for more information about Testing and Code Coverage.
 */
@isTest
private class AllocationTriggerHandler_Test {

    static testMethod void testLogCreation() {
    	
    	
    	list<npsp__Allocation__c> newgaus = new list<npsp__Allocation__c>();
    	
		// Create an Account that Donations can be linked to
		Account testAccount = TestFactory.createAccount('Test Account');
		insert testAccount;

        //Create Contact
         Contact con = new Contact (firstname = 'john', lastname = 'test', AccountId = testAccount.id, Email = 'test@test.com');
    	 Insert con;
    	    	
    	Campaign testCampaign = TestFactory.createCampaign(); 
    	
    	insert testCampaign;
    	
    	list<npsp__General_Accounting_Unit__c> newGenAllocs = new list<npsp__General_Accounting_Unit__c>();
    	
    	List<Opportunity> opps = new List<Opportunity>();

    	npsp__General_Accounting_Unit__c newGenAccUnit = new npsp__General_Accounting_Unit__c();
    	newGenAccUnit.name = 'test';
		newGenAllocs.add(newGenAccUnit);
    	
    	for (integer i = 0; i<100;i++) {
    		
    		Opportunity newOpp = TestFactory.createDonation(testCampaign, Date.today().addDays(i), testAccount.id, con.Id, 'Paid');
    		newOpp.amount = 100 + 1;
    		opps.add(newOpp);

	    	newGenAccUnit = new npsp__General_Accounting_Unit__c();
	    	newGenAccUnit.name = 'test'  + i;
    		newGenAllocs.add(newGenAccUnit);
    	

    	}
    	
    	insert newGenAllocs;
    	
		insert opps;        

    	for (integer i = 0; i<100;i++) {
    		
    		npsp__Allocation__c newGAU = new npsp__Allocation__c();
    		
    		newGAU.npsp__Amount__c = opps[i].amount- (opps[i].amount/100) * i;
    		newGAU.npsp__Percent__c = 100-i;
    		newGAU.npsp__Opportunity__c = opps[i].id;
    		newGAU.npsp__General_Accounting_Unit__c = newGenAllocs[i].id;
    		
    		newgaus.add(newGAU);

    		newGAU = new npsp__Allocation__c();
    		
    		newGAU.npsp__Amount__c = (opps[i].amount/100) * i;
    		newGAU.npsp__Percent__c = i;
    		newGAU.npsp__Opportunity__c = opps[i].id;
    		newGAU.npsp__General_Accounting_Unit__c = newGenAllocs[i+1].id;
    		
    		newgaus.add(newGAU);
    	}
    	
		insert newgaus;        

		List<GAU_Allocation_Change_Log__c> logs = [select id, New_GAU_Allocation__c, Opportunity__c, Campaign__c, Action__c, User__c from GAU_Allocation_Change_Log__c];

		system.assertEquals(logs.size(), 200);
		
		map<string, GAU_Allocation_Change_Log__c> logMap = new map<string, GAU_Allocation_Change_Log__c>();
		
		for (GAU_Allocation_Change_Log__c log:logs) {
			system.debug('log.New_GAU_Allocation__c - <' + log.New_GAU_Allocation__c +'>');
			logMap.put(log.New_GAU_Allocation__c, log);
				
		}
		
		map<id,  npsp__General_Accounting_Unit__c> GAUMap = new map<id,  npsp__General_Accounting_Unit__c>([select id, name from npsp__General_Accounting_Unit__c]);
		
		for (npsp__Allocation__c newgau:newgaus) {

    		string amount = string.valueOf(newgau.npsp__Amount__c);	
    		string percentage = string.valueOf(newgau.npsp__Percent__c.format());	

			npsp__General_Accounting_Unit__c gau = GAUMap.get(newgau.npsp__General_Accounting_Unit__c);

			system.debug('gau - <' + gau +'>');
				
			string gauName = gau.name;
			
			string keyVal = gauName + ' (£' + amount +' / ' + percentage + '%)';

			system.debug('keyVal - <' + keyVal +'>');
			
			GAU_Allocation_Change_Log__c thisLog = logMap.get(keyVal);
			
			system.assertEquals(thisLog.Opportunity__c, newgau.npsp__Opportunity__c);
			system.assertEquals(thisLog.Campaign__c, null);
			system.assertEquals(thisLog.Action__c, 'Created');
			
			system.assertEquals(thisLog.User__c, UserInfo.getUserId());
			
		}
    }
    
    static testMethod void testLogUpdate() {
    	
    	
    	list<npsp__Allocation__c> newgaus = new list<npsp__Allocation__c>();
    	
		// Create an Account that Donations can be linked to
		Account testAccount = TestFactory.createAccount('Test Account');
		insert testAccount;

        //Create Contact
         Contact con = new Contact (firstname = 'john', lastname = 'test', AccountId = testAccount.id, Email = 'test@test.com');
    	 Insert con;
    	    	
    	Campaign testCampaign = TestFactory.createCampaign(); 
    	
    	insert testCampaign;
    	
    	list<npsp__General_Accounting_Unit__c> newGenAllocs = new list<npsp__General_Accounting_Unit__c>();
    	
    	List<Opportunity> opps = new List<Opportunity>();

    	npsp__General_Accounting_Unit__c newGenAccUnit = new npsp__General_Accounting_Unit__c();
    	newGenAccUnit.name = 'test';
		newGenAllocs.add(newGenAccUnit);
    	
    	for (integer i = 0; i<100;i++) {
    		
    		Opportunity newOpp = TestFactory.createDonation(testCampaign, Date.today().addDays(i), testAccount.id, con.Id, 'Paid');
    		newOpp.amount = 100 + 1;
    		opps.add(newOpp);

	    	newGenAccUnit = new npsp__General_Accounting_Unit__c();
	    	newGenAccUnit.name = 'test'  + i;
    		newGenAllocs.add(newGenAccUnit);
    	

    	}
    	
    	insert newGenAllocs;
    	
		insert opps;        

    	for (integer i = 0; i<100;i++) {
    		
    		npsp__Allocation__c newGAU = new npsp__Allocation__c();
    		
    		newGAU.npsp__Amount__c = opps[i].amount- (opps[i].amount/100) * i;
    		newGAU.npsp__Percent__c = 100-i;
    		newGAU.npsp__Opportunity__c = opps[i].id;
    		newGAU.npsp__General_Accounting_Unit__c = newGenAllocs[i].id;
    		
    		newgaus.add(newGAU);

    		newGAU = new npsp__Allocation__c();
    		
    		newGAU.npsp__Amount__c = (opps[i].amount/100) * i;
    		newGAU.npsp__Percent__c = i;
    		newGAU.npsp__Opportunity__c = opps[i].id;
    		newGAU.npsp__General_Accounting_Unit__c = newGenAllocs[i+1].id;
    		
    		newgaus.add(newGAU);
    	}
    	
		insert newgaus;        

		List<GAU_Allocation_Change_Log__c> logs = [select id, New_GAU_Allocation__c, Opportunity__c, Campaign__c, Action__c, User__c from GAU_Allocation_Change_Log__c];

		system.assertEquals(logs.size(), 200);
		
		map<string, GAU_Allocation_Change_Log__c> logMap = new map<string, GAU_Allocation_Change_Log__c>();
		
		for (GAU_Allocation_Change_Log__c log:logs) {
//			system.debug('log.New_GAU_Allocation__c - <' + log.New_GAU_Allocation__c +'>');
			logMap.put(log.New_GAU_Allocation__c, log);
				
		}
		
		map<id,  npsp__General_Accounting_Unit__c> GAUMap = new map<id,  npsp__General_Accounting_Unit__c>([select id, name from npsp__General_Accounting_Unit__c]);
		
		for (npsp__Allocation__c newgau:newgaus) {

    		string amount = string.valueOf(newgau.npsp__Amount__c);	
    		string percentage = string.valueOf(newgau.npsp__Percent__c.format());	

			npsp__General_Accounting_Unit__c gau = GAUMap.get(newgau.npsp__General_Accounting_Unit__c);

	//		system.debug('gau - <' + gau +'>');
				
			string gauName = gau.name;
			
			string keyVal = gauName + ' (£' + amount +' / ' + percentage + '%)';

//			system.debug('keyVal - <' + keyVal +'>');
			
			GAU_Allocation_Change_Log__c thisLog = logMap.get(keyVal);
			
			system.assertEquals(thisLog.Opportunity__c, newgau.npsp__Opportunity__c);
			system.assertEquals(thisLog.Campaign__c, null);
			system.assertEquals(thisLog.Action__c, 'Created');
			
			system.assertEquals(thisLog.User__c, UserInfo.getUserId());
			
		}
		
		delete logs;
		
		list<npsp__Allocation__c> updatedGaus = new list<npsp__Allocation__c>();
				
    	decimal total = newgaus[4].npsp__Amount__c + newgaus[5].npsp__Amount__c;

		system.debug('total - <' + total +'>');
		system.debug('newgaus[5].npsp__Amount__c - <' + newgaus[5].npsp__Amount__c +'>');
		system.debug('newgaus[5].npsp__Percent__c - <' + newgaus[5].npsp__Percent__c +'>');
		system.debug('newgaus[4].npsp__Amount__c - <' + newgaus[4].npsp__Amount__c +'>');
		system.debug('newgaus[4].npsp__Percent__c - <' + newgaus[4].npsp__Percent__c +'>');
		system.debug('(total *5/100) - <' + (total *5/100) +'>');
    		
    	newgaus[5].npsp__Amount__c = newgaus[5].npsp__Amount__c + (total *5/100);
    		
    	newgaus[4].npsp__Amount__c = newgaus[4].npsp__Amount__c - (total *5/100);

    	newgaus[5].npsp__Percent__c = newgaus[5].npsp__Percent__c + 5;
    		
    	newgaus[4].npsp__Percent__c= newgaus[4].npsp__Percent__c - 5;

		system.debug('newgaus[5].npsp__Amount__c - <' + newgaus[5].npsp__Amount__c +'>');
		system.debug('newgaus[5].npsp__Percent__c - <' + newgaus[5].npsp__Percent__c +'>');
		system.debug('newgaus[4].npsp__Amount__c - <' + newgaus[4].npsp__Amount__c +'>');
		system.debug('newgaus[4].npsp__Percent__c - <' + newgaus[4].npsp__Percent__c +'>');
    	
    	updatedGaus.add(newgaus[4]);
    	updatedGaus.add(newgaus[5]);
    	
		update updatedGaus;  				

		logs = [select id, New_GAU_Allocation__c, Opportunity__c, Campaign__c, Action__c, User__c from GAU_Allocation_Change_Log__c];

		system.assertEquals(logs.size(), 2);
		
		logMap = new map<string, GAU_Allocation_Change_Log__c>();
		
		for (GAU_Allocation_Change_Log__c log:logs) {
			system.debug('log.New_GAU_Allocation__c - <' + log.New_GAU_Allocation__c +'>');
			logMap.put(log.New_GAU_Allocation__c, log);
				
		}

		GAUMap = new map<id,  npsp__General_Accounting_Unit__c>([select id, name from npsp__General_Accounting_Unit__c]);
		
		for (npsp__Allocation__c newgau:updatedGaus) {

    		string amount = string.valueOf(newgau.npsp__Amount__c);	
    		string percentage = string.valueOf(newgau.npsp__Percent__c.format());	

			npsp__General_Accounting_Unit__c gau = GAUMap.get(newgau.npsp__General_Accounting_Unit__c);

			system.debug('gau - <' + gau +'>');
				
			string gauName = gau.name;
			
			string keyVal = gauName + ' (£' + amount +' / ' + percentage + '%)';

			system.debug('keyVal - <' + keyVal +'>');
			
			GAU_Allocation_Change_Log__c thisLog = logMap.get(keyVal);
			
			system.assertEquals(thisLog.Opportunity__c, newgau.npsp__Opportunity__c);
			system.assertEquals(thisLog.Campaign__c, null);
			system.assertEquals(thisLog.Action__c, 'Edited');
			
			system.assertEquals(thisLog.User__c, UserInfo.getUserId());
			
		}
    }

    static testMethod void testLogDelete() {
    		
    	list<npsp__Allocation__c> newgaus = new list<npsp__Allocation__c>();
    	
		// Create an Account that Donations can be linked to
		Account testAccount = TestFactory.createAccount('Test Account');
		insert testAccount;

        //Create Contact
         Contact con = new Contact (firstname = 'john', lastname = 'test', AccountId = testAccount.id, Email = 'test@test.com');
    	 Insert con;
    	    	
    	Campaign testCampaign = TestFactory.createCampaign(); 
    	
    	insert testCampaign;
    	
    	list<npsp__General_Accounting_Unit__c> newGenAllocs = new list<npsp__General_Accounting_Unit__c>();
    	
    	List<Opportunity> opps = new List<Opportunity>();

    	npsp__General_Accounting_Unit__c newGenAccUnit = new npsp__General_Accounting_Unit__c();
    	newGenAccUnit.name = 'test';
		newGenAllocs.add(newGenAccUnit);
    	
    	for (integer i = 0; i<100;i++) {
    		
    		Opportunity newOpp = TestFactory.createDonation(testCampaign, Date.today().addDays(i), testAccount.id, con.Id, 'Paid');
    		newOpp.amount = 100 + 1;
    		opps.add(newOpp);

	    	newGenAccUnit = new npsp__General_Accounting_Unit__c();
	    	newGenAccUnit.name = 'test'  + i;
    		newGenAllocs.add(newGenAccUnit);
    	

    	}
    	
    	insert newGenAllocs;
    	
		insert opps;        

    	for (integer i = 0; i<100;i++) {
    		
    		npsp__Allocation__c newGAU = new npsp__Allocation__c();
    		
    		newGAU.npsp__Amount__c = opps[i].amount- (opps[i].amount/100) * i;
    		newGAU.npsp__Percent__c = 100-i;
    		newGAU.npsp__Opportunity__c = opps[i].id;
    		newGAU.npsp__General_Accounting_Unit__c = newGenAllocs[i].id;
    		
    		newgaus.add(newGAU);

    		newGAU = new npsp__Allocation__c();
    		
    		newGAU.npsp__Amount__c = (opps[i].amount/100) * i;
    		newGAU.npsp__Percent__c = i;
    		newGAU.npsp__Opportunity__c = opps[i].id;
    		newGAU.npsp__General_Accounting_Unit__c = newGenAllocs[i+1].id;
    		
    		newgaus.add(newGAU);
    	}
    	
		insert newgaus;        

		List<GAU_Allocation_Change_Log__c> logs = [select id, New_GAU_Allocation__c, Opportunity__c, Campaign__c, Action__c, User__c from GAU_Allocation_Change_Log__c];

		system.assertEquals(logs.size(), 200);
		
		map<string, GAU_Allocation_Change_Log__c> logMap = new map<string, GAU_Allocation_Change_Log__c>();
		
		for (GAU_Allocation_Change_Log__c log:logs) {
//			system.debug('log.New_GAU_Allocation__c - <' + log.New_GAU_Allocation__c +'>');
			logMap.put(log.New_GAU_Allocation__c, log);
				
		}
		
		map<id,  npsp__General_Accounting_Unit__c> GAUMap = new map<id,  npsp__General_Accounting_Unit__c>([select id, name from npsp__General_Accounting_Unit__c]);
		
		for (npsp__Allocation__c newgau:newgaus) {

    		string amount = string.valueOf(newgau.npsp__Amount__c);	
    		string percentage = string.valueOf(newgau.npsp__Percent__c.format());	

			npsp__General_Accounting_Unit__c gau = GAUMap.get(newgau.npsp__General_Accounting_Unit__c);

	//		system.debug('gau - <' + gau +'>');
				
			string gauName = gau.name;
			
			string keyVal = gauName + ' (£' + amount +' / ' + percentage + '%)';

//			system.debug('keyVal - <' + keyVal +'>');
			
			GAU_Allocation_Change_Log__c thisLog = logMap.get(keyVal);
			
			system.assertEquals(thisLog.Opportunity__c, newgau.npsp__Opportunity__c);
			system.assertEquals(thisLog.Campaign__c, null);
			system.assertEquals(thisLog.Action__c, 'Created');
			
			system.assertEquals(thisLog.User__c, UserInfo.getUserId());
			
		}
		
		delete logs;
		
		list<npsp__Allocation__c> updatedGaus = new list<npsp__Allocation__c>();
				
    	decimal total = newgaus[4].npsp__Amount__c + newgaus[5].npsp__Amount__c;

		system.debug('total - <' + total +'>');
		system.debug('newgaus[5].npsp__Amount__c - <' + newgaus[5].npsp__Amount__c +'>');
		system.debug('newgaus[5].npsp__Percent__c - <' + newgaus[5].npsp__Percent__c +'>');
		system.debug('newgaus[4].npsp__Amount__c - <' + newgaus[4].npsp__Amount__c +'>');
		system.debug('newgaus[4].npsp__Percent__c - <' + newgaus[4].npsp__Percent__c +'>');
		system.debug('(total *5/100) - <' + (total *5/100) +'>');
    		
    	newgaus[5].npsp__Amount__c = newgaus[5].npsp__Amount__c + (total *5/100);
    		
    	newgaus[4].npsp__Amount__c = newgaus[4].npsp__Amount__c - (total *5/100);

    	newgaus[5].npsp__Percent__c = newgaus[5].npsp__Percent__c + 5;
    		
    	newgaus[4].npsp__Percent__c= newgaus[4].npsp__Percent__c - 5;

		system.debug('newgaus[5].npsp__Amount__c - <' + newgaus[5].npsp__Amount__c +'>');
		system.debug('newgaus[5].npsp__Percent__c - <' + newgaus[5].npsp__Percent__c +'>');
		system.debug('newgaus[4].npsp__Amount__c - <' + newgaus[4].npsp__Amount__c +'>');
		system.debug('newgaus[4].npsp__Percent__c - <' + newgaus[4].npsp__Percent__c +'>');
    	
    	updatedGaus.add(newgaus[4]);
    	updatedGaus.add(newgaus[5]);
    	
		delete updatedGaus;  				

		logs = [select id, New_GAU_Allocation__c, Opportunity__c, Campaign__c, Action__c, User__c from GAU_Allocation_Change_Log__c];

		system.assertEquals(logs.size(), 2);
		
		logMap = new map<string, GAU_Allocation_Change_Log__c>();
		
		for (GAU_Allocation_Change_Log__c log:logs) {
			system.debug('log.New_GAU_Allocation__c - <' + log.New_GAU_Allocation__c +'>');
			logMap.put(log.New_GAU_Allocation__c, log);
				
		}

		GAUMap = new map<id,  npsp__General_Accounting_Unit__c>([select id, name from npsp__General_Accounting_Unit__c]);

		updatedGaus = [select id, npsp__Amount__c, npsp__Percent__c, npsp__General_Accounting_Unit__c, npsp__Opportunity__c from npsp__Allocation__c where isDeleted = true ALL ROWS];

		system.assertEquals(updatedGaus.size(), 2);
		
		for (npsp__Allocation__c newgau:updatedGaus) {

    		string amount = string.valueOf(newgau.npsp__Amount__c);	
    		string percentage = string.valueOf(newgau.npsp__Percent__c.format());	

			npsp__General_Accounting_Unit__c gau = GAUMap.get(newgau.npsp__General_Accounting_Unit__c);

			system.debug('gau - <' + gau +'>');
				
			string gauName = gau.name;
			
			string keyVal = gauName + ' (Deleted)';

			system.debug('keyVal - <' + keyVal +'>');
			
			GAU_Allocation_Change_Log__c thisLog = logMap.get(keyVal);
			
			system.assertEquals(thisLog.Opportunity__c, newgau.npsp__Opportunity__c);
			system.assertEquals(thisLog.Campaign__c, null);
			system.assertEquals(thisLog.Action__c, 'Deleted');
			
			system.assertEquals(thisLog.User__c, UserInfo.getUserId());
			
		}
    }
           
}