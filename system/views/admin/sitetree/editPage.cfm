<cfscript>
	page             = prc.page            ?: QueryNew('');
	mainFormName     = prc.mainFormName    ?: ""
	mergeFormName    = prc.mergeFormName   ?: ""
	validationResult = rc.validationResult ?: "";
	formId           = "editForm-" & CreateUUId();
	editPagePrompt    = translateResource( uri="preside-objects.page:editRecord.prompt", defaultValue="" );

	prc.pageIcon     = "pencil";
	prc.pageTitle    = translateResource( uri="cms:sitetree.editPage.title", data=[ prc.page.label ] );

	safeTitle = HtmlEditFormat( page.label );
</cfscript>

<cfoutput>
	<div class="top-right-button-group">

		<cfif page.id neq ( prc.homepage.id ?: "" )>
			<a class="pull-right inline confirmation-prompt" href="#event.buildAdminLink( linkTo="sitetree.trashPageAction", queryString="id=#page.id#")#" data-global-key="d" title="#translateResource( uri="cms:sitetree.trash.child.page.link", data=[ safeTitle ] )#">
				<button class="btn btn-danger btn-sm">
					<i class="fa fa-trash-o"></i>
					#translateResource( uri="cms:sitetree.trash.child.page.btn", data=[ safeTitle ] )#
				</button>
			</a>
		</cfif>
		<!---
TODO wire this into the same dialog as that used on the site tree
		<a class="pull-right inline" href="#event.buildAdminLink( linkTo="sitetree.addPage", queryString="parent_page=#page.id#" )#" data-global-key="a">
			<button class="btn btn-success btn-sm">
				<i class="fa fa-plus"></i>
				#translateResource( "cms:sitetree.add.child.page.btn" )#
			</button>
		</a>--->
		<a class="pull-right inline" href="#event.buildLink( page=page.id )#" data-global-key="p" target="_blank">
			<button class="btn btn-info btn-sm">
				<i class="fa fa-external-link"></i>
				#translateResource( "cms:sitetree.preview.page.btn" )#
			</button>
		</a>

	</div>

	<cfif Len( Trim( editPagePrompt ) )>
		<p>#editPagePrompt#</p>
		<div class="hr"></div>
	</cfif>

	<form id="#formId#" data-auto-focus-form="true" data-dirty-form="protect" class="form-horizontal" method="post" action="#event.buildAdminLink( linkTo='sitetree.editPageAction' )#">
		<input type="hidden" name="id" value="#event.getValue( name='id', defaultValue='' )#" />

		#renderForm(
			  formName          = mainFormName
			, mergeWithFormName = mergeFormName
			, context           = "admin"
			, formId            = formId
			, savedData         = page
			, validationResult  = validationResult
		)#

		<div class="form-actions row">
			<div class="col-md-offset-2">
				<a href="#event.buildAdminLink( linkTo="sitetree" )#" class="btn btn-default" data-global-key="c">
					<i class="fa fa-reply bigger-110"></i>
					#translateResource( "cms:sitetree.cancel.btn" )#
				</a>

				<button class="btn btn-info" type="submit" tabindex="#getNextTabIndex()#">
					<i class="fa fa-check bigger-110"></i>
					#translateResource( "cms:sitetree.savepage.btn" )#
				</button>
			</div>
		</div>
	</form>
</cfoutput>