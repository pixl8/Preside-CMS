component output=false {

<!--- VIEWLETS --->
	private string function notFound( event, rc, prc, args={} ) output=false {
		event.setHTTPHeader( statusCode="404" );
		event.setHTTPHeader( name="X-Robots-Tag", value="noindex" );

		return renderView( view="/errors/notFound", args=args );
	}

	private string function accessDenied( event, rc, prc, args={} ) output=false {
		event.setHTTPHeader( statusCode="401" );
		event.setHTTPHeader( name="X-Robots-Tag"    , value="noindex" );
		event.setHTTPHeader( name="WWW-Authenticate", value='Website realm="website"' );

		switch( args.reason ?: "" ){
			case "INSUFFICIENT_PRIVILEGES":
				return renderView( view="/errors/insufficientPrivileges", args=args );
			default:
				event.initializeApplicationPage( "login" );
				return renderView( view="/errors/loginRequired", args=args );
		}
	}
}

