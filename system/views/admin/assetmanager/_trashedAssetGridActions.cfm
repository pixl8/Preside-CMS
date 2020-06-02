<cfparam name="args.title"        type="string" />
<cfparam name="args.id"           type="string" />
<cfparam name="args.asset_folder" type="string" />

<cfoutput>
	<a class="green" href="#event.buildLink( assetId=args.id, trashed=true )#" data-context-key="w" title="#translateResource( uri="cms:assetmanager.download.asset.link", data=[ htmlEditFormat( args.title ) ] )#" target="_blank">
		<i class="fa fa-fw fa-download"></i></a>

	<a class="blue" href="##restore-assets-form" data-context-key="r" data-asset-id="#args.id#" data-folder-id="#args.asset_folder#" data-toggle="move-assets-dialog" data-dialog-title="#translateResource( uri='cms:assetmanager.restore.single.asset.dialog.title', data=[ htmlEditFormat( args.title ) ] )#">
		<i class="fa fa-fw fa-magic"></i></a>

	<a class="red confirmation-prompt" href="#event.buildAdminLink( linkTo="assetmanager.trashAssetAction", queryString="asset=#args.id#")#" data-context-key="d" title="#translateResource( uri="cms:assetmanager.permanentlydelete.asset.link", data=[ urlEncodedFormat( args.title ) ] )#">
		<i class="fa fa-fw fa-trash-o"></i></a>
</cfoutput>