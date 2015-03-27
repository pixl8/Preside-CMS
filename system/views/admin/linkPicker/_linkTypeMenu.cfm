<cfscript>
	param name="args.selectedType" type="string";
	param name="args.allowedTypes" type="string" default="sitetreelink,url,email,anchor";
</cfscript>

<cfoutput>
	<ul class="list-unstyled link-type-list">
		<cfif ListFindNoCase( args.allowedTypes, "sitetreelink" )>
			<li class="link-type<cfif args.selectedType eq 'sitetreelink'> selected</cfif>">
				<a href="##fieldset-sitetree" class="link-type-link" data-link-type="sitetreelink">#translateResource( "cms:ckeditor.linkpicker.type.sitetreelink")#</a>
			</li>
		</cfif>
		<cfif ListFindNoCase( args.allowedTypes, "url" )>
			<li class="link-type<cfif args.selectedType eq 'url'> selected</cfif>">
				<a href="##fieldset-url" class="link-type-link" data-link-type="url">#translateResource( "cms:ckeditor.linkpicker.type.url")#</a>
			</li>
		</cfif>
		<cfif ListFindNoCase( args.allowedTypes, "email" )>
			<li class="link-type<cfif args.selectedType eq 'email'> selected</cfif>">
				<a href="##fieldset-email" class="link-type-link" data-link-type="email">#translateResource( "cms:ckeditor.linkpicker.type.email")#</a>
			</li>
		</cfif>
		<cfif ListFindNoCase( args.allowedTypes, "asset" )>
			<li class="link-type<cfif args.selectedType eq 'asset'> selected</cfif>">
				<a href="##fieldset-asset" class="link-type-link" data-link-type="asset">#translateResource( "cms:ckeditor.linkpicker.type.asset")#</a>
			</li>
		</cfif>
		<cfif ListFindNoCase( args.allowedTypes, "anchor" )>
			<li class="link-type<cfif args.selectedType eq 'anchor'> selected</cfif>">
				<a href="##fieldset-anchor" class="link-type-link" data-link-type="anchor">#translateResource( "cms:ckeditor.linkpicker.type.anchor")#</a>
			</li>
		</cfif>
	</ul>
</cfoutput>