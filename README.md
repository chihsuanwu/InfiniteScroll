# InfiniteScroll

A SwiftUI implementation of two-direction infinite scrolling.

Currently the requirement is iOS 17.0+.

## Usage

```swift
import InfiniteScroll

struct ContentView: View {
    @State private var data: [Int] = Array(0..<10)

    var body: some View {
        InfiniteScroll(
            data: data,
            id: \.self,
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
            }
        ) { data in
            Text("\(data)")
                .frame(height: 50)
            
            Divider()
        }
    }
}


```

# Installation
## Swift Package Manager

- url: `https://github.com/chihsuanwu/InfiniteScroll.git`