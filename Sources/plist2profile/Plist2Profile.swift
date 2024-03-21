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
    version: "0.1"
  )

  func run() {
    print("Hello, plist2profile!")
  }
}
