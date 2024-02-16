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
public struct AutoInfiniteScroll<Data, ID, Content, TopProgress, BottomProgress> : View where Data : RandomAccessCollection, ID : Hashable, Content : View, TopProgress : View, BottomProgress : View {

    /// - Parameters:
    ///   - data: The data uses to create views dynamically.
    ///   - id: The key path to the provided data's identifier.
    ///   - initialFirstVisibleItem: The key of the initial first visible item. Defaults to `nil`.
    ///   - onLoadPrev: A closure to be called when the user scrolls to the top of the list. Use this closure to load previous data.
    ///   - onLoadMore: A closure to be called when the user scrolls to the bottom of the list. Use this closure to load more data.
    ///   - enableLoadPrev: A boolean value indicating whether to enable the load previous functionality. Defaults to `true`.
    ///   - enableLoadMore: A boolean value indicating whether to enable the load more functionality. Defaults to `true`.
    ///   - topProgress: A view builder that returns the top progress view.
    ///   - bottomProgress: A view builder that returns the bottom progress view.
    ///   - content: A view builder that returns the content view for each data item.
    public init(
        _ data: Data,
        id: KeyPath<Data.Element, ID>,
        initialFirstVisibleItem: ID? = nil,
        onLoadPrev: @escaping () -> Void,
        onLoadMore: @escaping () -> Void,
        enableLoadPrev: Bool = true,
        enableLoadMore: Bool = true,
        @ViewBuilder topProgress: @escaping () -> TopProgress,
        @ViewBuilder bottomProgress: @escaping () -> BottomProgress,
        @ViewBuilder content: @escaping (Data.Element) -> Content
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
    ///   - data: The data uses to create views dynamically.
    ///   - id: The key path to the provided data's identifier.
    ///   - initialFirstVisibleItem: The key of the initial first visible item. Defaults to `nil`.
    ///   - onLoadPrev: A closure to be called when the user scrolls to the top of the list. Use this closure to load previous data.
    ///   - onLoadMore: A closure to be called when the user scrolls to the bottom of the list. Use this closure to load more data.
    ///   - enableLoadPrev: A boolean value indicating whether to enable the load previous functionality. Defaults to `true`.
    ///   - enableLoadMore: A boolean value indicating whether to enable the load more functionality. Defaults to `true`.
    ///   - progress: A view builder that returns the progress view for both top and bottom.
    ///   - content: A view builder that returns the content view for each data item.
    public init(
        _ data: Data,
        id: KeyPath<Data.Element, ID>,
        initialFirstVisibleItem: ID? = nil,
        onLoadPrev: @escaping () -> Void,
        onLoadMore: @escaping () -> Void,
        enableLoadPrev: Bool = true,
        enableLoadMore: Bool = true,
        @ViewBuilder progress: @escaping () -> TopProgress,
        @ViewBuilder content: @escaping (Data.Element) -> Content
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
    ///   - data: The data uses to create views dynamically.
    ///   - id: The key path to the provided data's identifier.
    ///   - initialFirstVisibleItem: The key of the initial first visible item. Defaults to `nil`.
    ///   - onLoadPrev: A closure to be called when the user scrolls to the top of the list. Use this closure to load previous data.
    ///   - onLoadMore: A closure to be called when the user scrolls to the bottom of the list. Use this closure to load more data.
    ///   - enableLoadPrev: A boolean value indicating whether to enable the load previous functionality. Defaults to `true`.
    ///   - enableLoadMore: A boolean value indicating whether to enable the load more functionality. Defaults to `true`.
    ///   - content: A view builder that returns the content view for each data item.
    public init(
        _ data: Data,
        id: KeyPath<Data.Element, ID>,
        initialFirstVisibleItem: ID? = nil,
        onLoadPrev: @escaping () -> Void,
        onLoadMore: @escaping () -> Void,
        enableLoadPrev: Bool = true,
        enableLoadMore: Bool = true,
        @ViewBuilder content: @escaping (Data.Element) -> Content
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
    
    let data: Data
    let id: KeyPath<Data.Element, ID>
    let initialFirstVisibleItem: ID?
    let onLoadPrev: () -> Void
    let onLoadMore: () -> Void
    let enableLoadPrev: Bool
    let enableLoadMore: Bool
    
    @ViewBuilder private let topProgress: (() -> TopProgress)?
    @ViewBuilder private let bottomProgress: (() -> BottomProgress)?
    @ViewBuilder private let content: (Data.Element) -> Content
    
    public var body: some View {
        if #available(iOS 17.0, *) {
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
        } else {
            InfiniteScrollIOS16(
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
    }
    
    private var defaultProgress: some View {
        ProgressView()
            .progressViewStyle(CircularProgressViewStyle())
            .padding()
    }
}


public extension AutoInfiniteScroll where ID == Data.Element.ID, Content : View, Data.Element : Identifiable {
    
    /// - Parameters:
    ///  - data: The identifiable data uses to create views dynamically.
    ///  - initialFirstVisibleItem: The key of the initial first visible item. Defaults to `nil`.
    ///  - onLoadPrev: A closure to be called when the user scrolls to the top of the list. Use this closure to load previous data.
    ///  - onLoadMore: A closure to be called when the user scrolls to the bottom of the list. Use this closure to load more data.
    ///  - enableLoadPrev: A boolean value indicating whether to enable the load previous functionality. Defaults to `true`.
    ///  - enableLoadMore: A boolean value indicating whether to enable the load more functionality. Defaults to `true`.
    ///  - topProgress: A view builder that returns the top progress view.
    ///  - bottomProgress: A view builder that returns the bottom progress view.
    ///  - content: A view builder that returns the content view for each data item.
    public init(
        _ data: Data,
        initialFirstVisibleItem: ID,
        onLoadPrev: @escaping () -> Void,
        onLoadMore: @escaping () -> Void,
        enableLoadPrev: Bool = true,
        enableLoadMore: Bool = true,
        @ViewBuilder topProgress: @escaping () -> TopProgress,
        @ViewBuilder bottomProgress: @escaping () -> BottomProgress,
        @ViewBuilder content: @escaping (Data.Element) -> Content
    ) {
        self.init(
            data,
            id: \.id,
            initialFirstVisibleItem: initialFirstVisibleItem,
            onLoadPrev: onLoadPrev,
            onLoadMore: onLoadMore,
            enableLoadPrev: enableLoadPrev,
            enableLoadMore: enableLoadMore,
            topProgress: topProgress,
            bottomProgress: bottomProgress,
            content: content
        )
    }
    
    /// - Parameters:
    ///  - data: The identifiable data uses to create views dynamically.
    ///  - initialFirstVisibleItem: The key of the initial first visible item. Defaults to `nil`.
    ///  - onLoadPrev: A closure to be called when the user scrolls to the top of the list. Use this closure to load previous data.
    ///  - onLoadMore: A closure to be called when the user scrolls to the bottom of the list. Use this closure to load more data.
    ///  - enableLoadPrev: A boolean value indicating whether to enable the load previous functionality. Defaults to `true`.
    ///  - enableLoadMore: A boolean value indicating whether to enable the load more functionality. Defaults to `true`.
    ///  - progress: A view builder that returns the progress view for both top and bottom.
    ///  - content: A view builder that returns the content view for each data item.
    public init(
        _ data: Data,
        initialFirstVisibleItem: ID,
        onLoadPrev: @escaping () -> Void,
        onLoadMore: @escaping () -> Void,
        enableLoadPrev: Bool = true,
        enableLoadMore: Bool = true,
        progress: @escaping () -> TopProgress,
        @ViewBuilder content: @escaping (Data.Element) -> Content
    ) where BottomProgress == TopProgress {
        self.init(
            data,
            id: \.id,
            initialFirstVisibleItem: initialFirstVisibleItem,
            onLoadPrev: onLoadPrev,
            onLoadMore: onLoadMore,
            enableLoadPrev: enableLoadPrev,
            enableLoadMore: enableLoadMore,
            progress: progress,
            content: content
        )
    }
    
    /// - Parameters:
    ///  - data: The identifiable data uses to create views dynamically.
    ///  - initialFirstVisibleItem: The key of the initial first visible item. Defaults to `nil`.
    ///  - onLoadPrev: A closure to be called when the user scrolls to the top of the list. Use this closure to load previous data.
    ///  - onLoadMore: A closure to be called when the user scrolls to the bottom of the list. Use this closure to load more data.
    ///  - enableLoadPrev: A boolean value indicating whether to enable the load previous functionality. Defaults to `true`.
    ///  - enableLoadMore: A boolean value indicating whether to enable the load more functionality. Defaults to `true`.
    ///  - content: A view builder that returns the content view for each data item.
    public init(
        _ data: Data,
        initialFirstVisibleItem: ID,
        onLoadPrev: @escaping () -> Void,
        onLoadMore: @escaping () -> Void,
        enableLoadPrev: Bool = true,
        enableLoadMore: Bool = true,
        @ViewBuilder content: @escaping (Data.Element) -> Content
    ) where TopProgress == EmptyView, BottomProgress == EmptyView {
        self.init(
            data,
            id: \.id,
            initialFirstVisibleItem: initialFirstVisibleItem,
            onLoadPrev: onLoadPrev,
            onLoadMore: onLoadMore,
            enableLoadPrev: enableLoadPrev,
            enableLoadMore: enableLoadMore,
            content: content
        )
    }
}

private let COORDINATE_SPACE: String = "InfiniteScrollContainer"

@available(iOS 17.0, *)
private struct InfiniteScroll<Data, ID, Content, TopProgress, BottomProgress> : View where Data : RandomAccessCollection, ID : Hashable, Content : View, TopProgress : View, BottomProgress : View {

    let data: Data
    let id: KeyPath<Data.Element, ID>
    let initialFirstVisibleItem: ID?
    let onLoadPrev: () -> Void
    let onLoadMore: () -> Void
    let enableLoadPrev: Bool
    let enableLoadMore: Bool
    
    @ViewBuilder let topProgress: () -> TopProgress
    @ViewBuilder let bottomProgress: () -> BottomProgress
    @ViewBuilder let content: (Data.Element) -> Content

    @State private var scrollPosition: ID?
    
    // Lock for loading to prevent multiple calls
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
                ForEach(data, id: id) {
                    content($0)
                        .id($0[keyPath: id])
                }
            }
            .scrollTargetLayout()
            .padding(.top, enableLoadPrev ? loadPrevViewHeight : nil)
            .padding(.bottom, enableLoadMore ? loadMoreViewHeight : nil)
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
            if let loadPrevViewHeight, enableLoadPrev {
                if topOffset <= loadPrevViewHeight * 0.8 && topOffset >= 0 {
                    if topAppeared {
                        loading = true
                        onLoadPrev()
                    }
                }
            }
            if let loadPrevViewHeight, enableLoadMore {
                if bottomOffset <= loadPrevViewHeight * 0.8 && topOffset >= 0 {
                    loading = true
                    onLoadMore()
                }
            }
        }
    }
    
    private func initialScroll() {
        let first: ID?
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

private struct InfiniteScrollIOS16<Data, ID, Content, TopProgress, BottomProgress> : View where Data : RandomAccessCollection, ID : Hashable, Content : View, TopProgress : View, BottomProgress : View {
    
    let data: Data
    let id: KeyPath<Data.Element, ID>
    let initialFirstVisibleItem: ID?
    let onLoadPrev: () -> Void
    let onLoadMore: () -> Void
    let enableLoadPrev: Bool
    let enableLoadMore: Bool
    
    @ViewBuilder let topProgress: () -> TopProgress
    @ViewBuilder let bottomProgress: () -> BottomProgress
    @ViewBuilder let content: (Data.Element) -> Content
    
    // Lock for loading to prevent multiple calls
    @State private var loadingPrev: Bool = false
    @State private var loadingNext: Bool = false
    
    @State private var topAppeared = false
    @State private var topID: ID?
    @State private var topItemHeight: CGFloat?
    
    @State private var containerHeight: CGFloat = 0
    
    @State private var loadPrevViewHeight: CGFloat?
    @State private var loadMoreViewHeight: CGFloat?
    
    @State private var topOffset: CGFloat?
    @State private var bottomOffset: CGFloat?
    
    @State private var scrollToInitial = true
    
    public var body: some View {
        ScrollView {
            ScrollViewReader { proxy in
                LazyVStack(spacing: 0) {
                    ForEach(data, id: id) {
                        if topID == $0[keyPath: id] {
                            content($0)
                                .readGeometry { size in
                                    // geometry in lazyStack sometimes will be a very small value
                                    // need to filter out
                                    if size.height > 1 && topItemHeight != size.height {
                                        topItemHeight = size.height
                                    }
                                }
                                .id($0[keyPath: id])
                        } else {
                            content($0)
                                .id($0[keyPath: id])
                        }
                    }
                }
                .padding(.top, enableLoadPrev ? loadPrevViewHeight : nil)
                .padding(.bottom, enableLoadMore ? loadMoreViewHeight : nil)
                .background(
                    GeometryReader { proxy in
                        Color.clear.onChange(of: proxy.frame(in: .named(COORDINATE_SPACE))) { _ in
                            onScroll(proxy: proxy)
                        }
                    }
                )
                .onAppear {
                    initialScroll(proxy: proxy)
                }
                .onChange(of: data.count) { newValue in
                    if newValue < data.count {
                        scrollToInitial = true
                        initialScroll(proxy: proxy)
                    } else if loadingPrev {
                        proxy.scrollTo(topID, anchor: UnitPoint(x: 0, y: (loadPrevViewHeight ?? 0) / (containerHeight - (topItemHeight ?? 0))))
                        Task { @MainActor in
                            try? await Task.sleep(nanoseconds: 100_000_000)
                            loadingPrev = false
                        }
                    } else if loadingNext {
                        Task { @MainActor in
                            try? await Task.sleep(nanoseconds: 100_000_000)
                            loadingNext = false
                        }
                    }
                }
            }
        }
        .coordinateSpace(name: COORDINATE_SPACE)
        .overlay(
            Group {
                if enableLoadPrev {
                    topProgress()
                        .readGeometry {
                            if loadPrevViewHeight != $0.height {
                                loadPrevViewHeight = $0.height
                            }
                        }
                        .offset(y: -(topOffset ?? 1000))
                }
            },
            alignment: .top
        )
        .overlay(
            Group {
                if enableLoadMore {
                    bottomProgress()
                        .readGeometry {
                            if loadMoreViewHeight != $0.height {
                                loadMoreViewHeight = $0.height
                            }
                        }
                        .offset(y: bottomOffset ?? 1000)
                }
            },
            alignment: .bottom
        )
        .clipped()
        .readGeometry { size in
            containerHeight = size.height
        }
    }
    
    private func onScroll(proxy: GeometryProxy) {
        let bound = proxy.frame(in: .named(COORDINATE_SPACE))
            
        let topOffset = -bound.minY
        let contentHeight = proxy.frame(in: .global).height
        let bottomOffset = bound.maxY - containerHeight

        Task { @MainActor in
            if topID != data.first?[keyPath: id] {
                topID = data.first?[keyPath: id]
            }

            if self.topOffset != topOffset {
                self.topOffset = topOffset
            }
            
            if self.bottomOffset != bottomOffset {
                self.bottomOffset = bottomOffset
            }
            
            if loadingPrev || loadingNext { return }
            
            // TODO: fix hard code 0.8
            if let loadPrevViewHeight, enableLoadPrev {
                if topOffset <= loadPrevViewHeight * 0.8 && topOffset >= 0 {
                    if topAppeared {
                        loadingPrev = true
                        onLoadPrev()
                    }
                }
            }
            if let loadMoreViewHeight, enableLoadMore {
                if bottomOffset <= loadMoreViewHeight * 0.8 && topOffset >= 0 {
                    loadingNext = true
                    onLoadMore()
                }
            }
        }
    }
    
    private func initialScroll(proxy: ScrollViewProxy) {
        let first: ID?
        if initialFirstVisibleItem != nil {
            first = initialFirstVisibleItem
        } else {
            first = data.first?[keyPath: id]
        }
                
        if scrollToInitial {
            scrollToInitial = false
            proxy.scrollTo(first, anchor: .top)
            Task { @MainActor in
                try? await Task.sleep(nanoseconds: 100_000_000)
                topAppeared = true
            }
        }
    }
}
