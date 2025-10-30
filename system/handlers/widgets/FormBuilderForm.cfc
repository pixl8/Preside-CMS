/**
 * @feature formBuilder
 */
component {

	property name="formbuilderService" inject="FormbuilderService";

	private function index( event, rc, prc, args={} ) {
		var pageCachingEnabled = isFeatureEnabled( "fullPageCaching" );

		event.include( assetId="/js/frontend/formbuilder/" );

		if ( pageCachingEnabled ) {
			event.include( "recaptcha-js" );
		}

		return renderViewlet(
			  event   = "widgets.FormBuilderForm._renderForm"
			, args    = args
			, delayed = pageCachingEnabled
		);
	}

	private string function placeholder( event, rc, prc, args={} ) {
		var fbForm          = formbuilderService.getForm( args.form ?: "" );
		var translationArgs = [ fbForm.name ?: "unknown form" ];

		if ( Len( Trim( args.instanceid ?: "" ) ) ) {
			translationArgs[1] &= " (" & args.instanceid & ")";
		}

		return translateResource( uri="widgets.FormBuilderForm:placeholder", data=translationArgs );
	}

	private string function _renderForm( event, rc, prc, args={} ) {
		var formId = args.form   ?: "";
		var layout = args.layout ?: "";

		var storageKey = args.storageKey = args._sk = ( rc._sk ?: "" );

		var rendered       = "";
		var tempSubmission = formBuilderService.getTempStoredSubmission( formId=formId, storageKey=storageKey );

		StructAppend( rc, tempSubmission );

		if ( Len( Trim( formId ) ) ) {
			if( !formbuilderService.formExists( formId ) ){
				if ( !event.isAdminUser() ) {
					return "";
				}
				return '<div class="alert alert-warning"><p><strong>' & translateResource( "formbuilder:notexists.form.admin.preview.warning") & '</strong></p></div>';
			}

			if ( !formbuilderService.isFormActive( formId ) ) {
				if ( !event.isAdminUser() ) {
					return "";
				}

				rendered = '<div class="alert alert-warning"><p><strong>' & translateResource( "formbuilder:inactive.form.admin.preview.warning") & '</strong></p></div>';
			}

			var checkAccess = formbuilderService.checkAccessAllowed( formId );
			if ( !checkAccess.allowed ) {
				return checkAccess.content;
			}

			if ( isTrue( tempSubmission.checkAccess ?: "" ) ) {
				var resubmitMessage = formbuilderService.formHasFileUploadFields( formId ) ? "resubmit.after.login.with.files" : "resubmit.after.login";
				rendered &= '<div class="alert alert-info"><p>' & translateResource( "formbuilder:#resubmitMessage#") & '</p></div>';
			}

			var requestData = event.getCollectionWithoutSystemVars();

			args.instanceSite = args.instanceSite ?: event.getSiteId();
			args.instanceUrl  = args.instanceUrl  ?: event.getCurrentUrl();

			args.formPageCount  = formbuilderService.getPageCount( formId=formId );
			args.formPageNumber = args.formPageCount ? ( requestData.formPageNumber ?: 1  ) : 0;

			var page = formbuilderService.getPageByPageNumber( formId=formId, pageNumber=args.formPageNumber );
			args.instancePage = args.formPageCount ? ( tempSubmission.instancePage ?: ( page.id ?: "" ) ) : "";

			while ( !formbuilderService.evaluateConditionForPage( formId=formId, pageNumber=args.formPageNumber, storageKey=storageKey ) ) {
				args.formPageNumber += requestData.formPageNext ?: 1;
			}

			rendered &= formbuilderService.renderForm(
				  formId           = formId
				, layout           = layout
				, configuration    = args
				, validationResult = rc.validationResult ?: ""
			);
		}

		return rendered;
	}
}