---
id: configurableconsolekey
title: Configuring the developer console key
---

Keyboard layouts vary. The default key code that is used to toggle the developer console is `96` which on a UK keyboard layout maps to the backtick key (`).

In order to accomodate different layouts, PresideCMS allows you to configure the keycode that will trigger the Preside developer console to be toggled. In your application's `Config.cfc`, add the following entry:

```luceescript
component extends="preside.system.config.Config" {

	public void function configure() {
		super.configure();

		// ...

		settings.devConsoleToggleKeyCode = 96; // replace 96 with the keycode you wish to use

		// ...
	}

}
```

## Finding out your desired keycode

The keycode we need is the one that is fired by JavaScript on the `onKeyPress` event, and the one that is mapped to the `event.which` variable.

One quick method to get the correct keycode, is to visit the following web page that has a javascript based form that displays keycodes of the keys you press: [http://www.asquare.net/javascript/tests/KeyCode.html](http://www.asquare.net/javascript/tests/KeyCode.html).

See the relevant section from which to extract the keycode, below:

![Screenshot showing use of the keycode test tool](images/screenshots/discoverkeycode.png)

