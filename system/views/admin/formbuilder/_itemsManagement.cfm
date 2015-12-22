<cfscript>
	items = args.items ?: [];
</cfscript>

<cfoutput>
	<cfif !items.len()>
		<div class="instructions">
			<p>#translateResource( "formbuilder:manage.empty.form.notice")#</p>
			<i class="fa fa-fw fa-lg fa-plus blue"></i>
		</div>
	</cfif>

	<ul class="list-unstyled">
	</ul>
</cfoutput>