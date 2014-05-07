<cfparam name="args.title"         field="page.label"        editable="true" />
<cfparam name="args.main_content"  field="page.main_content" editable="true" />

<cfoutput>
	<h1>#args.title#</h1>
	#args.main_content#
</cfoutput>