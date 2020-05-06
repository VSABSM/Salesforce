/**
 * @description This class is used to generate objects required to build up test data. It is centralised in this factory class to ensure that
 * any changes to the object requirements only need to be made in one place
 **/
@isTest
public class TestFactory {
    private static Long counter = 0;    
    private static Product2 unrestrictedProduct;
    private static PricebookEntry pbEntry;
    
    //public static Id level3RecordTypeId = Schema.SObjectType.Campaign.getRecordTypeInfosByName().get('Level 3: Approach').getRecordTypeId();
    
    /**
     * @description This overloads the createCampaign method to allow them to be created with the default unrestricted product
     **/
    public static Campaign createCampaign() {
        
        // Get the unrestricted product
        Product2 prod = getUnrestrictedProduct();
        
        // Create and return a Campaign record
        return createCampaign(prod.Id);     
        
    }

    /**
     * @description This creates a new campaign record
     * @param Id The Id of the product that this should be linked to
     **/
    public static Campaign createCampaign(Id productId) {
        // Create a campaign with a product assicated with it
        Campaign campaign = new Campaign();
        campaign.IsActive = true;
        campaign.name = 'Test campaign No ' + counter;
        //campaign.RecordTypeId = level3RecordTypeId;
        //campaign.Channel__c= 'EM';
        //campaign.s360a__Product__c = productId;

        // Increment the counter
        counter++;
        
        return campaign;
                        
    }    

   /**
     * @description This will create but not insert an opportunity (donation)
     * @return Opportunity
     **/
    public static Opportunity createDonation(Campaign camp, Date closeDate, Id accId, Id contactId, String stageName) {
        //Create and return an opportunity        
        Opportunity opp = new Opportunity();
        opp.Name = 'Test opp';
        opp.CloseDate = closeDate; 
        opp.AccountId = accId;
        opp.CampaignId = camp.Id;
        opp.Amount = 10;
        //opp.currencyISOCode=currencyCode;
        opp.npsp__Primary_Contact__c = contactId;
        opp.StageName = stageName;
        //opp.RecordTypeId =Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Donation').getRecordTypeId();               
        return opp;        
    }     
     
    public static npe03__Recurring_Donation__c createMonthlyRecurringDonation(Id ContactId, Date StartDate, Decimal Amount, Id CampaignId){     

        npe03__Recurring_Donation__c r1 = new npe03__Recurring_Donation__c(); 
        r1.Name = 'test'; 
        r1.npe03__Installments__c = 12; 
        r1.npe03__Contact__c = ContactId; 
        r1.npe03__Amount__c = Amount; 
        r1.npe03__Installment_Period__c = 'Monthly'; 
        r1.npe03__Date_Established__c = StartDate; 
        r1.npe03__Schedule_Type__c = 'Multiply By'; 
        r1.npe03__Open_Ended_Status__c = 'Open'; 
        r1.npe03__Recurring_Donation_Campaign__c = CampaignId; 
        return r1;          
    }        
    
    /**
     * @description This creates a standard 'Unrestricted' product
     **/
    public static Product2 getUnrestrictedProduct() {
        if (unrestrictedProduct == null) {
            unrestrictedProduct = new Product2();   
            unrestrictedProduct.Name = 'Unresticted Donations';
            //unrestrictedProduct.Is_Tax_Eligible__c = true;
            insert unrestrictedProduct; 
            
            // Create a price book entry and link it to this product            
            pbEntry = new PricebookEntry();
            pbEntry.UnitPrice = 300;
            pbEntry.PriceBook2Id = Test.getStandardPricebookId();
            pbEntry.Product2Id = unrestrictedProduct.Id;
            pbEntry.IsActive = true;
            insert pbEntry;             

        }
        
        return unrestrictedProduct;
            
    }

 

    /**
     * @description This creates a test account
     **/
    public static Account createAccount(String name) {
        Account acc = new Account();
        acc.Name = name;
        acc.Type = 'Charity';
        acc.BillingPostalCode = 'AB12 1AA';
        acc.BillingCountry = 'United Kingdom';
        return acc;
    }

   


}