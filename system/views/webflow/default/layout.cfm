<!---@feature webflow--->
<cfscript>
	renderedStep     = args.renderedStep     ?: "";
	messages         = args.messages         ?: "";
	progressBar      = args.progressBar      ?: "";
	title            = args.title            ?: "";
	introCopy        = args.introCopy        ?: "";
	actions          = args.actions          ?: "";
	formId           = args.formId           ?: "";
	formAction       = args.formAction       ?: "";
	layoutClass      = args.layoutClass      ?: "webflow-layout";
	hiddenFormFields = args.hiddenFormFields ?: "";
	includeForm      = !IsTrue( args.noForm ?: "" );
</cfscript>

<cfoutput>
	<div class="#layoutClass#">
		#progressBar#
		#messages#
		#title#
		#introCopy#

		<cfif includeForm>
			<form id="#formId#" class="webflow-form" action="#formAction#" method="post" enctype="multipart/form-data" novalidate>
				#hiddenFormFields#
		</cfif>

		#renderedStep#
		#actions#

		<cfif includeForm>
			</form>
		</cfif>
	</div>
</cfoutput>