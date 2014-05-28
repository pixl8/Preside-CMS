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
	<table class="table manage-context-permissions">
		<tbody>
			<cfloop array="#args.permissionKeys#" index="i" item="key">
				<tr>
					<td class="permission-col">
						<h4>#translateResource( uri="permissions:#key#.title"      , defaultValue=key )#</h4>
						<p> #translateResource( uri="permissions:#key#.description", defaultValue=""  )#</p>
					</td>
					<td class="edit-col">
						<form data-auto-focus-form="true" data-dirty-form="protect" method="post" action="#args.saveAction#">
							<input type="hidden" name="permissionKey"  value="#key#">
							<input type="hidden" name="context"        value="#args.context#">
							<input type="hidden" name="contextKey"     value="#args.contextKey#">

							<div class="groups-list">
								#renderView( view="admin/permissions/_editableGroupsList", args={
									  savedPerms     = args.savedPermissions[ key ].granted ?: []
									, inheritedPerms = args.inheritedPermissions[ key ].granted ?: []
									, title          = grantTitle
									, icon           = "check-circle"
								} )#

								#renderView( view="admin/permissions/_editableGroupsList", args={
									  savedPerms     = args.savedPermissions[ key ].denied ?: []
									, inheritedPerms = args.inheritedPermissions[ key ].denied ?: []
									, title          = denyTitle
									, icon           = "times-circle"
								} )#
							</div>

							<div class="groups-input row">
								#renderView( view="admin/permissions/_editableGroupsInput", args={
									  controlName    = "grant"
									, savedPerms     = args.savedPermissions[ key ].granted ?: []
									, inheritedPerms = args.inheritedPermissions[ key ].granted ?: []
									, title          = grantTitle
								} )#

								#renderView( view="admin/permissions/_editableGroupsInput", args={
									  controlName    = "deny"
									, savedPerms     = args.savedPermissions[ key ].denied ?: []
									, inheritedPerms = args.inheritedPermissions[ key ].denied ?: []
									, title          = denyTitle
								} )#

								<div class="col-sm-4">
									<div class="context-permission-form-buttons">
										<a class="btn btn-default context-permission-form-cancel-button">
											<i class="fa fa-reply bigger-110"></i>
											#translateResource( "cms:contextperms.cancel.btn" )#
										</a>

										<button class="btn btn-info" type="submit" tabindex="#getNextTabIndex()#">
											<i class="fa fa-ok bigger-110"></i>
											#translateResource( "cms:contextperms.save.btn" )#
										</button>
									</div>
								</div>
							</div>

						</form>
					</td>
				</tr>
			</cfloop>
		</tbody>
	</table>
</cfoutput>