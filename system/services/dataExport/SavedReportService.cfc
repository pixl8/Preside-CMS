/**
 * @singleton      true
 * @presideService true
 */
component {
	public any function init() {
		return this;
	}

	public struct function getSavedReportDetail( required string reportId ) {
		var detail = $getPresideObject( "saved_report" ).selectData( id=arguments.reportId );

		return ( detail.recordcount ) ? queryGetRow( detail, 1 ) : {};
	}
}