component {
	private void function preAddRecordAction( event, rc, prc, args={} ){
		if ( !args.validationResult.validated() ) {
			args.formData.delete( "context" );
		}
	}
}