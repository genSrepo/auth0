public class gen_Auth0 {
    
    //Adding a comment to verify change is going to new branch
    
    //Gets an auth0 token
    public static auth0_token authenticate(Auth0_Setting__mdt settings) {
        
        tokenRequest tokenRequestBody = new tokenRequest();
        tokenRequestBody.grant_type = 'client_credentials';
        tokenRequestBody.client_id = settings.client_id__c;
        tokenRequestBody.client_secret = settings.client_secret__c;
        tokenRequestBody.audience = settings.audience__c;
			
		system.debug('Getting token');
		httpRequest req = new httpRequest();
		req.setEndpoint(settings.Auth_Endpoint__c);
    	req.setMethod('POST');
    	req.setHeader('Content-Type', 'application/json');
        req.setBody(JSON.serialize(tokenRequestBody));
		httpResponse response = new http().send(req);
		system.debug(response.getBody());
        
        auth0_token token = new auth0_token();
		if (response.getStatusCode() == 200) {
			system.debug('New token received');
            
            token = (auth0_token)JSON.deserialize(response.getBody(), auth0_token.class);
        } else {
            system.debug('Token request failed');
        }
    	
    	return token;
    	
    }
    
    //Callout method that handles authentication and switching among tenants
    public static httpResponse callout(String method, String endpoint, String body, String tenant) {
    	
        system.debug('Using tenant: ' + tenant);
        Auth0_Setting__mdt settings = [select audience__c, client_id__c, client_secret__c, auth_endpoint__c from Auth0_Setting__mdt where MasterLabel = :tenant];
        
        if(settings != null) {
            auth0_token token = authenticate(settings);            
            httpRequest req = new httpRequest();
            req.setEndpoint(settings.audience__c + endpoint);
            req.setHeader('Accept', 'application/json');
            req.setHeader('Content-Type', 'application/json');
            req.setHeader('Authorization', 'Bearer ' + token.access_token);
            req.setMethod(method);
            if(body != '') req.setBody(body);
            system.debug('Auth0 Request:' + req);
            system.debug('Auth0 Request Body: ' + req.getBody());
            httpResponse response = new http().send(req);
            system.debug('Auth0 Response:' + response);
            system.debug('Auth0 Response Body:' + response.getBody());
            return response;
        } else {
            
            //Return empty response if no settings are found for this auth0 tenant
            httpResponse response = new httpResponse();
            return response;
        }
        
    }
    
    //* Custom class definitions    
    public class tokenRequest {
		String grant_type;
		String client_id;
        String client_secret;
        String audience;
	}
    
    public class auth0_token {
        String access_token;
        String scope;
        Integer expires_in;
        String token_type;
    }
    
    public class auth0_user {
        public String connection;
		public String email;
		public String password;
		public Boolean verify_email;
        public Boolean email_verified;
        public String user_id;
        public String given_name;
        public String family_name;
        public String name;
        public app_metadata app_metadata;
    }
    
    public class app_metadata {
        public String salesforceId;
        public String[] scopes;
        public String profile;
    }
    
}