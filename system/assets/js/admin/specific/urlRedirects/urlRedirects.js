( function( $ ) {

	$( '[name="redirect_type"]' ).on( 'change', function( e ) {
		var $this      = $( this )
		  , $formGroup = $this.closest( '.form-group' )
		;

		$( '.alert', $formGroup ).remove();

		if ( $this.val() != "302" ) {
			$this.parent().after( '<div class="alert alert-warning"><i class="fa fa-fw fa-exclamation-triangle"></i> ' + cfrequest.redirectType301Warning + '</div>' );
		}
	} ).trigger( 'change' );

	$( '[name="exact_match_only"]' ).on( 'change', function( e ) {
		var $this      = $( this )
		  , $formGroup = $this.closest( '.form-group' )
		;

		$( '.alert', $formGroup ).remove();

		if ( !$this.is( ':checked' ) ) {
			$this.parent().after( '<div class="alert alert-warning"><i class="fa fa-fw fa-exclamation-triangle"></i> ' + cfrequest.exactMatchOnlyfalseWarning + '</div>' );
		}
	} ).trigger( 'change' );

	$( '[name="source_url_pattern"], [name="redirect_to_link"]' ).on( 'change', function( e ) {
		var slugDelimiter =  "-"
		  , repeatRegex   = new RegExp( slugDelimiter+"+", "g" )
		  , startRegex    = new RegExp( "^"+slugDelimiter, "g" )
		  , endRegex      = new RegExp( slugDelimiter+"$", "g" )
		;

		var toSlug = $( '#redirect_to_link_chosen .selected-text' ).text()
			.replace( /\W/g      , slugDelimiter )
			.replace( repeatRegex, slugDelimiter )
			.replace( startRegex , "" )
			.replace( endRegex   , "" )
			.toLowerCase();

		if ( toSlug.length > 0 ) {
			toSlug = cfrequest.toSlugPrefix + toSlug;
		}

		var fromSlug = $( '#source_url_pattern' ).val()
			.replace( /\W/g      , slugDelimiter )
			.replace( repeatRegex, slugDelimiter )
			.replace( startRegex , "" )
			.replace( endRegex   , "" )
			.toLowerCase();

		if ( fromSlug.length > 0 ) {
			fromSlug = ' ' + cfrequest.fromSlugPrefix + fromSlug;
		}

		$( '[name="label"]' ).val( ( toSlug + fromSlug ).trim().substring( 0, 250 ) );
	} );

} )( presideJQuery );