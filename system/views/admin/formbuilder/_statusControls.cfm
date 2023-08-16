<cfscript>
	formId      = args.id ?: "";
	canLock     = IsTrue( args.canLock     ?: "" );
	canActivate = IsTrue( args.canActivate ?: "" );
	active      = IsTrue( args.active      ?: "" );
	locked      = IsTrue( args.locked      ?: "" );

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

		<div class="btn-group pull-right">
			<button data-toggle="dropdown" class="btn btn-sm btn-default inline">
				<span class="fa fa-caret-down"></span>
				Form options
			</button>

			<ul class="dropdown-menu pull-right" role="menu" aria-labelledby="dLabel">
				<li><a href="#event.buildAdminLink( linkto="formbuilder.importForm", queryString="formid=#formId#" )#"><i class="fa fa-fw fa-file-import"></i>&nbsp; Import form</a></li>
				<li><a href="#event.buildAdminLink( linkto="formbuilder.exportFormAction", queryString="formid=#formId#" )#"><i class="fa fa-fw fa-file-export"></i>&nbsp; Export form</a></li>
			</ul>
		</div>

		<a class="pull-right inline" href="#event.buildAdminLink( linkto="formbuilder.exportSubmissions", queryString="formid=#formId#" )#">
			<button class="btn btn-success btn-sm">
				<i class="fa fa-cloud-download"></i>
				#translateResource( "formbuilder:excel.download.link" )#
			</button>
		</a>
	</div>
</cfoutput>