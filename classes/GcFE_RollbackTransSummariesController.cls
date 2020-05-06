/**
 * @description This supports the process which starts the rollback process
 * @author Eddie Bates
 * @date 22 January 2018
 * @copyright: Giveclarity.org, 2018
 **/
public with sharing class GcFE_RollbackTransSummariesController {

    /**
     * @description This calls the process to generate the file for this header
     **/
    @AuraEnabled
    public static void rollbackTransactionSummaries(Id transactionSummaryHeaderId) {

        // Start the process to export the transactions
        try {
            // Create a rollback class
            GcFE_TransactionSummaryRollbackBatch rollbackBatch = new GcFE_TransactionSummaryRollbackBatch(transactionSummaryHeaderId);

            // Get the header and therefore the settings
            Transaction_Summary_Header__c summaryHeader = [SELECT Id, Export_Name__c 
                                                           FROM Transaction_Summary_Header__c 
                                                           WHERE Id=:transactionSummaryHeaderId];
            Integer batchSize = null;
            if (summaryHeader.Export_Name__c != null) {
                Transaction_Export_Settings__mdt exportSettings = GcFE_TransactionSummaryService.getExportSettings(summaryHeader.Export_Name__c);
                batchSize = (Integer)exportSettings.Rollback_Batch_Size__c;
            }
            
            // Execute the batch
            if (batchSize != null) {
                Database.executeBatch(rollbackBatch, batchSize);    
            } else {
                Database.executeBatch(rollbackBatch);    
            }
            

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