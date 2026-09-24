/**
 * @feature admin
 */
component {

	private string function default( event, rc, prc, args={} ){
		var level = args.data ?: "";

		var label = renderEnum( data=level, enum="systemAlertLevel", property="label" );
		var icon  = renderEnum( data=level, enum="systemAlertLevel", property="icon" );
		var class = renderEnum( data=level, enum="systemAlertLevel", property="class" );

		return '<span class="badge radius-5 #class#">#UCase( label )#</span>';
	}

}