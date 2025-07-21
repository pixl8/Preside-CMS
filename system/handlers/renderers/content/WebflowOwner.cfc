component {

	public string function default( event, rc, prc, args={} ) {
		var ownerId = Trim( args.data ?: "" );

		if ( isFeatureEnabled( "websiteUsers" ) ) {
			return renderLabel( "website_user", ownerId );
		}
		return ownerId;
	}

	public string function admin( event, rc, prc, args={} ) {
		var ownerLabel = default( argumentCollection=arguments );
		var ownerId    = Trim( args.data ?: "" );

		return '<a href="#event.buildAdminLink( objectName="website_user", recordId=ownerId )#">#ownerLabel#</a>';
	}
}