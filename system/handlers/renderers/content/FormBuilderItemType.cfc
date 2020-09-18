component {

	private string function default( event, rc, prc, args={} ){
		var itemType = args.data ?: "";

		if ( Len( Trim( itemType ) ) ) {
			var title     = translateResource( uri="formbuilder.item-types.#itemType#:title", defaultValue=itemType );
			var iconClass = translateResource( uri="formbuilder.item-types.#itemType#:iconclass", defaultValue="fa-square" );

			return '<i class="fa fa-fw #iconClass#"></i> #title#';
		}

		return "";
	}

}