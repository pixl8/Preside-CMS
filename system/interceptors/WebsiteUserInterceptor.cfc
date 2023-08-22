component extends="coldbox.system.Interceptor" {

	property name="websiteLoginService" inject="delayedInjector:WebsiteLoginService";

	public void function configure() {}

	public void function postUpdateObjectData( event, interceptData ) {
		var objectName = interceptData.objectName ?: "";
		var id         = interceptData.id         ?: "";

		if ( objectName == "website_user" && Len( id ) ) {
			websiteLoginService.setUserSessionById( id );
		}
	}
}