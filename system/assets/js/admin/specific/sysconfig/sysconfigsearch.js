/**
 * This script controls the behaviour of the object listing table
 */
( function( $ ){

	$.fn.sysconfigTable = function(){
		return this.each( function(){
			var $sysconfigTable  = $( this )
			  , $resultDiv = $(this).find(".sysconfig_results").first()
			  , tableSettings = $(this).data()
			  , $searchInput     = $sysconfigTable.find( "input" ).first()
			  , searchDelay      = 400
			  , datasourceUrl    = tableSettings.datasourceUrl     || cfrequest.datasourceUrl  || buildAdminLink( "sysconfig.quicksearch")
			  , noRecordMessage  = tableSettings.noRecordMessage   || i18n.translateResource( "cms:datatables.emptyTable" )
			  , oTimerId;

   				$searchInput.bind( 'keyup', function() {
   					window.clearTimeout( oTimerId );
					oTimerId = window.setTimeout( function() {
						$.post( datasourceUrl, { sSearch : $searchInput.val() }, function(h) {
							if ( h==="") {
								$resultDiv.html( noRecordMessage )
							} else {
								$resultDiv.html( h )
							}
						});
					}, searchDelay );
				});


		} );
	};

	$( '.sysconfig-table' ).sysconfigTable();

} )( presideJQuery );