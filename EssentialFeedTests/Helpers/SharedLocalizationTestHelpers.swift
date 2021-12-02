//
//  SharedLocalizationTestHelpers.swift
//  EssentialFeedTests
//
//  Created by Avelino Rodrigues on 02/12/2021.
//

import XCTest

func assertLocalizedKeyAndValuesExist(in presentationBundle: Bundle, _ table: String, file: StaticString = #filePath, line: UInt = #line) {
    let localizationBundles = allLocalizationBundles(in: presentationBundle, file: file, line: line)
    let localizedStringKeys = allLocalizedStringKeys(in: localizationBundles, table: table, file: file, line: line)

    localizationBundles.forEach { bundle, localization in
        localizedStringKeys.forEach { key in
            let language = Locale.current.localizedString(forLanguageCode: localization) ?? ""
            let localizedString = bundle.localizedString(forKey: key, value: nil, table: table)

            if localizedString == key {
                XCTFail("Missing \(language) (\(localization)) localized string for key: '\(key)' in table: '\(table)'", file: file, line: line)
            }
        }
    }
}

private typealias LocalizedBundles = (bundle: Bundle, localization: String)

private func allLocalizationBundles(in bundle: Bundle, file: StaticString = #filePath, line: UInt = #line) -> [LocalizedBundles] {
    return bundle.localizations.compactMap { localization in
        guard let path = bundle.path(forResource: localization, ofType: "lproj"), let localizedBundle = Bundle(path: path) else {
            XCTFail("Couldn't find bundle for localization: \(localization)", file: file, line: line)
            return nil
        }

        return (localizedBundle, localization)
    }
}

private func allLocalizedStringKeys(in bundles: [LocalizedBundles], table: String, file: StaticString = #filePath, line: UInt = #line) -> Set<String> {
    return bundles.reduce([]) { acc, current in
        guard let path = current.bundle.path(forResource: table, ofType: "strings"),
              let strings = NSDictionary(contentsOfFile: path),
              let keys = strings.allKeys as? [String]
        else {
            XCTFail("Couldn't load localized strings for localization: \(current.localization)", file: file, line: line)
            return acc
        }

        return acc.union(Set(keys))
    }
}
