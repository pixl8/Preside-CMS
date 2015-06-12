( function( $ ){

	var OneToManyManager = (function() {
		function OneToManyManager( $link ) {
			this.$link = $link;
			this.setupManagerDialog();
			this.setupLinkBehaviour();
		}

		OneToManyManager.prototype.setupManagerDialog = function(){
			var iframeSrc        = this.$link.data( "managerUrl" )
			  , modalTitle       = this.$link.data( "modalTitle" )
			  , oneToManyManager = this
			  , modalOptions;

			modalOptions = {
				title      : modalTitle,
				className  : "full-screen-dialog",
				buttonList : [ "ok" ]
			};

			this.iframeModal = new PresideIframeModal( iframeSrc, "100%", "100%", {}, modalOptions );
		};

		OneToManyManager.prototype.setupLinkBehaviour = function(){
			var oneToManyManager = this;

			this.$link.click( function( e ){
				e.preventDefault();
				oneToManyManager.iframeModal.open();
			} );
		};

		return OneToManyManager;

	})();


	$.fn.oneToManyManager = function(){
		return this.each( function(){
			new OneToManyManager( $( this ) );
		} );
	};

	$( ".one-to-many-manager" ).oneToManyManager();

} )( presideJQuery );