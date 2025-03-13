<!---@feature formbuilder--->
<cfscript>
	submitLabel   = args.configuration.button_label   ?: translateResource( uri="formbuilder:button.submit.label" );
	backLabel     = args.configuration.back_label     ?: translateResource( uri="formbuilder:button.back.label" );
	continueLabel = args.configuration.continue_label ?: translateResource( uri="formbuilder:button.continue.label" );

	isFormPage  = args.isFormPage  ?: false;
	isFirstPage = args.isFirstPage ?: false;
	isLastPage  = args.isFirstPage ?: false;
</cfscript>

<cfoutput>
	<div class="form-group">
		<div class="col-md-offset-3 col-md-12">
			<cfif isFormPage>
				<cfif not isFirstPage>
					<button tabindex="#getNextTabIndex()#" class="btn btn-bordered" type="submit" name="_formNextPage" value="-1">#backLabel#</button>
				</cfif>
				<button tabindex="#getNextTabIndex()#" class="btn" type="submit" name="_formNextPage" value="1">#continueLabel#</button>
			<cfelse>
				<button tabindex="#getNextTabIndex()#" class="btn" type="submit">#submitLabel#</button>
			</cfif>
		</div>
	</div>
</cfoutput>

