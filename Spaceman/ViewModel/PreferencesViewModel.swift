//
//  PreferencesViewModel.swift
//  Spaceman
//
//  Created by Sasindu Jayasinghe on 6/12/20.
//

import Foundation
import SwiftUI

final class PreferencesViewModel: ObservableObject {
    @AppStorage("autoRefreshSpaces") private var autoRefreshSpaces = false
    @Published var selectedSpace = 0
    @Published var spaceName = ""
    var spaceNamesDict: [String: SpaceNameInfo] = [:]
    var sortedSpaceNamesDict: [Dictionary<String, SpaceNameInfo>.Element] = []
    private var timer: Timer?

    init() {
        if autoRefreshSpaces {
            startTimer()
        }
    }

    deinit {
        timer?.invalidate()
    }

    func loadData() {
        guard let data = UserDefaults.standard.value(forKey: "spaceNames") as? Data else {
            return
        }

        self.selectedSpace = 0
        guard let decoded = try? PropertyListDecoder().decode([String: SpaceNameInfo].self, from: data) else {
            Log.preferences.error("Failed to decode spaceNames; keeping previous state")
            return
        }
        self.spaceNamesDict = decoded

        let sorted = spaceNamesDict.sorted { first, second in
            first.value.spaceNum < second.value.spaceNum
        }

        sortedSpaceNamesDict = sorted
    }

    func updateSpace() {
        let key = sortedSpaceNamesDict[selectedSpace].key
        let spaceNum = sortedSpaceNamesDict[selectedSpace].value.spaceNum
        spaceNamesDict[key] = SpaceNameInfo(spaceNum: spaceNum, spaceName: spaceName.isEmpty ? "N/A" : spaceName)
    }

    func startTimer() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 5, repeats: true) { [weak self] _ in
            self?.refreshSpaces()
        }
    }

    func pauseTimer() {
        timer?.invalidate()
        timer = nil
    }

    private func refreshSpaces() {
        Log.preferences.debug("Periodic refresh tick")
        NotificationCenter.default.post(name: .spacemanRefresh, object: nil)
    }
}
