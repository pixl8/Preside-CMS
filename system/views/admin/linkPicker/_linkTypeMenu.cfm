<cfscript>
	param name="args.selectedType" type="string";

	baseUrl = event.buildAdminLink( linkTo="linkpicker", querystring="type=" );
</cfscript>

<cfoutput>
	<ul class="list-unstyled link-type-list">
		<li class="link-type<cfif args.selectedType eq 'sitetreelink'> selected</cfif>">
			<cfif args.selectedType eq "sitetreelink">
				Sitetree page
			<cfelse>
				<a href="#baseUrl#sitetreelink">Sitetree page</a>
			</cfif>
		</li>
		<li class="link-type<cfif args.selectedType eq 'url'> selected</cfif>">
			<cfif args.selectedType eq "url">
				URL
			<cfelse>
				<a href="#baseUrl#url">URL</a>
			</cfif>
		</li>
		<li class="link-type<cfif args.selectedType eq 'email'> selected</cfif>">
			<cfif args.selectedType eq "email">
				Email
			<cfelse>
				<a href="#baseUrl#email">Email</a>
			</cfif>
		</li>
	</ul>
</cfoutput>