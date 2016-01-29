component {

	property name="presideRestService" inject="presideRestService";

	public function request( event, rc, prc ) {
		presideRestService.onRestRequest(
			  uri            = rc.restUri ?: ""
			, requestContext = event
		);
	}

}