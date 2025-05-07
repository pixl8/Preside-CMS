<!---@feature formbuilder--->
<cfscript>
	submitLabel   = args.configuration.button_label   ?: translateResource( uri="formbuilder:button.submit.label" );
	backLabel     = args.configuration.back_label     ?: translateResource( uri="formbuilder:button.back.label" );
	continueLabel = args.configuration.continue_label ?: translateResource( uri="formbuilder:button.continue.label" );
	cancelLabel   = args.configuration.cancel_label   ?: translateResource( uri="formbuilder:button.cancel.label" );

	isFormPage    = args.isFormPage    ?: false;
	isFirstPage   = args.isFirstPage   ?: false;
	isLastPage    = args.isLastPage    ?: false;
	isSummaryPage = args.isSummaryPage ?: false;

	event.include( "/css/frontend/formbuilder/" );
</cfscript>

<cfoutput>
	<div class="form-group">
		<div class="form-buttons col-md-12">
			<button tabindex="#getNextTabIndex()#" class="btn" type="submit" name="formPageNext" value="1">#( ( isLastPage || isSummaryPage ) ? submitLabel : continueLabel )#</button>

			<cfif isFormPage and not isFirstPage>
				<button tabindex="#getNextTabIndex()#" class="btn btn-link" type="submit" name="formPageNext" value="0" formnovalidate>#cancelLabel#</button>

				<button tabindex="#getNextTabIndex()#" class="btn btn-bordered" type="submit" name="formPageNext" value="-1" formnovalidate>#backLabel#</button>
			</cfif>
		</div>
	</div>
</cfoutput>

