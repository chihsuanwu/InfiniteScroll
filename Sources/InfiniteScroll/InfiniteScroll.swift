import SwiftUI
import HuggingGeometryReader

private let COORDINATE_SPACE: String = "InfiniteScrollContainer"

@available(iOS 17.0, *)
struct InfiniteScroll<Data, ID, Content, TopProgress, BottomProgress> : View where Data : RandomAccessCollection, ID : Hashable, Content : View, TopProgress : View, BottomProgress : View {

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

struct InfiniteScrollIOS16<Data, ID, Content, TopProgress, BottomProgress> : View where Data : RandomAccessCollection, ID : Hashable, Content : View, TopProgress : View, BottomProgress : View {
    
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
