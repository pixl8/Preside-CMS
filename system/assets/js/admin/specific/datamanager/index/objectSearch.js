( function( $ ){
	var $searchInput = $( "#datamanager-search-box" )
	  , $objects     = $( ".datamanager-object" )
	  , $groups      = $( ".datamanager-group" )
	  , searchIndex  = []
	  , generateRegexForInput, search, reset;

	if ( $searchInput.length && $objects.length ) {

		$objects.each( function(){
			searchIndex.push( {
				  title : $( this ).find( ".datamanager-object-title" ).text()
				, index : searchIndex.length
			} );
		} );

		generateRegexForInput = function( input ){
			var inputLetters = input.replace(/\W/, '').split('')
			  , reg = {}, i;

			reg.expr = new RegExp('(' + inputLetters.join( ')(.*?)(' ) + ')', 'i');
			reg.replace = ""

			for( i=0; i < inputLetters.length; i++ ) {
				reg.replace += ( '<b>$' + (i*2+1) + '</b>' );
				if ( i + 1 < inputLetters.length ) {
			  		reg.replace += '$' + (i*2+2);
				}
			}

			return reg;
		};

		search = function( input ){
			var reg = generateRegexForInput( input )
			  , matches;

			matches = searchIndex.filter( function( item ) {
				var titleLen = item.title.length
				  , match, nextMatch, i, highlighted;

				for( i=0; i < titleLen; i++ ){
					nextMatch = item.title.substr(i).match( reg.expr );

					if ( !nextMatch ) {
						break;
					} else if ( !match || nextMatch[0].length < match[0].length ) {
						match = nextMatch;
						highlighted = item.title.substr(0,i)
						            + item.title.substr(i).replace( reg.expr, reg.replace );
					}
				}

				if ( match ) {
					item.score       = match[0].length - input.length;
					item.highlighted = highlighted;

					return true;
				}
			});

			return matches.sort( function( a, b ){
				return ( a.score - b.score ) || a.title.length - b.title.length;
			} );
		};

		reset = function() {
			var $object, i;

			for( i=searchIndex.length-1; i>=0; i-- ){
				$object = $( $objects.get( searchIndex[ i ].index ) );
				$object.find( ".datamanager-object-title" ).html( searchIndex[ i ].title );
			}
			$groups.show();
			$groups.parents( ".datamanager-group-column" ).show();
			$objects.show();
		}

		$searchInput.keyup( "down", function( e ){
			$objects.filter( ":visible" ).first().find( "a:first" ).focus();
		} );

		$searchInput.on( "keyup", function( e ){
			e.preventDefault();

			var searchTerm = $( this ).val()
			  , $object, results, i;

			if ( !searchTerm.length ) {
				reset();
				return;
			}

			results = search( searchTerm );

			$groups.hide();
			$groups.parents( ".datamanager-group-column" ).hide();
			$objects.hide();

			for( i=results.length-1; i>=0; i-- ){
				$object = $( $objects.get( results[ i ].index ) );
				$object.show();
				$object.find( ".datamanager-object-title" ).html( results[i].highlighted );
				$object.parents( ".datamanager-group" ).show();
				$object.parents( ".datamanager-group-column" ).show();
			}
		} );

		$searchInput.focus();
	}

} )( presideJQuery );