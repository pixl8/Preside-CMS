<cfscript>
	formId         = "managePermsForm-" & CreateUUId();
	saveAction     = args.saveAction     ?: event.buildAdminLink( linkTo="permissions.saveContextPermsAction" );
	cancelAction   = args.cancelAction   ?: cgi.http_referer;
	permissionKeys = args.permissionKeys ?: [];

	event.include( "/css/admin/specific/contextPermsForm/" )
</cfscript>

<cfoutput>
	<form id="#formId#" data-auto-focus-form="true" data-dirty-form="protect" class="form-horizontal manage-context-permissions-form" method="post" action="#saveAction#">
		<input type="hidden" name="permissionKeys" value="#permissionKeys.toList()#">

		<table class="table">
			<thead>
				<tr>
					<th class="permission-col">Permission</th>
					<th class="edit-col">Grant to</th>
					<th class="edit-col">Deny to</th>
				</tr>
			</thead>
			<tbody>
				<cfloop array="#permissionKeys#" index="i" item="key">
					<tr>
						<td class="permission-col">
							<h4>#translateResource( uri="permissions:#key#.title"      , defaultValue=key )#</h4>
							<p> #translateResource( uri="permissions:#key#.description", defaultValue=""  )#</p>
						</td>
						<td class="edit-col">
							#renderFormControl(
								  name        = "grant." & key
								, type        = "objectPicker"
								, object      = "security_group"
								, multiple    = true
								, layout      = ""
								, placeholder = "&nbsp;"
							)#
						</td>
						<td class="edit-col">
							#renderFormControl(
								  name        = "deny." & key
								, type        = "objectPicker"
								, object      = "security_group"
								, multiple    = true
								, layout      = ""
								, placeholder = "&nbsp;"
							)#
						</td>
					</tr>
				</cfloop>
			</tbody>
		</table>

		<div class="form-actions row">
			<div class="col-md-offset-2">
				<a href="#cancelAction#" class="btn btn-default" data-global-key="c">
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