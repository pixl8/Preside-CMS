( function( $ ) {
	$.fn.presideEnumRadioListControl = function() {
		function toggleControl( $control ) {
			var groupName = $control.attr( "name" );

			$( 'input:radio[name="' + groupName + '"]' ).each( function() {
				var fields = $( this ).data( "toggleFields" );

				if ( !fields ) return;

				fields.split( /\s*,\s*/ ).forEach( function( field ) {
					var selector = "";
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
				var fields = $control.data( "toggleFields" );

				if ( !fields ) return;

				fields.split( /\s*,\s*/ ).forEach( function( field ) {
					var selector = "";
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
		}

		this.each( function() {
			var $radio = $( this );
			$radio.on( "change", function() {
				toggleControl( $( this ) );
			} );
		} );

		const handledGroups = new Set();

		this.each( function() {
			var $radio    = $( this );
			var groupName = $radio.attr( "name" );

			if ( !handledGroups.has( groupName ) ) {
				var $checked = $( 'input:radio[name="' + groupName + '"]:checked' );
				if ( $checked.length > 0 ) {
					toggleControl( $checked );
				}
				handledGroups.add( groupName );
			}
		} );

		return this;
	};

	$( function() {
		$( "input:radio.togglable-enum-radio-list" ).presideEnumRadioListControl();
	} );
} )( jQuery || presideJQuery );
