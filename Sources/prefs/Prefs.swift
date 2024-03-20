//
//  Prefs.swift
//
//
//  Created by Armin Briegel on 2024-03-20.
//

import Foundation
import ArgumentParser

@main
struct Prefs: ParsableCommand {
  static var configuration = CommandConfiguration(
    commandName: "prefs",
    abstract: "Shows preference/defaults settings from all levels together with their level",
    usage: """
prefs <domain>
prefs <domain> [<keys> ...]
""",
    version: "0.1"
  )


  // MARK: arguments  and flags

  @Flag(
    name: [.customShort("g"), .customLong("globals")],
    help: "show values from GlobalPreferences files"
  )
  var showGlobals = false

  @Flag(
    name: [.customLong("volatiles")],
    help: "show values from volatile domains"
  )
  var showVolatiles = false

  @Flag(
    name: .customLong("value"),
    help: "show only the value, no other information"
  )
  var showOnlyValue = false

  @Argument(
    help: ArgumentHelp(
      "the app identifier or preference domain",
      valueName: "domain"
    )
  )
  var applicationID: String

  @Argument(help: "preference keys to show. When no key is given all values will be shown")
  var keys: [String] = []


  // MARK: functions
  func exit(_ message: Any, code: Int32) throws -> Never {
    print(message)
    throw ExitCode(code)
  }

  func printDetail(_ key: String, preferences: Preferences) {
    guard let value = preferences.userDefaults.object(forKey: key) else { return }
    let level = preferences.level(for: key) ?? "unknown"
    if showOnlyValue {
      print(value)
    } else {
      print("\(key) [\(level)]: \(value)")
    }
  }


  // MARK: run
  func run() throws {
    guard let preferences = Preferences(suiteName: applicationID)
    else {
      try exit("cannot get defaults for '\(applicationID)'", code: 11)
    }

    if keys.count > 0 {
      for key in keys {
        printDetail(key, preferences: preferences)
      }
      return
    }

    // cache these for performance
    let globalKeys = preferences.globalKeys
    //let volatileKeys = preferences.volatileKeys

    for key in preferences.allKeys {
      if !showGlobals && globalKeys.contains(where: {$0 == key}) {
        continue
      }

      if !showVolatiles && preferences.volatileKeys.contains(where: {$0 == key}) {
        continue
      }

      printDetail(key, preferences: preferences)
    }
  }
}
