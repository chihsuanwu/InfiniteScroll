import SwiftUI
import HuggingGeometryReader

/// A SwiftUI view that enables infinite scrolling functionality.
///
/// Use the `InfiniteScroll` view to display a list of data items and load more data as the user scrolls. 
/// The view automatically handles scrolling to the top and bottom of the list and triggers the appropriate callbacks to load more data.
///
/// `InfiniteScroll` uses `LazyVStack` internally, in that it only renders the items that are currently visible on the screen.
///
/// In the following example, the `InfiniteScroll` view is used to display a list of items and load more data as the user scrolls:
/// ```swift
/// InfiniteScroll(data: items, id: \.id, onLoadPrev: loadPrev, onLoadMore: loadMore) {
///     Text("Item \($0)")
/// }
/// ```
@available(iOS 17.0, *)
public struct AutoInfiniteScroll<Data, Key, Content, TopProgress, BottomProgress> : View where Key : Hashable, Content : View, TopProgress : View, BottomProgress : View {

    /// - Parameters:
    ///   - data: The array of data items to display.
    ///   - id: A key path that uniquely identifies each data item.
    ///   - initialFirstVisibleItem: The key of the initial first visible item. Defaults to `nil`.
    ///   - onLoadPrev: A closure to be called when the user scrolls to the top of the list. Use this closure to load previous data.
    ///   - onLoadMore: A closure to be called when the user scrolls to the bottom of the list. Use this closure to load more data.
    ///   - enableLoadPrev: A boolean value indicating whether to enable the load previous functionality. Defaults to `true`.
    ///   - enableLoadMore: A boolean value indicating whether to enable the load more functionality. Defaults to `true`.
    ///   - topProgress: A view builder that returns the top progress view.
    ///   - bottomProgress: A view builder that returns the bottom progress view.
    ///   - content: A view builder that returns the content view for each data item.
    public init(
        data: [Data],
        id: KeyPath<Data, Key>,
        initialFirstVisibleItem: Key? = nil,
        onLoadPrev: @escaping () -> Void,
        onLoadMore: @escaping () -> Void,
        enableLoadPrev: Bool = true,
        enableLoadMore: Bool = true,
        @ViewBuilder topProgress: @escaping () -> TopProgress,
        @ViewBuilder bottomProgress: @escaping () -> BottomProgress,
        @ViewBuilder content: @escaping (Data) -> Content
    ) {
        self.data = data
        self.id = id
        self.initialFirstVisibleItem = initialFirstVisibleItem
        self.onLoadPrev = onLoadPrev
        self.onLoadMore = onLoadMore
        self.enableLoadPrev = enableLoadPrev
        self.enableLoadMore = enableLoadMore
        self.topProgress = topProgress
        self.bottomProgress = bottomProgress
        self.content = content
    }
    
        
    /// - Parameters:
    ///   - data: The array of data items to display.
    ///   - id: A key path that uniquely identifies each data item.
    ///   - initialFirstVisibleItem: The key of the initial first visible item. Defaults to `nil`.
    ///   - onLoadPrev: A closure to be called when the user scrolls to the top of the list. Use this closure to load previous data.
    ///   - onLoadMore: A closure to be called when the user scrolls to the bottom of the list. Use this closure to load more data.
    ///   - enableLoadPrev: A boolean value indicating whether to enable the load previous functionality. Defaults to `true`.
    ///   - enableLoadMore: A boolean value indicating whether to enable the load more functionality. Defaults to `true`.
    ///   - progress: A view builder that returns the progress view for both top and bottom.
    ///   - content: A view builder that returns the content view for each data item.
    public init(
        data: [Data],
        id: KeyPath<Data, Key>,
        initialFirstVisibleItem: Key? = nil,
        onLoadPrev: @escaping () -> Void,
        onLoadMore: @escaping () -> Void,
        enableLoadPrev: Bool = true,
        enableLoadMore: Bool = true,
        @ViewBuilder progress: @escaping () -> TopProgress,
        @ViewBuilder content: @escaping (Data) -> Content
    ) where BottomProgress == TopProgress {
        self.data = data
        self.id = id
        self.initialFirstVisibleItem = initialFirstVisibleItem
        self.onLoadPrev = onLoadPrev
        self.onLoadMore = onLoadMore
        self.enableLoadPrev = enableLoadPrev
        self.enableLoadMore = enableLoadMore
        self.topProgress = progress
        self.bottomProgress = progress
        self.content = content
    }
    
    /// - Parameters:
    ///   - data: The array of data items to display.
    ///   - id: A key path that uniquely identifies each data item.
    ///   - initialFirstVisibleItem: The key of the initial first visible item. Defaults to `nil`.
    ///   - onLoadPrev: A closure to be called when the user scrolls to the top of the list. Use this closure to load previous data.
    ///   - onLoadMore: A closure to be called when the user scrolls to the bottom of the list. Use this closure to load more data.
    ///   - enableLoadPrev: A boolean value indicating whether to enable the load previous functionality. Defaults to `true`.
    ///   - enableLoadMore: A boolean value indicating whether to enable the load more functionality. Defaults to `true`.
    ///   - content: A view builder that returns the content view for each data item.
    public init(
        data: [Data],
        id: KeyPath<Data, Key>,
        initialFirstVisibleItem: Key? = nil,
        onLoadPrev: @escaping () -> Void,
        onLoadMore: @escaping () -> Void,
        enableLoadPrev: Bool = true,
        enableLoadMore: Bool = true,
        @ViewBuilder content: @escaping (Data) -> Content
    ) where TopProgress == EmptyView, BottomProgress == EmptyView {
        self.data = data
        self.id = id
        self.initialFirstVisibleItem = initialFirstVisibleItem
        self.onLoadPrev = onLoadPrev
        self.onLoadMore = onLoadMore
        self.enableLoadPrev = enableLoadPrev
        self.enableLoadMore = enableLoadMore
        self.topProgress = nil
        self.bottomProgress = nil
        self.content = content
    }
    
