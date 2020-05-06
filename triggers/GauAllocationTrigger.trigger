trigger GauAllocationTrigger on npsp__Allocation__c (after delete, after insert, after update, before delete, before insert, before update) {


	If (Trigger.isAfter) {
		if (Trigger.isInsert) {
		    AllocationTriggerHandler.handleAfterInsert(Trigger.new);
		}    
		    
		    
		if (Trigger.isUpdate) {
		    AllocationTriggerHandler.handleAfterUpdate(Trigger.new);
		}
		 
		if (Trigger.isDelete) {
		    AllocationTriggerHandler.handleAfterDelete(Trigger.old);
		}
	
	}    
}