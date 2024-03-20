# swift-prefs

A selection of command line tools for working with setting/defaults/preferences on macOS.

## `prefs`

This tool is inspired by [Greg Neagle's `fancy_defaults_read.py`](https://gist.github.com/gregneagle/010b369e86410a2f279ff8e980585c68) and a remake of [my earlier Python tool](https://github.com/scriptingosx/PrefsTool).

In the simplest use case you can just pass the app identifier:

```
% prefs com.apple.screensaver
moduleDict [host]: {
    moduleName = "Computer Name";
    path = "/System/Library/Frameworks/ScreenSaver.framework/PlugIns/Computer Name.appex";
    type = 0;
}
PrefsVersion [host]: 100
idleTime [host]: 0
lastDelayTime [host]: 1200
tokenRemovalAction [host]: 0
showClock [host]: 0
CleanExit [host]: 1
```

The tool will print _all_ composited preferences keys and their type and value, with the preference domain where the value was set. The output format is:

```
prefKey [domain]: value
```

A preference domain of `managed` means the value is set with a configuration profile.

While preference values set in `.GlobalPreferences.plist` in the different domains are composited into the the application defaults, they are _not_ shown by default, since there are many of them and they will make the output fairly unreadable. If you want to see them add the `--globals` (or `-g`) option:

```
% prefs --globals com.apple.screensaver
```

You can also add one or more keys after the app identifier to get just specific values:

```
% prefs com.apple.screensaver idleTime AppleLocale       
idleTime [host]: 0
AppleLocale [global/user]: en_US@rg=nlzzzz
```

You can also add the `--value` option to show just the value in the output (might be useful when you want to get the composited value for another script.

```
% prefs --value com.apple.screensaver idleTime
1200
```

### Known Issues

- doesn't read preferences of sandboxes apps from their containers

## plist2profile

This tool is a modern re-interpretation of [Tim Sutton's mcxToProfile](https://github.com/timsutton/mcxToProfile).

It will convert a normal flat plist file into a custom mobileconfig/configuration profile that can be used for manual installation or with an MDM server.

In the simplest form, you use it like this:

```
% plist2profile --plist settings.plist --identifier com.example.settings
```