    let data: [Data]
    let id: KeyPath<Data, Key>
    let initialFirstVisibleItem: Key?
    let onLoadPrev: () -> Void
    let onLoadMore: () -> Void
    let enableLoadPrev: Bool
    let enableLoadMore: Bool
    
    @ViewBuilder private let topProgress: (() -> TopProgress)?
    @ViewBuilder private let bottomProgress: (() -> BottomProgress)?
    @ViewBuilder private let content: (Data) -> Content
    
    public var body: some View {
        InfiniteScroll(
            data: data,
            id: id,
            initialFirstVisibleItem: initialFirstVisibleItem,
            onLoadPrev: onLoadPrev,
            onLoadMore: onLoadMore,
            enableLoadPrev: enableLoadPrev,
            enableLoadMore: enableLoadMore,
            topProgress: {
                if let topProgress {
                    topProgress()
                } else {
                    defaultProgress
                }
            },
            bottomProgress: {
                if let bottomProgress {
                    bottomProgress()
                } else {
                    defaultProgress
                }
            },
            content: content
        )
    }
    
    private var defaultProgress: some View {
        ProgressView()
            .progressViewStyle(CircularProgressViewStyle())
            .padding()
    }
}

private let COORDINATE_SPACE: String = "InfiniteScrollContainer"

@available(iOS 17.0, *)
private struct InfiniteScroll<Data, Key, Content, TopProgress, BottomProgress> : View where Key : Hashable, Content : View, TopProgress : View, BottomProgress : View {

    let data: [Data]
    let id: KeyPath<Data, Key>
    let initialFirstVisibleItem: Key?
    let onLoadPrev: () -> Void
    let onLoadMore: () -> Void
    let enableLoadPrev: Bool
    let enableLoadMore: Bool
    
    @ViewBuilder let topProgress: () -> TopProgress
    @ViewBuilder let bottomProgress: () -> BottomProgress
    @ViewBuilder let content: (Data) -> Content

    @State private var scrollPosition: Key?
    
    // Lock for onLoadPrev to prevent multiple calls
    @State private var loading: Bool = false
    
    @State private var topAppeared = false
    
    @State private var loadPrevViewHeight: CGFloat?
    @State private var loadMoreViewHeight: CGFloat?
    
    @State private var topOffset: CGFloat?
    @State private var bottomOffset: CGFloat?
    
    @State private var scrollToInitial = true
    
    public var body: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                ForEach(data, id: id) { data in
                    content(data)
                        .id(data[keyPath: id])
                }
            }
            .scrollTargetLayout()
            .padding(.top, loadPrevViewHeight)
            .padding(.bottom, loadMoreViewHeight)
            .background {
                GeometryReader { proxy -> Color in
                    onScroll(proxy: proxy)
                    
                    return Color.clear
                }
            }
        }
        .scrollPosition(id: $scrollPosition)
        .coordinateSpace(name: COORDINATE_SPACE)
        .overlay(alignment: .top) {
            if enableLoadPrev {
                topProgress()
                    .readGeometry {
                        if loadPrevViewHeight != $0.height {
                            loadPrevViewHeight = $0.height
                        }
                    }
                    .offset(y: -(topOffset ?? 1000))
            }
        }
        .overlay(alignment: .bottom) {
            if enableLoadMore {
                bottomProgress()
                    .readGeometry {
                        if loadMoreViewHeight != $0.height {
                            loadMoreViewHeight = $0.height
                        }
                    }
                    .offset(y: bottomOffset ?? 1000)
            }
        }
        .clipped()
        .onAppear { // dont use task, it will cause scrolling delay
            initialScroll()
        }
        .onChange(of: data.count) { oldValue, newValue in
            if newValue < oldValue {
                scrollToInitial = true
                initialScroll()
            } else if loading {
                Task { @MainActor in
                    try? await Task.sleep(nanoseconds: 100_000_000)
                    loading = false
                }
            }
        }
    }
    
    private func onScroll(proxy: GeometryProxy) {
        if !enableLoadPrev { return }
        guard let loadPrevViewHeight, let loadMoreViewHeight else { return }
        
        guard let bound = proxy.bounds(of: .named(COORDINATE_SPACE)) else { return }

        let topOffset = bound.minY
        let contentHeight = proxy.frame(in: .global).height
        let bottomOffset = contentHeight - bound.maxY

        Task { @MainActor in
            if self.topOffset != topOffset {
                self.topOffset = topOffset
            }
            
            if self.bottomOffset != bottomOffset {
                self.bottomOffset = bottomOffset
            }
            
            if loading { return }
            
            // TODO: fix hard code 0.8
            if topOffset <= loadPrevViewHeight * 0.8 && topOffset >= 0 {
                if topAppeared {
                    loading = true
                    onLoadPrev()
                }
            }
            if bottomOffset <= loadPrevViewHeight * 0.8 && topOffset >= 0 {
                loading = true
                onLoadMore()
            }
        }
    }
    
    private func initialScroll() {
        let first: Key?
        if initialFirstVisibleItem != nil {
            first = initialFirstVisibleItem
        } else {
            first = data.first?[keyPath: id]
        }
        
        if scrollToInitial {
            scrollToInitial = false
            scrollPosition = first
            Task { @MainActor in
                try? await Task.sleep(nanoseconds: 100_000_000)
                topAppeared = true
            }
        }
    }
}
