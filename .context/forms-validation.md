# Forms & Validation

## Form XML Structure

Forms live in `/forms/` as XML files. Structure: `form > tab > fieldset > field`.

```xml
<?xml version="1.0" encoding="UTF-8"?>
<form i18nBaseUri="system-config.email:"
      tabsPlacement="left"
      extends="another.form"
      feature="myFeature">

    <tab id="smtp" sortorder="10"
         title="system-config.email:tab.smtp.title"
         description="system-config.email:tab.smtp.description"
         iconClass="fa-envelope"
         feature="smtp"
         permissionKey="email.edit">

        <fieldset id="connection" sortorder="10"
                  title="system-config.email:fieldset.connection.title">

            <field name="server"
                   control="textinput"
                   required="true"
                   maxLength="255"
                   sortorder="10"
                   label="system-config.email:field.server.title"
                   placeholder="system-config.email:field.server.placeholder"
                   help="system-config.email:field.server.help"
                   default="localhost"
                   feature="smtp"
                   permissionKey="email.server.edit" />

            <field name="port"
                   control="spinner"
                   required="true"
                   minValue="1"
                   maxValue="65535"
                   default="25"
                   sortorder="20" />
        </fieldset>
    </tab>
</form>
```

## i18n Conventions with i18nBaseUri

Given `i18nBaseUri="system-config.email:"`, the system auto-resolves:
- Tab title: `system-config.email:tab.{id}.title`
- Tab description: `system-config.email:tab.{id}.description`
- Tab icon: `system-config.email:tab.{id}.iconClass`
- Fieldset title: `system-config.email:fieldset.{id}.title`
- Field label: `system-config.email:field.{name}.title`
- Field placeholder: `system-config.email:field.{name}.placeholder`
- Field help: `system-config.email:field.{name}.help`

For Preside Object forms, the default `i18nBaseUri` is `preside-objects.{objectname}:`.

## Field Binding to Preside Objects

Binding pulls all attributes (control type, validation, i18n) from the object's property:

```xml
<field binding="page.title" />
<!-- Equivalent to full definition from page.cfc's title property -->

<!-- Override specific attributes: -->
<field binding="page.title" required="true" maxLength="100" />
```

## Form Inheritance & Merging

```xml
<!-- Extend another form: -->
<form extends="preside-objects.page.admin.add">
    <!-- Add new fields -->
    <tab id="extra">
        <fieldset id="extra">
            <field name="custom_field" control="textinput" />
        </fieldset>
    </tab>
    <!-- Modify existing fields (match by name) -->
    <tab id="main">
        <fieldset id="main">
            <field name="title" maxLength="50" required="true" />
        </fieldset>
    </tab>
</form>

<!-- Remove elements: -->
<form>
    <tab id="dates" deleted="true" />
    <tab id="main">
        <fieldset id="meta" deleted="true" />
        <fieldset id="content">
            <field name="old_field" deleted="true" />
        </fieldset>
    </tab>
</form>
```

**Auto-merging:** Forms at the same relative path in core → extension → application → site-template are automatically merged. No explicit `extends` needed.

## Standard Form Controls

| Control | Description |
|---------|-------------|
| `textinput` | Single-line text |
| `textarea` | Multi-line text |
| `richeditor` | CKEditor rich text |
| `password` | Password input |
| `emailInput` | Email address |
| `select` | Dropdown |
| `radio` | Radio buttons |
| `checkbox` | Single checkbox |
| `checkboxList` | Multiple checkboxes |
| `yesNoSwitch` | Toggle switch |
| `spinner` | Numeric spinner |
| `datePicker` | Date picker |
| `timePicker` | Time picker |
| `datetimepicker` | Date + time |
| `objectPicker` | Select related Preside Object records |
| `manyToManySelect` | Multi-select for M2M |
| `assetPicker` | Asset Manager picker |
| `siteTreePagePicker` | Site tree page picker |
| `linkPicker` | URL/page/asset link picker |
| `enumSelect` | Dropdown from `settings.enum.myType` |
| `hidden` | Hidden field |
| `readonly` | Read-only display |
| `simpleColourPicker` | Colour picker |
| `captcha` | CAPTCHA |

## Custom Form Control

Create as a viewlet at `formcontrols.{controlName}.{context}`:

**View-based control** (`/views/formcontrols/myControl/index.cfm`):
```cfm
<cfscript>
    inputName    = args.name         ?: "";
    defaultValue = args.defaultValue ?: "";
    value = HtmlEditFormat( event.getValue( name=inputName, defaultValue=defaultValue ) );
</cfscript>
<cfoutput>
<input type="text" name="#inputName#" value="#value#" class="form-control my-control">
</cfoutput>
```

**Handler-based control** (`/handlers/formcontrols/MyControl.cfc`):
```cfml
component {
    private string function index( event, rc, prc, args={} ) {
        args.options = myService.getOptions();
        return renderView( view="formcontrols/select/index", args=args );
    }
}
```

