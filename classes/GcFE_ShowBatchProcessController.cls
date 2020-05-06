/**
 * @description This is used to show the progress of batches
 * @author Eddie Bates
 * @date 22 January 2018
 * @copyright: Giveclarity.org, 2018
 **/
public with sharing class GcFE_ShowBatchProcessController {
    // Get the apex class ID for this export batch
    public Id exportBatchClassId {get; private set;}
    public Id rollbackBatchClassId {get; private set;}

    /**
     * @description This is used to show the progress of the Export and Rollback batches
     **/
	public GcFE_ShowBatchProcessController() {
        // Get the apex ID for the export batch process
        this.exportBatchClassId = [SELECT Name, Id FROM ApexClass WHERE Name = 'GcFE_TransactionSummaryBatch' LIMIT 1][0].id;		

        // Get the apex ID for the rollback batch process
        this.rollbackBatchClassId = [SELECT Name, Id FROM ApexClass WHERE Name = 'GcFE_TransactionSummaryRollbackBatch' LIMIT 1][0].id;		        

	}
}