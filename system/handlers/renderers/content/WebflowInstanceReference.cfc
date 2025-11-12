component {
	property name="webflowLibrary" inject="WebflowSpecLibrary";

	private string function default( event, rc, prc, args={} ) {
		var propName     = Trim( args.propertyName ?: "" );
		var objectName   = Trim( args.objectName   ?: "" );
		var recordId     = Trim( args.recordId     ?: "" );
		var recordDetail = Len( objectName ) ? getPresideObject( objectName ).selectData(
			  returntype        = "singleRecordStruct"
			, id                = recordId
			, extraselectFields = Len( propName ) ? [ propName ] : []
			, selectFields      = [
				  "id"
				, "owner"
				, "reference"
				, "sub_reference"
				, "sub_sub_reference"
			]
		) : {};

		var webflowId = Len( args.webflowId ?: "" ) ? args.webflowId : ( recordDetail.reference ?: "" );

		if ( Len( webflowId ) ) {
			var webflow        = webflowLibrary.getWebflow( webflowId );
			var instRefConfig  = webflow.getInstRefConfig();
			var instRefViewlet = Len( instRefConfig.rendererViewlet ?: "" ) ? instRefConfig.rendererViewlet : "webflow.#webflowId#.instanceReferenceRenderer";

			if ( getController().viewletExists( instRefViewlet ) ) {
				StructAppend( recordDetail, args, false );

				return renderViewlet( event=instRefViewlet, args=recordDetail );
			}
		}

		if ( Len( propName ) && Len( recordDetail[ propName ] ?: "" ) ) {
			return recordDetail[ propName ] ?: "";
		}

		return Trim( args.data ?: "" );
	}

	private string function adminDataTable( event, rc, prc, args={} ) {
		if ( isEmptyString( args.recordId ?:"" ) ) {
			args.recordId = args.record?.id ?: "";
		}

		return default( argumentCollection=arguments );
	}

	private string function plainText( event, rc, prc, args={} ) {
		if ( isEmptyString( args.recordId ?:"" ) ) {
			args.recordId = args.record?.id ?: "";
		}

		args.plainText = true;

		return default( argumentCollection=arguments );
	}
}