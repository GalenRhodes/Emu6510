//
//  main.swift
//  DocFixer
//
//  Created by Galen Rhodes on 3/26/20.
//  Copyright © 2020 Project Galen. All rights reserved.
//

import Foundation
import PGDocFixer

func docFixer() -> Int32 {
    if CommandLine.argc > 1 {
        for (i, dir): (Int, String) in CommandLine.arguments.enumerated() {
            if i > 0 {
                do {
                    try docFixer(path: dir, matchAndReplace: [], docOutput: .Slashes, lineLength: 132)
                    return 0
                }
                catch let error {
                    print("ERROR: \(error)", to: &errorLog)
                    return 1
                }
            }
            else {
                print("Running as: \(dir)")
            }
        }
    }
    else {
        print("ERROR: No path(s) given", to: &errorLog)
        return 1
    }

    return 0
}

exit(docFixer())
