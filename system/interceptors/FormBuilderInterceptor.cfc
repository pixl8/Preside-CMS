component extends="coldbox.system.Interceptor" {
	property name="formBuilderService" inject="delayedInjector:FormBuilderService";

	public void function configure() {}

	public void function onApplicationStart() {
		formBuilderService.updateUsesGlobalQuestions();
	}
}