/**
 * @feature rulesEngine
 */
component {

	private string function adminView( event, rc, prc, args={} ){
		var recordId = Trim( args.data ?: ( args.record.id ?: "" ) );

		if ( Len( recordId ) ) {
			var recordDetail = getPresideObject( "rules_engine_condition" ).selectData(
				  id           = recordId
				, returntype   = "singleRecordStruct"
				, selectFields = [
					  "id"
					, "segmentation_tag_enabled AS tag_enabled"
					, "segmentation_tag_icon AS tag_icon"
					, "COALESCE( segmentation_tag_label, condition_name ) AS tag_label"
				]
			);

			if ( isTrue( recordDetail.tag_enabled ?: "" ) ) {
				var renderedTag = recordDetail.tag_label;
				if ( Len( recordDetail.tag_icon ?: "" ) ) {
					renderedTag = '<i class="fa fa-fw fa-#recordDetail.tag_icon#"></i>&nbsp;' & renderedTag;
				}

				return '<span class="badge badge-primary segmentation-tag">#renderedTag#</span>'
			} else {
				return '<span class="text-muted">#translateResource( uri="cms:not.applicable" )#</span>'
			}
		}
		return "";
	}

	private string function adminDatatable( event, rc, prc, args={} ){
		return adminView( argumentCollection=arguments );
	}
}