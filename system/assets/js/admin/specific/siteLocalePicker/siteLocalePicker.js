( function( $ ) {
	$( '.site-locale-picker' ).on( 'change', function(e) {
		var selectedLocale = $(this).val();
		var localeParts = selectedLocale.split('_');

		var countryCode = "";

		if( localeParts.length === 2 ) {
			countryCode = localeParts[1].toUpperCase();
		}
		else if ( localeParts.length === 1 ) {
			countryCode = localeParts[0].toUpperCase();
		}

		var key = 'enum.isoCountries:' + countryCode + '.region';

		var region = cfrequest.isoCountries[key];
		var defaultLocaleSettings = cfrequest.defaultLocaleSettings[region];
		if( typeof defaultLocaleSettings != 'undefined' ) {
			$('#short_date_format').data("uberSelect").select(defaultLocaleSettings.short_date_format);
			$('#long_date_format').data("uberSelect").select(defaultLocaleSettings.long_date_format);
		}
	});
} )( jQuery || presideJQuery );
