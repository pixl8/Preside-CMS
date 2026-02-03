component {

	public string function default( event, rc, prc, args={} ) {
		var ownerId = Trim( args.data ?: "" );

		if ( isFeatureEnabled( "websiteUsers" ) ) {
			return renderLabel( "website_user", ownerId );
		}
		return ownerId;
	}
}