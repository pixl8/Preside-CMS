component output="false" extends="preside.system.base.AdminHandler" {

	property name="applicationsService" inject="ApplicationsService";

	function prehandler( event, rc, prc ) {
		super.preHandler( argumentCollection = arguments );
	}

	function make( event, rc, prc ) {
		var data = DecodeFromUrl( rc.data ?: "" );

		getPresideObject( "security_user" ).updateData(
			  id   = event.getAdminUserId()
			, data = {
				homepage_data = data
			  }
		);

		messageBox.info( translateResource( uri="cms:homepage.make.message" ) );
		setNextEvent( url=cgi.http_referer );
	}

}