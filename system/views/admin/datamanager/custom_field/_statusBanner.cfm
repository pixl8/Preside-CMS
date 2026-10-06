<!---@feature admin and customFields--->
<cfscript>
	isActive     = IsTrue( args.active ?: "" );
	objectTitle  = args.objectTitle  ?: "";
	toggleLink   = args.toggleLink   ?: "";
	toggleLabel  = args.toggleLabel  ?: "";
	togglePrompt = args.togglePrompt ?: "";
	alertClass   = isActive ? "alert-success" : "alert-warning";
	iconClass    = isActive ? "fa-check-circle" : "fa-eye-slash";
	statusKey    = isActive ? "active" : "inactive";
	btnClass     = isActive ? "btn-warning" : "btn-success";
	btnIcon      = isActive ? "fa-eye-slash" : "fa-check";
</cfscript>
<cfoutput>
	<div class="alert #alertClass#">
		<p>
			<i class="fa fa-fw #iconClass#"></i>
			<strong>#translateResource( uri="preside-objects.custom_field:status.#statusKey#.title" )#</strong>
			#translateResource( uri="preside-objects.custom_field:status.#statusKey#.description", data=[ objectTitle ] )#
		</p>
		<cfif Len( toggleLink )>
			<br>
			<a class="btn btn-sm #btnClass# confirmation-prompt" href="#toggleLink#" title="#EncodeForHtmlAttribute( togglePrompt )#">
				<i class="fa fa-fw #btnIcon#"></i>
				#toggleLabel#
			</a>
		</cfif>
	</div>
</cfoutput>
