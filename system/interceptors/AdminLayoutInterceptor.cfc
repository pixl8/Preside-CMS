component extends="coldbox.system.Interceptor" {

	property name="dataManagerCustomizationService" inject="delayedInjector:dataManagerCustomizationService";

// PUBLIC
	public void function configure() {}

	public void function preLayoutRender( event, interceptData ) {
		if ( event.isDataManagerRequest() ) {
			var objectName    = prc.objectName ?: "";
			var currentAction = event.getCurrentAction();

			dataManagerCustomizationService.runCustomization(
				  objectName = objectName
				, action     = "preLayoutRender"
				, args       = { objectName=objectName, action=currentAction }
			);
			dataManagerCustomizationService.runCustomization(
				  objectName = objectName
				, action     = "preLayoutRenderFor#currentAction#"
				, args       = { objectName=objectName }
			);
		}
	}
}