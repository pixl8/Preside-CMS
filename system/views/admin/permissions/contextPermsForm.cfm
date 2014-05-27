<cfscript>
	param name="args.saveAction"       type="string";
	param name="args.cancelAction"     type="string";
	param name="args.permissionKeys"   type="array";
	param name="args.savedPermissions" type="struct";
	param name="args.context"          type="string";
	param name="args.contextKey"       type="string";

	event.include( "/css/admin/specific/contextPermsForm/" );
</cfscript>

<cfoutput>
	<form data-auto-focus-form="true" data-dirty-form="protect" class="form-horizontal manage-context-permissions-form" method="post" action="#args.saveAction#">
		<input type="hidden" name="permissionKeys" value="#args.permissionKeys.toList()#">
		<input type="hidden" name="context"        value="#args.context#">
		<input type="hidden" name="contextKey"     value="#args.contextKey#">

		<table class="table">
			<thead>
				<tr>
					<th class="permission-col">Permission</th>
					<th class="edit-col">Grant to</th>
					<th class="edit-col">Deny to</th>
				</tr>
			</thead>
			<tbody>
				<cfloop array="#args.permissionKeys#" index="i" item="key">
					<tr>
						<td class="permission-col">
							<h4>#translateResource( uri="permissions:#key#.title"      , defaultValue=key )#</h4>
							<p> #translateResource( uri="permissions:#key#.description", defaultValue=""  )#</p>
						</td>
						<td class="edit-col">
							#renderFormControl(
								  name         = "grant." & key
								, type         = "objectPicker"
								, object       = "security_group"
								, multiple     = true
								, layout       = ""
								, placeholder  = "&nbsp;"
								, defaultValue = ( args.savedPermissions[ key ].granted ?: [] ).toList()
							)#
						</td>
						<td class="edit-col">
							#renderFormControl(
								  name         = "deny." & key
								, type         = "objectPicker"
								, object       = "security_group"
								, multiple     = true
								, layout       = ""
								, placeholder  = "&nbsp;"
								, defaultValue = ( args.savedPermissions[ key ].denied ?: [] ).toList()
							)#
						</td>
					</tr>
				</cfloop>
			</tbody>
		</table>

		<div class="form-actions row">
			<div class="col-md-offset-2">
				<a href="#args.cancelAction#" class="btn btn-default" data-global-key="c">
					<i class="fa fa-reply bigger-110"></i>
					#translateResource( "cms:contextperms.cancel.btn" )#
				</a>

				<button class="btn btn-info" type="submit" tabindex="#getNextTabIndex()#">
					<i class="fa fa-ok bigger-110"></i>
					#translateResource( "cms:contextperms.save.btn" )#
				</button>
			</div>
		</div>
	</form>
</cfoutput>