<cfscript>
	parentPage       = prc.parentPage      ?: QueryNew('');
	mainFormName     = prc.mainFormName    ?: "";
	mergeFormName    = prc.mergeFormName   ?: "";
	validationResult = rc.validationResult ?: ""
	formId           = "addForm-" & CreateUUId();
	addPagePrompt    = translateResource( uri="preside-objects.page:addRecord.prompt", defaultValue="" );

	prc.pageIcon     = "plus";
	if ( parentPage.recordCount ) {
		prc.pageTitle    = translateResource( uri="cms:sitetree.addChildPage.title", data=[ parentPage.title ] );
	} else {
		prc.pageTitle    = translateResource( "cms:sitetree.addPage.title" );
	}

	canPublish   = IsTrue( prc.canPublish   ?: "" );
	canSaveDraft = IsTrue( prc.canSaveDraft ?: "" );

	actions = [];
	if ( canSaveDraft ) {
		actions.append( { key="savedraft", title=translateResource( "cms:sitetree.addpage.draft.btn" ) } );
	}
	if ( canPublish ) {
		actions.append( { key="publish", title=translateResource( "cms:sitetree.addpage.btn" ) } );
	}
</cfscript>

<cfoutput>
	<cfif Len( Trim( addPagePrompt ) )>
		<p>#addPagePrompt#</p>
		<div class="hr"></div>
	</cfif>

	<form id="#formId#" data-auto-focus-form="true" data-dirty-form="protect" class="form-horizontal" method="post" action="#event.buildAdminLink( linkTo='sitetree.addPageAction' )#">
		<input type="hidden" name="parent_page" value="#( rc.parent_page ?: '')#" />
		<input type="hidden" name="page_type"   value="#( rc.page_type   ?: '')#" />

		#renderForm(
			  formName          = mainFormName
			, mergeWithFormName = mergeFormName
			, context           = "admin"
			, formId            = formId
			, validationResult  = validationResult
		)#

		<div class="form-actions row">
			#renderFormControl(
				  type    = "yesNoSwitch"
				, context = "admin"
				, name    = "_addAnother"
				, id      = "_addAnother"
				, label   = translateResource( uri="cms:sitetree.add.another" )
			)#

			<div class="col-md-offset-2">
				<div class="btn-group">
					<a href="#event.buildAdminLink( linkTo="sitetree" )#" class="btn btn-default" data-global-key="c">
						<i class="fa fa-reply bigger-110"></i>
						#translateResource( "cms:sitetree.cancel.btn" )#
					</a>
				</div>

				<input name="_saveAction" type="hidden" value="#actions[1].key#">
				<cfif actions.len() == 1>
					<div class="btn-group">
						<button class="btn btn-info" type="submit" tabindex="#getNextTabIndex()#">
							<i class="fa fa-save bigger-110"></i>
							#actions[1].title#
						</button>
					</div>
				<cfelse>
					<div class="btn-group" data-multi-submit-field="_saveAction">
						<button type="submit" class="btn btn-info">
							<i class="fa fa-save bigger-110"></i> #actions[1].title#
						</button>
						<button type="button" class="btn btn-info dropdown-toggle" data-toggle="dropdown" aria-haspopup="true" aria-expanded="false">
							<i class="fa fa-caret-down bigger-110"></i><span class="sr-only">Toggle Dropdown</span>
						</button>
						<ul class="dropdown-menu">
							<cfloop array="#actions#" index="i" item="action">
								<li><a href="##" data-action-key="#action.key#">#action.title#</a></li>
							</cfloop>
						</ul>
					</div>
				</cfif>
			</div>
		</div>
	</form>
</cfoutput>