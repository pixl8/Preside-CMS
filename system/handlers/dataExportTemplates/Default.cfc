/**
 * @feature dataExport
 */
component {

	private void function preRenderConfigForm( event, rc, prc, objectName="", renderFormArgs={} ) {
		renderFormArgs.additionalArgs                     = renderFormArgs.additionalArgs ?: {};
		renderFormArgs.additionalArgs.fields              = renderFormArgs.additionalArgs.fields ?: {};
		renderFormArgs.additionalArgs.fields.exportFields = renderFormArgs.additionalArgs.fields.exportFields ?: {};

		renderFormArgs.additionalArgs.fields.exportFields.exportObject = arguments.objectName;
	}

}