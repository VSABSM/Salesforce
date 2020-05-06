<?xml version="1.0" encoding="UTF-8"?>
<Workflow xmlns="http://soap.sforce.com/2006/04/metadata">
    <alerts>
        <fullName>npsp__Opportunity_Email_Acknowledgment</fullName>
        <description>Opportunity Email Acknowledgment</description>
        <protected>false</protected>
        <recipients>
            <field>npsp__Primary_Contact__c</field>
            <type>contactLookup</type>
        </recipients>
        <senderType>CurrentUser</senderType>
        <template>npsp__NPSP_Email_Templates/npsp__NPSP_Opportunity_Acknowledgment</template>
    </alerts>
    <fieldUpdates>
        <fullName>Set_Amount_to_Zero</fullName>
        <description>This field update sets the Opportunity Amount to a value of &apos;0&apos; (VSA-14).</description>
        <field>Amount</field>
        <formula>0</formula>
        <name>Set Amount to Zero</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Set_Donation_Net_Amount</fullName>
        <description>This field update updates the Amount field to the donation net amount when the donation is paid via Charity Checkout. The value in the Amount field must reflect the Amount CC will credit to VSA&apos;s account, to support financial reconciliation.</description>
        <field>Amount</field>
        <formula>cc_Donation_Net_Amount__c</formula>
        <name>Set Donation Net Amount</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Set_Opportunity_Name</fullName>
        <description>This field update sets the Opportunity Name, and includes a reference to the fact that the record that is being re-named is a &quot;Table&quot; or &quot;Ticket&quot; donation (VSA-35).</description>
        <field>Name</field>
        <formula>npsp__Primary_Contact__r.FirstName +&quot; &quot;+npsp__Primary_Contact__r.LastName+&quot; - &quot; + &quot;Donation (&quot;+ TEXT(Type)+&quot;) - &quot;+&quot;£&quot;+TEXT( Amount )+&quot; - &quot;+ Today_Date_as_DDMMYYYY__c</formula>
        <name>Set Opportunity Name</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>npsp__Opportunity_AcknowledgmentStatus_Update</fullName>
        <description>Sets the Acknowledgment Status to &quot;Acknowledged&quot;</description>
        <field>npsp__Acknowledgment_Status__c</field>
        <literalValue>Acknowledged</literalValue>
        <name>Opportunity Acknowledgment Status Update</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Literal</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>npsp__Opportunity_Acknowledgment_Date_Update</fullName>
        <description>sets the Acknowledgment Date to Today.</description>
        <field>npsp__Acknowledgment_Date__c</field>
        <formula>Today()</formula>
        <name>Opportunity Acknowledgment Date Update</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>npsp__Opportunity_Copy_FMV_to_Amount</fullName>
        <description>Copy the Opportunities Fair Market Value field to the Amount field.</description>
        <field>Amount</field>
        <formula>npsp__Fair_Market_Value__c</formula>
        <name>Opportunity Copy FMV to Amount</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
    </fieldUpdates>
    <rules>
        <fullName>npsp__Opportunity Copy FMV to Amount</fullName>
        <actions>
            <name>npsp__Opportunity_Copy_FMV_to_Amount</name>
            <type>FieldUpdate</type>
        </actions>
        <active>false</active>
        <booleanFilter>(1 OR 2) AND (3 AND 4)</booleanFilter>
        <criteriaItems>
            <field>Opportunity.Amount</field>
            <operation>equals</operation>
            <value>0</value>
        </criteriaItems>
        <criteriaItems>
            <field>Opportunity.Amount</field>
            <operation>equals</operation>
        </criteriaItems>
        <criteriaItems>
            <field>Opportunity.npsp__Fair_Market_Value__c</field>
            <operation>notEqual</operation>
            <value>0</value>
        </criteriaItems>
        <criteriaItems>
            <field>Opportunity.npsp__Fair_Market_Value__c</field>
            <operation>notEqual</operation>
        </criteriaItems>
        <description>Enable this rule to copy the Fair Market Value to the Amount field, when the Amount is zero or blank.</description>
        <triggerType>onCreateOrTriggeringUpdate</triggerType>
    </rules>
    <rules>
        <fullName>npsp__Opportunity Email Acknowledgment</fullName>
        <actions>
            <name>npsp__Opportunity_Email_Acknowledgment</name>
            <type>Alert</type>
        </actions>
        <actions>
            <name>npsp__Opportunity_AcknowledgmentStatus_Update</name>
            <type>FieldUpdate</type>
        </actions>
        <actions>
            <name>npsp__Opportunity_Acknowledgment_Date_Update</name>
            <type>FieldUpdate</type>
        </actions>
        <active>false</active>
        <description>Emails an acknowledgement to the Primary Contact for an Opportunity when the Acknowledgement Status is set to Email Acknowledgement Now.</description>
        <formula>TEXT(npsp__Acknowledgment_Status__c) = $Label.npsp__sendAcknowledgmentFireStatus &amp;&amp;  npsp__Primary_Contact__r.Email &lt;&gt; NULL &amp;&amp;  npsp__Primary_Contact__r.npsp__Do_Not_Contact__c &lt;&gt; True &amp;&amp;  npsp__Primary_Contact__r.HasOptedOutOfEmail &lt;&gt; True &amp;&amp;  npsp__Primary_Contact__r.npsp__Deceased__c &lt;&gt; True</formula>
        <triggerType>onCreateOrTriggeringUpdate</triggerType>
    </rules>
</Workflow>
