import SwiftUI
import HuggingGeometryReader

private let infiniteScrollCoordinateSpaceName = "InfiniteScrollContainer"
private let scrollOffsetUpdateThreshold: CGFloat = 12
private let minimumLoadTriggerHeight: CGFloat = 48

@available(iOS 17.0, macOS 14.0, *)
public struct InfiniteScroll<Data, ID, Content, TopProgress, BottomProgress>: View
where Data: RandomAccessCollection,
      ID: Hashable,
      Content: View,
      TopProgress: View,
      BottomProgress: View
{
    let data: Data
    let id: KeyPath<Data.Element, ID>
    let initialFirstVisibleItem: ID?
    let onLoadPrev: () -> Void
    let onLoadMore: () -> Void
    let enableLoadPrev: Bool
    let enableLoadMore: Bool
    let loadingBinding: Binding<Bool>?
    let scrollPositionBinding: Binding<ID?>?
    let scrollToIDRequestBinding: Binding<ID?>?
    let scrollToTopIDRequestBinding: Binding<ID?>?
    let preventLoadPrevBinding: Binding<Bool>?
    let contentBottomInset: CGFloat
    let contentTopInset: CGFloat
    let scrollPositionAnchor: UnitPoint

    @ViewBuilder let topProgress: () -> TopProgress
    @ViewBuilder let bottomProgress: () -> BottomProgress
    @ViewBuilder let content: (Data.Element) -> Content

    public init(
        data: Data,
        id: KeyPath<Data.Element, ID>,
        initialFirstVisibleItem: ID? = nil,
        onLoadPrev: @escaping () -> Void,
        onLoadMore: @escaping () -> Void,
        enableLoadPrev: Bool = true,
        enableLoadMore: Bool = true,
        loadingBinding: Binding<Bool>? = nil,
        scrollPositionBinding: Binding<ID?>? = nil,
        scrollToIDRequestBinding: Binding<ID?>? = nil,
        scrollToTopIDRequestBinding: Binding<ID?>? = nil,
        preventLoadPrevBinding: Binding<Bool>? = nil,
        contentBottomInset: CGFloat = 0,
        contentTopInset: CGFloat = 0,
        scrollPositionAnchor: UnitPoint = .bottom,
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
        self.loadingBinding = loadingBinding
        self.scrollPositionBinding = scrollPositionBinding
        self.scrollToIDRequestBinding = scrollToIDRequestBinding
        self.scrollToTopIDRequestBinding = scrollToTopIDRequestBinding
        self.preventLoadPrevBinding = preventLoadPrevBinding
        self.contentBottomInset = contentBottomInset
        self.contentTopInset = contentTopInset
        self.scrollPositionAnchor = scrollPositionAnchor
        self.topProgress = topProgress
        self.bottomProgress = bottomProgress
        self.content = content
    }

    @State private var internalScrollPosition: ID?
    @State private var internalLoading = false
    @State private var topAppeared = false
    @State private var loadPrevViewHeight: CGFloat?
    @State private var loadMoreViewHeight: CGFloat?
    @State private var topOffset: CGFloat?
    @State private var bottomOffset: CGFloat?
    @State private var scrollToInitial = true

    private var effectiveScrollPosition: Binding<ID?> {
        scrollPositionBinding ?? Binding(
            get: { internalScrollPosition },
            set: { internalScrollPosition = $0 }
        )
    }

    private var effectiveScrollToIDRequest: Binding<ID?> {
        scrollToIDRequestBinding ?? Binding(get: { nil }, set: { _ in })
    }

    private var effectiveScrollToTopIDRequest: Binding<ID?> {
        scrollToTopIDRequestBinding ?? Binding(get: { nil }, set: { _ in })
    }

    private var loading: Bool {
        loadingBinding?.wrappedValue ?? internalLoading
    }

    public var body: some View {
        ScrollViewReader { scrollProxy in
            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(data, id: id) { element in
                        content(element)
                            .id(element[keyPath: id])
                    }
                    if contentBottomInset > 0 {
                        Color.clear
                            .frame(height: contentBottomInset)
                    }
                }
                .scrollTargetLayout()
                .padding(.top, contentTopInset + (enableLoadPrev ? (loadPrevViewHeight ?? 0) : 0))
                .padding(.bottom, enableLoadMore ? (loadMoreViewHeight ?? 0) : 0)
                .background {
                    GeometryReader { proxy in
                        Color.clear
                            .onAppear { onScroll(proxy: proxy) }
                            .onChange(of: proxy.frame(in: .named(infiniteScrollCoordinateSpaceName)).minY) { _, _ in
                                onScroll(proxy: proxy)
                            }
                    }
                }
            }
            .scrollPosition(id: effectiveScrollPosition, anchor: scrollPositionAnchor)
            .infiniteScrollDefaultAnchor(scrollPositionAnchor == .bottom ? .bottom : nil)
            .coordinateSpace(name: infiniteScrollCoordinateSpaceName)
            .onChange(of: effectiveScrollToIDRequest.wrappedValue) { _, newID in
                guard let newID else { return }
                scrollProxy.scrollTo(newID, anchor: .bottom)
                scrollToIDRequestBinding?.wrappedValue = nil
            }
            .onChange(of: effectiveScrollToTopIDRequest.wrappedValue) { _, newID in
                guard let newID else { return }
                Task { @MainActor in
                    try? await Task.sleep(nanoseconds: 80_000_000)
                    scrollProxy.scrollTo(newID, anchor: .top)
                    scrollToTopIDRequestBinding?.wrappedValue = nil
                }
            }
            .overlay(
                Group {
                    if enableLoadPrev {
                        topProgress()
                            .frame(height: minimumLoadTriggerHeight)
                            .readGeometry { size in
                                let height = size.height
                                if loadPrevViewHeight != height {
                                    DispatchQueue.main.async { loadPrevViewHeight = height }
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
                            .frame(height: minimumLoadTriggerHeight)
                            .readGeometry { size in
                                let height = size.height
                                if loadMoreViewHeight != height {
                                    DispatchQueue.main.async { loadMoreViewHeight = height }
                                }
                            }
                            .offset(y: bottomOffset ?? 1000)
                    }
                },
                alignment: .bottom
            )
            .clipped()
            .onAppear {
                initialScroll()
            }
            .onChange(of: data.count) { oldValue, newValue in
                if newValue < oldValue {
                    let currentID = effectiveScrollPosition.wrappedValue
                    if let currentID, !data.contains(where: { $0[keyPath: id] == currentID }) {
                        let survivor = data.last?[keyPath: id] ?? data.first?[keyPath: id]
                        setScrollPosition(survivor)
                    }
                } else if loading, newValue > oldValue {
                    let anchorID = effectiveScrollToTopIDRequest.wrappedValue
                        ?? effectiveScrollPosition.wrappedValue
                    Task { @MainActor in
                        if let anchorID,
                           data.contains(where: { $0[keyPath: id] == anchorID }) {
                            try? await Task.sleep(nanoseconds: 80_000_000)
                            scrollProxy.scrollTo(anchorID, anchor: .top)
                            scrollToTopIDRequestBinding?.wrappedValue = nil
                        }
                        try? await Task.sleep(nanoseconds: 20_000_000)
                        setLoading(false)
                    }
                } else if loading {
                    Task { @MainActor in
                        try? await Task.sleep(nanoseconds: 100_000_000)
                        setLoading(false)
                    }
                }
            }
        }
    }

    private func setScrollPosition(_ value: ID?) {
        if let binding = scrollPositionBinding {
            binding.wrappedValue = value
        } else {
            internalScrollPosition = value
        }
    }

    private func setLoading(_ value: Bool) {
        if let binding = loadingBinding {
            binding.wrappedValue = value
        } else {
            internalLoading = value
        }
    }

    private func onScroll(proxy: GeometryProxy) {
        guard let bound = proxy.bounds(of: .named(infiniteScrollCoordinateSpaceName)) else { return }

        let topOffset = bound.minY
        let contentHeight = proxy.frame(in: .global).height
        let bottomOffset = contentHeight - bound.maxY

        DispatchQueue.main.async {
            let threshold = scrollOffsetUpdateThreshold
            if let previous = self.topOffset, abs(previous - topOffset) > threshold {
                self.topOffset = topOffset
            } else if self.topOffset == nil {
                self.topOffset = topOffset
            }

            if let previous = self.bottomOffset, abs(previous - bottomOffset) > threshold {
                self.bottomOffset = bottomOffset
            } else if self.bottomOffset == nil {
                self.bottomOffset = bottomOffset
            }

            if loading { return }
            if preventLoadPrevBinding?.wrappedValue == true { return }

            if enableLoadPrev {
                let triggerHeight = max(loadPrevViewHeight ?? 0, minimumLoadTriggerHeight)
                if topOffset <= triggerHeight * 0.8,
                   topOffset >= -scrollOffsetUpdateThreshold,
                   topAppeared {
                    setLoading(true)
                    onLoadPrev()
                }
            }
            if enableLoadMore {
                let triggerHeight = max(loadMoreViewHeight ?? 0, minimumLoadTriggerHeight)
                if bottomOffset <= triggerHeight * 0.8, topOffset >= 0 {
                    setLoading(true)
                    onLoadMore()
                }
            }
        }
    }

    private func initialScroll() {
        let first = initialFirstVisibleItem ?? data.first?[keyPath: id]
        guard scrollToInitial else { return }
        scrollToInitial = false
        if effectiveScrollPosition.wrappedValue == nil {
            setScrollPosition(first)
        }
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 100_000_000)
            topAppeared = true
        }
    }
}

