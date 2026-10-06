( function( $ ){

	$( ".task-manager-tab" ).on( "click", function(){
		var tabId = $( this ).data( "tabId" );
		$.cookie( "_presideTaskManagerTab", tabId );
	} );

	$.fn.taskManagerSearch = function(){
		return this.each( function(){
			var $taskList    = $( this )
			  , $searchInput = $taskList.find( ".task-manager-search" )
			  , $taskRows    = $taskList.find( "tr[data-task-search]" )
			  , $groupPanes  = $taskList.find( ".tab-pane" )
			  , filterTasks;

			filterTasks = function(){
				var query         = $.trim( $searchInput.val() ).toLowerCase()
				  , searchWords   = query.length ? query.split( /\s+/ ) : []
				  , isSearching   = searchWords.length > 0
				  , matchingCount = 0;

				$taskRows.each( function(){
					var $taskRow    = $( this )
					  , searchText  = $taskRow.attr( "data-task-search" ) || ""
					  , isMatch     = true
					  , i;

					for ( i = 0; i < searchWords.length; i++ ) {
						if ( searchText.indexOf( searchWords[ i ] ) === -1 ) {
							isMatch = false;
							break;
						}
					}

					$taskRow.toggleClass( "no-search-match", !isMatch );
					if ( isMatch ) {
						matchingCount++;
					}
				} );

				$groupPanes.each( function(){
					var $groupPane = $( this );

					$groupPane.toggleClass( "no-search-results", $groupPane.find( "tr[data-task-search]:not(.no-search-match)" ).length === 0 );
				} );

				$taskList.toggleClass( "searching", isSearching );
				$taskList.toggleClass( "no-matches", isSearching && matchingCount === 0 );
			};

			$searchInput.on( "input", filterTasks );
			$searchInput.on( "keydown", function( e ){
				if ( e.which === 27 && $searchInput.val().length ) {
					$searchInput.val( "" );
					filterTasks();
				}
			} );
		} );
	};

	$( ".task-manager-list" ).taskManagerSearch();

} )( presideJQuery );
