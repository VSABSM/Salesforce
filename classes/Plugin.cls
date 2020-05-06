/**
* @description Enables the insertion of plugins from local code into the managed package logic
* @author Liam Collerton
* @date 12/04/2018
**/
global with sharing class Plugin { 
    public class PluginException extends Exception{}
    public interface IDefault {} // Marker Interface

    /**
    * @description Retrieves a list of instances of a plugin class for a specified plugin key
    * @author Liam Collerton
    * @date 12/04/2018
    * @param String pluginKey
    * @return Object
    **/
    @TestVisible private static List<Object> getInstance(String pluginKey, Transaction_Export_Settings__mdt exportSettings){
        List<Object> pluginInstances = new List<Object>();
   
		system.debug('pluginKey - ' + pluginKey);
		system.debug('plugins - ' + plugins);
		 
        if(!plugins.containsKey(pluginKey)){
            system.debug('No plugin found with key ' + pluginKey);
        } else { 
            // Generate list of active implementations of a plugin
            for (Export_to_Finance_Plugin__mdt plugin : plugins.get(pluginKey)) {
            	
	//			system.debug('plugin.Transaction_Export_Settings__r.DeveloperName - ' + plugin.Transaction_Export_Settings__r.DeveloperName);
	//			system.debug('exportSettings.DeveloperName - ' + exportSettings.DeveloperName);
            	
                if ((plugin.Active__c) && ((exportSettings == null) || (plugin.Transaction_Export_Settings__c == null) || (plugin.Transaction_Export_Settings__r.DeveloperName == exportSettings.DeveloperName))) {
                    Type t = Type.forName(plugin.Namespace__c, plugin.Class__c);
                    if (t == null) {
                        String message = 'Plugin with key \'' + pluginKey + '\', namespace \'' + plugin.Namespace__c + '\' & class \'' + plugin.Class__c + '\' not found';
                        system.debug(message);
                        throw new PluginException(message);
                    }

                    pluginInstances.add(t.newInstance());
                }
            } 
        }

        return pluginInstances;
    }

    // Allow injection of Custom Metadata from test class and store Custom Metadata as static variable
    @TestVisible private static List<Export_to_Finance_Plugin__mdt> pluginList {
        get {
            if (pluginList == null) {
                pluginList = [SELECT Plugin_Key__c, Transaction_Export_Settings__c, Transaction_Export_Settings__r.DeveloperName, Namespace__c, Class__c, Active__c FROM Export_to_Finance_Plugin__mdt WHERE Active__c = TRUE];
            } 
            return pluginList;
        } set; 
    }
 
    private static Map<String, List<Export_to_Finance_Plugin__mdt>> plugins {
        get {
            if (plugins == null) {
                plugins = new Map<String, List<Export_to_Finance_Plugin__mdt>>();

				
                // Select and group plugins by Plugin Key
                List<Export_to_Finance_Plugin__mdt> pluginList = pluginList;
                for (Export_to_Finance_Plugin__mdt plugin : pluginList) {
                    List<Export_to_Finance_Plugin__mdt> pluginsForKey = new List<Export_to_Finance_Plugin__mdt>();
                    if (plugins.containsKey(plugin.Plugin_Key__c)) {
                        pluginsForKey = plugins.get(plugin.Plugin_Key__c);
                    }
                    pluginsForKey.add(plugin);

                    plugins.put(plugin.Plugin_Key__c, pluginsForKey);
                }
            }
            return plugins;
        } set;
    }

    /**** START PLUGINS ****/

    /** IETFClaimBatchPreExecute **/
    public static final String PLUGIN_KEY_CLARITY_BANKING_BATCH_PRE_EXECUTE = 'IETFBatchPreExecute';

    public static List<Plugin.IETFBatchPreExecute> getInstanceIETFBatchPreExecute(){
        List<Plugin.IETFBatchPreExecute> plugins = new List<Plugin.IETFBatchPreExecute>();

        List<Object> pluginObjects = getInstance(PLUGIN_KEY_CLARITY_BANKING_BATCH_PRE_EXECUTE, null);

        for(Object plugin : pluginObjects){
            plugins.add((Plugin.IETFBatchPreExecute) plugin);
        }

		system.debug('Returning - ' + plugins);
		
        return plugins;
    }

    public static List<Plugin.IETFBatchPreExecute> getInstanceIETFBatchPreExecute(Transaction_Export_Settings__mdt exportSettings){
        List<Plugin.IETFBatchPreExecute> plugins = new List<Plugin.IETFBatchPreExecute>();

        List<Object> pluginObjects = getInstance(PLUGIN_KEY_CLARITY_BANKING_BATCH_PRE_EXECUTE, exportSettings);

        for(Object plugin : pluginObjects){
            plugins.add((Plugin.IETFBatchPreExecute) plugin);
        }

		system.debug('Returning - ' + plugins);
		
        return plugins;
    }
    
    global interface IETFBatchPreExecute {
        void execute();
    }

    /** IETFClaimBatchPreFinish **/
    public static final String PLUGIN_KEY_CLARITY_BANKING_BATCH_PRE_FINISH = 'IETFBatchPreFinish';

    public static List<Plugin.IETFBatchPreFinish> getInstanceIETFBatchPreFinish(){
        List<Plugin.IETFBatchPreFinish> plugins = new List<Plugin.IETFBatchPreFinish>();

        List<Object> pluginObjects = getInstance(PLUGIN_KEY_CLARITY_BANKING_BATCH_PRE_FINISH, null);


 
        for(Object plugin : pluginObjects){
            plugins.add((Plugin.IETFBatchPreFinish) plugin);
        }

        return plugins;
    }

    public static List<Plugin.IETFBatchPreFinish> getInstanceIETFBatchPreFinish(Transaction_Export_Settings__mdt exportSettings){
        List<Plugin.IETFBatchPreFinish> plugins = new List<Plugin.IETFBatchPreFinish>();

        List<Object> pluginObjects = getInstance(PLUGIN_KEY_CLARITY_BANKING_BATCH_PRE_FINISH, exportSettings);


 
        for(Object plugin : pluginObjects){
        	
             plugins.add((Plugin.IETFBatchPreFinish) plugin);
        	
        }

        return plugins;
    }
    
    global interface IETFBatchPreFinish {
        void execute();
    }


    /**** END PLUGINS ****/
}