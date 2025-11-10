component {

	property name="draftManagerService" inject="DraftManagerService";

	public string function default( event, rc, prc, args={} ) {
		var data = args.data ?: "";

		if ( ListLen( data, "." ) > 1 ) {
			var draft = draftManagerService.getDraftDataForObject( objectName=ListFirst( args.data, "." ), recordId=ListRest( args.data, "." ) );

			data = draft._status ?: "";
		}

		return renderEnum( data=data, enum="DraftStatus" );
	}

}