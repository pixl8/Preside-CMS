---
id: xss
title: XSS protection
---

PresideCMS comes with XSS protection out of the box using the AntiSamy project. This protection will automatically strip unwanted HTML from user input in order to prevent the possibility of successful cross site scripting attacks. See also [[csrf]].

## Configuring protection

The protection is turned on by default but bypassed by default when the logged in user is a CMS administrator. These settings, and also the AntiSamy profile to be used, can be edited in your sites `Config.cfc` file:

```luceescript

public void function configure() {
    super.configure();

    // turn off antisamy (don't do this!)
    settings.antiSamy.enabled = false;

    // use the "tinymce" AntiSamy policy (default is preside as of 10.8.24, myspace before that)
    settings.antiSamy.policy  = "tinymce"; 

    // do not bypass antisamy, even when logged in user is admin
    settings.antiSamy.bypassForAdministrators = false;

    // ...
}
```

The list of possible policies to use are:

* preside (added in 10.8.24)
* antisamy
* ebay
* myspace
* slashdot
* tinymce

For more information on the AntiSamy project, visit [https://www.owasp.org/index.php/Category:OWASP_AntiSamy_Project](https://www.owasp.org/index.php/Category:OWASP_AntiSamy_Project).