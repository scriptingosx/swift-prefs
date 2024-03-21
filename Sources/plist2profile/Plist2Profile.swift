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
    usage: "plist2profile <identifier> <plist> ...",
    version: "0.1"
  )
  
  // MARK: arguments,options, flags
  @Argument(
    help: ArgumentHelp(
      "the payload identifier for the profile",
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

  // TODO: option to create a modern or mcx profile

  // MARK: variables

  var uuid = UUID()
  var payloadVersion = 1
  var payloadType = "Configuration"
  var payloadScope = "System" // or "User"

  // TODO:  missing keys for profile
  // payload scope
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
      outputPath = identifier.appending(".plist")
    }
  }

  func validatePlists() throws {
    for plistPath in plistPaths {
      try isReadableFilePath(plistPath)
    }
  }

  func createModernPayload(plistPath: String) throws -> NSDictionary {
    let payloadUUID = UUID()
    // determine filename from path
    let plistURL = URL(fileURLWithPath: plistPath)
    let plistname = plistURL.deletingPathExtension().lastPathComponent
    guard let payload = try? NSMutableDictionary(contentsOf: plistURL, error: ())
    else {
      try exit("file at '\(plistPath)' might not be a plist!", code: 65)
    }
    // payload keys
    payload["PayloadIdentifier"] = plistname
    payload["PayloadType"] = plistname
    payload["PayloadDisplayName"] = "\(displayName): \(plistname)"
    payload["PayloadUUID"] = payloadUUID.description
    payload["PayloadVersion"] = payloadVersion

    if !organization.isEmpty {
      payload["PayloadOrganization"] = organization
    }
    return payload
  }

  // MARK: run

  mutating func run() throws {
    // TODO: if identifer points to a mobile config file, get data from there
    try validatePlists()
    populateDefaults()

    print("Hello, plist2profile!")

    // Boilerplate
    let profileDict: NSMutableDictionary = [
      "PayloadIdentifier": identifier,
      "PayloadUUID": uuid.description,
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
      let payload = try createModernPayload(plistPath: plistPath)
      payloads.add(payload)

      // insert payloads array
      profileDict["PayloadContent"] = payloads
    }

    guard let plistData = try? PropertyListSerialization.data(fromPropertyList: profileDict, format: .xml, options: .zero)
    else { try exit("could generate property list", code: 73) }

    print(String(data: plistData, encoding: .utf8) ?? "<no data>")
  }
}
