/**
 * @feature admin and emailCenter
 */
component {

	public string function adminDatatable( event, rc, prc, args={} ) {
		var data   = args.data   ?: "";
		var record = args.record ?: {};

		if ( !StructIsEmpty( record ) ) {
			var isDraft   = IsTrue( record._version_is_draft ?: "" );
			var hasDrafts = IsTrue( record._version_has_drafts ?: "" );
			record.noStatusText = true;

			data = renderView( view="/admin/datamanager/_recordStatus", args=record ) & " " & data;

			if ( hasDrafts && !isDraft ) {
				data &= "&nbsp;<em class=""light-grey"">#translateResource( "cms:datamanager.datamanager.status.has.drafts" )#</em>";
			}
		}

		return data;
	}

}