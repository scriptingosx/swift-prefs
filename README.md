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

This tool is a re-interpretation in Swift of [Tim Sutton's mcxToProfile](https://github.com/timsutton/mcxToProfile).

It will convert a normal flat plist file into a custom mobileconfig/configuration profile that can be used for manual installation or with an MDM server.

In the simplest form, use it like this:

```
% plist2profile --identifier example.settings com.example.settings.plist
```

This will generate a file named `example.settings.mobileconfig` in the current working directory which manages the preference keys in the `com.example.settings.plist` in the `com.example.settings` preference domain. You can add multiple plist files.

The preference domain for the settings is determined from the file name of each plist file given (removing the `plist` file extension).

You can add a display and organization name that will be used in the respective fields using the `--displayname` and `--organization` options.

By default, the profile is created with a `System` scope. you can change it to `User` with the `--user` flag.

There are two ways to assemble custom preference profile, the 'traditional' mcx format and a more modern format, which [Bob Gendler described in this post](https://boberito.medium.com/config-profile-and-manage-all-the-things-just-about-cafea8627d4b). This tool creates the modern format by default, but can also create the traditional format when you set the `--mcx` key.


