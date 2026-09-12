( function( $ ){
	var ext = $.fn.dataTableExt || ( $.fn.dataTable && $.fn.dataTable.ext );

	if ( !ext ) {
		return;
	}
	ext.oApi = ext.oApi || {};
	ext.oApi.fnSetFilteringDelay = function() {
		return this;
	};

	if ( $.fn.dataTable && $.fn.dataTable.Api ) {
		$.fn.dataTable.Api.register( "fnSetFilteringDelay()", function() {
			return this;
		} );
	}
} )( presideJQuery );
