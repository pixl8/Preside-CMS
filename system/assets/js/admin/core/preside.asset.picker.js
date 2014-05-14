( function( $ ){

	var AssetPicker;

	AssetPicker = (function() {
		function AssetPicker( $originalInput ) {
			this.$originalInput = $originalInput;

			this.setupUberSelect();
			this.setupBrowser();
		}

		AssetPicker.prototype.setupUberSelect = function(){
			this.$originalInput.uberSelect({
				  allow_single_deselect  : true
				, inherit_select_classes : true
			});
			this.$uberSelect = this.$originalInput.next();
			this.uberSelect = this.$originalInput.data( "uberSelect" );
		};

		AssetPicker.prototype.setupBrowser = function(){
			var iframeSrc = this.$originalInput.data( "browserUrl" )
			  , iframeId  = this.$originalInput.attr('id') & "_browser_frame"
			  , assetPicker = this;

			this.$browserIframeContainer = $( '<div id="' + iframeId + '" style="display:none;"><iframe src="' + iframeSrc + '" width="800" height="300" frameBorder="0"></iframe></div>' );
			this.$browserButton = $( '<a class="btn btn-default" data-toggle="bootbox-modal" href="#' + iframeId + '" title="' + i18n.translateResource( "cms:assetmanager.browser.title" ) + '">...</a>' );

			this.$uberSelect.after( this.$browserIframeContainer );
			this.$uberSelect.after( this.$browserButton );

			this.$browserButton.data( 'modalClass', 'asset-picker-dialog' );
			this.$browserButton.on( 'bootboxModalok', function(){
				assetPicker.processDialogOk();
			} );
		};

		AssetPicker.prototype.processDialogOk = function(){
			var iFramePicker = this.getPickerIframe();

			if ( typeof iFramePicker !== "undefined" ) {
				var selectedAssets = iFramePicker.getSelected()
				  , i=0, len = selectedAssets.length;

				for( ; i<len; i++ ){
					this.uberSelect.select( selectedAssets[i] );
				}
			}
		};

		AssetPicker.prototype.getPickerIframe = function(){
			var $iframe = $( '.modal-dialog iframe' )
			if ( $iframe.length ) {
				return $iframe.get(0).contentWindow.assetPicker;
			}
		};

		return AssetPicker;
	})();


	$.fn.assetPicker = function(){
		return this.each( function(){
			new AssetPicker( $(this) );
		} );
	};

} )( presideJQuery );