@isTest
private class gen_Auth0ControllerTests {
    
    //public static Auth0__c settings;
    public static Auth0_Setting__mdt settings;
    public static MultiStaticResourceCalloutMock mock1;
    public static MultiStaticResourceCalloutMock mock2;
    public static Id testUserId = gen_ScopeTestData.createTestUserWithScopes();
    
    static testMethod void getUserControlsCustomerProd() {
        
        Contact c = new Contact(
            FirstName = 'Test'
            , LastName = 'User'
            , Email = 'test@user.com'
            , Primary_Product_Interest__c = 'Oil'
            , User_Profile__c = 'Customer'
        );
        insert c;
        
        Test.startTest();
        gen_Auth0Controller.getUserCreationControls(c.Id, 'Genscape');
        Test.stopTest();
        
    }
    
    static testMethod void getUserControlsCustomerQA() {
        
        Contact c = new Contact(
            FirstName = 'Test'
            , LastName = 'User'
            , Email = 'test@user.com'
            , Primary_Product_Interest__c = 'Oil'
            , User_Profile__c = 'Customer'
        );
        insert c;
        
        Test.startTest();
        gen_Auth0Controller.getUserCreationControls(c.Id, 'Genscape-QA');
        Test.stopTest();
        
    }
    
    static testMethod void createNewUserProd() {    
        
        String tenant = 'Genscape';
        Auth0_Setting__mdt settings = [select audience__c, client_id__c, client_secret__c, auth_endpoint__c from Auth0_Setting__mdt where MasterLabel = :tenant];
        
        mock1 = new MultiStaticResourceCalloutMock();
        mock1.setStaticResource(settings.Auth_Endpoint__c, 'auth0_token');
        mock1.setStaticResource(settings.audience__c + 'users?q=app_metadata.salesforceId:"' + testUserId + '"', 'auth0_searchNotFound'); //First search should be NOT found
        mock1.setStaticResource(settings.Auth_Endpoint__c, 'auth0_token');
        mock1.setStaticResource(settings.audience__c + 'users', 'auth0_createUser');
        
        system.debug('Auth0Controller Tests - begin test');
        Test.setMock(HttpCalloutMock.class, mock1);
        Test.startTest();
        //Create user in Genscape (prod) tenant
        gen_Auth0Controller.createUser(testUserId, tenant); //First pass should be successful
        Test.stopTest();
        system.debug('Auth0Controller Tests - end test');
        
    }
    
    static testMethod void createNewUserQA() {    
        
        String tenant = 'Genscape-QA';
        Auth0_Setting__mdt settings = [select audience__c, client_id__c, client_secret__c, auth_endpoint__c from Auth0_Setting__mdt where MasterLabel = :tenant];
        
        mock1 = new MultiStaticResourceCalloutMock();
        mock1.setStaticResource(settings.Auth_Endpoint__c, 'auth0_token');
        mock1.setStaticResource(settings.audience__c + 'users?q=app_metadata.salesforceId:"' + testUserId + '"', 'auth0_searchNotFound'); //First search should be NOT found
        mock1.setStaticResource(settings.Auth_Endpoint__c, 'auth0_token');
        mock1.setStaticResource(settings.audience__c + 'users', 'auth0_createUser');
        
        system.debug('Auth0Controller Tests - begin test');
        Test.setMock(HttpCalloutMock.class, mock1);
        Test.startTest();
        //Create user in Genscape (prod) tenant
        gen_Auth0Controller.createUser(testUserId, tenant); //First pass should be successful
        Test.stopTest();
        system.debug('Auth0Controller Tests - end test');
        
    }
    
    static testMethod void createNewUserDev() {    
        
        String tenant = 'Genscape-Dev';
        Auth0_Setting__mdt settings = [select audience__c, client_id__c, client_secret__c, auth_endpoint__c from Auth0_Setting__mdt where MasterLabel = :tenant];
        
        mock1 = new MultiStaticResourceCalloutMock();
        mock1.setStaticResource(settings.Auth_Endpoint__c, 'auth0_token');
        mock1.setStaticResource(settings.audience__c + 'users?q=app_metadata.salesforceId:"' + testUserId + '"', 'auth0_searchNotFound'); //First search should be NOT found
        mock1.setStaticResource(settings.Auth_Endpoint__c, 'auth0_token');
        mock1.setStaticResource(settings.audience__c + 'users', 'auth0_createUser');
        
        system.debug('Auth0Controller Tests - begin test');
        Test.setMock(HttpCalloutMock.class, mock1);
        Test.startTest();
        //Create user in Genscape (prod) tenant
        gen_Auth0Controller.createUser(testUserId, tenant); //First pass should be successful
        Test.stopTest();
        system.debug('Auth0Controller Tests - end test');
        
    }
    
    static testMethod void createDuplicateUser() {

        Auth0_Setting__mdt settings = [select audience__c, client_id__c, client_secret__c, auth_endpoint__c from Auth0_Setting__mdt where MasterLabel = 'Genscape'];
        
        mock2 = new MultiStaticResourceCalloutMock();
        mock2.setStaticResource(settings.Auth_Endpoint__c, 'auth0_token');
        mock2.setStaticResource(settings.audience__c + 'users?q=app_metadata.salesforceId:"' + testUserId + '"', 'auth0_searchFound'); //Second search should be found
        
        system.debug('Auth0Controller Tests - begin test');
        Test.setMock(HttpCalloutMock.class, mock2);
        Test.startTest();
        gen_Auth0Controller.createUser(testUserId, 'Genscape'); //Second pass should fail but catch error handling code
        Test.stopTest();
        system.debug('Auth0Controller Tests - end test');
        
    }

}