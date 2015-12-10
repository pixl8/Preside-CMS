component {

	property name="presideRestService" inject="presideRestService";

	public function processRequest( event, rc, prc ) {
		presideRestService.processRequest(
			  uri            = rc.restUri ?: ""
			, requestContext = event
		);
	}

}