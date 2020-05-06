/**
* @description Aids ClarityBankingBatchable and AutomatedRefundBatchable in passing values between the two batch classes
* @author Liam Collerton
* @date 26/04/2018
**/
 
public with sharing class ETFBatchableHelper {
    public class ETFBatchableHelperException extends exception{}

    //@description: Constructor to clone existing ETFBatchableHelper
    public ETFBatchableHelper(){
    }

    /**
    * @description Runs plugins and packaged pre-execute logic that repeats across all Clarity Gift Aid batches
    **/ 
    public static void ETFBatchPreExecute(Transaction_Export_Settings__mdt exportSettings){
    	    	
        // In most cases, we can switch off triggers, process builders, workflows etc on Opportunity to improve CB performance
        List<Plugin.IETFBatchPreExecute> plugins = Plugin.getInstanceIETFBatchPreExecute(exportSettings);
        for(Plugin.IETFBatchPreExecute plugin : plugins){
        	
            plugin.execute();
        }
    }

    /**
    * @description Runs plugins and packaged pre-finish logic that repeats across all Clarity Gift Aid batches
    **/
    public static void ETFBatchPreFinish(Transaction_Export_Settings__mdt exportSettings){
        // In most cases, we can switch off triggers, process builders, workflows etc on Opportunity to improve CGA performance
        List<Plugin.IETFBatchPreFinish> plugins = Plugin.getInstanceIETFBatchPreFinish(exportSettings);
        for(Plugin.IETFBatchPreFinish plugin : plugins){
            plugin.execute();
        }
    }




}