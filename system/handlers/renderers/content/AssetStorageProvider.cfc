component {

	private string function default( event, rc, prc, args={} ){
		var provider = args.data ?: "";

		return translateResource( uri="storage-providers.#provider#:title", defaultValue=provider );
	}
}