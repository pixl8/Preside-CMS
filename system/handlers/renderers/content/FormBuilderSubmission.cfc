component  {

	property name="formBuilderService" inject="formBuilderService";


	private string function default( event, rc, prc, args={} ){
		var responses     = args.data ?: "";
		var formId        = ( rc.formId ?: ( rc.id ?: "" ) );
		var formItems     = formBuilderService.getFormItems( formId );
		var rendered      = "";


		if ( !IsJson( responses ) || !formItems.len() || !IsStruct( DeserializeJSON( responses ) ) ) {
			return responses;
		}


		responses = DeserializeJson( responses );
		args.responses = [];

		for( var item in formItems ) {
			if ( item.type.isFormField && responses.keyExists( item.configuration.name ?: "" ) ) {
				var inputName = item.configuration.name;
				var rendered  = formbuilderService.renderResponse(
					  formId     = formId
					, inputName  = inputName
					, inputValue = responses[ inputName ]
				);

				args.responses.append({
					  item     = item
					, rendered = rendered
				});
			}
		}

		return renderView( view="/renderers/content/formBuilderSubmission/default", args=args );
	}

	private string function adminDataTable( event, rc, prc, args={} ){
		return default( argumentCollection=arguments ); // todo - wrap this in some jazz to do show/hide
	}

}