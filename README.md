# InfiniteScroll

A SwiftUI implementation of two-direction infinite scrolling.

Note: The underlying Implementation bwtween iOS17+ and iOS16- is different. The iOS17+ version uses new `scrollPosition` and `scrollTargetLayout` to keep the scroll position, whitch is not available in iOS16-. Thus, the iOS16- version uses some workarounds and may not be as smooth as the iOS17+ version.

## Usage

Below is an example of how to use `AutoInfiniteScroll` to create a two-direction infinite scrolling list.

First two parameters are the same as `ForEach`'s, the third and fourth parameters are the closures to load more data when the list is scrolled to the top or bottom.

```swift
import InfiniteScroll

struct ContentView: View {
    @State private var data: [Int] = Array(0..<10)

    var body: some View {
        AutoInfiniteScroll(
            data,
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

If data conforms to `Identifiable`, you can omit the `id` parameter.

```swift
AutoInfiniteScroll(data, onLoadPrev: onLoadPrev, onLoadMore: onLoadMore) { data in
    //
}
```



# Installation
## Swift Package Manager

- url: `https://github.com/chihsuanwu/InfiniteScroll.git`