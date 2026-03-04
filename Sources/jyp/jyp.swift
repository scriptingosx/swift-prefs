//
//  jyp.swift
//  swift-prefs
//
//  Created by Armin Briegel on 04/03/2026.
//

import Foundation
import ArgumentParser
import Yams
import System

@main
struct jyp: ParsableCommand {
  static let configuration = CommandConfiguration(
    commandName: "jyp",
    abstract: "converts between json, yaml, and plist files",
    version: "0.1"
  )
  
  // MARK: arguments, options, flags
  
  @Option(help: "convert the specified files to to the indicated format (json, yaml, or plist) and write each one of them back to the file system")
  var convert: Format
  
  @Argument(help: "files to convert")
  var files: [String]
  
  
  // MARK: functions
  
  
  func object(_ data:Data, format: Format) throws -> Any? {
    switch format {
    case .json:
      try JSONSerialization.jsonObject(with: data)
    case .yaml:
      try Yams.load(yaml: String(decoding: data, as: UTF8.self))
    case .plist:
      try PropertyListSerialization.propertyList(from: data, format: nil)
    }
  }

  func outData(_ source: Any, target: Format) throws -> Data? {
    switch convert {
    case .json:
      return try JSONSerialization.data(withJSONObject: source, options: .prettyPrinted)
    case .yaml:
      if let sequence = source as? any Sequence {
        return try Yams.dump(objects: sequence).data(using: .utf8)
      } else {
        return nil
      }
    case .plist:
      return try PropertyListSerialization.data(fromPropertyList: source, format: .xml, options: 0)
    }
  }
  
  // MARK: run
  
  mutating func run() throws {
    for file in files {
      // check if file exists
      guard FileManager.default.fileExists(atPath: file) else {
        errorPrint("\(file): file not found")
        continue
      }
      
      let url = URL(filePath: file)
      let fileExtension = url.pathExtension
      
      // determine source format from file extension
      guard let sourceFormat = Format(rawValue: fileExtension) else {
        errorPrint("\(file): not a supported file type")
        continue
      }
      
      if sourceFormat == convert {
        errorPrint("\(file):  matches target format, skipping")
        continue
      }
      
      // get file name without extensions
      let filename = url.deletingPathExtension().lastPathComponent
      
      let sourceData = try Data(contentsOf: url)
      
      guard let source = try object(sourceData, format: sourceFormat) else {
        errorPrint("\(file): no data found")
        continue
      }
      
      let cwdURL = URL(filePath: FileManager.default.currentDirectoryPath)
      let targetURL = cwdURL.appending(component: filename).appendingPathExtension(convert.rawValue)
      
      // write out to target format
      guard let outData = try outData(source, target: convert) else {
        errorPrint("\(file): could not generate data")
        continue
      }
      
      try outData.write(to: targetURL, options: .atomic)
    }
  }
}

enum Format: String, ExpressibleByArgument {
  case json
  case yaml
  case plist
}
