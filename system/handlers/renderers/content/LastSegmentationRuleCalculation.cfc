/**
 * @feature rulesEngine
 */
component {

	private string function default( event, rc, prc, args={} ) {
		return runEvent(
			  event          = "renderers.content.datetime.relative"
			, private        = true
			, prePostExempt  = true
			, eventArguments = { args=arguments.args }
		);
	}

}