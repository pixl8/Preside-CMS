component  {

	property name="formBuilderService" inject="formBuilderService";


	private string function default( event, rc, prc, args={} ){
		args.noResponse = translateResource( "formbuilder:no.response.placeholder" );
		args.responses  = _preRenderResponses( argumentCollection=arguments );
		if ( IsSimpleValue( args.responses ) ) {
			return args.responses;
		}

		return renderView( view="/renderers/content/formBuilderSubmission/default", args=args );
	}

	private string function htmlEmail( event, rc, prc, args={} ){
		args.responses = _preRenderResponses( argumentCollection=arguments );

		if ( IsSimpleValue( args.responses ) ) {
			return args.responses;
		}

		return Trim( renderView( view="/renderers/content/formBuilderSubmission/htmlEmail", args=args ) );
	}

	private string function textEmail( event, rc, prc, args={} ){
		args.responses = _preRenderResponses( argumentCollection=arguments );

		if ( IsSimpleValue( args.responses ) ) {
			return args.responses;
		}

		return Trim( renderView( view="/renderers/content/formBuilderSubmission/textEmail", args=args ) );
	}

	private string function adminDataTable( event, rc, prc, args={} ){
		args.firstResponseOnly = true;
		args.renderedSubmission = default( argumentCollection=arguments );

		return renderView( view="/renderers/content/formBuilderSubmission/adminDataTable", args=args );
	}


// HELPERS
	private any function _preRenderResponses( event, rc, prc, args={} ) {
		var noResponse        = args.noResponse ?: translateResource( "formbuilder:no.response.placeholder" );
		var responses         = args.data ?: "";
		var formId            = ( rc.formId ?: ( rc.id ?: ( rc.form ?: "" ) ) );
		var formItems         = formBuilderService.getFormItems( formId );
		var rendered          = "";
		var renderedResponses = [];

		if( !formItems.len() ){
			return noResponse;
		}

		if ( !IsJson( responses ) || !IsStruct( DeserializeJSON( responses ) ) ) {
			return responses;
		}


		responses         = DeserializeJson( responses );
		renderedResponses = [];

		for( var item in formItems ) {
			if ( item.type.isFormField && StructKeyExists( responses, item.configuration.name ?: "" ) ) {
				var inputName = item.configuration.name;
				var rendered  = formbuilderService.renderResponse(
					  formId     = formId
					, inputName  = inputName
					, inputValue = responses[ inputName ]
				);

				renderedResponses.append({
					  item     = item
					, rendered = rendered
				});

				if ( IsTrue( args.firstResponseOnly ?: "" ) ) {
					break;
				}
			}
		}

		return renderedResponses;
	}
}