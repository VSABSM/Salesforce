/*
* @description: Test ProcessControl class
* @author: Stuart Garner, Giveclarity  
* @date:19/03/2017 
*/
@isTest
public with sharing class ProcessControlTest {

    private static Process_Control__c pcSettings;
    
    public static void setup(){
        //Create custom settings
        pcSettings = Process_Control__c.getInstance();
        pcSettings.Contact_Trigger__c=false;
        pcSettings.Account_Trigger__c=true;
        pcSettings.Opportunity_Trigger__c=true;
        upsert pcSettings;
    }

    /*
    @description: Test that the disabled check returns the correct default values
    */  
    public static testMethod void DisabledCheckDefaults(){
        setup();
        system.assertEquals(true, processControl.isDisabled('Contact_Trigger__c')); 
        system.assertEquals(false, processControl.isDisabled('Account_Trigger__c'));
        system.assertEquals(false, processControl.isDisabled('Opportunity_Trigger__c'));            
    }

    /*
    @description: Test that when settings are updated this will not affect settings in the current transaction 
    */  
    public static testMethod void testUpdateOfSettings(){
        setup();
        system.assertEquals(true, processControl.isDisabled('Contact_Trigger__c')); 
        system.assertEquals(false, processControl.isDisabled('Account_Trigger__c'));
        system.assertEquals(false, processControl.isDisabled('Opportunity_Trigger__c'));                                
        pcSettings.Account_Trigger__c=true;
        upsert pcSettings;
        system.assertEquals(true, processControl.isDisabled('Contact_Trigger__c')); 
        system.assertEquals(false, processControl.isDisabled('Account_Trigger__c'));
        system.assertEquals(false, processControl.isDisabled('Opportunity_Trigger__c'));                                            
    }

    /*
    @description: Test that settings can be updated in processControlMap (within the scope of a transaction)
    */  
    public static testMethod void SetEnabled(){
        setup();
        system.assertEquals(true, processControl.isDisabled('Contact_Trigger__c')); 
        system.assertEquals(false, processControl.isDisabled('Account_Trigger__c'));
        system.assertEquals(false, processControl.isDisabled('Opportunity_Trigger__c'));
        processControl.hasRunOnce('Contact_Trigger__c');
        processControl.hasRunOnce('Account_Trigger__c');
        system.assertEquals(true, processControl.isDisabled('Contact_Trigger__c'));
        system.assertEquals(true, processControl.isDisabled('Account_Trigger__c'));
        Test.StartTest();
            processControl.setEnabled('Contact_Trigger__c');    
            processControl.setEnabled('Account_Trigger__c');
        Test.StopTest();    
        //Contact trigger remains disabled as it was it was defaulted to disabled in the CS; don't want processes to enalbe triggers where they have been switched off
        system.assertEquals(true, processControl.isDisabled('Contact_Trigger__c')); 
        system.assertEquals(false, processControl.isDisabled('Account_Trigger__c'));
        system.assertEquals(false, processControl.isDisabled('Opportunity_Trigger__c'));                                                    
    }

    /*
    @description: Test that having made changes to processControl map in apex the defaults can be restored
    */  
    public static testMethod void ResetAllDefaults(){
        setup();
        system.assertEquals(true, processControl.isDisabled('Contact_Trigger__c')); 
        system.assertEquals(false, processControl.isDisabled('Account_Trigger__c'));
        system.assertEquals(false, processControl.isDisabled('Opportunity_Trigger__c'));
        processControl.hasRunOnce('Contact_Trigger__c');
        processControl.hasRunOnce('Account_Trigger__c');
        system.assertEquals(true, processControl.isDisabled('Contact_Trigger__c'));
        system.assertEquals(true, processControl.isDisabled('Account_Trigger__c'));
        Test.StartTest();
            processControl.resetAllDefaults();  
        Test.StopTest();    
        //Contact trigger remains disabled as it was it was defaulted to disabled in the CS; don't want processes to enalbe triggers where they have been switched off
        system.assertEquals(true, processControl.isDisabled('Contact_Trigger__c')); 
        system.assertEquals(false, processControl.isDisabled('Account_Trigger__c'));
        system.assertEquals(false, processControl.isDisabled('Opportunity_Trigger__c'));                                                    
    }
    
    /*
    @description: Test that all the process can be switched off in code in one go 
    */      
    public static testMethod void testSetAllDisabled(){
        setup();
        system.assertEquals(true, processControl.isDisabled('Contact_Trigger__c')); 
        system.assertEquals(false, processControl.isDisabled('Account_Trigger__c'));
        system.assertEquals(false, processControl.isDisabled('Opportunity_Trigger__c'));
        Test.StartTest();
            processControl.setAllDisabled();    
        Test.StopTest();    
        //Contact trigger remains disabled as it was it was defaulted to disabled in the CS; don't want processes to enalbe triggers where they have been switched off
        system.assertEquals(true, processControl.isDisabled('Contact_Trigger__c')); 
        system.assertEquals(true, processControl.isDisabled('Account_Trigger__c'));
        system.assertEquals(true, processControl.isDisabled('Opportunity_Trigger__c'));                                                 
    }

    /*
    @description: Test that a process name not found will generate an exception 
    */                  
    public static testMethod void NameCheckExceptionHandling(){
        setup();
        Exception ex;
        try{
            ProcessControl.processNameCheck('xxxxxxx');
            
        }catch(exception e){
            ex=e;
        }
        system.assertNotEquals(null,ex);
        system.assertEquals(ex.getMessage(), 'Process Control xxxxxxx not found in processControlMap');
    }

    /*
    @description: Test settings for a particular user 
    */
    public static testMethod void UserSettings(){    
        setup();
        Profile p = [SELECT Id FROM Profile WHERE Name='Standard User']; 
        User u = new User(Alias = 'testPC', Email='test@testpc.com', 
        EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US', 
        LocaleSidKey='en_US', ProfileId = p.Id,
        TimeZoneSidKey='GMT', UserName='test@testtpc.com');
        insert u;
          
        System.runAs(u) {
            pcSettings = Process_Control__c.getInstance();
            pcSettings.Account_Trigger__c=false;
            upsert pcSettings;          
            pcSettings = Process_Control__c.getInstance();
            system.assertEquals(false,pcSettings.get('Account_Trigger__c'));
            system.assertEquals(true, processControl.isDisabled('Account_Trigger__c'));     
        }                               
    }

    /*
    @description: Test exception handling where a process does not appear in the map
    */
    public static testMethod void FieldMissingFromMapExceptionHandling(){    
        Exception e;
        setup();
        ProcessControl.initialiseMap();
        ProcessControl.processControlMap.remove('Contact_Trigger__c');
        try{
            processControl.isDisabled('Contact_Trigger__c');
        }catch(Exception ex){
            e=ex;
        }   
        system.assertEquals('Process Control Contact_Trigger__c not found in processControlMap', e.getMessage());
    }
}