/**
 * @feature admin
 */
component {

	private string function default( event, rc, prc, args={} ){
		var context = args.data ?: "";

		return Len( context ) ? context : '<span class="light-grey">#translateResource( "cms:systemAlerts.global.label" )#</span>';
	}

}