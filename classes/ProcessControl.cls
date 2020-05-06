/*
* @description: A class to control access to triggers 
* This uses both custom settings and static variables to give control defaulted through settings 
* that can be also managed in code
* @author: Stuart Garner, Giveclarity
* @date:19/03/2017 
*/
public with sharing class ProcessControl {
    
    public class processControlException extends Exception{}

    public static Map<string,boolean> processControlMap;
    
    private static Map<string,boolean> processControlDefaultsMap;

    /*
    @description: Checks if access to a process is currently disabled 
    @param: string processName - the api name of the custom setting field used to control access to the process
    @return: boolean
    */
    public static boolean isDisabled(string processName){
        processNameCheck(processName);   
        return !processControlMap.get(processName); 
    }       

    /*
    @description: Recursion control for triggers; sets the trigger to be disabled once it has run for the first time
    @param: string processName - the api name of the custom setting field used to control access to the process
    @return: void  
    */
    public static void hasRunOnce(string processName){
        setDisabled(processName);
    }
        
    
    /*
    @description: Set the named process 
    @param: string processName - the api name of the custom setting field used to control access to the trigger
    @return: void  
    */
    public static void setDisabled(string processName){
        processNameCheck(processName);
        processControlMap.put(processName,false); 
    }

         
    /*
    @description: Checks if a trigger is currently disabled 
    @param: string processName - the api name of the custom setting field used to control access to the trigger
    @return: void  
    */   
    public static void setEnabled(string processName){
        processNameCheck(processName);
        if(processControlDefaultsMap.get(processName)==true){//only allow the flag to be changed if the default is enabled      
            processControlMap.put(processName,true);
        }
    }  

    /*
    @description: See all processes as disabled within this transaction 
    @param: none
    @return: void  
    */
    public static void setAllDisabled(){
        for(string processName:processControlMap.keySet()){         
            processControlMap.put(processName,false);
        }           
    } 

    /*
    @description: See all processes back to the users default values
    @param: none
    @return: void  
    */
    public static void resetAllDefaults(){
        processControlMap = processControlDefaultsMap.clone(); 
    } 
    
    //Creates a static map of the processes defined in the Process Control hierarchical setting and defaults to the values 
    //based on the current users setting     
    @testVisible private static void initialiseMap(){
        //create a static map of processes based on the fields defined in a the processControl hierarchical custom setting  
        processControlMap = new Map<string,boolean>();
        processControlDefaultsMap = new Map<string,boolean>();
        Map <String, Schema.SObjectField> fieldMap = Process_Control__c.sObjectType.getDescribe().fields.getMap();
        Process_Control__c pc = Process_Control__c.getInstance();//use getInstance so the hierarchy is respected
        for(schema.sobjectField fld:fieldMap.values()){         
            string fldname = fld.getDescribe().getName();
            if(fld.getDescribe().getType()==Schema.DisplayType.Boolean){
                if(pc.get(fldname)!=null){//For a new field the instance will not return a value unless an org wide setting has been updated
                    boolean defaultValue = boolean.valueOf(pc.get(fldname));
                    processControlMap.put(fldname,defaultValue);
                }else{
                    throw new processControlException('Process Control '+fldname+' not found in field map');
                }                               
            }
        }
       processControlDefaultsMap = processControlMap.clone();         
    }
    @testVisible private static void processNameCheck(string processName){
        if(processControlMap==null){
            initialiseMap();
        }
         if(processControlMap.get(processName)==null){
            throw new processControlException('Process Control '+processName+' not found in processControlMap');
        }           
    }  

    
    /**
     * @description: This method can be invoked from the Process Builder when the associated custom setting is set to switch off the process
     **/    
    @InvocableMethod
    public static void DoNothing() {}

}