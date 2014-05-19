<cfscript>
	linkType = ( ( rc.type ?: "" ) == "attachment" ) ? "attachment" : "image";
</cfscript>
<cfoutput>
	<div class="page-content">
		#renderView( view="admin/general/pageTitle", args={
			  title    = translateResource( "cms:ckeditor.#linkType#picker.title" )
			, subTitle = translateResource( "cms:ckeditor.#linkType#picker.subtitle" )
			, icon     = "picture-o"
		} )#

		<div class="row modal-dialog-body">
			<div class="col-sm-12">
				<form data-auto-focus-form="true" class="form-horizontal" id="#linkType#-config-form" method="post" action="">
					#renderForm(
						  formName         = "richeditor.#linkType#"
						, context          = "assetpicker"
						, formId           = "#linkType#-config-form"
					)#
				</form>
			</div>
		</div>
	</div>
</cfoutput>