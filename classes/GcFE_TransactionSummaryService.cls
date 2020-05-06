/**
 * @description This contains the logic to update the Transaction Summary records and export them to a file
 * @author Eddie Bates
 * @date 22 January 2018
 * @copyright: Giveclarity.org, 2018
 **/
public with sharing class GcFE_TransactionSummaryService {
	private static Set<String> transSummaryFieldNames;

	public GcFE_TransactionSummaryService() {
		
	}

	// NB in the batch query then sort by the group ID to make processes quicker

	/** 
	 * @description Given a number of objects this uses the settings to generate Transaction Summary records
	 * @param Id The id of the Summary Header record related to these summaries
	 * @param List<sObject> List of the Transaction objects that should be summarised
	 * @param LogService 
	 **/
	public static void createUpdateSummaries(String exportSettingName, Id summaryHeaderId, List<sObject> transactionObjs, Gc_LogService logService) {

		// Set a save point to roll back to
		Savepoint sp = Database.setSavepoint();

		// Get the settings
		Transaction_Export_Settings__mdt exportSettings = getExportSettings(exportSettingName);

		// Get the group key fields
		List<String> groupFieldNames = new List<String>();
		for (String groupFieldName : exportSettings.Group_Fields__c.split(',')) {
			groupFieldNames.add(groupFieldName.trim());
		}

		
		// Loop through the transactions and get a set of the group keys
		Set<String> groupKeys = new Set<String>();
		for (sObject transObj : transactionObjs) {

			system.debug('transObj - ' + transObj);

			for (String groupFieldName : groupFieldNames) {

				system.debug('groupFieldName - <' + groupFieldName + '>');

				String grpKey = String.valueOf(transObj.get(groupFieldName));
				if (grpKey != null) {
					groupKeys.add(grpKey);
				}
			}
		}

		// Find any current Summary records for these group keys for the Summary Header and build this into a map by group key
		Map<String, Transaction_Summary__c> transactionSummariesByGroupKey = getTransactionSummaries(exportSettings, summaryHeaderId, groupKeys);

		// Loop through the Transactions 
		for (sObject transObj : transactionObjs) {
			// Loop through the groups
			for (String groupFieldName : groupFieldNames) {
				// Get the group key
				String grpKey = String.valueOf(transObj.get(groupFieldName));			

				system.debug('grpKey - ' + grpKey);
				system.debug('groupFieldName - ' + groupFieldName);
				// Try and find an existing Transaction Summary object or create a new one
				Transaction_Summary__c transSummary = transactionSummariesByGroupKey.get(grpKey);
				if (transSummary == null) {
					transSummary = new Transaction_Summary__c();
					transSummary.Transaction_Summary_Header__c = summaryHeaderId;
					transSummary.Group_ID__c = grpKey;
				}

				// Step through the mapped fields and add them to the Summary object
				for (Transaction_Export_Field_Mapping__mdt fieldMapping : exportSettings.Transaction_Export_Field_Mappings__r) {
					if (fieldMapping.Destination_Field_Name__c != null) {
						if (fieldMapping.Total__c == true) {
							// Get the current value
							Double currentValue = 0;
							if (transSummary.get(fieldMapping.Destination_Field_Name__c) != null) {
								currentValue = (Double)transSummary.get(fieldMapping.Destination_Field_Name__c);
							}

							//system.debug('currentValue - ' + currentValue);
							//system.debug('transObj.get(fieldMapping.Source_Field_Name__c) - ' + transObj.get(fieldMapping.Source_Field_Name__c));
							// Get the additional value
							Double addValue = transObj.get(fieldMapping.Source_Field_Name__c) == null ? 0 : (Double)transObj.get(fieldMapping.Source_Field_Name__c);
							//system.debug('addValue - ' + addValue);

							transSummary.put(fieldMapping.Destination_Field_Name__c, currentValue + addValue);
						} else if (fieldMapping.Source_Field_Name__c == null) {
							transSummary.put(fieldMapping.Destination_Field_Name__c, fieldMapping.Default_Value__c);
						} else {
							Object sourceVal = transObj.get(fieldMapping.Source_Field_Name__c);
							if (sourceVal != null) {
								transSummary.put(fieldMapping.Destination_Field_Name__c, sourceVal);	
							} else {
								transSummary.put(fieldMapping.Destination_Field_Name__c, fieldMapping.Default_Value__c);
							}
						}
					}

					// If there is a stamp field specified then update it here on the Opportunity
					if (fieldMapping.Stamp_Field_Name__c != null) {
						if (fieldMapping.Source_Field_Name__c == null) {
							transObj.put(fieldMapping.Stamp_Field_Name__c, fieldMapping.Default_Value__c);
						} else {
							transObj.put(fieldMapping.Stamp_Field_Name__c, transObj.get(fieldMapping.Source_Field_Name__c));		
						}
					}

				}		

				// Update the group
				transactionSummariesByGroupKey.put(grpKey, transSummary);

			}
		}

		// Upsert the records
		Upsert transactionSummariesByGroupKey.values();

		// Build a map of the lookup fields to update by the group name
		Map<String, String> summaryLookupByGroup = new Map<String, String>();
		if (exportSettings.Transaction_Summary_Field_Name__c != null) {
			List<String> summaryLookupFields = exportSettings.Transaction_Summary_Field_Name__c.split(',');	
			Integer i=0;
			for (String groupFieldName : groupFieldNames) {
				if (i>summaryLookupFields.size()-1) {
					summaryLookupByGroup.put(groupFieldNames[i],summaryLookupFields[0]); // Use this to cover possible setup errors
				} else {
					summaryLookupByGroup.put(groupFieldNames[i],summaryLookupFields[i]);
				}

				i++;
			}
		} 		

		// Step through and update the Transaction records
		for (sObject transObj : transactionObjs) {
			// Update the date
			if (exportSettings.Processed_Date_Field__c != null) {transObj.put(exportSettings.Processed_Date_Field__c, System.today());}

			// Update the status
			if (exportSettings.Processed_Status_Field__c != null) {
				// If this is a field name from the Opportunity then use the value from that. Otherwise assume it is just a text value
				if (exportSettings.Processed_Status_Value__c != null && exportSettings.Processed_Status_Value__c.endsWith('__c')) {
					transObj.put(exportSettings.Processed_Status_Field__c, transObj.get(exportSettings.Processed_Status_Value__c));
				} else {
					transObj.put(exportSettings.Processed_Status_Field__c, exportSettings.Processed_Status_Value__c);
				}
			}			

			// Loop through the groups and get the related Summary objects
			if (summaryLookupByGroup.size() > 0) {
				for (String groupFieldName : groupFieldNames) {
					// Get the group value
					String groupVal = String.valueof(transObj.get(groupFieldName));

					// Get the Summary record for this group
					if (groupVal != null) {
						Transaction_Summary__c transSummary = transactionSummariesByGroupKey.get(groupVal);

						// Stamp this link on the Transaction object
						transObj.put(summaryLookupByGroup.get(groupFieldName), transSummary.Id);
					}
					
				}
			}
		}

		// Try and update and catch and deal with the errors
		Database.SaveResult[] srList = Database.update(transactionObjs, false);

		// Loop through the results
		List<String> errorMessages = new List<String>();
		Integer errorCount = 0;
		Integer recordCount = 0;
		for (Database.SaveResult sr : srList) {
			if (sr.isSuccess() == false) {
				// Get the original Transaction record
				sObject transRecord = transactionObjs[recordCount];

				// Only write this as an error if it is less than 50
				if (errorCount < 50) {
					for (Database.Error err : sr.getErrors()) {
						errorMessages.add(err.getStatusCode() + ' : ' + err.getMessage() + ' (ObjectId : ' + transRecord.Id + ')');	
					}
				}

				// Update the error count (only count the first 50)
				errorCount++;

			}

			// Increment the count
			recordCount++;

		}

		// If there are any errors then log it and also revert back to the save point
		if (errorCount > 0) {

			// Revert to the save point
			Database.rollback(sp);

			// Add an error log with the details
			Gc_Log__c gcLog = logService.createErrorLog('DML Update Errors', String.join(errorMessages, GcFE_ExportFileService.NEWLINE), null, null);

			// Write out the logs
			logService.saveLogs();

		}

	}

	/**
	 * @description This returns the settings object and related field mappings
	 * @param String The developer name of the Export settings
	 * @return This returns the Export settings and related 
	 **/
	public static Transaction_Export_Settings__mdt getExportSettings(String exportName) {
		// Get the Export settings by name
		return getExportSettings(null, exportName);
	}

	/**
	 * @description This returns the settings object and related field mappings
	 * @param Id The id of the export settings
	 * @return This returns the export settings and related 
	 **/
	public static Transaction_Export_Settings__mdt getExportSettings(Id exportId) {
		// Get the export settings by name
		return getExportSettings(exportId, null);
	}	

	/**
	 * @description Given the selections from the user this returns a SOQL query statement
	 * @param String The name of the Export setting that should be used
	 * @param Date The Start Date for the query
	 * @param Date The End Date for the query
	 * @param List<String> The first Selection values
	 * @param List<String> The second Selection values
	 * @return String A SOQL statement
	 **/
	public static String getObjectQuery(String exportName, Date fromDate, Date toDate, List<String> selectionValues1, List<String> selectionValues2) {
		String query;

		// Get the Export setting details
		Transaction_Export_Settings__mdt exportSettings = getExportSettings(exportName);

		// Start the query
		query = 'SELECT ';

		// Build up a set of the fields to be queried
		Set<String> transactionFields = new Set<String>();
		transactionFields.add('Id');

		system.debug('transactionFields1 - ' + transactionFields);
		// Add the Transaction date to the query
		transactionFields.add(exportSettings.Transaction_Date_Field__c);

		system.debug('transactionFields2 - ' + transactionFields);
		// Add the optional selection fields
		if (exportSettings.Selection_1_Field_Name__c != null) {transactionFields.add(exportSettings.Selection_1_Field_Name__c);}
		if (exportSettings.Selection_2_Field_Name__c != null) {transactionFields.add(exportSettings.Selection_2_Field_Name__c);}

		// Add the group field names
		if (exportSettings.Group_Fields__c != null) {transactionFields.add(exportSettings.Group_Fields__c);	}

		system.debug('transactionFields4 - ' + transactionFields);
		// Add update fields 
		if (exportSettings.Processed_Date_Field__c != null) {transactionFields.add(exportSettings.Processed_Date_Field__c);}
		if (exportSettings.Transaction_Summary_Field_Name__c != null) {transactionFields.add(exportSettings.Transaction_Summary_Field_Name__c);}
		system.debug('transactionFields5 - ' + transactionFields);
		
        // Add the status update values fro completion and rollback if these are custom fields
		if (exportSettings.Processed_Status_Value__c != null && exportSettings.Processed_Status_Value__c.endsWith('__c')) {transactionFields.add(exportSettings.Processed_Status_Value__c);}
		if (exportSettings.Status_Rollback_Value__c != null && exportSettings.Status_Rollback_Value__c.endsWith('__c')) {transactionFields.add(exportSettings.Status_Rollback_Value__c);}
		system.debug('transactionFields6 - ' + transactionFields);
        
		// Step through the mapped fields 
		for (Transaction_Export_Field_Mapping__mdt fieldMapping : exportSettings.Transaction_Export_Field_Mappings__r) {
			system.debug('fieldMapping.Source_Field_Name__c - <' + fieldMapping.Source_Field_Name__c + '>');
			if (fieldMapping.Source_Field_Name__c != null) {transactionFields.add(fieldMapping.Source_Field_Name__c);}
			if (fieldMapping.Stamp_Field_Name__c != null) {transactionFields.add(fieldMapping.Stamp_Field_Name__c);}			
		}
		system.debug('transactionFields7 - ' + transactionFields);

		// Add the fields
		query += String.join(new List<String>(transactionFields), ',');

		// Add the FROM statement
		query += ' FROM ' + exportSettings.Transaction_Object_Name__c;

		// Add the date restrictions
		List<String> whereClauses = new List<String>();
		if (fromDate != null) {
			DateTime fromDateTime = DateTime.newInstance(fromDate.year(),fromDate.month(),fromDate.day());
			whereClauses.add(exportSettings.Transaction_Date_Field__c + '>=' + fromDateTime.format('yyyy-MM-dd'));
		}
		if (toDate != null) {
			DateTime toDateTime = DateTime.newInstance(toDate.year(),toDate.month(),toDate.day());
			whereClauses.add(exportSettings.Transaction_Date_Field__c + '<=' + toDateTime.format('yyyy-MM-dd'));
		}

		// Add the optional restrictions
		String whereClauseSelect1 = createOptionalWhereClause(exportSettings.Selection_1_Field_Name__c, selectionValues1, exportSettings.Selection_1_Default_Value__c);
		if (whereClauseSelect1 != null) {whereClauses.add(whereClauseSelect1);}

		String whereClauseSelect2 = createOptionalWhereClause(exportSettings.Selection_2_Field_Name__c, selectionValues2, exportSettings.Selection_2_Default_Value__c);
		if (whereClauseSelect2 != null) {whereClauses.add(whereClauseSelect2);}


		// Add additional where filter if specified
		if (exportSettings.Additional_Filter__c != null) {
			whereClauses.add(exportSettings.Additional_Filter__c);
		}

		// Build the where clause for the selections
		String whereClauseStr;
		if (whereClauses.size() > 0) {
			for (String clause : whereClauses) {
				if (whereClauseStr == null) {
					whereClauseStr = ' WHERE ' + clause;
				} else {
					whereClauseStr += ' AND ' + clause;
				}
			}
		}

		// Add the where clause to the query
		if (whereClauseStr != null && whereClauseStr != '') {
			query += whereClauseStr;	
		}
		system.debug('query - ' + query);
		
		return query;
	}

	/** 
	 * @description Get a where clause for an optional selection
	 * @param String The name of the field that the restriction is being applied to
	 * @param List<String> The selected values
	 * @param String The default value that should be used
	 * @return String The additional where clause
	 **/
	private static String createOptionalWhereClause(String fieldName, List<String> selectedValues, String defaultValue) {
		String whereClause;

		if (selectedValues != null) {
			// Convert the selected values to a set			
			Set<String> selectedValueSet = new Set<String>(selectedValues);

			// If the selected value is blank, but there is a default value then set that
			if (selectedValueSet.size() == 0 && defaultValue != null) {
				selectedValueSet.add(defaultValue);
			}

			// If there is a field name and either a selection string or a default value then proceed to build the string
			if (fieldName != null && selectedValueSet.size() != 0 && selectedValueSet.contains('all') == false) {
				// Convert the string back to a list so that it can be joined
				List<String> selectedValuesList = new List<String>(selectedValueSet);

				// Add the clause with an IN
				whereClause = fieldName + ' IN (\'' + String.join(selectedValuesList, '\',\'') + '\')';

			} 
		}
 
 		return whereClause;

	}

	/**
	 * @description This creates a CSV file with details from the Summarised records 
	 * @param Id The Summary Header record ID
	 * @return Id The ID of the attachment that has been created
	 **/
	public static Id createExportFile(Id summaryHeaderId) {
		String fileContents;
		Id attachmentId;

		// Get the export name from the Summary Header
		Transaction_Summary_Header__c summaryHeader = [SELECT Id, Status__c, Export_Name__c FROM Transaction_Summary_Header__c WHERE Id=:summaryHeaderId];

		// Get the Export setting details
		Transaction_Export_Settings__mdt exportSettings = getExportSettings(summaryHeader.Export_Name__c);

		// Get a map of the fields to be exported
		List<String> exportFields = exportSettings.Export_Fields__c.split(',');

		// Get all the Summary records and sort them by any sub-group ID
		//List<Transaction_Summary__c> transactionSummaries = getTransactionSummariesForHeader(summaryHeaderId, exportSettings.Sub_Group_Field_Name__c);
		String transactionSummaryQuery = getTransactionSummaryQuery(summaryHeaderId, exportSettings);

		system.debug('exportSettings.Export_File_Header_Row__c - ' + exportSettings.Export_File_Header_Row__c);
		
		// Create the file and add the header row
		fileContents = '\ufeff' +  exportSettings.Export_File_Header_Row__c == null ? '' : GcFE_ExportFileService.MergeText(exportSettings.Export_File_Header_Row__c, summaryHeader) + GcFE_ExportFileService.NEWLINE;

		system.debug('fileContents - <' + fileContents + '>');

		// Step through the Summary records
		String subGroupName;
		//for (Transaction_Summary__c transSummary : transactionSummaries) {
		for (Transaction_Summary__c transSummary : Database.query(transactionSummaryQuery)) {
			// Get the group name and add it to the file
			if (exportSettings.Sub_Group_Field_Name__c != null && subGroupName != (String)transSummary.get(exportSettings.Sub_Group_Field_Name__c)) {
				subGroupName = (String)transSummary.get(exportSettings.Sub_Group_Field_Name__c);

				// If there is a specific string then use that
				if (exportSettings.Sub_Group_Export_String_Field_Name__c != null) {
					fileContents += (String)transSummary.get(exportSettings.Sub_Group_Export_String_Field_Name__c) + GcFE_ExportFileService.NEWLINE;
				} else {
					fileContents += subGroupName + GcFE_ExportFileService.NEWLINE;		
				}

				
			}

			// Add the row to the file by stepping through the
			fileContents += GcFE_ExportFileService.getExportRow(transSummary,exportFields, exportSettings.Escape_String__c) + GcFE_ExportFileService.NEWLINE;

		}
 
		// Work out the file name
		String fileName = GcFE_ExportFileService.MergeText(exportSettings.Export_File_Name_Pattern__c, summaryHeader);
		String fileExtension = exportSettings.Export_File_Name_Extension__c == null ? 'csv' : exportSettings.Export_File_Name_Extension__c;

		// Create the file as an attachment and add it to the Summary Header
		Attachment attach = GcFE_ExportFileService.createAttachment(summaryHeaderId, fileContents, fileName, fileExtension, 'Export file produced on ' + System.today());
		insert attach;
 
		// Update the Summary Header status
		summaryHeader.Posted_Date__c = System.today();
		summaryHeader.Status__c = 'Posted';
		update summaryHeader;

		// Notify the user at this point, if required



		// Return the attachment ID
		return attach.Id;

	}

	/**
	 * @description This rolls back the export details
	 * @param Id The id of the Summary Header that is to be rolled back
	 * @param List<sObject> A list of Transaction Summaries to process
	 * 
	 *
	public static void rollbackTransactionSummaries(Id summaryHeaderId, List<sObject> transactionSummaryObjs, Gc_LogService logService) {

		// Set a save point to roll back to
		Savepoint sp = Database.setSavepoint();

		// Loop through and get the IDs of all of the transctaion suimmaries
		Set<Id> transactionSummaryIds = new Set<Id>();
		for (sObject obj : transcationSummaryObjs) {
			transactionSummaryIds.add(obj.Id);
		}

		// Get the Summary Header object along with the export setting
		Transaction_Summary_Header__c summaryHeader = [SELECT Id, Status__c, Export_Name__c FROM Transaction_Summary_Header__c WHERE Id=:summaryHeaderId];

		// Get the Export settings since this will have the key fields to set on opp
		Transaction_Export_Settings__mdt exportSettings = getExportSettings(summaryHeader.Export_Name__c);

		// Get the Transaction Summary lookup fields
		List<String> summaryLookupFields = new List<String>();
		if (exportSettings.Transaction_Summary_Field_Name__c != null) {
			summaryLookupFields = exportSettings.Transaction_Summary_Field_Name__c.split(',');
		}		

		// Build up fields to get from the Transaction objects
		Set<String> transactionFields = new Set<String>();
		transactionFields.add('id');
		if (exportSettings.Processed_Date_Field__c != null) {transactionFields.add(exportSettings.Processed_Date_Field__c);}
		if (exportSettings.Processed_Status_Field__c != null) {transactionFields.add(exportSettings.Processed_Status_Field__c);}
		for (String summaryLookupField : summaryLookupFields) {
			transactionFields.add(summaryLookupField);
		}
		
        // Add the rollback status value if this is a valid field name
		if (exportSettings.Status_Rollback_Value__c != null && exportSettings.Status_Rollback_Value__c.endsWith('__c')) {transactionFields.add(exportSettings.Status_Rollback_Value__c);}
        
		// Find all the Opportunities linked to these (NB Match on multipel lookup fields)
		String transQuery = 'SELECT ' + String.join(new List<String>(transactionFields), ',') + ' FROM ' + exportSettings.Transaction_Object_Name__c + ' WHERE ';
		String whereClause = '';		
		for (String summaryLookupField : summaryLookupFields) {
			if (whereClause != '') {
				whereClause += ' OR ';
			}
			whereClause += summaryLookupField + ' IN :transactionSummaryIds';
		}
		transQuery += whereClause == null ? '' : whereClause;
		system.debug('transQuery - ' + transQuery);
		List<sObject> transactions = Database.query(transQuery);

		// Loop through the Transactions and update key values
		for (sObject transObj : transactions) {
			// Reset the date field
			if (exportSettings.Processed_Date_Field__c != null) {transObj.put(exportSettings.Processed_Date_Field__c, null);}

			// Reset the status field to the new value
			if (exportSettings.Processed_Status_Field__c != null) {
				// If this is a field name from the opp then use the value from that. Otherwise assume it is just a text value
				if (exportSettings.Status_Rollback_Value__c != null && exportSettings.Status_Rollback_Value__c.endsWith('__c')) {
					transObj.put(exportSettings.Processed_Status_Field__c, transObj.get(exportSettings.Status_Rollback_Value__c));
				} else {
					transObj.put(exportSettings.Processed_Status_Field__c, exportSettings.Status_Rollback_Value__c);
				}
			}

			// Loop through any Summary fields and clear them
			for (String summaryLookupField : summaryLookupFields) {
				transObj.put(summaryLookupField, null);
			}

		}

		// Try and update and catch and deal with the errors
		Database.SaveResult[] srList = Database.update(transactions, false);

		// Loop through the results
		List<String> errorMessages = new List<String>();
		Integer errorCount = 0;
		Integer recordCount = 0;
		for (Database.SaveResult sr : srList) {
			if (sr.isSuccess() == false) {
				// Get the original transaction record
				sObject transRecord = transactions[recordCount];

				// Only write this as an error if it is less than 50
				if (errorCount < 50) {
					for (Database.Error err : sr.getErrors()) {
						errorMessages.add(err.getStatusCode() + ' : ' + err.getMessage() + ' (ObjectId : ' + transRecord.Id + ')');	
					}
				}

				// Update the error count (only count the first 50)
				errorCount++;

			}

			// Increment the count
			recordCount++;

		}

		// Log any errors then revert back to the save point
		if (errorCount > 0) {

			// Revert to the save point
			Database.rollback(sp);

			// Add an error log with the details
			Gc_Log__c gcLog = logService.createErrorLog('DML Update Errors', String.join(errorMessages, GcFE_ExportFileService.NEWLINE), null, null);

			// Write out the logs
			logService.saveLogs();

			// Throw an error

		} else {
			// Delete all of the Transaction Summaries
			delete transactionSummaryObjs;			
		}

	} */
	/**
	 * @description This rolls back the export details
	 * @param Id The id of the Summary Header that is to be rolled back
	 * @param List<sObject> A list of Transaction Summaries to process
	 * 
	 **/
	public static void rollbackTransactionSummaries(List<sObject> transactions, Transaction_Summary_Header__c summaryHeader, Gc_LogService logService) {
		// Set a save point to roll back to
		Savepoint sp = Database.setSavepoint();
		// Get the Export settings since this will have the key fields to set on opp
		Transaction_Export_Settings__mdt exportSettings = getExportSettings(summaryHeader.Export_Name__c);
		// Get the Transaction Summary lookup fields
		List<String> summaryLookupFields = new List<String>();
		if (exportSettings.Transaction_Summary_Field_Name__c != null) {
			summaryLookupFields = exportSettings.Transaction_Summary_Field_Name__c.split(',');
		}		
		// Loop through the Transactions and update key values
		for (sObject transObj : transactions) {
			// Reset the date field
			if (exportSettings.Processed_Date_Field__c != null) {transObj.put(exportSettings.Processed_Date_Field__c, null);}
			// Reset the status field to the new value
			if (exportSettings.Processed_Status_Field__c != null) {
				// If this is a field name from the opp then use the value from that. Otherwise assume it is just a text value
				if (exportSettings.Status_Rollback_Value__c != null && exportSettings.Status_Rollback_Value__c.endsWith('__c')) {
					transObj.put(exportSettings.Processed_Status_Field__c, transObj.get(exportSettings.Status_Rollback_Value__c));
				} else {
					transObj.put(exportSettings.Processed_Status_Field__c, exportSettings.Status_Rollback_Value__c);
				}
			}
			// Loop through any Summary fields and clear them
			for (String summaryLookupField : summaryLookupFields) {
				transObj.put(summaryLookupField, null);
			}
		}
		// Try and update and catch and deal with the errors
//		Database.SaveResult[] srList = new List<Database.SaveResult>();
		Database.SaveResult[] srList = Database.update(transactions, false);
		// Loop through the results
		List<String> errorMessages = new List<String>();
		Integer errorCount = 0;
		Integer recordCount = 0;
		for (Database.SaveResult sr : srList) {
			if (sr.isSuccess() == false) {
				// Get the original transaction record
				sObject transRecord = transactions[recordCount];
				// Only write this as an error if it is less than 50
				if (errorCount < 50) {
					for (Database.Error err : sr.getErrors()) {
						errorMessages.add(err.getStatusCode() + ' : ' + err.getMessage() + ' (ObjectId : ' + transRecord.Id + ')');	
					}
				}
				// Update the error count (only count the first 50)
				errorCount++;
			}
			// Increment the count
			recordCount++;
		}
		// Log any errors then revert back to the save point
		if (errorCount > 0) {
			// Revert to the save point
			Database.rollback(sp);
			// Add an error log with the details
			Gc_Log__c gcLog = logService.createErrorLog('DML Update Errors', String.join(errorMessages, GcFE_ExportFileService.NEWLINE), null, null);
			// Write out the logs
			logService.saveLogs();
			// Throw an error
		} 
	}
	/**
	 * @description This rolls back the export details
	 * @param Id The id of the Summary Header that is to be rolled back
	 * @param List<sObject> A list of Transaction Summaries to process
	 * 
	 **/
	public static string getRollbackTransactionQuery(Id summaryHeaderId) {
		List<sObject> transactionSummaryObjs = [SELECT Id FROM Transaction_Summary__c WHERE Transaction_Summary_Header__c=:summaryHeaderId];
		// Loop through and get the Ids of all the Transaction Summaries
		Set<Id> transactionSummaryIds = new Set<Id>();
		for (sObject obj : transactionSummaryObjs) {
			if ((obj.Id != null) && (String.isBlank(obj.Id) == false)) {
			system.debug('obj.Id - ' + obj.Id);
			transactionSummaryIds.add(obj.Id);
			}
		}
        List<String> transactionSummaryIdsList = new List<String>();
		for (Id objId : transactionSummaryIds) {
			transactionSummaryIdsList.add(objId);
		}
		String transQuery = '';
		if (transactionSummaryIdsList.size() != 0) {
		// Get the Summary Header object along with the export setting
		Transaction_Summary_Header__c summaryHeader = [SELECT Id, Status__c, Export_Name__c FROM Transaction_Summary_Header__c WHERE Id=:summaryHeaderId];
		// Get the Export settings since this will have the key fields to set on opp
		Transaction_Export_Settings__mdt exportSettings = getExportSettings(summaryHeader.Export_Name__c);
		// Get the Transaction Summary lookup fields
		List<String> summaryLookupFields = new List<String>();
		if (exportSettings.Transaction_Summary_Field_Name__c != null) {
			summaryLookupFields = exportSettings.Transaction_Summary_Field_Name__c.split(',');
		}		
		// Build up fields to get from the Transaction objects
		Set<String> transactionFields = new Set<String>();
		transactionFields.add('id');
		if (exportSettings.Processed_Date_Field__c != null) {transactionFields.add(exportSettings.Processed_Date_Field__c);}
		if (exportSettings.Processed_Status_Field__c != null) {transactionFields.add(exportSettings.Processed_Status_Field__c);}
		for (String summaryLookupField : summaryLookupFields) {
			transactionFields.add(summaryLookupField);
		}
        // Add the rollback status value if this is a valid field name
		if (exportSettings.Status_Rollback_Value__c != null && exportSettings.Status_Rollback_Value__c.endsWith('__c')) {transactionFields.add(exportSettings.Status_Rollback_Value__c);}
		// Find all the Opportunities linked to these (NB Match on multipel lookup fields)
			transQuery = 'SELECT ' + String.join(new List<String>(transactionFields), ',') + ' FROM ' + exportSettings.Transaction_Object_Name__c + ' WHERE ';
		String whereClause = '';		
		for (String summaryLookupField : summaryLookupFields) {
			if (whereClause != '') {
				whereClause += ' OR ';
			}
//			whereClause += summaryLookupField + ' IN :transactionSummaryIds';
            whereClause += summaryLookupField + ' IN (\'' + String.join(transactionSummaryIdsList,'\',\'') + '\')';
		}
		transQuery += whereClause == null ? '' : whereClause; 
		}
		else {
			transQuery = 'SELECT id FROM Account LIMIT 0';
		}
		system.debug('transQuery - ' + transQuery);
		return transQuery;
/*		List<sObject> transactions = Database.query(transQuery);
		// Loop through the Transactions and update key values
		for (sObject transObj : transactions) {
			// Reset the date field
			if (exportSettings.Processed_Date_Field__c != null) {transObj.put(exportSettings.Processed_Date_Field__c, null);}
			// Reset the status field to the new value
			if (exportSettings.Processed_Status_Field__c != null) {
				// If this is a field name from the opp then use the value from that. Otherwise assume it is just a text value
				if (exportSettings.Status_Rollback_Value__c != null && exportSettings.Status_Rollback_Value__c.endsWith('__c')) {
					transObj.put(exportSettings.Processed_Status_Field__c, transObj.get(exportSettings.Status_Rollback_Value__c));
				} else {
					transObj.put(exportSettings.Processed_Status_Field__c, exportSettings.Status_Rollback_Value__c);
				}
			}
			// Loop through any Summary fields and clear them
			for (String summaryLookupField : summaryLookupFields) {
				transObj.put(summaryLookupField, null);
			}
		}
		// Try and update and catch and deal with the errors
		Database.SaveResult[] srList = Database.update(transactions, false);
		// Loop through the results
		List<String> errorMessages = new List<String>();
		Integer errorCount = 0;
		Integer recordCount = 0;
		for (Database.SaveResult sr : srList) {
			if (sr.isSuccess() == false) {
				// Get the original transaction record
				sObject transRecord = transactions[recordCount];
				// Only write this as an error if it is less than 50
				if (errorCount < 50) {
					for (Database.Error err : sr.getErrors()) {
						errorMessages.add(err.getStatusCode() + ' : ' + err.getMessage() + ' (ObjectId : ' + transRecord.Id + ')');	
					}
				}
				// Update the error count (only count the first 50)
				errorCount++;
			}
			// Increment the count
			recordCount++;
		}
		// Log any errors then revert back to the save point
		if (errorCount > 0) {
			// Revert to the save point
			Database.rollback(sp);
			// Add an error log with the details
			Gc_Log__c gcLog = logService.createErrorLog('DML Update Errors', String.join(errorMessages, GcFE_ExportFileService.NEWLINE), null, null);
			// Write out the logs
			logService.saveLogs();
			// Throw an error
		} else {
			// Delete all of the Transaction Summaries
			delete transactionSummaryObjs;			
		}
*/
	}

	/********************************* PRIVATE METHODS ***************************/
	private static Transaction_Export_Settings__mdt getExportSettings(Id exportHeaderId, String exportHeaderName) {
		String soql = 'SELECT Id, DeveloperName, Additional_Filter__c, Export_Fields__c, Export_File_Header_Row__c, Export_File_Name_Pattern__c, Export_File_Name_Extension__c, Group_Fields__c, Processed_Date_Field__c, Rollback_Batch_Size__c, Summary_Batch_Size__c, ';
		soql += 'Selection_1_Ask_User__c, Selection_1_Default_Value__c, Selection_1_Field_Name__c, Selection_2_Ask_User__c, Selection_2_Default_Value__c, Selection_2_Field_Name__c, Escape_String__c, Sub_Group_Export_String_Field_Name__c, ';
		soql += 'Sub_Group_Field_Name__c, Transaction_Date_Field__c, Transaction_Object_Name__c, Transaction_Summary_Field_Name__c, Processed_Status_Field__c, Status_Rollback_Value__c, Processed_Status_Value__c, ';
		soql += '(SELECT Id, DeveloperName, Default_Value__c, Destination_Field_Name__c, Source_Field_Name__c, Stamp_Field_Name__c, Total__c FROM Transaction_Export_Field_Mappings__r)';
		soql += ' FROM Transaction_Export_Settings__mdt';

		// Add the where depending on the parameters
		if (exportHeaderId != null) {
			soql += ' WHERE Id=' + exportHeaderId;
		} else if (exportHeaderName != null) {
			//soql += ' WHERE DeveloperName=\'' + exportHeaderName + '\'';
			soql += ' WHERE DeveloperName=:exportHeaderName';
		}

		// Get the record
		List<Transaction_Export_Settings__mdt> exportSettings = Database.query(soql);
		if (exportSettings.size() > 0) {
			return exportSettings[0];
		} else {
			// Throw an error
			// TOODO
			return null;
		}
	}

	private static Map<String, Transaction_Summary__c> getTransactionSummaries(Transaction_Export_Settings__mdt exportSettings, Id summaryHeaderId, Set<String> groupKeys) {

		// Build up a SOQL for the transaction summary object
		String soql = 'SELECT ';

		// Add the fields
		Set<String> fieldNames = new Set<String>{'Id','Finance_Code__c','Group_ID__c','Total_Amount__c','Transaction_Summary_Header__c'};

		// Add the mapped fields
		for (Transaction_Export_Field_Mapping__mdt fieldMapping : exportSettings.Transaction_Export_Field_Mappings__r) {
			if (fieldMapping.Destination_Field_Name__c != null) {fieldNames.add(fieldMapping.Destination_Field_Name__c);}
		}		

		// Add to the soql statement
		soql += String.join(new List<String>(fieldNames), ',');

		// Add the FROM statement
		soql += ' FROM Transaction_Summary__c';		

		// Add the WHERE statement
		soql += ' WHERE Transaction_Summary_Header__c=:summaryHeaderId AND Group_ID__c IN:groupKeys';

		// Get the transactions and put them into a map
		Map<String, Transaction_Summary__c> transactionsByGroupKey = new Map<String, Transaction_Summary__c>();
		List<Transaction_Summary__c> transactionSummaries = Database.Query(soql);
		for (Transaction_Summary__c transSummary : transactionSummaries) {

			system.debug('transSummary - ' + transSummary);
			
			transactionsByGroupKey.put(transSummary.Group_ID__c, transSummary);
		}

		// Return the map
		return transactionsByGroupKey;

	}

  //  private static List<Transaction_Summary__c> getTransactionSummariesForHeader(Id summaryHeaderId, String subGroupFieldName) {

		//// Get a set of field names
		//List<String> fieldNames = new List<String>(GcFE_ExportFileService.getObjectFieldNames('Transaction_Summary__c'));

		//// Build up a query
		//String query = 'SELECT ' + String.join( fieldNames, ',' ) + ' FROM Transaction_Summary__c WHERE Transaction_Summary_Header__c=:summaryHeaderId ORDER BY ';		 

		//// Sort the results by sub-group (if it is there) and then by original group ID
		//query += subGroupFieldName == null ? '' : subGroupFieldName + ',';
		//query += 'Group_ID__c';

		//// Return the results
		//return Database.query(query);

  //  }

    /**
     * @description This builds up a query to get all of the Transaction Summary record and required fields for a given header
     * @param Id The ID of the transaction summary header
     * @param Transaction_Export_Settings__mdt The export settings
     * @return String The query to get the objects
     **/
    private static String getTransactionSummaryQuery(Id summaryHeaderId, Transaction_Export_Settings__mdt exportSettings) {

		// Get a set of field names for the transaction summary
		Set<String> fieldNames = GcFE_ExportFileService.getObjectFieldNames('Transaction_Summary__c');
		Set<String> fieldNamesLowerCase = new Set<String>();
		for (String fldName : fieldNames) {
			fieldNamesLowerCase.add(fldName.toLowerCase());
		}

		// Create a list of the fields that are listed on the export settings
		Set<String> fieldsToGet = new Set<String>();
		fieldsToGet.add('id');

		// Loop through the export fields and add them if they are valid
		List<String> exportFields = exportSettings.Export_Fields__c.split(',');
		for (String exportFieldName : exportFields) {
			if(fieldNamesLowerCase.contains(exportFieldName.toLowerCase())) {
				fieldsToGet.add(exportFieldName);
			}
		}

		// If there is a Sub Group Field then add this
		if (exportSettings.Sub_Group_Field_Name__c != null && fieldNamesLowerCase.contains(exportSettings.Sub_Group_Field_Name__c.toLowerCase())) {
			fieldsToGet.add(exportSettings.Sub_Group_Field_Name__c);
		}

		// If there is a Sub Group Expotr String Field then add this
		if (exportSettings.Sub_Group_Export_String_Field_Name__c != null && fieldNamesLowerCase.contains(exportSettings.Sub_Group_Export_String_Field_Name__c.toLowerCase())) {
			fieldsToGet.add(exportSettings.Sub_Group_Export_String_Field_Name__c);
		}

		// Convert the set to a list
		List<String> fieldNamesToGetList = new List<String>(fieldsToGet);

		// Build up a query
		String query = 'SELECT ' + String.join(fieldNamesToGetList, ',' ) + ' FROM Transaction_Summary__c WHERE Transaction_Summary_Header__c=:summaryHeaderId ORDER BY ';		 

		// Sort the results by sub-group (if it is there) and then by original group ID
		query += exportSettings.Sub_Group_Field_Name__c == null ? '' : exportSettings.Sub_Group_Field_Name__c + ',';
		query += 'Group_ID__c';

		system.debug('query - ' + query);
		
		// Return the query
		return query;
		//return Database.query(query);    	

    }

}