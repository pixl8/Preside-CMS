/**
 * @feature admin
 */
component {

	private string function default( event, rc, prc, args={} ){
		var level = args.data ?: "";

		var label = translateResource( uri="enum.systemAlertLevel:#level#.label", defaultValue=level );
		var icon  = translateResource( uri="enum.systemAlertLevel:#level#.icon" , defaultValue="" );
		var class = translateResource( uri="enum.systemAlertLevel:#level#.class", defaultValue="" );

		return '<span class="badge radius-5 #class#">#UCase( label )#</span>';
	}

}