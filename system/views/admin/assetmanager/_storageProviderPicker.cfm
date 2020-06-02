<cfparam name="args.providers" type="array" />
<cfset rootLink = event.buildAdminLink( linkto="assetManager.addLocation", queryString="provider=" ) />

<cfoutput>
	<a class="pull-right inline" href="##provider-dialog" data-global-key="a" data-toggle="bootbox-modal" data-buttons="cancel" data-modal-class="page-type-picker" data-title="#translateResource( 'cms:assetmanager.addLocation.dialog.title' )#">
		<button class="btn btn-success btn-sm">
			<i class="fa fa-plus"></i>
			#translateResource( "cms:assetmanager.addlocation.btn" )#
		</button>
	</a>

	<div id="provider-dialog" class="hide">
		<ul class="list-unstyled page-type-list">
			<cfloop array="#args.providers#" index="provider">
				<li class="page-type">
					<h3 class="page-type-title">
						<a href="#rootLink##provider.id#">
							<i class="page-type-icon fa fa-lg #provider.iconClass#"></i>
							#provider.title#
						</a>
					</h3>
					<p>#provider.description#</p>
				</li>
			</cfloop>
		</ul>
	</div>
</cfoutput>