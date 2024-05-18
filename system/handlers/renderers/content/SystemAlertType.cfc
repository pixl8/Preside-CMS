/**
 * @feature admin
 */
component {

	private string function default( event, rc, prc, args={} ){
		var type = args.data ?: "";

		return translateResource( uri="systemAlerts.#type#:title", defaultValue=type );
	}

}