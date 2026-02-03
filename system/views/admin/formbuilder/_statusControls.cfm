<!---@feature admin and formbuilder--->
<cfscript>
	formId      = args.id ?: "";
	canLock     = IsTrue( args.canLock     ?: "" );
	canActivate = IsTrue( args.canActivate ?: "" );
	active      = IsTrue( args.active      ?: "" );
	locked      = IsTrue( args.locked      ?: "" );
	canEdit     = IsTrue( args.canEdit     ?: "" );
	canDelete   = IsTrue( args.canDelete   ?: "" );

	activeClass    = ( active ? "green"    : "grey" ) & " " & ( canActivate ? "enabled" : "disabled" );
	activeIcon     = active ? "fa-check" : "fa-times";
	activeTitle    = translateResource( "formbuilder:status.controls." & ( active ? "active" : "inactive" ) );
	activePrompt   = HtmlEditFormat( translateResource( "formbuilder:status.controls." & ( active ? "deactivate" : "activate" ) & ".prompt" ) );
	activeEndpoint = event.buildAdminLink( linkTo="formbuilder.activateAction", queryString="id=#formId#&activated=#( !active )#" );

	lockedClass    = ( locked ? "red"     : "grey" ) & " " & ( canLock ? "enabled" : "disabled" );
	lockedIcon     = locked ? "fa-lock" : "fa-unlock";
	lockedTitle    = translateResource( "formbuilder:status.controls." & ( locked ? "locked" : "unlocked" ) );
	lockedPrompt   = HtmlEditFormat( translateResource( "formbuilder:status.controls." & ( locked ? "unlock" : "lock" ) & ".prompt" ) );
	lockedEndpoint = event.buildAdminLink( linkTo="formbuilder.lockAction", queryString="id=#formId#&locked=#( !locked )#" );
</cfscript>

<cfoutput>
	<div class="top-right-button-group">
		<div class="formbuilder-status-controls">
			<label class="status-item control-label no-padding-right #activeClass#" for="form_active" data-prompt="#activePrompt#" data-endpoint="#activeEndpoint#">
				<i class="fa fa-fw #activeIcon#"></i>

				#activeTitle#

				<cfif canActivate>
					#renderFormControl(
						  name         = "form_active"
						, type         = "yesnoswitch"
						, context      = "admin"
						, id           = "form_active"
						, label        = "Active"
						, defaultValue = active
						, layout       = ""
					)#
				</cfif>
			</label>

			<label class="status-item control-label no-padding-right #lockedClass#" for="form_locked" data-prompt="#lockedPrompt#" data-endpoint="#lockedEndpoint#">
				<i class="fa fa-fw #lockedIcon#"></i>

				#lockedTitle#

				<cfif canLock>
					#renderFormControl(
						  name         = "form_locked"
						, type         = "yesnoswitch"
						, context      = "admin"
						, id           = "form_locked"
						, label        = "Locked"
						, defaultValue = locked
						, layout       = ""
					)#
				</cfif>
			</label>
		</div>

		<cfif canEdit or canDelete>
			<div class="btn-group pull-right">
				<button data-toggle="dropdown" class="btn btn-sm btn-default inline">
					<span class="fa fa-caret-down"></span>
					Form options
				</button>

				<ul class="dropdown-menu pull-right" role="menu" aria-labelledby="dLabel">
					<cfif canEdit>
						<li><a href="#event.buildAdminLink( linkto="formbuilder.exportFormFieldsAction", queryString="id=#formId#" )#"><i class="fa fa-fw fa-file-export"></i>&nbsp; #translateResource( "formbuilder:action.fields.export.title" )#</a></li>
					</cfif>
					<cfif canDelete>
						<li class="divider"></li>
						<li><a href="#event.buildAdminLink( linkto="formbuilder.deleteRecordAction", queryString="id=#formId#" )#" title="#translateResource( "formbuilder:action.form.delete.prompt" )#" class="red confirmation-prompt"><i class="fa fa-fw fa-trash-o"></i>&nbsp; #translateResource( "formbuilder:action.form.delete.title" )#</a></li>
					</cfif>
				</ul>
			</div>
		</cfif>

		<a class="pull-right inline" href="#event.buildAdminLink( linkto="formbuilder.exportSubmissions", queryString="formid=#formId#" )#">
			<button class="btn btn-success btn-sm">
				<i class="fa fa-cloud-download"></i>
				#translateResource( "formbuilder:action.submission.download.title" )#
			</button>
		</a>
	</div>
</cfoutput>