<cfscript>
	param name="args.selectedType" type="string";
	param name="args.allowedTypes" type="any" default="sitetreelink,url,email,asset,anchor";

	if ( IsSimpleValue( args.allowedTypes ) ) {
		args.allowedTypes = ListToArray( args.allowedTypes );
	}
</cfscript>

<cfoutput>
	<ul class="list-unstyled link-type-list">
		<cfloop array="#args.allowedTypes#" index="i" item="allowedType">
			<li class="link-type<cfif args.selectedType eq allowedType> selected</cfif>">
				<a href="##fieldset-#translateResource( uri="cms:ckeditor.linkpicker.type.#allowedType#.fieldset.id", defaultValue=allowedType )#" class="link-type-link" data-link-type="#allowedType#">#translateResource( "cms:ckeditor.linkpicker.type.#allowedType#")#</a>
			</li>
		</cfloop>
	</ul>
</cfoutput>