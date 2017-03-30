( function( $ ){
	$( ".static-data-table" ).each( function(){
		var $listingTable  = $( this )
		  , objectTitle    = $listingTable.data( "objectTitle" ) || i18n.translateResource( "cms:datamanager.record" );



		$listingTable.dataTable({
			sDom : "<'well'fr>t<'dataTables_pagination bottom'<'pull-left'i><'pull-left'l><'pull-right'p><'clearfix'>",
			fnInitComplete : function( settings ){
				var $searchContainer = $( settings.aanFeatures.f[0] )
				  , $input           = $searchContainer.find( "input" ).first();

				$input.addClass( "data-table-search" );
				$input.attr( "data-global-key", "s" );
				$input.attr( "autocomplete", "off" );
				$input.wrap( '<span class="input-icon"></span>' );
				$input.after( '<i class="fa fa-search data-table-search-icon"></i>' );

				$input.keydown( "down", function( e ){
					var $firstResult = $listingTable.find( 'tbody tr:first a:first' );

					if ( $firstResult.length ) {
						$firstResult.focus();
					}
				} );
			},
			oLanguage : {
				oAria : {
					sSortAscending : i18n.translateResource( "cms:datatables.sortAscending", {} ),
					sSortDescending : i18n.translateResource( "cms:datatables.sortDescending", {} )
				},
				oPaginate : {
					sFirst : i18n.translateResource( "cms:datatables.first", { data : [objectTitle], defaultValue : "" } ),
					sLast : i18n.translateResource( "cms:datatables.last", { data : [objectTitle], defaultValue : "" } ),
					sNext : i18n.translateResource( "cms:datatables.next", { data : [objectTitle], defaultValue : "" } ),
					sPrevious : i18n.translateResource( "cms:datatables.previous", { data : [objectTitle], defaultValue : "" } )
				},
				sEmptyTable : i18n.translateResource( "cms:datatables.emptyTable", { data : [objectTitle], defaultValue : "" } ),
				sInfo : i18n.translateResource( "cms:datatables.info", { data : [objectTitle], defaultValue : "" } ),
				sInfoEmpty : i18n.translateResource( "cms:datatables.infoEmpty", { data : [objectTitle], defaultValue : "" } ),
				sInfoFiltered : i18n.translateResource( "cms:datatables.infoFiltered", { data : [objectTitle], defaultValue : "" } ),
				sInfoThousands : i18n.translateResource( "cms:datatables.infoThousands", { data : [objectTitle], defaultValue : "" } ),
				sLengthMenu : i18n.translateResource( "cms:datatables.lengthMenu", { data : [objectTitle], defaultValue : "" } ),
				sLoadingRecords : i18n.translateResource( "cms:datatables.loadingRecords", { data : [objectTitle], defaultValue : "" } ),
				sProcessing : i18n.translateResource( "cms:datatables.processing", { data : [objectTitle], defaultValue : "" } ),
				sZeroRecords : i18n.translateResource( "cms:datatables.zeroRecords", { data : [objectTitle], defaultValue : "" } ),
				sSearch : '',
				sUrl : '',
				sInfoPostFix : ''
			}
		});
	} );
} )( presideJQuery );