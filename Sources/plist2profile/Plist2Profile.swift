//
//  Plist2Profile.swift
//
//
//  Created by Armin Briegel on 2024-03-20.
//

import Foundation
import ArgumentParser

@main
struct Plist2Profile: ParsableCommand {
  static var configuration = CommandConfiguration(
    commandName: "plist2profile",
    abstract: "converts a standard preference plist file to a mobileconfig profile",
    usage: "plist2profile --identifier <identifier> <plist> ...",
    version: "0.1"
  )

  // MARK: arguments,options, flags
  @Option(
    name: .shortAndLong,
    help: ArgumentHelp(
      "the identifier for the profile",
      valueName: "identifier"
    )
  )
  var identifier: String

  @Argument(
    help: ArgumentHelp(
      "Path to a plist to be added as a profile payload. Can be specified multiple times.",
      valueName: "plist"
    )
  )
  var plistPaths: [String]

  @Option(
    name: [.customShort("g"), .customLong("organization")],
    help: "Cosmetic name for the organization deploying the profile."
  )
  var organization = ""

  @Option(
    name: [.customShort("o"), .customLong("output")],
    help: "Output path for profile. Defaults to 'identifier.mobileconfig' in the current working directory."
  )
  var outputPath = ""

  @Option(
    name: [.customShort("d"), .customLong("displayname")],
    help: "Display name for profile. Defaults to 'plist2profile: <first domain>'."
  )
  var displayName = ""

  @Flag(
    name: .customLong("user"),
    help: "sets the scope for the profile to 'User' (otherwise scope is 'System')"
  )
  var userScope = false
  
  @Flag(
    name: .customLong("mcx"),
    help: "creates the profile in macx format (default: modern)"
    )
  var mcx = false

  // MARK: variables

  var uuid = UUID()
  var payloadVersion = 1
  var payloadType = "Configuration"
  var payloadScope = "System"

  // TODO:  missing keys for profile
  // removal disallowed
  // removalDate, duration until removal
  // description
  //
  // all of these should at least be grabbed when initialising from a file
  //

  // MARK: functions
  
  // TODO: can we put these functions in shared file? Can we share files between targets in a package without creating a library?

  func exit(_ message: Any, code: Int32 = 1) throws -> Never {
    print(message)
    throw ExitCode(code)
  }

  func isReadableFilePath(_ path: String) throws {
    let fm = FileManager.default
    var isDirectory: ObjCBool = false
    if !fm.fileExists(atPath: path, isDirectory: &isDirectory) {
      try exit("no file at path '\(path)'!", code: 66)
    }
    if isDirectory.boolValue {
      try exit("path '\(path)' is a directory", code: 66)
    }
    if !fm.isReadableFile(atPath: path) {
      try exit("cannot read file at '\(path)'!", code: 66)
    }
  }

  mutating func populateDefaults() {
    // if displayName is empty, populate
    if displayName.isEmpty {
      displayName = "plist2Profile: \(identifier)"
    }

    // if output is empty, generate file name
    if outputPath.isEmpty {
      outputPath = identifier.appending(".mobileConfig")
    }

    if userScope {
      payloadScope = "User"
    }
  }

  func validatePlists() throws {
    for plistPath in plistPaths {
      try isReadableFilePath(plistPath)
    }
  }

  func createModernPayload(name: String, plist: NSDictionary) throws -> NSDictionary {
    let mutablePayload = plist.mutableCopy() as! NSMutableDictionary
    // payload keys
    mutablePayload["PayloadIdentifier"] = name
    mutablePayload["PayloadType"] = name
    mutablePayload["PayloadDisplayName"] = displayName
    mutablePayload["PayloadUUID"] = UUID().uuidString
    mutablePayload["PayloadVersion"] = payloadVersion

    if !organization.isEmpty {
      mutablePayload["PayloadOrganization"] = organization
    }
    return mutablePayload
  }

  func createMCXPayload(name: String, plist: NSDictionary) throws -> NSDictionary {
    let mcxPayload = NSMutableDictionary()
    mcxPayload["PayloadIdentifier"] = name
    mcxPayload["PayloadType"] = "com.apple.ManagedClient.preferences"
    mcxPayload["PayloadDisplayName"] = displayName
    mcxPayload["PayloadUUID"] = UUID().uuidString
    mcxPayload["PayloadVersion"] = payloadVersion
    
    let prefSettings = NSDictionary(object: plist, forKey: "mcx_preference_settings" as NSString)
    let prefArray = NSArray(object: prefSettings)
    let forcedDict = NSDictionary(object: prefArray, forKey: "Forced" as NSString)
    let domainDict = NSDictionary(object: forcedDict, forKey: name as NSString)
    mcxPayload["PayloadContent"] = domainDict

    return mcxPayload
  }

  // MARK: run

  mutating func run() throws {
    // TODO: if identifer points to a mobile config file, get data from there
    try validatePlists()
    populateDefaults()

    // Boilerplate keys
    let profileDict: NSMutableDictionary = [
      "PayloadIdentifier": identifier,
      "PayloadUUID": uuid.uuidString,
      "PayloadVersion": payloadVersion,
      "PayloadType": payloadType,
      "PayloadDisplayName": displayName,
      "PayloadScope": payloadScope
    ]

    if !organization.isEmpty {
      profileDict["PayloadOrganization"] = organization
    }

    let payloads = NSMutableArray()

    for plistPath in plistPaths {

      // determine filename from path
      let plistURL = URL(fileURLWithPath: plistPath)
      let plistname = plistURL.deletingPathExtension().lastPathComponent
      guard let plistdict = try? NSDictionary(contentsOf: plistURL, error: ())
      else {
        try exit("file at '\(plistPath)' might not be a plist!", code: 65)
      }

      let payload = mcx ? try createMCXPayload(name: plistname, plist: plistdict)
                 : try createModernPayload(name: plistname, plist: plistdict)

      payloads.add(payload)
    }
    
    // insert payloads array
    profileDict["PayloadContent"] = payloads

    let profileURL = URL(filePath: outputPath)
    try profileDict.write(to: profileURL)

    // TODO: sign profile after creation

    print(profileURL.relativePath)
  }
}
