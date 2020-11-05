component {
	property name="rulesEngineFilterService" inject="RulesEngineFilterService";

	private void function preAddRecordAction( event, rc, prc, args={} ){
		if ( !args.validationResult.validated() ) {
			args.formData.delete( "context" );
		}
	}

	private void function preFetchRecordsForGridListing( event, rc, prc, args={} ) {
		rulesEngineFilterService.getRulesEngineSelectArgsForEdit( args=args );
	}

	private void function preEditRecordAction( event, rc, prc, args={} ) {
		switch ( args.formData.filter_sharing_scope ?: "" ) {
			case "global":
				args.formData.owner            = "";
				args.formData.user_groups      = "";
				args.formData.allow_group_edit = 0;
				break;
			case "individual":
				args.formData.user_groups      = "";
				args.formData.allow_group_edit = 0;
				break;
		}
	}

}