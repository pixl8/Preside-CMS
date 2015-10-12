( function( $ ){

	var ImageDimensionPicker;

	ImageDimensionPicker = (function() {
		var picker;

		function ImageDimensionPicker( $originalInput ) {
			picker = this;

			picker.$originalInput = $originalInput;

			picker.setupHtml();
		}

		ImageDimensionPicker.prototype.setupHtml = function(){
			var dimensions = picker.calculateDimensions( picker.$originalInput.val() );

			picker.$html = $( '<span class="image-dimensions-picker-wrapper">\
			                      <input type="number" class="image-dimensions-picker-input image-dimensions-picker-width"  value="' + dimensions.width  + '" title="' + i18n.translateResource( "cms:width"  ) + '" />\
			                      <i class="fa fa-unlock image-dimensions-picker-maintain-ratio"></i>\
			                      <input type="number" class="image-dimensions-picker-input image-dimensions-picker-height" value="' + dimensions.height + '" title="' + i18n.translateResource( "cms:height" ) + '" />\
			                   </span>' );

			picker.$originalInput.attr( "type", "hidden" );
			picker.$originalInput.after( picker.$html );

			picker.setupWidthAndHeightInputs();
			picker.setupAspectRatioToggler();
		};

		ImageDimensionPicker.prototype.updateHiddenVal = function(){
			var width  = parseInt( picker.$width.val() )
			  , height = parseInt( picker.$height.val() );

			if ( isNaN( width ) || isNaN( height ) ) {
				picker.$originalInput.val( "" );
			} else {
				picker.$originalInput.val( width + "x" + height );
			}
		};

		ImageDimensionPicker.prototype.calculateDimensions = function( val ){
			var dimensions = val.split( "x" )
			  , width      = dimensions.length ? dimensions[0] : ""
			  , height     = dimensions.length > 1 ? dimensions[1] : ""

			width  = width.length  ? parseInt( width )  : "";
			height = height.length ? parseInt( height ) : "";

			picker.setAspectRatio( isNaN( width  ) || isNaN( height ) ? parseInt( "" ) : width / height );

			return {
				  width  : isNaN( width  ) ? "" : width
				, height : isNaN( height ) ? "" : height
			};
		};

		ImageDimensionPicker.prototype.setupWidthAndHeightInputs = function(){
			var originalTabIndex = picker.$originalInput.attr( 'tabindex' );

			picker.$width  = picker.$html.find( '.image-dimensions-picker-width' );
			picker.$height = picker.$html.find( '.image-dimensions-picker-height' );

			picker.$width.change( function( e ){
				picker.isAspectRatioLocked() && picker.setHeightBasedOnWidth();
				picker.updateHiddenVal();
			} );
			picker.$height.change( function( e ){
				picker.isAspectRatioLocked() && picker.setWidthBasedOnHeight();
				picker.updateHiddenVal();
			} );

			if ( !isNaN( parseInt( originalTabIndex ) ) ) {
				picker.$width.attr( 'tabindex', originalTabIndex );
				picker.$height.attr( 'tabindex', originalTabIndex );
			}
		};

		ImageDimensionPicker.prototype.setupAspectRatioToggler = function(){
			picker.$aspectRatioToggle = this.$html.find( '.image-dimensions-picker-maintain-ratio' );
			picker.$aspectRatioToggle.click( function( e ){
				e.preventDefault();
				if ( picker.isAspectRatioTogglerEnabled() ) {
					picker.lockAspectRatio( !picker.isAspectRatioLocked() );
					if ( picker.isAspectRatioLocked() ) {
						picker.setHeightBasedOnWidth();
					}
				}
			} );

			if ( isNaN( picker.ratio ) ) {
				picker.enableAspectRatioToggler( false );
			} else {
				picker.enableAspectRatioToggler( true );
				picker.lockAspectRatio( true );
			}
		};

		ImageDimensionPicker.prototype.setAspectRatio = function( ratio ){
			picker.ratio = ratio;
		};

		ImageDimensionPicker.prototype.isAspectRatioLocked = function( ratio ){
			return picker.$aspectRatioToggle.hasClass( "fa-lock" );
		};

		ImageDimensionPicker.prototype.lockAspectRatio = function( locked ){
			picker.$aspectRatioToggle.removeClass( locked ? "fa-unlock" : "fa-lock" );
			picker.$aspectRatioToggle.addClass( locked ? "fa-lock" : "fa-unlock" );
		};

		ImageDimensionPicker.prototype.enableAspectRatioToggler = function( enabled ){
			if ( enabled ) {
				picker.$aspectRatioToggle.removeClass( "disabled" );
			} else {
				picker.$aspectRatioToggle.addClass( "disabled" );
				picker.lockAspectRatio( false );
			}
		};

		ImageDimensionPicker.prototype.isAspectRatioTogglerEnabled = function(){
			return !picker.$aspectRatioToggle.hasClass( "disabled" );
		};

		ImageDimensionPicker.prototype.reset = function( width, height ){
			var dimensions = picker.calculateDimensions( width + "x" + height );

			picker.$width.val( dimensions.width );
			picker.$height.val( dimensions.height );
			picker.updateHiddenVal();

			if ( isNaN( picker.ratio ) ) {
				picker.enableAspectRatioToggler( false );
			} else {
				picker.enableAspectRatioToggler( true );
				picker.lockAspectRatio( true );
			}
		};

		ImageDimensionPicker.prototype.setHeightBasedOnWidth = function(){
			var width = parseInt( picker.$width.val() );

			if ( !isNaN( width ) && !isNaN( picker.ratio ) ) {
				picker.$height.val( parseInt( width / picker.ratio ) );
			}
		};
		ImageDimensionPicker.prototype.setWidthBasedOnHeight = function(){
			var height = parseInt( picker.$height.val() );

			if ( !isNaN( height ) && !isNaN( picker.ratio ) ) {
				picker.$width.val( parseInt( height * picker.ratio ) );
			}
		};

		return ImageDimensionPicker;
	} )();

	$.fn.imageDimensionPicker = function(){
		return this.each( function(){
			var $originalInput = $(this)
			  , picker         = new ImageDimensionPicker( $originalInput );

			$originalInput.data( "ImageDimensionPicker", picker );

			return picker;
		} );
	};

} )( presideJQuery );