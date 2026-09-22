( function( $ ){

	var RelatedDataTree = ( function(){
		function RelatedDataTree( $tree ) {
			this.$tree              = $tree;
			this.$relationshipInput = $tree.find( "input[type=hidden]" ).first();
			this.$summary           = $tree.find( ".related-data-tree-summary" );
			this.$nav               = $tree.find( ".related-data-tree-nav" );
			this.fetchUrl           = $tree.data( "fetchUrl" ) || "";
			this.targetObject       = $tree.data( "targetObject" ) || "";
			this.propertyInputName  = $tree.data( "propertyInputName" ) || "related_data_property";
			this.loadingText        = $tree.data( "loadingText" ) || "";
			this.errorText          = $tree.data( "errorText" ) || "";
			this.placeholder        = $tree.data( "placeholder" ) || "";
			this.$propertyInput     = this._findPropertyInput();

			this._bindEvents();
			this._restoreSelection();
		}

		RelatedDataTree.prototype._findPropertyInput = function(){
			var $form = this.$tree.closest( "form" );
			var $input = $form.find( "input[name='" + this.propertyInputName + "']" );

			if ( !$input.length ) {
				$input = $( "<input type='hidden' />" ).attr( "name", this.propertyInputName ).appendTo( this.$tree );
			}

			return $input;
		};

		RelatedDataTree.prototype._bindEvents = function(){
			var tree = this;

			tree.$tree.on( "click", ".tree-node-toggler", function( e ){
				e.preventDefault();
				e.stopPropagation();
				tree.toggle( $( this ).closest( ".tree-folder" ) );
			} );

			tree.$tree.on( "click", ".tree-node", function( e ){
				var $item   = $( this ).closest( ".tree-folder, .tree-item" );
				var $target = $( e.target );

				e.preventDefault();

				if ( $target.closest( ".tree-node-toggler" ).length ) {
					return;
				}

				if ( tree._isRootRelationship( $item ) ) {
					tree.toggle( $item );
					return;
				}

				tree.select( $item );
			} );

			tree.$tree.on( "keydown", ".tree-node", function( e ){
				var $item = $( this ).closest( ".tree-folder, .tree-item" );

				if ( e.keyCode === 13 ) {
					e.preventDefault();
					if ( tree._isRootRelationship( $item ) ) {
						tree.toggle( $item );
					} else {
						tree.select( $item );
					}
				} else if ( e.keyCode === 39 && $item.hasClass( "tree-folder" ) ) {
					e.preventDefault();
					tree.toggle( $item, true );
				} else if ( e.keyCode === 37 && $item.hasClass( "tree-folder" ) ) {
					e.preventDefault();
					tree.toggle( $item, false );
				}
			} );
		};

		RelatedDataTree.prototype._isRootRelationship = function( $item ){
			return $item.data( "type" ) === "relationship" && !$.trim( $item.data( "relationshipPath" ) || "" );
		};

		RelatedDataTree.prototype.toggle = function( $folder, show ){
			var $content     = $folder.children( ".tree-folder-content" );
			var $toggler     = $folder.find( ".tree-folder-header .tree-node-toggler" ).first();
			var currentlyOpen = $content.hasClass( "open" );
			var shouldOpen    = ( typeof show === "undefined" ) ? !currentlyOpen : show;

			if ( !shouldOpen ) {
				$content.removeClass( "open" );
				$toggler.removeClass( "fa-caret-down" ).addClass( "fa-caret-right" );
				return $.Deferred().resolve().promise();
			}

			$content.addClass( "open" );
			$toggler.removeClass( "fa-caret-right" ).addClass( "fa-caret-down" );

			return this._ensureChildren( $folder );
		};

		RelatedDataTree.prototype._ensureChildren = function( $folder ){
			var tree = this;

			if ( $folder.data( "childrenLoaded" ) ) {
				return $.Deferred().resolve().promise();
			}
			if ( $folder.data( "childrenLoading" ) ) {
				return $folder.data( "childrenLoading" );
			}

			var request = this._loadChildren( $folder );
			$folder.data( "childrenLoading", request );

			request.always( function(){
				$folder.removeData( "childrenLoading" );
			} );

			return request;
		};

		RelatedDataTree.prototype._loadChildren = function( $folder ){
			var tree      = this;
			var $content  = $folder.children( ".tree-folder-content" );
			var $loading  = $( '<div class="related-data-tree-loading"><i class="fa fa-fw fa-refresh fa-spin"></i> ' + tree.loadingText + "</div>" );
			var deferred  = $.Deferred();

			$content.empty().append( $loading );

			$.ajax( tree.fetchUrl, {
				  method : "GET"
				, cache  : false
				, data   : {
					  target_object             : tree.targetObject
					, related_data_relationship : $folder.data( "path" ) || ""
				  }
			} ).done( function( nodes ){
				$content.empty();

				if ( !$.isArray( nodes ) || !nodes.length ) {
					$folder.find( ".tree-folder-header .tree-node-toggler" ).first().remove();
					$folder.data( "childrenLoaded", true );
					deferred.resolve();
					return;
				}

				$.each( nodes, function( i, node ){
					$content.append( tree._renderNode( node ) );
				} );

				$folder.data( "childrenLoaded", true );
				deferred.resolve();
			} ).fail( function(){
				$content.html( '<div class="related-data-tree-error"><i class="fa fa-fw fa-exclamation-circle"></i> ' + tree.errorText + "</div>" );
				deferred.reject();
			} );

			return deferred.promise();
		};

		RelatedDataTree.prototype._nodeValue = function( node, key ){
			if ( typeof node[ key ] !== "undefined" ) {
				return node[ key ];
			}

			var upper = key.toUpperCase();
			if ( typeof node[ upper ] !== "undefined" ) {
				return node[ upper ];
			}

			return "";
		};

		RelatedDataTree.prototype._isTrue = function( value ){
			return value === true || value === "true" || value === "yes" || value === 1 || value === "1";
		};

		RelatedDataTree.prototype._renderNode = function( node ){
			var hasChildren      = this._isTrue( this._nodeValue( node, "hasChildren" ) );
			var nodeType         = this._nodeValue( node, "type" ) || "property";
			var nodeId           = this._nodeValue( node, "id" );
			var label            = this._nodeValue( node, "label" );
			var path             = this._nodeValue( node, "path" );
			var propertyName     = this._nodeValue( node, "property" );
			var relationshipPath = this._nodeValue( node, "relationshipPath" );
			var $item, $header;

			if ( hasChildren ) {
				$item = $( "<div class='tree-folder'></div>" );
				$header = $( "<div class='tree-node tree-folder-header' tabindex='0'></div>" );
				$header.append( "<i class='fa fa-fw fa-caret-right tree-node-toggler'></i>" );
				$header.append(
					$( "<div class='tree-folder-name node-name'></div>" ).append(
						$( "<span class='node-label'></span>" ).text( label )
					)
				);
				$item.append( $header );
				$item.append( "<div class='tree-folder-content'></div>" );
			} else {
				$item = $( "<div class='tree-node tree-item' tabindex='0'></div>" );
				$item.append( "<i class='fa fa-fw fa-caret-right related-data-tree-spacer'></i>" );
				$item.append(
					$( "<div class='tree-item-name node-name'></div>" ).append(
						$( "<span class='node-label'></span>" ).text( label )
					)
				);
			}

			$item.attr( {
				  "data-node-id"           : nodeId
				, "data-type"              : nodeType
				, "data-path"              : path
				, "data-property"          : propertyName
				, "data-relationship-path" : relationshipPath
				, "data-has-children"      : hasChildren ? "true" : "false"
			} );

			return $item;
		};

		RelatedDataTree.prototype.select = function( $item ){
			var relationshipPath = $.trim( $item.data( "relationshipPath" ) || "" );
			var propertyName     = $.trim( $item.data( "property" ) || "" );
			var label            = this._selectionLabel( $item );

			this.$tree.find( ".tree-node" ).removeClass( "selected" );
			if ( $item.hasClass( "tree-item" ) ) {
				$item.addClass( "selected" );
			} else {
				$item.children( ".tree-folder-header" ).addClass( "selected" );
			}

			this.$relationshipInput.val( relationshipPath );
			this.$propertyInput.val( propertyName );
			this.$summary.text( label || this.placeholder );
		};

		RelatedDataTree.prototype._selectionLabel = function( $item ){
			var labels = [];
			var $current = $item;

			while( $current.length && $current.closest( this.$nav ).length ) {
				var text = $.trim( $current.find( ".node-label" ).first().text() );
				if ( text ) {
					labels.unshift( text );
				}
				$current = $current.parent().closest( ".tree-folder" );
			}

			return labels.join( " → " );
		};

		RelatedDataTree.prototype._restoreSelection = function(){
			var tree             = this;
			var relationshipPath = $.trim( this.$relationshipInput.val() || "" );
			var propertyName     = $.trim( this.$propertyInput.val() || "" );

			if ( !relationshipPath || !propertyName ) {
				return;
			}

			var hops = relationshipPath.split( "." );

			var expandHop = function( index ){
				if ( index >= hops.length ) {
					tree._highlightSavedNode( relationshipPath, propertyName );
					return;
				}

				var pathSoFar = hops.slice( 0, index + 1 ).join( "." );
				var $folder   = tree.$nav.find( ".tree-folder[data-path='" + pathSoFar + "']" ).first();

				if ( !$folder.length ) {
					return;
				}

				tree.toggle( $folder, true ).done( function(){
					expandHop( index + 1 );
				} );
			};

			expandHop( 0 );
		};

		RelatedDataTree.prototype._highlightSavedNode = function( relationshipPath, propertyName ){
			var $item = this.$nav.find( "[data-relationship-path='" + relationshipPath + "'][data-property='" + propertyName + "']" ).first();

			if ( $item.length ) {
				this.$tree.find( ".tree-node" ).removeClass( "selected" );
				if ( $item.hasClass( "tree-item" ) ) {
					$item.addClass( "selected" );
				} else {
					$item.children( ".tree-folder-header" ).addClass( "selected" );
				}
			}
		};

		return RelatedDataTree;
	} )();

	$.fn.relatedDataTree = function(){
		return this.each( function(){
			var $this = $( this );

			if ( !$this.data( "relatedDataTree" ) ) {
				$this.data( "relatedDataTree", new RelatedDataTree( $this ) );
			}
		} );
	};

	$( function(){
		$( ".related-data-tree" ).relatedDataTree();
	} );

} )( presideJQuery );
