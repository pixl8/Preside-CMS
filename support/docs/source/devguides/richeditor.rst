Working with the richeditor
===========================

PresideCMS uses CKEditor_ for its richeditor.

Beyond the standard install, PresideCMS provides custom plugins to interact with the CMS such as inserting images and documents from the Asset Manager, linking to pages in the site tree, etc. It also allows you to customize and configure the editor from your CFML code.

Configuration
#############

Default settings and toolbar sets can be configured in your site's :doc:`Config.cfc <configcfc>`. For example,

.. code-block:: js

    public void function configure() output=false {
        super.configure();

        // ...

        settings.ckeditor = {};

        // default settings
        settings.ckeditor.defaults = {
              width       = "auto"                                // default width of the editor, in pixels if numeric
            , height      = 400                                   // default height of the editor, in pixels if numeric
            , toolbar     = "full"                                // default toolbar set, see below
            , stylesheets = [ "/specific/richeditor/", "/core/" ] // array of stylesheets to be included in editor body
            , configFile  = "/ckeditorExtensions/config.js"       // path is relative to the compiled assets folder
        };

        // toolbar sets, see further documentation below
        settings.ckeditor.toolbars = {};
        settings.ckeditor.toolbars.full = 'Maximize,-,Source,-,Preview'
                                       & '|Cut,Copy,Paste,PasteText,PasteFromWord,-,Undo,Redo'
                                       & '|Find,Replace,-,SelectAll,-,Scayt'
                                       & '|Widgets,ImagePicker,AttachmentPicker,Table,HorizontalRule,SpecialChar,Iframe'
                                       & '|Link,Unlink,Anchor'
                                       & '|Bold,Italic,Underline,Strike,Subscript,Superscript,-,RemoveFormat'
                                       & '|NumberedList,BulletedList,-,Outdent,Indent,-,Blockquote,CreateDiv,-,JustifyLeft,JustifyCenter,JustifyRight,JustifyBlock,-,BidiLtr,BidiRtl,Language'
                                       & '|Styles,Format,Font,FontSize'
                                       & '|TextColor,BGColor';

        settings.ckeditor.toolbars.boldItalicOnly = 'Bold,Italic';
    }

Configuring toolbars
--------------------

PresideCMS uses a light-weight syntax for defining sets of toolbars that translates to the full CKEditor toolbar definition. The following two definitions are equivalent:

**CKEditor config.js**

.. code-block:: js

    CKEDITOR.editorConfig = function( config ) {
        config.toolbar = "mytoolbar";

        config.toolbar_mytoolbar = [
            [
                [ 'Source', '-', 'NewPage', 'Preview', '-', 'Templates' ],                     // Defines toolbar group, '-' indicates a vertical divider within the group
                [ 'Cut', 'Copy', 'Paste', 'PasteText', 'PasteFromWord', '-', 'Undo', 'Redo' ], // Defines another toolbar group
                '/',                                                                           // Line break - next group will be placed in new line.
                [ 'Bold', 'Italic' ]                                                           // Defines another toolbar group
            ]
        ];
    };

**Config.cfc equivalent**

.. code-block:: js

    public void function configure() output=false {
        super.configure();

        // ...

        settings.ckeditor.defaults = {
            , toolbar = "mytoolbar"
        };

        // in the PresideCMS version of the toolbar configuration, toolbar groups
        // are simply comma separated lists of buttons and dividers. Toolbar groups
        // are then delimited by the pipe ('|') symbol.
        settings.ckeditor.toolbars.mytoolbar = 'Source,-,NewPage,Preview,-,Templates'
                                            & '|Cut,Copy,Paste,PasteText,PasteFromWord,-,Undo,Redo'
                                            & '|/'
                                            & '|Bold,Italic';

        // the above toolbar string all on one line: 'Source,-,NewPage,Preview,-,Templates|Cut,Copy,Paste,PasteText,PasteFromWord,-,Undo,Redo|/|Bold,Italic'
    }

Specifying non-default toolbars for form fields
***********************************************

You can define multiple toolbars in your configuration and then specify which toolbar to use for individual form fields (if you do not define a toolbar, the default will be used). An example, using a PresideCMS form definition:

.. code-block:: xml

    <?xml version="1.0" encoding="UTF-8"?>
    <form>
        <tab>
            <fieldset>
                <field name="description" control="richeditor" toolbar="boldItalicOnly" label="widgets.mywidget:description.label"  />
            </fieldset>
        </tab>
    </form>

You can also define toolbars inline:

.. code-block:: xml

    <?xml version="1.0" encoding="UTF-8"?>
    <form>
        <tab>
            <fieldset>
                <field name="description" control="richeditor" toolbar="Bold,Italic,Underline|Cut,Copy,Paste,PasteText,PasteFromWord,-,Undo,Redo" label="widgets.mywidget:description.label"  />
            </fieldset>
        </tab>
    </form>

Configuring stylesheets
-----------------------

The stylesheets configuration effects how content within the editor is displayed during editing. You will likely want to include your site's core styles so that the WYSIWYG experience is as close to the final product as possible.

Default stylesheets are configured as an array of stylesheet includes (see Config.cfc example above). Each item in the array will be expanded as a CfStatic include resource (see :doc:`cssandjs`). The example below gives a sample folder structure along with the configuration required to include the site's core styles + richeditor specific styles:

.. code-block:: text

    /app
        /assets
            /css
                /core
                    00_reset.less
                    01_bootstrap.less
                    02.typography.less
                    03.forms.less
                    ... etc.

                /specific
                    /richeditor
                        00_richeditorReset.less
                    /newspage
                    /eventspage
                    ... etc
            /js

.. code-block:: js

    ckeditor.defaults.stylesheets = [ "/specific/richeditor/", "/core/" ]; // note how the paths are relative to the css folder

Specifying non-default stylesheets for form fields
**************************************************

You can define specific stylesheets for individual form controls by supplying a comma separated list:

.. code-block:: xml

    <?xml version="1.0" encoding="UTF-8"?>
    <form>
        <tab>
            <fieldset>
                <field name="description" control="richeditor" stylesheets="/specific/myCustomEditorStyles/,/core/" label="widgets.mywidget:description.label" />
            </fieldset>
        </tab>
    </form>

Configuring a custom CKEditor config file
-----------------------------------------

For the most flexible configuration tweaking, you can define your own CKEditor :code:`config.js` file:

.. code-block:: js

    ckeditor.defaults.configFile = "/path/to/my/custom/config/file.js"; // relative to your root assets folder

You can also define this inline:

.. code-block:: xml

    <?xml version="1.0" encoding="UTF-8"?>
    <form>
        <tab>
            <fieldset>
                <field name="description" control="richeditor" customConfig="/path/to/my/custom/config/file.js" label="widgets.mywidget:description.label" />
            </fieldset>
        </tab>
    </form>

.. note::

    The default configuration file can be found at :code:`/preside/system/assets/ckeditorExtensions/config.js`


Where the code lives (for maintainers and contributers)
#######################################################

We manage a custom build of the editor, including all the core plugins that we require, through our `own repository on GitHub`_. In addition, any Preside specific extensions to the editor are developed and maintained in the `core repository`_, they can be found at: :code:`/system/assets/ckeditorExtensions`.

Finally, we have our own custom javascript object for building instances of the editor. It can be found at :code:`/system/assets/js/admin/core/preside.richeditor.js`.

.. _CKEditor: http://ckeditor.com/
.. _`own repository on GitHub`: https://github.com/pixl8/Preside-Editor
.. _`core repository`: https://github.com/pixl8/Preside-CMS