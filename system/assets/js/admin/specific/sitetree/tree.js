/**
 * Preside specific behaviour for the site tree browser
 *
 *
 */

( function( $ ){

	var $tree             = $( ".site-tree" )
	  , $contextPanel     = $( "#tree-context-panel" )
	  , $contextPagetitle = $contextPanel.find( ".pagetitle" )
	  , $contextTemplate  = $contextPanel.find( ".template" )
	  , $contextSlug      = $contextPanel.find( ".slug" )
	  , $contextFullslug  = $contextPanel.find( ".fullslug" )
	  , $contextActive    = $contextPanel.find( ".active" )
	  , $contextCreated   = $contextPanel.find( ".created" )
	  , $contextModified  = $contextPanel.find( ".modified" )
	  , $selectedNode     = $tree.find( ".selected-node" )
	  , toggleNode, showNodeDetails;

	toggleNode = function( $node, show ){
		var $header        = $node.find( ".tree-folder-header:first" )
		  , $nodeChildren  = $node.find( ".tree-folder-content:first" )
		  , $plusMinusIcon = $header.find( "i:first" );

		if ( typeof show === "undefined" ) {
			$nodeChildren.toggleClass( "open" );
			$plusMinusIcon.toggleClass( "fa-folder" );
			$plusMinusIcon.toggleClass( "fa-folder-open" );
		} else {
			$nodeChildren.toggleClass( "open", show );
			$plusMinusIcon.toggleClass( "fa-folder", !show );
			$plusMinusIcon.toggleClass( "fa-folder-open", show );
		}
	};

	showNodeDetails = function( $node ){
		var $nodeData = $node.find( ".node-data:first" );

		$contextPagetitle.html( $nodeData.find( '.pagetitle' ).html() );
		$contextTemplate.html( $nodeData.find( '.template' ).html() );
		$contextSlug.html( $nodeData.find( '.slug' ).html() );
		$contextFullslug.html( $nodeData.find( '.fullslug' ).html() );
		$contextActive.html( $nodeData.find( '.active' ).html() );
		$contextCreated.html( $nodeData.find( '.created' ).html() );
		$contextModified.html( $nodeData.find( '.modified' ).html() );
	};

	$tree.on( "click", ".tree-folder-header", function( e ){
		var $clickedEl = $( e.target );

		if ( $clickedEl.prop( "nodeName" ) !== "A" && !$clickedEl.parent( "A" ).length ) {
			toggleNode( $( this ).parent() );
		}
	} );

	$tree.on( "keydown", ".tree-folder-header", "left", function( e ){
		e.stopPropagation();
		toggleNode( $( this ).parent(), false );
	} );

	$tree.on( "keydown", ".tree-folder-header", "right", function( e ){
		e.stopPropagation();
		toggleNode( $( this ).parent(), true );
	} );

	$tree.on( "keydown", ".tree-node", "return", function( e ){
		var $editLink = $(this).find( "a[data-context-key=e]" ).first();

		if ( $editLink.length ) {
			$editLink.get(0).click();
		}
		e.stopPropagation();

	} );

	$tree.on( "dblclick", ".tree-node", "return", function( e ){
		var $editLink = $(this).find( "a[data-context-key=e]" ).first();

		if ( $editLink.length ) {
			$editLink.get(0).click();
		}
		e.stopPropagation();

	} );

	$tree.on( "focus", ".tree-folder-header,.tree-item", function( e ){
		showNodeDetails( $( this ) );
	} );

	if ( $selectedNode.length ) {
		$selectedNode.parents( ".tree-folder" ).each( function(){
			toggleNode( $( this ), true );
		} );

		$selectedNode.focus();
	} else {
		toggleNode( $tree.find( ".tree-folder" ).first(), true );
	}

} )( presideJQuery );