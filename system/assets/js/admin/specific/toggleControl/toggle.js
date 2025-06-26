( function( $ ) {

	$.fn.presideToggleControl = function() {
		function toggleControl( $control, overridden ) {
			var controlAttributes = [ "toggleFields", "toggleDefaultFields" ]
			  , controlChecked    = false;

			if ( typeof overridden === "undefined" ) {
				if ( typeof $control.data( "toggled" ) === "undefined" ) {
					if ( $control.attr( "type" ) == "radio" ) {
						controlChecked = Boolean( parseInt( $control.val() ) );
					} else {
						controlChecked = $control.is( ":checked"  );
					}
				} else {
					$control.removeData( "toggled" );
				}
			} else {
				controlChecked = overridden;
				$control.data( "toggled", true );
			}

			for ( var i=0; i<controlAttributes.length; i++ ) {
				var controlsName = []
				  , fieldsets    = []
				  , controlsList = $control.data( controlAttributes[ i ] ) ? $control.data( controlAttributes[ i ] ).split( "," ) : [];

				for ( var j=0; j<controlsList.length; j++ ) {
					var selector = "";

					switch ( controlsList[ j ].charAt(0) ) {
						case "#":
						case ".":
							selector = controlsList[ j ];
							break;

						default:
							selector = '[name="' + controlsList[ j ] + '"]';
					}

					if ( $( selector ).is( "fieldset" ) ) {
						fieldsets.push( selector );
					} else {
						controlsName.push( selector );
					}

					var $child = $( selector );

					if ( typeof $child.data( controlAttributes[ i ] ) !== "undefined" ) {
						if ( controlChecked ) {
							toggleControl( $child );
						} else {
							toggleControl( $child, controlChecked ); // Override
						}
					}
				}

				var toggleEvent = "";
				if ( controlAttributes[ i ] == "toggleDefaultFields" ) {
					toggleEvent = controlChecked ? "toggledoff" : "toggledon";
				} else {
					toggleEvent = controlChecked ? "toggledon" : "toggledoff";
				}
				if ( fieldsets.length ) {
					$( fieldsets.join( "," ) ).toggle( controlAttributes[ i ] == "toggleDefaultFields" ? !controlChecked : controlChecked );
					$( fieldsets.join( "," ) ).trigger( toggleEvent );
				}
				if ( controlsName.length ) {
					$( controlsName.join( "," ) ).closest( ".form-group" ).toggle( controlAttributes[ i ] == "toggleDefaultFields" ? !controlChecked : controlChecked );
					$( controlsName.join( "," ) ).trigger( toggleEvent );
				}
			}
		}

		this.each( function() {
			var $toggle = $( this );

			$toggle.on( "change", function( e ) {
				toggleControl( $( this ) );
			} );

			if ( $toggle.attr( "type" ) == "radio" ) {
				if ( $toggle.is( ":checked" ) ) {
					toggleControl( $toggle );
				}
			} else {
				toggleControl( $toggle );
			}

			$toggle.trigger( "postinit" );
		} );

		return this;
	};

	$( function() {
		$( "input:radio.toggle-fields,input:checkbox.toggle-fields" ).presideToggleControl();
	} );

} )( jQuery || presideJQuery );
