component {

	property name="presideObjectService" inject="presideObjectService";

	private string function admindatatable( event, rc, prc, args={} ) {
		var label       = args.data      ?: "";
		var recordId    = args.record.id ?: "";
		var description = presideObjectService.selectData(
			  objectName   = "saved_export"
			, id           = recordId
			, selectFields = [ "description" ]
		).description ?: "";

		var rendered = "<strong>" & EncodeForHTML( label ) & "</strong>";

		if ( !isEmptyString( description ) ) {
			rendered &= "<br>" & EncodeForHTML( description );
		}

		return rendered;
	}

}
