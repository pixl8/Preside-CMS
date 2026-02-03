/**
 * @feature formbuilder
 */
component  {

	property name="formBuilderService" inject="FormBuilderService";

	private string function default( event, rc, prc, args={} ){
		var formId       = rc.formId       ?: ( rc.id          ?: ( rc.form ?: "" ) );
		var submissionId = rc.submissionId ?: ( args.record.id ?: ( rc.id   ?: "" ) );

		args.tabs = _getAnsweredPages( formId=formId, submissionId=submissionId );

		var showTabs = IsFalse( args.firstResponseOnly ?: "" ) && ArrayLen( args.tabs ) > 0;

		if ( showTabs ) {
			args.responses = [];

			for ( var tab in args.tabs ) {
				ArrayAppend( args.responses, renderView( view="/renderers/content/formBuilderSubmission/default", args={
					  responses  = _getRenderedResponses( formId=formId, submissionId=submissionId, args=args, pageNumber=tab.page_number )
				} ) );
			}

			return renderView( view="/renderers/content/formBuilderSubmission/_tabs", args=args );
		}

		args.responses = _getRenderedResponses( formId=formId, submissionId=submissionId, args=args );

		if ( IsSimpleValue( args.responses ) ) {
			return args.responses;
		}

		return renderView( view="/renderers/content/formBuilderSubmission/default", args=args );
	}

	private string function htmlEmail( event, rc, prc, args={} ){
		var formId       = rc.formId       ?: ( rc.id          ?: ( rc.form ?: "" ) );
		var submissionId = rc.submissionId ?: ( args.record.id ?: ( rc.id   ?: "" ) );

		return _renderEmailResponse( formId=formId, submissionId=submissionId, args=args );
	}

	private string function textEmail( event, rc, prc, args={} ){
		var formId       = rc.formId       ?: ( rc.id          ?: ( rc.form ?: "" ) );
		var submissionId = rc.submissionId ?: ( args.record.id ?: ( rc.id   ?: "" ) );

		return Trim( _renderEmailResponse( formId=formId, submissionId=submissionId, args=args, context="text" ) );
	}

	private string function adminDataTable( event, rc, prc, args={} ){
		args.firstResponseOnly  = true;
		args.renderedSubmission = default( argumentCollection=arguments );

		args.renderedSubmission = REReplaceNoCase( args.renderedSubmission, "<\s*th\s*>", "<b>", "all" );
		args.renderedSubmission = REReplaceNoCase( args.renderedSubmission, "<\s*/\s*th\s*>", "</b>", "all" );
		args.renderedSubmission = REReplaceNoCase( args.renderedSubmission, "<(?!/?b\s*>)[^>]+>", "", "all" );

		return renderView( view="/renderers/content/formBuilderSubmission/adminDataTable", args=args );
	}


// HELPERS
	private any function _getRenderedResponses(
		  required string  formId
		, required string  submissionId
		,          struct  args          = {}
		,          numeric pageNumber    = 0
		,          boolean withPageTitle = false
		,          string  context       = "html"
	) {
		var isV2       = formBuilderService.isV2Form( arguments.formId );
		var formItems  = formBuilderService.getFormItems( id=arguments.formId, pageNumber=arguments.pageNumber );
		var noResponse = args.noResponse ?: translateResource( "formbuilder:no.response.placeholder" );

		if ( !ArrayLen( formItems ) ) {
			return noResponse;
		}

		var responses         = "";
		var renderedResponses = [];

		if ( isV2 ) {
			responses = formBuilderService.getV2Responses(
				  formId       = arguments.formId
				, submissionId = arguments.submissionId
			);
		} else {
			responses = args.data ?: "";
			if ( !IsJson( responses ) || !IsStruct( DeserializeJSON( responses ) ) ) {
				return responses;
			}
			responses = DeserializeJSON( responses );
		}

		for ( var item in formItems ) {
			if ( item.type.isFormField ?: false ) {
				var keyField = isV2 ? item.questionId : ( item.configuration.name ?: "" );

				if ( StructKeyExists( responses, keyField ) ) {
					var inputName = item.configuration.name;

					ArrayAppend( renderedResponses, {
						  item     = item
						, rendered = formbuilderService.renderResponse(
							  formId     = formId
							, inputName  = inputName
							, inputValue = responses[ keyField ]
							, context    = arguments.context
						  )
					} );

					if ( isTrue( args.firstResponseOnly ?: "" ) ) {
						break;
					}
				}
			} else if ( arguments.withPageTitle && ( item.item_type ?: "" ) == "page" ) {
				ArrayAppend( renderedResponses, { item=item } );
			}
		}

		return renderedResponses;
	}

	private string function _renderEmailResponse(
		  required string  formId
		, required string  submissionId
		,          struct  args          = {}
		,          string  context       = "html"
	) {
		var pages = _getAnsweredPages( formId=arguments.formId, submissionId=arguments.submissionId );

		if ( ArrayLen( pages ) ) {
			args.responses = [];

			for ( var page in pages ) {
				ArrayAppend( args.responses, _getRenderedResponses( formId=arguments.formId, submissionId=arguments.submissionId, args=args, withPageTitle=true, pageNumber=page.page_number, context=arguments.context ), true );
			}
		} else {
			args.responses = _getRenderedResponses( formId=arguments.formId, submissionId=arguments.submissionId, args=args, withPageTitle=true, context=arguments.context );

			if ( IsSimpleValue( args.responses ) ) {
				return args.responses;
			}
		}

		return renderView( view="/renderers/content/formBuilderSubmission/#arguments.context#Email", args=args );
	}

	private array function _getAnsweredPages(
		  required string formId
		, required string submissionId
	) {
		var submission = formBuilderService.getSubmission( submissionId=arguments.submissionId, selectFields=[ "form_page" ] );
		var pages      = formBuilderService.getPages( formId=arguments.formId );

		return ArrayFilter( pages, function( item ) {
			return ListContains( submission.form_page ?: "", item.id );
		} );
	}

}