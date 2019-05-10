public class gen_Auth0Controller {
    
    @AuraEnabled
    public static UserControls getUserCreationControls(Id contactId, String tenant) {
        
		system.debug('Getting user controls for contact: ' + contactId);
        Contact c = [select Id, User_Profile__c, User_Auth_ID__c, User_Auth_ID_Beta__c, User_Auth_ID_QA__c, User_Auth_ID_Dev__c from Contact where Id = :contactId];
        
        UserControls controls = new UserControls();
        controls.canBeCreated = false;
        controls.hasBeenCreated = false;
        
        //Can Be Created Logic
        if(c.User_Profile__c == 'Internal' || c.User_Profile__c == 'Test') {
            controls.canBeCreated = true;
        } else if((c.User_Profile__c == 'Customer' || c.User_Profile__c == null) && (tenant == 'Genscape' || tenant == 'Genscape-Beta')) {
            controls.canBeCreated = true;
        } else {
            controls.canBeCreated = false;
        }
        
        //Has Been Created Logic
        if(tenant == 'Genscape' && (c.User_Auth_ID__c != null || c.User_Auth_Id__c == '')) { controls.hasBeenCreated = true; }
        if(tenant == 'Genscape-Beta' && (c.User_Auth_ID_Beta__c != null || c.User_Auth_Id_Beta__c == '')) { controls.hasBeenCreated = true; }
        if(tenant == 'Genscape-QA' && (c.User_Auth_ID_QA__c != null || c.User_Auth_Id_QA__c == '')) { controls.hasBeenCreated = true; }
        if(tenant == 'Genscape-Dev' && (c.User_Auth_ID_Dev__c != null || c.User_Auth_Id_Dev__c == '')) { controls.hasBeenCreated = true; }
        
        system.debug('Controls: ' + controls);
        return controls;

    }
    
    @AuraEnabled
    public static String createUser(Id contactId, String tenant) {
        
        Contact c = [select Id, Name, FirstName, LastName, Email, User_Scopes__c, User_Profile__c, User_Auth_ID__c, User_Auth_ID_Beta__c, User_Auth_ID_QA__c, User_Auth_ID_Dev__c from Contact where Id = :contactId];
        
        system.debug('Check to see if user already exists');
        gen_Auth0.auth0_user auth0_user = getAuth0User(contactId, tenant);
        system.debug('Current auth0_user value: ' + auth0_user);
        
        if(auth0_user.user_id == null) {
            //Create New User
            system.debug('User does not exist');
            
            //Remove user_id to prevent invalid field error on user creation
            auth0_user.user_id = '';
            auth0_user.connection = 'Username-Password-Authentication';
            auth0_user.email = c.Email;
            auth0_user.password = 'defaultP@ssword!';
            auth0_user.given_name = c.FirstName;
            auth0_user.family_name = c.LastName;
            auth0_user.name = c.Name;
            
            //This will cause the user to receive a verification email
            auth0_user.verify_email = false;
            auth0_user.email_verified = true;
            
            //Build App Metadata
            gen_Auth0.app_metadata app_metadata = new gen_Auth0.app_metadata();
            app_metadata.salesforceId = String.valueOf(contactId);
            
            //Gather scopes
            app_metadata.scopes = new List<String>();
            if(c.User_Scopes__c != '' && c.User_Scopes__c != null) {
                List<String> user_scopes = c.User_Scopes__c.split(';');
            	app_metadata.scopes = user_scopes;
            }
            
            //Set Profile Type
            if(c.User_Profile__c != '' && c.User_Profile__c != null) {
            	app_metadata.profile = c.User_Profile__c;    
            }
            
            //Add scopes to new user
            auth0_user.app_metadata = app_metadata;
            system.debug(auth0_user);
            
            try {
                system.debug('Creating new user');
            	HTTPResponse newUserResponse = gen_Auth0.callout('POST', 'users', JSON.serialize(auth0_user), tenant);
            	gen_Auth0.auth0_user new_user = (gen_Auth0.auth0_user)JSON.deserialize(newUserResponse.getBody(), gen_Auth0.auth0_user.class);
                
                //Update Contact Record with Auth0 ID
                switch on tenant {
                    when 'Genscape' { c.User_Auth_ID__c = new_user.user_id; }
                    when 'Genscape-Beta' { c.User_Auth_ID_Beta__c = new_user.user_id; }
                    when 'Genscape-QA' { c.User_Auth_ID_QA__c = new_user.user_id; }
                    when 'Genscape-Dev' { c.User_Auth_ID_Dev__c = new_user.user_id; }
                }
                
                update c;
                
                return 'New User Record Added Successfully';
                
            } catch(Exception e) {
                return e.getMessage();
            }
            
        } else {
            //Use Existing User
            system.debug('User exists');
            return 'A user already exists with this ID';
        }

    }
    
    public static gen_Auth0.auth0_user getAuth0User(Id contactId, String tenant) {
        //See if user already exists in Auth0
        system.debug('Querying Auth0 by Contact Id');
        httpResponse response = gen_Auth0.callout('GET', 'users?q=app_metadata.salesforceId:"' + contactId + '"', '', tenant);
        system.debug(response.getBody());
        
        //Deserialize results
        List<gen_Auth0.auth0_user> auth0_users = (List<gen_Auth0.auth0_user>)JSON.deserialize(response.getBody(), List<gen_Auth0.auth0_user>.class);
        
        if(auth0_users.size() > 0) {
            
            if(auth0_users.size() == 1) {
                return auth0_users[0];
            } else {
                //Handle multiple records returned
                return auth0_users[0];
            }
            
        } else {
            gen_Auth0.auth0_user new_user = new gen_Auth0.auth0_user();
            return new_user;
        }

    }
    
    
    public class UserControls {
        @AuraEnabled
        public Boolean canBeCreated {get; set;}
        @AuraEnabled
        public Boolean hasBeenCreated {get; set;}
    }
}