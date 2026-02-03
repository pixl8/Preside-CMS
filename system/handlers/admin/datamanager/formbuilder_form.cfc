/**
 * @feature admin and formbuilder
 */
component {

	private string function buildListingLink( event, rc, prc, args={} ) {
		return event.buildAdminLink(
			  linkto      = "formbuilder.index"
			, queryString = args.queryString ?: ""
		);
	}

	private string function buildViewRecordLink( event, rc, prc, args={} ) {
		var recordId = args.recordId ?: "";
		var queryString = "id=#recordId#";

		return event.buildAdminLink(
			  linkto      = "formbuilder.manageForm"
			, queryString = _queryString( queryString, args )
		);
	}

	private string function buildEditRecordLink( event, rc, prc, args={} ) {
		var recordId = args.recordId ?: "";
		var queryString = "id=#recordId#";

		return event.buildAdminLink(
			  linkto      = "formbuilder.manageForm"
			, queryString = _queryString( queryString, args )
		);
	}

	private string function _queryString( required string querystring, struct args={} ) {
		var extraQs = args.queryString ?: "";

		if ( extraQs.len() ) {
			return arguments.queryString & "&" & extraQs;
		}

		return arguments.queryString;
	}

	private void function preAddRecordAction( event, rc, prc, args={} ){
		_processFormData( argumentCollection=arguments );
	}
	private void function preEditRecordAction( event, rc, prc, args={} ){
		_processFormData( argumentCollection=arguments );
	}
	private void function _processFormData( event, rc, prc, args={} ) {
		if ( isFalse( args.formData.submission_remove_enabled ?: "" ) && Len( Trim( args.formData.submission_remove_after ?: "" ) ) ) {
			args.formData.submission_remove_after = "";
		} else if ( isTrue( args.formData.submission_remove_enabled ?: "" ) && !Len( Trim( args.formData.submission_remove_after ?: "" ) ) ) {
			args.validationResult.addError(
				  fieldName = "submission_remove_after"
				, message   = translateResource(
					  uri  = "preside-objects.formbuilder_form:validation.removal.fields.required"
					, data = [ translateResource( uri="preside-objects.formbuilder_form:field.submission_remove_after.title" ) ]
				)
			);
		}
	}
}
