<?xml version="1.0" encoding="UTF-8"?>
<CustomMetadata xmlns="http://soap.sforce.com/2006/04/metadata" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema">
    <label>VSA Export to Finance</label>
    <protected>false</protected>
    <values>
        <field>Additional_Filter__c</field>
        <value xsi:type="xsd:string">Finance_Export_Status__c = &apos;To Be Exported&apos; and Export_to_Finance_Not_Applicable__c != true</value>
    </values>
    <values>
        <field>Description__c</field>
        <value xsi:nil="true"/>
    </values>
    <values>
        <field>Escape_String__c</field>
        <value xsi:type="xsd:boolean">true</value>
    </values>
    <values>
        <field>Export_Fields__c</field>
        <value xsi:type="xsd:string">ST__c,VAT_Total__c,Doc_Type__c,Doc_Date__c,Jnl_Type__c,Description__c,Control_Code_Formula__c,Account_Code_Formula__c,Detailed_Description_Formula__c,Dr__c,Total_Amount_Formula__c,VAT_Code_Formula__c,Input_Output__c,Total_Amount_Formula__c,VAT_Formula__c</value>
    </values>
    <values>
        <field>Export_File_Header_Row__c</field>
        <value xsi:type="xsd:string">Journal Header,VAT Total, Doc Type, Doc Date, Jnl Type, Desc for posting header, Cost Code, Expense Code, Detailed Desc per line, Dr, CR, VAT Code, Input/Output, Goods, VAT</value>
    </values>
    <values>
        <field>Export_File_Name_Extension__c</field>
        <value xsi:nil="true"/>
    </values>
    <values>
        <field>Export_File_Name_Pattern__c</field>
        <value xsi:type="xsd:string">Finance Export {!Today,ddMMYY}</value>
    </values>
    <values>
        <field>Group_Fields__c</field>
        <value xsi:type="xsd:string">Finance_Summary_Group__c,Finance_Export_Group__c</value>
    </values>
    <values>
        <field>Is_Test__c</field>
        <value xsi:type="xsd:boolean">false</value>
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
        <value xsi:type="xsd:double">12.0</value>
    </values>
    <values>
        <field>Selection_1_Ask_User__c</field>
        <value xsi:type="xsd:boolean">false</value>
    </values>
    <values>
        <field>Selection_1_Default_Value__c</field>
        <value xsi:nil="true"/>
    </values>
    <values>
        <field>Selection_1_Field_Name__c</field>
        <value xsi:nil="true"/>
    </values>
    <values>
        <field>Selection_2_Ask_User__c</field>
        <value xsi:type="xsd:boolean">false</value>
    </values>
    <values>
        <field>Selection_2_Default_Value__c</field>
        <value xsi:nil="true"/>
    </values>
    <values>
        <field>Selection_2_Field_Name__c</field>
        <value xsi:nil="true"/>
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
        <value xsi:nil="true"/>
    </values>
    <values>
        <field>Summary_Batch_Size__c</field>
        <value xsi:type="xsd:double">12.0</value>
    </values>
    <values>
        <field>Transaction_Date_Field__c</field>
        <value xsi:type="xsd:string">Opportunity_Close_Date__c</value>
    </values>
    <values>
        <field>Transaction_Object_Name__c</field>
        <value xsi:type="xsd:string">npsp__Allocation__c</value>
    </values>
    <values>
        <field>Transaction_Summary_Field_Name__c</field>
        <value xsi:type="xsd:string">Transaction_Summary__c,Transaction_Group__c</value>
    </values>
</CustomMetadata>
