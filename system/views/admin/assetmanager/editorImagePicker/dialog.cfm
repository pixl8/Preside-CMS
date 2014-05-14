<cfoutput>
	<div class="page-content">
		#renderView( view="admin/general/pageTitle", args={
			  title    = translateResource( "cms:ckeditor.imagepicker.title" )
			, subTitle = translateResource( "cms:ckeditor.imagepicker.subtitle" )
			, icon     = ""
		} )#

		<div class="row modal-dialog-body">
			<div class="col-sm-12">
				<form data-auto-focus-form="true" class="form-horizontal" id="image-config-form" method="post" action="">
					#renderForm(
						  formName         = "richeditor.image"
						, context          = "imagepicker"
						, formId           = "image-config-form"
					)#
				</form>
			</div>
		</div>
	</div>
</cfoutput>