( function( $ ){

	$.fn.sitetreePagePicker = function(){
		var datasource = buildAjaxLink( "sitetree.picker" )
		  , pickerHtml
		  , fetchPickerHtml
		  , setupPicker
		  , openModal;

		fetchPickerHtml = function( callback ){
			$.ajax( datasource, {
				  cache    : false
				, method   : "GET"
				, success  : function( content ){ pickerHtml=content; if ( callback ) { callback.call( this, content ); } }
				, dataType : "html"
			} );
		};
		fetchPickerHtml();

		setupPicker = function( currentSelection ){
			var $dialogContents = $( "<div>" + pickerHtml + "</div>" )
			  , $tree           = $dialogContents.find( ".tree" ).first()
			  , $currentSelection = $tree.find( ".tree-node[data-node-id=" + currentSelection + "]" )
			  , toggleNode
			  , selectNode;

			toggleNode = function( $node, show ){
				var $header        = $node.find( ".tree-folder-header:first" )
				  , $nodeChildren  = $node.find( ".tree-folder-content:first" )
				  , $plusMinusIcon = $header.find( "i:first" );

				if ( typeof show === "undefined" ) {
					$nodeChildren.toggleClass( "open" );
					$plusMinusIcon.toggleClass( "fa fa-folder-close" );
					$plusMinusIcon.toggleClass( "fa fa-folder" );
				} else {
					$nodeChildren.toggleClass( "open", show );
					$plusMinusIcon.toggleClass( "fa fa-folder-close", !show );
					$plusMinusIcon.toggleClass( "fa fa-folder", show );
				}
			};

			selectNode = function( $node ){
				$tree.find( ".tree-node" ).removeClass( "picked" );
				$node.addClass( "picked" );
				$node.parents( ".tree-folder" ).each( function(){
					toggleNode( $(this), true ); // ensure each parent folder is opened
				} );
			};

			$tree.on( "click", ".tree-folder-header", function( e ){
				toggleNode( $( this ).parent() );
			} );

			$tree.on( "click", ".tree-node", function( e ){
				e.stopPropagation();
				selectNode( $( this ) );
			} );

			if ( $currentSelection.length ) {
				selectNode( $currentSelection );
			}

			return $dialogContents;
		};

		openModal = function( $pickerInput, $pickerDisplay ){
			var $pickerDialog = setupPicker( $pickerInput.val() );

			presideBootbox.dialog( {
				message : $pickerDialog,
				title   : i18n.translateResource( "cms:sitetree.picker.title" ),
				buttons: {
					cancel : {
						label     : i18n.translateResource( "cms:cancel.btn" ),
						className : "btn-default"
					},
					clear : {
						label     : i18n.translateResource( "cms:sitetree.picker.clear.btn" ),
						className : "btn-danger",
						callback  : function() {
							$pickerInput.val( "" );
							$pickerDisplay.val( "" );
						}
					},
					ok : {
						label     : i18n.translateResource( "cms:ok.btn" ),
						className : "btn-primary",
						callback  : function() {
							var $selected = $pickerDialog.find( ".tree-node.picked" ).first();

							if ( $selected.length ) {
								$pickerInput.val( $selected.data( "nodeId" ) );
								$pickerDisplay.val( $selected.find( ".page-title" ).first().text() );
							} else {
								$pickerInput.val( "" );
								$pickerDisplay.val( "" );
							}
						}
					}
				}
			});
		};


		return this.each( function(){
			var $picker = $( this )
			  , selectedPageTitle = $picker.data( "pageTitle" )
			  , $newPicker = $( '<span class="block input-icon input-icon-right" style="cursor:pointer"><input class="form-control sitetree-page-picker" type="text" disabled="disabled" value="' + selectedPageTitle + '" style="cursor:pointer"><i class="fa fa-sitemap"></i></span>' );

			$picker.attr( "type", "hidden" );
			$picker.after( $newPicker );

			$newPicker.click( function( e ){
				e.preventDefault();

				if ( pickerHtml ) {
					openModal( $picker, $newPicker.find( "input" ) );
				} else {
					fetchPickerHtml( function(){
						setupPicker();
						openModal( $picker, $newPicker.find( "input" ) );
					});
				}
			} );

		} );
	};

	$( ".sitetree-page-picker-control" ).sitetreePagePicker();

} )( presideJQuery );