@isTest
public with sharing class PluginTest implements PluginTest.IPluginTest {

//	public static void addApplicationProperty(string logLevel) {

 //       	Clarity_Banking_Settings__c coreSettings = Clarity_Banking_Settings__c.getOrgDefaults();        

//	        coreSettings.Logging_Level__c = logLevel;
	        
//	        insert coreSettings;		

//	}
	
    /** IPluginTest **/
    // Define a plugin only to be used for test purposes
    public static final String PLUGIN_KEY_PLUGIN_TEST = 'IPluginTest';

    public static List<PluginTest.IPluginTest> getInstanceIPluginTest(Transaction_Export_Settings__mdt exportSettings){
        List<PluginTest.IPluginTest> plugins = new List<PluginTest.IPluginTest>();
  
        List<Object> pluginObjects = Plugin.getInstance(PLUGIN_KEY_PLUGIN_TEST, exportSettings);
        for(Object plugin : pluginObjects){ 
            plugins.add((PluginTest.IPluginTest) plugin);
        }

        return plugins;
    }

    public interface IPluginTest {
        Boolean pluginTest(Boolean result);
    }

    // Define a 'local' implementation of plugin
    public Boolean pluginTest(Boolean result){
        return result;
    } 
 
    /** GENERAL TEST METHODS **/
    private static testMethod void testInterfaceWithoutPlugins(){
   //     addApplicationProperty('DEBUG');
 		Transaction_Export_Settings__mdt exportSettings;

        Test.startTest();
        PluginTest.getInstanceIPluginTest(exportSettings);
        Test.stopTest();
 
//		Logger.flush();
//        List<Log__c> logs = [SELECT Message__c FROM Log__c];
//        System.assertEquals(1, logs.size());
//        System.assertEquals('No plugin found with key IPluginTest', logs[0].Message__c);
    }

    private static testMethod void testInterfaceWithIncorrectPlugin() {
        String plugins = '[{"' + 'Plugin_Key__c" : "IPluginTest", "'  + 'Namespace__c" : "", "' + 'Class__c" : "Fake", "'  + 'Active__c" : 1}]';
        Plugin.pluginList = (List<Export_to_Finance_Plugin__mdt>) JSON.deserialize(plugins, List<Export_to_Finance_Plugin__mdt>.class);
 		
 		Transaction_Export_Settings__mdt exportSettings;
 		system.debug('plugins - ' + plugins);
 
        Test.startTest();
        Boolean errorThrown = false;
        try {
            PluginTest.getInstanceIPluginTest(exportSettings);
        } catch(Plugin.PluginException e){ 
            errorThrown = true;
            System.assertEquals('Plugin with key \'IPluginTest\', namespace \'\' & class \'Fake\' not found', e.getMessage());
        }
        Test.stopTest();
        System.assert(errorThrown); 
    }
 
    private static testMethod void testInterfaceWithMultiplePlugins() {
        String plugins = '[';
        plugins = plugins + '{"'  + 'Plugin_Key__c" : "IPluginTest", "'  + 'Namespace__c" : "", "'  + 'Class__c" : "PluginTest", "'  + 'Active__c" : 1},';
        plugins = plugins + '{"'  + 'Plugin_Key__c" : "IPluginTest", "'  + 'Namespace__c" : "", "'  + 'Class__c" : "PluginTest", "'  + 'Active__c" : 1}';
        plugins = plugins + ']';
        Plugin.pluginList = (List<Export_to_Finance_Plugin__mdt>) JSON.deserialize(plugins, List<Export_to_Finance_Plugin__mdt>.class);
		Transaction_Export_Settings__mdt exportSettings;
 
        Test.startTest();
        List<PluginTest.IPluginTest> pluginList = PluginTest.getInstanceIPluginTest(exportSettings);
        System.assertEquals(2, pluginList.size());
        for(PluginTest.IPluginTest plugin : pluginList){
            System.assert(true, plugin.pluginTest(true));
        }

        List<Plugin.IETFBatchPreExecute> plugins2 = Plugin.getInstanceIETFBatchPreExecute();

        Test.stopTest();
    }

    /** PLUGIN TEST METHODS *
    private testMethod static void testGetInstanceIETFBatchPreExecute(){
        List<Plugin.IETFBatchPreExecute> plugins = Plugin.getInstanceIETFBatchPreExecute();
        System.assertEquals(1, plugins.size());
        System.debug('plugins - ' + plugins);
        System.assert(plugins.get(0) instanceof Plugin.IDefault); // Only the default should be returned
    }

    private testMethod static void testGetInstanceIETFBatchPreFinish(){
        List<Plugin.IETFBatchPreFinish> plugins = Plugin.getInstanceIETFBatchPreFinish();
        System.assertEquals(1, plugins.size());
        System.assert(plugins.get(0) instanceof Plugin.IDefault); // Only the default should be returned

    } */
}