@available(iOS 14.0, macOS 14.0, *)
public struct InfiniteScrollIOS16<Data, ID, Content, TopProgress, BottomProgress>: View
where Data: RandomAccessCollection,
      ID: Hashable,
      Content: View,
      TopProgress: View,
      BottomProgress: View
{
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

    @State private var loadingPrev = false
    @State private var loadingNext = false
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
                    ForEach(data, id: id) { element in
                        let elementID = element[keyPath: id]
                        if topID == elementID {
                            content(element)
                                .readGeometry { size in
                                    let height = size.height
                                    if height > 1, topItemHeight != height {
                                        DispatchQueue.main.async { topItemHeight = height }
                                    }
                                }
                                .id(elementID)
                        } else {
                            content(element)
                                .id(elementID)
                        }
                    }
                }
                .padding(.top, enableLoadPrev ? loadPrevViewHeight : nil)
                .padding(.bottom, enableLoadMore ? loadMoreViewHeight : nil)
                .background(
                    GeometryReader { geo in
                        Color.clear.onChange(of: geo.frame(in: .named(infiniteScrollCoordinateSpaceName))) { _ in
                            onScroll(proxy: geo)
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
                        let anchorY = (loadPrevViewHeight ?? 0) / max(containerHeight - (topItemHeight ?? 0), 1)
                        proxy.scrollTo(topID, anchor: UnitPoint(x: 0, y: anchorY))
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
        .coordinateSpace(name: infiniteScrollCoordinateSpaceName)
        .overlay(
            Group {
                if enableLoadPrev {
                    topProgress()
                        .readGeometry { size in
                            let height = size.height
                            if loadPrevViewHeight != height {
                                DispatchQueue.main.async { loadPrevViewHeight = height }
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
                        .readGeometry { size in
                            let height = size.height
                            if loadMoreViewHeight != height {
                                DispatchQueue.main.async { loadMoreViewHeight = height }
                            }
                        }
                        .offset(y: bottomOffset ?? 1000)
                }
            },
            alignment: .bottom
        )
        .clipped()
        .readGeometry { size in
            let height = size.height
            if containerHeight != height {
                DispatchQueue.main.async { containerHeight = height }
            }
        }
    }

    private func onScroll(proxy: GeometryProxy) {
        let bound = proxy.frame(in: .named(infiniteScrollCoordinateSpaceName))
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

            if enableLoadPrev {
                let triggerHeight = max(loadPrevViewHeight ?? 0, minimumLoadTriggerHeight)
                if topOffset <= triggerHeight * 0.8, topOffset >= 0, topAppeared {
                    loadingPrev = true
                    onLoadPrev()
                }
            }
            if enableLoadMore {
                let triggerHeight = max(loadMoreViewHeight ?? 0, minimumLoadTriggerHeight)
                if bottomOffset <= triggerHeight * 0.8, topOffset >= 0 {
                    loadingNext = true
                    onLoadMore()
                }
            }
        }
    }

    private func initialScroll(proxy: ScrollViewProxy) {
        let first = initialFirstVisibleItem ?? data.first?[keyPath: id]
        guard scrollToInitial else { return }
        scrollToInitial = false
        proxy.scrollTo(first, anchor: .top)
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 100_000_000)
            topAppeared = true
        }
    }
}

@available(iOS 17.0, macOS 14.0, *)
private extension View {
    @ViewBuilder
    func infiniteScrollDefaultAnchor(_ anchor: UnitPoint?) -> some View {
        if let anchor {
            self.defaultScrollAnchor(anchor)
        } else {
            self
        }
    }
}
