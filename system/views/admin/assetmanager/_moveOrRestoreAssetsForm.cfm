<cfoutput>
	<div id="restore-assets-form" class="hide">
		<form class="form-horizontal row" action="#event.buildAdminLink( linkTo = "assetmanager.restoreAssetsAction" )#" method="post">
			<input type="hidden" name="fromFolder" value="" />
			<input type="hidden" name="assets"     value="" />

			#renderFormControl(
				  name = "toFolder"
				, type = "assetFolderPicker"
				, label = translateResource( "preside-objects.asset:field.asset_folder.title" )
			)#
		</form>
	</div>

	<div id="move-assets-form" class="hide">
		<form class="form-horizontal row" action="#event.buildAdminLink( linkTo = "assetmanager.moveAssetsAction" )#" method="post">
			<input type="hidden" name="fromFolder" value="" />
			<input type="hidden" name="assets"     value="" />

			#renderFormControl(
				  name = "toFolder"
				, type = "assetFolderPicker"
				, label = translateResource( "preside-objects.asset:field.asset_folder.title" )
			)#
		</form>
	</div>
</cfoutput>