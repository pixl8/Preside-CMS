<cfscript>
	renderedProps = args.renderedProps ?: [];
</cfscript>

<cfoutput>
	<dl class="dl-horizontal">
		<cfloop array="#renderedProps#" item="prop" index="i">
			<dt>#prop.propertyTitle#</dt>
			<dd>#prop.rendered#</dd>
		</cfloop>
	</dl>
</cfoutput>