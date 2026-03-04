//
//  ParsableCommand+Extensions.swift
//  translate-cli
//
//  Created by Armin Briegel on 2026-01-05.
//

import Foundation
import ArgumentParser

func errorPrint(_ message: String) {
  fputs("\(message)\n", stderr)
  fflush(stderr)
}

extension ParsableCommand {
  func exit(_ message: String, code: Int32 = EXIT_FAILURE) throws -> Never {
    errorPrint(message)
    throw ExitCode(code)
  }
}
