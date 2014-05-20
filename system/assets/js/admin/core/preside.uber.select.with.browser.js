( function( $ ){

	var UberSelectWithBrowser;

	UberSelectWithBrowser = (function() {
		function UberSelectWithBrowser( $originalInput ) {
			this.$originalInput = $originalInput;

			this.setupUberSelect();
			this.setupBrowser();
		}

		UberSelectWithBrowser.prototype.setupUberSelect = function(){
			this.$originalInput.uberSelect({
				  allow_single_deselect  : true
				, inherit_select_classes : true
			});
			this.$uberSelect = this.$originalInput.next();
			this.uberSelect = this.$originalInput.data( "uberSelect" );
		};

		UberSelectWithBrowser.prototype.setupBrowser = function(){
			var iframeSrc   = this.$originalInput.data( "browserUrl" )
			  , modalTitle  = this.$originalInput.data( "modalTitle" )
			  , iframeId    = this.$originalInput.attr('id') + "_browser_frame"
			  , uberBrowser = this;

			this.$browserIframeContainer = $( '<div id="' + iframeId + '" style="display:none;"><iframe src="' + iframeSrc + '" width="800" height="300" frameBorder="0"></iframe></div>' );
			this.$browserButton = $( '<a class="btn btn-default" data-toggle="bootbox-modal" href="#' + iframeId + '" title="' + modalTitle + '"><i class="fa fa-ellipsis-h"></i></a>' );

			this.$uberSelect.after( this.$browserIframeContainer );
			this.$uberSelect.after( this.$browserButton );

			this.$browserButton.data( 'modalClass', 'uber-browser-dialog' );
			this.$browserButton.on( 'bootboxModalok', function(){
				uberBrowser.processDialogOk();
			} );
		};

		UberSelectWithBrowser.prototype.processDialogOk = function(){
			var iFramePicker = this.getPickerIframe();

			if ( typeof iFramePicker !== "undefined" ) {
				var selectedAssets = iFramePicker.getSelected()
				  , i=0, len = selectedAssets.length;

				for( ; i<len; i++ ){
					this.uberSelect.select( selectedAssets[i] );
				}
			}
		};

		UberSelectWithBrowser.prototype.getPickerIframe = function(){
			var $iframe = $( '.modal-dialog iframe' )
			if ( $iframe.length ) {
				return $iframe.get(0).contentWindow.uberBrowser;
			}
		};

		return UberSelectWithBrowser;
	})();


	$.fn.uberSelectWithBrowser = function(){
		return this.each( function(){
			new UberSelectWithBrowser( $(this) );
		} );
	};

} )( presideJQuery );