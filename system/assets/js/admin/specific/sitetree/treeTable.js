( function( $ ){

	$.fn.treeTable = function(){
		var loadingRowTemplate = '<tr class="depth-{{depth}} ajax-loading" data-parent="{{parent}}" data-depth="{{depth}}"><td colspan="5"><i class="fa fa-fw fa-refresh fa-spin"></i> ' + i18n.translateResource( "cms:sitetree.ajax.loading.message" ) + '</td></tr>'
		  , errorRowTemplate   = '<tr class="depth-{{depth}} ajax-loading-error" data-parent="{{parent}}" data-depth="{{depth}}"><td colspan="5"><i class="fa fa-fw fa-exclamation-circle"></i> ' + i18n.translateResource( "cms:sitetree.ajax.loading.error.message" ) + '</td></tr>'
		  , selectedNode       = ( cfrequest.selectedNode || "" )
		  , openChildren, closeChildren, toggleRow, linkWasClicked, loadChildren, getChildren;

		openChildren = function( $parent ){
			var $childRows = getChildren( $parent );

			$childRows.show().each( function(){
				var $childRow = $( this );

				if ( getChildren( $childRow ).length && $childRow.data( "open" ) ) {
					openChildren( $childRow );
				}
			} );

			if ( !$parent.data( "childrenLoaded" ) && !$parent.data( "childrenLoading" ) ) {
				loadChildren( $parent );
			}
		};

		loadChildren = function( $parent ){
			$parent.data( "childrenLoading", true )

			var $children = getChildren( $parent )
			  , $loadingRow = $( Mustache.render( loadingRowTemplate, {
					  depth  : parseInt( $parent.data( 'depth' ) ) + 1
					, parent : $parent.data( 'id' )
				} ) )
			  , ajaxSuccessHandler, ajaxErrorHandler, ajaxCompleteHandler;

			if ( $children.length ) {
				$( $children.get( $children.length-1 ) ).after( $loadingRow );
			} else {
				$parent.after( $loadingRow );
			}

			$parent.data( "children", calculateChildren( $parent ) );

			ajaxSuccessHandler = function( data ){
				$loadingRow.before( data );
			};

			ajaxErrorHandler = function(){
				var $errorRow = $( Mustache.render( errorRowTemplate, {
					  depth  : parseInt( $parent.data( 'depth' ) ) + 1
					, parent : $parent.data( 'id' )
				} ) );

				$loadingRow.before( $errorRow );
			};

			ajaxCompleteHandler = function(){
				var $children = calculateChildren( $parent );

				$loadingRow.remove();
				$parent.data( "childrenLoaded", true );
				$parent.data( "childrenLoading", false );
				$parent.data( "children", $children );

				$children.attr( "tabindex", $parent.attr( "tabindex" ) );
				$children.filter( "[data-open-on-start]" ).each( function(){
					openChildren( $( this ) );
				} );
			};

			$.ajax( buildAjaxLink( 'sitetree.ajaxChildNodes', { parentId : $parent.data( "id" ), selected : selectedNode  } ), {
				  method   : "GET"
				, cache    : false
				, success  : ajaxSuccessHandler
				, error    : ajaxErrorHandler
				, complete : ajaxCompleteHandler
			} );
		};

		calculateChildren = function( $parent ) {
			var $table = $parent.closest( "table" );

			return $table.find( "tr[data-parent='" + $parent.data( "id" ) + "']" )
		};

		closeChildren = function( $parent ){
			var $childRows = getChildren( $parent );
			if ( $childRows.length ) {
				$childRows.hide().each( function(){
					var $childRow = $( this );

					if ( getChildren( $childRow ).length ) {
						closeChildren( $childRow );
					}
				} );
			}
		};

		toggleRow = function( $row ){
			var $toggler = $row.find( ".tree-toggler" )
			  , open     = $row.data( "open" )

			$toggler.toggleClass( "fa-caret-right" );
			$toggler.toggleClass( "fa-caret-down" );

			open ? closeChildren( $row ) : openChildren( $row );
			$row.data( "open", !open );

		}

		linkWasClicked = function( eventTarget ){
			return $.inArray( eventTarget.nodeName, ['A','INPUT','BUTTON','TEXTAREA','SELECT'] ) >= 0
			    || $( eventTarget ).parents( 'a:first,input:first,button:first,textarea:first,select:first' ).length
			    || $( eventTarget ).data( 'toggle' );
		};

		getChildren = function( $parent ) {
			if ( typeof $parent.data( "children" ) === "undefined" ) {
				$parent.data( "children", calculateChildren( $parent ) );
			}

			return $parent.data( "children" );
		}

		return this.each( function(){
			var $table      = $( this )
			  , $selected   = $table.find( "tr.selected:first" );

			$table.on( "click", ".tree-toggler", function( e ){
				e.preventDefault();

				var $toggler   = $( this )
				  , $parentRow = $toggler.closest( "tr" );

				toggleRow( $parentRow );
			} );

			$table.on( "keydown", "tbody > tr", "left", function( e ){
				e.stopPropagation();
				var $row = $( this );

				if ( $row.data( "open" ) ) {
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
				if ( !$row.data( "open" ) ) {
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

				toggleRow( $selected );
				$selected.focus();
				$selected.blur( function(){
					$( this ).removeClass( "selected" );
				} );

			} else {
				toggleRow( $table.find( "tr[data-has-children='true']" ).first() );
			}

		} );
	};

	$( '.tree-table' ).treeTable();

} )( presideJQuery );