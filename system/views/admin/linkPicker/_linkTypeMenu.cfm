<cfscript>
	param name="args.selectedType" type="string";
</cfscript>

<cfoutput>
	<ul class="list-unstyled link-type-list">
		<li class="link-type<cfif args.selectedType eq 'sitetreelink'> selected</cfif>">
			<a href="##fieldset-sitetree" class="link-type-link" data-link-type="sitetreelink">Sitetree page</a>
		</li>
		<li class="link-type<cfif args.selectedType eq 'url'> selected</cfif>">
			<a href="##fieldset-url" class="link-type-link" data-link-type="url">URL</a>
		</li>
		<li class="link-type<cfif args.selectedType eq 'email'> selected</cfif>">
			<a href="##fieldset-email" class="link-type-link" data-link-type="email">Email</a>
		</li>
	</ul>
</cfoutput>