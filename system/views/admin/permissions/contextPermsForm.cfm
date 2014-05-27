<cfscript>
	formId       = "managePermsForm-" & CreateUUId();
	saveAction   = args.saveAction   ?: event.buildAdminLink( linkTo="permissions.saveContextPermsAction" );
	cancelAction = args.cancelAction ?: cgi.http_referer;
</cfscript>

<cfoutput>
	<form id="#formId#" data-auto-focus-form="true" data-dirty-form="protect" class="form-horizontal manage-context-permissions-form" method="post" action="#saveAction#">


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