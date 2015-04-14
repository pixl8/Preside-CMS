<cfparam name="args.title" type="string" />
<cfparam name="args.id"    type="string" />

<cfoutput>
	<a class="blue" href="#event.buildAdminLink( linkto="assetmanager.editAsset", querystring="asset=#args.id#" )#" data-context-key="e">
		<i class="fa fa-fw fa-pencil"></i>
	</a>
	<a class="green" href="#event.buildLink( assetId=args.id )#" data-context-key="w" title="#translateResource( uri="cms:assetmanager.download.asset.link", data=[ urlEncodedFormat( args.title ) ] )#" target="_blank">
		<i class="fa fa-fw fa-download"></i>
	</a>
	<a class="red confirmation-prompt" href="#event.buildAdminLink( linkTo="assetmanager.trashAssetAction", queryString="asset=#args.id#")#" data-context-key="d" title="#translateResource( uri="cms:assetmanager.trash.asset.link", data=[ urlEncodedFormat( args.title ) ] )#">
		<i class="fa fa-fw fa-trash-o"></i>
	</a>
</cfoutput>