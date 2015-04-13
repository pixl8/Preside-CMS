<cfparam name="args.isCurrentVersion" type="boolean" />
<cfparam name="args.id"               type="string"  />
<cfparam name="args.asset"            type="string"  />
<cfparam name="args.version_number"   type="string"  />
<cfparam name="args.asset_type"       type="string"  />
<cfparam name="args.size"             type="string"  />
<cfparam name="args.datecreated"      type="date"    />

<cfoutput>
	<figure class="<cfif args.isCurrentVersion> current-version</cfif>">
		<div class="edit-asset-preview pull-left">
			#renderAsset( assetId=args.asset, context="adminPreview", args={ versionId=args.id } )#
		</div>
		<figcaption class="pull-left">
			<h4 class="title">
				<i class="fa fa-fw <cfif args.isCurrentVersion>fa-check green<cfelse>fa-ban</cfif>"></i>
				#translateResource( uri="cms:assetmanager.versionpreview.version.title", data=[ args.version_number ] )#
			</h4>

			<i class="fa fa-fw fa-info-circle"></i>
			#translateResource( uri="cms:assetmanager.versionpreview.info", data=[ FileSizeFormat( args.size ), args.asset_type, renderContent( 'datetime', args.datecreated ) ] )#<br><br>

			<a href="#event.buildLink( assetId=args.asset, versionId=args.id )#" target="_blank">
				<i class="fa fa-fw fa-download blue"></i>
				#translateResource( uri="cms:assetmanager.download.asset.link" )#
			</a><br>
			<cfif not args.isCurrentVersion>
				<a href="#event.buildAdminLink( linkTo='assetManager.makeVersionActiveAction', querystring='asset=#args.asset#&version=#args.id#' )#">
					<i class="fa fa-fw fa-check green"></i>
					#translateResource( uri="cms:assetmanager.versionpreview.makeactive.link" )#

				</a><br>
				<a href="##">
					<i class="fa fa-fw fa-trash red"></i>
					#translateResource( uri="cms:assetmanager.versionpreview.delete.link" )#
				</a><br>
			</cfif>
		</figcaption>
		<div class="clearfix"></div><br>
	</figure>
</cfoutput>