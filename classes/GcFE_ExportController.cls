/**
 * @description This is the controller that supports the export quick action on the transaction summary header
 * @author Eddie Bates
 * @date 22 January 2018
 * @copyright: Giveclarity.org, 2018 
 **/
public with sharing class GcFE_ExportController {


	/**
	 * @description This calls the process to generate the file for this header
	 **/
	@AuraEnabled
	public static void exportTransactionSummaries(Id transactionSummaryHeaderId) {

		// Start the process to export the transactions
		try {
			GcFE_TransactionSummaryService.createExportFile(transactionSummaryHeaderId);
		} catch (Exception e) {
			throw new AuraHandledException('Error Found: ' + e.getMessage());
		}
		
	}

    /**
	 * @description This calls the process to get the Transaction Summary Header Name
	 **/
    @AuraEnabled
    public static Transaction_Summary_Header__c getSummaryHeader(Id transactionSummaryHeaderId) {
        // Perform isAccessible() checks here
        return [SELECT Id, Name FROM Transaction_Summary_Header__c WHERE Id=:transactionSummaryHeaderId];
    }


}