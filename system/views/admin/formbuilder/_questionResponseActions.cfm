<cfparam name="args.viewQuestionResponseLink"    type="string"  />
<cfparam name="args.viewQuestionResponseTitle"   type="string"  />

<cfoutput>
	<div class="action-buttons btn-group">
		<a href="#args.viewQuestionResponseLink#"  data-title="#HtmlEditFormat( args.viewQuestionResponseTitle )#" >
			<i class="fa fa-eye"></i>
		</a>

	</div>
</cfoutput>
