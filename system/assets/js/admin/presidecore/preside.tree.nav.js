/**
 * Our own little tree widget for navigation site tree / asset manager
 *
 */

( function( $ ){

	var PresideTreeNav = ( function() {
		function PresideTreeNav( $tree, options ) {
			this.$tree = $tree;

			this.setupOptions( options );
			this.setupUxBehaviours();
			this.initializeSelection();
		};

		PresideTreeNav.prototype.setupOptions = function( userProvidedOptions ){
			var defaultOptions = {};

			this.options = $.extend( {}, defaultOptions, userProvidedOptions );
		};

		PresideTreeNav.prototype.setupUxBehaviours = function(){
			var treeNav = this;

			treeNav.$tree.on( "click", ".tree-node", function( e ){
				var $node = $( this );

				if ( $node.hasClass( "tree-folder-header" ) ) {
					treeNav.toggleNode( $node.parent() );
				}

				if ( typeof treeNav.options.onClick === "function" ) {
					treeNav.options.onClick( $node );
				}
			} );
		};

		PresideTreeNav.prototype.toggleNode = function( $node, show ){
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

		PresideTreeNav.prototype.initializeSelection = function(){
			var $selectedNode = this.$tree.find( ".selected-node" )
			  , treeNav       = this;

			if ( $selectedNode.length ) {
				$selectedNode.parents( ".tree-folder" ).each( function(){
					treeNav.toggleNode( $( this ), true );
				} );

				$selectedNode.focus();
			} else {
				treeNav.toggleNode( this.$tree.find( ".tree-folder" ).first(), true );
			}
		};

		return PresideTreeNav;
	} )();


	$.fn.presideTreeNav = function( options ) {
		return this.each( function() {
			var $this          = $( this )
			  , presideTreeNav = $this.data( 'presideTreeNav' );

			if ( !presideTreeNav ) {
				$this.data( 'presideTreeNav', new PresideTreeNav( $this, options ) );
			}
		} );
	};

} )( presideJQuery );