## Validation Framework

### Auto-Validation from Field Attributes
- `required="true"` → required validator
- `minLength="5"` / `maxLength="100"` → length validators
- `minValue="0"` / `maxValue="100"` → numeric range validators
- `type="date"` → date format validator
- `uniqueindexes` on object property → unique index validator (server-side only)

### Explicit Validation Rules
```xml
<field name="password" control="password" required="true">
    <rule validator="minLength" message="validation:password.too.short">
        <param name="length" value="8" />
    </rule>
    <rule validator="pattern" message="validation:password.complexity">
        <param name="regex" value="^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)" />
    </rule>
</field>
<field name="confirmPassword" control="password">
    <rule validator="sameAs" message="validation:passwords.must.match">
        <param name="field" value="password" />
    </rule>
</field>
```

### Common Validators
`required`, `minLength`, `maxLength`, `rangeLength`, `min`, `max`, `range`, `email`, `sameAs`, `pattern`, `presideObjectUniqueIndex`

### Custom Validator
```cfml
/**
 * @validationProvider
 */
component {
    /**
     * @validator
     * @validatorMessage myapp:validation.myvalidator.message
     */
    public boolean function myValidator(
          required string  fieldName
        , required any     value
        , required struct  data
        , required string  someParam
    ) {
        return !Len(Trim(arguments.value)) || myCheck(arguments.value, arguments.someParam);
    }

    // Optional: client-side JS
    public string function myValidator_js() {
        return "function(value, elem, params){ return !value.length || myJsCheck(value, params.someParam); }";
    }
}
```

Register in `Config.cfc`:
```cfml
settings.interceptors.append({ class="app.validators.MyValidator" });
```

### Using Validation in Handlers
```cfml
function savePost( event, rc, prc ) {
    var formName         = "preside-objects.blog_post.admin.edit";
    var formData         = event.getCollectionForForm( formName );
    var validationResult = validateForm( formName, formData );

    if ( !validationResult.validated() ) {
        setNextEvent(
              url           = event.buildAdminLink( linkTo="blog.editPost", queryString="id=#rc.id#" )
            , persistStruct = { validationResult=validationResult, formData=formData }
        );
    }
    // ... save data
}
```

### Rendering a Form
```cfm
<form id="my-form" method="post" action="#postUrl#">
    #renderForm(
          formName         = "my.form.name"
        , context          = "admin"
        , formId           = "my-form"
        , validationResult = rc.validationResult ?: ""
        , savedData        = rc.formData ?: {}
    )#
    <button type="submit">Save</button>
</form>
```

## Form File Naming Conventions

| Purpose | Path |
|---------|------|
| Object add form | `/forms/preside-objects/{objectName}/admin.add.xml` |
| Object edit form | `/forms/preside-objects/{objectName}/admin.edit.xml` |
| Object default form (v10.9+) | `/forms/preside-objects/{objectName}.xml` |
| Page type form | `/forms/page-types/{pageTypeName}.xml` |
| Widget config form | `/forms/widgets/{widgetName}.xml` |
| System config form | `/forms/system-config/{categoryName}.xml` |
| Email layout config | `/forms/email/layout/{layoutId}.xml` |
| Translation form | `/forms/preside-objects/_translation_{objectName}/admin.edit.xml` |

## Auto-Generated Forms

If no form file exists for an object, Preside auto-generates one from the object's properties. This is usually sufficient for simple objects managed via Data Manager.

## Programmatic Form Creation

```cfml
var newFormName = formsService.createForm( function( formDefinition ) {
    formDefinition.addField(
          tab       = "default"
        , fieldset  = "default"
        , name      = "title"
        , control   = "textinput"
        , required  = true
        , maxLength = 200
    );
});

// Based on existing form:
var newFormName = formsService.createForm(
      basedOn   = "preside-objects.blog_post.admin.edit"
    , generator = function( formDefinition ) {
        formDefinition.addField(
              tab     = "default"
            , fieldset = "default"
            , name    = "extra_field"
            , control = "textinput"
        );
    }
);
```

## Getting Form Data from Request

```cfml
// Get data for submitted form (auto-trims by default in admin)
var formData = event.getCollectionForForm( "my.form.name" );

// Disable auto-trim:
var formData = event.getCollectionForForm( formName="my.form.name", autoTrim=false );
```

## richEditor Field Options

```xml
<!-- In a form field: -->
<field name="body" control="richeditor"
       toolbar="full"
       stylesheets="/css/editor/"
       widgetCategories="content,email"
       linkPickerCategory="default" />
```

Configure toolbars in `Config.cfc`:
```cfml
settings.ckeditor.toolbars.minimal = "Bold,Italic,Underline,-,Link,Unlink";
settings.ckeditor.defaults.toolbar = "full";
```
