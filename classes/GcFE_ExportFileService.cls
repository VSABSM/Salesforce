/**
 * @description These are a number of procedures that help with the creation of files and attachments
 * @author Eddie Bates
 * @date 22 January 2018
 * @copyright: Giveclarity.org, 2018
 **/
public with sharing class GcFE_ExportFileService {
	private static Map<String, Set<String>> objectFieldNamesByObject = new Map<String, Set<String>>();

    // Constants
    public static final String NEWLINE = '\r\n';
    // Set up a date format
    public static String dateFormat = 'yyyy-MM-dd';

	public GcFE_ExportFileService() {
	}

    /**
     * @description This creates a new attachment object
     * @param Id The Id of the object that this will be linked to
     * @param String The contents of the file
     * @param String The name of the file
     **/
    public static Attachment createAttachment(Id parentId, String fileContents, String fileName, String fileExtension, String description) {
        
        // Create a new attachment file 
        Attachment attach = new Attachment();
        attach.isPrivate = false;
        attach.ParentId = parentId;
        attach.Description = description;
        attach.ContentType = 'text/csv; charset=UTF-8';

        if (fileContents != null) {
            // Save file contents to attachment
            Blob body = Blob.valueOf(fileContents);
        
            attach.Body = body;
            attach.Name = fileName + '.' + fileExtension;
        
        }
        
        // Return the attachment
        return attach;

    }

    /**
     * @description This steps through the given field names and creates an export row from the given object
     * @param sObject The object that is to be included in the row
     * @param List<String> A list of fields to be extracted from the object and added to the text
     * @param Boolean Determines whether the exported string should be escaped
     **/
    public static String getExportRow(sObject exportObj,List<String> exportFields, Boolean escapeString) {

    	// Get the sObject name from the id
    	String sObjName = exportObj.Id.getSObjectType().getDescribe().getName();

    	// Get the set of valid field names
    	Set<String> validExportFieldNames = getObjectFieldNames(sObjName);

		system.debug('sObjName - ' + sObjName);


		for (string s:validExportFieldNames) {
			system.debug('validExportFieldName - ' + s);
			
		}

    	// Step through the fields and export then to the row
    	String exportRow = '';
    	for (String exportField : exportFields) {
    		
    		system.debug('exportField - <' + exportField.toLowerCase() + '>');
    		
    		// Add a comma separator
    		exportRow += exportRow == '' ? '' : ',';

    		system.debug('validExportFieldNames.contains(exportField.toLowerCase()) - ' + validExportFieldNames.contains(exportField.toLowerCase()));

    		// If this is a valid field then get the value
    		if (validExportFieldNames.contains(exportField.toLowerCase().trim())) {
    			Object fieldVal = exportObj.get(exportField.toLowerCase().trim());

 		  		system.debug('fieldVal - ' + fieldVal);
 
    			// If the field value is null then skip it
    			if (fieldVal != null) {
    				String fieldValStr;
	    			if ((fieldVal instanceof Decimal) == true) {
    					Decimal fieldValDec = (Decimal)fieldVal;
    					fieldValStr = fieldValDec.stripTrailingZeros().toPlainString();
    				} else if ((fieldVal instanceof Date) == true) {
    					Date fieldValDate = Date.valueOf(fieldVal);
    					Datetime fieldValDateTime = Datetime.newInstance(fieldValDate.year(), fieldValDate.month(), fieldValDate.day());
    					fieldValStr = fieldValDateTime.format(dateFormat);    					
    				} else if ((fieldVal instanceof String) == false) {
    					fieldValStr = String.valueOf(fieldVal);
	    			} else {
    					fieldValStr = (String)fieldVal;
    				}

    				// Add to the row and escape it
    				if (escapeString == true) {
    					exportRow += fieldValStr.escapeCsv();
    				} else {
    					exportRow += fieldValStr;
    				}

    			}
    			else {
    				String fieldValStr;
	    			if ((fieldVal instanceof Decimal) == true) {
    					Decimal fieldValDec = 0;
    					fieldValStr = fieldValDec.stripTrailingZeros().toPlainString();
	    			} else {
    					fieldValStr = ' ';
    				}

    				// Add to the row and escape it
    				if (escapeString == true) {
    					exportRow += fieldValStr.escapeCsv();
    				} else {
    					exportRow += fieldValStr;
    				}
    			}
    		} else {
    			exportRow += exportField;
    		}
    	}

 		system.debug('exportRow - ' + exportRow);

    	return exportRow;

    }    

    /**
     * @description This returns a set of the field names for a given object
     * @param String The name of the object that is being queried
     * @return Set<String> A set of field names for the given object
     **/
    public static Set<String> getObjectFieldNames(String sObjectName) {

    	// If the set is not already populated then get it from the object
    	if (objectFieldNamesByObject.containsKey(sObjectName) == false) {
			Map<String, Schema.SObjectType> gd = Schema.getGlobalDescribe();

			// Get a map of all fields on the 'Transaction_Summary__c' object
			Map<String, Schema.SObjectField> fMap = Schema.getGlobalDescribe().get(sObjectName).getDescribe().Fields.getMap();

			// Get a list of all the field names
			objectFieldNamesByObject.put(sObjectName, new Set<String>(fMap.keySet()));

    	}

    	return objectFieldNamesByObject.get(sObjectName);

    }

    /**
     * @description This takes a source string and replaces merge tags '{!fieldname,format}' with values from the object
     * @param String The source string
     * @param SObject The object that contains the fields
     * @return String The string with merge fields replaced
     **/
	public static String MergeText(String source, SObject obj){
	    String s = '';      

		system.debug('source - ' + source);

	    if(source != null && obj != null){
	        Integer curPos = 0;
	        Pattern mergeField = Pattern.compile('\\{![a-zA-Z0-9_,\\.]*\\}');
	        Matcher m = mergeField.matcher(source);
	        while(m.find()){
	            //add the piece of text from the end of the previous match
	            //until the start of this one.
	            s += source.substring(curPos, m.start());


	            // Get the actual merge name (without {! })
	            String mergeName = source.substring(m.start()+2,m.end()-1);

	            // Extract the merge format, if there is one
	            String mergeFormat;
	            if (mergeName.contains(',')) {
	            	String[] mergeParameters = mergeName.split(',');
	            	mergeFormat = mergeParameters[1];
	            	mergeName = mergeParameters[0];
	            }

	            // Split the merge name to get the different relations as parts (i.e. if this is related to a parent field)
	            String[] relations = mergeName.split('\\.');

	            // Get the merge value and trap any fields that cannot be found
				String mergeValue = '';
	            try {
	            	// If this is a date/time reference then use a merge to find it
	            	if (relations[0].equalsIgnoreCase('today')) {
	            		Datetime nowDt = System.now();
	            		if (mergeFormat != null) {
	            			mergeValue = nowDt.format(mergeFormat);	
	            		} else {
	            			String.valueOf(System.today());
	            		}
	            		
	            	} else {
		                //iterate over the relations to get to the object that's needed.
		                SObject tmp = obj;
	    	            for(Integer i=0; i<relations.size()-1; i++){
	        	            tmp = tmp.getSObject(relations[i]);
	            	    }

		                //now get the value of the field
		                mergeValue = (String)tmp.get(relations[relations.size()-1]);

		            }

	            } catch(Exception ex){
	                mergeValue = '[Invalid merge field: ' + m.group() + ']';
	            }

	            // Add the merge value to the string
	            s += mergeValue;

	            // Move the current position
	            curPos = m.end();
	        }

	        // Add the end of the original string
	        s += source.substring(curPos);
	    }

		system.debug('s - ' + s);
		
	    return s;
	}


}