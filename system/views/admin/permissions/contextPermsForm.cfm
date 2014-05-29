<cfscript>
	param name="args.saveAction"           type="string";
	param name="args.cancelAction"         type="string";
	param name="args.permissionKeys"       type="array";
	param name="args.savedPermissions"     type="struct";
	param name="args.inheritedPermissions" type="struct";
	param name="args.context"              type="string";
	param name="args.contextKey"           type="string";

	event.include( "/css/admin/specific/contextPermsForm/" );
	event.include( "/js/admin/specific/contextPermsForm/" );

	grantTitle = translateResource( "cms:contextperms.grant.row.title" );
	denyTitle  = translateResource( "cms:contextperms.deny.row.title" );
</cfscript>

<cfoutput>
	<form class="manage-context-permissions-form" data-auto-focus-form="true" data-dirty-form="protect" method="post" action="#args.saveAction#">
		<input type="hidden" name="permissionKeys" value="#args.permissionKeys.toList()#">
		<input type="hidden" name="context"        value="#args.context#">
		<input type="hidden" name="contextKey"     value="#args.contextKey#">

		<table class="table">
			<tbody>
				<cfloop array="#args.permissionKeys#" index="i" item="key">
					<cfset savedGrants      = args.savedPermissions[ key ].granted     ?: [] />
					<cfset inheritedGrants  = args.inheritedPermissions[ key ].granted ?: [] />
					<cfset savedDenials     = args.savedPermissions[ key ].denied      ?: [] />
					<cfset inheritedDenials = args.inheritedPermissions[ key ].denied  ?: [] />

					<tr>
						<td class="permission-col">
							<h4>#translateResource( uri="permissions:#key#.title"      , defaultValue=key )#</h4>
							<p> #translateResource( uri="permissions:#key#.description", defaultValue=""  )#</p>
						</td>
						<td class="edit-col">

							<div class="groups-list">
								<div class="pull-left">
									#renderView( view="admin/permissions/_editableGroupsList", args={
										  savedPerms     = savedGrants
										, inheritedPerms = inheritedGrants
										, savedOpposites = savedDenials
										, title          = grantTitle
										, icon           = "check-circle"
									} )#

									#renderView( view="admin/permissions/_editableGroupsList", args={
										  savedPerms     = savedDenials
										, savedOpposites = savedGrants
										, inheritedPerms = inheritedDenials
										, title          = denyTitle
										, icon           = "minus-circle"
									} )#
								</div>

								<i class="fa fa-pencil edit-row-icon pull-right"></i>
							</div>

							<div class="groups-input">
								<div class="row">
									<div class="col-sm-11">
										<div class="row">
											#renderView( view="admin/permissions/_editableGroupsInput", args={
												  controlName    = "grant.#key#"
												, savedPerms     = savedGrants
												, inheritedPerms = inheritedGrants
												, title          = grantTitle
											} )#

											#renderView( view="admin/permissions/_editableGroupsInput", args={
												  controlName    = "deny.#key#"
												, savedPerms     = savedDenials
												, inheritedPerms = inheritedDenials
												, title          = denyTitle
											} )#

										</div>
									</div>
									<div class="col-sm-1">
										<i class="close-icon fa fa-lg fa-times-circle pull-right"></i>
									</div>
								</div>
							</div>

						</td>
					</tr>
				</cfloop>
			</tbody>
		</table>

		<div class="form-actions row">
			<a href="#args.cancelAction#" class="btn btn-default">
				<i class="fa fa-reply bigger-110"></i>
				#translateResource( "cms:contextperms.cancel.btn" )#
			</a>

			<button class="btn btn-info" type="submit" tabindex="#getNextTabIndex()#">
				<i class="fa fa-check bigger-110"></i>
				#translateResource( "cms:contextperms.save.btn" )#
			</button>
		</div>
	</form>
</cfoutput>