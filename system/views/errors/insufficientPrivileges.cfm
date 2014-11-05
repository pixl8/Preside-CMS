<cfparam name="args.title"        field="page.title"        editable="true" />
<cfparam name="args.main_content" field="page.main_content" editable="true" />

<cfoutput>
	<h1>#args.title#</h1>
	<p>#args.main_content#</p>
</cfoutput>