<cfscript>
	param name="args.selectedType" type="string";
</cfscript>

<cfoutput>
	<ul class="list-unstyled link-type-list">
		<li class="link-type<cfif args.selectedType eq 'sitetreelink'> selected</cfif>">
			<a href="##fieldset-sitetree" class="link-type-link" data-link-type="sitetreelink">#translateResource( "cms:ckeditor.linkpicker.type.sitetreelink")#</a>
		</li>
		<li class="link-type<cfif args.selectedType eq 'url'> selected</cfif>">
			<a href="##fieldset-url" class="link-type-link" data-link-type="url">#translateResource( "cms:ckeditor.linkpicker.type.url")#</a>
		</li>
		<li class="link-type<cfif args.selectedType eq 'email'> selected</cfif>">
			<a href="##fieldset-email" class="link-type-link" data-link-type="email">#translateResource( "cms:ckeditor.linkpicker.type.email")#</a>
		</li>
	</ul>
</cfoutput>