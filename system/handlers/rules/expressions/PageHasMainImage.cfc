/**
 * Expression handler for "Current page has/does not have a main image"
 *
 */
component {

	/**
	 * @expression true
	 * @expressionContexts webrequest,page
	 */
	private boolean function webRequest(
		  boolean _posesses = true
	) {
		var hasImage = Len( Trim( payload.page.main_image ?: "" ) );

		return _posesses ? hasImage : !hasImage;
	}

}