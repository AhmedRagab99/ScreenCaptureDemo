//
//  BundleIDsListView.swift
//  ScreenCaptureDemo
//
//  Created by Ahmed Ragab on 10/09/2024.
//

import SwiftUI

struct BundleIDsListView {
    @ObservedObject var screenRecorder: ScreenCaptureManger
}

extension BundleIDsListView: View {
    

    var body: some View {
        Section {
            ForEach(Array(screenRecorder.excludedBundleIDs.enumerated()), id: \.element) { index, element in
                HStack {
                    Text("\(element)")
                        .padding(.leading, 5)
                        .foregroundColor(.gray)
                    Spacer()
                    Button {
                        screenRecorder.excludedBundleIDs.remove(at: index)
                    } label: {
                        Image(systemName: "xmark.circle")
                    }
                    .padding(.trailing, 10)
                    .foregroundStyle(.secondary)
                    .buttonStyle(.plain)
                }
            }
        }
    }
}
