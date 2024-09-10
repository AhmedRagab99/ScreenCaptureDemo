//
//  HeaderView.swift
//  ScreenCaptureDemo
//
//  Created by Ahmed Ragab on 10/09/2024.
//

import SwiftUI

struct HeaderView {
    private let title: String
    private let alignmentOffset: CGFloat = 10.0
    
    init(_ title: String) {
        self.title = title
    }
}

extension HeaderView: View {
    
    
    
    var body: some View {
        Text(title)
            .font(.headline)
            .foregroundColor(.secondary)
            .alignmentGuide(.leading) { _ in alignmentOffset }
    }
}
