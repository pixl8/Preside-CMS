component output=false {

<!--- VIEWLETS --->
	private string function notFound( event, rc, prc, args={} ) output=false {
		event.setHTTPHeader( statusCode="404" );
		event.setHTTPHeader( name="X-Robots-Tag", value="noindex" );

		return renderView( view="/errors/notFound", args=args );
	}
}