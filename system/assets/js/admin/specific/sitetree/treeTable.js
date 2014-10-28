( function( $ ){

	$.fn.treeTable = function(){
		var openChildren, closeChildren, toggleRow, linkWasClicked;

		openChildren = function( $parent ){
			var $childRows = $parent.data( "children" );
			$childRows.show().each( function(){
				var $childRow = $( this );

				if ( $childRow.data( "children" ) && !$childRow.data( "closed" ) ) {
					openChildren( $childRow );
				}
			} );
		};

		closeChildren = function( $parent ){
			var $childRows = $parent.data( "children" );
			$childRows.hide().each( function(){
				var $childRow = $( this );

				if ( $childRow.data( "children" ) ) {
					closeChildren( $childRow );
				}
			} );
		};

		toggleRow = function( $row ){
			var $toggler = $row.data( "toggler" )
			  , closed   = $row.data( "closed" )


			$toggler.toggleClass( "fa-caret-right" );
			$toggler.toggleClass( "fa-caret-down" );

			closed ? openChildren( $row ) : closeChildren( $row );

			$row.data( "closed", !closed );
		}

		linkWasClicked = function( eventTarget ){
			return $.inArray( eventTarget.nodeName, ['A','INPUT','BUTTON','TEXTAREA','SELECT'] ) >= 0
			    || $( eventTarget ).parents( 'a:first,input:first,button:first,textarea:first,select:first' ).length
			    || $( eventTarget ).data( 'toggle' );
		};

		return this.each( function(){
			var $table      = $( this )
			  , $parentRows = $table.find( "tr[data-has-children='true']" )
			  , $selected   = $table.find( "tr.selected:first" );

			$parentRows.each( function(){
				var $parentRow = $( this )
				  , $children  = $table.find( "tr[data-parent='" + $parentRow.data( "id" ) + "']" )
				  , $toggler   = $( '<i class="fa fa-lg fa-fw fa-caret-right tree-toggler"></i>' );

				$toggler.insertBefore( $parentRow.find( '.page-type-icon' ) );
				$toggler.data( "parentRow", $parentRow );

				$parentRow.data( "toggler" , $toggler );
				$parentRow.data( "children", $children );
				$parentRow.data( "closed"  , true );

				$children.hide();
			} );

			$table.on( "click", ".tree-toggler", function( e ){
				e.preventDefault();

				var $toggler   = $( this )
				  , $parentRow = $toggler.data( "parentRow" )

				toggleRow( $parentRow );
			} );

			$table.on( "keydown", "tbody > tr", "left", function( e ){
				e.stopPropagation();
				var $row = $( this );

				if ( !$row.data( "closed" ) ) {
					toggleRow( $row );
				}
			} );

			$table.on( "keydown", "tbody > tr", "return", function( e ){
				if ( !linkWasClicked( e ) ) {
					var $firstLink = $( this ).find( 'a:first' );

					if ( $firstLink.length ) {
						e.stopPropagation();
						e.preventDefault();

						$firstLink.get(0).click();
					}
				}
			} );

			$table.on( "keydown", "tbody > tr", "right", function( e ){
				e.stopPropagation();
				var $row = $( this );
				if ( $row.data( "closed" ) ) {
					toggleRow( $row );
				}
			} );

			$table.sortable({
				  items  : "tbody > tr"
				, handle : ".sortable-handle"
			});

			if ( $selected.length ) {
				var $parent = $table.find( "tr[data-id='" + ( $selected.data( "parent" ) || '' ) + "']"  );
				while( $parent.length ){
					toggleRow( $parent );

					$parent = $table.find( "tr[data-id='" + ( $parent.data( "parent" ) || '' ) + "']"  );
				}

				$selected.focus();
				$selected.blur( function(){
					$( this ).removeClass( "selected" );
				} );

			} else {
				toggleRow( $parentRows.first() );
			}

		} );
	};

	$( '.tree-table' ).treeTable();

} )( presideJQuery );