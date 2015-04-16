<cfscript>
	fromFolder   = htmlEditFormat( rc.fromFolder ?: "" );
	assets       = htmlEditFormat( rc.assets     ?: "" );
	submitAction = event.buildAdminLink( linkTo = "assetmanager.moveAssetsAction" );
</cfscript>
<cfoutput>
	<div id="move-assets-form" class="hide">
		<form class="form-horizontal row" action="#submitAction#" method="post">
			<input type="hidden" name="fromFolder" value="#fromFolder#" />
			<input type="hidden" name="assets"     value="" />

			#renderFormControl(
				  name = "toFolder"
				, type = "assetFolderPicker"
				, label = translateResource( "preside-objects.asset:field.asset_folder.title" )
			)#
		</form>
	</div>
</cfoutput>