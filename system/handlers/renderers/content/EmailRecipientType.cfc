component {

	private string function default( event, rc, prc, args={} ){
		var type = args.data ?: "";

		return translateResource( uri="email.recipienttype.#type#:title", defaultValue=type );
	}
}