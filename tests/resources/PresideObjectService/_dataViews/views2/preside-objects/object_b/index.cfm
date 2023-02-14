<cfparam name="args.title"       type="string" field="label" />
<cfparam name="args.createdDate" type="string" field="datecreated" />

<cfoutput>
	<h1>#args.title#</h1>
	<p> #args.createdDate#</p>
</cfoutput>