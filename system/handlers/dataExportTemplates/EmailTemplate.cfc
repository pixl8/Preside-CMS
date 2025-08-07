/**
 * Custom export template for email templates with percentage calculations
 */
component extends="preside.system.handlers.dataExportTemplates.Default" {

	private any function renderRecords( event, rc, prc, objectName, templateConfig, records ) {
		for( var i=1; i<=records.recordCount; i++ ) {
			var opens        = Val( records.unique_opens_count[i]        ?: 0 );
			var clicks       = Val( records.unique_clicks_count[i]       ?: 0 );
			var unsubscribes = Val( records.unique_unsubscribes_count[i] ?: 0 );
			var sentCount    = Val( records.send_count_from_stats[i]     ?: 0 );

			var openRate        = 0;
			var clickRate       = 0;
			var unsubscribeRate = 0;

			if ( sentCount > 0 ) {
				openRate        = ( opens / sentCount ) * 100;
				clickRate       = ( clicks / sentCount ) * 100;
				unsubscribeRate = ( unsubscribes / sentCount ) * 100;
			}

			records.open_rate_percentage[i]        = NumberFormat( openRate, "99.99" );
			records.click_rate_percentage[i]       = NumberFormat( clickRate, "99.99" );
			records.unsubscribe_rate_percentage[i] = NumberFormat( unsubscribeRate, "99.99" );
		}
	}

}