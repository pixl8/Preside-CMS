<cfscript>
	prc.pageIcon  = "picture";
	prc.pageTitle = translateResource( "cms:assetManager" );
</cfscript>

<cfoutput>
	<div class="row">
		<div class="col-lg-8 col-md-8 col-sm-7 col-xs-6">
			#renderView( "admin/assetmanager/listingtable" )#
		</div>

		<div class="col-lg-4 col-md-4 col-sm-5 col-xs-6">
			#renderView( "admin/assetmanager/assetDropZone" )#
		</div>
	</div>
</cfoutput>