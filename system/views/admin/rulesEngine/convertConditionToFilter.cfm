<cfscript>
	description            = args.pageDescription        ?: ( prc.pageDescription       ?: "" );
	formData               = args.formData               ?: ( rc.formData               ?: {} );
	formData.id            = args.id                     ?: ( rc.id                     ?: "" );
	formData.saveAction    = args.saveAction             ?: ( rc.saveAction             ?: "" );
	formData.filter_object = args.objectsFilterable[ 1 ] ?: ( rc.objectsFilterable[ 1 ] ?: "" );
	submitAction           = args.submitAction           ?: ( prc.submitAction          ?: "" );
</cfscript>
<cfoutput>
	<div class="alert alert-warning">
		<p>
			<i class="fa fa-fw fa-question-circle"></i>
			#description#
		</p>

		<br>

		<form action="#submitAction#" method="post">
			<cfloop collection="#formData#" item="key">
				<input type="hidden" name="#key#" value="#HtmlEditFormat( formData[ key ] )#">
			</cfloop>
			<button class="btn btn-info" name="convertAction" value="filter" type="submit" tabindex="#getNextTabIndex()#">
				<i class="fa fa-check bigger-110"></i>
				#translateResource( "cms:rulesEngine.convert.condition.to.filter.yes.btn" )#
			</button>
			<button class="btn btn-warning" name="convertAction" value="condition" type="submit" tabindex="#getNextTabIndex()#">
				<i class="fa fa-save bigger-110"></i>
				#translateResource( "cms:rulesEngine.convert.condition.to.filter.no.btn" )#
			</button>
		</form>
	</div>
</cfoutput>