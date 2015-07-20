<cfscript>
	page             = event.getValue( name="page", defaultValue=QueryNew(''), private=true );
	childPages       = event.getValue( name="childPages", defaultValue=QueryNew(''), private=true );
	formId           = "editForm-" & CreateUUId();

	prc.pageIcon     = "sort-by-attributes";
	prc.pageTitle    = translateResource( uri="cms:sitetree.reorderChildren.title", data=[ prc.page.title ] );
</cfscript>

<cfoutput>
	<div class="dd" id="reorderable-children">
		<ol class="dd-list">
			<cfloop query="childPages">
				<li class="dd-item" data-id="#childPages.id#">
					<div class="dd-handle">#childPages.title#</div>
				</li>
			</cfloop>
		</ol>
	</div>

	<form id="reorder-form" data-dirty-form="toggleDisable,protect" action="#event.buildAdminLink( linkTo='sitetree.reorderChildrenAction' )#" method="post">
		<input type="hidden" value="#page.id#" name="id" />
		<input type="hidden" value="#ValueList( childPages.id )#" name="ordered" />

		<div class="form-actions">
			<div>
				<button id="reset-order-btn" class="btn btn-sm btn-default" type="submit">
					<i class="fa fa-reply bigger-110"></i>
					#translateResource( "cms:sitetree.reorderchildren.reset.btn" )#
				</button>
				<button class="btn btn-sm btn-success" type="submit">
					<i class="fa fa-check bigger-110"></i>
					#translateResource( "cms:sitetree.reorderchildren.submit.btn" )#
				</button>
			</div>
		</div>
	</form>
</cfoutput>