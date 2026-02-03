( function( $ ) {
	if ( !$.presideEnumRadioListControl ) {
		$.presideEnumRadioListControl = {};
	}

	$.presideEnumRadioListControl.toggleControl = function( $control ) {
		const groupName = $control.attr( "name" );

		$( 'input:radio[name="' + groupName + '"]' ).each( function() {
			const fields = $( this ).data( "toggleFields" );
			if ( !fields ) return;

			fields.split( /\s*,\s*/ ).forEach( function( field ) {
				let selector = "";
				switch ( field.charAt( 0 ) ) {
					case "#":
					case ".":
						selector = field;
						break;
					default :
						selector = '[name="' + field + '"]';
				}
				$( selector ).closest( ".form-group" ).hide();
			} );
		} );

		if ( $control.is( ":checked" ) ) {
			const fields = $control.data( "toggleFields" );
			if ( !fields ) return;

			fields.split( /\s*,\s*/ ).forEach( function( field ) {
				let selector = "";
				switch ( field.charAt( 0 ) ) {
					case "#":
					case ".":
						selector = field;
						break;
					default :
						selector = '[name="' + field + '"]';
				}
				$( selector ).closest( ".form-group" ).show();
			} );
		}
	};

	$.fn.presideEnumRadioListControl = function() {
		this.each( function() {
			const $radio = $( this );
			$radio.on( "change", function() {
				$.presideEnumRadioListControl.toggleControl( $( this ) );
			} );
		} );

		const handledGroups = new Set();

		this.each( function() {
			const $radio    = $( this );
			const groupName = $radio.attr( "name" );

			if ( !handledGroups.has( groupName ) ) {
				const $checked = $( 'input:radio[name="' + groupName + '"]:checked' );

				if ( $checked.length ) {
					$.presideEnumRadioListControl.toggleControl( $checked );
				}
				handledGroups.add( groupName );
			}

			$radio.trigger( "postinit" );
		} );

		return this;
	};

	$( function() {
		$( "input:radio.togglable-enum-radio-list" ).presideEnumRadioListControl();
	} );
} )( jQuery || presideJQuery );
