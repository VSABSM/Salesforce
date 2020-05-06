/**
 * @description This is used to create Log records
 * This implements the Singleton pattern so that only one is available per session
 * @author Eddie Bates
 * @date 22 January 2018
 * @copyright: Giveclarity.org, 2018
 **/
public with sharing class Gc_LogService {
	private static Gc_LogService instance = null; // This is the instance of this class to return each time the class is instantiated
	//public enum LogLevel {INFO, ERROR} // TODO
	private Integer errorLogCount = 0;
	private Integer infoLogCount = 0;
	private LogSettings oLogSettings;
	private List<Gc_Log__c> logs;
	private Id lookupObjectId;
	

	/**
	 * @description Make the constructor private to force the getInstance method to be used
	 * @param The name of the Log settings that this should use
	 * @param Id The Id of the Lookup Object
	 **/
	private Gc_LogService(String logSettingName, Id lookupObjectId) {
		this.oLogSettings = new LogSettings(logSettingName);
		this.lookupObjectId = lookupObjectId;
		if (logs == null) {
			logs = new List<Gc_Log__c>();	
		}
	}

	/**
	 * @description This either creates or finds a new instance of this service
	 * @param String The name of the settings that should be used
	 * @param Id The Id of the Lookup Object
	 **/
	public static Gc_LogService getInstance(String logSettingName, Id lookupObjectId) {
		if (instance == null) {
			instance = new Gc_LogService(logSettingName, lookupObjectId);
		}
		return instance;
	}

	/**
	 * @description This either creates or finds a new instance of this service
	 * @overload This overloads the main getinstance
	 **/
	public static Gc_LogService getInstance() {
		return getInstance(null,null);
	}

	/**
	 * @description This creates and returns a new Log object
	 * @param String The Subject
	 * @param String The Error Message
	 * @param Id The Object Id
	 * @return Gc_Log__c Returns the Log
	 **/
	public Gc_Log__c createInfoLog(String subjectStr, String fullMessage, Id objectId) {
		// Create a Log (this may not be saved)
		Gc_Log__c newLog = createLog('Information', 'Info: ' + subjectStr, fullMessage, objectId, null, null);

		// Check that the info Log count has not been exceeded
		if (this.oLogSettings.logLevel != 'Errors' && this.infoLogCount < this.oLogSettings.maxInfoLogs) {
			// Add the Log to the list
			logs.add(newLog);
		}

		// Returns the Logs, although info may not be saved or written to this
		this.infoLogCount++;
		return newLog;
	}

	/**
	 * @description This create and returns a new Log object
	 * @param String The type of Error
	 * @param String The Error Message
	 * @param Id The Object Id
	 * @param String The StackTrace message
	 * @return Gc_Log__c Returns the Log
	 **/
	public Gc_Log__c createErrorLog(String errorType, String fullMessage, Id objectId, String stackTrace) {
		// Create a Log (this may not be saved)
		Gc_Log__c newLog = createLog('Error', 'Error: ' + errorType, fullMessage, objectId, errorType, stackTrace);

		// Check that the info Log count has not been exceeded
		if (this.errorLogCount < this.oLogSettings.maxErrorLogs) {
			// Add the log to the list
			logs.add(newLog);
		}

		// Returns the Log, although info may not be saved or written to this
		this.errorLogCount ++;
		return newLog;

	}	

	/**
	 * @description When this is called any Logs that are in the list are written out. This can be used to avoid rollbacks
	 **/
	public void saveLogs() {

		if (logs.size() > 0) {
			insert logs;	

			// If notifications should be sent, then send thes out
			sendNotifications();

		}

		// Reset the logs list
		logs = new List<Gc_Log__c>();

	}


	/********************** PRIVATE METHODS *******************/
	private Gc_Log__c createLog(String logLevel, String subjectStr, String fullMessage, Id objectId, String errorType, String stackTrace) {
		Gc_Log__c newLog = new Gc_Log__c();
		newLog.Log_Level__c = logLevel;
		newLog.Log_Setting_Name__c = this.oLogSettings.settingsName;
		newLog.Datetime__c = System.now();
		newLog.Subject__c = subjectStr;
		newLog.Object_Id__c = objectId;
		newLog.Error_Type__c = errorType;
		newLog.Stack_Trace__c = stackTrace;
		newLog.Full_Message__c = fullMessage;
		
		// Set the lookup field if this is set
		if (this.lookupObjectId != null && this.oLogSettings.lookupFieldName != null) {
			// Wrap this in a try in case the field does not exist
			try {
				newLog.put(this.oLogSettings.lookupFieldName, this.lookupObjectId);
			} catch (Exception e) {
				// Do nothing 
				System.debug('Log Error: The lookup field name specified in the settings is not valid');
			}
		}		

		// If the Object Id has been supplied then record this
		if (objectId != null) {
			try {
				newLog.Object_Name__c = objectId.getSObjectType().getDescribe().getName();
			} catch (Exception e) {
				newLog.Object_Name__c = 'Invalid Object Id';
			}
		}

		return newLog;

	}

	private void sendNotifications() {

		// If notifications have been set then continue
		if (this.oLogSettings.sendNotifications == true) {
			// Loop through and send out notifications 


			// Update email sent on the logs


		}

	}

	/********************** INNER CLASS **********************/
	private class LogSettings {
		public String settingsName;
		public String notificationRecipients;
		public Boolean sendNotifications;
		public String logLevel;
		public String lookupFieldName;
		public Integer maxErrorLogs;
		public Integer maxInfoLogs;
		public Boolean rollbackChanges;

		/**
		 * @ddescription This either gets the settings or uses default values 
		 * @param String The name of the Log settings to retrieve
		 **/
		public LogSettings(String logSettingName) {
			// Set the default values
			this.sendNotifications = false;
			this.logLevel = 'Errors';
			this.maxErrorLogs = 10;
			this.maxInfoLogs = 10;
			this.rollbackChanges = true;

			// If settings have been specified then set them
			if (logSettingName != null) {
				// Use the setting name to find the meta data type for this setting
				List<Gc_Log_Settings__mdt> logSettingObjects = [SELECT Id, Error_Notification_Recipients__c, Error_Notifications__c, Log_Level__c, Lookup_Field_Name__c, Max_Error_Logs__c, 
																	Max_Information_Logs__c, Rollback_Changes__c
																		FROM Gc_Log_Settings__mdt
																		WHERE DeveloperName=:logSettingName];
				if (logSettingObjects.size() > 0) {
					this.settingsName = logSettingName;
					this.notificationRecipients = logSettingObjects[0].Error_Notification_Recipients__c;
					this.sendNotifications = logSettingObjects[0].Error_Notifications__c;
					this.logLevel = logSettingObjects[0].Log_Level__c;
					this.lookupFieldName = logSettingObjects[0].Lookup_Field_Name__c;
					this.maxErrorLogs = logSettingObjects[0].Max_Error_Logs__c == null ? 10 : (Integer)logSettingObjects[0].Max_Error_Logs__c;
					this.maxInfoLogs = logSettingObjects[0].Max_Information_Logs__c == null ? 10 : (Integer)logSettingObjects[0].Max_Information_Logs__c;
					this.rollbackChanges = logSettingObjects[0].Rollback_Changes__c;
				}

			}

		}

	}


}