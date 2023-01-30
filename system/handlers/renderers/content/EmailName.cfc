component {

	public string function adminDatatable( event, rc, prc, args={} ) {
		var data   = args.data   ?: "";
		var record = args.record ?: {};

		if ( !StructIsEmpty( record ) ) {
			record.noStatusText = true;

			data = renderView( view="/admin/datamanager/_recordStatus", args=record ) & " " & data;
		}

		return data;
	}

}