( function( $ ) {

	function parsePredicate( raw ) {
		var predicate = { invert: false, values: [] }
		  , parts     = []
		  , i         = 0;

		raw = $.trim( raw || "" );

		if ( raw.charAt( 0 ) === "!" ) {
			predicate.invert = true;
			raw = $.trim( raw.substring( 1 ) );
		}

		parts = raw.split( "," );
		for ( i = 0; i < parts.length; i++ ) {
			predicate.values.push( $.trim( parts[ i ] ) );
		}

		return predicate;
	}

	function currentValues( $wrapper ) {
		var $checkable = $wrapper.find( "input:radio, input:checkbox" )
		  , $field     = null
		  , val        = null;

		if ( $checkable.length ) {
			return $checkable.filter( ":checked" ).map( function() { return String( $( this ).val() ); } ).get();
		}

		// Enhanced selects move the name onto a hidden field and never update the original
		// select, so the named element is the only reliable source of the current value
		$field = $wrapper.find( "select[name], input[name], textarea[name]" ).first();
		if ( !$field.length ) {
			$field = $wrapper.find( "select, input, textarea" ).first();
		}
		if ( !$field.length ) {
			return [];
		}

		val = $field.val();
		if ( val === null || typeof val === "undefined" ) {
			return [];
		}

		if ( $.isArray( val ) ) {
			return $.map( val, String );
		}

		val = String( val );

		return val.indexOf( "," ) === -1 ? [ val ] : $.map( val.split( "," ), $.trim );
	}

	function predicateMatched( predicate, values ) {
		var matched = false
		  , i       = 0;

		for ( i = 0; i < values.length && !matched; i++ ) {
			matched = $.inArray( values[ i ], predicate.values ) !== -1;
		}

		return predicate.invert ? !matched : matched;
	}

	function resolveTargets( list ) {
		var targets = { controls: [], fieldsets: [] }
		  , items   = ( list || "" ).split( "," )
		  , i       = 0
		  , name    = ""
		  , selector = "";

		for ( i = 0; i < items.length; i++ ) {
			name = $.trim( items[ i ] );
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

	function cascade( $region ) {
		$region.each( function() {
			var $node = $( this );

			if ( $node.is( "[data-toggle-when]" ) ) {
				apply( $node );
			}
			$node.find( "[data-toggle-when]" ).each( function() {
				apply( $( this ) );
			} );
		} );
	}

	function apply( $wrapper ) {
		var predicate   = parsePredicate( $wrapper.attr( "data-toggle-when" ) )
		  , selfVisible = $wrapper.is( ":visible" )
		  , show        = selfVisible && predicateMatched( predicate, currentValues( $wrapper ) )
		  , targets     = resolveTargets( $wrapper.attr( "data-toggle-fields" ) )
		  , toggleEvent = show ? "toggledon" : "toggledoff"
		  , $affected   = $();

		if ( targets.fieldsets.length ) {
			var $fieldsets = $( targets.fieldsets.join( "," ) );
			$fieldsets.toggle( show ).trigger( toggleEvent );
			$affected = $affected.add( $fieldsets );
		}

		if ( targets.controls.length ) {
			var $controls = $( targets.controls.join( "," ) )
			  , $groups   = $controls.closest( ".form-group" );

			$groups.toggle( show );
			$controls.trigger( toggleEvent );
			$affected = $affected.add( $groups );
		}

		cascade( $affected );
	}

	$.fn.presideConditionalFieldVisibility = function() {
		return this.each( function() {
			var $wrapper = $( this );

			// Delegated so controls added after init (e.g. an enhanced select's hidden field) are covered
			$wrapper.on( "change", "select, input, textarea", function() {
				apply( $wrapper );
			} );

			apply( $wrapper );
		} );
	};

	$( function() {
		$( ".form-group[data-toggle-when]" ).presideConditionalFieldVisibility();
	} );

} )( jQuery || presideJQuery );
