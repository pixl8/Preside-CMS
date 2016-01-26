<cfparam name="args.canDelete"             type="boolean" />
<cfparam name="args.viewSubmissionLink"    type="string"  />
<cfparam name="args.viewSubmissionTitle"   type="string"  />
<cfparam name="args.deleteSubmissionLink"  type="string"  />
<cfparam name="args.deleteSubmissionTitle" type="string"  />

<cfoutput>
	<div class="action-buttons btn-group">
		<a href="#args.viewSubmissionLink#" data-toggle="bootbox-modal" data-title="#HtmlEditFormat( args.viewSubmissionTitle )#" data-modal-class="full-screen-dialog limited-size">
			<i class="fa fa-eye"></i>
		</a>

		<cfif args.canDelete>
			<a class="confirmation-prompt" data-context-key="d" href="#args.deleteSubmissionLink#" title="#HtmlEditFormat( args.deleteSubmissionTitle )#">
				<i class="fa fa-trash-o"></i>
			</a>
		</cfif>
	</div>
</cfoutput>