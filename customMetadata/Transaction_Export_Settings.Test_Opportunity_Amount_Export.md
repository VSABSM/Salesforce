<?xml version="1.0" encoding="UTF-8"?>
<CustomMetadata xmlns="http://soap.sforce.com/2006/04/metadata" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema">
    <label>Test Opportunity Amount Export</label>
    <protected>false</protected>
    <values>
        <field>Additional_Filter__c</field>
        <value xsi:nil="true"/>
    </values>
    <values>
        <field>Description__c</field>
        <value xsi:type="xsd:string">Finance Export:
This is used by the test scripts to validate the code and is therefore part of the code design of the export process
Grant Contract Number is just used at the group field since it can be written to when creating test data</value>
    </values>
    <values>
        <field>Escape_String__c</field>
        <value xsi:type="xsd:boolean">false</value>
    </values>
    <values>
        <field>Export_Fields__c</field>
        <value xsi:type="xsd:string">G,Finance_Code__c,,Total_Amount__c,Outcome__c</value>
    </values>
    <values>
        <field>Export_File_Header_Row__c</field>
        <value xsi:type="xsd:string">H,,,SRM Import DY{!Today,ddMMYY},,,</value>
    </values>
    <values>
        <field>Export_File_Name_Extension__c</field>
        <value xsi:nil="true"/>
    </values>
    <values>
        <field>Export_File_Name_Pattern__c</field>
        <value xsi:type="xsd:string">SRM Import DY{!Today,ddMMYY}</value>
    </values>
    <values>
        <field>Group_Fields__c</field>
        <value xsi:type="xsd:string">npsp__Grant_Contract_Number__c</value>
    </values>
    <values>
        <field>Is_Test__c</field>
        <value xsi:type="xsd:boolean">true</value>
    </values>
    <values>
        <field>Processed_Date_Field__c</field>
        <value xsi:type="xsd:string">Finance_Export_Date__c</value>
    </values>
    <values>
        <field>Processed_Status_Field__c</field>
        <value xsi:type="xsd:string">Finance_Export_Status__c</value>
    </values>
    <values>
        <field>Processed_Status_Value__c</field>
        <value xsi:type="xsd:string">Exported</value>
    </values>
    <values>
        <field>Rollback_Batch_Size__c</field>
        <value xsi:type="xsd:double">100.0</value>
    </values>
    <values>
        <field>Selection_1_Ask_User__c</field>
        <value xsi:type="xsd:boolean">true</value>
    </values>
    <values>
        <field>Selection_1_Default_Value__c</field>
        <value xsi:nil="true"/>
    </values>
    <values>
        <field>Selection_1_Field_Name__c</field>
        <value xsi:type="xsd:string">Payment_Method__c</value>
    </values>
    <values>
        <field>Selection_2_Ask_User__c</field>
        <value xsi:type="xsd:boolean">true</value>
    </values>
    <values>
        <field>Selection_2_Default_Value__c</field>
        <value xsi:nil="true"/>
    </values>
    <values>
        <field>Selection_2_Field_Name__c</field>
        <value xsi:type="xsd:string">Payment_Method__c</value>
    </values>
    <values>
        <field>Status_Rollback_Value__c</field>
        <value xsi:type="xsd:string">To Be Exported</value>
    </values>
    <values>
        <field>Sub_Group_Export_String_Field_Name__c</field>
        <value xsi:nil="true"/>
    </values>
    <values>
        <field>Sub_Group_Field_Name__c</field>
        <value xsi:type="xsd:string">Project__c</value>
    </values>
    <values>
        <field>Summary_Batch_Size__c</field>
        <value xsi:type="xsd:double">100.0</value>
    </values>
    <values>
        <field>Transaction_Date_Field__c</field>
        <value xsi:type="xsd:string">CloseDate</value>
    </values>
    <values>
        <field>Transaction_Object_Name__c</field>
        <value xsi:type="xsd:string">Opportunity</value>
    </values>
    <values>
        <field>Transaction_Summary_Field_Name__c</field>
        <value xsi:type="xsd:string">Transaction_Summary__c</value>
    </values>
</CustomMetadata>
