( function( $ ) {

	$.fn.presideToggleControl = function() {
		function resolveTargets( list ) {
			var targets = { controls: [], fieldsets: [] }
			  , items   = list ? list.split( "," ) : [];

			for ( var i=0; i<items.length; i++ ) {
				var name     = $.trim( items[ i ] )
				  , selector = "";

				if ( !name.length ) {
					continue;
				}

				switch ( name.charAt( 0 ) ) {
					case "#":
					case ".":
						selector = name;
						break;

					default:
						selector = '[name="' + name + '"]';
				}

				if ( $( selector ).is( "fieldset" ) ) {
					targets.fieldsets.push( selector );
				} else {
					targets.controls.push( selector );
				}
			}

			return targets;
		}

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
				var targets   = resolveTargets( $control.data( controlAttributes[ i ] ) )
				  , selectors = targets.controls.concat( targets.fieldsets );

				for ( var j=0; j<selectors.length; j++ ) {
					var $child = $( selectors[ j ] );

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
				if ( targets.fieldsets.length ) {
					$( targets.fieldsets.join( "," ) ).toggle( controlAttributes[ i ] == "toggleDefaultFields" ? !controlChecked : controlChecked );
					$( targets.fieldsets.join( "," ) ).trigger( toggleEvent );
				}
				if ( targets.controls.length ) {
					$( targets.controls.join( "," ) ).closest( ".form-group" ).toggle( controlAttributes[ i ] == "toggleDefaultFields" ? !controlChecked : controlChecked );
					$( targets.controls.join( "," ) ).trigger( toggleEvent );
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
