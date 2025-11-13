component {

	property name="draftManagerService" inject="DraftManagerService";

	public string function default( event, rc, prc, args={} ) {
		var data = args.data ?: "";

		if ( ListLen( data, "." ) > 1 ) {
			var draft = draftManagerService.getDraftForObject( objectName=ListFirst( args.data, "." ), recordId=ListRest( args.data, "." ) );

			data = draft[ ReplaceNoCase( args.propertyName, "draftmanager", "" ) ] ?: "";
		}

		return renderLabel( objectName="security_user", recordId=data );
	}

}