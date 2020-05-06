public with sharing class AllocationTriggerHandler {
  
    //After Insert
    public static void handleAfterInsert(List<npsp__Allocation__c> newAllocations) {
    	
		createLogs(newAllocations, 'Created');

    }

    //After Update
    public static void handleAfterUpdate(List<npsp__Allocation__c> newAllocations) {
	
		createLogs(newAllocations, 'Edited');
    
  	}    
    
    
    //After Delete
    public static void handleAfterDelete(List<npsp__Allocation__c> deletedAllocations) {

		createLogs(deletedAllocations, 'Deleted');
    
  	}    
    
    
    private static void createLogs(List<npsp__Allocation__c> newAllocations, string operation) {
    	
      	List<GAU_Allocation_Change_Log__c> newlogs = new List<GAU_Allocation_Change_Log__c>();
		set<Id> GAUIds = new set<Id>();

    	for (npsp__Allocation__c thisAllocation:newAllocations) {
    		
    		if (thisAllocation.npsp__General_Accounting_Unit__c != null) {
				GAUIds.add(thisAllocation.npsp__General_Accounting_Unit__c);
    		}
    	}

		map<id,  npsp__General_Accounting_Unit__c> GAUMap = new map<id,  npsp__General_Accounting_Unit__c>([select id, name from npsp__General_Accounting_Unit__c where id in :GAUIds]);
		   			      	 
    	for (npsp__Allocation__c thisAllocation:newAllocations) {
    		GAU_Allocation_Change_Log__c newLog = new GAU_Allocation_Change_Log__c();
    		
    		string gauName = '';
    		
    		if (thisAllocation.npsp__General_Accounting_Unit__c != null) {

				npsp__General_Accounting_Unit__c gau = GAUMap.get(thisAllocation.npsp__General_Accounting_Unit__c);
				
				if (gau != null) {
					gauName = gau.name;
				}
				
				 
    		}
    		
    		string amount = '0.00';
    		string percentage = '0.00';
    		
    		if (thisAllocation.npsp__Amount__c != null) {
    			amount = string.valueOf(thisAllocation.npsp__Amount__c);	
    		}

    		if (thisAllocation.npsp__Percent__c != null) {
    			percentage = string.valueOf(thisAllocation.npsp__Percent__c.format());	
    		}
    		
			if (operation == 'Deleted') {
				newLog.New_GAU_Allocation__c = gauName + ' (Deleted)';
				
			}   
			else { 		
				newLog.New_GAU_Allocation__c = gauName + ' (£' + amount +' / ' + percentage + '%)';
			}
			
			newLog.Opportunity__c = thisAllocation.npsp__Opportunity__c;
			newLog.Campaign__c = thisAllocation.npsp__Campaign__c;
			newLog.Action__c = operation;
			
			newLog.User__c = UserInfo.getUserId();
			
			newLogs.add(newLog);
    	} 
    	
    	insert newLogs;

    }    
    
}