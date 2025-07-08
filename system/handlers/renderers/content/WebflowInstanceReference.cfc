component {
	property name="webflowLibrary" inject="WebflowSpecLibrary";

	public string function default( event, rc, prc, args={} ) {
		var propName     = Trim( args.propertyName ?: "" );
		var objectName   = Trim( args.objectName   ?: "" );
		var recordId     = Trim( args.recordId     ?: "" );
		var recordDetail = Len( objectName ) ? getPresideObject( objectName ).selectData(
			  returntype        = "singleRecordStruct"
			, id                = recordId
			, extraselectFields = [ propName ]
			, selectFields      = [
				  "id"
				, "owner"
				, "reference"
				, "sub_reference"
				, "sub_sub_reference"
			]
		) : {};

		if ( !StructIsEmpty( recordDetail ) ) {
			var webflowId = recordDetail.reference ?: "";
			if ( Len( webflowId ) ) {
				var webflow         = webflowLibrary.getWebflow( webflowId );
				var instRefConfig   = webflow.getInstRefConfig();
				var instRefRenderer = Len( instRefConfig.renderer ?: "" ) ? instRefConfig.renderer : "webflow.#webflowId#.instanceReferenceRenderer"

				if ( getController().viewletExists( instRefRenderer ) ) {
					return renderViewlet( event=instRefRenderer, args=recordDetail );
				}
			}

			return recordDetail[ propName ] ?: "";
		}

		return Trim( args.data ?: "" );
	}
}