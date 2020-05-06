({
	doInit : function(component, event, helper) {
        // Prepare the action to load summary header record
        var action = component.get("c.getSummaryHeader");
        action.setParams({"transactionSummaryHeaderId": component.get("v.recordId")});

        // Configure response handler
        action.setCallback(this, function(response) {
            var state = response.getState();
            if(component.isValid() && state === "SUCCESS") {
                component.set("v.summaryHeader", response.getReturnValue());
            } else {
                console.log('Problem getting summary header, response state: ' + state);
            }
        });
        $A.enqueueAction(action);
    },
        
	handleStartRollback: function(component, event, helper) {
 
        // Create and call the background action
        var action = component.get("c.rollbackTransactionSummaries");
		action.setParams({"transactionSummaryHeaderId": component.get("v.recordId")});
        
        // Configure response handler
        action.setCallback(this, function(response) {
            var state = response.getState();
            if(component.isValid() && state === "SUCCESS") {
                //component.set("v.summaryHeader", response.getReturnValue());
            } else if (component.isValid() && state == "ERROR") {
				var errors = response.getError();
                if (errors) {
                    if (errors[0] && errors[0].message) {
                        component.set("v.message", errors[0].message);
                    }
                }
            } else {
                console.log('Problem rolling back transactions for summary header, response state: ' + state);
            }
        });
        $A.enqueueAction(action);        
        
		// Display a completion message
		var resultsToast = $A.get("e.force:showToast");
		resultsToast.setParams({
			"title": "Complete",
            "message": "The process has started. Please check the Batch Progress tab for details." 
		});
		resultsToast.fire();
 
        // Close the action panel
		var dismissActionPanel = $A.get("e.force:closeQuickAction");
		dismissActionPanel.fire();
	},
    
   	handleCancel: function(component, event, helper) {
    	$A.get("e.force:closeQuickAction").fire();
	}
    
})