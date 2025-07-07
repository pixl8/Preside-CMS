( function( $ ) {
	if ( !$.presideEnumRadioListControl ) {
		$.presideEnumRadioListControl = {};
	}

	$.presideEnumRadioListControl.toggleControl = function( $control ) {
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
	};

	$.fn.presideEnumRadioListControl = function() {
		this.each( function() {
			var $radio = $( this );
			$radio.on( "change", function() {
				$.presideEnumRadioListControl.toggleControl( $( this ) );
			} );
		} );

		const handledGroups = new Set();

		this.each( function() {
			var $radio    = $( this );
			var groupName = $radio.attr( "name" );

			if ( !handledGroups.has( groupName ) ) {
				$.presideEnumRadioListControl.toggleControl( $radio );
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
