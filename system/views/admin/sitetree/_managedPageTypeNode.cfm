<cfparam name="args.depth"    type="numeric" />
<cfparam name="args.pagetype" type="string" />
<cfparam name="args.parentId" type="string" />

<cfset compoundId = "#args.parentId#_#args.pageType#" />

<cfoutput>
	<tr class="depth-#args.depth#" data-id="#compoundId#" data-parent="#args.parentId#" data-depth="#args.depth#" data-context-container="#compoundId#">
		<td colspan="5" class="managed-page-type-link-cell">
			<i class="fa fa-fw fa-ellipsis-h page-type-icon"></i>
			<a href="#quickBuildLink( args.managedChildrenBaseLink, { id=args.parentId, type=args.pageType } )#">#translateResource( uri="cms:sitetree.manage.type", data=[ LCase( translateResource( "page-types.#args.pageType#:name" ) ) ] )#</a>
		</td>
	</tr>
</cfoutput>