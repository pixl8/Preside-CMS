/**
 * @singleton
 *
 */
component extends="coldbox.system.Plugin" {

	public any function init( controller ) {
		super.Init(arguments.controller);

		// Plugin Properties
		setpluginName("Messagebox");
		setpluginVersion("2.1");
		setpluginDescription("This is a visual plugin that creates message boxes.");
		setpluginAuthor("Luis Majano");
		setpluginAuthorURL("http://www.coldbox.org");

		// static constant save key
		instance.flashKey = "coldbox_plugin_messagebox";
		instance.flashDataKey = "coldbox_plugin_messagebox_data";
		instance.realMessageBox = arguments.controller.getWirebox().getInstance( "messagebox@cbmessagebox" );

		return this;

	}

	function error()          { return instance.realMessageBox.error( argumentCollection=arguments ); }
	function info()           { return instance.realMessageBox.info( argumentCollection=arguments ); }
	function warn()           { return instance.realMessageBox.warn( argumentCollection=arguments ); }
	function warning()        { return instance.realMessageBox.warning( argumentCollection=arguments ); }
	function setMessage()     { return instance.realMessageBox.setMessage( argumentCollection=arguments ); }
	function append()         { return instance.realMessageBox.append( argumentCollection=arguments ); }
	function appendArray()    { return instance.realMessageBox.appendArray( argumentCollection=arguments ); }
	function prependArray()   { return instance.realMessageBox.prependArray( argumentCollection=arguments ); }
	function getMessage()     { return instance.realMessageBox.getMessage( argumentCollection=arguments ); }
	function clearMessage()   { return instance.realMessageBox.clearMessage( argumentCollection=arguments ); }
	function isEmptyMessage() { return instance.realMessageBox.isEmptyMessage( argumentCollection=arguments ); }
	function putData()        { return instance.realMessageBox.putData( argumentCollection=arguments ); }
	function addData()        { return instance.realMessageBox.addData( argumentCollection=arguments ); }
	function getData()        { return instance.realMessageBox.getData( argumentCollection=arguments ); }
	function getDataJSON()    { return instance.realMessageBox.getDataJSON( argumentCollection=arguments ); }
	function hasMessageType() { return instance.realMessageBox.hasMessageType( argumentCollection=arguments ); }
	function renderMessage()  { return instance.realMessageBox.renderMessage( argumentCollection=arguments ); }

}