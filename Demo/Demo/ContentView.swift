//
//  ContentView.swift
//  Demo
//
//  Created by 吳其軒 on 2024/2/14.
//

import SwiftUI
import InfiniteScroll

struct ContentView: View {
    
    @State private var data: [Int] = Array(0..<10)
    @State private var enableLoadPrev = true
    @State private var enableLoadMore = true
    
    var body: some View {
        VStack {
            AutoInfiniteScroll(
                data,
                id: \.self,
                initialFirstVisibleItem: 3,
                onLoadPrev: {
                    Task {
                        try? await Task.sleep(nanoseconds: 1_000_000_000)
                        let min = data.min() ?? 0
                        data.insert(contentsOf: (min-10..<min), at: 0)
                    }
                },
                onLoadMore: {
                    Task {
                        try? await Task.sleep(nanoseconds: 1_000_000_000)
                        let max = data.max() ?? 0
                        data.append(contentsOf: (max+1..<max+11))
                    }
                },
                enableLoadPrev: enableLoadPrev,
                enableLoadMore: enableLoadMore,
                progress: {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle())
                        .scaleEffect(1.5)
                        .padding()
                        .tint(.yellow)
                }
            ) { data in
                Text("\(data)")
                    .frame(maxWidth: .infinity)
                    .frame(height: 100)
                    .background(
                        Color(
                            hue: abs(Double(data % 20)) / 20.0,
                            saturation: 0.8,
                            brightness: 0.5
                        ).opacity(0.6)
                    )
                
                Divider()
            }
            
            HStack {
                Button("Load Prev: \(enableLoadPrev ? "true" : "false")") {
                    enableLoadPrev.toggle()
                }
                Button("Reload") {
                    data = Array(0..<10)
                }
                Button("Load More: \(enableLoadMore ? "true" : "false")") {
                    enableLoadMore.toggle()
                }
            }
        }
        .padding()
    }
}

#Preview {
    ContentView()
}
