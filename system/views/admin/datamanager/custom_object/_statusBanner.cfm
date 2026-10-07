<!---@feature admin and customObjects--->
<cfscript>
	isActive     = IsTrue( args.active ?: "" );
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
			<strong>#translateResource( uri="preside-objects.custom_object:status.#statusKey#.title" )#</strong>
			#translateResource( uri="preside-objects.custom_object:status.#statusKey#.description" )#
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
